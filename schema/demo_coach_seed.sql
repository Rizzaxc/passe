-- ============================================================================
-- demo_coach_seed.sql — curated coach profiles for demoing the coaching
-- experience to prospective real coaches. Unlike schema/mocked_seed.sql
-- (bulk synthetic load-test data for the soccer teammate/lobby surfaces),
-- this seeds a small, hand-picked set of *loggable* coach accounts so you can
-- sign in as any of them during a demo and show off a fully populated
-- pro-mode dashboard: schedule/availability, course roster, chat thread,
-- pending enrollment offers, pending session proposals, pending session
-- reports, and reviews.
--
-- Login: every coach account below can sign in with email
--   democoach{1..7}@demo.passe   password: 12345678
-- (see the ENV=local/test Supabase auth screen; these are real, confirmed
-- auth.users rows, not placeholders.)
--
-- Idempotent: re-running first removes every previously seeded row from this
-- script. Apply with the Supabase MCP `execute_sql` (runs as postgres →
-- bypasses RLS and the course-activity direct-write guard), NOT
-- `apply_migration` (this is data, not schema).
--
-- Identification of seeded rows:
--   "user".username             LIKE 'democoach%' OR LIKE 'demostudent%'
--   professional.linked_user_id IN (SELECT id FROM "user" WHERE username LIKE 'democoach%')
--
-- The 7 coaches, one per sport (soccer x3, basketball, badminton, tennis,
-- pickleball), each carry a full weekly availability schedule (so they
-- always surface regardless of a discovery timeslot filter) plus one active
-- course. Two of them (Soccer Coach 1, Tennis Coach) also carry a second,
-- *ended* course with reviews, so their average_rating isn't zero. Names are
-- deliberately plain/descriptive ("Soccer Coach 1", not a fictional persona)
-- since this is disclosed as test data to whoever you're demoing to. Coverage
-- is deliberately spread thin rather than duplicated on every coach:
--   - pending enrollment offer (inquiring student) .... coach 1, coach 7
--   - pending session proposal (awaiting approval) .... coach 1, coach 4
--   - pending session report (coach hasn't written) ... coach 6
--   - ended course + reviews .......................... coach 1, coach 5
--   - light roster (1 student) ........................ coach 3, coach 6
--   - heavier roster (3-4 students) .................... coach 1, 2, 4, 5
-- ============================================================================

-- ── 0. Cleanup (re-runnable) ────────────────────────────────────────────────

DELETE FROM course_review
WHERE student_id IN (SELECT id FROM "user" WHERE username LIKE 'demostudent%')
   OR course_id IN (
        SELECT c.id FROM course c
        JOIN professional p ON p.id = c.professional_id
        JOIN "user" u ON u.id = p.linked_user_id
        WHERE u.username LIKE 'democoach%');

DELETE FROM course_session_report
WHERE student_id IN (SELECT id FROM "user" WHERE username LIKE 'demostudent%')
   OR course_id IN (
        SELECT c.id FROM course c
        JOIN professional p ON p.id = c.professional_id
        JOIN "user" u ON u.id = p.linked_user_id
        WHERE u.username LIKE 'democoach%');

DELETE FROM activity_confirmation ac
USING activity a, course c, professional p, "user" u
WHERE ac.activity_id = a.id AND a.course_id = c.id AND c.professional_id = p.id
  AND p.linked_user_id = u.id AND u.username LIKE 'democoach%';

DELETE FROM activity a
USING course c, professional p, "user" u
WHERE a.course_id = c.id AND c.professional_id = p.id AND p.linked_user_id = u.id
  AND u.username LIKE 'democoach%';

DELETE FROM message m
USING conversation cv, course c, professional p, "user" u
WHERE m.conversation_id = cv.id AND cv.course_id = c.id AND c.professional_id = p.id
  AND p.linked_user_id = u.id AND u.username LIKE 'democoach%';

DELETE FROM conversation_member cm
USING conversation cv, course c, professional p, "user" u
WHERE cm.conversation_id = cv.id AND cv.course_id = c.id AND c.professional_id = p.id
  AND p.linked_user_id = u.id AND u.username LIKE 'democoach%';

DELETE FROM conversation cv
USING course c, professional p, "user" u
WHERE cv.course_id = c.id AND c.professional_id = p.id AND p.linked_user_id = u.id
  AND u.username LIKE 'democoach%';

DELETE FROM course_enrollment_offer o
USING course c, professional p, "user" u
WHERE o.course_id = c.id AND c.professional_id = p.id AND p.linked_user_id = u.id
  AND u.username LIKE 'democoach%';

DELETE FROM course_member cme
USING course c, professional p, "user" u
WHERE cme.course_id = c.id AND c.professional_id = p.id AND p.linked_user_id = u.id
  AND u.username LIKE 'democoach%';

DELETE FROM course c
USING professional p, "user" u
WHERE c.professional_id = p.id AND p.linked_user_id = u.id AND u.username LIKE 'democoach%';

DELETE FROM professional_service ps
USING professional p, "user" u
WHERE ps.professional_id = p.id AND p.linked_user_id = u.id AND u.username LIKE 'democoach%';

DELETE FROM professional p
USING "user" u
WHERE p.linked_user_id = u.id AND u.username LIKE 'democoach%';

DELETE FROM user_contact
WHERE user_id IN (SELECT id FROM "user" WHERE username LIKE 'democoach%');

DELETE FROM "user" WHERE username LIKE 'democoach%' OR username LIKE 'demostudent%';

DELETE FROM auth.identities
WHERE user_id IN (SELECT id FROM auth.users WHERE email LIKE 'democoach%@demo.passe');

DELETE FROM auth.users
WHERE email LIKE 'democoach%@demo.passe' OR email LIKE 'demostudent%@demo.passe';

-- ── 1. Generation ───────────────────────────────────────────────────────────
DO $$
DECLARE
    v_password text := '12345678';
    v_today    timestamptz := date_trunc('day', now());

    v_names    text[] := ARRAY['Soccer Coach 1','Soccer Coach 2 (Youth)','Basketball Coach',
                               'Badminton Coach','Tennis Coach','Pickleball Coach',
                               'Soccer Coach 3 (Goalkeeper)'];
    v_email    text[] := ARRAY['democoach1','democoach2','democoach3','democoach4',
                               'democoach5','democoach6','democoach7'];
    v_sport    int[]  := ARRAY[1,1,2,3,4,5,1];
    v_sporttag text[] := ARRAY['soccer','basketball','badminton','tennis','pickleball']; -- index = sport_id
    v_bio      text[] := ARRAY[
        'Cựu cầu thủ phong trào TP.HCM, 9 năm kinh nghiệm huấn luyện kỹ thuật cá nhân và chiến thuật. Từng dẫn dắt đội futsal vô địch giải quận.',
        'Chuyên huấn luyện bóng đá thiếu nhi 8-14 tuổi, chú trọng nền tảng kỹ thuật và tinh thần đồng đội. Có chứng chỉ HLV trẻ cấp độ C.',
        'HLV bóng rổ cá nhân hoá, tập trung kỹ thuật ném rổ và di chuyển không bóng. Từng thi đấu giải sinh viên toàn quốc.',
        'HLV cầu lông cho người mới bắt đầu và trình độ phong trào, chuyên chỉnh kỹ thuật cầm vợt và di chuyển sân.',
        'Cựu tuyển thủ tennis phong trào, 10 năm kinh nghiệm huấn luyện từ nhập môn đến nâng cao. Chuyên sửa kỹ thuật giao bóng và trái tay.',
        'HLV pickleball năng động, đam mê lan toả bộ môn đang thịnh hành tới người chơi mới.',
        'Chuyên gia đào tạo thủ môn, từng thi đấu tại giải phong trào hạng nhất TP.HCM. Huấn luyện phản xạ, bắt bóng bổng và chỉ huy hàng thủ.'
    ];
    v_experience int[]     := ARRAY[9,6,5,4,10,2,7];
    v_price      numeric[] := ARRAY[300000,250000,220000,180000,350000,150000,260000];
    v_district   text[]    := ARRAY['hcm_saigon','hcm_thuduc','hcm_binhthanh','hcm_phunhuan',
                                     'hcm_tanthuan','hcm_govap','hcm_banco'];
    v_start_hour int[]     := ARRAY[18,16,19,17,7,8,18];

    v_course_name text[] := ARRAY['Kỹ thuật nền tảng bóng đá','Bóng đá thiếu nhi','Rèn kỹ năng ném rổ',
                                  'Cầu lông cho người mới','Tennis kỹ thuật nâng cao','Pickleball cơ bản',
                                  'Đào tạo thủ môn chuyên sâu'];
    v_course_desc text[] := ARRAY[
        'Khoá học tập trung kiểm soát bóng, chuyền ngắn và tư duy chiến thuật cơ bản, phù hợp người mới bắt đầu.',
        'Lớp học vui nhộn giúp các bạn nhỏ làm quen kỹ thuật bóng đá cơ bản và rèn luyện thể chất.',
        'Buổi tập 1 kèm 1 cải thiện form ném, ném phạt và tốc độ ra tay.',
        'Khoá học nhập môn: cầm vợt, phát cầu, di chuyển và các cú đánh cơ bản.',
        'Hoàn thiện cú thuận tay, trái tay và chiến thuật thi đấu đơn.',
        'Làm quen luật chơi, kỹ thuật giao bóng và volley cơ bản.',
        'Chương trình chuyên biệt cho thủ môn: phản xạ, bắt bóng bổng và phát bóng.'
    ];
    v_target     int[] := ARRAY[12,10,6,8,12,6,10];
    v_enrolled_n int[] := ARRAY[4,3,1,3,4,1,2];
    v_past_n     int[] := ARRAY[2,2,1,1,2,1,1];

    v_has_inquiring        boolean[] := ARRAY[true,false,false,false,false,false,true];
    v_has_pending_proposal boolean[] := ARRAY[true,false,false,true,false,false,false];
    v_has_pending_report   boolean[] := ARRAY[false,false,false,false,false,true,false];
    v_has_ended            boolean[] := ARRAY[true,false,false,false,true,false,false];
    v_ended_name text[] := ARRAY['Khoá nâng cao thủ môn','','','','Tennis nhập môn','',''];
    v_ended_desc text[] := ARRAY[
        'Khoá học chuyên sâu kỹ thuật bắt bóng, phản xạ và chỉ huy hàng thủ cho thủ môn.','','','',
        'Khoá học làm quen mặt sân, cầm vợt và các cú đánh cơ bản cho người mới.','',''];
    v_review_body text[] := ARRAY[
        'Huấn luyện viên rất tận tâm, mình tiến bộ rõ rệt sau khoá học!',
        'Buổi tập chất lượng, chỉ tiếc lịch hơi khó xếp vào cuối tuần.',
        'Thầy dạy rất dễ hiểu, mình đánh bóng ổn định chỉ sau vài buổi.',
        'Rất chuyên nghiệp, lịch tập linh hoạt, sẽ tiếp tục học thêm.'
    ];
    v_review_rating int[] := ARRAY[5,4,5,5];

    v_report_templates text[] := ARRAY[
        'Buổi tập hôm nay tiến bộ rõ rệt, tiếp tục duy trì nhé!',
        'Kỹ thuật đã cải thiện nhiều, cần chú ý thêm về thể lực.',
        'Tinh thần tập luyện rất tốt, hãy giữ vững phong độ này.',
        'Cần luyện thêm phần xử lý tình huống, các phần khác đều ổn.',
        'Rất chủ động trong buổi tập, tiếp tục phát huy nhé!'
    ];
    v_report_i int := 0;

    v_student_uid    uuid[] := '{}';
    v_student_cursor int := 1;

    v_coach_uid uuid;
    v_pro_id    uuid;
    v_loc       uuid;
    v_course_id uuid;
    v_conv_id   uuid;
    v_start     timestamptz;

    v_course_students uuid[];
    v_past_activity   uuid[];
    v_review_idx      int;

    i int; j int; p int; v_id uuid; v_joined timestamptz;
BEGIN
    -- ── 24 demo students (never signed in — same non-usable password hash
    -- convention as mocked_seed.sql) ────────────────────────────────────────
    FOR j IN 1..24 LOOP
        v_id := gen_random_uuid();
        INSERT INTO auth.users (
            instance_id, id, aud, role, email, encrypted_password,
            email_confirmed_at, created_at, updated_at,
            raw_app_meta_data, raw_user_meta_data,
            confirmation_token, recovery_token, email_change_token_new, email_change)
        VALUES (
            '00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated',
            'demostudent' || lpad(j::text, 2, '0') || '@demo.passe',
            '$2a$10$PznXR5Vz3pMfqVbKwR0bcebFX74Cb6m9o0bRfWiwwH/9eS/uxHHTK',
            now(), now(), now(),
            '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
            '', '', '', '');

        UPDATE "user" SET
            tag_number = lpad((9500 + j)::text, 4, '0'),
            details = jsonb_build_object(
                'gender', CASE WHEN j % 2 = 0 THEN 'male' ELSE 'female' END,
                'ageGroup', (ARRAY['student','mature','middleAge'])[1 + (j % 3)])
        WHERE id = v_id;

        v_student_uid := array_append(v_student_uid, v_id);
    END LOOP;

    -- ── 7 loggable coaches ───────────────────────────────────────────────────
    FOR i IN 1..7 LOOP
        v_coach_uid := gen_random_uuid();
        INSERT INTO auth.users (
            instance_id, id, aud, role, email, encrypted_password,
            email_confirmed_at, created_at, updated_at,
            raw_app_meta_data, raw_user_meta_data,
            confirmation_token, recovery_token, email_change_token_new, email_change)
        VALUES (
            '00000000-0000-0000-0000-000000000000', v_coach_uid, 'authenticated', 'authenticated',
            v_email[i] || '@demo.passe',
            crypt(v_password, gen_salt('bf')),
            now(), now(), now(),
            '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
            '', '', '', '');

        INSERT INTO auth.identities (
            provider_id, user_id, identity_data, provider, created_at, updated_at)
        VALUES (
            v_coach_uid::text, v_coach_uid,
            jsonb_build_object('sub', v_coach_uid::text, 'email', v_email[i] || '@demo.passe',
                                'email_verified', true, 'phone_verified', false),
            'email', now(), now());

        UPDATE "user" SET
            tag_number = lpad((9600 + i)::text, 4, '0'),
            details = jsonb_build_object(
                'gender', CASE WHEN i % 2 = 0 THEN 'female' ELSE 'male' END,
                'ageGroup', 'mature')
        WHERE id = v_coach_uid;

        -- placeholder Zalo number so the profile's contact button renders
        -- client-side (lib/professional/controller.dart reads
        -- professional.linked_user_id → user_contact.zalo)
        INSERT INTO user_contact (user_id, zalo) VALUES (v_coach_uid, '090000000' || i);

        -- a real HCM venue matching the coach's sport
        SELECT id INTO v_loc FROM location
        WHERE city_cluster = 1
          AND tags @> ARRAY['sport:[' || v_sporttag[v_sport[i]] || ']']
          AND coalesce(name, '') <> ''
        ORDER BY id OFFSET (i % 5) LIMIT 1;

        INSERT INTO professional (
            linked_user_id, professional_role, display_name, bio, is_verified, sports,
            experience_years, preferred_city_cluster, preferred_districts, schedule)
        VALUES (
            v_coach_uid, 'coach', v_names[i], v_bio[i], true, ARRAY[v_sport[i]]::bigint[],
            v_experience[i], 1, ARRAY[v_district[i]],
            (SELECT jsonb_agg(jsonb_build_object('dayOfWeek', d, 'dayChunk', c))
             FROM unnest(ARRAY['mon','tue','wed','thu','fri','sat','sun']) AS d
             CROSS JOIN unnest(ARRAY['early','midday','noon','night']) AS c))
        RETURNING id INTO v_pro_id;

        INSERT INTO professional_service (
            professional_id, sport_id, service_type, service_description,
            price_amount, pricing_kind, min_duration_minutes, max_participants, is_active)
        VALUES (
            v_pro_id, v_sport[i], 'coaching', 'Buổi tập cá nhân/nhóm nhỏ',
            v_price[i], 'hourly', 60, 4, true);

        -- ── Active course ────────────────────────────────────────────────────
        INSERT INTO course (professional_id, sport_id, name, description, target_session_count,
                            status, created_at)
        VALUES (v_pro_id, v_sport[i], v_course_name[i], v_course_desc[i], v_target[i],
                'active', v_today - interval '25 days')
        RETURNING id INTO v_course_id;

        INSERT INTO conversation (kind, course_id) VALUES ('course', v_course_id)
        RETURNING id INTO v_conv_id;

        v_course_students := '{}';

        FOR j IN 1..v_enrolled_n[i] LOOP
            v_id := v_student_uid[v_student_cursor];
            v_student_cursor := v_student_cursor + 1;
            v_joined := v_today - interval '20 days';
            v_course_students := array_append(v_course_students, v_id);

            INSERT INTO course_member (course_id, user_id, status, joined_at)
            VALUES (v_course_id, v_id, 'enrolled', v_joined);
            INSERT INTO conversation_member (conversation_id, user_id, joined_at)
            VALUES (v_conv_id, v_id, v_joined);

            INSERT INTO message (conversation_id, kind, body, payload, created_at)
            VALUES (v_conv_id, 'system', 'enrollment_accepted',
                    jsonb_build_object('username', (SELECT username FROM "user" WHERE id = v_id)),
                    v_joined);

            IF j = 1 THEN
                INSERT INTO message (conversation_id, sender_id, kind, body, created_at)
                VALUES (v_conv_id, v_id, 'text', 'Chào thầy/cô, em rất mong được học ạ!',
                        v_joined + interval '1 hour');
                INSERT INTO message (conversation_id, sender_id, kind, body, created_at)
                VALUES (v_conv_id, v_coach_uid, 'text',
                        'Chào em, mình đã sắp lịch buổi tập rồi, em kiểm tra lịch giúp mình nhé.',
                        v_joined + interval '3 hours');
            END IF;
        END LOOP;

        -- past sessions (approved, already happened)
        v_past_activity := '{}';
        FOR p IN 1..v_past_n[i] LOOP
            v_start := v_today - (v_past_n[i] - p + 1) * interval '7 days'
                       + make_interval(hours => v_start_hour[i]);
            INSERT INTO activity (user_id, sport_id, start_time, end_time, location_id,
                                  course_id, proposed_by, proposal_status)
            VALUES (v_coach_uid, v_sport[i], v_start, v_start + interval '90 minutes', v_loc,
                    v_course_id, v_coach_uid, 'approved')
            RETURNING id INTO v_id;
            v_past_activity := array_append(v_past_activity, v_id);
        END LOOP;

        -- attendance + reports for every past session × every enrolled student,
        -- except the pending-report showcase coach, whose last past session is
        -- left deliberately unreported.
        FOR p IN 1..array_length(v_past_activity, 1) LOOP
            FOREACH v_id IN ARRAY v_course_students LOOP
                INSERT INTO activity_confirmation (activity_id, user_id, attendance)
                VALUES (v_past_activity[p], v_id, 'going');

                IF NOT (v_has_pending_report[i] AND p = array_length(v_past_activity, 1)) THEN
                    v_report_i := v_report_i + 1;
                    INSERT INTO course_session_report (course_id, activity_id, student_id, body, created_at)
                    VALUES (v_course_id, v_past_activity[p], v_id,
                            v_report_templates[1 + (v_report_i % 5)],
                            (SELECT a.end_time FROM activity a WHERE a.id = v_past_activity[p]) + interval '30 minutes');
                END IF;
            END LOOP;
        END LOOP;

        -- one upcoming approved session; the first 1-2 students already RSVP'd
        v_start := v_today + interval '4 days' + make_interval(hours => v_start_hour[i]);
        INSERT INTO activity (user_id, sport_id, start_time, end_time, location_id,
                              course_id, proposed_by, proposal_status)
        VALUES (v_coach_uid, v_sport[i], v_start, v_start + interval '90 minutes', v_loc,
                v_course_id, v_coach_uid, 'approved')
        RETURNING id INTO v_id;
        FOR j IN 1..least(2, array_length(v_course_students, 1)) LOOP
            INSERT INTO activity_confirmation (activity_id, user_id, attendance)
            VALUES (v_id, v_course_students[j], 'going');
        END LOOP;

        -- pending session proposal awaiting the coach's approval
        IF v_has_pending_proposal[i] THEN
            v_start := v_today + interval '7 days' + make_interval(hours => v_start_hour[i]);
            INSERT INTO activity (user_id, sport_id, start_time, end_time, location_id,
                                  course_id, proposed_by, proposal_status)
            VALUES (v_course_students[1], v_sport[i], v_start, v_start + interval '90 minutes', v_loc,
                    v_course_id, v_course_students[1], 'pending')
            RETURNING id INTO v_id;
            INSERT INTO message (conversation_id, kind, body, payload, created_at)
            VALUES (v_conv_id, 'system', 'activity_proposed',
                    jsonb_build_object('activity_id', v_id, 'username',
                                        (SELECT username FROM "user" WHERE id = v_course_students[1])),
                    v_start - interval '2 days');
        END IF;

        -- pending enrollment offer (an inquiring lead who hasn't accepted yet)
        IF v_has_inquiring[i] THEN
            v_id := v_student_uid[v_student_cursor];
            v_student_cursor := v_student_cursor + 1;
            v_joined := v_today - interval '1 day';

            INSERT INTO course_member (course_id, user_id, status, joined_at)
            VALUES (v_course_id, v_id, 'inquiring', v_joined);
            INSERT INTO conversation_member (conversation_id, user_id, joined_at)
            VALUES (v_conv_id, v_id, v_joined);
            INSERT INTO course_enrollment_offer (course_id, user_id, name, description, target_session_count)
            VALUES (v_course_id, v_id, v_course_name[i], v_course_desc[i], v_target[i]);
        END IF;

        -- ── Ended course + reviews (average_rating comes from the trigger) ───
        IF v_has_ended[i] THEN
            INSERT INTO course (professional_id, sport_id, name, description, target_session_count,
                                status, created_at, ended_at)
            VALUES (v_pro_id, v_sport[i], v_ended_name[i], v_ended_desc[i], 2,
                    'ended', v_today - interval '70 days', v_today - interval '40 days')
            RETURNING id INTO v_course_id;

            INSERT INTO conversation (kind, course_id) VALUES ('course', v_course_id)
            RETURNING id INTO v_conv_id;

            v_past_activity := '{}';
            FOR p IN 1..2 LOOP
                v_start := v_today - interval '70 days' + (p - 1) * interval '10 days'
                           + make_interval(hours => v_start_hour[i]);
                INSERT INTO activity (user_id, sport_id, start_time, end_time, location_id,
                                      course_id, proposed_by, proposal_status)
                VALUES (v_coach_uid, v_sport[i], v_start, v_start + interval '90 minutes', v_loc,
                        v_course_id, v_coach_uid, 'approved')
                RETURNING id INTO v_id;
                v_past_activity := array_append(v_past_activity, v_id);
            END LOOP;

            FOR j IN 1..2 LOOP
                v_id := v_student_uid[v_student_cursor];
                v_student_cursor := v_student_cursor + 1;
                v_joined := v_today - interval '65 days';

                INSERT INTO course_member (course_id, user_id, status, joined_at, left_at)
                VALUES (v_course_id, v_id, 'left', v_joined, v_today - interval '40 days');
                INSERT INTO conversation_member (conversation_id, user_id, joined_at, left_at)
                VALUES (v_conv_id, v_id, v_joined, v_today - interval '40 days');
                INSERT INTO message (conversation_id, kind, body, payload, created_at)
                VALUES (v_conv_id, 'system', 'enrollment_accepted',
                        jsonb_build_object('username', (SELECT username FROM "user" WHERE id = v_id)),
                        v_joined);

                FOR p IN 1..2 LOOP
                    INSERT INTO activity_confirmation (activity_id, user_id, attendance)
                    VALUES (v_past_activity[p], v_id, 'going');
                    v_report_i := v_report_i + 1;
                    INSERT INTO course_session_report (course_id, activity_id, student_id, body, created_at)
                    VALUES (v_course_id, v_past_activity[p], v_id,
                            v_report_templates[1 + (v_report_i % 5)],
                            (SELECT a.end_time FROM activity a WHERE a.id = v_past_activity[p]) + interval '30 minutes');
                END LOOP;

                v_review_idx := CASE WHEN i = 1 THEN j ELSE j + 2 END;
                INSERT INTO course_review (course_id, student_id, rating, comment, created_at)
                VALUES (v_course_id, v_id, v_review_rating[v_review_idx],
                        v_review_body[v_review_idx], v_today - interval '35 days' + j * interval '3 days');
            END LOOP;

            INSERT INTO message (conversation_id, kind, body, created_at)
            VALUES (v_conv_id, 'system', 'course_ended', v_today - interval '40 days');
        END IF;
    END LOOP;
END $$;
