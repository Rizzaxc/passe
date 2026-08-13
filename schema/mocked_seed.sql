-- ============================================================================
-- mocked_seed.sql — synthetic integration-test data for SOCCER (sport_id = 1)
-- scoped to Ho Chi Minh City (city_cluster = 1 / City.dbIndex = 1).
--
-- Idempotent: re-running first removes every previously seeded `mocked_` row.
-- Apply with the Supabase MCP `execute_sql` (runs as postgres → bypasses RLS),
-- NOT `apply_migration` (this is data, not schema).
--
-- NOTE: public."user".id has a FK to auth.users(id), so each synthetic user
-- needs a matching auth.users row first. We create minimal email-provider rows
-- (email mockeduserNN@mocked.passe) — they are never used to sign in.
--
-- Identification of seeded rows:
--   user.username      LIKE 'mockeduser%'   (username CHECK is ^[a-zA-Z0-9]+$,
--                                            so the `mocked_` prefix can't be used here)
--   lobby.name         LIKE 'mocked_%'
--   professional.display_name LIKE 'mocked_%'
--   location.name      LIKE 'mocked_%'
--
-- Networks & industries are NOT created — users pick from existing rows.
-- ============================================================================

-- ── 0. Cleanup (re-runnable) ────────────────────────────────────────────────
-- Order matters: drop non-captain members so lobby_before_delete won't raise,
-- then activities/bookings that FK into lobbies & pros, then the parents.

DELETE FROM lobby_member lm
USING lobby l
WHERE lm.lobby_id = l.id
  AND l.name LIKE 'mocked_%'
  AND lm.user_id <> l.captain_id;

DELETE FROM activity a
WHERE a.lobby_id IN (SELECT id FROM lobby WHERE name LIKE 'mocked_%')
   OR a.user_id  IN (SELECT id FROM "user" WHERE username LIKE 'mockeduser%')
   OR a.course_id IN (
        SELECT c.id FROM course c
        JOIN professional p ON p.id = c.professional_id
        WHERE p.display_name LIKE 'mocked_%');

-- Courses replaced coach bookings; `referee_booking` is left alone here since
-- nothing mocked ever created one.
DELETE FROM course c
USING professional p
WHERE c.professional_id = p.id
  AND p.display_name LIKE 'mocked_%';

DELETE FROM lobby WHERE name LIKE 'mocked_%';            -- cascades captain member + feed/match
DELETE FROM professional WHERE display_name LIKE 'mocked_%';  -- cascades professional_service

DELETE FROM soccer_profile WHERE user_id IN (SELECT id FROM "user" WHERE username LIKE 'mockeduser%');
DELETE FROM user_rating    WHERE user_id IN (SELECT id FROM "user" WHERE username LIKE 'mockeduser%');
DELETE FROM user_network   WHERE user_id IN (SELECT id FROM "user" WHERE username LIKE 'mockeduser%');
DELETE FROM user_industry  WHERE user_id IN (SELECT id FROM "user" WHERE username LIKE 'mockeduser%');
DELETE FROM lobby_member   WHERE user_id IN (SELECT id FROM "user" WHERE username LIKE 'mockeduser%');
DELETE FROM "user"         WHERE username LIKE 'mockeduser%';
DELETE FROM auth.users     WHERE email LIKE 'mockeduser%@mocked.passe';

DELETE FROM location WHERE name LIKE 'mocked_%';

-- ── 1. Generation ───────────────────────────────────────────────────────────
DO $$
DECLARE
    v_loc       uuid[] := '{}';
    v_user      uuid[] := '{}';
    v_lobby     uuid[] := '{}';
    v_current   uuid;
    v_id        uuid;
    v_cap       uuid;
    v_pro       uuid;
    v_course       uuid;
    v_conversation uuid;
    i           int;
    j           int;
    v_target    int;
    v_count     int;
    v_guard     int;
    v_elo       int;
    v_seed      text;
    v_pt        jsonb;
    v_today     timestamptz := date_trunc('day', now());
    v_netpool   bigint[];
    v_days      text[] := ARRAY['mon','tue','wed','thu','fri','sat','sun'];
    v_chunks    text[] := ARRAY['early','midday','noon','night'];
    v_districts text[] := ARRAY['hcm_q1','hcm_q3','hcm_q4','hcm_q5','hcm_q7','hcm_q10',
                                'hcm_binhthanh','hcm_govap','hcm_phunhuan','hcm_tanbinh','hcm_thuduc'];
    v_dn        int := 11;  -- array_length(v_districts)
    v_lobnames  text[] := ARRAY['Sài Gòn United','Quận 1 Stars','Thủ Đức Warriors','Phú Nhuận FC',
                                'Bình Thạnh Rangers','Gò Vấp Galaxy','Tân Bình Tigers','Quận 7 Sharks',
                                'Chợ Lớn Dragons','Bến Thành Athletic','Landmark Lions','Phú Mỹ Hưng Eagles'];
BEGIN
    -- current (real) signed-in user
    SELECT id INTO v_current FROM "user" WHERE username NOT LIKE 'mockeduser%' ORDER BY username LIMIT 1;

    -- network pool: HCM-scoped schools/universities (city=1) + nationwide companies
    SELECT array_agg(id) INTO v_netpool
    FROM network
    WHERE city = 1 OR (city IS NULL AND category = 'company');

    -- ── Locations (14 soccer venues across districts) ──────────────────────
    FOR i IN 1..14 LOOP
        INSERT INTO location (name, district, city, full_address, city_cluster, lat, lon, tags)
        VALUES ('mocked_Sân bóng ' || i,
                v_districts[1 + (i % v_dn)],
                'Thành phố Hồ Chí Minh',
                'mocked_ Số ' || i || ', ' || v_districts[1 + (i % v_dn)] || ', TP.HCM',
                1,
                10.740 + (i * 0.0065),
                106.660 + (i * 0.0055),
                ARRAY['soccer','mocked'])
        RETURNING id INTO v_id;
        v_loc := array_append(v_loc, v_id);
    END LOOP;

    -- ── 50 users (+ soccer_profile, user_rating, networks, industries) ─────
    FOR i IN 1..50 LOOP
        v_pt := jsonb_build_array(
            jsonb_build_object('dayOfWeek', v_days[1 + (i % 7)],       'dayChunk', v_chunks[1 + (i % 4)]),
            jsonb_build_object('dayOfWeek', v_days[1 + ((i + 2) % 7)], 'dayChunk', v_chunks[1 + ((i + 1) % 4)]),
            jsonb_build_object('dayOfWeek', v_days[1 + ((i + 4) % 7)], 'dayChunk', v_chunks[1 + ((i + 2) % 4)])
        );

        -- auth.users row → the on_auth_user_created trigger auto-inserts the
        -- matching public."user" row with username = email local-part
        -- ('mockeduserNN'). We only fill in details/tag_number afterwards.
        v_id := gen_random_uuid();
        INSERT INTO auth.users (
            instance_id, id, aud, role, email, encrypted_password,
            email_confirmed_at, created_at, updated_at,
            raw_app_meta_data, raw_user_meta_data,
            confirmation_token, recovery_token, email_change_token_new, email_change)
        VALUES (
            '00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated',
            'mockeduser' || lpad(i::text, 2, '0') || '@mocked.passe',
            '$2a$10$PznXR5Vz3pMfqVbKwR0bcebFX74Cb6m9o0bRfWiwwH/9eS/uxHHTK',
            now(), now(), now(),
            '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
            '', '', '', '');

        UPDATE "user" SET
            tag_number = lpad((1000 + i)::text, 4, '0'),
            details = jsonb_build_object(
                'gender',          CASE WHEN i % 2 = 0 THEN 'male' ELSE 'female' END,
                'ageGroup',        (ARRAY['student','mature','middleAge'])[1 + (i % 3)],
                'generatedAvatar', 'mocked_avatar_' || i,
                'playtime',        v_pt,
                'location',        jsonb_build_object(
                                       'city', 1,
                                       'districts', to_jsonb(ARRAY[
                                           v_districts[1 + (i % v_dn)],
                                           v_districts[1 + ((i + 4) % v_dn)]
                                       ])))
        WHERE id = v_id;
        v_user := array_append(v_user, v_id);

        -- soccer profile (the elo_seed trigger creates a user_rating row)
        v_seed := (ARRAY['beginner','casual','fair','good','advanced'])[1 + (i % 5)];
        INSERT INTO soccer_profile (user_id, "position", pitch, elo_seed)
        VALUES (
            v_id,
            CASE WHEN i % 7 = 0 THEN ARRAY['keeper']
                 ELSE ARRAY[(ARRAY['forward','midfielder','defender'])[1 + (i % 3)]]
            END,
            CASE (i % 4)
                WHEN 0 THEN ARRAY['futsal']
                WHEN 1 THEN ARRAY['5v5']
                WHEN 2 THEN ARRAY['7v7']
                ELSE ARRAY['5v5','7v7']
            END,
            v_seed);

        -- spread the live ELO (upsert-by-hand: no unique constraint on user_rating)
        v_elo := 600 + ((i * 37) % 1000);
        UPDATE user_rating SET elo = v_elo, games_played = (i * 3) % 45
            WHERE user_id = v_id AND sport = 'soccer';
        IF NOT FOUND THEN
            INSERT INTO user_rating (user_id, sport, elo, games_played)
            VALUES (v_id, 'soccer', v_elo, (i * 3) % 45);
        END IF;

        -- 1–3 networks (mixed alumni)
        FOR j IN 0 .. (i % 3) LOOP
            INSERT INTO user_network (user_id, network_id, alumni)
            VALUES (v_id, v_netpool[1 + ((i * 7 + j * 13) % array_length(v_netpool, 1))], (j % 2 = 0));
        END LOOP;

        -- 1–2 industries
        FOR j IN 0 .. (i % 2) LOOP
            INSERT INTO user_industry (user_id, industry_id)
            VALUES (v_id, 1 + ((i * 5 + j * 3) % 18));
        END LOOP;
    END LOOP;

    -- ── 12 lobbies (captain auto-joined by trigger) ────────────────────────
    FOR i IN 1..12 LOOP
        v_cap := v_user[i];  -- distinct captains
        INSERT INTO lobby (captain_id, name, sport_id, home_ground, visibility, open_to_challengers, playtime, details)
        VALUES (
            v_cap,
            'mocked_' || v_lobnames[i],
            1,
            v_loc[1 + (i % 14)],
            (CASE WHEN i % 6 = 0 THEN 'private' WHEN i % 2 = 0 THEN 'public' ELSE 'discoverable' END)::lobby_visibility,
            (i % 5 <> 0),
            jsonb_build_array(
                jsonb_build_object('dayOfWeek', v_days[1 + (i % 7)],       'dayChunk', v_chunks[1 + (i % 4)]),
                jsonb_build_object('dayOfWeek', v_days[1 + ((i + 3) % 7)], 'dayChunk', v_chunks[1 + ((i + 2) % 4)])
            ),
            jsonb_build_object('ageGroup', (ARRAY['student','mature','middleAge'])[1 + (i % 3)],
                               'skill', 800 + (i * 50) % 800))
        RETURNING id INTO v_id;
        v_lobby := array_append(v_lobby, v_id);

        -- overlapping membership: grow to 5–10 total members
        v_target := 5 + (i % 6);
        j := 0;
        LOOP
            SELECT count(*) INTO v_count FROM lobby_member WHERE lobby_id = v_id;
            EXIT WHEN v_count >= v_target;
            -- spread picks across the 50 users so each lands in ~1–3 lobbies
            INSERT INTO lobby_member (user_id, lobby_id)
            VALUES (v_user[1 + ((i * 5 + j * 7) % 50)], v_id)
            ON CONFLICT (user_id, lobby_id) DO NOTHING;
            j := j + 1;
            EXIT WHEN j > 80;  -- safety
        END LOOP;
    END LOOP;

    -- ── Enroll the real current user into 3 lobbies ────────────────────────
    IF v_current IS NOT NULL THEN
        FOR i IN 1..3 LOOP
            INSERT INTO lobby_member (user_id, lobby_id)
            VALUES (v_current, v_lobby[i])
            ON CONFLICT (user_id, lobby_id) DO NOTHING;
        END LOOP;
    END IF;

    -- recompute denormalised lobby stats (mmr, member_count, network/industry/playtime arrays)
    FOREACH v_id IN ARRAY v_lobby LOOP
        PERFORM fn_lobby_recompute_stats(v_id);
    END LOOP;

    -- ── 5 coaches + 5 referees (+ services) ────────────────────────────────
    -- preferred location + schedule feed the home_professional_data filter:
    -- all in HCM (cluster 1), one varied district each, fully available.
    FOR i IN 1..10 LOOP
        INSERT INTO professional (professional_role, display_name, bio, is_verified, sports,
                                  experience_years, average_rating, review_count,
                                  preferred_city_cluster, preferred_districts, schedule)
        VALUES (
            (CASE WHEN i <= 5 THEN 'coach' ELSE 'referee' END)::professional_role,
            (CASE WHEN i <= 5 THEN 'mocked_HLV ' ELSE 'mocked_Trọng tài ' END) || i,
            (CASE WHEN i <= 5
                  THEN 'mocked_ Huấn luyện viên bóng đá giàu kinh nghiệm.'
                  ELSE 'mocked_ Trọng tài đã điều khiển nhiều giải phong trào.' END),
            (i % 4 <> 0),                              -- ~75% verified
            ARRAY[1]::bigint[],                        -- soccer
            2 + (i % 12),
            round((3.6 + (i % 14) * 0.1)::numeric, 2), -- 3.6–5.0
            5 + (i * 7) % 95,
            1,                                         -- Ho Chi Minh
            ARRAY[(ARRAY['hcm_q1','hcm_q3','hcm_q5','hcm_q7','hcm_binhthanh',
                         'hcm_phunhuan','hcm_govap','hcm_thuduc','hcm_tanbinh',
                         'hcm_q10'])[i]],
            (SELECT jsonb_agg(jsonb_build_object('dayOfWeek', d, 'dayChunk', c))
             FROM unnest(ARRAY['mon','tue','wed','thu','fri','sat','sun']) AS d
             CROSS JOIN unnest(ARRAY['early','midday','noon','night']) AS c))
        RETURNING id INTO v_pro;

        INSERT INTO professional_service (professional_id, sport_id, service_type, service_description,
                                          price_amount, pricing_kind,
                                          min_duration_minutes, max_participants, is_active)
        VALUES (
            v_pro, 1,
            (CASE WHEN i <= 5 THEN 'coaching' ELSE 'refereeing' END),
            (CASE WHEN i <= 5 THEN 'mocked_ Buổi tập cá nhân/nhóm' ELSE 'mocked_ Điều khiển trận đấu' END),
            200 + (i * 30) % 400,
            'hourly',
            60,
            (CASE WHEN i <= 5 THEN 1 + (i % 6) ELSE 22 END),
            true);
    END LOOP;

    -- ── Activities for the current user (populate Manage → Schedule) ───────
    IF v_current IS NOT NULL THEN
        -- today (sport)
        INSERT INTO activity (user_id, sport_id, start_time, end_time, lobby_id)
        VALUES (v_current, 1, v_today + interval '18 hours', v_today + interval '20 hours', v_lobby[1]);
        -- tomorrow (sport)
        INSERT INTO activity (user_id, sport_id, start_time, end_time, lobby_id)
        VALUES (v_current, 1, v_today + interval '1 day 18 hours', v_today + interval '1 day 20 hours', v_lobby[1]);
        -- +3 days (sport)
        INSERT INTO activity (user_id, sport_id, start_time, end_time, lobby_id)
        VALUES (v_current, 1, v_today + interval '3 days 20 hours', v_today + interval '3 days 22 hours', v_lobby[2]);
        -- weekly recurring on Wednesday (recurrence_day_of_week 0=Mon..6=Sun → Wed = 2)
        INSERT INTO activity (user_id, sport_id, start_time, end_time, lobby_id, recurrence_day_of_week)
        VALUES (v_current, 1, v_today + interval '19 hours', v_today + interval '21 hours', v_lobby[3], 2);

        -- one coaching relationship: an enrolled course with an approved
        -- upcoming session, which is what produces the coach-tone schedule row
        -- now that lessons aren't bookings.
        SELECT p.id INTO v_pro
        FROM professional p
        WHERE p.display_name LIKE 'mocked_HLV%' AND p.is_verified
          AND p.professional_role = 'coach'
        ORDER BY p.display_name LIMIT 1;

        IF v_pro IS NOT NULL THEN
            INSERT INTO course (professional_id, sport_id, name, target_session_count)
            VALUES (v_pro, 1, 'mocked_ Khoá kỹ thuật cơ bản', 8)
            RETURNING id INTO v_course;

            INSERT INTO conversation (kind, course_id) VALUES ('course', v_course)
            RETURNING id INTO v_conversation;

            INSERT INTO course_member (course_id, user_id, status)
            VALUES (v_course, v_current, 'enrolled');
            INSERT INTO conversation_member (conversation_id, user_id)
            VALUES (v_conversation, v_current);

            INSERT INTO activity (user_id, sport_id, start_time, end_time,
                                  course_id, proposal_status, location_id)
            VALUES (v_current, 1,
                    v_today + interval '1 day 7 hours 30 minutes',
                    v_today + interval '1 day 9 hours',
                    v_course, 'approved', v_loc[1]);
        END IF;
    END IF;
END $$;
