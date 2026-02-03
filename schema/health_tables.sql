-- Health feature tables migration
-- Run this in Supabase SQL editor

-- ===========================================
-- 1. Health service linking status
-- ===========================================
CREATE TYPE "public"."health_platform" AS ENUM (
    'apple_health',
    'google_fit',
    'health_connect'
);

CREATE TABLE IF NOT EXISTS "public"."user_health_link" (
    "user_id" UUID PRIMARY KEY REFERENCES "public"."user"("id") ON DELETE CASCADE,
    "platform" "public"."health_platform" NOT NULL,
    "linked_at" TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    "last_sync_at" TIMESTAMPTZ
);

ALTER TABLE "public"."user_health_link" OWNER TO "postgres";

COMMENT ON TABLE "public"."user_health_link" IS 'Tracks user health service (Apple Health/Google Fit) linking status';

-- ===========================================
-- 2. Activity table (lobby or professional session)
-- ===========================================
CREATE TABLE IF NOT EXISTS "public"."activity" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL REFERENCES "public"."user"("id") ON DELETE CASCADE,
    "sport_id" BIGINT NOT NULL REFERENCES "public"."sport"("id"),
    "start_time" TIMESTAMPTZ NOT NULL,
    "end_time" TIMESTAMPTZ,

    -- Either lobby-bound or professional session (nullable - allows standalone activities)
    "lobby_id" UUID REFERENCES "public"."lobby"("id") ON DELETE SET NULL,
    "professional_booking_id" UUID REFERENCES "public"."professional_booking"("id") ON DELETE SET NULL,

    "created_at" TIMESTAMPTZ DEFAULT NOW() NOT NULL,

    -- Ensure activity has valid time range when end_time is set
    CONSTRAINT "activity_time_validity" CHECK ("end_time" IS NULL OR "end_time" > "start_time"),
    -- Can be linked to at most one of lobby or professional booking
    CONSTRAINT "activity_source_exclusivity" CHECK (
        NOT ("lobby_id" IS NOT NULL AND "professional_booking_id" IS NOT NULL)
    )
);

ALTER TABLE "public"."activity" OWNER TO "postgres";

COMMENT ON TABLE "public"."activity" IS 'User activity sessions - can be linked to lobby or professional booking';

-- Index for querying user activities
CREATE INDEX "idx_activity_user_id" ON "public"."activity" ("user_id");
CREATE INDEX "idx_activity_start_time" ON "public"."activity" ("start_time");
CREATE INDEX "idx_activity_sport_id" ON "public"."activity" ("sport_id");

-- ===========================================
-- 3. Activity health metrics (aggregates)
-- ===========================================
CREATE TABLE IF NOT EXISTS "public"."activity_health_metrics" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL REFERENCES "public"."user"("id") ON DELETE CASCADE,
    "activity_id" UUID NOT NULL REFERENCES "public"."activity"("id") ON DELETE CASCADE,

    -- Activity metrics
    "steps" INT,
    "distance_meters" REAL,
    "active_calories" REAL,

    -- Heart rate aggregates (computed from samples)
    "avg_heart_rate" INT,
    "max_heart_rate" INT,
    "min_heart_rate" INT,

    -- HRV metrics (from Apple Health / Health Connect)
    "hrv_sdnn_ms" REAL,           -- Standard deviation of NN intervals (milliseconds)
    "hrv_rmssd_ms" REAL,          -- Root mean square of successive differences

    -- HR Zone distribution (seconds spent in each zone)
    -- Zones based on % of max HR: Z1(50-60%), Z2(60-70%), Z3(70-80%), Z4(80-90%), Z5(90-100%)
    "hr_zone_1_seconds" INT,
    "hr_zone_2_seconds" INT,
    "hr_zone_3_seconds" INT,
    "hr_zone_4_seconds" INT,
    "hr_zone_5_seconds" INT,

    -- Derived performance metrics
    "training_load" REAL,         -- TRIMP or similar score
    "effort_score" REAL,          -- 0-100 normalized effort

    -- Weight (snapshot at time of activity)
    "weight_kg" REAL,

    -- Workout type from health platform (e.g., 'running', 'soccer', etc.)
    "workout_type" TEXT,

    "recorded_at" TIMESTAMPTZ DEFAULT NOW() NOT NULL,

    -- One metrics record per activity
    CONSTRAINT "activity_health_metrics_unique" UNIQUE ("user_id", "activity_id"),

    -- Validate heart rate ranges
    CONSTRAINT "heart_rate_validity" CHECK (
        ("avg_heart_rate" IS NULL OR ("avg_heart_rate" >= 30 AND "avg_heart_rate" <= 250)) AND
        ("max_heart_rate" IS NULL OR ("max_heart_rate" >= 30 AND "max_heart_rate" <= 250)) AND
        ("min_heart_rate" IS NULL OR ("min_heart_rate" >= 30 AND "min_heart_rate" <= 250))
    )
);

ALTER TABLE "public"."activity_health_metrics" OWNER TO "postgres";

COMMENT ON TABLE "public"."activity_health_metrics" IS 'Aggregated health metrics for user activities';

CREATE INDEX "idx_activity_health_metrics_user_id" ON "public"."activity_health_metrics" ("user_id");
CREATE INDEX "idx_activity_health_metrics_activity_id" ON "public"."activity_health_metrics" ("activity_id");

-- ===========================================
-- 4. Raw heart rate samples (for detailed analysis)
-- ===========================================
CREATE TABLE IF NOT EXISTS "public"."activity_hr_sample" (
    "id" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "activity_id" UUID NOT NULL REFERENCES "public"."activity"("id") ON DELETE CASCADE,
    "timestamp" TIMESTAMPTZ NOT NULL,
    "bpm" SMALLINT NOT NULL,

    CONSTRAINT "hr_sample_bpm_validity" CHECK ("bpm" >= 30 AND "bpm" <= 250)
);

ALTER TABLE "public"."activity_hr_sample" OWNER TO "postgres";

COMMENT ON TABLE "public"."activity_hr_sample" IS 'Raw heart rate samples during activities - enables HR curve reconstruction and detailed analysis';

-- Optimized index for time-series queries
CREATE INDEX "idx_activity_hr_sample_activity_timestamp" ON "public"."activity_hr_sample" ("activity_id", "timestamp");

-- ===========================================
-- 5. Daily health summary (for trend analysis)
-- ===========================================
CREATE TABLE IF NOT EXISTS "public"."daily_health_summary" (
    "user_id" UUID NOT NULL REFERENCES "public"."user"("id") ON DELETE CASCADE,
    "date" DATE NOT NULL,

    -- Resting vitals
    "resting_heart_rate" INT,
    "hrv_sdnn_ms" REAL,

    -- Daily totals
    "steps" INT,
    "distance_meters" REAL,
    "active_calories" REAL,
    "total_calories" REAL,

    -- Sleep
    "sleep_minutes" INT,
    "sleep_quality_score" REAL,   -- 0-100 if available

    -- Weight tracking
    "weight_kg" REAL,

    -- Activity count for the day
    "activity_count" INT DEFAULT 0,
    "total_activity_minutes" INT DEFAULT 0,

    "synced_at" TIMESTAMPTZ DEFAULT NOW() NOT NULL,

    PRIMARY KEY ("user_id", "date"),

    CONSTRAINT "resting_hr_validity" CHECK (
        "resting_heart_rate" IS NULL OR ("resting_heart_rate" >= 30 AND "resting_heart_rate" <= 150)
    )
);

ALTER TABLE "public"."daily_health_summary" OWNER TO "postgres";

COMMENT ON TABLE "public"."daily_health_summary" IS 'Daily health metrics for long-term trend analysis';

CREATE INDEX "idx_daily_health_summary_user_date" ON "public"."daily_health_summary" ("user_id", "date" DESC);

-- ===========================================
-- 6. Row Level Security Policies
-- ===========================================

ALTER TABLE "public"."user_health_link" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."activity" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."activity_health_metrics" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."activity_hr_sample" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."daily_health_summary" ENABLE ROW LEVEL SECURITY;

-- user_health_link policies
CREATE POLICY "Users can view their own health link"
    ON "public"."user_health_link" FOR SELECT
    TO "authenticated"
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own health link"
    ON "public"."user_health_link" FOR INSERT
    TO "authenticated"
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own health link"
    ON "public"."user_health_link" FOR UPDATE
    TO "authenticated"
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own health link"
    ON "public"."user_health_link" FOR DELETE
    TO "authenticated"
    USING (user_id = auth.uid());

-- activity policies
CREATE POLICY "Users can view their own activities"
    ON "public"."activity" FOR SELECT
    TO "authenticated"
    USING (user_id = auth.uid());

CREATE POLICY "Users can create their own activities"
    ON "public"."activity" FOR INSERT
    TO "authenticated"
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own activities"
    ON "public"."activity" FOR UPDATE
    TO "authenticated"
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own activities"
    ON "public"."activity" FOR DELETE
    TO "authenticated"
    USING (user_id = auth.uid());

-- activity_health_metrics policies
CREATE POLICY "Users can view their own health metrics"
    ON "public"."activity_health_metrics" FOR SELECT
    TO "authenticated"
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own health metrics"
    ON "public"."activity_health_metrics" FOR INSERT
    TO "authenticated"
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own health metrics"
    ON "public"."activity_health_metrics" FOR UPDATE
    TO "authenticated"
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own health metrics"
    ON "public"."activity_health_metrics" FOR DELETE
    TO "authenticated"
    USING (user_id = auth.uid());

-- activity_hr_sample policies (via activity ownership)
CREATE POLICY "Users can view HR samples for their activities"
    ON "public"."activity_hr_sample" FOR SELECT
    TO "authenticated"
    USING (EXISTS (
        SELECT 1 FROM "public"."activity" a
        WHERE a.id = activity_id AND a.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert HR samples for their activities"
    ON "public"."activity_hr_sample" FOR INSERT
    TO "authenticated"
    WITH CHECK (EXISTS (
        SELECT 1 FROM "public"."activity" a
        WHERE a.id = activity_id AND a.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete HR samples for their activities"
    ON "public"."activity_hr_sample" FOR DELETE
    TO "authenticated"
    USING (EXISTS (
        SELECT 1 FROM "public"."activity" a
        WHERE a.id = activity_id AND a.user_id = auth.uid()
    ));

-- daily_health_summary policies
CREATE POLICY "Users can view their own daily summaries"
    ON "public"."daily_health_summary" FOR SELECT
    TO "authenticated"
    USING (user_id = auth.uid());

CREATE POLICY "Users can upsert their own daily summaries"
    ON "public"."daily_health_summary" FOR INSERT
    TO "authenticated"
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own daily summaries"
    ON "public"."daily_health_summary" FOR UPDATE
    TO "authenticated"
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- ===========================================
-- 7. Grants
-- ===========================================

GRANT ALL ON TABLE "public"."user_health_link" TO "anon";
GRANT ALL ON TABLE "public"."user_health_link" TO "authenticated";
GRANT ALL ON TABLE "public"."user_health_link" TO "service_role";

GRANT ALL ON TABLE "public"."activity" TO "anon";
GRANT ALL ON TABLE "public"."activity" TO "authenticated";
GRANT ALL ON TABLE "public"."activity" TO "service_role";

GRANT ALL ON TABLE "public"."activity_health_metrics" TO "anon";
GRANT ALL ON TABLE "public"."activity_health_metrics" TO "authenticated";
GRANT ALL ON TABLE "public"."activity_health_metrics" TO "service_role";

GRANT ALL ON TABLE "public"."activity_hr_sample" TO "anon";
GRANT ALL ON TABLE "public"."activity_hr_sample" TO "authenticated";
GRANT ALL ON TABLE "public"."activity_hr_sample" TO "service_role";

GRANT ALL ON TABLE "public"."daily_health_summary" TO "anon";
GRANT ALL ON TABLE "public"."daily_health_summary" TO "authenticated";
GRANT ALL ON TABLE "public"."daily_health_summary" TO "service_role";

GRANT USAGE, SELECT ON SEQUENCE "public"."activity_hr_sample_id_seq" TO "anon";
GRANT USAGE, SELECT ON SEQUENCE "public"."activity_hr_sample_id_seq" TO "authenticated";
GRANT USAGE, SELECT ON SEQUENCE "public"."activity_hr_sample_id_seq" TO "service_role";
