-- ============================================================================
-- shot_seed_timeline.sql — the TIME-SENSITIVE half of the App Store screenshot
-- dataset. Pairs with schema/shot_seed_structure.sql, which MUST be applied
-- first (this file references its cast and lobbies by sentinel uuid).
--
-- Why the split: structure is slow-moving and stays live until the build is
-- approved; everything here decays. `wall_post` hard-expires at <= 7 days,
-- `expire_past_activities()` deletes past UNCONFIRMED lobby activities on every
-- lobby-list load, and `fn_cron_tick` auto-cancels any under-threshold activity
-- at its `start_time`. So every timestamp below is relative to now(), and this
-- file is delete-and-regenerate: re-run it before each capture session, and
-- again at submission so the reviewer doesn't land on a decayed account.
--
-- Apply with psql or the Supabase MCP `execute_sql` (runs as postgres -> bypasses
-- RLS), NOT `apply_migration` — this is data, not schema.
--
-- Sentinel uuids, continuing the structure seed's `5107` scheme:
--   activities   51072000-0000-4000-8000-<12-digit index>
--   feed items   51073000-0000-4000-8000-<12-digit index>
--
-- ── Tiering (deliberate — neither store requires feature coverage) ──────────
-- TIER A, art-directed, the surfaces actually captured. TIER B, merely
-- not-hollow so a reviewer poking around finds something. TIER C, deliberately
-- EMPTY and honest: match history (only `record_challenge_match` writes
-- `lobby_match`, and the app renders a proper empty state), the đá wallet, and
-- referee hiring. Fabricating those would misrepresent the build.
--
-- THIS FILE COVERS BUILD STEP 1: activities, RSVPs and the lobby action-stream.
-- It unlocks the Manage activity card (shot 1), the lobby feed (shot 3) and all
-- of Manage ▸ Schedule, which falls out of these activities for free.
-- Still to come: payment settlement, freeplay listings, course session,
-- achievements, the HealthKit injector, and challenge data LAST (that area took
-- 5 commits in 7 days).
--
-- ── Things that bit, or would have ─────────────────────────────────────────
-- * `prepayment_amount` is GONE. Cost is `cost_type` (`per_pax`|`total`) +
--   `cost_amount`, informational only (schema/activity_cost_rework.sql).
-- * A PAST activity must clear its threshold or `expire_past_activities()`
--   deletes it out from under the health recap and wall posts that hang off it.
--   Every past activity here is over-confirmed on purpose.
-- * `confirmation_deadline` must stay in the FUTURE on an under-threshold
--   activity. Once it passes, the threshold sweep stamps `at_risk_notified_at`,
--   pushes the organizer, and FREEZES all RSVP writes — mid-shoot that turns a
--   live RSVP control into a padlock.
-- * Default threshold is `min(4, roster)` and OFF below 4 members
--   (`defaultConfirmationThreshold`), not a fixed 4.
-- * `kind = 'photo'` is retired as a writable feed kind. The lobby feed unions
--   `wall_post` rows instead (schema/lobby_feed_wall_posts.sql), so lobby photos
--   arrive with the wall-post step, not here.
-- * Naming rule inherited from the structure seed: FICTIONAL, not merely
--   invented. Captions, notes and poll options are free text and the easiest
--   place for a real brand to creep back in.
-- ============================================================================

-- ── 0. Cleanup (re-runnable) ────────────────────────────────────────────────
-- Feed items first (they FK activities), then the notification rows the
-- activity/RSVP triggers emit, then confirmations, then the activities.

DELETE FROM public.lobby_feed_item WHERE id::text LIKE '51073%';

-- `fn_emit_activity_scheduled` / `fn_emit_activity_confirmed` fire on the
-- inserts below and enqueue outbox rows. Every recipient is a seeded user, so
-- scoping by recipient is exact and cannot touch a real user's notifications.
DELETE FROM public.notification_outbox WHERE recipient_user_id::text LIKE '5107%';

DELETE FROM public.activity_confirmation
WHERE activity_id::text LIKE '51072%' OR user_id::text LIKE '5107%';

DELETE FROM public.activity WHERE id::text LIKE '51072%';

-- ── 1. Activities ───────────────────────────────────────────────────────────
DO $shot$
DECLARE
    c_hero    CONSTANT uuid := '51070000-0000-4000-8000-000000000001'::uuid;
    c_soccer  CONSTANT uuid := '51071000-0000-4000-8000-000000000001'::uuid; -- Anh Em Tan Làm (hero is CAPTAIN)
    c_pickle  CONSTANT uuid := '51071000-0000-4000-8000-000000000008'::uuid; -- Pickle Bình Thạnh (hero is MEMBER)
    v_soc_loc uuid;
    v_pic_loc uuid;
    v_pic_cap uuid := '51070000-0000-4000-8000-000000000057'::uuid;
    rec       record;
    v_act     uuid;
    i         int;
    -- Tonight's kickoff, snapped to 19:30 local, as the anchor every offset
    -- hangs off. Asia/Ho_Chi_Minh explicitly: the server is UTC, and a naive
    -- date_trunc would put an "evening" session at 02:30 for the shoot.
    v_base    timestamptz := (date_trunc('day', now() AT TIME ZONE 'Asia/Ho_Chi_Minh')
                              + interval '19 hours 30 minutes') AT TIME ZONE 'Asia/Ho_Chi_Minh';
BEGIN
    SELECT location_id INTO v_soc_loc FROM public.lobby_homeground WHERE lobby_id = c_soccer AND is_primary;
    SELECT location_id INTO v_pic_loc FROM public.lobby_homeground WHERE lobby_id = c_pickle AND is_primary;
    IF v_soc_loc IS NULL OR v_pic_loc IS NULL THEN
        RAISE EXCEPTION 'shot_seed_timeline: homegrounds missing — apply schema/shot_seed_structure.sql first.';
    END IF;

    FOR rec IN
        SELECT * FROM (VALUES
            -- idx, lobby,    organizer,  sport, start offset,              dur,  threshold, deadline lead, cost_type, cost
            -- A1: THE STAR. Two evenings out, comfortably over threshold.
            (1, c_soccer, c_hero,    1, v_base + interval '2 days',  interval '2 hours', 4, interval '36 hours', 'per_pax', 50000),
            -- A2: still gathering, so the Planner shows a second, live card.
            (2, c_soccer, c_hero,    1, v_base + interval '6 days',  interval '2 hours', 4, interval '36 hours', 'per_pax', 50000),
            -- A3/A4: PAST and over-confirmed, so expire_past_activities() leaves
            -- them alone. These are what the health recaps and wall posts hook to.
            (3, c_soccer, c_hero,    1, v_base - interval '5 days',  interval '2 hours', 4, NULL,                'per_pax', 50000),
            (4, c_soccer, c_hero,    1, v_base - interval '12 days', interval '2 hours', 4, NULL,                'per_pax', 50000),
            -- A5: pickleball, organised by ITS captain, not the hero — this is
            -- the member-side RSVP surface.
            (5, c_pickle, v_pic_cap, 5, v_base + interval '3 days' - interval '12 hours', interval '90 minutes', 4, interval '36 hours', 'per_pax', 80000),
            (6, c_pickle, v_pic_cap, 5, v_base - interval '8 days' - interval '12 hours', interval '90 minutes', 4, NULL, 'per_pax', 80000)
        ) AS t(idx, lobby_id, organizer, sport_id, start_at, dur, threshold, deadline_lead, ctype, camount)
    LOOP
        v_act := ('51072000-0000-4000-8000-' || lpad(rec.idx::text, 12, '0'))::uuid;
        INSERT INTO public.activity (
            id, user_id, sport_id, lobby_id, location_id,
            start_time, end_time, confirmation_threshold, confirmation_deadline,
            cost_type, cost_amount)
        VALUES (
            v_act, rec.organizer, rec.sport_id, rec.lobby_id,
            CASE rec.sport_id WHEN 1 THEN v_soc_loc ELSE v_pic_loc END,
            rec.start_at, rec.start_at + rec.dur,
            rec.threshold,
            CASE WHEN rec.deadline_lead IS NULL THEN NULL ELSE rec.start_at - rec.deadline_lead END,
            rec.ctype::public.activity_cost_type, rec.camount);
    END LOOP;
END
$shot$;

-- ── 2. RSVPs ────────────────────────────────────────────────────────────────
-- `activity_is_confirmed` is what decides whether a card reads "đã chốt", what
-- survives expire_past_activities(), and who a wall post may tag. The mix below
-- is deliberately NOT unanimous: a roster where everyone always says yes looks
-- synthetic, and `maybe`/`out` rows are what make the RSVP strip legible.
DO $shot$
DECLARE
    v_act uuid;
    v_u   uuid;
    rec   record;
    i     int;
BEGIN
    FOR rec IN
        SELECT * FROM (VALUES
            -- activity idx, going members (user idx), maybe, out
            (1, ARRAY[1,2,3,4,5,6], ARRAY[7],    ARRAY[8]),   -- 6/8 going -> confirmed (threshold 4)
            (2, ARRAY[1,3,5],       ARRAY[2,4],  ARRAY[]::int[]), -- 3/8 -> still gathering, under 4
            (3, ARRAY[1,2,3,4,5,7], ARRAY[]::int[], ARRAY[6]),    -- past, confirmed
            (4, ARRAY[1,2,4,5,6,8], ARRAY[]::int[], ARRAY[3]),    -- past, confirmed
            -- Pickleball: the hero is deliberately `maybe` so the member-side
            -- RSVP control is LIVE and un-padlocked when captured. A `going`
            -- row on a confirmed activity can no longer be changed
            -- (activity_confirmation_lock_after_confirmed).
            (5, ARRAY[57,58,59,60], ARRAY[1],    ARRAY[61]),
            (6, ARRAY[1,57,58,59,60], ARRAY[]::int[], ARRAY[61])  -- past, confirmed, hero attended
        ) AS t(act_idx, going, maybe_, out_)
    LOOP
        v_act := ('51072000-0000-4000-8000-' || lpad(rec.act_idx::text, 12, '0'))::uuid;

        FOREACH i IN ARRAY rec.going LOOP
            v_u := ('51070000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid;
            INSERT INTO public.activity_confirmation (activity_id, user_id, attendance)
            VALUES (v_act, v_u, 'going') ON CONFLICT DO NOTHING;
        END LOOP;

        FOREACH i IN ARRAY rec.maybe_ LOOP
            v_u := ('51070000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid;
            INSERT INTO public.activity_confirmation (activity_id, user_id, attendance)
            VALUES (v_act, v_u, 'maybe') ON CONFLICT DO NOTHING;
        END LOOP;

        FOREACH i IN ARRAY rec.out_ LOOP
            v_u := ('51070000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid;
            INSERT INTO public.activity_confirmation (activity_id, user_id, attendance)
            VALUES (v_act, v_u, 'out') ON CONFLICT DO NOTHING;
        END LOOP;
    END LOOP;
END
$shot$;

-- ── 3. Lobby action-stream (shot 3) ─────────────────────────────────────────
-- Payload shapes are enforced by `lobby_feed_item_payload_shape` and parsed by
-- lib/manage_tab/lobby_section/activity/feed.dart — the canonical reference:
--   update   -> title, kind (UpdateKind.db), tone (FeedTone.name), fields [[label, value], …]
--   personal -> action_kind (PersonalActionKind.db); `note` additionally REQUIRES
--               activity_id + a 1–72 char `detail` (lobby_feed_item_activity_note_shape)
--   poll     -> question, options [label, …], total_members, deadline (a label, not a timestamp)
-- `photo` is deliberately absent: it is retired as a writable kind, and the
-- feed unions `wall_post` rows for photos instead.
DO $shot$
DECLARE
    c_soccer CONSTANT uuid := '51071000-0000-4000-8000-000000000001'::uuid;
    c_a1     CONSTANT uuid := '51072000-0000-4000-8000-000000000001'::uuid;
    c_a3     CONSTANT uuid := '51072000-0000-4000-8000-000000000003'::uuid;
    rec      record;
BEGIN
    FOR rec IN
        SELECT * FROM (VALUES
            -- idx, author idx, kind, activity, age, payload
            (1, 1, 'update', c_a1, interval '3 days',
                 jsonb_build_object(
                   'title', 'Đã lên lịch buổi đá tối thứ 6',
                   'kind',  'scheduled',
                   'tone',  'blue',
                   'fields', jsonb_build_array(
                       jsonb_build_array('Sân',      'Sân vận động Gia Định'),
                       jsonb_build_array('Giờ',      '19:30 – 21:30'),
                       jsonb_build_array('Chi phí',  '50.000đ / người')))),
            (2, 3, 'personal', NULL, interval '2 days 4 hours',
                 jsonb_build_object('action_kind', 'come_early')),
            (3, 4, 'personal', NULL, interval '2 days 1 hour',
                 jsonb_build_object('action_kind', 'offer_lift')),
            -- `note` is the one personal action with a hard payload contract:
            -- it needs an activity_id and a 1–72 char detail string.
            (4, 5, 'personal', c_a1, interval '1 day 20 hours',
                 jsonb_build_object('action_kind', 'note',
                                    'detail', 'Mang áo sáng màu nha anh em, đội kia áo tối.')),
            (5, 6, 'personal', NULL, interval '1 day 6 hours',
                 jsonb_build_object('action_kind', 'bring_gear')),
            (6, 1, 'poll', NULL, interval '22 hours',
                 jsonb_build_object(
                   'question', 'Tuần sau đá thứ 6 hay thứ 7?',
                   'options', jsonb_build_array('Thứ 6, 19:30', 'Thứ 7, 17:00'),
                   'total_members', 8,
                   'deadline', 'Trong 24 giờ')),
            (7, 2, 'personal', NULL, interval '9 hours',
                 jsonb_build_object('action_kind', 'cheer')),
            -- A past session's own entry, so scrolling back looks lived-in.
            (8, 1, 'update', c_a3, interval '5 days 6 hours',
                 jsonb_build_object(
                   'title', 'Đổi sân buổi tối thứ 2',
                   'kind',  'venue_changed',
                   'tone',  'amber',
                   'fields', jsonb_build_array(
                       jsonb_build_array('Sân mới', 'Sân vận động Gia Định'))))
        ) AS t(idx, author_idx, kind, activity_id, age, payload)
    LOOP
        INSERT INTO public.lobby_feed_item (id, lobby_id, author_id, kind, payload, activity_id, created_at)
        VALUES (
            ('51073000-0000-4000-8000-' || lpad(rec.idx::text, 12, '0'))::uuid,
            c_soccer,
            ('51070000-0000-4000-8000-' || lpad(rec.author_idx::text, 12, '0'))::uuid,
            rec.kind::public.lobby_feed_item_kind,
            rec.payload,
            rec.activity_id,
            now() - rec.age);
    END LOOP;
END
$shot$;
