-- Canonical achievement catalog (production reference data, NOT mock).
-- Idempotent upsert keyed by `code`. Re-run safely to retune.
--
-- All v1 badges are sport-agnostic (sport = NULL): the driving signals are body
-- metrics. `xp_reward` is hand-set and snapshotted into user_achievement at earn
-- time, so retuning here never rewrites already-banked XP. Tuning rule: the
-- curve constant (25) ratchets DOWN only; per-badge XP here is free to move.
--
-- criteria grammar:
--   source:      daily | activity | special
--   agg:         sum | count | max | session_streak | special
--   window:      day | week | month | all_time     (calendar only)
--   metric:      a column name, or virtual 'session_load' (3-zone TRIMP)
--   threshold:   target value           comparator: >= (default) | >
--   row_min:     per-row qualifier for `count`     (e.g. activity_count >= 1)
--   session_min: per-session qualifier for `session_streak`

INSERT INTO public.achievement (code, name, description, sport, xp_reward, repeatable, difficulty, consistency, criteria) VALUES
-- ── Repeatable (the XP engine) ───────────────────────────────────────────────
('steps_50k_week',       'Chân đi không mỏi',   'Đi 50.000 bước trong tuần này.',                   NULL,  60, true,  1, 1, '{"source":"daily","agg":"sum","metric":"steps","window":"week","threshold":50000}'),
('sessions_3_week',      'Tuần tam tấu',        'Hoàn thành 3 buổi tập trong tuần này.',            NULL,  90, true,  1, 2, '{"source":"activity","agg":"count","metric":"sessions","window":"week","threshold":3}'),
('calories_800_week',    'Đốt mỡ cuối tuần',    'Đốt 800 kcal vận động trong tuần này.',            NULL,  90, true,  2, 1, '{"source":"daily","agg":"sum","metric":"active_calories","window":"week","threshold":800}'),
('steps_200k_month',     'Vạn dặm trường chinh','Đi 200.000 bước trong tháng này.',                 NULL, 120, true,  1, 2, '{"source":"daily","agg":"sum","metric":"steps","window":"month","threshold":200000}'),
('active_days_12_month', 'Lịch kín mít',        'Vận động ít nhất 12 ngày trong tháng này.',        NULL, 110, true,  1, 2, '{"source":"daily","agg":"count","metric":"activity_count","row_min":1,"window":"month","threshold":12}'),
('sessions_12_month',    'Phong độ đỉnh cao',   'Hoàn thành 12 buổi tập trong tháng này.',          NULL, 150, true,  1, 3, '{"source":"activity","agg":"count","metric":"sessions","window":"month","threshold":12}'),
('calories_3k_month',    'Lò luyện đan',        'Đốt 3.000 kcal vận động trong tháng này.',         NULL, 150, true,  2, 2, '{"source":"daily","agg":"sum","metric":"active_calories","window":"month","threshold":3000}'),
('zone1_5h_month',       'Nền tảng vững chắc',  'Tích lũy 5 giờ ở vùng nhịp tim nhẹ trong tháng.',  NULL, 110, true,  1, 2, '{"source":"activity","agg":"sum","metric":"hr_zone_easy_seconds","window":"month","threshold":18000}'),
('load_1k_month',        'Tổng lực tháng',      'Đạt 1.000 điểm tải luyện tập (TRIMP) trong tháng.',NULL, 150, true,  2, 2, '{"source":"activity","agg":"sum","metric":"session_load","window":"month","threshold":1000}'),
('streak_load_5',        'Không bỏ buổi nào',   '5 buổi tập chất lượng liên tiếp trong tháng.',     NULL, 190, true,  2, 3, '{"source":"activity","agg":"session_streak","metric":"session_load","session_min":50,"window":"month","threshold":5}'),
('streak_load_4',        'Lửa thử vàng',        '4 buổi tập nặng liên tiếp trong tháng.',           NULL, 310, true,  3, 3, '{"source":"activity","agg":"session_streak","metric":"session_load","session_min":80,"window":"month","threshold":4}'),
-- ── One-time milestones ──────────────────────────────────────────────────────
('link_wearable',        'Khởi động!',          'Kết nối thiết bị đeo sức khỏe.',                   NULL,  50, false, 1, 1, '{"source":"special","agg":"special","threshold":1}'),
('first_session',        'Phát súng đầu tiên',  'Ghi nhận buổi tập đầu tiên.',                      NULL, 100, false, 1, 1, '{"source":"activity","agg":"count","metric":"sessions","window":"all_time","threshold":1}'),
('first_10k_day',        'Mười nghìn bước chân','Đi 10.000 bước trong một ngày.',                   NULL, 100, false, 1, 1, '{"source":"daily","agg":"max","metric":"steps","window":"all_time","threshold":10000}'),
('active_days_30',       'Thói quen vàng',      'Vận động tổng cộng 30 ngày.',                      NULL, 200, false, 1, 3, '{"source":"daily","agg":"count","metric":"activity_count","row_min":1,"window":"all_time","threshold":30}'),
('sessions_10',          'Tân binh',            'Hoàn thành 10 buổi tập.',                          NULL, 150, false, 1, 2, '{"source":"activity","agg":"count","metric":"sessions","window":"all_time","threshold":10}'),
('sessions_50',          'Kỳ cựu',              'Hoàn thành 50 buổi tập.',                          NULL, 300, false, 1, 3, '{"source":"activity","agg":"count","metric":"sessions","window":"all_time","threshold":50}'),
('sessions_100',         'Huyền thoại sân bãi', 'Hoàn thành 100 buổi tập.',                         NULL, 500, false, 2, 3, '{"source":"activity","agg":"count","metric":"sessions","window":"all_time","threshold":100}'),
('distance_50k',         'Phượt thủ',           'Di chuyển tổng cộng 50 km trong các buổi tập.',    NULL, 150, false, 1, 2, '{"source":"activity","agg":"sum","metric":"distance_meters","window":"all_time","threshold":50000}'),
('distance_250k',        'Vượt đường trường',   'Di chuyển tổng cộng 250 km trong các buổi tập.',   NULL, 350, false, 2, 3, '{"source":"activity","agg":"sum","metric":"distance_meters","window":"all_time","threshold":250000}'),
('calories_50k',         'Vạn ngọn lửa',        'Đốt tổng cộng 50.000 kcal trong các buổi tập.',    NULL, 350, false, 2, 3, '{"source":"activity","agg":"sum","metric":"active_calories","window":"all_time","threshold":50000}'),
('first_hard_hour',      'Nếm mùi cực hạn',     'Tích lũy 1 giờ ở vùng nhịp tim cao.',              NULL, 200, false, 3, 1, '{"source":"activity","agg":"sum","metric":"hr_zone_hard_seconds","window":"all_time","threshold":3600}'),
('single_cal_1000',      'Bùng nổ',             'Đốt 1.000 kcal trong một buổi tập.',               NULL, 200, false, 3, 1, '{"source":"activity","agg":"max","metric":"active_calories","window":"all_time","threshold":1000}'),
('load_pr',              'Đỉnh của chóp',       'Đạt 120 điểm tải luyện tập trong một buổi.',       NULL, 200, false, 3, 1, '{"source":"activity","agg":"max","metric":"session_load","window":"all_time","threshold":120}')
ON CONFLICT (code) DO UPDATE SET
  name        = EXCLUDED.name,
  description = EXCLUDED.description,
  sport       = EXCLUDED.sport,
  xp_reward   = EXCLUDED.xp_reward,
  repeatable  = EXCLUDED.repeatable,
  difficulty  = EXCLUDED.difficulty,
  consistency = EXCLUDED.consistency,
  criteria    = EXCLUDED.criteria;

-- Now that the catalog is populated, enforce the invariants.
ALTER TABLE public.achievement
  ALTER COLUMN code SET NOT NULL,
  ALTER COLUMN criteria SET NOT NULL;
