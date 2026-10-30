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

-- Payees first: their FK to the feed item may not cascade, and a stale payee
-- row would re-attach to a regenerated request with the same sentinel id.
DELETE FROM public.lobby_payment_request_payee
WHERE feed_item_id::text LIKE '51073%' OR user_id::text LIKE '5107%';

DELETE FROM public.lobby_feed_item WHERE id::text LIKE '51073%';

-- `fn_emit_activity_scheduled` / `fn_emit_activity_confirmed` fire on the
-- inserts below and enqueue outbox rows. Every recipient is a seeded user, so
-- scoping by recipient is exact and cannot touch a real user's notifications.
DELETE FROM public.notification_outbox WHERE recipient_user_id::text LIKE '5107%';

DELETE FROM public.activity_confirmation
WHERE activity_id::text LIKE '51072%' OR user_id::text LIKE '5107%';

-- Wall posts get server-generated uuids (create_wall_post is the write path,
-- so the sentinel scheme can't reach them). Scoping by author is exact: every
-- author here is a seeded user. Tags/reactions cascade from the post.
-- Challenge rows. The offer's own trigger retires its Planner fixture, and the
-- activity delete below clears anything left; challenges cascade from the offer.
DELETE FROM public.lobby_challenge
 WHERE initiator_lobby_id::text LIKE '51071%' OR target_lobby_id::text LIKE '51071%';
DELETE FROM public.lobby_challenge_offer WHERE lobby_id::text LIKE '51071%';

DELETE FROM public.wall_post WHERE author_id::text LIKE '5107%';

-- Health + course + achievements. All keyed to seeded users, so scoping by
-- user id is exact.
DELETE FROM public.activity_hr_sample     WHERE activity_id::text LIKE '51072%';
DELETE FROM public.activity_health_metrics WHERE user_id::text LIKE '5107%';
DELETE FROM public.user_achievement     WHERE user_id::text LIKE '5107%';
DELETE FROM public.daily_health_summary WHERE user_id::text LIKE '5107%';
DELETE FROM public.user_health_link     WHERE user_id::text LIKE '5107%';
DELETE FROM public.course_member        WHERE user_id::text LIKE '5107%';
DELETE FROM public.conversation_member  WHERE user_id::text LIKE '5107%';

DELETE FROM public.activity WHERE id::text LIKE '51072%';

-- Freeplay rows: freeplay_activity is keyed by activity_id so it goes with the
-- activity delete above, but the host profile is its own row.
DELETE FROM public.freeplay_host WHERE id::text LIKE '51074%';

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
            -- A3 sits INSIDE the 7-day window on purpose: create_wall_post only
            -- accepts an activity that started in the last 7 days and which the
            -- author RSVP'd `going` to. A4 is deliberately outside it, so the
            -- health tab has history that the Feed cannot post against.
            (3, c_soccer, c_hero,    1, v_base - interval '5 days',  interval '2 hours', 4, NULL,                'per_pax', 50000),
            (4, c_soccer, c_hero,    1, v_base - interval '12 days', interval '2 hours', 4, NULL,                'per_pax', 50000),
            -- A5: pickleball, organised by ITS captain, not the hero — this is
            -- the member-side RSVP surface.
            (5, c_pickle, v_pic_cap, 5, v_base + interval '3 days' - interval '12 hours', interval '90 minutes', 4, interval '36 hours', 'per_pax', 80000),
            (6, c_pickle, v_pic_cap, 5, v_base - interval '3 days' - interval '12 hours', interval '90 minutes', 4, NULL, 'per_pax', 80000)
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
                   -- Options are OBJECTS with a `label`, not bare strings:
                   -- feed.dart does `(raw as Map<String, dynamic>)['label']`.
                   -- The payload CHECK only requires the `options` key to
                   -- exist, so the DB happily accepts bare strings and the
                   -- client then throws mid-iteration -- which wipes out the
                   -- ENTIRE feed, not just the poll card.
                   'options', jsonb_build_array(
                       jsonb_build_object('label', 'Thứ 6, 19:30'),
                       jsonb_build_object('label', 'Thứ 7, 17:00')),
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

-- user_payment_info IS DELIBERATELY NOT SEEDED. DO NOT ADD IT.
--   The QR sheet builds a LIVE image from
--   img.vietqr.io/image/<bin>-<account>-compact2.png. A fictional bin renders a
--   broken QR; a real bin renders a genuinely SCANNABLE one encoding that bank
--   plus whatever account number is seeded -- and a screenshot of a scannable
--   QR is a transfer target. If that number ever collided with a real account,
--   someone scanning the storefront image could send money to a stranger.
--   Decision: seed nothing. payRecipient (lib/core/payment/pay_recipient.dart)
--   already degrades to a toast when a recipient has no payment info, so the
--   split card still renders in full -- amounts, payees, paid/outstanding --
--   and only the pay action no-ops. Real details can be entered by hand at
--   capture time if a transfer surface is ever genuinely wanted in frame.
-- ── 4. Bill splitting (shot 4) ──────────────────────────────────────────────
-- The website's own claim is "Passe chia phần. Ngân hàng chuyển tiền." — this
-- is the "chia phần" half. The bank half is `user_payment_info`, seeded
-- separately because it needs a decision about naming a real bank (see below).
--
-- Payload and payee shape mirror `fn_sweep_activity_payment_requests` exactly,
-- so a hand-authored request renders identically to a swept one. Two details
-- read off the LIVE function, not the checked-in file (which is stale here):
--   * payees are inserted WITHOUT recipient_id — a BEFORE trigger
--     (`fn_fill_payment_request_recipient`) fills it from the payload.
--   * the sweep cannot collide with these rows: it only considers activities
--     whose end_time is inside the last DAY and which have manager_confirmed_at
--     set. Ours are 5–12 days old with it null, so nothing will be
--     double-created, and nothing will pop up mid-shoot.
--
-- Two requests, deliberately pointing opposite ways, because the payer view and
-- the collector view are different screens:
--   R1 — the hero COLLECTS (he fronted the pitch fee). Mixed payee statuses, so
--        the sheet shows both "đã trả" and "còn nợ" rather than a uniform list.
--   R2 — the hero OWES someone else, which is the only way to reach the payer
--        side (and the QR/transfer surface) from his own account.
DO $shot$
DECLARE
    c_soccer CONSTANT uuid := '51071000-0000-4000-8000-000000000001'::uuid;
    c_hero   CONSTANT uuid := '51070000-0000-4000-8000-000000000001'::uuid;
    c_u2     CONSTANT uuid := '51070000-0000-4000-8000-000000000002'::uuid;
    c_a3     CONSTANT uuid := '51072000-0000-4000-8000-000000000003'::uuid;
    c_a4     CONSTANT uuid := '51072000-0000-4000-8000-000000000004'::uuid;
    rec      record;
    v_fi     uuid;
    v_u      uuid;
    i        int;
BEGIN
    FOR rec IN
        SELECT * FROM (VALUES
            -- idx, source activity, recipient, per-person, age,
            --   payees paid_direct, payees outstanding
            (9,  c_a3, c_hero, 50000, interval '4 days 20 hours',
                 ARRAY[2,3], ARRAY[4,5,7]),
            (10, c_a4, c_u2,   50000, interval '11 days 20 hours',
                 ARRAY[4,5],  ARRAY[1,6,8])
        ) AS t(idx, src_activity, recipient, per_person, age, paid, outstanding)
    LOOP
        v_fi := ('51073000-0000-4000-8000-' || lpad(rec.idx::text, 12, '0'))::uuid;

        INSERT INTO public.lobby_feed_item (id, lobby_id, author_id, kind, payload, created_at)
        VALUES (
            v_fi, c_soccer, rec.recipient, 'payment_request',
            jsonb_build_object(
                'type',               'split',
                'source_activity_id', rec.src_activity,
                'recipient_id',       rec.recipient,
                'cost_type',          'per_pax',
                'total_amount',       rec.per_person,
                'per_person_amount',  rec.per_person),
            now() - rec.age);

        FOREACH i IN ARRAY rec.paid LOOP
            v_u := ('51070000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid;
            INSERT INTO public.lobby_payment_request_payee
                (feed_item_id, user_id, amount_owed, status, paid_at)
            VALUES (v_fi, v_u, rec.per_person, 'paid_direct', now() - rec.age + interval '6 hours');
        END LOOP;

        FOREACH i IN ARRAY rec.outstanding LOOP
            v_u := ('51070000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid;
            INSERT INTO public.lobby_payment_request_payee
                (feed_item_id, user_id, amount_owed, status)
            VALUES (v_fi, v_u, rec.per_person, 'outstanding');
        END LOOP;
    END LOOP;
END
$shot$;

-- ── 5. Freeplay listings (shot 10, player side) ─────────────────────────────
-- Discover ▸ Kèo is now a first-class subtab. The hero is a BUYER here, so
-- every listing belongs to someone he is not a member of — otherwise the seat
-- CTA is replaced by owner controls and the shot becomes the wrong screen.
--
-- A listing is an `activity` plus a 1:1 `freeplay_activity` row. Two ownership
-- shapes exist and both are seeded, because the feed renders them identically
-- but resolves identity differently (`coalesce(h.display_name, l.name)`):
--   * LOBBY-owned: the activity keeps `lobby_id`, `freeplay_host_id` stays
--     NULL, and there is deliberately NO phantom `freeplay_host` row — see
--     schema/lobby_freeplay_exposure.sql. Capacity means seats for OUTSIDERS,
--     counted independently of member RSVPs.
--   * HOST-owned: a real `freeplay_host` row, `freeplay_host_id` set and
--     `lobby_id` NULL (activity_source_exclusivity forbids both).
--
-- No `freeplay_request` rows are seeded: a pending seat request would put the
-- hero in a mid-handshake state, and the shot wants the browse/join CTA live.
-- Host display name follows the structure seed's rule — fictional, not merely
-- invented.
DO $shot$
DECLARE
    c_host_u  CONSTANT uuid := '51070000-0000-4000-8000-000000000047'::uuid;
    c_host    CONSTANT uuid := '51074000-0000-4000-8000-000000000001'::uuid;
    rec       record;
    v_act     uuid;
    v_loc     uuid;
    v_lobby   uuid;
    v_today   date;
    v_start   timestamptz;
BEGIN
    -- The one host-owned listing needs a host profile.
    INSERT INTO public.freeplay_host (id, user_id, display_name, bio, status)
    VALUES (c_host, c_host_u, 'Sân Chiều Thứ Bảy',
            'Giữ sân cố định chiều thứ 7, nhận thêm người lẻ cho đủ đội.', 'active')
    ON CONFLICT (id) DO UPDATE SET display_name = EXCLUDED.display_name, bio = EXCLUDED.bio;

    FOR rec IN
        SELECT * FROM (VALUES
            -- idx, owning lobby idx (NULL = host-owned), sport, ISO dow, hour, minute,
            --   dur, capacity, male price, female price, skills, description
            --
            -- Days/times are NOT arbitrary. Discover's filter preloads the
            -- hero's own playtime (DiscoverFilterController.build reads
            -- user.details.playtime), and home_freeplay_data filters the
            -- listing's OWN start_time against it, deriving the chunk as
            -- <9 early, <14 midday, <18 noon, else night — all in ICT. The
            -- hero's playtime is mon/wed/fri night + sat noon, so a listing
            -- outside those slots is invisible on the default filter. An
            -- earlier pass put these on Thu/Sun and the feed came back EMPTY.
            (1, 2,    1, 5, 19, 30, interval '2 hours', 4, 60000, 40000,
                ARRAY['casual','fair'],
                'Thiếu 4 người cho kèo tối thứ 6, sân cỏ nhân tạo, có đèn.'),
            (2, 3,    1, 3, 19, 30, interval '2 hours', 3, 70000, 50000,
                ARRAY['fair','good'],
                'Kèo tối thứ 4 hàng tuần, cần thêm 3 chân. Đá vui, không ăn thua.'),
            (3, NULL, 1, 6, 16,  0, interval '2 hours', 6, 50000, 50000,
                ARRAY['beginner','casual'],
                'Sân giữ cố định chiều thứ 7, nhận người lẻ. Ai mới chơi cũng được.')
        ) AS t(idx, lobby_idx, sport_id, dow, hh, mi, dur, capacity, m_price, f_price, skills, descr)
    LOOP
        v_act := ('51072000-0000-4000-8000-' || lpad((100 + rec.idx)::text, 12, '0'))::uuid;

        -- Next occurrence of rec.dow at rec.hh:rec.mi ICT, strictly future.
        v_today := (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date;
        v_start := ((v_today + (((rec.dow - extract(isodow FROM v_today)::int) + 7) % 7))
                     + make_time(rec.hh, rec.mi, 0)) AT TIME ZONE 'Asia/Ho_Chi_Minh';
        IF v_start <= now() THEN
            v_start := v_start + interval '7 days';
        END IF;

        IF rec.lobby_idx IS NULL THEN
            v_lobby := NULL;
            -- Host-owned: borrow a real public venue for the address fields.
            SELECT id INTO v_loc FROM public.location
            WHERE city_cluster = 1 AND is_verified AND name = 'Sân vận động Hoa Lư' LIMIT 1;
        ELSE
            v_lobby := ('51071000-0000-4000-8000-' || lpad(rec.lobby_idx::text, 12, '0'))::uuid;
            SELECT location_id INTO v_loc FROM public.lobby_homeground
            WHERE lobby_id = v_lobby AND is_primary;
        END IF;

        INSERT INTO public.activity (
            id, user_id, sport_id, lobby_id, freeplay_host_id, location_id, start_time, end_time)
        VALUES (
            v_act,
            CASE WHEN rec.lobby_idx IS NULL
                 THEN c_host_u
                 ELSE (SELECT captain_id FROM public.lobby WHERE id = v_lobby) END,
            rec.sport_id, v_lobby,
            CASE WHEN rec.lobby_idx IS NULL THEN c_host ELSE NULL END,
            v_loc, v_start, v_start + rec.dur);

        INSERT INTO public.freeplay_activity (
            activity_id, description, capacity, male_price, female_price,
            recommended_skills, venue_name, city_cluster, ward)
        SELECT v_act, rec.descr, rec.capacity, rec.m_price, rec.f_price, rec.skills,
               l.name, l.city_cluster, l.district
        FROM public.location l WHERE l.id = v_loc;
    END LOOP;
END
$shot$;

-- ── 6. Wall posts (Feed, tab 1) ─────────────────────────────────────────────
-- RUN tool/shot_upload_media.sh FIRST. `wall_post.media` is NOT NULL and
-- `fn_valid_wall_post_media` only checks that each entry has a non-empty
-- `path` — it cannot know whether the object exists. A post pointing at a
-- missing object renders a BROKEN IMAGE, which is worse than an empty tab.
--
-- Why this matters beyond the shot: Feed is tab 1, so it is the first thing an
-- App Review tester sees on opening the app. An empty or broken first screen is
-- App Completeness exposure, which is the whole reason the demo account exists.
--
-- These go through `create_wall_post` as each author rather than being INSERTed
-- directly, so the real rules apply and the snapshot columns
-- (source_label/source_start_time/source_venue_name) are filled the same way a
-- genuine post fills them. The function only accepts an activity that started
-- in the last 7 days which the AUTHOR RSVP'd `going` to, and allows one post
-- per author per session — which is exactly why A6 sits 3 days back, not 8.
--
-- Authors are mixed on purpose. Feed visibility is self + author's friends +
-- author's lobby mates + anyone tagged + friends of anyone tagged, so posts by
-- a friend (user 3) and a pickleball lobby mate (user 58) prove two different
-- edges of fn_can_see_wall_post, and the feed is cross-sport as designed.
--
-- Captions follow the structure seed's naming rule: fictional, not merely
-- invented, and no brand names.

BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims = '{"sub":"51070000-0000-4000-8000-000000000001","role":"authenticated"}';
SELECT public.create_wall_post(
    '51072000-0000-4000-8000-000000000003'::uuid,
    '[{"type":"image","path":"51070000-0000-4000-8000-000000000001/shot_soccer1.jpg"}]'::jsonb,
    'Tối thứ 2 ở sân quen. Cú vô lê cuối trận trượt trong gang tấc 😂',
    7::smallint,
    ARRAY['51070000-0000-4000-8000-000000000003',
          '51070000-0000-4000-8000-000000000005']::uuid[]);
COMMIT;

BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims = '{"sub":"51070000-0000-4000-8000-000000000003","role":"authenticated"}';
SELECT public.create_wall_post(
    '51072000-0000-4000-8000-000000000003'::uuid,
    '[{"type":"image","path":"51070000-0000-4000-8000-000000000003/shot_soccer2.jpg"}]'::jsonb,
    'Đá xong còn kịp ngồi trà đá. Tuần sau chơi tiếp nhé anh em.',
    7::smallint,
    ARRAY['51070000-0000-4000-8000-000000000001']::uuid[]);
COMMIT;

BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims = '{"sub":"51070000-0000-4000-8000-000000000001","role":"authenticated"}';
SELECT public.create_wall_post(
    '51072000-0000-4000-8000-000000000006'::uuid,
    '[{"type":"image","path":"51070000-0000-4000-8000-000000000001/shot_pickleball1.jpg"}]'::jsonb,
    'Đổi gió sang pickleball sáng nay. Mới tập mà vui phết.',
    7::smallint,
    ARRAY['51070000-0000-4000-8000-000000000058']::uuid[]);
COMMIT;

BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims = '{"sub":"51070000-0000-4000-8000-000000000058","role":"authenticated"}';
SELECT public.create_wall_post(
    '51072000-0000-4000-8000-000000000006'::uuid,
    '[{"type":"image","path":"51070000-0000-4000-8000-000000000058/shot_pickleball2.jpg"}]'::jsonb,
    'Sân sáng cuối tuần, bóng vàng nắng vàng. Ai rảnh mai đánh tiếp không?',
    7::smallint,
    ARRAY['51070000-0000-4000-8000-000000000001']::uuid[]);
COMMIT;

-- ── 7. Coaching course (shot 6) ─────────────────────────────────────────────
-- The hero enrols in an EXISTING democoach course rather than a new synthetic
-- one: schema/demo_coach_seed.sql already dresses those coaches with
-- availability, rosters, reviews and a thread, so joining one inherits all of
-- it instead of re-faking it. "One enrolled coach per sport" is a partial
-- unique index, so this only works because the hero has no other soccer course.
DO $shot$
DECLARE
    c_hero   CONSTANT uuid := '51070000-0000-4000-8000-000000000001'::uuid;
    c_course CONSTANT uuid := 'e8032b9c-3e36-45f1-9f37-2b94e612126f'::uuid; -- Kỹ thuật nền tảng bóng đá
    c_pro    CONSTANT uuid := '85e2282d-a7bd-4631-9e1e-ae987b3059d5'::uuid;
    v_act    uuid := '51072000-0000-4000-8000-000000000201'::uuid;
    v_today  date := (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date;
    v_start  timestamptz;
BEGIN
    INSERT INTO public.course_member (course_id, user_id, status, professional_id, sport_id, joined_at)
    VALUES (c_course, c_hero, 'enrolled', c_pro, 1, now() - interval '26 days')
    ON CONFLICT (course_id, user_id) DO UPDATE SET status = EXCLUDED.status;

    -- The thread's membership too. `fn_course_add_member` writes both rows on
    -- the real enrol path; a bare course_member row leaves the hero outside
    -- `conversation_member` (the messaging visibility floor), so
    -- `conversation_data` raises "conversation not found" and the Feed tab
    -- shows a load error over a closed composer. Same joined_at, so the
    -- floor hides only what predates the enrolment.
    INSERT INTO public.conversation_member (conversation_id, user_id, joined_at)
    SELECT cv.id, c_hero, now() - interval '26 days'
    FROM public.conversation cv WHERE cv.course_id = c_course
    ON CONFLICT (conversation_id, user_id) DO UPDATE SET left_at = NULL;

    -- Next Tuesday 18:00 ICT: a coach-proposed session is born `approved`
    -- (only the coach approves), so it reads as a confirmed upcoming lesson.
    v_start := ((v_today + (((2 - extract(isodow FROM v_today)::int) + 7) % 7))
                 + make_time(18, 0, 0)) AT TIME ZONE 'Asia/Ho_Chi_Minh';
    IF v_start <= now() THEN v_start := v_start + interval '7 days'; END IF;

    INSERT INTO public.activity (
        id, user_id, sport_id, course_id, proposal_status, proposed_by,
        location_id, start_time, end_time)
    SELECT v_act,
           (SELECT linked_user_id FROM public.professional WHERE id = c_pro),
           1, c_course, 'approved',
           (SELECT linked_user_id FROM public.professional WHERE id = c_pro),
           (SELECT location_id FROM public.lobby_homeground
             WHERE lobby_id = '51071000-0000-4000-8000-000000000001'::uuid AND is_primary),
           v_start, v_start + interval '90 minutes'
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.activity_confirmation (activity_id, user_id, attendance)
    VALUES (v_act, c_hero, 'going') ON CONFLICT DO NOTHING;
END
$shot$;

-- ── 8. Health (shots 7 and 8) ───────────────────────────────────────────────
-- The Health tab is gated on LINK STATUS, not on data: HealthController calls
-- requestAuthorization and renders HealthNotLinkedView unless it comes back
-- granted. Seeding `user_health_link` is necessary but NOT sufficient — the
-- capture device must also grant HealthKit once (see docs/app_store_shots.md).
--
-- Seeding the rollup tables directly is safe against the sync engine:
-- _syncDailySummaries BREAKS on the first day the device can't read, so an
-- empty simulator store stops immediately rather than overwriting these rows
-- with zeroes.
--
-- Achievements are seeded directly because `user_achievement` has NO triggers —
-- verified, not assumed — so shot 8 does not depend on the HealthKit injector.
-- Nothing maintains user.xp/level from that table either, so both are set here.
-- Deterministic noise in [0, 1) for (day, channel): the classic shader hash.
-- A pg_temp function so the seed leaves nothing behind in the schema; Postgres
-- never resolves functions from pg_temp implicitly, hence the qualified calls.
CREATE OR REPLACE FUNCTION pg_temp.fract_hash(p_day int, p_channel int)
RETURNS double precision LANGUAGE sql IMMUTABLE AS $$
    SELECT x - floor(x)
    FROM (SELECT sin(p_day * 12.9898 + p_channel * 78.233) * 43758.5453 AS x) h
$$;

DO $shot$
DECLARE
    c_hero CONSTANT uuid := '51070000-0000-4000-8000-000000000001'::uuid;
    d      date;
    v_xp   bigint := 0;
    rec    record;
    v_play boolean;  -- a session day: the hero plays every third evening
    v_wkd  boolean;
    v_hr   double precision;
    v_hrv  double precision;
    v_stp  double precision;
    v_wt   double precision;
BEGIN
    INSERT INTO public.user_health_link (user_id, platform, linked_at, last_sync_at,
                                         max_heart_rate, lt1_bpm, lt2_bpm)
    VALUES (c_hero, 'apple_health', now() - interval '92 days', now() - interval '20 minutes',
            191, 148, 171)
    ON CONFLICT (user_id) DO UPDATE
      SET last_sync_at = EXCLUDED.last_sync_at,
          max_heart_rate = EXCLUDED.max_heart_rate,
          lt1_bpm = EXCLUDED.lt1_bpm, lt2_bpm = EXCLUDED.lt2_bpm;

    -- 90 days of daily rollups: a slow trend + a weekly rhythm + small noise.
    -- The noise is a deterministic hash of the day number, not random(), so a
    -- re-run reproduces the same charts. Each metric's noise is kept well under
    -- its 90-day trend — the old `(i * k) % n` generator zig-zagged HRV by
    -- 11 ms every single day against a 3 ms trend, burying the story.
    -- i is days AGO, so `+ i * slope` makes older days worse (fitter today).
    FOR i IN 0 .. 89 LOOP
        d      := ((now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date - i);
        v_play := i % 3 = 0;
        v_wkd  := extract(isodow FROM d) >= 6;
        -- Resting HR: 63 → 57 bpm, ±1 bpm noise, a touch higher the morning
        -- after a session.
        v_hr  := 57 + i * 0.065
                 + (pg_temp.fract_hash(i, 1) - 0.5) * 2
                 + CASE WHEN i % 3 = 2 THEN 0.8 ELSE 0 END;
        -- HRV: 49 → 58 ms, ±3 ms noise, dipping the morning after a session.
        v_hrv := 58 - i * 0.1
                 + (pg_temp.fract_hash(i, 2) - 0.5) * 6
                 - CASE WHEN i % 3 = 2 THEN 3 ELSE 0 END;
        -- Steps: ~8.5k weekdays, ~11k weekends, +2.5k on a session day.
        v_stp := 8500
                 + CASE WHEN v_wkd THEN 2500 ELSE 0 END
                 + CASE WHEN v_play THEN 2500 ELSE 0 END
                 + (pg_temp.fract_hash(i, 3) - 0.5) * 1800;
        -- Weight: 72.6 → 71.4 kg, ±0.15 kg noise.
        v_wt  := 71.4 + i * 0.013 + (pg_temp.fract_hash(i, 4) - 0.5) * 0.3;

        INSERT INTO public.daily_health_summary (
            user_id, date, steps, distance_meters, active_calories,
            total_activity_minutes, activity_count,
            resting_heart_rate, hrv_sdnn_ms, sleep_minutes, weight_kg, synced_at)
        VALUES (
            c_hero, d,
            round(v_stp),
            round(v_stp * 0.72),
            round(320 + (v_stp - 8500) * 0.04
                  + CASE WHEN v_play THEN 380 ELSE 0 END
                  + (pg_temp.fract_hash(i, 5) - 0.5) * 60),
            CASE WHEN v_play THEN 95 + round(pg_temp.fract_hash(i, 6) * 20)
                 ELSE 25 + round(pg_temp.fract_hash(i, 6) * 15) END,
            CASE WHEN v_play THEN 1 ELSE 0 END,
            round(v_hr),
            round(v_hrv::numeric, 1),
            round(415 + (pg_temp.fract_hash(i, 7) - 0.5) * 50
                  + CASE WHEN v_wkd THEN 30 ELSE 0 END),
            round(v_wt::numeric, 1),
            now() - interval '20 minutes')
        ON CONFLICT (user_id, date) DO UPDATE
          SET steps = EXCLUDED.steps, distance_meters = EXCLUDED.distance_meters,
              active_calories = EXCLUDED.active_calories,
              total_activity_minutes = EXCLUDED.total_activity_minutes,
              activity_count = EXCLUDED.activity_count,
              resting_heart_rate = EXCLUDED.resting_heart_rate,
              hrv_sdnn_ms = EXCLUDED.hrv_sdnn_ms,
              sleep_minutes = EXCLUDED.sleep_minutes, weight_kg = EXCLUDED.weight_kg,
              synced_at = EXCLUDED.synced_at;
    END LOOP;

    -- Badges: a believable mix of early + mid-tier, not a full set.
    FOR rec IN
        SELECT a.id, a.xp_reward, ord
        FROM (VALUES ('first_session',1),('first_10k_day',2),('distance_50k',3),
                     ('active_days_30',4),('first_post',5),('first_hard_hour',6)) AS v(code, ord)
        JOIN public.achievement a ON a.code = v.code
    LOOP
        INSERT INTO public.user_achievement (user_id, achievement_id, period_key, xp_granted, earned_at)
        VALUES (c_hero, rec.id, 'all', rec.xp_reward, now() - (rec.ord * interval '9 days'))
        ON CONFLICT DO NOTHING;
        v_xp := v_xp + rec.xp_reward;
    END LOOP;

    UPDATE public."user"
       SET xp = v_xp, level = GREATEST(1, (v_xp / 250) + 1)
     WHERE id = c_hero;
END
$shot$;

-- ── 9. Friendly challenges (shot 5) ─────────────────────────────────────────
-- Written LAST on purpose: this area took 5 commits in 7 days while the rest of
-- the seed was being built (friendly_challenge_followups.sql alone is 1128
-- lines), so anything written against an older shape would have rotted.
--
-- Challenger ships as the FRIENDLY, referee-free mode. `challengerFlow` now
-- gates only the refereed variant, so everything below is reachable in the
-- default build with no dart-define. Nothing here creates a referee_booking.
--
-- Every row goes through the real RPCs as a real manager, never a raw INSERT:
-- `publish_challenge_offer` also creates the home side's Planner fixture,
-- RSVPs the publisher and posts a `challenge_offered` feed item, and
-- `send_friendly_challenge` auto-RSVPs the sender and posts
-- `challenge_gathering`. Hand-inserting the rows would skip all of that and
-- leave a half-built fixture that reads wrong on the card.
--
-- Shape: three OTHER lobbies advertise fixtures, which is what Discover ▸
-- Thách đấu shows the hero; then the hero's own lobby advertises one and takes
-- an incoming challenger, which is what the in-lobby chooser shows. Kickoffs
-- sit on Fri/Sat evenings so they read as real weekend fixtures.
--
-- `fn_lobbies_share_manager` blocks two lobbies with a shared captain or
-- coordinator from meeting — every seeded lobby has its own captain, so this
-- pairing is legal.

-- Bình Thạnh United (captain = user 9)
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims = '{"sub":"51070000-0000-4000-8000-000000000009","role":"authenticated"}';
SELECT public.publish_challenge_offer(
  '51071000-0000-4000-8000-000000000002'::uuid, 1::smallint,
  ((date_trunc('day', now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date
    + (((5 - extract(isodow FROM (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date)::int) + 7) % 7 + 7)
    + make_time(19, 30, 0)) AT TIME ZONE 'Asia/Ho_Chi_Minh'),
  (SELECT location_id FROM public.lobby_homeground
    WHERE lobby_id = '51071000-0000-4000-8000-000000000002' AND is_primary),
  now() + interval '4 days',
  600000, 'split_even', 'none', NULL, 'standard', NULL, 'none', NULL,
  'Sân 7 cỏ nhân tạo, chia đôi tiền sân. Đá đẹp, không tiểu xảo.',
  'friendly',
  ((date_trunc('day', now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date
    + (((5 - extract(isodow FROM (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date)::int) + 7) % 7 + 7)
    + make_time(21, 30, 0)) AT TIME ZONE 'Asia/Ho_Chi_Minh'));
COMMIT;

-- Sài Gòn Night FC (captain = user 16)
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims = '{"sub":"51070000-0000-4000-8000-000000000016","role":"authenticated"}';
SELECT public.publish_challenge_offer(
  '51071000-0000-4000-8000-000000000003'::uuid, 1::smallint,
  ((date_trunc('day', now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date
    + (((6 - extract(isodow FROM (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date)::int) + 7) % 7 + 7)
    + make_time(17, 0, 0)) AT TIME ZONE 'Asia/Ho_Chi_Minh'),
  (SELECT location_id FROM public.lobby_homeground
    WHERE lobby_id = '51071000-0000-4000-8000-000000000003' AND is_primary),
  now() + interval '5 days',
  700000, 'loser_pays', 'none', NULL, 'standard', NULL, 'none', NULL,
  'Kèo chiều thứ 7. Đội thua trả tiền sân, vui là chính.',
  'friendly',
  ((date_trunc('day', now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date
    + (((6 - extract(isodow FROM (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date)::int) + 7) % 7 + 7)
    + make_time(19, 0, 0)) AT TIME ZONE 'Asia/Ho_Chi_Minh'));
COMMIT;

-- Cựu Sinh Viên FC (captain = user 22)
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims = '{"sub":"51070000-0000-4000-8000-000000000022","role":"authenticated"}';
SELECT public.publish_challenge_offer(
  '51071000-0000-4000-8000-000000000004'::uuid, 1::smallint,
  ((date_trunc('day', now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date
    + (((5 - extract(isodow FROM (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date)::int) + 7) % 7 + 14)
    + make_time(20, 0, 0)) AT TIME ZONE 'Asia/Ho_Chi_Minh'),
  (SELECT location_id FROM public.lobby_homeground
    WHERE lobby_id = '51071000-0000-4000-8000-000000000004' AND is_primary),
  now() + interval '9 days',
  500000, 'split_even', 'none', NULL, 'standard', NULL, 'none', NULL,
  'Anh em cựu sinh viên giao lưu, trình độ vừa phải.',
  'friendly',
  ((date_trunc('day', now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date
    + (((5 - extract(isodow FROM (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date)::int) + 7) % 7 + 14)
    + make_time(22, 0, 0)) AT TIME ZONE 'Asia/Ho_Chi_Minh'));
COMMIT;

-- ── 10. Per-activity health metrics (Health ▸ recap) ────────────────────────
-- Section 8 fills the DAILY rollups, which is what the trends charts read. The
-- recap subtab reads `activity_health_metrics` (via the activity_health_data
-- RPC) plus `activity_hr_sample` for the curve, and those were empty — so the
-- recap list rendered as an empty state next to a fully populated trends tab.
--
-- Only the hero's PAST sessions that he actually attended get a row: the sync
-- engine captures a confirmed activity the device can be queried for, so a
-- metrics row against a session he was `out` for would be a shape the app
-- cannot produce. Checked against activity_confirmation rather than assumed.
--
-- The three HR zones are easy/moderate/hard and must sum to roughly the
-- session's duration; they are derived from it rather than typed in, so a
-- re-anchored session keeps a coherent recap. `dismissed` stays false — true
-- is the tombstone for a detected workout the user waved away.
DO $shot$
DECLARE
    c_hero CONSTANT uuid := '51070000-0000-4000-8000-000000000001'::uuid;
    rec    record;
    v_secs int;
    v_easy int;
    v_mod  int;
    v_hard int;
    v_avg  int;
    v_j    bigint;
    t      timestamptz;
    i      int;
BEGIN
    FOR rec IN
        SELECT a.id, a.start_time, a.end_time, a.sport_id,
               GREATEST(EXTRACT(EPOCH FROM (a.end_time - a.start_time))::int, 1800) AS dur
        FROM public.activity a
        JOIN public.activity_confirmation ac
          ON ac.activity_id = a.id AND ac.user_id = c_hero AND ac.attendance = 'going'
        WHERE a.id::text LIKE '51072%'
          AND a.end_time < now()
        ORDER BY a.start_time
    LOOP
        v_secs := rec.dur;
        -- Per-session jitter, derived from the activity id so it is stable
        -- across re-runs. Without it two sessions of the same length came out
        -- byte-identical -- same bpm, kcal, steps, distance and effort -- which
        -- is the single most obvious tell that a recap list is fabricated.
        v_j := (('x' || substr(md5(rec.id::text), 1, 8))::bit(32)::bigint % 100);
        IF v_j < 0 THEN v_j := -v_j; END IF;

        -- A plausible pickup-football split: mostly moderate, a real but
        -- minority hard block, the rest easy. The hard share moves 13-23%.
        v_hard := (v_secs * (13 + (v_j % 11))) / 100;
        v_mod  := (v_secs * (42 + (v_j % 9))) / 100;
        v_easy := v_secs - v_hard - v_mod;
        v_avg  := CASE rec.sport_id WHEN 1 THEN 141 ELSE 126 END + (v_j % 13);

        INSERT INTO public.activity_health_metrics (
            user_id, activity_id, steps, distance_meters, active_calories,
            avg_heart_rate, max_heart_rate, min_heart_rate,
            hrv_sdnn_ms, hrv_rmssd_ms,
            hr_zone_easy_seconds, hr_zone_moderate_seconds, hr_zone_hard_seconds,
            training_load, effort_score, workout_type, recorded_at, dismissed)
        VALUES (
            c_hero, rec.id,
            (v_secs / 60) * (68 + (v_j % 19)),
            (v_secs / 60) * (48.0 + (v_j % 23)),
            (v_secs / 60) * (7.1 + ((v_j % 17) / 10.0)),
            v_avg, v_avg + 24 + (v_j % 11), 88 + (v_j % 9),
            38.0 + (v_j % 17), 33.0 + (v_j % 13),
            v_easy, v_mod, v_hard,
            (v_secs / 60) * 1.9,
            LEAST(99.0, 46.0 + (v_hard::numeric / NULLIF(v_secs,0)) * 180),
            CASE rec.sport_id WHEN 1 THEN 'soccer' ELSE 'pickleball' END,
            rec.end_time + interval '6 minutes', false)
        ON CONFLICT DO NOTHING;

        -- One sample a minute is plenty for the curve and keeps the seed small;
        -- the real capture downsamples too. Deterministic, so a re-run redraws
        -- the same curve rather than a different one.
        i := 0;
        t := rec.start_time;
        WHILE t < rec.end_time LOOP
            INSERT INTO public.activity_hr_sample (activity_id, "timestamp", bpm)
            VALUES (
                rec.id, t,
                (v_avg
                  + 22 * sin(i::numeric / 7.0)
                  + 9  * sin(i::numeric / 2.3)
                  - CASE WHEN i < 5 THEN 28 ELSE 0 END)::smallint)
            ON CONFLICT DO NOTHING;
            t := t + interval '1 minute';
            i := i + 1;
        END LOOP;
    END LOOP;
END
$shot$;
