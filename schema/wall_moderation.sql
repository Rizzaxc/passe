-- ============================================================================
-- Wall post reporting + auto-hide.
--
-- The blocking half of moderation lives in schema/friendship.sql (`user_block`)
-- because a block is a relationship between people, not a property of a post.
-- This file is the post-level half.
--
-- Apple review guideline 1.2 and Google Play's UGC policy both require a report
-- mechanism, a block mechanism and a moderation response for an app with a
-- user-generated photo feed — this is a submission blocker, not polish.
--
-- Depends on: schema/wall_post.sql. Idempotent / re-runnable.
-- ============================================================================

create table if not exists public.wall_post_report (
    post_id     uuid not null references public.wall_post(id) on delete cascade,
    reporter_id uuid not null default auth.uid()
                    references public."user"(id) on delete cascade,
    reason      text not null constraint wall_post_report_reason check (
                    reason in ('spam', 'harassment', 'nudity',
                               'violence', 'impersonation', 'other')),
    note        text constraint wall_post_report_note_length
                    check (note is null or char_length(note) <= 280),
    created_at  timestamptz not null default now(),
    primary key (post_id, reporter_id)   -- one report each; no ballot stuffing
);

create index if not exists wall_post_report_post_idx
    on public.wall_post_report (post_id);

alter table public.wall_post_report enable row level security;

-- Report anything you can see. No SELECT policy for regular users: reports are
-- triage input for the operator, not a public score, and letting people read
-- them turns reporting into a social act.
drop policy if exists "Report a visible post" on public.wall_post_report;
create policy "Report a visible post"
    on public.wall_post_report for insert to authenticated
    with check (
        reporter_id = (select auth.uid())
        and public.fn_can_see_wall_post(post_id)
    );

drop policy if exists "Reporters can see their own reports" on public.wall_post_report;
create policy "Reporters can see their own reports"
    on public.wall_post_report for select to authenticated
    using (reporter_id = (select auth.uid()));

-- Auto-hide once enough *distinct* people have reported it. The PK already
-- guarantees one row per reporter, so the count is distinct by construction.
--
-- Threshold is 5, not 3: in a community this size three coordinated reporters
-- is a trivially cheap takedown of someone they dislike. Hiding is reversible
-- (clear `hidden_at`) and does not delete the post — the author still sees it,
-- because fn_can_see_wall_post lets the author through unconditionally.
create or replace function public.fn_wall_post_autohide()
    returns trigger
    language plpgsql security definer set search_path to ''
as $$
declare
    v_reports int;
begin
    select count(*) into v_reports
        from public.wall_post_report where post_id = new.post_id;

    if v_reports >= 5 then
        update public.wall_post
            set hidden_at = now()
            where id = new.post_id and hidden_at is null;
    end if;

    return new;
end;
$$;

drop trigger if exists trg_wall_post_autohide on public.wall_post_report;
create trigger trg_wall_post_autohide
    after insert on public.wall_post_report
    for each row execute function public.fn_wall_post_autohide();

-- Operator helpers (service role / SQL console only — deliberately not granted
-- to `authenticated`). `wall_post_moderation_queue` is what you triage.
-- `security_invoker = true` matters: Postgres views default to running as
-- their *creator*, which would let any grantee read every reported post
-- regardless of RLS. Paired with an explicit revoke from anon — the default
-- privileges grant anon a direct SELECT that `revoke ... from public` misses.
create or replace view public.wall_post_moderation_queue
    with (security_invoker = true) as
    select p.id,
           p.author_id,
           p.caption,
           p.image_paths,
           p.created_at,
           p.expires_at,
           p.hidden_at,
           count(r.*) as report_count,
           array_agg(distinct r.reason) as reasons
    from public.wall_post p
    join public.wall_post_report r on r.post_id = p.id
    group by p.id
    order by count(r.*) desc, p.created_at desc;

revoke all on public.wall_post_moderation_queue from anon, authenticated, public;
