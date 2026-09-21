-- ============================================================================
-- shot_seed_structure.sql — the STRUCTURAL half of the App Store screenshot /
-- clip dataset. Cast, lobbies, affiliations, sport profiles, friendships.
--
-- Pairs with schema/shot_seed_timeline.sql (activities, wall posts, friendly
-- challenges, payment requests, notifications, health rollups). The split is
-- deliberate:
--
--   * THIS file is slow-moving. Seed it once, leave it live until the build is
--     approved, then run the cleanup at the top on its own to remove it.
--   * The TIMELINE file is now()-relative and decays (wall posts hard-expire at
--     <= 7 days, past unconfirmed activities are deleted by
--     expire_past_activities() on every lobby-list load). Re-run it before each
--     capture session and again at submission.
--
-- Apply with the Supabase MCP `execute_sql` (runs as postgres -> bypasses RLS),
-- NOT `apply_migration` — this is data, not schema.
--
-- ── Identification ──────────────────────────────────────────────────────────
-- Every row this script creates carries a deterministic sentinel UUID with the
-- prefix `5107`, so cleanup and re-runs match on `id::text LIKE '5107%'`.
-- This is NOT how schema/mocked_seed.sql or schema/demo_coach_seed.sql work —
-- they prefix the *names* (`mocked_`, `democoach`). That is unusable here:
-- usernames, lobby names and venue names all render on screen, and a marketing
-- screenshot cannot show "mocked_Lobby". Sentinel ids buy fully realistic
-- names at no cost, and make this file idempotent via ON CONFLICT DO UPDATE.
--
--   users    51070000-0000-4000-8000-<12-digit index>
--   lobbies  51071000-0000-4000-8000-<12-digit index>
--
-- ── The hero ────────────────────────────────────────────────────────────────
-- Index 1. Signs in as  shothero@demo.passe  /  12345678  (same bcrypt hash as
-- demo_coach_seed.sql). This is also the App Store review demo account.
--   * male, ageGroup `mature`, Binh Thanh, HCMC
--   * soccer elo_seed `fair` (skill rank 2 — deliberately mid, so lobbies can
--     sit both above and below him)
--   * captain of one soccer lobby, plain member of one pickleball lobby
--   * networks: VNG Corporation (383, alumni=false -> the ACTIVE tie)
--               DH Bach khoa TP.HCM (193, alumni=true)
--   * industry: technology (17)
--
-- ── Districts: depends on the ward backfill having run ──────────────────────
--   `DiscoverFilterController.build()` (lib/discover_tab/filter_controller.dart)
--   seeds the filter from user.details.location.districts, and the teammate /
--   challenger / professional feeds send District *ids* (`hcm_binhthanh`) as
--   p_districts, compared against the homeground venue's `location.district`.
--
--   That only matches because of the venue overhaul: schema/location_ward_normalization.sql
--   plus the tool/venue backfill rewrite `location.district` from the scrape's
--   free text ("Quan Binh Thanh", "Phuong Thao Dien", blank) to the canonical
--   District.id, preserving the old value in `district_legacy`. Verified live:
--   754 of 997 HCMC rows now carry a ward id, and all 11 homegrounds below do.
--
--   BEFORE that backfill an id could never equal a legacy name, so any saved
--   district made the teammate feed return ZERO rows. If you ever see an empty
--   Discover feed with a district chip active, check `location.district` first —
--   it means the backfill was reverted or a venue moved to an un-normalized row.
--   Setting districts to '[]' short-circuits the filter (cardinality = 0) and is
--   the safe fallback.
--
-- ── Venues ──────────────────────────────────────────────────────────────────
-- Real directory rows only, resolved BY NAME at run time (never hardcoded
-- uuids), and only venues whose `sport_ids` actually contains the sport — a
-- soccer lobby gets a real pitch, a pickleball lobby a real court. Binh Thanh
-- carries both, which is why the hero lives there.
--
-- `sport_ids bigint[]` (schema/location_sport_tags.sql, populated by
-- tool/venue/normalize.py) replaced parsing the raw OSM `tags` "sport:[a, b]"
-- strings client-side. Raw `tags` is still kept as the provenance record, but
-- it is NOT the thing to filter on any more.
--
-- The old `Sport Station` trap — city_cluster=1 but physically in Dong Nai —
-- is gone; the overhaul purged the mis-clustered rows (HCMC went ~2050 -> 997).
--
-- ── The FitScore gradient (the whole point of the cast size) ────────────────
-- `calculate_profile_compat` scores  raw -> 2.5 + min(raw,10)/10 * 2.5.
-- Since the fix in schema/fitscore_verified_mmr_skill.sql, the skill component
-- prefers a VERIFIED rating (user games_played>=10, lobby rated_match_count>=5)
-- and only falls back to comparing elo_seed tiers. No seeded user or lobby ever
-- reaches those thresholds — fn_seed_initial_elo writes user_rating at
-- games_played=0 — so scoring is deterministic on the seed-tier path.
--
-- For a MALE hero the reachable components are network (+4 / +3 / +2),
-- skill (+3) and age (+1.5); the +2 gender bonus is female-only, so 8.5 raw
-- (4.6) is the ceiling. The cast is laid out to produce a believable spread:
--
-- VERIFIED against the live functions on 2026-09-21 by calling
-- home_teammate_lobby_data as the hero (role authenticated + request.jwt.claims
-- inside a transaction — outside one, SET LOCAL is ignored, auth.uid() comes back
-- NULL and EVERY row falsely reads 2.5/{playtime}; if you see that, your test
-- harness is broken, not the seed). Actual feed, in order:
--
--   lobby                 score  chips
--   Bình Thạnh United     4.6    network, skill, age, playtime   <- the star card
--   Sài Gòn Night FC      4.4    network, skill, age, playtime
--   Bách Khoa Alumni FC   3.9    network, age, playtime
--   Phủi Cuối Tuần        3.4    network, age, playtime
--   Trẻ Trâu FC           3.3    skill, playtime
--   Hẻm 8 FC              2.5    (none — plain card)
--
-- Sài Gòn Night FC was designed for 4.0/{network,skill} but lands at 4.4: 4 of
-- its 6 members fall in the `mature` bucket via the modulo fallback in 1a and
-- pick up the +1.5 age component. Left as-is — the wider spread reads better
-- than the planned one. Anh Em VNG FC (the hero's own lobby) also scores 4.6 but
-- never appears in his feed; home_teammate_lobby_data excludes
-- get_my_lobby_ids(). Four chips is also exactly _FitScoreVibes' display cap.
--
-- L6 sitting exactly at the 2.5 floor is intentional. `LobbyFeedCard` renders
-- NO match board at the floor (`isGoodFit = score > 2.5`), and a feed where
-- every card glows amber reads as fake — the plain card is what makes the
-- others mean something.
--
-- The `playtime` chip is appended by home_teammate_lobby_data itself (not by
-- calculate_profile_compat) when ts_score >= 4, and that same score is a HARD
-- FILTER: a lobby whose playtime doesn't overlap the hero's is dropped from the
-- feed entirely. Every seeded lobby therefore overlaps the hero's schedule.
-- ============================================================================

-- ── 0. Cleanup (re-runnable) ────────────────────────────────────────────────
-- FK-safe order. lobby_before_delete raises if non-captain members remain, so
-- those go first; lobby delete then cascades the captain row and feed/match.

DELETE FROM public.lobby_member lm
USING public.lobby l
WHERE lm.lobby_id = l.id
  AND l.id::text LIKE '5107%'
  AND lm.user_id <> l.captain_id;

-- A seeded user's membership in a NON-seeded lobby, if one was ever added by
-- hand during a shoot. Captain rows are excluded here for the same reason as
-- above: lobby_member_prevent_captain_leave RAISEs on them, and the captain row
-- of a seeded lobby is removed by the lobby DELETE below (ON DELETE CASCADE).
-- Deleting them blind made this script fail on its second run against an
-- already-seeded database.
DELETE FROM public.lobby_member lm
USING public.lobby l
WHERE lm.lobby_id = l.id
  AND lm.user_id::text LIKE '5107%'
  AND lm.user_id <> l.captain_id;

DELETE FROM public.lobby_homeground WHERE lobby_id::text LIKE '5107%';
DELETE FROM public.lobby            WHERE id::text      LIKE '5107%';

DELETE FROM public.friendship
WHERE requester_id::text LIKE '5107%' OR addressee_id::text LIKE '5107%';

DELETE FROM public.user_network     WHERE user_id::text LIKE '5107%';
DELETE FROM public.user_industry    WHERE user_id::text LIKE '5107%';
DELETE FROM public.user_rating      WHERE user_id::text LIKE '5107%';
DELETE FROM public.soccer_profile     WHERE user_id::text LIKE '5107%';
DELETE FROM public.pickleball_profile WHERE user_id::text LIKE '5107%';

DELETE FROM public."user" WHERE id::text LIKE '5107%';
DELETE FROM auth.users    WHERE id::text LIKE '5107%';

-- ── 1. Generation ───────────────────────────────────────────────────────────
DO $shot$
DECLARE
    -- bcrypt('12345678'), identical to schema/demo_coach_seed.sql so every
    -- seeded account shares one memorable demo password.
    c_pw    CONSTANT text := '$2a$10$PznXR5Vz3pMfqVbKwR0bcebFX74Cb6m9o0bRfWiwwH/9eS/uxHHTK';
    c_vng   CONSTANT bigint := 383;   -- VNG Corporation        (company, city NULL)
    c_bk    CONSTANT bigint := 193;   -- DH Bach khoa TP.HCM    (university, city 1)
    c_tech  CONSTANT integer := 17;   -- industry: technology

    -- Hero's schedule. Every lobby below overlaps it so none is filtered out by
    -- the ts_score floor in home_teammate_lobby_data.
    c_pt_hero CONSTANT jsonb := '[{"dayOfWeek":"mon","dayChunk":"night"},
                                  {"dayOfWeek":"wed","dayChunk":"night"},
                                  {"dayOfWeek":"fri","dayChunk":"night"},
                                  {"dayOfWeek":"sat","dayChunk":"noon"}]'::jsonb;
    c_pt_alt  CONSTANT jsonb := '[{"dayOfWeek":"wed","dayChunk":"night"},
                                  {"dayOfWeek":"fri","dayChunk":"night"},
                                  {"dayOfWeek":"sun","dayChunk":"midday"}]'::jsonb;

    -- 82 realistic, CHECK-legal usernames (^[a-zA-Z0-9]+$, <= 16 chars).
    -- Index 1 is the hero.
    v_names text[] := ARRAY[
      'minhtuan','quanganh','hoangnam','thanhdat','duykhanh','baolong','giahuy','phucthinh',
      'trungkien','nhatminh','vinhphat','dathien','hieunghia','kienvu','locphat','namphong',
      'phongvu','quanle','sonlam','taianh','tuanvu','vuhoang','anhkhoa','binhminh',
      'cuongtran','dungpham','giangho','haidang','khoale','lamvu','manhhung','nghiadao',
      'oanhvu','phinguyen','quocbao','sangle','thaison','ucduy','vietanh','xuanbac',
      'yenthe','anhdung','baoquoc','chithanh','danhnam','ducanh','gianghai','hoangvu',
      'khangle','longvu','minhkhoi','ngocson','phattai','quangminh','sinhvu','tanphat',
      'thehung','tiendat','trongnghia','tuananh','vandat','viethoang','xuanhoa','anhquan',
      'bachduong','caolinh','daiduong','dinhnam','giaminh','hungthinh','khaihoan','langiang',
      'minhduc','nguyenvu','phuongnam','quyenle','songhai','thanhtung','trieuvy','tuongvi',
      'vanhung','xuanthanh'
    ];

    v_id      uuid;
    v_lobby   uuid;
    v_loc     uuid;
    i         int;

    -- Per-user attributes, resolved in the loop.
    v_gender  text;
    v_age     text;
    v_seed    text;
    v_sport   int;     -- 1 = soccer, 5 = pickleball

BEGIN
    -- ---------------------------------------------------------------------
    -- 1a. Users. auth.users first: public."user".id FKs to it, and a trigger
    --     on auth.users auto-creates the public row, so the public insert is
    --     an UPDATE-shaped upsert rather than a plain INSERT.
    -- ---------------------------------------------------------------------
    FOR i IN 1 .. array_length(v_names, 1) LOOP
        v_id := ('51070000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid;

        -- Cast composition, tuned for the gradient documented in the header.
        --   `mature` dominates L1/L3/L4 so the age component (+1.5) fires there
        --   and not on L5/L6.
        v_age := CASE
                   WHEN i = 1                     THEN 'mature'
                   WHEN i BETWEEN 9  AND 15       THEN CASE WHEN i <= 12 THEN 'mature' ELSE 'student' END
                   WHEN i BETWEEN 22 AND 34       THEN 'mature'
                   WHEN i BETWEEN 35 AND 46       THEN 'student'
                   ELSE CASE WHEN i % 3 = 0 THEN 'student' ELSE 'mature' END
                 END;

        -- A realistic minority of women across the cast. The hero is male, so
        -- the +2 female-comfort component never fires for him either way.
        v_gender := CASE WHEN i = 1 THEN 'male'
                         WHEN i % 7 = 0 THEN 'female'
                         ELSE 'male' END;

        INSERT INTO auth.users (
            instance_id, id, aud, role, email, encrypted_password,
            email_confirmed_at, created_at, updated_at,
            raw_app_meta_data, raw_user_meta_data,
            confirmation_token, recovery_token, email_change_token_new, email_change)
        VALUES (
            '00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated',
            CASE WHEN i = 1 THEN 'shothero@demo.passe'
                 ELSE 'shotuser' || lpad(i::text, 2, '0') || '@demo.passe' END,
            c_pw, now(), now(), now(),
            '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
            '', '', '', '')
        ON CONFLICT (id) DO NOTHING;

        INSERT INTO public."user" (id, username, tag_number, details)
        VALUES (
            v_id,
            v_names[i],
            lpad(((i * 37) % 10000)::text, 4, '0'),
            jsonb_build_object(
                'gender',          v_gender,
                'ageGroup',        v_age,
                'playtime',        CASE WHEN i % 4 = 0 THEN c_pt_alt ELSE c_pt_hero END,
                'generatedAvatar', v_names[i],
                'location', jsonb_build_object(
                    'city', 1,
                    -- The hero's six wards are exactly the ones his seeded
                    -- lobbies' homegrounds sit in, so the Discover filter opens
                    -- pre-filled with real ward chips and still returns every
                    -- card. Six is also District's per-filter cap
                    -- (FilterController.setDistricts trims above 6).
                    'districts', CASE WHEN i = 1
                                      THEN '["hcm_binhthanh","hcm_binhloitrung","hcm_binhquoi","hcm_thanhmytay","hcm_dienhong","hcm_xuanhoa"]'::jsonb
                                      ELSE '["hcm_binhthanh","hcm_binhloitrung"]'::jsonb END
                )
            ))
        ON CONFLICT (id) DO UPDATE
          SET username = EXCLUDED.username,
              tag_number = EXCLUDED.tag_number,
              details    = EXCLUDED.details;
    END LOOP;
END
$shot$;

-- ── 1b. Sport profiles ──────────────────────────────────────────────────────
-- elo_seed is what the FitScore skill component falls back to (nobody here is
-- "verified"), so these values ARE the gradient's skill lever. The insert also
-- fires fn_seed_initial_elo, which writes the user_rating row at
-- games_played = 0 — deliberately left unverified.
DO $shot$
DECLARE
    v_id   uuid;
    v_seed text;
    i      int;
BEGIN
    -- Soccer: the hero (1), his own lobby's members (2-8), the six gradient
    -- lobbies (9-46) and the solo teammate cards (47-56).
    FOR i IN 1 .. 56 LOOP
        v_id := ('51070000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid;

        -- `fair` = rank 2 = the hero's tier. A lobby scores the +3 skill
        -- component when at least HALF its members sit on the hero's tier.
        v_seed := CASE
            WHEN i = 1                THEN 'fair'                                    -- hero
            WHEN i BETWEEN 2  AND 8   THEN CASE WHEN i <= 5  THEN 'fair' ELSE 'good' END
            WHEN i BETWEEN 9  AND 15  THEN CASE WHEN i <= 12 THEN 'fair' ELSE 'good' END  -- L1: 4/7 fair -> +3
            WHEN i BETWEEN 16 AND 21  THEN CASE WHEN i <= 19 THEN 'fair' ELSE 'casual' END -- L2: 4/6 fair -> +3
            WHEN i BETWEEN 22 AND 28  THEN 'good'                                     -- L3: 0 fair -> no skill
            WHEN i BETWEEN 29 AND 34  THEN 'casual'                                   -- L4: 0 fair -> no skill
            WHEN i BETWEEN 35 AND 40  THEN CASE WHEN i <= 38 THEN 'fair' ELSE 'good' END -- L5: 4/6 fair -> +3
            WHEN i BETWEEN 41 AND 46  THEN 'advanced'                                 -- L6: nothing
            ELSE (ARRAY['casual','fair','good','advanced'])[1 + (i % 4)]
        END;

        INSERT INTO public.soccer_profile (user_id, position, pitch, elo_seed)
        VALUES (
            v_id,
            (CASE i % 4
               WHEN 0 THEN ARRAY['forward']
               WHEN 1 THEN ARRAY['midfielder']
               WHEN 2 THEN ARRAY['defender']
               ELSE        ARRAY['keeper']
             END)::text[],
            ARRAY['5v5','7v7']::text[],
            v_seed)
        ON CONFLICT (user_id) DO UPDATE SET elo_seed = EXCLUDED.elo_seed;
    END LOOP;

    -- Pickleball: the hero plus the pickleball cast (57-82).
    FOR i IN 57 .. 82 LOOP
        v_id := ('51070000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid;
        INSERT INTO public.pickleball_profile (user_id, dominant_hand, discipline, elo_seed)
        VALUES (
            v_id,
            CASE WHEN i % 5 = 0 THEN 'left' ELSE 'right' END,
            ARRAY['doubles'],
            (ARRAY['casual','fair','good'])[1 + (i % 3)])
        ON CONFLICT (user_id) DO UPDATE SET elo_seed = EXCLUDED.elo_seed;
    END LOOP;

    -- The hero plays both. `casual` here (a notch under his soccer `fair`) is
    -- the honest shape of someone newer to the sport.
    INSERT INTO public.pickleball_profile (user_id, dominant_hand, discipline, elo_seed)
    VALUES ('51070000-0000-4000-8000-000000000001'::uuid, 'right', ARRAY['doubles'], 'casual')
    ON CONFLICT (user_id) DO UPDATE SET elo_seed = EXCLUDED.elo_seed;
END
$shot$;

-- ── 1c. Affiliations — the network half of the gradient ─────────────────────
-- Scoring recap (user -> lobby branch of calculate_profile_compat):
--   >= 3 members sharing ANY of the caller's networks           -> +4 (flat)
--   1-2 members sharing, at least one tie non-alumni BOTH sides -> +3
--   1-2 members sharing, alumni on either side                  -> +2
DO $shot$
DECLARE
    c_vng  CONSTANT bigint  := 383;
    c_bk   CONSTANT bigint  := 193;
    c_tech CONSTANT integer := 17;
    v_id   uuid;
    i      int;
BEGIN
    -- Hero: an ACTIVE employer tie (VNG) and an ALUMNI university tie (Bach khoa).
    -- Two ties of different alumni-ness is what lets L2 (+3, needs an active
    -- match on both sides) and L4 (+2, alumni-only) score differently at all.
    v_id := '51070000-0000-4000-8000-000000000001'::uuid;
    INSERT INTO public.user_network (user_id, network_id, alumni) VALUES
        (v_id, c_vng, false),
        (v_id, c_bk,  true);
    INSERT INTO public.user_industry (user_id, industry_id) VALUES (v_id, c_tech);

    -- Hero's own lobby (2-8): teammates from work. Not scored (you don't get a
    -- FitScore against your own lobby) but it makes the roster coherent.
    FOR i IN 2 .. 8 LOOP
        v_id := ('51070000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid;
        INSERT INTO public.user_network (user_id, network_id, alumni) VALUES (v_id, c_vng, false);
        INSERT INTO public.user_industry (user_id, industry_id) VALUES (v_id, c_tech);
    END LOOP;

    -- L1 (9-15) — THE STAR CARD. Four colleagues share VNG, so the >=3 branch
    -- fires: +4. Combined with >=half `fair` (+3) and >=half `mature` (+1.5)
    -- that is 8.5 raw -> 4.6/5, the male ceiling.
    FOR i IN 9 .. 12 LOOP
        v_id := ('51070000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid;
        INSERT INTO public.user_network (user_id, network_id, alumni) VALUES (v_id, c_vng, false);
        INSERT INTO public.user_industry (user_id, industry_id) VALUES (v_id, c_tech);
    END LOOP;

    -- L2 (16-21) — exactly ONE shared tie, active on both sides: +3.
    v_id := '51070000-0000-4000-8000-000000000016'::uuid;
    INSERT INTO public.user_network (user_id, network_id, alumni) VALUES (v_id, c_vng, false);

    -- L3 (22-28) — three Bach khoa alumni: the >=3 branch again (+4, flat,
    -- alumni-ness irrelevant once you clear three).
    FOR i IN 22 .. 24 LOOP
        v_id := ('51070000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid;
        INSERT INTO public.user_network (user_id, network_id, alumni) VALUES (v_id, c_bk, true);
    END LOOP;

    -- L4 (29-34) — ONE Bach khoa tie, alumni on both sides, so it stops at +2.
    v_id := '51070000-0000-4000-8000-000000000029'::uuid;
    INSERT INTO public.user_network (user_id, network_id, alumni) VALUES (v_id, c_bk, true);

    -- L5 (35-40) and L6 (41-46) share NOTHING with the hero. L5 still scores on
    -- skill alone; L6 lands on the 2.5 floor and renders as a plain card.
END
$shot$;

-- ── 1d. Lobbies, homegrounds and rosters ────────────────────────────────────
-- Trigger notes that dictate the order here:
--   * `lobby_add_captain_as_member` inserts the captain into lobby_member on
--     INSERT, so the captain must NOT be added again below.
--   * `lobby_member_recompute_stats` and `trg_user_affiliation_recompute`
--     maintain member_count / network_ids / active_network_ids / industry_ids /
--     mmr, so none of those are written by hand. Affiliations (1c) are seeded
--     BEFORE membership so the recompute sees them.
--   * `trg_lobby_playtime_keys` derives playtime_keys from playtime.
--
-- Venues are resolved by name against real directory rows and the lookup RAISES
-- if one is missing — a silently NULL homeground would drop the lobby out of
-- home_teammate_lobby_data's city filter and quietly empty the Discover feed.
DO $shot$
DECLARE
    c_pt CONSTANT jsonb := '[{"dayOfWeek":"mon","dayChunk":"night"},
                             {"dayOfWeek":"wed","dayChunk":"night"},
                             {"dayOfWeek":"fri","dayChunk":"night"},
                             {"dayOfWeek":"sat","dayChunk":"noon"}]'::jsonb;
    rec     record;
    v_lobby uuid;
    v_loc   uuid;
    v_cap   uuid;
    i       int;
BEGIN
    FOR rec IN
        SELECT * FROM (VALUES
            -- idx, captain, sport, name, venue, member range, description
            ( 1,  1, 1, 'Anh Em VNG FC',        'Sân vận động Gia Định',
                   2,  8, 'Đội bóng anh em trong công ty, đá tối thứ 6 hàng tuần.'),
            ( 2,  9, 1, 'Bình Thạnh United',    'Sân bóng đá Phan Chu Trinh',
                  10, 15, 'Team phủi Bình Thạnh, vui là chính nhưng đá nghiêm túc.'),
            ( 3, 16, 1, 'Sài Gòn Night FC',     'Sân cỏ nhân tạo Thiên Trường',
                  17, 21, 'Đá đêm sau giờ làm. Ai rảnh tối là vào.'),
            ( 4, 22, 1, 'Bách Khoa Alumni FC',  'Sân banh số 8',
                  23, 28, 'Cựu sinh viên Bách Khoa, duy trì kèo đều từ 2019.'),
            ( 5, 29, 1, 'Phủi Cuối Tuần',       'Sân Bóng Đá Cỏ Nhân Tạo Mini Thành Phát',
                  30, 34, 'Chỉ đá cuối tuần, không áp lực thành tích.'),
            ( 6, 35, 1, 'Trẻ Trâu FC',          'Sân vận động Thống Nhất',
                  36, 40, 'Anh em sinh viên, đá nhanh khoẻ, thiếu người thường xuyên.'),
            ( 7, 41, 1, 'Hẻm 8 FC',             'Sân bóng đá Phan Chu Trinh',
                  42, 46, 'Đội xóm, đá cho vui, ai tới cũng được.'),
            ( 8, 57, 5, 'Pickle Bình Thạnh',    'Liber Pickleball',
                  58, 61, 'Nhóm pickleball Bình Thạnh, đánh đôi là chính.'),
            ( 9, 62, 5, 'Smash Sài Gòn',        'Pickleball 426',
                  63, 66, 'Đánh đôi trình độ khá, giao lưu hàng tuần.'),
            (10, 67, 5, 'Pickle Sớm Mai',       'Sân Pickleball Thành Thái',
                  68, 71, 'Đánh sáng sớm trước giờ đi làm.'),
            (11, 72, 5, 'CLB Pickle Quận 3',    'CLB Pickleball Ho Xuan Huong',
                  73, 76, 'CLB quận 3, mở cho người mới.')
        ) AS t(idx, captain_idx, sport_id, lname, venue, m_from, m_to, descr)
    LOOP
        v_lobby := ('51071000-0000-4000-8000-' || lpad(rec.idx::text, 12, '0'))::uuid;
        v_cap   := ('51070000-0000-4000-8000-' || lpad(rec.captain_idx::text, 12, '0'))::uuid;

        -- Real venue, correct sport. The sport-tag predicate mirrors
        -- Location.matchesSport: OSM rows store "sport:[soccer, tennis]".
        SELECT l.id INTO v_loc
        FROM public.location l
        WHERE l.name = rec.venue
          AND l.city_cluster = 1
          AND l.district <> ''
          AND l.sport_ids @> ARRAY[rec.sport_id]::bigint[]
        LIMIT 1;

        IF v_loc IS NULL THEN
            RAISE EXCEPTION
              'shot_seed: no real % venue named "%" in city_cluster 1. The directory changed — pick another from schema/shot_seed_structure.sql''s venue list.',
              CASE rec.sport_id WHEN 1 THEN 'soccer' ELSE 'pickleball' END, rec.venue;
        END IF;

        INSERT INTO public.lobby (id, captain_id, searchable_id, name, sport_id,
                                  playtime, visibility, description)
        VALUES (v_lobby, v_cap,
                'shot' || lpad(rec.idx::text, 4, '0'),
                rec.lname, rec.sport_id, c_pt, 'discoverable', rec.descr)
        ON CONFLICT (id) DO UPDATE
          SET name = EXCLUDED.name, description = EXCLUDED.description;

        INSERT INTO public.lobby_homeground (lobby_id, location_id, is_primary)
        VALUES (v_lobby, v_loc, true)
        ON CONFLICT DO NOTHING;

        -- Captain is already a member via lobby_add_captain_as_member.
        FOR i IN rec.m_from .. rec.m_to LOOP
            INSERT INTO public.lobby_member (user_id, lobby_id, role)
            VALUES (('51070000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid, v_lobby, 'member')
            ON CONFLICT DO NOTHING;
        END LOOP;
    END LOOP;

    -- The hero is a plain MEMBER of the pickleball lobby (idx 8) — this is what
    -- makes the member-side RSVP / join-request UI reachable in the same
    -- account that shows captain-only UI in his soccer lobby.
    INSERT INTO public.lobby_member (user_id, lobby_id, role)
    VALUES ('51070000-0000-4000-8000-000000000001'::uuid,
            '51071000-0000-4000-8000-000000000008'::uuid, 'member')
    ON CONFLICT DO NOTHING;
END
$shot$;

-- ── 1e. Friendships ─────────────────────────────────────────────────────────
-- 12 accepted friends, which is what fills the Feed tab: a wall post reaches
-- the author's friends and lobby mates (see fn_can_see_wall_post). Two pending
-- INCOMING requests give the Profile "Bạn bè" badge something to show without
-- burying the account in pending items.
DO $shot$
DECLARE
    c_hero CONSTANT uuid := '51070000-0000-4000-8000-000000000001'::uuid;
    v_other uuid;
    i int;
BEGIN
    -- Accepted: his own lobby mates (2-8) plus five from the star lobby (9-13).
    FOR i IN 2 .. 13 LOOP
        v_other := ('51070000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid;
        INSERT INTO public.friendship (requester_id, addressee_id, status, responded_at)
        VALUES (c_hero, v_other, 'accepted', now() - (i || ' days')::interval);
    END LOOP;

    -- Pending, addressed TO the hero so there is something to accept on camera.
    FOR i IN 47 .. 48 LOOP
        v_other := ('51070000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid;
        INSERT INTO public.friendship (requester_id, addressee_id, status)
        VALUES (v_other, c_hero, 'pending');
    END LOOP;
END
$shot$;
