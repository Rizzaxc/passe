

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pgsodium";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_jsonschema" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "unaccent" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."country" AS ENUM (
    'VN'
);


ALTER TYPE "public"."country" OWNER TO "postgres";


CREATE TYPE "public"."gender" AS ENUM (
    'M',
    'F'
);


ALTER TYPE "public"."gender" OWNER TO "postgres";


CREATE TYPE "public"."lobby_befriend_interaction" AS ENUM (
    'request',
    'invite',
    'pair'
);


ALTER TYPE "public"."lobby_befriend_interaction" OWNER TO "postgres";


CREATE TYPE "public"."lobby_befriend_status" AS ENUM (
    'pending',
    'accepted',
    'declined',
    'cancelled'
);


ALTER TYPE "public"."lobby_befriend_status" OWNER TO "postgres";


CREATE TYPE "public"."lobby_visibility" AS ENUM (
    'private',
    'discoverable',
    'public'
);


ALTER TYPE "public"."lobby_visibility" OWNER TO "postgres";


CREATE TYPE "public"."professional_booking_status" AS ENUM (
    'requested',
    'rejected',
    'confirmed',
    'cancelled_by_client',
    'cancelled_by_pro',
    'completed'
);


ALTER TYPE "public"."professional_booking_status" OWNER TO "postgres";


CREATE TYPE "public"."professional_role" AS ENUM (
    'coach',
    'referee'
);


ALTER TYPE "public"."professional_role" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_profile_compat_score"("p_user_id" "uuid", "p_target_id" "uuid", "p_sport_id" bigint) RETURNS numeric
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
DECLARE
    score NUMERIC := 0;
    max_raw_score NUMERIC := 8; -- Maximum possible raw score before rescaling
    max_final_score NUMERIC := 5; -- Desired maximum score after rescaling
    min_score NUMERIC := 1;
    is_user BOOLEAN;
    host_id UUID;
    user_details JSONB;
    target_details JSONB;
    sport_id_text TEXT;
    shared_network_count INTEGER := 0;
    active_shared_network_count INTEGER := 0;
    shared_industry_count INTEGER := 0;
    lobby_members_with_shared_network INTEGER := 0;
    total_lobby_members INTEGER := 0;
    lobby_members_with_same_skill INTEGER := 0;
    user_skill_level INTEGER;
    has_active_shared_member BOOLEAN := FALSE;
BEGIN
    -- Convert sport ID to text for accessing JSON
    sport_id_text := p_sport_id::TEXT;

    -- Determine if target is a user or a lobby
    SELECT EXISTS(SELECT 1 FROM public."user" WHERE id = p_target_id) INTO is_user;

    -- Get user details
    SELECT details INTO user_details FROM public."user" WHERE id = p_user_id;

    -- Extract user's skill level for the context sport - adjusted to match schema
    IF user_details->'sport' ? sport_id_text AND user_details->'sport'->sport_id_text ? 'skill' THEN
        user_skill_level := (user_details->'sport'->sport_id_text->>'skill')::INTEGER;
    ELSE
        user_skill_level := NULL;
    END IF;

    IF is_user THEN
        -- =============================================
        -- USER-TO-USER COMPATIBILITY CALCULATION
        -- =============================================

        -- Get target user details
        SELECT details INTO target_details FROM public."user" WHERE id = p_target_id;

        -- Check if they share at least one network (+3)
        SELECT COUNT(*) INTO shared_network_count
        FROM public.user_network un1
                 JOIN public.user_network un2 ON un1.network_id = un2.network_id
        WHERE un1.user_id = p_user_id AND un2.user_id = p_target_id;

        IF shared_network_count > 0 THEN
            score := score + 3;

            -- Check if they're both currently members of a shared network (not alumni) (+2)
            SELECT COUNT(*) INTO active_shared_network_count
            FROM public.user_network un1
                     JOIN public.user_network un2 ON un1.network_id = un2.network_id
            WHERE un1.user_id = p_user_id
              AND un2.user_id = p_target_id
              AND NOT un1.alumni
              AND NOT un2.alumni;

            IF active_shared_network_count > 0 THEN
                score := score + 2;
            END IF;
        ELSE
            -- If they don't share a network, check if they share an industry (+2)
            SELECT COUNT(*) INTO shared_industry_count
            FROM public.user_industry ui1
                     JOIN public.user_industry ui2 ON ui1.industry_id = ui2.industry_id
            WHERE ui1.user_id = p_user_id AND ui2.user_id = p_target_id;

            IF shared_industry_count > 0 THEN
                score := score + 2;
            END IF;
        END IF;

        -- Check if they are at the same skill level for the context sport (+2)
        -- Updated to match the JSON schema structure
        IF user_skill_level IS NOT NULL AND
           target_details->'sport' ? sport_id_text AND
           target_details->'sport'->sport_id_text ? 'skill' AND
           user_skill_level = (target_details->'sport'->sport_id_text->>'skill')::INTEGER THEN
            score := score + 2;
        END IF;

    ELSE
        -- =============================================
        -- USER-TO-LOBBY COMPATIBILITY CALCULATION
        -- =============================================

        -- Get lobby details and count members
        SELECT COUNT(*) INTO total_lobby_members
        FROM public.lobby_member
        WHERE lobby_id = p_target_id;

        -- Get the lobby host/captain ID
        SELECT captain_id INTO host_id
        FROM public.lobby
        WHERE id = p_target_id;

        -- If there's only one member (the host), treat as user-to-user interaction
        IF total_lobby_members = 1 AND host_id IS NOT NULL THEN
            -- Recursive call with the host's ID
            RETURN public.calculate_profile_compat_score(p_user_id, host_id, p_sport_id);
        END IF;

        -- Count lobby members who share a network with the user
        SELECT COUNT(DISTINCT lm.user_id) INTO lobby_members_with_shared_network
        FROM public.lobby_member lm
                 JOIN public.user_network un_member ON lm.user_id = un_member.user_id
                 JOIN public.user_network un_user ON un_member.network_id = un_user.network_id
        WHERE lm.lobby_id = p_target_id
          AND un_user.user_id = p_user_id;

        -- Check if at least one lobby member shares a network with the user
        -- and is not an alumni (+1 for shared network, +1 for active member)
        IF lobby_members_with_shared_network >= 1 THEN
            -- Check if they have at least 3 shared members (+4)
            IF lobby_members_with_shared_network >= 3 THEN
                score := score + 4;
            ELSE
                -- If less than 3 shared members, give +1 for at least one shared network
                score := score + 1;

                -- Check if any of the shared members are active (both user and member are not alumni)
                SELECT EXISTS (
                    SELECT 1
                    FROM public.lobby_member lm
                             JOIN public.user_network un_member ON lm.user_id = un_member.user_id
                             JOIN public.user_network un_user ON un_member.network_id = un_user.network_id
                    WHERE lm.lobby_id = p_target_id
                      AND un_user.user_id = p_user_id
                      AND NOT un_member.alumni
                      AND NOT un_user.alumni
                ) INTO has_active_shared_member;

                IF has_active_shared_member THEN
                    score := score + 1;
                END IF;
            END IF;
        END IF;

        -- Count lobby members with the same skill level as the user
        -- Updated to match the JSON schema structure
        IF user_skill_level IS NOT NULL THEN
            SELECT COUNT(DISTINCT lm.user_id) INTO lobby_members_with_same_skill
            FROM public.lobby_member lm
                     JOIN public."user" u ON lm.user_id = u.id
            WHERE lm.lobby_id = p_target_id
              AND u.details->'sport' ? sport_id_text
              AND u.details->'sport'->sport_id_text ? 'skill'
              AND (u.details->'sport'->sport_id_text->>'skill')::INTEGER = user_skill_level;

            -- If at least half of the lobby members are at the same skill level as the user (+4)
            IF lobby_members_with_same_skill >= (total_lobby_members / 2) THEN
                score := score + 4;
            END IF;
        END IF;
    END IF;

    -- Properly rescale score to range from min_score to max_final_score
    -- Formula: rescaled = min + (score/max_raw_score) * (max_final_score - min_score)
    score := min_score + (score / max_raw_score) * (max_final_score - min_score);

    -- Ensure we don't go below minimum
    score := GREATEST(min_score, score);

    RETURN score;
END;
$$;


ALTER FUNCTION "public"."calculate_profile_compat_score"("p_user_id" "uuid", "p_target_id" "uuid", "p_sport_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_timeslot_compat_score"("source" "jsonb", "target" "jsonb") RETURNS integer
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
DECLARE
    total_score INTEGER := 0;
    source_day TEXT;
    source_chunks JSONB;
    target_chunks JSONB;
    chunk TEXT;
BEGIN
    FOR source_day, source_chunks IN SELECT * FROM jsonb_each(source)
        LOOP
            IF target ? source_day THEN
                -- Day match: 2 points
                total_score := total_score + 2;

                -- Check for matching chunks
                target_chunks := target->source_day;

                IF jsonb_typeof(source_chunks) = 'array' AND jsonb_typeof(target_chunks) = 'array' THEN
                    FOR chunk IN SELECT jsonb_array_elements_text(source_chunks)
                        LOOP
                            IF target_chunks @> jsonb_build_array(chunk) THEN
                                -- Chunk match: 2 additional points
                                total_score := total_score + 2;
                            END IF;
                        END LOOP;
                END IF;
            END IF;
        END LOOP;

    RETURN total_score;
END;
$$;


ALTER FUNCTION "public"."calculate_timeslot_compat_score"("source" "jsonb", "target" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_popular_networks"("limit_count" integer DEFAULT 5) RETURNS TABLE("id" bigint, "name" "text", "category" "text")
    LANGUAGE "sql"
    SET "search_path" TO ''
    AS $$
SELECT
    n.id,
    n.name,
    n.category
FROM public.network n
         LEFT JOIN public.user_network un ON n.id = un.network_id
GROUP BY n.id, n.name, n.category
ORDER BY COUNT(un.user_id) DESC, n.name
LIMIT limit_count;
$$;


ALTER FUNCTION "public"."get_popular_networks"("limit_count" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."home_teammate_lobby_data"("p_sport_id" bigint, "p_timeslots" "jsonb", "p_city" integer, "p_districts" character varying[], "p_page_size" integer DEFAULT 10, "p_page_number" integer DEFAULT 1) RETURNS TABLE("id" "uuid", "name" character varying, "homeground_name" character varying, "playtime" "jsonb", "details" "jsonb", "visibility" "public"."lobby_visibility", "timeslot_compat_score" integer, "profile_compat_score" numeric)
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
    RETURN QUERY
        SELECT
            l.id,
            l.name,
            loc.name AS homeground_name,
            l.playtime,
            l.details,
            l.visibility,
            ts_score AS timeslot_compat_score,
            profile_score AS profile_compat_score
        FROM
            public.lobby l
                JOIN
            public.location loc ON l.home_ground = loc.id
                CROSS JOIN LATERAL (
                SELECT public.calculate_timeslot_compat_score(p_timeslots, l.playtime) AS ts_score
                ) ts
                CROSS JOIN LATERAL (
                SELECT public.calculate_profile_compat_score(auth.uid(), l.id, l.sport_id) AS profile_score
                ) ps
        WHERE
            l.sport_id = p_sport_id
          AND l.visibility != 'private'
          AND loc.city_cluster = p_city
          AND loc.district = ANY(p_districts)
          AND ts.ts_score >= 4
        ORDER BY
            profile_compat_score DESC,
            timeslot_compat_score DESC
        LIMIT p_page_size
            OFFSET (p_page_number - 1) * p_page_size;
END;
$$;


ALTER FUNCTION "public"."home_teammate_lobby_data"("p_sport_id" bigint, "p_timeslots" "jsonb", "p_city" integer, "p_districts" character varying[], "p_page_size" integer, "p_page_number" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."immutable_unaccent"("text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    SET "search_path" TO ''
    AS $_$
SELECT extensions.unaccent($1)
$_$;


ALTER FUNCTION "public"."immutable_unaccent"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."nanoid"("size" integer DEFAULT 10, "alphabet" "text" DEFAULT '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'::"text") RETURNS "text"
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO ''
    AS $$
DECLARE
    idBuilder text := '';
    i int := 0;
    bytes bytea;
    alphabetIndex int;
    mask int;
    step int;
BEGIN
    mask := (2 << cast(floor(log(length(alphabet) - 1) / log(2)) as int)) -1;
    step := cast(ceil(1.6 * mask * size / length(alphabet)) AS int);

    while true loop
            bytes := gen_random_bytes(size);
            while i < size loop
                    alphabetIndex := get_byte(bytes, i) & mask;
                    if alphabetIndex < length(alphabet) then
                        idBuilder := idBuilder || substr(alphabet, alphabetIndex, 1);
                        if length(idBuilder) = size then
                            return idBuilder;
                        end if;
                    end if;
                    i = i + 1;
                end loop;

            i := 0;
        end loop;
END
$$;


ALTER FUNCTION "public"."nanoid"("size" integer, "alphabet" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."new_user_created_trigger_fn"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
    insert into public.user(id, username)
    values (new.id,
            substring(split_part(new.email, '@', 1), 1, 16));
    return new;
end;
$$;


ALTER FUNCTION "public"."new_user_created_trigger_fn"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."professional_booking_review_updated_trigger_fn"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
BEGIN
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        UPDATE public.professional
        SET
            average_rating = (
                SELECT COALESCE(AVG(rating), 0.00)
                FROM public.professional_booking_review
                WHERE professional_id = NEW.professional_id
            ),
            review_count = (
                SELECT COUNT(*)
                FROM public.professional_booking_review
                WHERE professional_id = NEW.professional_id
            )
        WHERE id = NEW.professional_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.professional
        SET
            average_rating = (
                SELECT COALESCE(AVG(rating), 0.00)
                FROM public.professional_booking_review
                WHERE professional_id = OLD.professional_id
            ),
            review_count = (
                SELECT COUNT(*)
                FROM public.professional_booking_review
                WHERE professional_id = OLD.professional_id
            )
        WHERE id = OLD.professional_id;
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."professional_booking_review_updated_trigger_fn"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."search_networks_unaccent"("search_term" "text", "result_limit" integer DEFAULT 20) RETURNS TABLE("id" bigint, "name" "text", "category" "text")
    LANGUAGE "sql"
    SET "search_path" TO ''
    AS $$
SELECT
    n.id,
    n.name,
    n.category
FROM public.network n
WHERE
    -- Try both accented and unaccented matching for Vietnamese text
    (extensions.unaccent(LOWER(n.name)) ILIKE '%' || extensions.unaccent(LOWER(search_term)) || '%'
        OR LOWER(n.name) ILIKE '%' || LOWER(search_term) || '%')
ORDER BY
    -- Prioritize exact matches, then prefix matches, then contains
    CASE
        WHEN LOWER(n.name) = LOWER(search_term) THEN 1
        WHEN LOWER(n.name) LIKE LOWER(search_term) || '%' THEN 2
        WHEN extensions.unaccent(LOWER(n.name)) LIKE extensions.unaccent(LOWER(search_term)) || '%' THEN 3
        ELSE 4
        END,
    n.name
LIMIT result_limit;
$$;


ALTER FUNCTION "public"."search_networks_unaccent"("search_term" "text", "result_limit" integer) OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."booking_additional_users" (
    "booking_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL
);


ALTER TABLE "public"."booking_additional_users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."industry" (
    "id" integer NOT NULL,
    "name" character varying(128) NOT NULL
);


ALTER TABLE "public"."industry" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."industry_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."industry_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."industry_id_seq" OWNED BY "public"."industry"."id";



CREATE TABLE IF NOT EXISTS "public"."lobby" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "captain_id" "uuid" NOT NULL,
    "searchable_id" "text" DEFAULT "public"."nanoid"(8) NOT NULL,
    "name" "text" NOT NULL,
    "sport_id" bigint NOT NULL,
    "playtime" "jsonb",
    "details" "jsonb",
    "home_ground" "uuid",
    "visibility" "public"."lobby_visibility" DEFAULT 'discoverable'::"public"."lobby_visibility"
);


ALTER TABLE "public"."lobby" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."lobby_befriend_record" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "initiator_user_id" "uuid" NOT NULL,
    "target_user_id" "uuid",
    "target_lobby_id" "uuid",
    "interaction_type" "public"."lobby_befriend_interaction" NOT NULL,
    "status" "public"."lobby_befriend_status" DEFAULT 'pending'::"public"."lobby_befriend_status" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "details" "jsonb",
    CONSTRAINT "befriend_record_invite_conditions" CHECK ((("interaction_type" <> 'invite'::"public"."lobby_befriend_interaction") OR ("target_user_id" IS NOT NULL))),
    CONSTRAINT "befriend_record_pair_conditions" CHECK ((("interaction_type" <> 'pair'::"public"."lobby_befriend_interaction") OR (("target_user_id" IS NOT NULL) AND ("target_lobby_id" IS NULL) AND ("initiator_user_id" <> "target_user_id")))),
    CONSTRAINT "befriend_record_request_conditions" CHECK ((("interaction_type" <> 'request'::"public"."lobby_befriend_interaction") OR (("target_user_id" IS NULL) AND ("target_lobby_id" IS NOT NULL))))
);


ALTER TABLE "public"."lobby_befriend_record" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."lobby_member" (
    "id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "lobby_id" "uuid" NOT NULL
);


ALTER TABLE "public"."lobby_member" OWNER TO "postgres";


COMMENT ON TABLE "public"."lobby_member" IS 'join table between user and lobby';



ALTER TABLE "public"."lobby_member" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."lobby_member_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."location" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "external_id" "text",
    "name" "text" NOT NULL,
    "full_address" "text" NOT NULL,
    "street_number" integer,
    "street_name" "text",
    "district" "text",
    "city" "text",
    "lat" double precision NOT NULL,
    "lon" double precision NOT NULL,
    "tags" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "city_cluster" bigint NOT NULL
);


ALTER TABLE "public"."location" OWNER TO "postgres";


COMMENT ON COLUMN "public"."location"."lat" IS 'latitude';



COMMENT ON COLUMN "public"."location"."lon" IS 'longitude';



CREATE TABLE IF NOT EXISTS "public"."network" (
    "id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "category" "text",
    "city" bigint,
    CONSTRAINT "network_category_check" CHECK (("category" = ANY (ARRAY['high school'::"text", 'gifted high school'::"text", 'university'::"text", 'company'::"text"])))
);


ALTER TABLE "public"."network" OWNER TO "postgres";


COMMENT ON TABLE "public"."network" IS 'entities/ organizations that users may share';



ALTER TABLE "public"."network" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."network_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."professional" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "linked_user_id" "uuid",
    "professional_role" "public"."professional_role" NOT NULL,
    "display_name" "text" NOT NULL,
    "bio" "text",
    "contact_details" "jsonb",
    "certifications" "jsonb",
    "schedule" "jsonb",
    "schedule_note" "text",
    "is_verified" boolean DEFAULT false NOT NULL,
    "sports" bigint[] NOT NULL,
    "experience_years" integer,
    "average_rating" numeric(3,2) DEFAULT 0.00,
    "review_count" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "professional_experience_years_check" CHECK (("experience_years" >= 0)),
    CONSTRAINT "professional_sports_check" CHECK (("array_length"("sports", 1) > 0))
);


ALTER TABLE "public"."professional" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."professional_booking" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "client_user_id" "uuid" NOT NULL,
    "service_id" "uuid" NOT NULL,
    "professional_id" "uuid" NOT NULL,
    "event_id" "uuid",
    "location_id" "uuid",
    "booking_time_start" timestamp with time zone NOT NULL,
    "booking_time_end" timestamp with time zone NOT NULL,
    "agreed_rate" numeric(10,2),
    "status" "public"."professional_booking_status" DEFAULT 'requested'::"public"."professional_booking_status" NOT NULL,
    "client_notes" "text",
    "professional_notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "booking_times_validity" CHECK (("booking_time_end" > "booking_time_start")),
    CONSTRAINT "professional_booking_agreed_rate_check" CHECK (("agreed_rate" >= (0)::numeric)),
    CONSTRAINT "professional_booking_status_check" CHECK (("status" <> 'completed'::"public"."professional_booking_status"))
);


ALTER TABLE "public"."professional_booking" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."professional_booking_review" (
    "booking_id" "uuid" NOT NULL,
    "reviewer_user_id" "uuid" NOT NULL,
    "professional_id" "uuid" NOT NULL,
    "rating" numeric(2,1) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "professional_booking_review_rating_check" CHECK ((("rating" >= 0.5) AND ("rating" <= 5.0) AND (("rating" * (2)::numeric) = "floor"(("rating" * (2)::numeric)))))
);


ALTER TABLE "public"."professional_booking_review" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."professional_service" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "professional_id" "uuid" NOT NULL,
    "sport_id" bigint NOT NULL,
    "service_type" "text" NOT NULL,
    "service_description" "text",
    "hourly_rate" numeric(10,2),
    "min_duration_minutes" integer,
    "max_participants" integer,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "professional_service_hourly_rate_check" CHECK (("hourly_rate" >= (0)::numeric)),
    CONSTRAINT "professional_service_max_participants_check" CHECK (("max_participants" >= 1)),
    CONSTRAINT "professional_service_min_duration_minutes_check" CHECK (("min_duration_minutes" > 0))
);


ALTER TABLE "public"."professional_service" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sport" (
    "id" bigint NOT NULL,
    "name" "text" NOT NULL
);


ALTER TABLE "public"."sport" OWNER TO "postgres";


ALTER TABLE "public"."sport" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."sport_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."supported_city_cluster" (
    "id" bigint NOT NULL,
    "country" "public"."country" DEFAULT 'VN'::"public"."country" NOT NULL,
    "name" "text" NOT NULL
);


ALTER TABLE "public"."supported_city_cluster" OWNER TO "postgres";


ALTER TABLE "public"."supported_city_cluster" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."supported_city_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."user" (
    "id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "username" character varying(16) DEFAULT "public"."nanoid"(16) NOT NULL,
    "tag_number" character varying(4) DEFAULT "lpad"(((("floor"(("random"() * (10000)::double precision)))::integer)::character varying)::"text", 4, '0'::"text") NOT NULL,
    "details" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    CONSTRAINT "user_details_schema" CHECK ("extensions"."jsonb_matches_schema"('{
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "description": "Freeform data for user profile",
          "type": "object",
          "properties": {
            "gender": {
              "type": "string"
            },
            "age_group": {
              "type": "string"
            },
            "playtime": {
              "type": "array"
            },
            "location": {
              "type": "object",
              "properties": {
                "city": {
                  "type": "integer"
                },
                "districts": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            },
            "sport": {
              "description": "Sport profile for the user",
              "type": "object",
              "properties": {
                "1": {
                  "title": "Soccer",
                  "type": "object",
                  "properties": {
                    "skill": {
                      "type": "integer"
                    }
                  }
                },
                "2": {
                  "title": "Basketball",
                  "type": "object",
                  "properties": {
                    "skill": {
                      "type": "integer"
                    }
                  }
                },
                "3": {
                  "title": "Badminton",
                  "type": "object",
                  "properties": {
                    "skill": {
                      "type": "integer"
                    }
                  }
                },
                "4": {
                  "title": "Tennis",
                  "type": "object",
                  "properties": {
                    "skill": {
                      "type": "integer"
                    }
                  }
                },
                "5": {
                  "title": "Pickleball",
                  "type": "object",
                  "properties": {
                    "skill": {
                      "type": "integer"
                    }
                  }
                }
              }
            }
          }
        }'::"json", "details"))
);


ALTER TABLE "public"."user" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_industry" (
    "id" bigint NOT NULL,
    "user_id" "uuid",
    "industry_id" integer
);


ALTER TABLE "public"."user_industry" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_industry" IS 'join table for `user` and `industry`';



ALTER TABLE "public"."user_industry" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."user_industry_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."user_network" (
    "id" bigint NOT NULL,
    "user_id" "uuid",
    "network_id" bigint,
    "alumni" boolean DEFAULT true NOT NULL
);


ALTER TABLE "public"."user_network" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_network" IS 'join table for `user` and `network`';



ALTER TABLE "public"."user_network" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."user_network_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE ONLY "public"."industry" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."industry_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."booking_additional_users"
    ADD CONSTRAINT "booking_additional_users_pkey" PRIMARY KEY ("booking_id", "user_id");



ALTER TABLE ONLY "public"."industry"
    ADD CONSTRAINT "industry_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."industry"
    ADD CONSTRAINT "industry_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."lobby_befriend_record"
    ADD CONSTRAINT "lobby_befriend_record_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."lobby_member"
    ADD CONSTRAINT "lobby_member_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."lobby"
    ADD CONSTRAINT "lobby_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."location"
    ADD CONSTRAINT "location_external_id_key" UNIQUE ("external_id");



ALTER TABLE ONLY "public"."location"
    ADD CONSTRAINT "location_full_address_key" UNIQUE ("full_address");



ALTER TABLE ONLY "public"."location"
    ADD CONSTRAINT "location_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."network"
    ADD CONSTRAINT "network_name_city_key" UNIQUE ("name", "city");



ALTER TABLE ONLY "public"."network"
    ADD CONSTRAINT "network_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."professional_booking"
    ADD CONSTRAINT "professional_booking_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."professional_booking_review"
    ADD CONSTRAINT "professional_booking_review_pkey" PRIMARY KEY ("booking_id");



ALTER TABLE ONLY "public"."professional"
    ADD CONSTRAINT "professional_linked_user_id_key" UNIQUE ("linked_user_id");



ALTER TABLE ONLY "public"."professional"
    ADD CONSTRAINT "professional_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."professional_service"
    ADD CONSTRAINT "professional_service_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sport"
    ADD CONSTRAINT "sport_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."sport"
    ADD CONSTRAINT "sport_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."supported_city_cluster"
    ADD CONSTRAINT "supported_city_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_industry"
    ADD CONSTRAINT "user_industry_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_network"
    ADD CONSTRAINT "user_network_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user"
    ADD CONSTRAINT "user_pk" UNIQUE ("username", "tag_number");



ALTER TABLE ONLY "public"."user"
    ADD CONSTRAINT "user_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_bookings_client_user_id" ON "public"."professional_booking" USING "btree" ("client_user_id");



CREATE INDEX "idx_bookings_professional_id" ON "public"."professional_booking" USING "btree" ("professional_id");



CREATE INDEX "idx_bookings_service_id" ON "public"."professional_booking" USING "btree" ("service_id");



CREATE INDEX "idx_bookings_status" ON "public"."professional_booking" USING "btree" ("status");



CREATE INDEX "idx_listed_professionals_is_verified" ON "public"."professional" USING "btree" ("is_verified");



CREATE INDEX "idx_listed_professionals_linked_user_id" ON "public"."professional" USING "btree" ("linked_user_id") WHERE ("linked_user_id" IS NOT NULL);



CREATE INDEX "idx_listed_professionals_role" ON "public"."professional" USING "btree" ("professional_role");



CREATE INDEX "idx_lobby_befriend_record_initiator" ON "public"."lobby_befriend_record" USING "btree" ("initiator_user_id");



CREATE INDEX "idx_lobby_befriend_record_interaction_type" ON "public"."lobby_befriend_record" USING "btree" ("interaction_type");



CREATE INDEX "idx_lobby_befriend_record_status" ON "public"."lobby_befriend_record" USING "btree" ("status");



CREATE INDEX "idx_lobby_befriend_record_target_lobby" ON "public"."lobby_befriend_record" USING "btree" ("target_lobby_id");



CREATE INDEX "idx_lobby_befriend_record_target_user" ON "public"."lobby_befriend_record" USING "btree" ("target_user_id");



CREATE INDEX "idx_professional_review_professional_id" ON "public"."professional_booking_review" USING "btree" ("professional_id");



CREATE INDEX "idx_professional_review_reviewer_user_id" ON "public"."professional_booking_review" USING "btree" ("reviewer_user_id");



CREATE INDEX "idx_professional_services_is_active" ON "public"."professional_service" USING "btree" ("is_active");



CREATE INDEX "idx_professional_services_listed_professional_id" ON "public"."professional_service" USING "btree" ("professional_id");



CREATE INDEX "idx_professional_services_sport_id" ON "public"."professional_service" USING "btree" ("sport_id");



CREATE INDEX "network_name_fts_english_idx" ON "public"."network" USING "gin" ("to_tsvector"('"english"'::"regconfig", "name"));



CREATE INDEX "network_name_fts_simple_idx" ON "public"."network" USING "gin" ("to_tsvector"('"simple"'::"regconfig", "name"));



CREATE INDEX "network_name_lower_idx" ON "public"."network" USING "btree" ("lower"("name") "text_pattern_ops");



CREATE INDEX "network_name_partial_idx" ON "public"."network" USING "btree" ("name" "text_pattern_ops");



CREATE INDEX "network_name_unaccent_idx" ON "public"."network" USING "btree" ("public"."immutable_unaccent"("lower"("name")) "text_pattern_ops");



CREATE OR REPLACE TRIGGER "professional_review_stats_trigger" AFTER INSERT OR DELETE OR UPDATE ON "public"."professional_booking_review" FOR EACH ROW EXECUTE FUNCTION "public"."professional_booking_review_updated_trigger_fn"();



ALTER TABLE ONLY "public"."booking_additional_users"
    ADD CONSTRAINT "booking_additional_users_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."professional_booking"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."booking_additional_users"
    ADD CONSTRAINT "booking_additional_users_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."lobby_befriend_record"
    ADD CONSTRAINT "lobby_befriend_record_initiator_user_id_fkey" FOREIGN KEY ("initiator_user_id") REFERENCES "public"."user"("id") ON UPDATE CASCADE;



ALTER TABLE ONLY "public"."lobby_befriend_record"
    ADD CONSTRAINT "lobby_befriend_record_target_lobby_id_fkey" FOREIGN KEY ("target_lobby_id") REFERENCES "public"."lobby"("id") ON UPDATE CASCADE;



ALTER TABLE ONLY "public"."lobby_befriend_record"
    ADD CONSTRAINT "lobby_befriend_record_target_user_id_fkey" FOREIGN KEY ("target_user_id") REFERENCES "public"."user"("id") ON UPDATE CASCADE;



ALTER TABLE ONLY "public"."lobby"
    ADD CONSTRAINT "lobby_captain_id_fkey" FOREIGN KEY ("captain_id") REFERENCES "public"."user"("id") ON UPDATE CASCADE;



ALTER TABLE ONLY "public"."lobby"
    ADD CONSTRAINT "lobby_home_ground_fkey" FOREIGN KEY ("home_ground") REFERENCES "public"."location"("id");



ALTER TABLE ONLY "public"."lobby_member"
    ADD CONSTRAINT "lobby_member_lobby_id_fkey" FOREIGN KEY ("lobby_id") REFERENCES "public"."lobby"("id");



ALTER TABLE ONLY "public"."lobby_member"
    ADD CONSTRAINT "lobby_member_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id");



ALTER TABLE ONLY "public"."lobby"
    ADD CONSTRAINT "lobby_sport_id_fkey" FOREIGN KEY ("sport_id") REFERENCES "public"."sport"("id");



ALTER TABLE ONLY "public"."location"
    ADD CONSTRAINT "location_city_cluster_fkey" FOREIGN KEY ("city_cluster") REFERENCES "public"."supported_city_cluster"("id");



ALTER TABLE ONLY "public"."network"
    ADD CONSTRAINT "network_city_fkey" FOREIGN KEY ("city") REFERENCES "public"."supported_city_cluster"("id");



ALTER TABLE ONLY "public"."professional_booking"
    ADD CONSTRAINT "professional_booking_client_user_id_fkey" FOREIGN KEY ("client_user_id") REFERENCES "public"."user"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."professional_booking"
    ADD CONSTRAINT "professional_booking_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "public"."location"("id");



ALTER TABLE ONLY "public"."professional_booking"
    ADD CONSTRAINT "professional_booking_professional_id_fkey" FOREIGN KEY ("professional_id") REFERENCES "public"."professional"("id");



ALTER TABLE ONLY "public"."professional_booking_review"
    ADD CONSTRAINT "professional_booking_review_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."professional_booking"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."professional_booking_review"
    ADD CONSTRAINT "professional_booking_review_professional_id_fkey" FOREIGN KEY ("professional_id") REFERENCES "public"."professional"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."professional_booking_review"
    ADD CONSTRAINT "professional_booking_review_reviewer_user_id_fkey" FOREIGN KEY ("reviewer_user_id") REFERENCES "public"."user"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."professional_booking"
    ADD CONSTRAINT "professional_booking_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "public"."professional_service"("id");



ALTER TABLE ONLY "public"."professional"
    ADD CONSTRAINT "professional_linked_user_id_fkey" FOREIGN KEY ("linked_user_id") REFERENCES "public"."user"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."professional_service"
    ADD CONSTRAINT "professional_service_professional_id_fkey" FOREIGN KEY ("professional_id") REFERENCES "public"."professional"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."professional_service"
    ADD CONSTRAINT "professional_service_sport_id_fkey" FOREIGN KEY ("sport_id") REFERENCES "public"."sport"("id");



ALTER TABLE ONLY "public"."user"
    ADD CONSTRAINT "user_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE;



ALTER TABLE ONLY "public"."user_industry"
    ADD CONSTRAINT "user_industry_industry_id_fkey" FOREIGN KEY ("industry_id") REFERENCES "public"."industry"("id");



ALTER TABLE ONLY "public"."user_industry"
    ADD CONSTRAINT "user_industry_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id");



ALTER TABLE ONLY "public"."user_network"
    ADD CONSTRAINT "user_network_network_id_fkey" FOREIGN KEY ("network_id") REFERENCES "public"."network"("id");



ALTER TABLE ONLY "public"."user_network"
    ADD CONSTRAINT "user_network_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id");



CREATE POLICY "Additional users can see bookings they are part of" ON "public"."booking_additional_users" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Client can manage additional users for their bookings" ON "public"."booking_additional_users" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."professional_booking" "pb"
  WHERE (("pb"."id" = "booking_additional_users"."booking_id") AND ("pb"."client_user_id" = ( SELECT "auth"."uid"() AS "uid")))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."professional_booking" "pb"
  WHERE (("pb"."id" = "booking_additional_users"."booking_id") AND ("pb"."client_user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Clients can create reviews for their completed bookings" ON "public"."professional_booking_review" FOR INSERT TO "authenticated" WITH CHECK ((("reviewer_user_id" = ( SELECT "auth"."uid"() AS "uid")) AND (EXISTS ( SELECT 1
   FROM "public"."professional_booking" "pb"
  WHERE (("pb"."id" = "professional_booking_review"."booking_id") AND ("pb"."client_user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("pb"."status" = 'completed'::"public"."professional_booking_status"))))));



CREATE POLICY "Clients can manage their own bookings" ON "public"."professional_booking" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "client_user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "client_user_id"));



CREATE POLICY "Enable insert for authenticated users only" ON "public"."lobby" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable read access for all users" ON "public"."industry" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."lobby" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."location" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."network" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."sport" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."supported_city_cluster" FOR SELECT USING (true);



CREATE POLICY "Enable read access for authenticated user" ON "public"."user_industry" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable read access for authenticated users" ON "public"."user" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable read access for authenticated users" ON "public"."user_network" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable read access for verified professional profiles" ON "public"."professional" FOR SELECT TO "anon" USING (("is_verified" = true));



CREATE POLICY "Enable read for active services by verified professionals" ON "public"."professional_service" FOR SELECT TO "authenticated", "anon" USING ((("is_active" = true) AND (EXISTS ( SELECT 1
   FROM "public"."professional" "p"
  WHERE (("p"."id" = "professional_service"."professional_id") AND ("p"."is_verified" = true))))));



CREATE POLICY "Enable user to update their own profile" ON "public"."user" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "id"));



CREATE POLICY "Linked professionals can manage their bookings" ON "public"."professional_booking" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."professional" "p"
  WHERE (("p"."id" = "professional_booking"."professional_id") AND ("p"."linked_user_id" = ( SELECT "auth"."uid"() AS "uid")))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."professional" "p"
  WHERE (("p"."id" = "professional_booking"."professional_id") AND ("p"."linked_user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Linked professionals can manage their own services" ON "public"."professional_service" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."professional" "p"
  WHERE (("p"."id" = "professional_service"."professional_id") AND ("p"."linked_user_id" = ( SELECT "auth"."uid"() AS "uid")))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."professional" "p"
  WHERE (("p"."id" = "professional_service"."professional_id") AND ("p"."linked_user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Linked users can manage their own professional profile" ON "public"."professional" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "linked_user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "linked_user_id"));



CREATE POLICY "Users can create befriend records with restrictions" ON "public"."lobby_befriend_record" FOR INSERT TO "authenticated" WITH CHECK ((true AND (("interaction_type" <> 'request'::"public"."lobby_befriend_interaction") OR (NOT (EXISTS ( SELECT 1
   FROM "public"."lobby"
  WHERE (("lobby"."id" = "lobby_befriend_record"."target_lobby_id") AND ("lobby"."visibility" = 'private'::"public"."lobby_visibility"))))))));



CREATE POLICY "Users can delete their own data" ON "public"."user_industry" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can insert their own data" ON "public"."user_industry" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can view befriend records" ON "public"."lobby_befriend_record" FOR SELECT TO "authenticated" USING (((( SELECT "auth"."uid"() AS "uid") = "target_user_id") OR (( SELECT "auth"."uid"() AS "uid") = "initiator_user_id") OR ("target_lobby_id" IN ( SELECT "lobby_member"."lobby_id"
   FROM "public"."lobby_member"
  WHERE ("lobby_member"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Users involved can update befriend record status" ON "public"."lobby_befriend_record" FOR UPDATE TO "authenticated" USING (((( SELECT "auth"."uid"() AS "uid") = "initiator_user_id") OR (( SELECT "auth"."uid"() AS "uid") = "target_user_id") OR (("target_lobby_id" IS NOT NULL) AND ("target_lobby_id" IN ( SELECT "lobby"."id"
   FROM "public"."lobby"
  WHERE ("lobby"."captain_id" = ( SELECT "auth"."uid"() AS "uid"))))))) WITH CHECK (true);



ALTER TABLE "public"."booking_additional_users" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."industry" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."lobby" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."lobby_befriend_record" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."lobby_member" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."location" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."network" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."professional" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."professional_booking" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."professional_booking_review" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."professional_service" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sport" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."supported_city_cluster" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_industry" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_network" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";












































































































































































































GRANT ALL ON FUNCTION "public"."calculate_profile_compat_score"("p_user_id" "uuid", "p_target_id" "uuid", "p_sport_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_profile_compat_score"("p_user_id" "uuid", "p_target_id" "uuid", "p_sport_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_profile_compat_score"("p_user_id" "uuid", "p_target_id" "uuid", "p_sport_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_timeslot_compat_score"("source" "jsonb", "target" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_timeslot_compat_score"("source" "jsonb", "target" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_timeslot_compat_score"("source" "jsonb", "target" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_popular_networks"("limit_count" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_popular_networks"("limit_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_popular_networks"("limit_count" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."home_teammate_lobby_data"("p_sport_id" bigint, "p_timeslots" "jsonb", "p_city" integer, "p_districts" character varying[], "p_page_size" integer, "p_page_number" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."home_teammate_lobby_data"("p_sport_id" bigint, "p_timeslots" "jsonb", "p_city" integer, "p_districts" character varying[], "p_page_size" integer, "p_page_number" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."home_teammate_lobby_data"("p_sport_id" bigint, "p_timeslots" "jsonb", "p_city" integer, "p_districts" character varying[], "p_page_size" integer, "p_page_number" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."immutable_unaccent"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."immutable_unaccent"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."immutable_unaccent"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."nanoid"("size" integer, "alphabet" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."nanoid"("size" integer, "alphabet" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."nanoid"("size" integer, "alphabet" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."new_user_created_trigger_fn"() TO "anon";
GRANT ALL ON FUNCTION "public"."new_user_created_trigger_fn"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."new_user_created_trigger_fn"() TO "service_role";



GRANT ALL ON FUNCTION "public"."professional_booking_review_updated_trigger_fn"() TO "anon";
GRANT ALL ON FUNCTION "public"."professional_booking_review_updated_trigger_fn"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."professional_booking_review_updated_trigger_fn"() TO "service_role";



GRANT ALL ON FUNCTION "public"."search_networks_unaccent"("search_term" "text", "result_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."search_networks_unaccent"("search_term" "text", "result_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_networks_unaccent"("search_term" "text", "result_limit" integer) TO "service_role";



























GRANT ALL ON TABLE "public"."booking_additional_users" TO "anon";
GRANT ALL ON TABLE "public"."booking_additional_users" TO "authenticated";
GRANT ALL ON TABLE "public"."booking_additional_users" TO "service_role";



GRANT ALL ON TABLE "public"."industry" TO "anon";
GRANT ALL ON TABLE "public"."industry" TO "authenticated";
GRANT ALL ON TABLE "public"."industry" TO "service_role";



GRANT ALL ON SEQUENCE "public"."industry_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."industry_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."industry_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."lobby" TO "anon";
GRANT ALL ON TABLE "public"."lobby" TO "authenticated";
GRANT ALL ON TABLE "public"."lobby" TO "service_role";



GRANT ALL ON TABLE "public"."lobby_befriend_record" TO "anon";
GRANT ALL ON TABLE "public"."lobby_befriend_record" TO "authenticated";
GRANT ALL ON TABLE "public"."lobby_befriend_record" TO "service_role";



GRANT ALL ON TABLE "public"."lobby_member" TO "anon";
GRANT ALL ON TABLE "public"."lobby_member" TO "authenticated";
GRANT ALL ON TABLE "public"."lobby_member" TO "service_role";



GRANT ALL ON SEQUENCE "public"."lobby_member_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."lobby_member_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."lobby_member_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."location" TO "anon";
GRANT ALL ON TABLE "public"."location" TO "authenticated";
GRANT ALL ON TABLE "public"."location" TO "service_role";



GRANT ALL ON TABLE "public"."network" TO "anon";
GRANT ALL ON TABLE "public"."network" TO "authenticated";
GRANT ALL ON TABLE "public"."network" TO "service_role";



GRANT ALL ON SEQUENCE "public"."network_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."network_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."network_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."professional" TO "anon";
GRANT ALL ON TABLE "public"."professional" TO "authenticated";
GRANT ALL ON TABLE "public"."professional" TO "service_role";



GRANT ALL ON TABLE "public"."professional_booking" TO "anon";
GRANT ALL ON TABLE "public"."professional_booking" TO "authenticated";
GRANT ALL ON TABLE "public"."professional_booking" TO "service_role";



GRANT ALL ON TABLE "public"."professional_booking_review" TO "anon";
GRANT ALL ON TABLE "public"."professional_booking_review" TO "authenticated";
GRANT ALL ON TABLE "public"."professional_booking_review" TO "service_role";



GRANT ALL ON TABLE "public"."professional_service" TO "anon";
GRANT ALL ON TABLE "public"."professional_service" TO "authenticated";
GRANT ALL ON TABLE "public"."professional_service" TO "service_role";



GRANT ALL ON TABLE "public"."sport" TO "anon";
GRANT ALL ON TABLE "public"."sport" TO "authenticated";
GRANT ALL ON TABLE "public"."sport" TO "service_role";



GRANT ALL ON SEQUENCE "public"."sport_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."sport_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."sport_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."supported_city_cluster" TO "anon";
GRANT ALL ON TABLE "public"."supported_city_cluster" TO "authenticated";
GRANT ALL ON TABLE "public"."supported_city_cluster" TO "service_role";



GRANT ALL ON SEQUENCE "public"."supported_city_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."supported_city_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."supported_city_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."user" TO "anon";
GRANT ALL ON TABLE "public"."user" TO "authenticated";
GRANT ALL ON TABLE "public"."user" TO "service_role";



GRANT ALL ON TABLE "public"."user_industry" TO "anon";
GRANT ALL ON TABLE "public"."user_industry" TO "authenticated";
GRANT ALL ON TABLE "public"."user_industry" TO "service_role";



GRANT ALL ON SEQUENCE "public"."user_industry_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_industry_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_industry_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."user_network" TO "anon";
GRANT ALL ON TABLE "public"."user_network" TO "authenticated";
GRANT ALL ON TABLE "public"."user_network" TO "service_role";



GRANT ALL ON SEQUENCE "public"."user_network_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_network_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_network_id_seq" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";






























RESET ALL;
