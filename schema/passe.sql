--
-- PostgreSQL database dump
--

\restrict 7BlJnFxfvqmJomhALlsqgvOrJZQtS9WsUGPR3FV0FT0AX6k8ivcYeZfjp93vUmw

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.9 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA auth;


ALTER SCHEMA auth OWNER TO supabase_admin;

--
-- Name: pg_cron; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION pg_cron; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_cron IS 'Job scheduler for PostgreSQL';


--
-- Name: extensions; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA extensions;


ALTER SCHEMA extensions OWNER TO postgres;

--
-- Name: graphql; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA graphql;


ALTER SCHEMA graphql OWNER TO supabase_admin;

--
-- Name: graphql_public; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA graphql_public;


ALTER SCHEMA graphql_public OWNER TO supabase_admin;

--
-- Name: pg_net; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA public;


--
-- Name: EXTENSION pg_net; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_net IS 'Async HTTP';


--
-- Name: pgbouncer; Type: SCHEMA; Schema: -; Owner: pgbouncer
--

CREATE SCHEMA pgbouncer;


ALTER SCHEMA pgbouncer OWNER TO pgbouncer;

--
-- Name: pgsodium; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA pgsodium;


ALTER SCHEMA pgsodium OWNER TO supabase_admin;

--
-- Name: pgsodium; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgsodium WITH SCHEMA pgsodium;


--
-- Name: EXTENSION pgsodium; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgsodium IS 'Pgsodium is a modern cryptography library for Postgres.';


--
-- Name: realtime; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA realtime;


ALTER SCHEMA realtime OWNER TO supabase_admin;

--
-- Name: storage; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA storage;


ALTER SCHEMA storage OWNER TO supabase_admin;

--
-- Name: supabase_migrations; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA supabase_migrations;


ALTER SCHEMA supabase_migrations OWNER TO postgres;

--
-- Name: vault; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA vault;


ALTER SCHEMA vault OWNER TO supabase_admin;

--
-- Name: pg_jsonschema; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_jsonschema WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_jsonschema; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_jsonschema IS 'pg_jsonschema';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: supabase_vault; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;


--
-- Name: EXTENSION supabase_vault; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION supabase_vault IS 'Supabase Vault Extension';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA extensions;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: aal_level; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.aal_level AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


ALTER TYPE auth.aal_level OWNER TO supabase_auth_admin;

--
-- Name: code_challenge_method; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.code_challenge_method AS ENUM (
    's256',
    'plain'
);


ALTER TYPE auth.code_challenge_method OWNER TO supabase_auth_admin;

--
-- Name: factor_status; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.factor_status AS ENUM (
    'unverified',
    'verified'
);


ALTER TYPE auth.factor_status OWNER TO supabase_auth_admin;

--
-- Name: factor_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.factor_type AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


ALTER TYPE auth.factor_type OWNER TO supabase_auth_admin;

--
-- Name: oauth_authorization_status; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.oauth_authorization_status AS ENUM (
    'pending',
    'approved',
    'denied',
    'expired'
);


ALTER TYPE auth.oauth_authorization_status OWNER TO supabase_auth_admin;

--
-- Name: oauth_client_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.oauth_client_type AS ENUM (
    'public',
    'confidential'
);


ALTER TYPE auth.oauth_client_type OWNER TO supabase_auth_admin;

--
-- Name: oauth_registration_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.oauth_registration_type AS ENUM (
    'dynamic',
    'manual'
);


ALTER TYPE auth.oauth_registration_type OWNER TO supabase_auth_admin;

--
-- Name: oauth_response_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.oauth_response_type AS ENUM (
    'code'
);


ALTER TYPE auth.oauth_response_type OWNER TO supabase_auth_admin;

--
-- Name: one_time_token_type; Type: TYPE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TYPE auth.one_time_token_type AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


ALTER TYPE auth.one_time_token_type OWNER TO supabase_auth_admin;

--
-- Name: activity_attendance; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.activity_attendance AS ENUM (
    'going',
    'maybe',
    'out'
);


ALTER TYPE public.activity_attendance OWNER TO postgres;

--
-- Name: activity_cost_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.activity_cost_type AS ENUM (
    'per_pax',
    'total'
);


ALTER TYPE public.activity_cost_type OWNER TO postgres;

--
-- Name: TYPE activity_cost_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TYPE public.activity_cost_type IS 'per_pax: cost_amount is what each attendee owes. total: cost_amount is split equally (rounded up to the nearest 1000 VND) across confirmed (going) attendees, including the organizer.';


--
-- Name: activity_proposal_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.activity_proposal_status AS ENUM (
    'pending',
    'approved',
    'rejected',
    'withdrawn'
);


ALTER TYPE public.activity_proposal_status OWNER TO postgres;

--
-- Name: conversation_kind; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.conversation_kind AS ENUM (
    'freeplay',
    'course'
);


ALTER TYPE public.conversation_kind OWNER TO postgres;

--
-- Name: country; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.country AS ENUM (
    'VN'
);


ALTER TYPE public.country OWNER TO postgres;

--
-- Name: course_member_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.course_member_status AS ENUM (
    'inquiring',
    'enrolled',
    'left',
    'removed'
);


ALTER TYPE public.course_member_status OWNER TO postgres;

--
-- Name: course_offer_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.course_offer_status AS ENUM (
    'pending',
    'accepted',
    'declined',
    'withdrawn'
);


ALTER TYPE public.course_offer_status OWNER TO postgres;

--
-- Name: course_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.course_status AS ENUM (
    'active',
    'ended'
);


ALTER TYPE public.course_status OWNER TO postgres;

--
-- Name: freeplay_host_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.freeplay_host_status AS ENUM (
    'active',
    'suspended'
);


ALTER TYPE public.freeplay_host_status OWNER TO postgres;

--
-- Name: freeplay_message_kind; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.freeplay_message_kind AS ENUM (
    'text',
    'system',
    'payment_info'
);


ALTER TYPE public.freeplay_message_kind OWNER TO postgres;

--
-- Name: freeplay_request_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.freeplay_request_status AS ENUM (
    'pending',
    'accepted',
    'declined',
    'cancelled',
    'host_cancelled',
    'lapsed',
    'blocked'
);


ALTER TYPE public.freeplay_request_status OWNER TO postgres;

--
-- Name: friendship_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.friendship_status AS ENUM (
    'pending',
    'accepted',
    'declined',
    'cancelled'
);


ALTER TYPE public.friendship_status OWNER TO postgres;

--
-- Name: gender; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.gender AS ENUM (
    'M',
    'F'
);


ALTER TYPE public.gender OWNER TO postgres;

--
-- Name: health_platform; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.health_platform AS ENUM (
    'apple_health',
    'google_fit',
    'health_connect'
);


ALTER TYPE public.health_platform OWNER TO postgres;

--
-- Name: lobby_befriend_interaction; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.lobby_befriend_interaction AS ENUM (
    'request',
    'invite',
    'pair'
);


ALTER TYPE public.lobby_befriend_interaction OWNER TO postgres;

--
-- Name: lobby_befriend_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.lobby_befriend_status AS ENUM (
    'pending',
    'accepted',
    'declined',
    'cancelled'
);


ALTER TYPE public.lobby_befriend_status OWNER TO postgres;

--
-- Name: lobby_challenge_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.lobby_challenge_status AS ENUM (
    'requested',
    'accepted',
    'declined',
    'cancelled',
    'scheduled',
    'played',
    'lapsed'
);


ALTER TYPE public.lobby_challenge_status OWNER TO postgres;

--
-- Name: lobby_feed_item_kind; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.lobby_feed_item_kind AS ENUM (
    'update',
    'personal',
    'system',
    'poll',
    'photo',
    'payment_request'
);


ALTER TYPE public.lobby_feed_item_kind OWNER TO postgres;

--
-- Name: lobby_match_result; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.lobby_match_result AS ENUM (
    'win',
    'loss',
    'practice',
    'draw'
);


ALTER TYPE public.lobby_match_result OWNER TO postgres;

--
-- Name: lobby_member_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.lobby_member_role AS ENUM (
    'member',
    'coordinator'
);


ALTER TYPE public.lobby_member_role OWNER TO postgres;

--
-- Name: lobby_payment_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.lobby_payment_status AS ENUM (
    'outstanding',
    'paid_direct',
    'cleared_together'
);


ALTER TYPE public.lobby_payment_status OWNER TO postgres;

--
-- Name: lobby_visibility; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.lobby_visibility AS ENUM (
    'private',
    'discoverable',
    'public'
);


ALTER TYPE public.lobby_visibility OWNER TO postgres;

--
-- Name: message_kind; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.message_kind AS ENUM (
    'text',
    'system',
    'payment_info',
    'poll'
);


ALTER TYPE public.message_kind OWNER TO postgres;

--
-- Name: notification_kind; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.notification_kind AS ENUM (
    'activity_confirmed',
    'pro_session_reminder',
    'challenger_confirmed',
    'lobby_invite',
    'professional_booking_requested',
    'professional_booking_confirmed',
    'professional_booking_rejected',
    'challenge_received',
    'challenge_declined',
    'friend_request',
    'friend_accepted',
    'challenge_lapsed',
    'match_result_recorded',
    'challenge_scheduled',
    'payment_requested',
    'debt_collected',
    'activity_scheduled',
    'member_kicked',
    'lobby_join_request',
    'lobby_join_request_approved',
    'lobby_join_request_denied',
    'freeplay_request_received',
    'freeplay_request_accepted',
    'freeplay_request_declined',
    'freeplay_request_cancelled',
    'freeplay_activity_cancelled',
    'freeplay_chat_message',
    'course_message',
    'course_enrollment_offer',
    'course_enrollment_accepted',
    'course_activity_proposed',
    'course_activity_approved',
    'course_activity_changed',
    'course_session_report',
    'course_ended',
    'course_member_removed',
    'activity_at_risk_organizer',
    'activity_at_risk_member',
    'activity_cancelled_low_turnout'
);


ALTER TYPE public.notification_kind OWNER TO postgres;

--
-- Name: professional_booking_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.professional_booking_status AS ENUM (
    'requested',
    'rejected',
    'confirmed',
    'cancelled_by_client',
    'cancelled_by_pro',
    'completed'
);


ALTER TYPE public.professional_booking_status OWNER TO postgres;

--
-- Name: professional_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.professional_role AS ENUM (
    'coach',
    'referee'
);


ALTER TYPE public.professional_role OWNER TO postgres;

--
-- Name: action; Type: TYPE; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE TYPE realtime.action AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE',
    'ERROR'
);


ALTER TYPE realtime.action OWNER TO supabase_realtime_admin;

--
-- Name: equality_op; Type: TYPE; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE TYPE realtime.equality_op AS ENUM (
    'eq',
    'neq',
    'lt',
    'lte',
    'gt',
    'gte',
    'in',
    'like',
    'ilike',
    'is',
    'match',
    'imatch',
    'isdistinct'
);


ALTER TYPE realtime.equality_op OWNER TO supabase_realtime_admin;

--
-- Name: user_defined_filter; Type: TYPE; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE TYPE realtime.user_defined_filter AS (
	column_name text,
	op realtime.equality_op,
	value text,
	negate boolean
);


ALTER TYPE realtime.user_defined_filter OWNER TO supabase_realtime_admin;

--
-- Name: wal_column; Type: TYPE; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE TYPE realtime.wal_column AS (
	name text,
	type_name text,
	type_oid oid,
	value jsonb,
	is_pkey boolean,
	is_selectable boolean
);


ALTER TYPE realtime.wal_column OWNER TO supabase_realtime_admin;

--
-- Name: wal_rls; Type: TYPE; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE TYPE realtime.wal_rls AS (
	wal jsonb,
	is_rls_enabled boolean,
	subscription_ids uuid[],
	errors text[]
);


ALTER TYPE realtime.wal_rls OWNER TO supabase_realtime_admin;

--
-- Name: buckettype; Type: TYPE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TYPE storage.buckettype AS ENUM (
    'STANDARD',
    'ANALYTICS',
    'VECTOR'
);


ALTER TYPE storage.buckettype OWNER TO supabase_storage_admin;

--
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


ALTER FUNCTION auth.email() OWNER TO supabase_auth_admin;

--
-- Name: FUNCTION email(); Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON FUNCTION auth.email() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';


--
-- Name: jwt(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.jwt() RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


ALTER FUNCTION auth.jwt() OWNER TO supabase_auth_admin;

--
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


ALTER FUNCTION auth.role() OWNER TO supabase_auth_admin;

--
-- Name: FUNCTION role(); Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON FUNCTION auth.role() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';


--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


ALTER FUNCTION auth.uid() OWNER TO supabase_auth_admin;

--
-- Name: FUNCTION uid(); Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON FUNCTION auth.uid() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';


--
-- Name: grant_pg_cron_access(); Type: FUNCTION; Schema: extensions; Owner: supabase_admin
--

CREATE FUNCTION extensions.grant_pg_cron_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_cron'
  )
  THEN
    grant usage on schema cron to postgres with grant option;

    alter default privileges in schema cron grant all on tables to postgres with grant option;
    alter default privileges in schema cron grant all on functions to postgres with grant option;
    alter default privileges in schema cron grant all on sequences to postgres with grant option;

    alter default privileges for user supabase_admin in schema cron grant all
        on sequences to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on tables to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on functions to postgres with grant option;

    grant all privileges on all tables in schema cron to postgres with grant option;
    revoke all on table cron.job from postgres;
    grant select on table cron.job to postgres with grant option;
  END IF;
END;
$$;


ALTER FUNCTION extensions.grant_pg_cron_access() OWNER TO supabase_admin;

--
-- Name: FUNCTION grant_pg_cron_access(); Type: COMMENT; Schema: extensions; Owner: supabase_admin
--

COMMENT ON FUNCTION extensions.grant_pg_cron_access() IS 'Grants access to pg_cron';


--
-- Name: grant_pg_graphql_access(); Type: FUNCTION; Schema: extensions; Owner: supabase_admin
--

CREATE FUNCTION extensions.grant_pg_graphql_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
    func_is_graphql_resolve bool;
BEGIN
    func_is_graphql_resolve = (
        SELECT n.proname = 'resolve'
        FROM pg_event_trigger_ddl_commands() AS ev
        LEFT JOIN pg_catalog.pg_proc AS n
        ON ev.objid = n.oid
    );

    IF func_is_graphql_resolve
    THEN
        -- Update public wrapper to pass all arguments through to the pg_graphql resolve func
        DROP FUNCTION IF EXISTS graphql_public.graphql;
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language sql
        as $$
            select graphql.resolve(
                query := query,
                variables := coalesce(variables, '{}'),
                "operationName" := "operationName",
                extensions := extensions
            );
        $$;

        -- This hook executes when `graphql.resolve` is created. That is not necessarily the last
        -- function in the extension so we need to grant permissions on existing entities AND
        -- update default permissions to any others that are created after `graphql.resolve`
        grant usage on schema graphql to postgres, anon, authenticated, service_role;
        grant select on all tables in schema graphql to postgres, anon, authenticated, service_role;
        grant execute on all functions in schema graphql to postgres, anon, authenticated, service_role;
        grant all on all sequences in schema graphql to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on tables to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on functions to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on sequences to postgres, anon, authenticated, service_role;

        -- Allow postgres role to allow granting usage on graphql and graphql_public schemas to custom roles
        grant usage on schema graphql_public to postgres with grant option;
        grant usage on schema graphql to postgres with grant option;
    END IF;

END;
$_$;


ALTER FUNCTION extensions.grant_pg_graphql_access() OWNER TO supabase_admin;

--
-- Name: FUNCTION grant_pg_graphql_access(); Type: COMMENT; Schema: extensions; Owner: supabase_admin
--

COMMENT ON FUNCTION extensions.grant_pg_graphql_access() IS 'Grants access to pg_graphql';


--
-- Name: grant_pg_net_access(); Type: FUNCTION; Schema: extensions; Owner: supabase_admin
--

CREATE FUNCTION extensions.grant_pg_net_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_net'
  )
  THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_roles
      WHERE rolname = 'supabase_functions_admin'
    )
    THEN
      CREATE USER supabase_functions_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
    END IF;

    GRANT USAGE ON SCHEMA net TO supabase_functions_admin, postgres, anon, authenticated, service_role;

    IF EXISTS (
      SELECT FROM pg_extension
      WHERE extname = 'pg_net'
      -- all versions in use on existing projects as of 2025-02-20
      -- version 0.12.0 onwards don't need these applied
      AND extversion IN ('0.2', '0.6', '0.7', '0.7.1', '0.8', '0.10.0', '0.11.0')
    ) THEN
      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;

      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;

      REVOKE ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
      REVOKE ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;

      GRANT EXECUTE ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
      GRANT EXECUTE ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
    END IF;
  END IF;
END;
$$;


ALTER FUNCTION extensions.grant_pg_net_access() OWNER TO supabase_admin;

--
-- Name: FUNCTION grant_pg_net_access(); Type: COMMENT; Schema: extensions; Owner: supabase_admin
--

COMMENT ON FUNCTION extensions.grant_pg_net_access() IS 'Grants access to pg_net';


--
-- Name: nanoid(integer, text); Type: FUNCTION; Schema: extensions; Owner: postgres
--

CREATE FUNCTION extensions.nanoid(size integer DEFAULT 10, alphabet text DEFAULT '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'::text) RETURNS text
    LANGUAGE plpgsql STABLE
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


ALTER FUNCTION extensions.nanoid(size integer, alphabet text) OWNER TO postgres;

--
-- Name: pgrst_ddl_watch(); Type: FUNCTION; Schema: extensions; Owner: supabase_admin
--

CREATE FUNCTION extensions.pgrst_ddl_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN SELECT * FROM pg_event_trigger_ddl_commands()
  LOOP
    IF cmd.command_tag IN (
      'CREATE SCHEMA', 'ALTER SCHEMA'
    , 'CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO', 'ALTER TABLE'
    , 'CREATE FOREIGN TABLE', 'ALTER FOREIGN TABLE'
    , 'CREATE VIEW', 'ALTER VIEW'
    , 'CREATE MATERIALIZED VIEW', 'ALTER MATERIALIZED VIEW'
    , 'CREATE FUNCTION', 'ALTER FUNCTION'
    , 'CREATE TRIGGER'
    , 'CREATE TYPE', 'ALTER TYPE'
    , 'CREATE RULE'
    , 'COMMENT'
    )
    -- don't notify in case of CREATE TEMP table or other objects created on pg_temp
    AND cmd.schema_name is distinct from 'pg_temp'
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


ALTER FUNCTION extensions.pgrst_ddl_watch() OWNER TO supabase_admin;

--
-- Name: pgrst_drop_watch(); Type: FUNCTION; Schema: extensions; Owner: supabase_admin
--

CREATE FUNCTION extensions.pgrst_drop_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
  LOOP
    IF obj.object_type IN (
      'schema'
    , 'table'
    , 'foreign table'
    , 'view'
    , 'materialized view'
    , 'function'
    , 'trigger'
    , 'type'
    , 'rule'
    )
    AND obj.is_temporary IS false -- no pg_temp objects
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


ALTER FUNCTION extensions.pgrst_drop_watch() OWNER TO supabase_admin;

--
-- Name: set_graphql_placeholder(); Type: FUNCTION; Schema: extensions; Owner: supabase_admin
--

CREATE FUNCTION extensions.set_graphql_placeholder() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
    DECLARE
    graphql_is_dropped bool;
    BEGIN
    graphql_is_dropped = (
        SELECT ev.schema_name = 'graphql_public'
        FROM pg_event_trigger_dropped_objects() AS ev
        WHERE ev.schema_name = 'graphql_public'
    );

    IF graphql_is_dropped
    THEN
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language plpgsql
        as $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;
    END IF;

    END;
$_$;


ALTER FUNCTION extensions.set_graphql_placeholder() OWNER TO supabase_admin;

--
-- Name: FUNCTION set_graphql_placeholder(); Type: COMMENT; Schema: extensions; Owner: supabase_admin
--

COMMENT ON FUNCTION extensions.set_graphql_placeholder() IS 'Reintroduces placeholder function for graphql_public.graphql';


--
-- Name: graphql(text, text, jsonb, jsonb); Type: FUNCTION; Schema: graphql_public; Owner: supabase_admin
--

CREATE FUNCTION graphql_public.graphql("operationName" text DEFAULT NULL::text, query text DEFAULT NULL::text, variables jsonb DEFAULT NULL::jsonb, extensions jsonb DEFAULT NULL::jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;


ALTER FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) OWNER TO supabase_admin;

--
-- Name: get_auth(text); Type: FUNCTION; Schema: pgbouncer; Owner: supabase_admin
--

CREATE FUNCTION pgbouncer.get_auth(p_usename text) RETURNS TABLE(username text, password text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
begin
    raise debug 'PgBouncer auth request: %', p_usename;

    return query
    select 
        rolname::text, 
        case when rolvaliduntil < now() 
            then null 
            else rolpassword::text 
        end 
    from pg_authid 
    where rolname=$1 and rolcanlogin;
end;
$_$;


ALTER FUNCTION pgbouncer.get_auth(p_usename text) OWNER TO supabase_admin;

--
-- Name: _achievement_current_value(uuid, jsonb, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._achievement_current_value(p_user_id uuid, p_criteria jsonb, p_eligible_from timestamp with time zone) RETURNS numeric
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_source      text    := p_criteria->>'source';
  v_agg         text    := p_criteria->>'agg';
  v_metric      text    := p_criteria->>'metric';
  v_window      text    := COALESCE(p_criteria->>'window', 'all_time');
  v_session_min numeric := (p_criteria->>'session_min')::numeric;
  v_row_min     numeric := COALESCE((p_criteria->>'row_min')::numeric, 1);
  v_start       timestamptz;
  v_result      numeric := 0;
BEGIN
  v_start := CASE v_window
    WHEN 'week'  THEN date_trunc('week',  now())
    WHEN 'month' THEN date_trunc('month', now())
    WHEN 'day'   THEN date_trunc('day',   now())
    ELSE p_eligible_from
  END;
  v_start := GREATEST(v_start, p_eligible_from);

  IF v_source = 'special' THEN
    RETURN CASE WHEN EXISTS(
      SELECT 1 FROM public.user_health_link l WHERE l.user_id = p_user_id
    ) THEN 1 ELSE 0 END;
  END IF;

  IF v_source = 'social' THEN
    IF v_agg = 'count' THEN
      SELECT COUNT(*) INTO v_result
      FROM public.social_event e
      WHERE e.user_id = p_user_id AND e.kind = v_metric
        AND e.created_at >= v_start AND e.created_at <= now();
    END IF;
    RETURN v_result;
  END IF;

  IF v_source = 'daily' THEN
    IF v_agg = 'sum' THEN
      SELECT COALESCE(SUM(CASE v_metric
        WHEN 'steps'                  THEN d.steps::numeric
        WHEN 'active_calories'        THEN d.active_calories::numeric
        WHEN 'distance_meters'        THEN d.distance_meters::numeric
        WHEN 'total_calories'         THEN d.total_calories::numeric
        WHEN 'total_activity_minutes' THEN d.total_activity_minutes::numeric
        WHEN 'sleep_minutes'          THEN d.sleep_minutes::numeric
        ELSE 0 END), 0) INTO v_result
      FROM public.daily_health_summary d
      WHERE d.user_id = p_user_id AND d.date >= v_start::date;
    ELSIF v_agg = 'count' THEN
      SELECT COUNT(*) INTO v_result
      FROM public.daily_health_summary d
      WHERE d.user_id = p_user_id AND d.date >= v_start::date
        AND (CASE v_metric
          WHEN 'activity_count' THEN d.activity_count::numeric
          WHEN 'steps'          THEN d.steps::numeric
          WHEN 'sleep_minutes'  THEN d.sleep_minutes::numeric
          WHEN 'active_calories'THEN d.active_calories::numeric
          ELSE 0 END) >= v_row_min;
    ELSIF v_agg = 'max' THEN
      SELECT COALESCE(MAX(CASE v_metric
        WHEN 'steps'           THEN d.steps::numeric
        WHEN 'active_calories' THEN d.active_calories::numeric
        WHEN 'distance_meters' THEN d.distance_meters::numeric
        ELSE 0 END), 0) INTO v_result
      FROM public.daily_health_summary d
      WHERE d.user_id = p_user_id AND d.date >= v_start::date;
    END IF;
    RETURN v_result;
  END IF;

  IF v_source = 'activity' THEN
    IF v_agg = 'sum' THEN
      SELECT COALESCE(SUM(public._activity_metric_value(m, v_metric)), 0) INTO v_result
      FROM public.activity_health_metrics m
      JOIN public.activity a ON a.id = m.activity_id
      WHERE m.user_id = p_user_id AND NOT m.dismissed
        AND a.start_time >= v_start AND a.start_time <= now();
    ELSIF v_agg = 'count' THEN
      SELECT COUNT(*) INTO v_result
      FROM public.activity_health_metrics m
      JOIN public.activity a ON a.id = m.activity_id
      WHERE m.user_id = p_user_id AND NOT m.dismissed
        AND a.start_time >= v_start AND a.start_time <= now();
    ELSIF v_agg = 'max' THEN
      SELECT COALESCE(MAX(public._activity_metric_value(m, v_metric)), 0) INTO v_result
      FROM public.activity_health_metrics m
      JOIN public.activity a ON a.id = m.activity_id
      WHERE m.user_id = p_user_id AND NOT m.dismissed
        AND a.start_time >= v_start AND a.start_time <= now();
    ELSIF v_agg = 'session_streak' THEN
      WITH s AS (
        SELECT a.start_time,
          CASE WHEN public._activity_metric_value(m, v_metric) >= v_session_min
               THEN 1 ELSE 0 END AS ok
        FROM public.activity_health_metrics m
        JOIN public.activity a ON a.id = m.activity_id
        WHERE m.user_id = p_user_id AND NOT m.dismissed
          AND a.start_time >= v_start AND a.start_time <= now()
      ),
      grp AS (
        SELECT ok,
          row_number() OVER (ORDER BY start_time)
          - row_number() OVER (PARTITION BY ok ORDER BY start_time) AS g
        FROM s
      )
      SELECT COALESCE(MAX(cnt), 0) INTO v_result
      FROM (SELECT COUNT(*) AS cnt FROM grp WHERE ok = 1 GROUP BY g) t;
    END IF;
    RETURN v_result;
  END IF;

  RETURN 0;
END;
$$;


ALTER FUNCTION public._achievement_current_value(p_user_id uuid, p_criteria jsonb, p_eligible_from timestamp with time zone) OWNER TO postgres;

--
-- Name: _achievement_level_floor(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._achievement_level_floor(p_level integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $$
  SELECT (25 * p_level * (p_level - 1))::bigint;
$$;


ALTER FUNCTION public._achievement_level_floor(p_level integer) OWNER TO postgres;

--
-- Name: _achievement_level_for_xp(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._achievement_level_for_xp(p_xp bigint) RETURNS integer
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $$
  SELECT LEAST(50, GREATEST(1,
    floor((25 + sqrt(625 + 100 * GREATEST(p_xp, 0)::numeric)) / 50)::int));
$$;


ALTER FUNCTION public._achievement_level_for_xp(p_xp bigint) OWNER TO postgres;

--
-- Name: _achievement_period_key(jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._achievement_period_key(p_criteria jsonb) RETURNS text
    LANGUAGE sql STABLE
    SET search_path TO ''
    AS $$
  SELECT CASE p_criteria->>'window'
    WHEN 'week'  THEN to_char(now(), 'IYYY"-W"IW')
    WHEN 'month' THEN to_char(now(), 'YYYY-MM')
    ELSE 'all'
  END;
$$;


ALTER FUNCTION public._achievement_period_key(p_criteria jsonb) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: activity_health_metrics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activity_health_metrics (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    activity_id uuid NOT NULL,
    steps integer,
    distance_meters real,
    active_calories real,
    avg_heart_rate integer,
    max_heart_rate integer,
    min_heart_rate integer,
    hrv_sdnn_ms real,
    hrv_rmssd_ms real,
    hr_zone_easy_seconds integer,
    hr_zone_moderate_seconds integer,
    hr_zone_hard_seconds integer,
    training_load real,
    effort_score real,
    weight_kg real,
    workout_type text,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    dismissed boolean DEFAULT false NOT NULL,
    CONSTRAINT heart_rate_validity CHECK ((((avg_heart_rate IS NULL) OR ((avg_heart_rate >= 30) AND (avg_heart_rate <= 250))) AND ((max_heart_rate IS NULL) OR ((max_heart_rate >= 30) AND (max_heart_rate <= 250))) AND ((min_heart_rate IS NULL) OR ((min_heart_rate >= 30) AND (min_heart_rate <= 250)))))
);


ALTER TABLE public.activity_health_metrics OWNER TO postgres;

--
-- Name: TABLE activity_health_metrics; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.activity_health_metrics IS 'Aggregated health metrics for user activities';


--
-- Name: COLUMN activity_health_metrics.dismissed; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.activity_health_metrics.dismissed IS 'Tombstone: true rows carry no metrics and mark a detected workout the user dismissed, so it is not re-prompted. Excluded from activity_health_data.';


--
-- Name: _activity_metric_value(public.activity_health_metrics, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._activity_metric_value(m public.activity_health_metrics, p_metric text) RETURNS numeric
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $$
  SELECT CASE p_metric
    WHEN 'session_load' THEN
      (COALESCE(m.hr_zone_easy_seconds,0)
       + 2 * COALESCE(m.hr_zone_moderate_seconds,0)
       + 3 * COALESCE(m.hr_zone_hard_seconds,0)) / 60.0
    WHEN 'active_calories'          THEN COALESCE(m.active_calories,0)::numeric
    WHEN 'distance_meters'          THEN COALESCE(m.distance_meters,0)::numeric
    WHEN 'steps'                    THEN COALESCE(m.steps,0)::numeric
    WHEN 'hr_zone_hard_seconds'     THEN COALESCE(m.hr_zone_hard_seconds,0)::numeric
    WHEN 'hr_zone_moderate_seconds' THEN COALESCE(m.hr_zone_moderate_seconds,0)::numeric
    WHEN 'hr_zone_easy_seconds'     THEN COALESCE(m.hr_zone_easy_seconds,0)::numeric
    WHEN 'effort_score'             THEN COALESCE(m.effort_score,0)::numeric
    WHEN 'training_load'            THEN COALESCE(m.training_load,0)::numeric
    ELSE 0 END;
$$;


ALTER FUNCTION public._activity_metric_value(m public.activity_health_metrics, p_metric text) OWNER TO postgres;

--
-- Name: _fn_social_event_on_post(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._fn_social_event_on_post() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
  INSERT INTO public.social_event (user_id, kind) VALUES (NEW.author_id, 'post_created');
  RETURN NEW;
END;
$$;


ALTER FUNCTION public._fn_social_event_on_post() OWNER TO postgres;

--
-- Name: _fn_social_event_on_reaction(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._fn_social_event_on_reaction() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_author uuid;
BEGIN
  SELECT author_id INTO v_author FROM public.wall_post WHERE id = NEW.post_id;

  IF v_author IS NOT NULL AND v_author IS DISTINCT FROM NEW.user_id THEN
    INSERT INTO public.social_event (user_id, kind) VALUES (v_author, 'reaction_received');
    INSERT INTO public.social_event (user_id, kind) VALUES (NEW.user_id, 'reaction_given');
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public._fn_social_event_on_reaction() OWNER TO postgres;

--
-- Name: _vitality_daily_load_series(uuid, date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._vitality_daily_load_series(p_user_id uuid, p_from date, p_to date) RETURNS TABLE(date date, session_load real)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT gs.d::date, COALESCE(vdl.session_load, 0)
  FROM generate_series(p_from, p_to, interval '1 day') AS gs(d)
  LEFT JOIN public.vitality_daily_load vdl
    ON vdl.user_id = p_user_id AND vdl.date = gs.d::date
  ORDER BY gs.d;
$$;


ALTER FUNCTION public._vitality_daily_load_series(p_user_id uuid, p_from date, p_to date) OWNER TO postgres;

--
-- Name: _vitality_ewma(uuid, date, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._vitality_ewma(p_user_id uuid, p_as_of date, p_window_days integer) RETURNS real
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  WITH RECURSIVE series AS (
    SELECT date, session_load
    FROM public._vitality_daily_load_series(
      p_user_id, p_as_of - (p_window_days * 3), p_as_of
    )
  ),
  ewma AS (
    SELECT date, session_load::real AS value
    FROM series WHERE date = (SELECT MIN(date) FROM series)
    UNION ALL
    SELECT s.date,
      (e.value + (s.session_load - e.value) / p_window_days)::real
    FROM series s
    JOIN ewma e ON s.date = e.date + 1
  )
  SELECT value FROM ewma WHERE date = p_as_of;
$$;


ALTER FUNCTION public._vitality_ewma(p_user_id uuid, p_as_of date, p_window_days integer) OWNER TO postgres;

--
-- Name: _vitality_scale(real, real[], real[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._vitality_scale(p_value real, p_breaks real[], p_scores real[]) RETURNS real
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO ''
    AS $$
DECLARE
  n integer := array_length(p_breaks, 1);
BEGIN
  IF p_value <= p_breaks[1] THEN RETURN p_scores[1]; END IF;
  IF p_value >= p_breaks[n] THEN RETURN p_scores[n]; END IF;
  FOR i IN 1..n - 1 LOOP
    IF p_value >= p_breaks[i] AND p_value <= p_breaks[i + 1] THEN
      RETURN p_scores[i] + (p_value - p_breaks[i])
        / (p_breaks[i + 1] - p_breaks[i]) * (p_scores[i + 1] - p_scores[i]);
    END IF;
  END LOOP;
  RETURN p_scores[n];
END;
$$;


ALTER FUNCTION public._vitality_scale(p_value real, p_breaks real[], p_scores real[]) OWNER TO postgres;

--
-- Name: accept_referee_booking(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.accept_referee_booking(p_booking_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_booking record;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'accept_referee_booking: authentication required';
    END IF;

    SELECT pb.professional_id, pb.status,
           pb.booking_time_start, pb.booking_time_end
    INTO v_booking
    FROM public.referee_booking pb
    WHERE pb.id = p_booking_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'accept_referee_booking: booking % not found', p_booking_id;
    END IF;
    IF NOT EXISTS (
        SELECT 1
        FROM public.professional p
        WHERE p.id = v_booking.professional_id
          AND p.linked_user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'accept_referee_booking: caller is not the linked professional';
    END IF;
    IF v_booking.status <> 'requested' OR v_booking.booking_time_start <= now() THEN
        RAISE EXCEPTION 'accept_referee_booking: request is no longer actionable';
    END IF;

    PERFORM pg_catalog.pg_advisory_xact_lock(
        pg_catalog.hashtextextended(v_booking.professional_id::text, 0)
    );

    IF EXISTS (
        SELECT 1
        FROM public.referee_booking pb2
        WHERE pb2.professional_id = v_booking.professional_id
          AND pb2.id <> p_booking_id
          AND pb2.status = 'confirmed'
          AND pb2.booking_time_start < v_booking.booking_time_end
          AND pb2.booking_time_end > v_booking.booking_time_start
    ) THEN
        RAISE EXCEPTION 'accept_referee_booking: overlaps another confirmed booking';
    END IF;

    UPDATE public.referee_booking
    SET status = 'confirmed'
    WHERE id = p_booking_id;
END;
$$;


ALTER FUNCTION public.accept_referee_booking(p_booking_id uuid) OWNER TO postgres;

--
-- Name: achievement_progress(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.achievement_progress(p_user_id uuid) RETURNS TABLE(achievement_id uuid, code text, name text, description text, difficulty smallint, consistency smallint, xp_reward bigint, repeatable boolean, current_value numeric, threshold numeric, progress numeric, state text, period_key text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_eligible_from timestamptz;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT GREATEST(u.created_at, now() - interval '90 days')
    INTO v_eligible_from FROM public."user" u WHERE u.id = p_user_id;

  RETURN QUERY
  SELECT
    a.id, a.code, a.name, a.description, a.difficulty, a.consistency, a.xp_reward, a.repeatable,
    cv.val,
    th.thr,
    LEAST(1.0, CASE WHEN th.thr > 0 THEN cv.val / th.thr ELSE 0 END),
    CASE
      WHEN ua.id IS NOT NULL AND a.repeatable THEN 'earned_period'
      WHEN ua.id IS NOT NULL                  THEN 'done'
      WHEN cv.val <= 0                         THEN 'not_started'
      ELSE 'in_progress'
    END,
    pk.pkey
  FROM public.achievement a
  CROSS JOIN LATERAL (SELECT public._achievement_current_value(p_user_id, a.criteria, v_eligible_from) AS val) cv
  CROSS JOIN LATERAL (SELECT COALESCE((a.criteria->>'threshold')::numeric, 1) AS thr) th
  CROSS JOIN LATERAL (SELECT public._achievement_period_key(a.criteria) AS pkey) pk
  LEFT JOIN public.user_achievement ua
    ON ua.user_id = p_user_id AND ua.achievement_id = a.id AND ua.period_key = pk.pkey;
END;
$$;


ALTER FUNCTION public.achievement_progress(p_user_id uuid) OWNER TO postgres;

--
-- Name: activity_confirmation_status(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.activity_confirmation_status(p_activity_id uuid) RETURNS TABLE(confirmed_count integer, maybe_count integer, threshold integer, my_attendance text, activity_confirmed boolean, deadline_locked boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_threshold int;
    v_going     int;
    v_maybe     int;
    v_mine      text;
    v_locked    boolean;
BEGIN
    SELECT a.confirmation_threshold, (a.at_risk_notified_at IS NOT NULL)
        INTO v_threshold, v_locked
        FROM public.activity a WHERE a.id = p_activity_id;

    SELECT COUNT(*) FILTER (WHERE attendance = 'going')::int,
           COUNT(*) FILTER (WHERE attendance = 'maybe')::int
        INTO v_going, v_maybe
        FROM public.activity_confirmation
        WHERE activity_id = p_activity_id;

    SELECT attendance::text INTO v_mine
        FROM public.activity_confirmation
        WHERE activity_id = p_activity_id AND user_id = auth.uid();

    RETURN QUERY SELECT
        COALESCE(v_going, 0),
        COALESCE(v_maybe, 0),
        v_threshold,
        v_mine,
        public.activity_is_confirmed(p_activity_id),
        COALESCE(v_locked, false);
END;
$$;


ALTER FUNCTION public.activity_confirmation_status(p_activity_id uuid) OWNER TO postgres;

--
-- Name: activity_health_data(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.activity_health_data(p_sport_id bigint) RETURNS TABLE(activity_id uuid, start_time timestamp with time zone, end_time timestamp with time zone, duration_minutes integer, location_label text, source text, steps integer, distance_meters real, active_calories real, avg_heart_rate integer, max_heart_rate integer, min_heart_rate integer, hrv_sdnn_ms real, hrv_rmssd_ms real, hr_zone_easy_seconds integer, hr_zone_moderate_seconds integer, hr_zone_hard_seconds integer, training_load real, effort_score real, workout_type text, recorded_at timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid();
BEGIN
  RETURN QUERY SELECT m.activity_id, a.start_time, a.end_time,
    CASE WHEN a.end_time IS NOT NULL
         THEN (extract(epoch FROM (a.end_time - a.start_time))/60)::int END,
    coalesce(loc.name, fa.venue_name),
    CASE WHEN a.course_id IS NOT NULL THEN 'professional'
      WHEN a.freeplay_host_id IS NOT NULL THEN 'freeplay'
      WHEN a.lobby_id IS NOT NULL THEN 'lobby' ELSE 'self' END,
    m.steps, m.distance_meters, m.active_calories, m.avg_heart_rate, m.max_heart_rate,
    m.min_heart_rate, m.hrv_sdnn_ms, m.hrv_rmssd_ms, m.hr_zone_easy_seconds,
    m.hr_zone_moderate_seconds, m.hr_zone_hard_seconds, m.training_load,
    m.effort_score, m.workout_type, m.recorded_at
  FROM public.activity_health_metrics m
  JOIN public.activity a ON a.id = m.activity_id
  LEFT JOIN public.location loc ON loc.id = a.location_id
  LEFT JOIN public.freeplay_activity fa ON fa.activity_id = a.id
  WHERE m.user_id = v_uid AND m.dismissed = false AND a.sport_id = p_sport_id
  ORDER BY a.start_time DESC;
END
$$;


ALTER FUNCTION public.activity_health_data(p_sport_id bigint) OWNER TO postgres;

--
-- Name: activity_is_confirmed(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.activity_is_confirmed(p_activity_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_threshold int;
    v_override  timestamptz;
    v_count     int;
BEGIN
    SELECT a.confirmation_threshold, a.threshold_override_at
        INTO v_threshold, v_override
        FROM public.activity a WHERE a.id = p_activity_id;
    IF NOT FOUND THEN RETURN false; END IF;
    IF v_override IS NOT NULL THEN RETURN true; END IF;
    IF v_threshold IS NULL THEN RETURN true; END IF;

    SELECT COUNT(*) INTO v_count
        FROM public.activity_confirmation
        WHERE activity_id = p_activity_id AND attendance = 'going';

    RETURN v_count >= v_threshold;
END;
$$;


ALTER FUNCTION public.activity_is_confirmed(p_activity_id uuid) OWNER TO postgres;

--
-- Name: add_payment_info(text, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_payment_info(p_bank_id text, p_bank_display_name text, p_value text, p_account_name text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    v_value_secret_id uuid := vault.create_secret(p_value);
    v_name_secret_id uuid;
    v_old_value_secret_id uuid;
    v_old_name_secret_id uuid;
    v_id uuid;
BEGIN
    IF p_account_name IS NOT NULL THEN
        v_name_secret_id := vault.create_secret(p_account_name);
    END IF;

    SELECT value_secret_id, account_name_secret_id
      INTO v_old_value_secret_id, v_old_name_secret_id
      FROM public.user_payment_info WHERE user_id = auth.uid();

    INSERT INTO public.user_payment_info
        (user_id, bank_id, bank_display_name, value_secret_id, account_name_secret_id)
    VALUES (auth.uid(), p_bank_id, p_bank_display_name, v_value_secret_id, v_name_secret_id)
    ON CONFLICT (user_id) DO UPDATE SET
        bank_id                = excluded.bank_id,
        bank_display_name      = excluded.bank_display_name,
        value_secret_id        = excluded.value_secret_id,
        account_name_secret_id = excluded.account_name_secret_id,
        created_at              = now()
    RETURNING id INTO v_id;

    IF v_old_value_secret_id IS NOT NULL THEN
        DELETE FROM vault.secrets WHERE id IN (v_old_value_secret_id, v_old_name_secret_id);
    END IF;

    RETURN v_id;
END;
$$;


ALTER FUNCTION public.add_payment_info(p_bank_id text, p_bank_display_name text, p_value text, p_account_name text) OWNER TO postgres;

--
-- Name: block_user(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.block_user(p_user_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_uid uuid := auth.uid();
begin
    if v_uid is null then raise exception 'not authenticated'; end if;
    if p_user_id = v_uid then raise exception 'cannot block yourself'; end if;

    insert into public.user_block (blocker_id, blocked_id)
        values (v_uid, p_user_id)
        on conflict do nothing;

    update public.friendship
        set status = 'cancelled', responded_at = now()
        where status in ('pending', 'accepted')
          and least(requester_id, addressee_id) = least(v_uid, p_user_id)
          and greatest(requester_id, addressee_id) = greatest(v_uid, p_user_id);
end;
$$;


ALTER FUNCTION public.block_user(p_user_id uuid) OWNER TO postgres;

--
-- Name: calculate_profile_compat(uuid, uuid, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_profile_compat(p_user_id uuid, p_target_id uuid, p_sport_id bigint) RETURNS jsonb
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
    raw_score   NUMERIC := 0;
    max_raw     NUMERIC := 10;
    base_score  NUMERIC := 2.5;
    top_score   NUMERIC := 5;
    final_score NUMERIC;
    factors     TEXT[] := ARRAY[]::TEXT[];

    is_user BOOLEAN;
    host_id UUID;
    user_details   JSONB;
    target_details JSONB;
    sport_id_text  TEXT;

    user_skill_level INTEGER;
    user_gender   TEXT;
    user_age      TEXT;

    shared_network_count        INTEGER := 0;
    active_shared_network_count INTEGER := 0;
    shared_industry_count       INTEGER := 0;

    total_lobby_members               INTEGER := 0;
    lobby_members_with_shared_network INTEGER := 0;
    lobby_members_with_same_skill     INTEGER := 0;
    lobby_members_same_age            INTEGER := 0;
    lobby_female_members              INTEGER := 0;
    has_active_shared_member          BOOLEAN := FALSE;
BEGIN
    sport_id_text := p_sport_id::TEXT;

    SELECT EXISTS(SELECT 1 FROM public."user" WHERE id = p_target_id) INTO is_user;

    SELECT details INTO user_details FROM public."user" WHERE id = p_user_id;

    IF user_details->'sport' ? sport_id_text AND user_details->'sport'->sport_id_text ? 'skill' THEN
        user_skill_level := (user_details->'sport'->sport_id_text->>'skill')::INTEGER;
    END IF;
    user_gender := user_details->>'gender';
    user_age    := user_details->>'ageGroup';

    IF is_user THEN
        SELECT details INTO target_details FROM public."user" WHERE id = p_target_id;

        SELECT COUNT(*) INTO shared_network_count
        FROM public.user_network un1
                 JOIN public.user_network un2 ON un1.network_id = un2.network_id
        WHERE un1.user_id = p_user_id AND un2.user_id = p_target_id;

        IF shared_network_count > 0 THEN
            raw_score := raw_score + 3;
            factors := array_append(factors, 'network');

            SELECT COUNT(*) INTO active_shared_network_count
            FROM public.user_network un1
                     JOIN public.user_network un2 ON un1.network_id = un2.network_id
            WHERE un1.user_id = p_user_id
              AND un2.user_id = p_target_id
              AND NOT un1.alumni
              AND NOT un2.alumni;

            IF active_shared_network_count > 0 THEN
                raw_score := raw_score + 1;
            END IF;
        ELSE
            SELECT COUNT(*) INTO shared_industry_count
            FROM public.user_industry ui1
                     JOIN public.user_industry ui2 ON ui1.industry_id = ui2.industry_id
            WHERE ui1.user_id = p_user_id AND ui2.user_id = p_target_id;

            IF shared_industry_count > 0 THEN
                raw_score := raw_score + 2;
                factors := array_append(factors, 'industry');
            END IF;
        END IF;

        IF user_skill_level IS NOT NULL AND
           target_details->'sport' ? sport_id_text AND
           target_details->'sport'->sport_id_text ? 'skill' AND
           user_skill_level = (target_details->'sport'->sport_id_text->>'skill')::INTEGER THEN
            raw_score := raw_score + 3;
            factors := array_append(factors, 'skill');
        END IF;

        IF user_age IS NOT NULL AND user_age = (target_details->>'ageGroup') THEN
            raw_score := raw_score + 1.5;
            factors := array_append(factors, 'age');
        END IF;

        IF user_gender = 'female' AND (target_details->>'gender') = 'female' THEN
            raw_score := raw_score + 2;
            factors := array_append(factors, 'gender');
        END IF;

    ELSE
        SELECT COUNT(*) INTO total_lobby_members
        FROM public.lobby_member
        WHERE lobby_id = p_target_id;

        SELECT captain_id INTO host_id
        FROM public.lobby
        WHERE id = p_target_id;

        IF total_lobby_members = 1 AND host_id IS NOT NULL THEN
            RETURN public.calculate_profile_compat(p_user_id, host_id, p_sport_id);
        END IF;

        IF total_lobby_members = 0 THEN
            RETURN jsonb_build_object('score', base_score, 'factors', factors);
        END IF;

        SELECT COUNT(DISTINCT lm.user_id) INTO lobby_members_with_shared_network
        FROM public.lobby_member lm
                 JOIN public.user_network un_member ON lm.user_id = un_member.user_id
                 JOIN public.user_network un_user ON un_member.network_id = un_user.network_id
        WHERE lm.lobby_id = p_target_id
          AND un_user.user_id = p_user_id;

        IF lobby_members_with_shared_network >= 3 THEN
            raw_score := raw_score + 4;
            factors := array_append(factors, 'network');
        ELSIF lobby_members_with_shared_network >= 1 THEN
            raw_score := raw_score + 2;
            factors := array_append(factors, 'network');

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
                raw_score := raw_score + 1;
            END IF;
        END IF;

        IF user_skill_level IS NOT NULL THEN
            SELECT COUNT(DISTINCT lm.user_id) INTO lobby_members_with_same_skill
            FROM public.lobby_member lm
                     JOIN public."user" u ON lm.user_id = u.id
            WHERE lm.lobby_id = p_target_id
              AND u.details->'sport' ? sport_id_text
              AND u.details->'sport'->sport_id_text ? 'skill'
              AND (u.details->'sport'->sport_id_text->>'skill')::INTEGER = user_skill_level;

            IF lobby_members_with_same_skill * 2 >= total_lobby_members THEN
                raw_score := raw_score + 3;
                factors := array_append(factors, 'skill');
            END IF;
        END IF;

        IF user_age IS NOT NULL THEN
            SELECT COUNT(DISTINCT lm.user_id) INTO lobby_members_same_age
            FROM public.lobby_member lm
                     JOIN public."user" u ON lm.user_id = u.id
            WHERE lm.lobby_id = p_target_id
              AND (u.details->>'ageGroup') = user_age;

            IF lobby_members_same_age * 2 >= total_lobby_members THEN
                raw_score := raw_score + 1.5;
                factors := array_append(factors, 'age');
            END IF;
        END IF;

        IF user_gender = 'female' THEN
            SELECT COUNT(DISTINCT lm.user_id) INTO lobby_female_members
            FROM public.lobby_member lm
                     JOIN public."user" u ON lm.user_id = u.id
            WHERE lm.lobby_id = p_target_id
              AND (u.details->>'gender') = 'female';

            IF lobby_female_members >= 1 THEN
                raw_score := raw_score + 2;
                factors := array_append(factors, 'gender');
            END IF;
        END IF;
    END IF;

    final_score := base_score + (LEAST(raw_score, max_raw) / max_raw) * (top_score - base_score);
    final_score := GREATEST(base_score, LEAST(top_score, final_score));

    RETURN jsonb_build_object('score', ROUND(final_score, 1), 'factors', factors);
END;
$$;


ALTER FUNCTION public.calculate_profile_compat(p_user_id uuid, p_target_id uuid, p_sport_id bigint) OWNER TO postgres;

--
-- Name: calculate_profile_compat_score(uuid, uuid, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_profile_compat_score(p_user_id uuid, p_target_id uuid, p_sport_id bigint) RETURNS numeric
    LANGUAGE sql STABLE
    SET search_path TO ''
    AS $$
    SELECT (public.calculate_profile_compat(p_user_id, p_target_id, p_sport_id)->>'score')::numeric;
$$;


ALTER FUNCTION public.calculate_profile_compat_score(p_user_id uuid, p_target_id uuid, p_sport_id bigint) OWNER TO postgres;

--
-- Name: calculate_timeslot_compat_score(jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_timeslot_compat_score(source jsonb, target jsonb) RETURNS integer
    LANGUAGE plpgsql
    SET search_path TO ''
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


ALTER FUNCTION public.calculate_timeslot_compat_score(source jsonb, target jsonb) OWNER TO postgres;

--
-- Name: can_write_conversation(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.can_write_conversation(p_conversation_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT coalesce(public.fn_can_write_conversation(p_conversation_id, auth.uid()), false);
$$;


ALTER FUNCTION public.can_write_conversation(p_conversation_id uuid) OWNER TO postgres;

--
-- Name: cancel_challenge(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cancel_challenge(p_challenge_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_uid  uuid := auth.uid();
    v_init uuid;
begin
    if v_uid is null then raise exception 'not authenticated'; end if;
    select initiator_lobby_id into v_init
        from public.lobby_challenge
        where id = p_challenge_id and status = 'requested';
    if v_init is null then raise exception 'no open challenge to cancel'; end if;
    if not public.lobby_can_manage(v_init, v_uid) then
        raise exception 'not a manager of the initiating lobby';
    end if;
    update public.lobby_challenge
        set status = 'cancelled', updated_at = now() where id = p_challenge_id;
end;
$$;


ALTER FUNCTION public.cancel_challenge(p_challenge_id uuid) OWNER TO postgres;

--
-- Name: cancel_course_activity(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cancel_course_activity(p_activity_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_course uuid; v_start timestamptz;
BEGIN
  SELECT a.course_id, a.start_time INTO v_course, v_start FROM public.activity a
  WHERE a.id = p_activity_id AND a.course_id IS NOT NULL FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'course session not found'; END IF;
  IF NOT public.fn_is_course_coach(v_course, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;

  DELETE FROM public.activity WHERE id = p_activity_id;

  PERFORM public.fn_course_system_message(v_course, 'activity_cancelled',
    jsonb_build_object('start_time', v_start));
  PERFORM public.fn_enqueue_notification('course_activity_changed',
    (SELECT array_agg(m.user_id) FROM public.course_member m
     WHERE m.course_id = v_course AND m.status = 'enrolled'),
    'Buổi tập đã huỷ', 'Huấn luyện viên đã huỷ một buổi tập.',
    jsonb_build_object('course_id', v_course));
END
$$;


ALTER FUNCTION public.cancel_course_activity(p_activity_id uuid) OWNER TO postgres;

--
-- Name: cancel_freeplay_activity(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cancel_freeplay_activity(p_activity_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid:=auth.uid(); v_user_ids uuid[]; v_request record;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.activity a JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
    WHERE a.id=p_activity_id AND h.user_id=v_uid) THEN RAISE EXCEPTION 'activity not found or not owned'; END IF;
  UPDATE public.freeplay_activity SET cancelled_at=coalesce(cancelled_at,now()),intake_closed_at=coalesce(intake_closed_at,now()),updated_at=now()
  WHERE activity_id=p_activity_id;
  UPDATE public.freeplay_request SET status='host_cancelled',resolved_at=now(),updated_at=now()
  WHERE activity_id=p_activity_id AND status IN ('pending','accepted');
  DELETE FROM public.activity_confirmation WHERE activity_id=p_activity_id;

  FOR v_request IN SELECT id FROM public.freeplay_request WHERE activity_id=p_activity_id
  LOOP
    INSERT INTO public.message(conversation_id,kind,body)
    VALUES(public.fn_ensure_freeplay_conversation(v_request.id),'system','activity_cancelled');
  END LOOP;

  SELECT array_agg(DISTINCT user_id) INTO v_user_ids FROM public.freeplay_request WHERE activity_id=p_activity_id;
  IF cardinality(v_user_ids)>0 THEN
    PERFORM public.fn_enqueue_notification('freeplay_activity_cancelled',v_user_ids,'Buổi Xé vé đã huỷ',
      'Host đã huỷ buổi chơi.',jsonb_build_object('activity_id',p_activity_id));
  END IF;
END
$$;


ALTER FUNCTION public.cancel_freeplay_activity(p_activity_id uuid) OWNER TO postgres;

--
-- Name: cancel_freeplay_request(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cancel_freeplay_request(p_request_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid:=auth.uid(); v_row record; v_conversation uuid;
BEGIN
  SELECT r.*,a.end_time,h.user_id host_user_id INTO v_row FROM public.freeplay_request r
  JOIN public.activity a ON a.id=r.activity_id JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE r.id=p_request_id AND r.user_id=v_uid FOR UPDATE OF r;
  IF NOT FOUND OR v_row.status NOT IN ('pending','accepted') OR v_row.end_time<=now() THEN
    RAISE EXCEPTION 'active request not found';
  END IF;
  UPDATE public.freeplay_request SET status='cancelled',resolved_at=now(),updated_at=now() WHERE id=p_request_id;
  DELETE FROM public.activity_confirmation WHERE activity_id=v_row.activity_id AND user_id=v_uid;
  v_conversation := public.fn_ensure_freeplay_conversation(p_request_id);
  INSERT INTO public.message(conversation_id,kind,body)
  VALUES(v_conversation,'system','request_cancelled');
  PERFORM public.fn_enqueue_notification('freeplay_request_cancelled',ARRAY[v_row.host_user_id],
    'Người chơi đã huỷ','Một người chơi đã huỷ yêu cầu Xé vé.',jsonb_build_object('activity_id',v_row.activity_id,'request_id',p_request_id));
END
$$;


ALTER FUNCTION public.cancel_freeplay_request(p_request_id uuid) OWNER TO postgres;

--
-- Name: cancel_referee_booking(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cancel_referee_booking(p_booking_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_booking record;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'cancel_referee_booking: authentication required';
    END IF;

    SELECT pb.client_user_id, pb.status, pb.booking_time_start
    INTO v_booking
    FROM public.referee_booking pb
    WHERE pb.id = p_booking_id
    FOR UPDATE;

    IF NOT FOUND OR v_booking.client_user_id <> auth.uid() THEN
        RAISE EXCEPTION 'cancel_referee_booking: booking not found';
    END IF;
    IF v_booking.status NOT IN ('requested', 'confirmed')
       OR (v_booking.status = 'confirmed'
           AND v_booking.booking_time_start <= now()) THEN
        RAISE EXCEPTION 'cancel_referee_booking: invalid status transition';
    END IF;

    UPDATE public.referee_booking
    SET status = 'cancelled_by_client'
    WHERE id = p_booking_id;
END;
$$;


ALTER FUNCTION public.cancel_referee_booking(p_booking_id uuid) OWNER TO postgres;

--
-- Name: complete_referee_booking(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.complete_referee_booking(p_booking_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_booking record;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'complete_referee_booking: authentication required';
    END IF;

    SELECT pb.client_user_id, pb.professional_id, pb.status, pb.booking_time_end,
           p.linked_user_id
    INTO v_booking
    FROM public.referee_booking pb
    JOIN public.professional p ON p.id = pb.professional_id
    WHERE pb.id = p_booking_id
    FOR UPDATE OF pb;

    IF NOT FOUND
       OR (v_booking.client_user_id <> auth.uid()
           AND v_booking.linked_user_id <> auth.uid()) THEN
        RAISE EXCEPTION 'complete_referee_booking: booking not found';
    END IF;
    IF v_booking.status <> 'confirmed' OR v_booking.booking_time_end > now() THEN
        RAISE EXCEPTION 'complete_referee_booking: invalid status transition';
    END IF;

    UPDATE public.referee_booking
    SET status = 'completed'
    WHERE id = p_booking_id;
END;
$$;


ALTER FUNCTION public.complete_referee_booking(p_booking_id uuid) OWNER TO postgres;

--
-- Name: confirm_challenge_activity(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.confirm_challenge_activity(p_activity_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_uid       uuid := auth.uid();
    v_lobby     uuid;
    v_challenge uuid;
    v_threshold integer;
    v_going     integer;
    v_pending   integer;
    v_init      uuid;
    v_target    uuid;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;

    SELECT lobby_id, challenge_id, confirmation_threshold
      INTO v_lobby, v_challenge, v_threshold
      FROM public.activity WHERE id = p_activity_id;

    IF v_challenge IS NULL THEN RAISE EXCEPTION 'not a challenge activity'; END IF;
    IF NOT public.lobby_can_manage(v_lobby, v_uid) THEN
        RAISE EXCEPTION 'not a manager of this lobby';
    END IF;

    SELECT count(*) INTO v_going
      FROM public.activity_confirmation
     WHERE activity_id = p_activity_id AND attendance = 'going';

    IF v_threshold IS NOT NULL AND v_going < v_threshold THEN
        RAISE EXCEPTION 'not enough confirmations yet (% of %)', v_going, v_threshold;
    END IF;

    UPDATE public.activity
       SET manager_confirmed_at = now()
     WHERE id = p_activity_id AND manager_confirmed_at IS NULL;

    SELECT count(*) INTO v_pending
      FROM public.activity
     WHERE challenge_id = v_challenge AND manager_confirmed_at IS NULL;

    IF v_pending = 0 THEN
        UPDATE public.lobby_challenge
           SET status = 'scheduled', updated_at = now()
         WHERE id = v_challenge AND status = 'accepted'
        RETURNING initiator_lobby_id, target_lobby_id INTO v_init, v_target;

        IF v_init IS NOT NULL THEN
            PERFORM public.fn_enqueue_notification(
                'challenge_scheduled',
                ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = v_init),
                'Trận đấu đã được chốt',
                'Cả hai đội đã xác nhận — trận thách đấu chính thức được lên lịch',
                jsonb_build_object('lobby_id', v_init, 'challenge_id', v_challenge));
            PERFORM public.fn_enqueue_notification(
                'challenge_scheduled',
                ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = v_target),
                'Trận đấu đã được chốt',
                'Cả hai đội đã xác nhận — trận thách đấu chính thức được lên lịch',
                jsonb_build_object('lobby_id', v_target, 'challenge_id', v_challenge));

            -- Mirrors the accept-time feed item (respond_challenge) — this is
            -- the next entry in the same scheduling lifecycle, not a match
            -- outcome, so it belongs in the lobby feed the way schedule/
            -- reschedule/cancel already do.
            INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
            SELECT l.id, l.captain_id, 'update',
                   jsonb_build_object(
                       'title', 'Trận đấu đã được chốt',
                       'kind',  'match_confirmed',
                       'tone',  'green',
                       'fields', jsonb_build_array(
                           jsonb_build_array('Trạng thái', 'Cả hai đội đã xác nhận')))
              FROM public.lobby l
             WHERE l.id IN (v_init, v_target);
        END IF;
    END IF;
END;
$$;


ALTER FUNCTION public.confirm_challenge_activity(p_activity_id uuid) OWNER TO postgres;

--
-- Name: conversation_data(uuid, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.conversation_data(p_conversation_id uuid, p_since timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS TABLE(id uuid, sender_id uuid, sender_username text, sender_avatar text, kind text, body text, payload jsonb, created_at timestamp with time zone, can_write boolean, payment_info jsonb, poll_votes jsonb, my_vote smallint)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_joined timestamptz; v_left timestamptz;
BEGIN
  SELECT m.joined_at, m.left_at INTO v_joined, v_left
  FROM public.conversation_member m
  WHERE m.conversation_id = p_conversation_id AND m.user_id = v_uid;
  IF NOT FOUND THEN RAISE EXCEPTION 'conversation not found'; END IF;

  RETURN QUERY
  SELECT m.id, m.sender_id, u.username::text, u.details->>'generatedAvatar',
         m.kind::text, m.body, m.payload, m.created_at,
         coalesce(public.fn_can_write_conversation(p_conversation_id, v_uid), false),
         CASE WHEN m.kind = 'payment_info' THEN jsonb_build_object(
           'id', i.id, 'bank_id', i.bank_id, 'bank_display_name', i.bank_display_name,
           'value', vv.decrypted_secret, 'account_name', vn.decrypted_secret,
           'created_at', i.created_at) END,
         CASE WHEN m.kind = 'poll' THEN
           (SELECT coalesce(jsonb_object_agg(t.option_index, t.c), '{}'::jsonb)
            FROM (SELECT v.option_index, count(*) c FROM public.message_poll_vote v
                  WHERE v.message_id = m.id GROUP BY v.option_index) t) END,
         CASE WHEN m.kind = 'poll' THEN
           (SELECT v.option_index FROM public.message_poll_vote v
            WHERE v.message_id = m.id AND v.user_id = v_uid) END
  FROM public.message m
  LEFT JOIN public."user" u ON u.id = m.sender_id
  LEFT JOIN public.user_payment_info i ON i.id = m.payment_info_id
  LEFT JOIN vault.decrypted_secrets vv ON vv.id = i.value_secret_id
  LEFT JOIN vault.decrypted_secrets vn ON vn.id = i.account_name_secret_id
  WHERE m.conversation_id = p_conversation_id
    AND m.created_at >= v_joined
    AND (v_left IS NULL OR m.created_at <= v_left)
    AND (p_since IS NULL OR m.created_at > p_since)
  ORDER BY m.created_at;
END
$$;


ALTER FUNCTION public.conversation_data(p_conversation_id uuid, p_since timestamp with time zone) OWNER TO postgres;

--
-- Name: course_activity_conflicts(uuid, timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.course_activity_conflicts(p_professional_id uuid, p_start timestamp with time zone, p_end timestamp with time zone) RETURNS TABLE(start_time timestamp with time zone, end_time timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT a.start_time, coalesce(a.end_time, a.start_time)
  FROM public.activity a
  JOIN public.course c ON c.id = a.course_id
  WHERE c.professional_id = p_professional_id
    AND a.proposal_status = 'approved'
    AND a.start_time < p_end
    AND coalesce(a.end_time, a.start_time) > p_start;
$$;


ALTER FUNCTION public.course_activity_conflicts(p_professional_id uuid, p_start timestamp with time zone, p_end timestamp with time zone) OWNER TO postgres;

--
-- Name: course_detail_data(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.course_detail_data(p_course_id uuid) RETURNS TABLE(course_id uuid, conversation_id uuid, name text, description text, status text, sport_id bigint, professional_id uuid, coach_name text, coach_user_id uuid, is_coach boolean, my_member_status text, target_session_count integer, held_session_count integer, members jsonb, sessions jsonb, reports jsonb, my_review_rating smallint)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_is_coach boolean;
BEGIN
  v_is_coach := public.fn_is_course_coach(p_course_id, v_uid);
  IF NOT v_is_coach AND NOT public.fn_is_course_member(p_course_id, v_uid) THEN
    RAISE EXCEPTION 'course not found';
  END IF;

  RETURN QUERY
  SELECT c.id, conv.id, c.name, c.description, c.status::text, c.sport_id,
         c.professional_id, p.display_name, p.linked_user_id, v_is_coach,
         (SELECT m.status::text FROM public.course_member m
          WHERE m.course_id = c.id AND m.user_id = v_uid AND m.left_at IS NULL),
         c.target_session_count, public.fn_course_held_sessions(c.id),
         coalesce((
           SELECT jsonb_agg(jsonb_build_object(
             'user_id', m.user_id, 'username', u.username,
             'generated_avatar', u.details->>'generatedAvatar',
             'status', m.status::text, 'joined_at', m.joined_at)
             ORDER BY u.username)
           FROM public.course_member m JOIN public."user" u ON u.id = m.user_id
           WHERE m.course_id = c.id AND m.left_at IS NULL), '[]'::jsonb),
         coalesce((
           SELECT jsonb_agg(jsonb_build_object(
             'activity_id', a.id, 'start_time', a.start_time, 'end_time', a.end_time,
             'location_id', a.location_id,
             'venue_name', loc.name,
             'street_address', coalesce(
               nullif(btrim(loc.full_address), ''),
               nullif(concat_ws(', ', nullif(btrim(loc.street_number), ''),
                 nullif(btrim(loc.street_name), ''), nullif(btrim(loc.district), ''),
                 nullif(btrim(loc.city), '')), '')
             ),
             'location_street_number', loc.street_number,
             'location_street_name', loc.street_name,
             'location_district', loc.district,
             'location_city', loc.city,
             'location_lat', loc.lat, 'location_lon', loc.lon,
             'note', a.note, 'proposal_status', a.proposal_status::text,
             'proposed_by', a.proposed_by,
             'my_attendance', (SELECT ac.attendance::text FROM public.activity_confirmation ac
                               WHERE ac.activity_id = a.id AND ac.user_id = v_uid),
             'going_count', (SELECT count(*) FROM public.activity_confirmation ac
                             WHERE ac.activity_id = a.id AND ac.attendance = 'going'))
             ORDER BY a.start_time)
           FROM public.activity a
           LEFT JOIN public.location loc ON loc.id = a.location_id
           WHERE a.course_id = c.id
             AND a.proposal_status IN ('approved','pending')), '[]'::jsonb),
         coalesce((
           SELECT jsonb_agg(jsonb_build_object(
             'activity_id', r.activity_id, 'student_id', r.student_id,
             'body', r.body, 'created_at', r.created_at)
             ORDER BY r.created_at DESC)
           FROM public.course_session_report r
           WHERE r.course_id = c.id
             AND (v_is_coach OR r.student_id = v_uid)), '[]'::jsonb),
         (SELECT rv.rating FROM public.course_review rv
          WHERE rv.course_id = c.id AND rv.student_id = v_uid)
  FROM public.course c
  JOIN public.professional p ON p.id = c.professional_id
  LEFT JOIN public.conversation conv ON conv.course_id = c.id
  WHERE c.id = p_course_id;
END
$$;


ALTER FUNCTION public.course_detail_data(p_course_id uuid) OWNER TO postgres;

--
-- Name: create_ancillary_payment_request(uuid, numeric, text, uuid[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_ancillary_payment_request(p_activity_id uuid, p_total_amount numeric, p_note text, p_tagged_users uuid[]) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_uid uuid := auth.uid();
    v_lobby_id uuid;
    v_end_time timestamptz;
    v_start_time timestamptz;
    v_tagged uuid[];
    v_payee_count int;
    v_per_person numeric(10, 2);
    v_feed_item_id uuid;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not authenticated';
    END IF;

    IF p_total_amount IS NULL OR p_total_amount <= 0 THEN
        RAISE EXCEPTION 'amount must be positive';
    END IF;

    v_tagged := ARRAY(SELECT DISTINCT u FROM unnest(p_tagged_users) AS u WHERE u <> v_uid);
    v_payee_count := COALESCE(array_length(v_tagged, 1), 0);
    IF v_payee_count = 0 THEN
        RAISE EXCEPTION 'must tag at least one lobby mate';
    END IF;

    SELECT a.lobby_id, a.end_time, a.start_time
      INTO v_lobby_id, v_end_time, v_start_time
      FROM public.activity a
      JOIN public.activity_confirmation ac
        ON ac.activity_id = a.id AND ac.user_id = v_uid AND ac.attendance = 'going'
     WHERE a.id = p_activity_id;

    IF v_lobby_id IS NULL THEN
        RAISE EXCEPTION 'must be a confirmed attendee of this session';
    END IF;

    IF COALESCE(v_end_time, v_start_time) > now() THEN
        RAISE EXCEPTION 'session has not ended yet';
    END IF;

    v_per_person := CEIL(p_total_amount / v_payee_count / 1000) * 1000;

    INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, activity_id, payload)
    VALUES (
        v_lobby_id, v_uid, 'payment_request', p_activity_id,
        jsonb_build_object(
            'type',               'ancillary',
            'source_activity_id', p_activity_id,
            'recipient_id',       v_uid,
            'total_amount',       p_total_amount,
            'per_person_amount',  v_per_person,
            'note',               p_note
        )
    )
    RETURNING id INTO v_feed_item_id;

    INSERT INTO public.lobby_payment_request_payee (feed_item_id, user_id, amount_owed)
    SELECT v_feed_item_id, u, v_per_person FROM unnest(v_tagged) AS u;

    PERFORM public.fn_enqueue_notification(
        'payment_requested',
        v_tagged,
        'Yêu cầu thanh toán',
        COALESCE(p_note, 'Bạn được yêu cầu thanh toán ' || v_per_person::text || 'đ'),
        jsonb_build_object(
            'lobby_id', v_lobby_id,
            'feed_item_id', v_feed_item_id,
            'activity_id', p_activity_id
        ));

    RETURN v_feed_item_id;
END;
$$;


ALTER FUNCTION public.create_ancillary_payment_request(p_activity_id uuid, p_total_amount numeric, p_note text, p_tagged_users uuid[]) OWNER TO postgres;

--
-- Name: create_freeplay_activity(bigint, timestamp with time zone, timestamp with time zone, integer, numeric, numeric, text[], text, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_freeplay_activity(p_sport_id bigint, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text DEFAULT ''::text, p_location_id uuid DEFAULT NULL::uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_host uuid; v_activity uuid;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;
  SELECT id INTO v_host FROM public.freeplay_host WHERE user_id=v_uid AND status='active';
  IF v_host IS NULL THEN RAISE EXCEPTION 'active Host profile required'; END IF;
  IF p_sport_id NOT BETWEEN 1 AND 5 OR p_end_time <= p_start_time OR p_end_time <= now() THEN
    RAISE EXCEPTION 'invalid activity terms';
  END IF;
  IF p_location_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.location WHERE id = p_location_id) THEN
    RAISE EXCEPTION 'location not found';
  END IF;
  INSERT INTO public.activity(user_id,sport_id,start_time,end_time,location_id,freeplay_host_id)
  VALUES(v_uid,p_sport_id,p_start_time,p_end_time,p_location_id,v_host) RETURNING id INTO v_activity;
  INSERT INTO public.freeplay_activity(activity_id,description,capacity,male_price,female_price,recommended_skills)
  VALUES(v_activity,coalesce(p_description,''),p_capacity,p_male_price,p_female_price,p_recommended_skills);
  RETURN v_activity;
END
$$;


ALTER FUNCTION public.create_freeplay_activity(p_sport_id bigint, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid) OWNER TO postgres;

--
-- Name: create_lobby_with_location(text, integer, text, jsonb, jsonb, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text DEFAULT 'discoverable'::text, p_playtime jsonb DEFAULT NULL::jsonb, p_details jsonb DEFAULT NULL::jsonb, p_home_ground_id uuid DEFAULT NULL::uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'extensions'
    AS $$
DECLARE
    v_user_id  uuid;
    v_lobby_id uuid;
    v_result   jsonb;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    INSERT INTO public.lobby (name, sport_id, visibility, playtime, details, home_ground, captain_id)
    VALUES (
        p_name,
        p_sport_id,
        p_visibility::public.lobby_visibility,
        p_playtime,
        p_details,
        p_home_ground_id,
        v_user_id
    )
    RETURNING id INTO v_lobby_id;

    -- Captain → lobby_member is handled by the lobby_add_captain_as_member
    -- AFTER INSERT trigger.

    SELECT row_to_json(l)::jsonb
        INTO v_result
        FROM public.lobby l
        WHERE l.id = v_lobby_id;

    RETURN v_result;
END;
$$;


ALTER FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid) OWNER TO postgres;

--
-- Name: create_location(text, text, text, text, text, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_location(p_name text, p_street_number text DEFAULT NULL::text, p_street_name text DEFAULT NULL::text, p_district text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_city_cluster bigint DEFAULT NULL::bigint) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'extensions'
    AS $$
DECLARE
    v_user_id uuid;
    v_loc_id  uuid;
    v_result  jsonb;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'create_location: authentication required';
    END IF;
    IF NULLIF(TRIM(COALESCE(p_name, '')), '') IS NULL THEN
        RAISE EXCEPTION 'create_location: name is required';
    END IF;

    INSERT INTO public.location (
        name, street_number, street_name, district, city, city_cluster,
        source, submitted_by, is_verified
    )
    VALUES (
        TRIM(p_name),
        NULLIF(p_street_number, ''),
        NULLIF(p_street_name, ''),
        NULLIF(p_district, ''),
        NULLIF(p_city, ''),
        p_city_cluster,
        'user_submitted',
        v_user_id,
        false
    )
    RETURNING id INTO v_loc_id;

    SELECT row_to_json(l)::jsonb INTO v_result
        FROM public.location l
        WHERE l.id = v_loc_id;

    RETURN v_result;
END;
$$;


ALTER FUNCTION public.create_location(p_name text, p_street_number text, p_street_name text, p_district text, p_city text, p_city_cluster bigint) OWNER TO postgres;

--
-- Name: create_message_poll(uuid, text, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_message_poll(p_conversation_id uuid, p_question text, p_options text[]) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_id uuid;
BEGIN
  IF NOT coalesce(public.fn_can_write_conversation(p_conversation_id, v_uid), false) THEN
    RAISE EXCEPTION 'chat is read-only';
  END IF;
  IF nullif(btrim(p_question),'') IS NULL OR char_length(btrim(p_question)) > 200
     OR cardinality(p_options) NOT BETWEEN 2 AND 6 THEN
    RAISE EXCEPTION 'invalid poll';
  END IF;

  INSERT INTO public.message(conversation_id, sender_id, kind, payload)
  VALUES (p_conversation_id, v_uid, 'poll',
    jsonb_build_object('question', btrim(p_question), 'options', to_jsonb(p_options)))
  RETURNING id INTO v_id;
  RETURN v_id;
END
$$;


ALTER FUNCTION public.create_message_poll(p_conversation_id uuid, p_question text, p_options text[]) OWNER TO postgres;

--
-- Name: create_wall_post(uuid, jsonb, text, smallint, uuid[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_wall_post(p_activity_id uuid, p_media jsonb, p_caption text DEFAULT NULL::text, p_ttl_days smallint DEFAULT 7, p_tagged_users uuid[] DEFAULT '{}'::uuid[]) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_id uuid; v_sport bigint; v_lobby uuid;
  v_label text; v_start timestamptz; v_venue text; v_tag uuid;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
  IF p_activity_id IS NULL THEN RAISE EXCEPTION 'an activity is required'; END IF;
  IF NOT public.fn_valid_wall_post_media(p_media) THEN
    RAISE EXCEPTION 'a post needs 1-4 media items, each an image or a video under 1 minute';
  END IF;
  IF array_length(p_tagged_users,1) > 5 THEN
    RAISE EXCEPTION 'a post can tag at most 5 people';
  END IF;

  SELECT a.sport_id, a.lobby_id,
         coalesce(l.name, h.display_name, co.name, pr.display_name, 'Xé vé'),
         a.start_time, coalesce(loc.name, fa.venue_name)
  INTO v_sport, v_lobby, v_label, v_start, v_venue
  FROM public.activity a
  LEFT JOIN public.lobby l ON l.id = a.lobby_id
  LEFT JOIN public.freeplay_activity fa ON fa.activity_id = a.id
  LEFT JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
  LEFT JOIN public.course co ON co.id = a.course_id
  LEFT JOIN public.professional pr ON pr.id = co.professional_id
  LEFT JOIN public.location loc ON loc.id = a.location_id
  WHERE a.id = p_activity_id
    AND a.start_time < now() AND a.start_time > now() - interval '7 days'
    AND (a.course_id IS NULL OR a.proposal_status = 'approved')
    AND EXISTS(SELECT 1 FROM public.activity_confirmation c
               WHERE c.activity_id = a.id AND c.user_id = v_uid AND c.attendance = 'going');
  IF v_start IS NULL THEN
    RAISE EXCEPTION 'activity is not postable (must be within 7 days and RSVP''d going)';
  END IF;

  INSERT INTO public.wall_post(author_id, activity_id, sport_id, lobby_id,
    source_label, source_start_time, source_venue_name, caption, media, ttl_days, expires_at)
  VALUES(v_uid, p_activity_id, coalesce(v_sport,0), v_lobby, v_label, v_start, v_venue,
    nullif(btrim(p_caption),''), p_media, p_ttl_days, now() + (p_ttl_days||' days')::interval)
  RETURNING id INTO v_id;

  FOREACH v_tag IN ARRAY coalesce(p_tagged_users,'{}'::uuid[]) LOOP
    INSERT INTO public.wall_post_tag(post_id,user_id) VALUES(v_id,v_tag) ON CONFLICT DO NOTHING;
  END LOOP;
  RETURN v_id;
END
$$;


ALTER FUNCTION public.create_wall_post(p_activity_id uuid, p_media jsonb, p_caption text, p_ttl_days smallint, p_tagged_users uuid[]) OWNER TO postgres;

--
-- Name: delete_payment_info(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_payment_info(p_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
    v_value_secret_id uuid;
    v_name_secret_id uuid;
begin
    delete from public.user_payment_info
    where id = p_id and user_id = auth.uid()
    returning value_secret_id, account_name_secret_id
    into v_value_secret_id, v_name_secret_id;

    delete from vault.secrets where id in (v_value_secret_id, v_name_secret_id);
end;
$$;


ALTER FUNCTION public.delete_payment_info(p_id uuid) OWNER TO postgres;

--
-- Name: delete_wall_post(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_wall_post(p_post_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_media jsonb;
begin
    select media into v_media
        from public.wall_post
        where id = p_post_id and author_id = auth.uid();
    if v_media is null then raise exception 'not your post'; end if;

    insert into public.wall_post_gc (bucket_id, path)
        select bucket_id, path from public.fn_wall_post_media_gc_paths(v_media)
        on conflict do nothing;

    delete from public.wall_post where id = p_post_id;
end;
$$;


ALTER FUNCTION public.delete_wall_post(p_post_id uuid) OWNER TO postgres;

--
-- Name: edit_freeplay_listing(uuid, integer, text, text[], uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.edit_freeplay_listing(p_activity_id uuid, p_capacity integer, p_description text, p_recommended_skills text[], p_location_id uuid DEFAULT NULL::uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_current_capacity integer;
  v_current_location uuid;
  v_accepted integer;
  v_has_requests boolean;
BEGIN
  SELECT fa.capacity,a.location_id INTO v_current_capacity,v_current_location
  FROM public.freeplay_activity fa
  JOIN public.activity a ON a.id=fa.activity_id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE a.id=p_activity_id AND h.user_id=v_uid AND fa.cancelled_at IS NULL
  FOR UPDATE OF fa,a;
  IF NOT FOUND THEN RAISE EXCEPTION 'activity not found or not owned'; END IF;

  SELECT count(*)::integer INTO v_accepted
  FROM public.freeplay_request
  WHERE activity_id=p_activity_id AND status='accepted';
  v_has_requests := EXISTS(
    SELECT 1 FROM public.freeplay_request
    WHERE activity_id=p_activity_id AND status IN ('pending','accepted'));

  IF p_capacity<v_current_capacity OR p_capacity<v_accepted THEN
    RAISE EXCEPTION 'capacity can only increase';
  END IF;
  IF p_location_id IS NOT NULL
     AND NOT EXISTS(SELECT 1 FROM public.location WHERE id=p_location_id) THEN
    RAISE EXCEPTION 'location not found';
  END IF;
  IF v_has_requests
     AND p_location_id IS DISTINCT FROM v_current_location
     AND p_location_id IS NOT NULL THEN
    RAISE EXCEPTION 'location cannot change after requests';
  END IF;

  IF p_location_id IS NOT NULL THEN
    UPDATE public.activity SET location_id=p_location_id WHERE id=p_activity_id;
  END IF;
  UPDATE public.freeplay_activity
  SET capacity=p_capacity,
      description=coalesce(p_description,''),
      recommended_skills=p_recommended_skills,
      updated_at=now()
  WHERE activity_id=p_activity_id;
END
$$;


ALTER FUNCTION public.edit_freeplay_listing(p_activity_id uuid, p_capacity integer, p_description text, p_recommended_skills text[], p_location_id uuid) OWNER TO postgres;

--
-- Name: end_course(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.end_course(p_course_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_students uuid[];
BEGIN
  IF NOT public.fn_is_course_coach(p_course_id, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;

  UPDATE public.course SET status = 'ended', ended_at = now()
  WHERE id = p_course_id AND status = 'active';
  IF NOT FOUND THEN RAISE EXCEPTION 'active course not found'; END IF;

  -- Upcoming approved sessions can't survive the course.
  DELETE FROM public.activity
  WHERE course_id = p_course_id AND start_time > now();

  PERFORM public.fn_course_system_message(p_course_id, 'course_ended');

  SELECT array_agg(m.user_id) INTO v_students FROM public.course_member m
  WHERE m.course_id = p_course_id AND m.status = 'enrolled';
  IF v_students IS NOT NULL THEN
    PERFORM public.fn_enqueue_notification('course_ended', v_students,
      'Khoá học đã kết thúc', 'Bạn có thể đánh giá huấn luyện viên.',
      jsonb_build_object('course_id', p_course_id));
  END IF;

  -- Free the one-coach-per-sport / one-live-thread partial unique indexes —
  -- an ended course's membership is no longer "live". Mirrors leave_course's
  -- own transition, just applied to the whole roster at once.
  UPDATE public.course_member SET status = 'left', left_at = now()
  WHERE course_id = p_course_id AND status IN ('inquiring','enrolled');
END
$$;


ALTER FUNCTION public.end_course(p_course_id uuid) OWNER TO postgres;

--
-- Name: evaluate_achievements(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.evaluate_achievements(p_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_eligible_from timestamptz;
  v_prev_level int;
  v_prev_xp    bigint;
  v_new_xp     bigint;
  v_new_level  int;
  a            RECORD;
  v_val        numeric;
  v_thr        numeric;
  v_cmp        text;
  v_pk         text;
  v_met        boolean;
  v_newly      jsonb := '[]'::jsonb;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT GREATEST(u.created_at, now() - interval '90 days'),
         COALESCE(u.xp, 0), COALESCE(u.level, 1)
    INTO v_eligible_from, v_prev_xp, v_prev_level
    FROM public."user" u WHERE u.id = p_user_id;

  FOR a IN SELECT * FROM public.achievement WHERE criteria IS NOT NULL LOOP
    v_thr := COALESCE((a.criteria->>'threshold')::numeric, 1);
    v_cmp := COALESCE(a.criteria->>'comparator', '>=');
    v_pk  := public._achievement_period_key(a.criteria);

    CONTINUE WHEN EXISTS(
      SELECT 1 FROM public.user_achievement ua
      WHERE ua.user_id = p_user_id AND ua.achievement_id = a.id AND ua.period_key = v_pk
    );

    v_val := public._achievement_current_value(p_user_id, a.criteria, v_eligible_from);
    v_met := CASE WHEN v_cmp = '>' THEN v_val > v_thr ELSE v_val >= v_thr END;

    IF v_met THEN
      INSERT INTO public.user_achievement(user_id, achievement_id, period_key, xp_granted)
      VALUES (p_user_id, a.id, v_pk, a.xp_reward)
      ON CONFLICT (user_id, achievement_id, period_key) DO NOTHING;

      IF FOUND THEN
        v_newly := v_newly || jsonb_build_object(
          'code', a.code, 'name', a.name, 'xp', a.xp_reward,
          'difficulty', a.difficulty, 'consistency', a.consistency,
          'repeatable', a.repeatable);
      END IF;
    END IF;
  END LOOP;

  SELECT COALESCE(SUM(xp_granted), 0) INTO v_new_xp
    FROM public.user_achievement WHERE user_id = p_user_id;
  v_new_level := public._achievement_level_for_xp(v_new_xp);

  UPDATE public."user" SET xp = v_new_xp, level = v_new_level WHERE id = p_user_id;

  RETURN jsonb_build_object(
    'newly_unlocked', v_newly,
    'xp_total',       v_new_xp,
    'level',          v_new_level,
    'previous_level', v_prev_level,
    'leveled_up',     v_new_level > v_prev_level,
    'xp_gained',      v_new_xp - v_prev_xp
  );
END;
$$;


ALTER FUNCTION public.evaluate_achievements(p_user_id uuid) OWNER TO postgres;

--
-- Name: evaluate_vitality_score(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.evaluate_vitality_score(p_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_today             date := now()::date;
  v_eligible_from      date;
  v_has_prior_load     boolean;
  v_recompute_from     date;

  v_ctl_today          real;
  v_ctl_28ago          real;
  v_atl_today          real;

  v_sessions_28d       integer;
  v_freq_weekly        real;
  v_consistency        real;

  v_load_28d           real;
  v_load_weekly        real;
  v_load               real;

  v_rhr_7d             real;
  v_rhr_56d            real;
  v_rhr_stddev         real;
  v_rhr_z              real;
  v_recovery           real;

  v_cal_28d            real;
  v_cal_weekly         real;
  v_volume             real;

  v_streak_weeks       integer;
  v_streak_bonus       real;

  v_score_sum          real;
  v_weight_sum         real;
  v_score              real;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT GREATEST(u.created_at::date, v_today - 90)
    INTO v_eligible_from
    FROM public."user" u WHERE u.id = p_user_id;

  v_has_prior_load := EXISTS(
    SELECT 1 FROM public.vitality_daily_load WHERE user_id = p_user_id
  );
  v_recompute_from := GREATEST(
    CASE WHEN v_has_prior_load THEN v_today - 7 ELSE v_eligible_from END,
    v_eligible_from
  );

  INSERT INTO public.vitality_daily_load (user_id, date, session_load, session_count, computed_at)
  SELECT
    p_user_id,
    a.start_time::date,
    SUM(public._activity_metric_value(m, 'session_load')),
    COUNT(*),
    now()
  FROM public.activity_health_metrics m
  JOIN public.activity a ON a.id = m.activity_id
  WHERE m.user_id = p_user_id AND NOT m.dismissed
    AND a.start_time::date BETWEEN v_recompute_from AND v_today
  GROUP BY a.start_time::date
  ON CONFLICT (user_id, date) DO UPDATE
    SET session_load  = EXCLUDED.session_load,
        session_count = EXCLUDED.session_count,
        computed_at   = now();

  INSERT INTO public.vitality_daily_load (user_id, date, session_load, session_count, computed_at)
  SELECT p_user_id, gs.d::date, 0, 0, now()
  FROM generate_series(v_recompute_from, v_today, interval '1 day') AS gs(d)
  ON CONFLICT (user_id, date) DO NOTHING;

  v_ctl_today := public._vitality_ewma(p_user_id, v_today, 42);
  v_ctl_28ago := public._vitality_ewma(p_user_id, v_today - 28, 42);
  v_atl_today := public._vitality_ewma(p_user_id, v_today, 7);

  SELECT COUNT(*) INTO v_sessions_28d
    FROM public.activity_health_metrics m
    JOIN public.activity a ON a.id = m.activity_id
    WHERE m.user_id = p_user_id AND NOT m.dismissed
      AND a.start_time::date BETWEEN v_today - 27 AND v_today;

  v_freq_weekly := v_sessions_28d / 4.0;
  v_consistency := public._vitality_scale(
    v_freq_weekly,
    ARRAY[0, 1, 2, 3, 4, 5, 6],
    ARRAY[20, 45, 55, 65, 75, 85, 92]
  );

  SELECT COALESCE(SUM(public._activity_metric_value(m, 'session_load')), 0) INTO v_load_28d
    FROM public.activity_health_metrics m
    JOIN public.activity a ON a.id = m.activity_id
    WHERE m.user_id = p_user_id AND NOT m.dismissed
      AND a.start_time::date BETWEEN v_today - 27 AND v_today;

  v_load_weekly := v_load_28d / 4.0;
  v_load := public._vitality_scale(
    v_load_weekly,
    ARRAY[0, 60, 120, 200, 320, 450],
    ARRAY[20, 38, 55, 68, 80, 92]
  );

  SELECT AVG(resting_heart_rate) INTO v_rhr_7d
    FROM public.daily_health_summary
    WHERE user_id = p_user_id AND date BETWEEN v_today - 6 AND v_today
      AND resting_heart_rate IS NOT NULL;

  SELECT AVG(resting_heart_rate), STDDEV(resting_heart_rate) INTO v_rhr_56d, v_rhr_stddev
    FROM public.daily_health_summary
    WHERE user_id = p_user_id AND date BETWEEN v_today - 55 AND v_today
      AND resting_heart_rate IS NOT NULL;

  IF v_rhr_7d IS NULL OR v_rhr_56d IS NULL THEN
    v_recovery := NULL;
  ELSE
    v_rhr_z := (v_rhr_56d - v_rhr_7d) / GREATEST(COALESCE(v_rhr_stddev, 0), 2.0);
    v_recovery := LEAST(100, GREATEST(0, 50 + v_rhr_z * 25));
  END IF;

  SELECT SUM(active_calories) INTO v_cal_28d
    FROM public.daily_health_summary
    WHERE user_id = p_user_id AND date BETWEEN v_today - 27 AND v_today;

  IF v_cal_28d IS NULL THEN
    v_volume := NULL;
  ELSE
    v_cal_weekly := v_cal_28d / 4.0;
    v_volume := public._vitality_scale(
      v_cal_weekly,
      ARRAY[0, 500, 1000, 2000, 3200, 4500],
      ARRAY[20, 35, 55, 70, 85, 93]
    );
  END IF;

  v_streak_weeks := 0;
  FOR i IN 0..7 LOOP
    EXIT WHEN NOT EXISTS(
      SELECT 1 FROM public.activity_health_metrics m
      JOIN public.activity a ON a.id = m.activity_id
      WHERE m.user_id = p_user_id AND NOT m.dismissed
        AND date_trunc('week', a.start_time::date)
          = date_trunc('week', v_today) - (i || ' weeks')::interval
    );
    v_streak_weeks := v_streak_weeks + 1;
  END LOOP;
  v_streak_bonus := CASE WHEN v_streak_weeks >= 4 THEN 3 ELSE 0 END;

  v_score_sum := v_consistency * 0.40;
  v_weight_sum := 0.40;
  v_score_sum := v_score_sum + v_load * 0.30;
  v_weight_sum := v_weight_sum + 0.30;
  IF v_recovery IS NOT NULL THEN
    v_score_sum := v_score_sum + v_recovery * 0.15;
    v_weight_sum := v_weight_sum + 0.15;
  END IF;
  IF v_volume IS NOT NULL THEN
    v_score_sum := v_score_sum + v_volume * 0.15;
    v_weight_sum := v_weight_sum + 0.15;
  END IF;

  IF (v_today - v_eligible_from) < 14 THEN
    v_score := NULL;
  ELSE
    v_score := LEAST(100, (v_score_sum / v_weight_sum) + v_streak_bonus);
  END IF;

  INSERT INTO public.vitality_score (
    user_id, date, score, consistency_component, load_component,
    recovery_component, volume_component, streak_bonus, ctl, atl, computed_at
  ) VALUES (
    p_user_id, v_today, v_score, v_consistency, v_load,
    v_recovery, v_volume, v_streak_bonus, v_ctl_today, v_atl_today, now()
  )
  ON CONFLICT (user_id, date) DO UPDATE
    SET score                 = EXCLUDED.score,
        consistency_component = EXCLUDED.consistency_component,
        load_component        = EXCLUDED.load_component,
        recovery_component    = EXCLUDED.recovery_component,
        volume_component      = EXCLUDED.volume_component,
        streak_bonus          = EXCLUDED.streak_bonus,
        ctl                   = EXCLUDED.ctl,
        atl                   = EXCLUDED.atl,
        computed_at           = now();

  RETURN jsonb_build_object(
    'date', v_today,
    'score', v_score,
    'consistency_component', v_consistency,
    'load_component', v_load,
    'recovery_component', v_recovery,
    'volume_component', v_volume,
    'streak_bonus', v_streak_bonus,
    'ctl', v_ctl_today,
    'atl', v_atl_today
  );
END;
$$;


ALTER FUNCTION public.evaluate_vitality_score(p_user_id uuid) OWNER TO postgres;

--
-- Name: expire_past_activities(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.expire_past_activities() RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_uid   uuid := auth.uid();
  v_count int;
BEGIN
  DELETE FROM public.activity a
  WHERE a.lobby_id IS NOT NULL
    AND a.start_time < now()
    AND NOT (
      a.series_id IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM public.activity_series_frontier f
         WHERE f.series_id = a.series_id AND f.frontier_start = a.start_time
      )
    )
    AND NOT public.activity_is_confirmed(a.id)
    AND NOT EXISTS (
      SELECT 1 FROM public.lobby_match lm WHERE lm.activity_id = a.id
    )
    AND EXISTS (
      SELECT 1 FROM public.lobby_member m
      WHERE m.lobby_id = a.lobby_id AND m.user_id = v_uid
    );

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;


ALTER FUNCTION public.expire_past_activities() OWNER TO postgres;

--
-- Name: find_course_with_coach(uuid, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.find_course_with_coach(p_professional_id uuid, p_sport_id bigint) RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT m.course_id FROM public.course_member m
  WHERE m.user_id = auth.uid() AND m.professional_id = p_professional_id
    AND m.sport_id = p_sport_id AND m.status IN ('inquiring','enrolled')
  LIMIT 1;
$$;


ALTER FUNCTION public.find_course_with_coach(p_professional_id uuid, p_sport_id bigint) OWNER TO postgres;

--
-- Name: fn_activity_attachment_role_check(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_activity_attachment_role_check() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
  IF NEW.referee_booking_id IS NOT NULL AND NOT EXISTS (
      SELECT 1
      FROM public.referee_booking pb
      JOIN public.professional p ON p.id = pb.professional_id
      WHERE pb.id = NEW.referee_booking_id
        AND p.professional_role = 'referee'
  ) THEN
    RAISE EXCEPTION 'referee_booking_id % must reference a referee booking', NEW.referee_booking_id;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_activity_attachment_role_check() OWNER TO postgres;

--
-- Name: fn_apply_match_rating(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_apply_match_rating(p_match_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    c_home_adv    constant integer := 50;
    c_k_new       constant numeric := 32;
    c_k_settled   constant numeric := 20;
    c_provisional constant integer := 10;
    c_margin_cap  constant numeric := 2.0;

    v_home     uuid;
    v_away     uuid;
    v_result   public.lobby_match_result;
    v_sets     jsonb;
    v_activity uuid;
    v_challenge uuid;
    v_sport    text;
    v_home_mmr integer;
    v_away_mmr integer;
    v_expected numeric;
    v_score    numeric;
    v_margin   numeric := 0;
    v_mult     numeric := 1;
    r          record;
BEGIN
    SELECT m.lobby_id, m.opponent_lobby_id, m.result, m.sets, m.activity_id
      INTO v_home, v_away, v_result, v_sets, v_activity
      FROM public.lobby_match m WHERE m.id = p_match_id;

    IF v_away IS NULL OR v_result = 'practice' THEN RETURN; END IF;

    SELECT challenge_id INTO v_challenge FROM public.activity WHERE id = v_activity;
    IF v_challenge IS NULL THEN RETURN; END IF;

    SELECT public.fn_sport_name(sport_id), mmr INTO v_sport, v_home_mmr
      FROM public.lobby WHERE id = v_home;
    SELECT mmr INTO v_away_mmr FROM public.lobby WHERE id = v_away;
    IF v_sport IS NULL THEN RETURN; END IF;

    v_expected := 1.0 / (1.0 + power(10.0,
        ((v_away_mmr - (v_home_mmr + c_home_adv))::numeric / 400.0)));
    v_score := CASE v_result WHEN 'win' THEN 1.0 WHEN 'draw' THEN 0.5 ELSE 0.0 END;

    IF v_sets IS NOT NULL AND jsonb_typeof(v_sets) = 'array' THEN
        SELECT COALESCE(abs(sum((s->>0)::numeric - (s->>1)::numeric)), 0)
          INTO v_margin
          FROM jsonb_array_elements(v_sets) s;
    END IF;
    IF v_margin > 1 THEN
        v_mult := LEAST(c_margin_cap, 1 + 0.5 * ln(v_margin));
    END IF;

    FOR r IN
        SELECT a.lobby_id,
               ac.user_id,
               CASE WHEN a.lobby_id = v_home THEN v_score ELSE 1.0 - v_score END AS s,
               CASE WHEN a.lobby_id = v_home THEN v_expected ELSE 1.0 - v_expected END AS e
          FROM public.activity a
          JOIN public.activity_confirmation ac ON ac.activity_id = a.id
         WHERE a.challenge_id = v_challenge AND ac.attendance = 'going'
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM public.user_rating
             WHERE user_id = r.user_id AND sport = v_sport AND format IS NULL
        ) THEN
            INSERT INTO public.user_rating (user_id, sport, elo, games_played)
            VALUES (r.user_id, v_sport, 1000, 0);
        END IF;

        UPDATE public.user_rating ur
           SET elo = GREATEST(100, ur.elo + round(
                   (CASE WHEN ur.games_played < c_provisional THEN c_k_new ELSE c_k_settled END)
                   * v_mult * (r.s - r.e))::integer),
               games_played = ur.games_played + 1,
               updated_at = now()
         WHERE ur.user_id = r.user_id AND ur.sport = v_sport AND ur.format IS NULL;
    END LOOP;
END;
$$;


ALTER FUNCTION public.fn_apply_match_rating(p_match_id uuid) OWNER TO postgres;

--
-- Name: fn_broadcast_message(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_broadcast_message() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_payload jsonb; v_username text; v_avatar text;
BEGIN
  SELECT u.username::text, u.details->>'generatedAvatar'
  INTO v_username, v_avatar
  FROM public."user" u WHERE u.id = NEW.sender_id;

  v_payload := jsonb_build_object(
    'id', NEW.id,
    'conversation_id', NEW.conversation_id,
    'sender_id', NEW.sender_id,
    'sender_username', v_username,
    'sender_avatar', v_avatar,
    'kind', NEW.kind::text,
    'created_at', NEW.created_at
  );

  IF NEW.kind IN ('text','system') THEN
    v_payload := v_payload || jsonb_build_object('body', NEW.body, 'payload', NEW.payload);
  ELSIF NEW.kind = 'poll' THEN
    v_payload := v_payload || jsonb_build_object('payload', NEW.payload);
  END IF;

  PERFORM realtime.send(
    v_payload,
    'new_message',
    'conversation:' || NEW.conversation_id::text,
    true
  );
  RETURN NULL;
END
$$;


ALTER FUNCTION public.fn_broadcast_message() OWNER TO postgres;

--
-- Name: fn_bump_series_frontier(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_bump_series_frontier() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
    IF NEW.series_id IS NULL THEN
        RETURN NEW;
    END IF;
    INSERT INTO public.activity_series_frontier (series_id, frontier_start)
    VALUES (NEW.series_id, NEW.start_time)
    ON CONFLICT (series_id) DO UPDATE SET frontier_start = EXCLUDED.frontier_start;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_bump_series_frontier() OWNER TO postgres;

--
-- Name: fn_can_access_course_activity(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_can_access_course_activity(p_activity_id uuid, p_uid uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.activity a
    WHERE a.id = p_activity_id AND a.course_id IS NOT NULL
      AND (
        public.fn_is_enrolled_course_member(a.course_id, p_uid)
        OR public.fn_is_course_coach(a.course_id, p_uid)
      )
  );
$$;


ALTER FUNCTION public.fn_can_access_course_activity(p_activity_id uuid, p_uid uuid) OWNER TO postgres;

--
-- Name: fn_can_receive_conversation_topic(text, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_can_receive_conversation_topic(p_topic text, p_uid uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.conversation_member cm
    WHERE cm.user_id = p_uid
      AND cm.left_at IS NULL
      AND p_topic = 'conversation:' || cm.conversation_id::text
  );
$$;


ALTER FUNCTION public.fn_can_receive_conversation_topic(p_topic text, p_uid uuid) OWNER TO postgres;

--
-- Name: fn_can_see_message(uuid, timestamp with time zone, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_can_see_message(p_conversation_id uuid, p_created_at timestamp with time zone, p_uid uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.conversation_member m
    WHERE m.conversation_id = p_conversation_id
      AND m.user_id = p_uid
      AND p_created_at >= m.joined_at
      AND (m.left_at IS NULL OR p_created_at <= m.left_at)
  );
$$;


ALTER FUNCTION public.fn_can_see_message(p_conversation_id uuid, p_created_at timestamp with time zone, p_uid uuid) OWNER TO postgres;

--
-- Name: fn_can_see_wall_post(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_can_see_wall_post(p_post_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    select exists (
        select 1
        from public.wall_post p
        where p.id = p_post_id
          and (
            p.author_id = auth.uid()
            or (
                p.hidden_at is null
                and p.expires_at > now()
                and not public.fn_is_blocked(auth.uid(), p.author_id)
                and (
                    p.author_id in (select public.get_my_friend_ids())
                    or p.author_id in (select public.get_my_lobbymate_ids())
                    or exists (
                        select 1 from public.wall_post_tag t
                        where t.post_id = p.id
                          and (
                            t.user_id = auth.uid()
                            or t.user_id in (select public.get_my_friend_ids())
                          )
                    )
                )
            )
          )
    );
$$;


ALTER FUNCTION public.fn_can_see_wall_post(p_post_id uuid) OWNER TO postgres;

--
-- Name: fn_can_write_conversation(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_can_write_conversation(p_conversation_id uuid, p_uid uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_kind public.conversation_kind; v_request uuid; v_course uuid;
BEGIN
  SELECT c.kind, c.freeplay_request_id, c.course_id
  INTO v_kind, v_request, v_course
  FROM public.conversation c WHERE c.id = p_conversation_id;
  IF NOT FOUND THEN RETURN false; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.conversation_member m
    WHERE m.conversation_id = p_conversation_id
      AND m.user_id = p_uid AND m.left_at IS NULL
  ) THEN RETURN false; END IF;

  IF v_kind = 'freeplay' THEN
    RETURN coalesce((
      SELECT CASE
        WHEN r.status = 'pending' THEN a.end_time > now()
        WHEN r.status = 'accepted' THEN a.end_time + interval '7 days' > now()
        WHEN r.status = 'host_cancelled' THEN a.end_time + interval '7 days' > now()
        ELSE false END
      FROM public.freeplay_request r
      JOIN public.activity a ON a.id = r.activity_id
      JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
      WHERE r.id = v_request
        AND NOT public.fn_is_blocked(r.user_id, h.user_id)
    ), false);
  END IF;

  RETURN EXISTS (
    SELECT 1 FROM public.course c
    WHERE c.id = v_course AND c.status = 'active'
  );
END
$$;


ALTER FUNCTION public.fn_can_write_conversation(p_conversation_id uuid, p_uid uuid) OWNER TO postgres;

--
-- Name: notification_outbox; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_outbox (
    id bigint NOT NULL,
    kind public.notification_kind NOT NULL,
    recipient_user_id uuid NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    attempt_count integer DEFAULT 0 NOT NULL,
    last_error text,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT notification_outbox_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'sending'::text, 'sent'::text, 'failed'::text])))
);


ALTER TABLE public.notification_outbox OWNER TO postgres;

--
-- Name: fn_claim_outbox(integer, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_claim_outbox(p_limit integer DEFAULT 100, p_max_attempts integer DEFAULT 3, p_stale text DEFAULT '2 minutes'::text) RETURNS SETOF public.notification_outbox
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    return query
    update public.notification_outbox o
       set status        = 'sending',
           attempt_count = o.attempt_count + 1,
           updated_at    = now()
     where o.id in (
        select id from public.notification_outbox
         where attempt_count < p_max_attempts
           and (status = 'pending'
                or (status = 'sending' and updated_at < now() - p_stale::interval))
         order by created_at
         limit p_limit
         for update skip locked
     )
    returning o.*;
end;
$$;


ALTER FUNCTION public.fn_claim_outbox(p_limit integer, p_max_attempts integer, p_stale text) OWNER TO postgres;

--
-- Name: fn_clear_read_notifications(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_clear_read_notifications() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    delete from public.notification_outbox
        where recipient_user_id = auth.uid() and read_at is not null;
end;
$$;


ALTER FUNCTION public.fn_clear_read_notifications() OWNER TO postgres;

--
-- Name: fn_complete_referee_booking_on_match(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_complete_referee_booking_on_match() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
    IF NEW.referee_booking_id IS NOT NULL THEN
        UPDATE public.referee_booking
        SET status = 'completed'
        WHERE id = NEW.referee_booking_id
          AND status = 'confirmed';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_complete_referee_booking_on_match() OWNER TO postgres;

--
-- Name: fn_course_add_member(uuid, uuid, public.course_member_status); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_course_add_member(p_course_id uuid, p_user_id uuid, p_status public.course_member_status) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_conversation uuid;
BEGIN
  INSERT INTO public.course_member(course_id, user_id, status)
  VALUES (p_course_id, p_user_id, p_status)
  ON CONFLICT (course_id, user_id) DO UPDATE
    SET status = excluded.status, left_at = NULL;

  SELECT c.id INTO v_conversation FROM public.conversation c WHERE c.course_id = p_course_id;
  IF v_conversation IS NOT NULL THEN
    INSERT INTO public.conversation_member(conversation_id, user_id)
    VALUES (v_conversation, p_user_id)
    ON CONFLICT (conversation_id, user_id) DO UPDATE SET left_at = NULL;
  END IF;
END
$$;


ALTER FUNCTION public.fn_course_add_member(p_course_id uuid, p_user_id uuid, p_status public.course_member_status) OWNER TO postgres;

--
-- Name: fn_course_held_sessions(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_course_held_sessions(p_course_id uuid) RETURNS integer
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT count(*)::integer FROM public.activity a
  WHERE a.course_id = p_course_id
    AND a.proposal_status = 'approved'
    AND coalesce(a.end_time, a.start_time) < now();
$$;


ALTER FUNCTION public.fn_course_held_sessions(p_course_id uuid) OWNER TO postgres;

--
-- Name: fn_course_member_denormalise(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_course_member_denormalise() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  SELECT c.professional_id, c.sport_id INTO NEW.professional_id, NEW.sport_id
  FROM public.course c WHERE c.id = NEW.course_id;
  RETURN NEW;
END
$$;


ALTER FUNCTION public.fn_course_member_denormalise() OWNER TO postgres;

--
-- Name: fn_course_prompt_if_no_students(uuid, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_course_prompt_if_no_students(p_course_id uuid, p_was_enrolled boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_coach uuid;
BEGIN
  IF NOT p_was_enrolled THEN RETURN; END IF;
  IF EXISTS (
    SELECT 1 FROM public.course_member m
    WHERE m.course_id = p_course_id AND m.status = 'enrolled' AND m.left_at IS NULL
  ) THEN RETURN; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.course WHERE id = p_course_id AND status = 'active') THEN
    RETURN;
  END IF;

  PERFORM public.fn_course_system_message(p_course_id, 'no_students_left');

  SELECT p.linked_user_id INTO v_coach FROM public.professional p
  JOIN public.course c ON c.professional_id = p.id WHERE c.id = p_course_id;
  IF v_coach IS NOT NULL THEN
    PERFORM public.fn_enqueue_notification('course_ended', ARRAY[v_coach],
      'Khoá học không còn học viên', 'Bạn có thể mời học viên mới hoặc kết thúc khoá học.',
      jsonb_build_object('course_id', p_course_id));
  END IF;
END
$$;


ALTER FUNCTION public.fn_course_prompt_if_no_students(p_course_id uuid, p_was_enrolled boolean) OWNER TO postgres;

--
-- Name: fn_course_review_rollup(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_course_review_rollup() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_professional uuid;
BEGIN
  SELECT c.professional_id INTO v_professional
  FROM public.course c WHERE c.id = NEW.course_id;

  UPDATE public.professional p SET
    average_rating = sub.avg_rating,
    review_count = sub.total
  FROM (
    SELECT avg(r.rating)::numeric(3,2) AS avg_rating, count(*) AS total
    FROM public.course_review r
    JOIN public.course c ON c.id = r.course_id
    WHERE c.professional_id = v_professional
  ) sub
  WHERE p.id = v_professional;
  RETURN NULL;
END
$$;


ALTER FUNCTION public.fn_course_review_rollup() OWNER TO postgres;

--
-- Name: fn_course_system_message(uuid, text, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_course_system_message(p_course_id uuid, p_code text, p_payload jsonb DEFAULT NULL::jsonb) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_conversation uuid;
BEGIN
  SELECT c.id INTO v_conversation FROM public.conversation c WHERE c.course_id = p_course_id;
  IF v_conversation IS NULL THEN RETURN; END IF;
  INSERT INTO public.message(conversation_id, kind, body, payload)
  VALUES (v_conversation, 'system', p_code, p_payload);
END
$$;


ALTER FUNCTION public.fn_course_system_message(p_course_id uuid, p_code text, p_payload jsonb) OWNER TO postgres;

--
-- Name: fn_cron_tick(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_cron_tick() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
  PERFORM public.fn_sweep_challenges();
  PERFORM public.fn_sweep_activity_thresholds();
  PERFORM public.fn_sweep_activity_payment_requests();
  PERFORM public.fn_sweep_freeplay();
  PERFORM public.fn_sweep_course_targets();
  PERFORM public.fn_process_reminders();
  IF EXISTS (SELECT 1 FROM public.notification_outbox WHERE status IN ('pending','sending')) THEN
    PERFORM public.fn_invoke_send_push();
  END IF;
END;
$$;


ALTER FUNCTION public.fn_cron_tick() OWNER TO postgres;

--
-- Name: fn_delete_notification(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_delete_notification(p_id bigint) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    delete from public.notification_outbox
        where id = p_id and recipient_user_id = auth.uid();
end;
$$;


ALTER FUNCTION public.fn_delete_notification(p_id bigint) OWNER TO postgres;

--
-- Name: fn_emit_activity_confirmed(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_emit_activity_confirmed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_threshold  int;
    v_lobby_id   uuid;
    v_challenge  uuid;
    v_going      int;
    v_recipients uuid[];
    v_lobby_name text;
begin
    select a.confirmation_threshold, a.lobby_id, a.challenge_id
        into v_threshold, v_lobby_id, v_challenge
        from public.activity a
        where a.id = new.activity_id;

    if v_threshold is null or v_lobby_id is null or v_challenge is not null then
        return new;
    end if;

    if new.attendance <> 'going' then
        return new;
    end if;
    if tg_op = 'UPDATE' and old.attendance = 'going' then
        return new;
    end if;

    select count(*) filter (where attendance = 'going') into v_going
        from public.activity_confirmation
        where activity_id = new.activity_id;

    if v_going <> v_threshold then
        return new;
    end if;

    select array_agg(lm.user_id) into v_recipients
        from public.lobby_member lm
        where lm.lobby_id = v_lobby_id;

    select l.name into v_lobby_name from public.lobby l where l.id = v_lobby_id;

    perform public.fn_enqueue_notification(
        'activity_confirmed',
        v_recipients,
        'Hoạt động đã được chốt',
        coalesce(v_lobby_name, 'Lobby') || ' đã đủ người tham gia',
        jsonb_build_object('lobby_id', v_lobby_id, 'activity_id', new.activity_id)
    );

    return new;
end;
$$;


ALTER FUNCTION public.fn_emit_activity_confirmed() OWNER TO postgres;

--
-- Name: fn_emit_activity_scheduled(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_emit_activity_scheduled() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_recipients     uuid[];
    v_lobby_name     text;
    v_location_name  text;
begin
    if new.lobby_id is null or new.challenge_id is not null then
        return new;
    end if;

    select array_agg(lm.user_id) into v_recipients
        from public.lobby_member lm
        where lm.lobby_id = new.lobby_id and lm.user_id <> new.user_id;

    if v_recipients is null or array_length(v_recipients, 1) = 0 then
        return new;
    end if;

    select l.name into v_lobby_name from public.lobby l where l.id = new.lobby_id;
    select loc.name into v_location_name from public.location loc where loc.id = new.location_id;

    perform public.fn_enqueue_notification(
        'activity_scheduled',
        v_recipients,
        coalesce(v_lobby_name, 'Lobby') || ' vừa lên lịch buổi chơi mới',
        'Lúc ' || to_char(new.start_time at time zone 'Asia/Ho_Chi_Minh', 'HH24:MI DD/MM')
            || coalesce(' tại ' || v_location_name, '') || ' — xác nhận tham gia nhé',
        jsonb_build_object('lobby_id', new.lobby_id, 'activity_id', new.id)
    );

    return new;
end;
$$;


ALTER FUNCTION public.fn_emit_activity_scheduled() OWNER TO postgres;

--
-- Name: fn_emit_lobby_join_request(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_emit_lobby_join_request() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_captain_id     uuid;
    v_lobby_name     text;
    v_requester_name text;
begin
    if new.interaction_type <> 'request'
       or new.status <> 'pending'
       or new.target_lobby_id is null then
        return new;
    end if;

    select l.captain_id, l.name
      into v_captain_id, v_lobby_name
      from public.lobby l
     where l.id = new.target_lobby_id;

    if v_captain_id is null then
        return new;
    end if;

    select concat(u.username, '#', u.tag_number)
      into v_requester_name
      from public."user" u
     where u.id = new.initiator_user_id;

    perform public.fn_enqueue_notification(
        'lobby_join_request',
        array[v_captain_id],
        'Yêu cầu tham gia lobby',
        coalesce(v_requester_name, 'Một người chơi') ||
            ' muốn tham gia ' || coalesce(v_lobby_name, 'lobby của bạn'),
        jsonb_build_object(
            'lobby_id', new.target_lobby_id::text,
            'record_id', new.id::text,
            'user_id', new.initiator_user_id::text
        )
    );

    return new;
end;
$$;


ALTER FUNCTION public.fn_emit_lobby_join_request() OWNER TO postgres;

--
-- Name: fn_emit_lobby_join_request_response(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_emit_lobby_join_request_response() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_lobby_name text;
begin
    if new.interaction_type <> 'request'
       or old.status <> 'pending'
       or new.status not in ('accepted', 'declined')
       or new.target_lobby_id is null then
        return new;
    end if;

    -- The table's broad legacy UPDATE policy also lets an initiator cancel
    -- their own request. Only a captain/coordinator decision is an approval or
    -- denial worthy of a push; this also prevents a forged self-response push.
    if not public.lobby_can_manage(new.target_lobby_id, auth.uid()) then
        return new;
    end if;

    select l.name
      into v_lobby_name
      from public.lobby l
     where l.id = new.target_lobby_id;

    if new.status = 'accepted' then
        perform public.fn_enqueue_notification(
            'lobby_join_request_approved',
            array[new.initiator_user_id],
            'Yêu cầu tham gia được duyệt',
            'Bạn đã trở thành thành viên của ' ||
                coalesce(v_lobby_name, 'lobby'),
            jsonb_build_object(
                'lobby_id', new.target_lobby_id::text,
                'record_id', new.id::text
            )
        );
    else
        perform public.fn_enqueue_notification(
            'lobby_join_request_denied',
            array[new.initiator_user_id],
            'Yêu cầu tham gia bị từ chối',
            coalesce(v_lobby_name, 'Lobby') ||
                ' đã từ chối yêu cầu tham gia của bạn',
            jsonb_build_object(
                'lobby_id', new.target_lobby_id::text,
                'record_id', new.id::text
            )
        );
    end if;

    return new;
end;
$$;


ALTER FUNCTION public.fn_emit_lobby_join_request_response() OWNER TO postgres;

--
-- Name: fn_emit_member_kicked(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_emit_member_kicked() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_lobby_name    text;
    v_being_deleted text;
begin
    if old.user_id = (select auth.uid()) then
        return old;  -- self-leave, not a kick
    end if;

    v_being_deleted := current_setting('app.lobby_being_deleted', true);
    if v_being_deleted = old.lobby_id::text then
        return old;  -- lobby teardown, not a targeted removal
    end if;

    select name into v_lobby_name from public.lobby where id = old.lobby_id;
    if v_lobby_name is null then
        return old;  -- lobby already gone
    end if;

    perform public.fn_enqueue_notification(
        'member_kicked',
        ARRAY[old.user_id],
        'Bạn đã bị xoá khỏi lobby',
        'Bạn không còn là thành viên của ' || v_lobby_name,
        jsonb_build_object('lobby_id', old.lobby_id::text)
    );

    return old;
end;
$$;


ALTER FUNCTION public.fn_emit_member_kicked() OWNER TO postgres;

--
-- Name: fn_enqueue_notification(public.notification_kind, uuid[], text, text, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_enqueue_notification(p_kind public.notification_kind, p_recipients uuid[], p_title text, p_body text, p_data jsonb DEFAULT '{}'::jsonb) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_enabled      boolean;
    v_inserted     int;
    v_presentation jsonb;
begin
    select enabled into v_enabled
      from public.enabled_notification_kind
     where kind = p_kind;

    if not coalesce(v_enabled, false) then return; end if;

    -- Every recipient in this fanout receives the same snapshot. Resolve it
    -- once so a large lobby notification does not repeat the domain lookups.
    v_presentation := public.fn_notification_presentation(
        p_kind, coalesce(p_data, '{}'::jsonb), p_body
    ) || coalesce(p_data->'presentation', '{}'::jsonb);

    insert into public.notification_outbox
        (kind, recipient_user_id, title, body, data)
    select p_kind, recipient, p_title, p_body,
           coalesce(p_data, '{}'::jsonb)
           || jsonb_build_object('kind', p_kind::text)
           || jsonb_build_object('presentation', v_presentation)
      from unnest(p_recipients) as recipient
     where recipient is not null;

    get diagnostics v_inserted = row_count;
    if v_inserted > 0 then perform public.fn_invoke_send_push(); end if;
end;
$$;


ALTER FUNCTION public.fn_enqueue_notification(p_kind public.notification_kind, p_recipients uuid[], p_title text, p_body text, p_data jsonb) OWNER TO postgres;

--
-- Name: fn_ensure_freeplay_conversation(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_ensure_freeplay_conversation(p_request_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_id uuid; v_requester uuid; v_host uuid; v_created timestamptz;
BEGIN
  SELECT c.id INTO v_id FROM public.conversation c
  WHERE c.freeplay_request_id = p_request_id;
  IF v_id IS NOT NULL THEN RETURN v_id; END IF;

  SELECT r.user_id, h.user_id, r.created_at INTO v_requester, v_host, v_created
  FROM public.freeplay_request r
  JOIN public.activity a ON a.id = r.activity_id
  JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
  WHERE r.id = p_request_id;
  IF v_requester IS NULL THEN RAISE EXCEPTION 'freeplay request not found'; END IF;

  INSERT INTO public.conversation(kind, freeplay_request_id)
  VALUES ('freeplay', p_request_id)
  ON CONFLICT (freeplay_request_id) WHERE freeplay_request_id IS NOT NULL
  DO NOTHING
  RETURNING id INTO v_id;

  IF v_id IS NULL THEN
    SELECT c.id INTO v_id FROM public.conversation c
    WHERE c.freeplay_request_id = p_request_id;
    RETURN v_id;
  END IF;

  INSERT INTO public.conversation_member(conversation_id, user_id, joined_at)
  VALUES (v_id, v_requester, v_created), (v_id, v_host, v_created)
  ON CONFLICT DO NOTHING;

  RETURN v_id;
END
$$;


ALTER FUNCTION public.fn_ensure_freeplay_conversation(p_request_id uuid) OWNER TO postgres;

--
-- Name: fn_fill_payment_request_recipient(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_fill_payment_request_recipient() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_recipient_id uuid;
BEGIN
    SELECT (fi.payload->>'recipient_id')::uuid INTO v_recipient_id
      FROM public.lobby_feed_item fi
     WHERE fi.id=NEW.feed_item_id AND fi.kind='payment_request';
    IF v_recipient_id IS NULL THEN RAISE EXCEPTION 'payment request recipient is missing'; END IF;
    IF v_recipient_id=NEW.user_id THEN RAISE EXCEPTION 'a member cannot owe themselves'; END IF;
    NEW.recipient_id := v_recipient_id;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_fill_payment_request_recipient() OWNER TO postgres;

--
-- Name: fn_freeplay_block_cleanup(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_freeplay_block_cleanup() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
  UPDATE public.freeplay_request r SET status='blocked',resolved_at=now(),updated_at=now()
  FROM public.activity a JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE r.activity_id=a.id AND r.status IN ('pending','accepted')
    AND ((r.user_id=NEW.blocker_id AND h.user_id=NEW.blocked_id) OR (r.user_id=NEW.blocked_id AND h.user_id=NEW.blocker_id));
  DELETE FROM public.activity_confirmation ac USING public.activity a,public.freeplay_host h
  WHERE ac.activity_id=a.id AND h.id=a.freeplay_host_id
    AND ((ac.user_id=NEW.blocker_id AND h.user_id=NEW.blocked_id) OR (ac.user_id=NEW.blocked_id AND h.user_id=NEW.blocker_id));
  RETURN NEW;
END
$$;


ALTER FUNCTION public.fn_freeplay_block_cleanup() OWNER TO postgres;

--
-- Name: fn_freeplay_host_zalo(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_freeplay_host_zalo(p_host_id uuid) RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    SELECT uc.zalo
    FROM public.freeplay_host h
    JOIN public.user_contact uc ON uc.user_id = h.user_id
    WHERE h.id = p_host_id AND h.status = 'active';
$$;


ALTER FUNCTION public.fn_freeplay_host_zalo(p_host_id uuid) OWNER TO postgres;

--
-- Name: fn_guard_referee_booking_review(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_guard_referee_booking_review() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_booking record;
BEGIN
    SELECT pb.client_user_id, pb.professional_id, pb.status, pb.package_id
    INTO v_booking
    FROM public.referee_booking pb
    WHERE pb.id = NEW.booking_id;

    IF NOT FOUND
       OR NEW.reviewer_user_id <> v_booking.client_user_id
       OR NEW.professional_id <> v_booking.professional_id
       OR v_booking.status <> 'completed' THEN
        RAISE EXCEPTION 'referee_booking_review: booking attribution is invalid';
    END IF;

    NEW.package_id := v_booking.package_id;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_guard_referee_booking_review() OWNER TO postgres;

--
-- Name: fn_invoke_send_push(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_invoke_send_push() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_url text;
    v_key text;
begin
    select decrypted_secret into v_url
        from vault.decrypted_secrets where name = 'edge_send_push_url';
    select decrypted_secret into v_key
        from vault.decrypted_secrets where name = 'edge_service_role_key';
    if v_url is null or v_key is null then
        return;
    end if;
    perform net.http_post(
        url     := v_url,
        headers := jsonb_build_object(
            'Content-Type',  'application/json',
            'Authorization', 'Bearer ' || v_key
        ),
        body    := '{}'::jsonb
    );
end;
$$;


ALTER FUNCTION public.fn_invoke_send_push() OWNER TO postgres;

--
-- Name: fn_is_active_freeplay_host(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_is_active_freeplay_host(p_user_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    select exists (
        select 1 from public.freeplay_host h
        where h.user_id = p_user_id and h.status = 'active'
    );
$$;


ALTER FUNCTION public.fn_is_active_freeplay_host(p_user_id uuid) OWNER TO postgres;

--
-- Name: fn_is_blocked(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_is_blocked(p_a uuid, p_b uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    select exists (
        select 1 from public.user_block
        where (blocker_id = p_a and blocked_id = p_b)
           or (blocker_id = p_b and blocked_id = p_a)
    );
$$;


ALTER FUNCTION public.fn_is_blocked(p_a uuid, p_b uuid) OWNER TO postgres;

--
-- Name: fn_is_conversation_member(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_is_conversation_member(p_conversation_id uuid, p_uid uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.conversation_member m
    WHERE m.conversation_id = p_conversation_id AND m.user_id = p_uid
  );
$$;


ALTER FUNCTION public.fn_is_conversation_member(p_conversation_id uuid, p_uid uuid) OWNER TO postgres;

--
-- Name: fn_is_course_coach(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_is_course_coach(p_course_id uuid, p_uid uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.course c
    JOIN public.professional p ON p.id = c.professional_id
    WHERE c.id = p_course_id AND p.linked_user_id = p_uid
  );
$$;


ALTER FUNCTION public.fn_is_course_coach(p_course_id uuid, p_uid uuid) OWNER TO postgres;

--
-- Name: fn_is_course_member(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_is_course_member(p_course_id uuid, p_uid uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.course_member m
    WHERE m.course_id = p_course_id AND m.user_id = p_uid AND m.left_at IS NULL
  );
$$;


ALTER FUNCTION public.fn_is_course_member(p_course_id uuid, p_uid uuid) OWNER TO postgres;

--
-- Name: fn_is_enrolled_course_member(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_is_enrolled_course_member(p_course_id uuid, p_uid uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.course_member m
    WHERE m.course_id = p_course_id AND m.user_id = p_uid
      AND m.status = 'enrolled' AND m.left_at IS NULL
  );
$$;


ALTER FUNCTION public.fn_is_enrolled_course_member(p_course_id uuid, p_uid uuid) OWNER TO postgres;

--
-- Name: fn_is_linked_professional(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_is_linked_professional(p_user_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    select exists (
        select 1 from public.professional p
        where p.linked_user_id = p_user_id
    );
$$;


ALTER FUNCTION public.fn_is_linked_professional(p_user_id uuid) OWNER TO postgres;

--
-- Name: fn_lobby_playtime_keys(jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_lobby_playtime_keys(p_playtime jsonb) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $$
    SELECT COALESCE(array_agg(DISTINCT base_day || ':' || chunk), '{}')
    FROM (
        SELECT
            elem->>'dayChunk' AS chunk,
            unnest(CASE elem->>'dayOfWeek'
                       WHEN 'all' THEN ARRAY['mon','tue','wed','thu','fri','sat','sun']
                       WHEN 'mwf' THEN ARRAY['mon','wed','fri']
                       WHEN 'tts' THEN ARRAY['tue','thu','sat']
                       WHEN 'wkn' THEN ARRAY['sat','sun']
                       ELSE ARRAY[elem->>'dayOfWeek']
                   END) AS base_day
        FROM jsonb_array_elements(
                 CASE WHEN jsonb_typeof(COALESCE(p_playtime, '[]'::jsonb)) = 'array'
                      THEN p_playtime ELSE '[]'::jsonb END
             ) AS elem
        WHERE elem->>'dayChunk' IS NOT NULL AND elem->>'dayOfWeek' IS NOT NULL
    ) expanded;
$$;


ALTER FUNCTION public.fn_lobby_playtime_keys(p_playtime jsonb) OWNER TO postgres;

--
-- Name: fn_lobby_recompute_rated_matches(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_lobby_recompute_rated_matches(p_lobby_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
    IF p_lobby_id IS NULL THEN RETURN; END IF;
    UPDATE public.lobby l
       SET rated_match_count = (
            SELECT count(*) FROM public.lobby_match m
             WHERE m.result <> 'practice'
               AND (m.lobby_id = p_lobby_id OR m.opponent_lobby_id = p_lobby_id))
     WHERE l.id = p_lobby_id;
END;
$$;


ALTER FUNCTION public.fn_lobby_recompute_rated_matches(p_lobby_id uuid) OWNER TO postgres;

--
-- Name: fn_lobby_recompute_stats(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_lobby_recompute_stats(p_lobby_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_sport      text;
    v_mmr        integer;
    v_count      integer;
    v_net        bigint[];
    v_active_net bigint[];
    v_ind        integer[];
BEGIN
    SELECT public.fn_sport_name(l.sport_id) INTO v_sport
    FROM public.lobby l WHERE l.id = p_lobby_id;

    SELECT count(*)::integer INTO v_count
    FROM public.lobby_member WHERE lobby_id = p_lobby_id;

    WITH member_elo AS (
        SELECT COALESCE(MAX(ur.elo), 1000) AS elo
        FROM public.lobby_member lm
        LEFT JOIN public.user_rating ur
            ON ur.user_id = lm.user_id AND ur.sport = v_sport
        WHERE lm.lobby_id = p_lobby_id
        GROUP BY lm.user_id
    ),
    top_n AS (SELECT elo FROM member_elo ORDER BY elo DESC LIMIT 5)
    SELECT COALESCE(ROUND(AVG(elo))::integer, 1000) INTO v_mmr FROM top_n;

    SELECT COALESCE(array_agg(DISTINCT un.network_id), '{}')
    INTO v_net
    FROM public.lobby_member lm
    JOIN public.user_network un ON un.user_id = lm.user_id
    WHERE lm.lobby_id = p_lobby_id;

    SELECT COALESCE(array_agg(DISTINCT un.network_id), '{}')
    INTO v_active_net
    FROM public.lobby_member lm
    JOIN public.user_network un ON un.user_id = lm.user_id
    WHERE lm.lobby_id = p_lobby_id AND NOT un.alumni;

    SELECT COALESCE(array_agg(DISTINCT ui.industry_id), '{}')
    INTO v_ind
    FROM public.lobby_member lm
    JOIN public.user_industry ui ON ui.user_id = lm.user_id
    WHERE lm.lobby_id = p_lobby_id;

    UPDATE public.lobby
       SET mmr                = v_mmr,
           member_count       = v_count,
           network_ids        = v_net,
           active_network_ids = v_active_net,
           industry_ids       = v_ind
     WHERE id = p_lobby_id;
END;
$$;


ALTER FUNCTION public.fn_lobby_recompute_stats(p_lobby_id uuid) OWNER TO postgres;

--
-- Name: fn_mark_all_notifications_read(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_mark_all_notifications_read() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    update public.notification_outbox
        set read_at = now()
        where recipient_user_id = auth.uid() and read_at is null;
end;
$$;


ALTER FUNCTION public.fn_mark_all_notifications_read() OWNER TO postgres;

--
-- Name: fn_mark_notification_read(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_mark_notification_read(p_id bigint) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    update public.notification_outbox
        set read_at = now()
        where id = p_id and recipient_user_id = auth.uid() and read_at is null;
end;
$$;


ALTER FUNCTION public.fn_mark_notification_read(p_id bigint) OWNER TO postgres;

--
-- Name: fn_notification_presentation(public.notification_kind, jsonb, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_notification_presentation(p_kind public.notification_kind, p_data jsonb, p_body text) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_lobby_id       uuid;
    v_activity_id    uuid;
    v_booking_id     uuid;
    v_challenge_id   uuid;
    v_record_id      uuid;
    v_request_id     uuid;
    v_feed_item_id   uuid;
    v_user_id        uuid;
    v_lobby_name     text;
    v_username       text;
    v_location_name  text;
    v_address        text;
    v_amount         text;
    v_start_time     timestamptz;
    v_weekday        text;
    v_time           text;
begin
    v_lobby_id     := nullif(p_data->>'lobby_id', '')::uuid;
    v_activity_id  := nullif(coalesce(p_data->>'activity_id',
                                      case when p_kind = 'activity_confirmed'
                                           then p_data->>'target_id' end), '')::uuid;
    v_booking_id   := nullif(coalesce(p_data->>'booking_id',
                                      case when p_kind = 'pro_session_reminder'
                                           then p_data->>'target_id' end), '')::uuid;
    v_challenge_id := nullif(p_data->>'challenge_id', '')::uuid;
    v_record_id    := nullif(p_data->>'record_id', '')::uuid;
    v_request_id   := nullif(p_data->>'request_id', '')::uuid;
    v_feed_item_id := nullif(p_data->>'feed_item_id', '')::uuid;
    v_user_id      := nullif(p_data->>'user_id', '')::uuid;

    -- Challenge copy names the other lobby, while lobby_id routes into the
    -- recipient's own lobby. Resolve that perspective once, at enqueue time.
    if p_kind in ('challenger_confirmed', 'challenge_received',
                  'challenge_declined', 'challenge_scheduled',
                  'challenge_lapsed', 'match_result_recorded')
       and v_challenge_id is not null then
        select case when c.initiator_lobby_id = v_lobby_id then target.name
                    else initiator.name end,
               c.proposed_time,
               loc.name,
               loc.full_address,
               case when c.agreed_cost is null then null
                    else c.agreed_cost::text || 'đ' end
          into v_lobby_name, v_start_time, v_location_name, v_address, v_amount
          from public.lobby_challenge c
          join public.lobby initiator on initiator.id = c.initiator_lobby_id
          join public.lobby target on target.id = c.target_lobby_id
          left join public.location loc on loc.id = c.proposed_location
         where c.id = v_challenge_id;
    elsif v_lobby_id is not null then
        select l.name into v_lobby_name
          from public.lobby l where l.id = v_lobby_id;
    end if;

    if v_activity_id is not null then
        select coalesce(v_start_time, a.start_time),
               coalesce(v_location_name, loc.name, fa.venue_name),
               coalesce(v_address, loc.full_address, fa.street_address),
               coalesce(v_lobby_name, l.name)
          into v_start_time, v_location_name, v_address, v_lobby_name
          from public.activity a
          left join public.lobby l on l.id = a.lobby_id
          left join public.location loc on loc.id = a.location_id
          left join public.freeplay_activity fa on fa.activity_id = a.id
         where a.id = v_activity_id;
    end if;

    if v_booking_id is not null then
        select b.booking_time_start,
               loc.name,
               loc.full_address,
               case when b.agreed_rate is null then null
                    else b.agreed_rate::text || 'đ' end
          into v_start_time, v_location_name, v_address, v_amount
          from public.referee_booking b
          left join public.location loc on loc.id = b.location_id
         where b.id = v_booking_id;
    end if;

    if p_kind = 'lobby_invite' and v_record_id is not null then
        select r.initiator_user_id, coalesce(v_lobby_id, r.target_lobby_id)
          into v_user_id, v_lobby_id
          from public.lobby_befriend_record r where r.id = v_record_id;
        if v_lobby_name is null then
            select l.name into v_lobby_name
              from public.lobby l where l.id = v_lobby_id;
        end if;
    end if;

    if v_request_id is not null then
        select coalesce(v_user_id, r.user_id), coalesce(v_activity_id, r.activity_id),
               case when r.price_amount is null then null
                    else r.price_amount::text || 'đ' end
          into v_user_id, v_activity_id, v_amount
          from public.freeplay_request r where r.id = v_request_id;
    end if;

    -- A freeplay request is itself what supplies activity_id, so resolve its
    -- venue only after loading the request above.
    if v_request_id is not null and v_activity_id is not null then
        select coalesce(v_start_time, a.start_time),
               coalesce(v_location_name, loc.name, fa.venue_name),
               coalesce(v_address, loc.full_address, fa.street_address)
          into v_start_time, v_location_name, v_address
          from public.activity a
          left join public.location loc on loc.id = a.location_id
          left join public.freeplay_activity fa on fa.activity_id = a.id
         where a.id = v_activity_id;
    end if;

    if v_user_id is not null then
        select u.username || '#' || u.tag_number into v_username
          from public."user" u where u.id = v_user_id;
    end if;

    if v_feed_item_id is not null and v_amount is null then
        select case when f.payload->>'per_person_amount' is null then null
                    else (f.payload->>'per_person_amount') || 'đ' end,
               coalesce(v_lobby_name, l.name)
          into v_amount, v_lobby_name
          from public.lobby_feed_item f
          left join public.lobby l on l.id = f.lobby_id
         where f.id = v_feed_item_id;
    end if;

    if v_start_time is not null then
        v_time := to_char(
            v_start_time at time zone 'Asia/Ho_Chi_Minh',
            'HH24:MI'
        );
        v_weekday := case extract(isodow from v_start_time at time zone 'Asia/Ho_Chi_Minh')
            when 1 then 'thứ Hai'
            when 2 then 'thứ Ba'
            when 3 then 'thứ Tư'
            when 4 then 'thứ Năm'
            when 5 then 'thứ Sáu'
            when 6 then 'thứ Bảy'
            when 7 then 'Chủ Nhật'
        end;
    end if;

    -- Only retain values literally present in the body. This prevents title-
    -- only metadata and generic routing context from being treated as body
    -- emphasis, while preserving an exact, non-regex client contract.
    return jsonb_strip_nulls(jsonb_build_object(
        'lobby_name',    case when strpos(p_body, v_lobby_name) > 0 then v_lobby_name end,
        'username',      case when strpos(p_body, v_username) > 0 then v_username end,
        'weekday',       case when strpos(p_body, v_weekday) > 0 then v_weekday end,
        'time',          case when strpos(p_body, v_time) > 0 then v_time end,
        'amount',        case when strpos(p_body, v_amount) > 0 then v_amount end,
        'location_name', case when strpos(p_body, v_location_name) > 0 then v_location_name end,
        'address',       case when strpos(p_body, v_address) > 0 then v_address end
    ));
exception
    when invalid_text_representation then
        -- Malformed optional routing metadata must never prevent the push.
        return '{}'::jsonb;
end;
$$;


ALTER FUNCTION public.fn_notification_presentation(p_kind public.notification_kind, p_data jsonb, p_body text) OWNER TO postgres;

--
-- Name: fn_notify_lobby_invite(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_notify_lobby_invite() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_inviter_name text;
    v_lobby_name   text;
BEGIN
    IF NEW.interaction_type != 'invite' OR NEW.target_user_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT u.username INTO v_inviter_name
    FROM public."user" u WHERE u.id = NEW.initiator_user_id;

    IF NEW.target_lobby_id IS NOT NULL THEN
        SELECT l.name INTO v_lobby_name
        FROM public.lobby l WHERE l.id = NEW.target_lobby_id;
    END IF;

    PERFORM public.fn_enqueue_notification(
        'lobby_invite',
        ARRAY[NEW.target_user_id],
        COALESCE(v_inviter_name, 'Ai đó') || ' mời bạn vào lobby',
        COALESCE(v_lobby_name, 'một lobby'),
        jsonb_build_object(
            'lobby_id', NEW.target_lobby_id,
            'record_id', NEW.id
        )
    );

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_notify_lobby_invite() OWNER TO postgres;

--
-- Name: fn_notify_new_message(uuid, uuid, public.notification_kind, uuid, text, text, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_notify_new_message(p_conversation_id uuid, p_message_id uuid, p_kind public.notification_kind, p_sender uuid, p_title text, p_body text, p_data jsonb) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_recipients uuid[]; v_quiet_period constant interval := interval '4 hours';
BEGIN
  SELECT array_agg(m.user_id) INTO v_recipients
  FROM public.conversation_member m
  WHERE m.conversation_id = p_conversation_id
    AND m.user_id <> p_sender
    AND m.left_at IS NULL
    AND (
      NOT EXISTS (
        SELECT 1 FROM public.message x
        WHERE x.conversation_id = p_conversation_id
          AND x.id <> p_message_id
          AND x.created_at > m.last_read_at
          AND x.created_at >= m.joined_at
          AND (m.left_at IS NULL OR x.created_at <= m.left_at)
      )
      OR NOT EXISTS (
        SELECT 1 FROM public.notification_outbox o
        WHERE o.recipient_user_id = m.user_id
          AND o.data->>'conversation_id' = p_conversation_id::text
          AND o.created_at > now() - v_quiet_period
      )
    );

  IF v_recipients IS NOT NULL THEN
    PERFORM public.fn_enqueue_notification(p_kind, v_recipients, p_title, p_body,
      coalesce(p_data,'{}'::jsonb) || jsonb_build_object('conversation_id', p_conversation_id));
  END IF;
END
$$;


ALTER FUNCTION public.fn_notify_new_message(p_conversation_id uuid, p_message_id uuid, p_kind public.notification_kind, p_sender uuid, p_title text, p_body text, p_data jsonb) OWNER TO postgres;

--
-- Name: fn_notify_referee_booking_created(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_notify_referee_booking_created() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_professional_user_id uuid;
    v_client_name text;
BEGIN
    SELECT linked_user_id INTO v_professional_user_id
    FROM public.professional
    WHERE id = NEW.professional_id;

    IF v_professional_user_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT u.username INTO v_client_name
    FROM public."user" u WHERE u.id = NEW.client_user_id;

    PERFORM public.fn_enqueue_notification(
        'professional_booking_requested',
        ARRAY[v_professional_user_id],
        COALESCE(v_client_name, 'Một học viên') || ' vừa gửi yêu cầu đặt lịch',
        'Chạm để xem chi tiết và xác nhận',
        jsonb_build_object('booking_id', NEW.id)
    );

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_notify_referee_booking_created() OWNER TO postgres;

--
-- Name: fn_notify_referee_booking_status_changed(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_notify_referee_booking_status_changed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_professional_name text;
BEGIN
    SELECT display_name INTO v_professional_name
    FROM public.professional WHERE id = NEW.professional_id;

    IF NEW.status = 'confirmed' THEN
        PERFORM public.fn_enqueue_notification(
            'professional_booking_confirmed',
            ARRAY[NEW.client_user_id],
            COALESCE(v_professional_name, 'Chuyên gia') || ' đã xác nhận lịch hẹn',
            'Buổi tập của bạn đã được xác nhận',
            jsonb_build_object('booking_id', NEW.id)
        );
    ELSIF NEW.status = 'rejected' THEN
        PERFORM public.fn_enqueue_notification(
            'professional_booking_rejected',
            ARRAY[NEW.client_user_id],
            COALESCE(v_professional_name, 'Chuyên gia') || ' đã từ chối yêu cầu đặt lịch',
            COALESCE(NEW.professional_notes, 'Bạn có thể thử đặt một khung giờ khác'),
            jsonb_build_object('booking_id', NEW.id)
        );
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_notify_referee_booking_status_changed() OWNER TO postgres;

--
-- Name: fn_outbox_poke(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_outbox_poke() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    perform public.fn_invoke_send_push();
    return null;
end;
$$;


ALTER FUNCTION public.fn_outbox_poke() OWNER TO postgres;

--
-- Name: fn_playtime_to_dict(jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_playtime_to_dict(p_playtime jsonb) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $$
    SELECT COALESCE(jsonb_object_agg(base_day, chunks), '{}'::jsonb)
    FROM (
        SELECT
            base_day,
            jsonb_agg(DISTINCT chunk) AS chunks
        FROM (
            SELECT
                elem->>'dayChunk' AS chunk,
                unnest(CASE elem->>'dayOfWeek'
                           WHEN 'all' THEN ARRAY['mon','tue','wed','thu','fri','sat','sun']
                           WHEN 'mwf' THEN ARRAY['mon','wed','fri']
                           WHEN 'tts' THEN ARRAY['tue','thu','sat']
                           WHEN 'wkn' THEN ARRAY['sat','sun']
                           ELSE ARRAY[elem->>'dayOfWeek']
                       END) AS base_day
            FROM jsonb_array_elements(
                     CASE WHEN jsonb_typeof(COALESCE(p_playtime, '[]'::jsonb)) = 'array'
                          THEN p_playtime ELSE '[]'::jsonb END
                 ) AS elem
            WHERE elem->>'dayChunk' IS NOT NULL AND elem->>'dayOfWeek' IS NOT NULL
        ) expanded
        GROUP BY base_day
    ) grouped;
$$;


ALTER FUNCTION public.fn_playtime_to_dict(p_playtime jsonb) OWNER TO postgres;

--
-- Name: fn_poke_wall_gc(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_poke_wall_gc() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_url text;
    v_key text;
begin
    if not exists (select 1 from public.wall_post_gc limit 1) then
        return;
    end if;

    select decrypted_secret into v_url
        from vault.decrypted_secrets where name = 'edge_wall_gc_url';
    select decrypted_secret into v_key
        from vault.decrypted_secrets where name = 'edge_service_role_key';

    if v_url is null or v_key is null then
        return;
    end if;

    perform net.http_post(
        url := v_url,
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || v_key
        ),
        body := '{}'::jsonb
    );
end;
$$;


ALTER FUNCTION public.fn_poke_wall_gc() OWNER TO postgres;

--
-- Name: fn_process_reminders(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_process_reminders() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT b.id, b.booking_time_start, b.client_user_id
      FROM public.referee_booking b
      WHERE b.reminder_sent_at IS NULL
        AND b.status = 'confirmed'
        AND b.booking_time_start > now()
        AND b.booking_time_start <= now() + interval '1 hour'
      FOR UPDATE SKIP LOCKED
  LOOP
    PERFORM public.fn_enqueue_notification(
      'pro_session_reminder',
      (SELECT array_agg(uid) FROM (
          SELECT r.client_user_id AS uid
          UNION
          SELECT au.user_id FROM public.referee_booking_additional_users au
          WHERE au.booking_id = r.id
       ) s),
      'Sắp tới giờ trận đấu',
      'Trận đấu bắt đầu lúc '
        || to_char(r.booking_time_start AT TIME ZONE 'Asia/Ho_Chi_Minh', 'HH24:MI'),
      jsonb_build_object('target_id', r.id::text)
    );
    UPDATE public.referee_booking SET reminder_sent_at = now() WHERE id = r.id;
  END LOOP;

  FOR r IN
    SELECT a.id, a.start_time, a.course_id
      FROM public.activity a
      WHERE a.course_id IS NOT NULL
        AND a.proposal_status = 'approved'
        AND a.start_time > now()
        AND a.start_time <= now() + interval '1 hour'
        AND NOT EXISTS (SELECT 1 FROM public.activity_reminder_sent s
                        WHERE s.activity_id = a.id)
      FOR UPDATE SKIP LOCKED
  LOOP
    PERFORM public.fn_enqueue_notification(
      'pro_session_reminder',
      (SELECT array_agg(ac.user_id) FROM public.activity_confirmation ac
       WHERE ac.activity_id = r.id AND ac.attendance = 'going'),
      'Sắp tới giờ tập với coach',
      'Buổi tập của bạn bắt đầu lúc '
        || to_char(r.start_time AT TIME ZONE 'Asia/Ho_Chi_Minh', 'HH24:MI'),
      jsonb_build_object('course_id', r.course_id::text, 'activity_id', r.id::text)
    );
    INSERT INTO public.activity_reminder_sent(activity_id) VALUES (r.id)
    ON CONFLICT (activity_id) DO NOTHING;
  END LOOP;
END;
$$;


ALTER FUNCTION public.fn_process_reminders() OWNER TO postgres;

--
-- Name: fn_referee_booking_role_check(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_referee_booking_role_check() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.professional p
    WHERE p.id = NEW.professional_id AND p.professional_role = 'referee'
  ) THEN
    RAISE EXCEPTION 'referee_booking.professional_id % must reference a referee', NEW.professional_id;
  END IF;
  RETURN NEW;
END
$$;


ALTER FUNCTION public.fn_referee_booking_role_check() OWNER TO postgres;

--
-- Name: fn_reject_pair_befriend(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_reject_pair_befriend() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
begin
    if new.interaction_type = 'pair' then
        raise exception
            'lobby_befriend_record.pair is retired — use send_friend_request()';
    end if;
    return new;
end;
$$;


ALTER FUNCTION public.fn_reject_pair_befriend() OWNER TO postgres;

--
-- Name: fn_seed_initial_elo(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_seed_initial_elo() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_sport     text;
  v_elo       int;
begin
  -- Only act on first-time elo_seed set (null → value)
  if NEW.elo_seed is null then
    return NEW;
  end if;
  if OLD is not null and OLD.elo_seed is not null then
    return NEW;  -- already seeded, don't touch Elo
  end if;

  -- Derive sport from table name: 'soccer_profile' → 'soccer'
  v_sport := replace(TG_TABLE_NAME, '_profile', '');

  -- Map seed to starting Elo (200 apart per tier)
  v_elo := case NEW.elo_seed
    when 'beginner' then  700
    when 'casual'   then  900
    when 'fair'     then 1100
    when 'good'     then 1300
    when 'advanced' then 1500
    else                 900
  end;

  -- Insert only if no rating exists yet for this user+sport
  if not exists (
    select 1 from public.user_rating
    where user_id = NEW.user_id
      and sport   = v_sport
  ) then
    insert into public.user_rating (user_id, sport, elo, games_played)
    values (NEW.user_id, v_sport, v_elo, 0);
  end if;

  return NEW;
end;
$$;


ALTER FUNCTION public.fn_seed_initial_elo() OWNER TO postgres;

--
-- Name: fn_sport_name(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_sport_name(p_sport_id bigint) RETURNS text
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $$
    SELECT CASE p_sport_id
               WHEN 1 THEN 'soccer'
               WHEN 2 THEN 'basketball'
               WHEN 3 THEN 'badminton'
               WHEN 4 THEN 'tennis'
               WHEN 5 THEN 'pickleball'
               ELSE NULL
           END;
$$;


ALTER FUNCTION public.fn_sport_name(p_sport_id bigint) OWNER TO postgres;

--
-- Name: fn_sweep_activity_payment_requests(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_sweep_activity_payment_requests() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    r record;
    v_payees uuid[];
    v_billable uuid[];
    v_payee_count int;
    v_per_person numeric(10, 2);
    v_feed_item_id uuid;
BEGIN
    FOR r IN
        SELECT a.id, a.lobby_id, a.user_id AS organizer_id,
               a.cost_type, a.cost_amount
          FROM public.activity a
         WHERE a.end_time IS NOT NULL
           AND a.end_time <= now() - interval '15 minutes'
           AND a.end_time >  now() - interval '1 day'
           AND a.cost_type IS NOT NULL
           AND a.lobby_id IS NOT NULL
           AND (
                (a.challenge_id IS NULL
                 AND public.activity_is_confirmed(a.id))
                OR
                (a.challenge_id IS NOT NULL
                 AND a.manager_confirmed_at IS NOT NULL)
           )
           AND NOT EXISTS (
               SELECT 1 FROM public.lobby_feed_item fi
                WHERE fi.kind = 'payment_request'
                  AND fi.payload->>'type' = 'split'
                  AND fi.payload->>'source_activity_id' = a.id::text
           )
    LOOP
        SELECT array_agg(ac.user_id) INTO v_payees
          FROM public.activity_confirmation ac
         WHERE ac.activity_id = r.id AND ac.attendance = 'going';

        v_payee_count := COALESCE(array_length(v_payees, 1), 0);
        IF v_payee_count = 0 THEN
            CONTINUE;
        END IF;

        v_per_person := CASE r.cost_type
            WHEN 'per_pax' THEN r.cost_amount
            ELSE CEIL(r.cost_amount / v_payee_count / 1000) * 1000
        END;

        v_billable := ARRAY(
            SELECT u FROM unnest(v_payees) AS u WHERE u <> r.organizer_id
        );
        IF COALESCE(array_length(v_billable, 1), 0) = 0 THEN
            CONTINUE;
        END IF;

        INSERT INTO public.lobby_feed_item
            (lobby_id, author_id, kind, activity_id, payload)
        VALUES (
            r.lobby_id, r.organizer_id, 'payment_request', r.id,
            jsonb_build_object(
                'type',               'split',
                'source_activity_id', r.id,
                'recipient_id',       r.organizer_id,
                'cost_type',          r.cost_type,
                'total_amount',       r.cost_amount,
                'per_person_amount',  v_per_person
            )
        )
        RETURNING id INTO v_feed_item_id;

        INSERT INTO public.lobby_payment_request_payee
            (feed_item_id, user_id, amount_owed)
        SELECT v_feed_item_id, u, v_per_person FROM unnest(v_billable) AS u;

        PERFORM public.fn_enqueue_notification(
            'payment_requested',
            v_billable,
            'Chia tiền buổi chơi',
            'Mỗi người đóng ' || v_per_person::text || 'đ',
            jsonb_build_object(
                'lobby_id', r.lobby_id,
                'feed_item_id', v_feed_item_id,
                'activity_id', r.id
            )
        );
    END LOOP;
END;
$$;


ALTER FUNCTION public.fn_sweep_activity_payment_requests() OWNER TO postgres;

--
-- Name: fn_sweep_activity_thresholds(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_sweep_activity_thresholds() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    r            record;
    v_lobby_name text;
    v_recipients uuid[];
BEGIN
    -- (a) Deadline passed, still under threshold, not yet notified, and not
    -- ALSO already past kickoff (that case is handled by pass (b) below —
    -- no point prompting for an activity that's being auto-cancelled in the
    -- same tick, e.g. after the cron job missed a beat).
    FOR r IN
        SELECT a.id, a.user_id AS organizer_id, a.lobby_id
          FROM public.activity a
         WHERE a.lobby_id IS NOT NULL
           AND a.challenge_id IS NULL
           AND a.confirmation_threshold IS NOT NULL
           AND a.confirmation_deadline IS NOT NULL
           AND a.confirmation_deadline <= now()
           AND a.start_time > now()
           AND a.at_risk_notified_at IS NULL
           AND NOT public.activity_is_confirmed(a.id)
    LOOP
        UPDATE public.activity SET at_risk_notified_at = now() WHERE id = r.id;

        SELECT l.name INTO v_lobby_name FROM public.lobby l WHERE l.id = r.lobby_id;

        PERFORM public.fn_enqueue_notification(
            'activity_at_risk_organizer',
            ARRAY[r.organizer_id],
            'Buổi chơi chưa đủ người',
            COALESCE(v_lobby_name, 'Lobby') || ' chưa đủ xác nhận trước hạn chót — xác nhận hoặc hủy',
            jsonb_build_object('target_id', r.id::text, 'lobby_id', r.lobby_id::text));

        -- "maybe" holders and never-responded members (no row at all) — NOT
        -- "out" (already decided), NOT "going" (nothing for them to do), and
        -- NOT the organizer (they already got their own organizer-tier
        -- notification above — as a lobby member who never RSVP'd on their
        -- own activity they'd otherwise also match "never-responded" here).
        SELECT array_agg(DISTINCT lm.user_id) INTO v_recipients
            FROM public.lobby_member lm
            LEFT JOIN public.activity_confirmation ac
                   ON ac.activity_id = r.id AND ac.user_id = lm.user_id
            WHERE lm.lobby_id = r.lobby_id
              AND lm.user_id <> r.organizer_id
              AND (ac.attendance IS NULL OR ac.attendance = 'maybe');

        IF v_recipients IS NOT NULL THEN
            PERFORM public.fn_enqueue_notification(
                'activity_at_risk_member',
                v_recipients,
                'Xác nhận tham gia?',
                COALESCE(v_lobby_name, 'Lobby') || ' cần thêm người xác nhận trước giờ chơi',
                jsonb_build_object('target_id', r.id::text, 'lobby_id', r.lobby_id::text));
        END IF;
    END LOOP;

    -- (b) Kickoff passed, still unconfirmed — covers both an activity with
    -- no deadline at all, and an at-risk activity nobody resolved in time.
    -- Hard-delete (no activity/match record persists), but leave a feed
    -- item + push explaining why.
    FOR r IN
        SELECT a.id, a.user_id AS organizer_id, a.lobby_id
          FROM public.activity a
         WHERE a.lobby_id IS NOT NULL
           AND a.challenge_id IS NULL
           AND a.confirmation_threshold IS NOT NULL
           AND a.start_time <= now()
           AND NOT public.activity_is_confirmed(a.id)
    LOOP
        SELECT l.name INTO v_lobby_name FROM public.lobby l WHERE l.id = r.lobby_id;

        SELECT array_agg(DISTINCT u) INTO v_recipients
            FROM unnest(
                ARRAY[r.organizer_id] || COALESCE((
                    SELECT array_agg(ac.user_id)
                    FROM public.activity_confirmation ac
                    WHERE ac.activity_id = r.id AND ac.attendance = 'going'
                ), ARRAY[]::uuid[])
            ) AS u;

        DELETE FROM public.activity WHERE id = r.id;

        INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
        VALUES (r.lobby_id, r.organizer_id, 'update',
            jsonb_build_object(
                'title', 'Đã hủy buổi chơi',
                'kind',  'cancelled',
                'tone',  'crimson',
                'fields', jsonb_build_array(
                    jsonb_build_array('Lý do', 'Không đủ người xác nhận trước giờ chơi'))));

        PERFORM public.fn_enqueue_notification(
            'activity_cancelled_low_turnout',
            v_recipients,
            'Buổi chơi đã bị hủy',
            COALESCE(v_lobby_name, 'Lobby') || ' đã tự động hủy do không đủ người xác nhận',
            jsonb_build_object('lobby_id', r.lobby_id::text));
    END LOOP;
END;
$$;


ALTER FUNCTION public.fn_sweep_activity_thresholds() OWNER TO postgres;

--
-- Name: fn_sweep_challenges(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_sweep_challenges() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    r record;
BEGIN
    UPDATE public.lobby
       SET open_to_challengers    = false,
           challenge_offer_time     = NULL,
           challenge_offer_location = NULL,
           challenge_offer_cost     = NULL
     WHERE open_to_challengers AND challenge_offer_time <= now();

    FOR r IN
        SELECT c.id, c.initiator_lobby_id, c.target_lobby_id
          FROM public.lobby_challenge c
         WHERE c.status = 'accepted'
           AND EXISTS (
               SELECT 1 FROM public.activity a
                WHERE a.challenge_id = c.id
                  AND a.confirmation_deadline IS NOT NULL
                  AND a.confirmation_deadline <= now()
                  AND a.manager_confirmed_at IS NULL)
    LOOP
        DELETE FROM public.activity WHERE challenge_id = r.id;
        UPDATE public.lobby_challenge
           SET status = 'lapsed', updated_at = now() WHERE id = r.id;

        PERFORM public.fn_enqueue_notification(
            'challenge_lapsed',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = r.initiator_lobby_id),
            'Trận thách đấu bị huỷ',
            'Không đủ xác nhận trước hạn chót nên trận đấu đã bị huỷ',
            jsonb_build_object('lobby_id', r.initiator_lobby_id, 'challenge_id', r.id));
        PERFORM public.fn_enqueue_notification(
            'challenge_lapsed',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = r.target_lobby_id),
            'Trận thách đấu bị huỷ',
            'Không đủ xác nhận trước hạn chót nên trận đấu đã bị huỷ',
            jsonb_build_object('lobby_id', r.target_lobby_id, 'challenge_id', r.id));

        INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
        SELECT l.id, l.captain_id, 'update',
               jsonb_build_object(
                   'title', 'Trận thách đấu bị huỷ',
                   'kind',  'cancelled',
                   'tone',  'crimson',
                   'fields', jsonb_build_array(
                       jsonb_build_array('Lý do', 'Không đủ xác nhận trước hạn chót')))
          FROM public.lobby l
         WHERE l.id IN (r.initiator_lobby_id, r.target_lobby_id);
    END LOOP;

    FOR r IN
        SELECT c.id, c.target_lobby_id AS home, c.initiator_lobby_id AS away,
               a.id AS activity_id, a.start_time, a.location_id
          FROM public.lobby_challenge c
          JOIN public.activity a
            ON a.challenge_id = c.id AND a.lobby_id = c.target_lobby_id
         WHERE c.status IN ('accepted', 'scheduled')
           AND COALESCE(a.end_time, a.start_time) <= now()
           AND NOT EXISTS (SELECT 1 FROM public.lobby_match m WHERE m.activity_id = a.id)
    LOOP
        INSERT INTO public.lobby_match
            (lobby_id, activity_id, opponent_lobby_id, opponent_tag, result,
             venue_label, played_at)
        VALUES (r.home, r.activity_id, r.away,
                COALESCE((SELECT name FROM public.lobby WHERE id = r.away), '—'),
                'practice',
                COALESCE((SELECT name FROM public.location WHERE id = r.location_id), '—'),
                r.start_time);

        UPDATE public.lobby_challenge
           SET status = 'played', updated_at = now() WHERE id = r.id;

        PERFORM public.fn_enqueue_notification(
            'match_result_recorded',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = r.home),
            'Trận đấu đã diễn ra',
            'Không có trọng tài nên trận đấu được ghi nhận nhưng không tính điểm',
            jsonb_build_object('lobby_id', r.home, 'challenge_id', r.id));
        PERFORM public.fn_enqueue_notification(
            'match_result_recorded',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = r.away),
            'Trận đấu đã diễn ra',
            'Không có trọng tài nên trận đấu được ghi nhận nhưng không tính điểm',
            jsonb_build_object('lobby_id', r.away, 'challenge_id', r.id));
    END LOOP;
END;
$$;


ALTER FUNCTION public.fn_sweep_challenges() OWNER TO postgres;

--
-- Name: fn_sweep_course_targets(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_sweep_course_targets() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE r record; v_coach uuid;
BEGIN
  FOR r IN
    SELECT c.id, c.professional_id, c.target_session_count
    FROM public.course c
    WHERE c.status = 'active'
      AND c.target_session_count IS NOT NULL
      AND c.target_reached_at IS NULL
      AND public.fn_course_held_sessions(c.id) >= c.target_session_count
  LOOP
    UPDATE public.course SET target_reached_at = now() WHERE id = r.id;
    PERFORM public.fn_course_system_message(r.id, 'target_reached',
      jsonb_build_object('target', r.target_session_count));

    SELECT p.linked_user_id INTO v_coach FROM public.professional p
    WHERE p.id = r.professional_id;
    IF v_coach IS NOT NULL THEN
      PERFORM public.fn_enqueue_notification('course_ended', ARRAY[v_coach],
        'Khoá học đã đủ số buổi', 'Bạn có thể gia hạn hoặc kết thúc khoá học.',
        jsonb_build_object('course_id', r.id));
    END IF;
  END LOOP;
END
$$;


ALTER FUNCTION public.fn_sweep_course_targets() OWNER TO postgres;

--
-- Name: fn_sweep_expired_wall_posts(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_sweep_expired_wall_posts() RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_count int;
begin
    with expired as (
        delete from public.wall_post
        where expires_at <= now()
        returning media
    ), queued as (
        insert into public.wall_post_gc (bucket_id, path)
        select distinct g.bucket_id, g.path
        from expired e, public.fn_wall_post_media_gc_paths(e.media) g
        on conflict do nothing
        returning 1
    )
    select count(*) into v_count from queued;

    return v_count;
end;
$$;


ALTER FUNCTION public.fn_sweep_expired_wall_posts() OWNER TO postgres;

--
-- Name: fn_sweep_freeplay(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_sweep_freeplay() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
  UPDATE public.freeplay_request r SET status='lapsed',resolved_at=now(),updated_at=now()
  FROM public.activity a WHERE a.id=r.activity_id AND r.status='pending' AND a.end_time<=now();
END
$$;


ALTER FUNCTION public.fn_sweep_freeplay() OWNER TO postgres;

--
-- Name: fn_sweep_recurring_activities(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_sweep_recurring_activities() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    r           record;
    v_new_id    uuid;
    v_new_start timestamptz;
    v_new_end   timestamptz;
    v_wd        text;
    v_fields    jsonb;
BEGIN
    FOR r IN
        SELECT a.*
          FROM public.activity a
         WHERE a.series_id IS NOT NULL
           AND a.recurrence_day_of_week IS NOT NULL
           AND a.end_time IS NOT NULL
           AND a.end_time < now()
           AND now() >= (a.start_time + interval '7 days' - interval '4 days')
           AND a.start_time = (
               SELECT f.frontier_start FROM public.activity_series_frontier f
                WHERE f.series_id = a.series_id)
    LOOP
        v_new_start := r.start_time + interval '7 days';
        v_new_end   := r.end_time + interval '7 days';

        -- Per-occurrence, not template-level: coach_booking_id,
        -- referee_booking_id, challenge_id, manager_confirmed_at are
        -- deliberately NOT copied onto the new row.
        INSERT INTO public.activity (
            user_id, sport_id, lobby_id, start_time, end_time, location_id,
            confirmation_threshold, confirmation_deadline, recurrence_day_of_week,
            cost_type, cost_amount, series_id
        ) VALUES (
            r.user_id, r.sport_id, r.lobby_id, v_new_start, v_new_end, r.location_id,
            r.confirmation_threshold,
            CASE WHEN r.confirmation_deadline IS NULL THEN NULL
                 ELSE r.confirmation_deadline + interval '7 days' END,
            r.recurrence_day_of_week, r.cost_type, r.cost_amount, r.series_id
        )
        RETURNING id INTO v_new_id;

        -- Mirrors ScheduleActivityController.schedule()'s feed item shape
        -- (lib/manage_tab/lobby_section/schedule_activity_controller.dart)
        -- so an auto-spawned occurrence reads identically to a manually
        -- scheduled one. The activity_scheduled_emit trigger on `activity`
        -- (schema/activity_scheduled_notify.sql) already fires on this
        -- INSERT regardless of source, so no notification call is needed
        -- here — same push + feed item as manual scheduling, by design.
        v_wd := (ARRAY['T2','T3','T4','T5','T6','T7','CN'])[
            EXTRACT(ISODOW FROM v_new_start AT TIME ZONE 'Asia/Ho_Chi_Minh')::int];

        v_fields := jsonb_build_array(
            jsonb_build_array('Ngày', v_wd || ', ' ||
                to_char(v_new_start AT TIME ZONE 'Asia/Ho_Chi_Minh', 'FMDD/FMMM/YYYY')),
            jsonb_build_array('Giờ',
                to_char(v_new_start AT TIME ZONE 'Asia/Ho_Chi_Minh', 'HH24:MI') || ' - ' ||
                to_char(v_new_end AT TIME ZONE 'Asia/Ho_Chi_Minh', 'HH24:MI')),
            jsonb_build_array('Lặp lại', 'Hằng tuần')
        );
        IF r.cost_type IS NOT NULL AND r.cost_amount IS NOT NULL THEN
            v_fields := v_fields || jsonb_build_array(jsonb_build_array('Chi phí',
                to_char(r.cost_amount, 'FM999999999990') ||
                CASE WHEN r.cost_type = 'per_pax' THEN ' đ/người' ELSE ' đ (tổng)' END));
        END IF;

        INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
        VALUES (
            r.lobby_id, r.user_id, 'update',
            jsonb_build_object(
                'title', 'Lên lịch buổi chơi',
                'kind',  'scheduled',
                'tone',  'blue',
                'fields', v_fields
            )
        );
    END LOOP;
END;
$$;


ALTER FUNCTION public.fn_sweep_recurring_activities() OWNER TO postgres;

--
-- Name: FUNCTION fn_sweep_recurring_activities(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_sweep_recurring_activities() IS 'Materialises the next occurrence of each recurring series. Per-occurrence fields (referee_booking_id, challenge_id, manager_confirmed_at, proposal_status) are deliberately not carried over from the template.';


--
-- Name: fn_touch_user_contact(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_touch_user_contact() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
begin
    new.updated_at := now();
    return new;
end
$$;


ALTER FUNCTION public.fn_touch_user_contact() OWNER TO postgres;

--
-- Name: fn_valid_wall_post_media(jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_valid_wall_post_media(p_media jsonb) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $$
    select
        jsonb_typeof(p_media) = 'array'
        and jsonb_array_length(p_media) between 1 and 4
        and not exists (
            select 1 from jsonb_array_elements(p_media) elem
            where (elem->>'type') not in ('image', 'video')
               or coalesce(elem->>'path', '') = ''
               or (
                    (elem->>'type') = 'video'
                    and coalesce((elem->>'duration_ms')::numeric, 0) > 60000
                  )
        );
$$;


ALTER FUNCTION public.fn_valid_wall_post_media(p_media jsonb) OWNER TO postgres;

--
-- Name: fn_validate_activity_feed_item_scope(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_validate_activity_feed_item_scope() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
    IF NEW.activity_id IS NOT NULL AND NOT EXISTS (
        SELECT 1
          FROM public.activity a
         WHERE a.id = NEW.activity_id
           AND a.lobby_id = NEW.lobby_id
    ) THEN
        RAISE EXCEPTION 'activity does not belong to lobby'
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_validate_activity_feed_item_scope() OWNER TO postgres;

--
-- Name: fn_wall_cron_tick(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_wall_cron_tick() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    perform public.fn_sweep_expired_wall_posts();
    perform public.fn_poke_wall_gc();
end;
$$;


ALTER FUNCTION public.fn_wall_cron_tick() OWNER TO postgres;

--
-- Name: fn_wall_post_autohide(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_wall_post_autohide() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


ALTER FUNCTION public.fn_wall_post_autohide() OWNER TO postgres;

--
-- Name: fn_wall_post_media_gc_paths(jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_wall_post_media_gc_paths(p_media jsonb) RETURNS TABLE(bucket_id text, path text)
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $$
    select case when elem->>'type' = 'video' then 'wall_post_video'
                else 'wall_post' end,
           elem->>'path'
    from jsonb_array_elements(p_media) elem
    union all
    select 'wall_post', elem->>'thumbnail_path'
    from jsonb_array_elements(p_media) elem
    where elem->>'type' = 'video' and coalesce(elem->>'thumbnail_path', '') <> '';
$$;


ALTER FUNCTION public.fn_wall_post_media_gc_paths(p_media jsonb) OWNER TO postgres;

--
-- Name: fn_wall_post_tag_guard(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_wall_post_tag_guard() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_activity uuid;
    v_lobby    uuid;
    v_count    int;
BEGIN
    SELECT activity_id, lobby_id INTO v_activity, v_lobby
      FROM public.wall_post WHERE id = new.post_id;

    SELECT count(*) INTO v_count
      FROM public.wall_post_tag WHERE post_id = new.post_id;
    IF v_count >= 5 THEN
        RAISE EXCEPTION 'a post can tag at most 5 people';
    END IF;

    IF v_activity IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM public.activity_confirmation c
                WHERE c.activity_id = v_activity AND c.user_id = new.user_id
            UNION ALL
            SELECT 1 FROM public.lobby_member m
                WHERE m.lobby_id = v_lobby AND m.user_id = new.user_id
            UNION ALL
            SELECT 1 FROM public.activity a
                JOIN public.course_member cm ON cm.course_id = a.course_id
                WHERE a.id = v_activity AND cm.user_id = new.user_id AND cm.left_at IS NULL
            UNION ALL
            SELECT 1 FROM public.activity a
                JOIN public.course c ON c.id = a.course_id
                JOIN public.professional p ON p.id = c.professional_id
                WHERE a.id = v_activity AND p.linked_user_id = new.user_id
        ) THEN
            RAISE EXCEPTION 'can only tag attendees, lobby members or course members';
        END IF;
    END IF;

    RETURN new;
END;
$$;


ALTER FUNCTION public.fn_wall_post_tag_guard() OWNER TO postgres;

--
-- Name: freeplay_activity_detail_data(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.freeplay_activity_detail_data(p_activity_id uuid) RETURNS TABLE(activity_id uuid, host_id uuid, host_name text, host_avatar_url text, description text, start_time timestamp with time zone, end_time timestamp with time zone, location_id uuid, venue_name text, street_address text, location_street_number text, location_street_name text, location_district text, location_city text, location_lat double precision, location_lon double precision, capacity integer, accepted_count bigint, male_price numeric, female_price numeric, recommended_skills text[], my_request_id uuid, my_request_status text, roster jsonb)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid:=auth.uid(); v_allowed boolean;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM public.activity a
    JOIN public.freeplay_activity fa ON fa.activity_id=a.id
    JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
    WHERE a.id=p_activity_id AND (
      h.status='active' OR h.user_id=v_uid OR EXISTS(
        SELECT 1 FROM public.freeplay_request r
        WHERE r.activity_id=a.id AND r.user_id=v_uid)))
  INTO v_allowed;
  IF NOT v_allowed THEN RETURN; END IF;

  RETURN QUERY
  SELECT a.id,h.id,h.display_name,h.avatar_url,fa.description,a.start_time,a.end_time,
    a.location_id, coalesce(loc.name,fa.venue_name),
    coalesce(
      nullif(btrim(loc.full_address), ''),
      nullif(concat_ws(', ', nullif(btrim(loc.street_number), ''),
        nullif(btrim(loc.street_name), ''), nullif(btrim(loc.district), ''),
        nullif(btrim(loc.city), '')), ''),
      fa.street_address
    ),
    loc.street_number,loc.street_name,loc.district,loc.city,loc.lat,loc.lon,
    fa.capacity,
    (SELECT count(*) FROM public.freeplay_request x
     WHERE x.activity_id=a.id AND x.status='accepted'),
    fa.male_price,fa.female_price,fa.recommended_skills,mr.id,mr.status::text,
    CASE WHEN h.user_id=v_uid OR mr.status='accepted' THEN
      (SELECT coalesce(jsonb_agg(jsonb_build_object(
        'id',u.id,'username',u.username,
        'generatedAvatar',u.details->>'generatedAvatar','skill',x.skill)
        ORDER BY u.username),'[]'::jsonb)
       FROM public.freeplay_request x JOIN public."user" u ON u.id=x.user_id
       WHERE x.activity_id=a.id AND x.status='accepted')
    ELSE '[]'::jsonb END
  FROM public.activity a
  JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  LEFT JOIN public.location loc ON loc.id=a.location_id
  LEFT JOIN LATERAL(
    SELECT r.id,r.status FROM public.freeplay_request r
    WHERE r.activity_id=a.id AND r.user_id=v_uid
    ORDER BY r.created_at DESC LIMIT 1
  ) mr ON true
  WHERE a.id=p_activity_id;
END
$$;


ALTER FUNCTION public.freeplay_activity_detail_data(p_activity_id uuid) OWNER TO postgres;

--
-- Name: freeplay_activity_requests(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.freeplay_activity_requests(p_activity_id uuid) RETURNS TABLE(request_id uuid, user_id uuid, username text, generated_avatar text, status text, gender text, skill text, price_amount numeric, created_at timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT r.id,r.user_id,u.username,u.details->>'generatedAvatar',r.status::text,r.gender,r.skill,r.price_amount,r.created_at
  FROM public.freeplay_request r JOIN public."user" u ON u.id=r.user_id
  JOIN public.activity a ON a.id=r.activity_id JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE r.activity_id=p_activity_id AND h.user_id=auth.uid() ORDER BY r.created_at
$$;


ALTER FUNCTION public.freeplay_activity_requests(p_activity_id uuid) OWNER TO postgres;

--
-- Name: freeplay_chat_counterpart_data(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.freeplay_chat_counterpart_data(p_request_id uuid) RETURNS TABLE(counterpart_id uuid)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid:=auth.uid();
BEGIN
  RETURN QUERY
  SELECT CASE WHEN r.user_id=v_uid THEN h.user_id ELSE r.user_id END
  FROM public.freeplay_request r
  JOIN public.activity a ON a.id=r.activity_id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE r.id=p_request_id AND (r.user_id=v_uid OR h.user_id=v_uid);
END
$$;


ALTER FUNCTION public.freeplay_chat_counterpart_data(p_request_id uuid) OWNER TO postgres;

--
-- Name: freeplay_conversation_id(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.freeplay_conversation_id(p_request_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_id uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.freeplay_request r
    JOIN public.activity a ON a.id = r.activity_id
    JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
    WHERE r.id = p_request_id AND (r.user_id = v_uid OR h.user_id = v_uid)
  ) THEN RAISE EXCEPTION 'chat not found'; END IF;

  v_id := public.fn_ensure_freeplay_conversation(p_request_id);
  RETURN v_id;
END
$$;


ALTER FUNCTION public.freeplay_conversation_id(p_request_id uuid) OWNER TO postgres;

--
-- Name: freeplay_host_data(boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.freeplay_host_data(p_history boolean DEFAULT false) RETURNS TABLE(activity_id uuid, description text, start_time timestamp with time zone, end_time timestamp with time zone, venue_name text, capacity integer, accepted_count bigint, pending_count bigint, intake_closed boolean, cancelled boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT a.id,fa.description,a.start_time,a.end_time,coalesce(loc.name,fa.venue_name),fa.capacity,
    count(r.id) FILTER(WHERE r.status='accepted'),count(r.id) FILTER(WHERE r.status='pending'),
    fa.intake_closed_at IS NOT NULL,fa.cancelled_at IS NOT NULL
  FROM public.activity a JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id LEFT JOIN public.location loc ON loc.id=a.location_id
  LEFT JOIN public.freeplay_request r ON r.activity_id=a.id
  WHERE h.user_id=auth.uid() AND (p_history=(a.end_time<=now() OR fa.cancelled_at IS NOT NULL))
  GROUP BY a.id,fa.activity_id,loc.name ORDER BY a.start_time DESC
$$;


ALTER FUNCTION public.freeplay_host_data(p_history boolean) OWNER TO postgres;

--
-- Name: freeplay_host_management_data(boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.freeplay_host_management_data(p_history boolean DEFAULT false) RETURNS TABLE(activity_id uuid, host_id uuid, host_name text, host_avatar_url text, description text, start_time timestamp with time zone, end_time timestamp with time zone, location_id uuid, venue_name text, street_address text, location_street_number text, location_street_name text, location_district text, location_city text, location_lat double precision, location_lon double precision, capacity integer, accepted_count bigint, pending_count bigint, male_price numeric, female_price numeric, recommended_skills text[], intake_closed boolean, cancelled boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT a.id,h.id,h.display_name,h.avatar_url,fa.description,a.start_time,a.end_time,
    a.location_id,coalesce(loc.name,fa.venue_name),
    coalesce(
      nullif(btrim(loc.full_address), ''),
      nullif(concat_ws(', ', nullif(btrim(loc.street_number), ''),
        nullif(btrim(loc.street_name), ''), nullif(btrim(loc.district), ''),
        nullif(btrim(loc.city), '')), ''),
      fa.street_address
    ),
    loc.street_number,loc.street_name,loc.district,loc.city,loc.lat,loc.lon,
    fa.capacity,
    count(r.id) FILTER(WHERE r.status='accepted'),
    count(r.id) FILTER(WHERE r.status='pending'),
    fa.male_price,fa.female_price,fa.recommended_skills,
    fa.intake_closed_at IS NOT NULL,fa.cancelled_at IS NOT NULL
  FROM public.activity a
  JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  LEFT JOIN public.location loc ON loc.id=a.location_id
  LEFT JOIN public.freeplay_request r ON r.activity_id=a.id
  WHERE h.user_id=auth.uid()
    AND (p_history=(a.end_time<=now() OR fa.cancelled_at IS NOT NULL))
  GROUP BY a.id,fa.activity_id,h.id,loc.id
  ORDER BY CASE WHEN p_history THEN NULL ELSE a.start_time END,
    CASE WHEN p_history THEN a.end_time END DESC
$$;


ALTER FUNCTION public.freeplay_host_management_data(p_history boolean) OWNER TO postgres;

--
-- Name: freeplay_host_open_data(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.freeplay_host_open_data(p_host_id uuid) RETURNS TABLE(activity_id uuid, host_id uuid, host_name text, host_avatar_url text, description text, start_time timestamp with time zone, end_time timestamp with time zone, venue_name text, street_address text, capacity integer, accepted_count bigint, male_price numeric, female_price numeric, recommended_skills text[])
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT a.id,h.id,h.display_name,h.avatar_url,fa.description,a.start_time,a.end_time,
    coalesce(loc.name,fa.venue_name),coalesce(loc.full_address,fa.street_address),fa.capacity,
    (SELECT count(*) FROM public.freeplay_request r WHERE r.activity_id=a.id AND r.status='accepted'),
    fa.male_price,fa.female_price,fa.recommended_skills
  FROM public.activity a JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  LEFT JOIN public.location loc ON loc.id=a.location_id
  WHERE h.id=p_host_id AND h.status='active' AND a.end_time>now()
    AND fa.cancelled_at IS NULL AND fa.intake_closed_at IS NULL
    AND (SELECT count(*) FROM public.freeplay_request r WHERE r.activity_id=a.id AND r.status='accepted')<fa.capacity
  ORDER BY a.start_time,a.created_at
$$;


ALTER FUNCTION public.freeplay_host_open_data(p_host_id uuid) OWNER TO postgres;

--
-- Name: freeplay_host_profile_data(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.freeplay_host_profile_data(p_host_id uuid) RETURNS TABLE(id uuid, display_name text, avatar_url text, bio text, completed_count bigint)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT h.id, h.display_name, h.avatar_url, h.bio,
    count(a.id) FILTER (WHERE a.end_time <= now() AND fa.cancelled_at IS NULL)
  FROM public.freeplay_host h
  LEFT JOIN public.activity a ON a.freeplay_host_id = h.id
  LEFT JOIN public.freeplay_activity fa ON fa.activity_id = a.id
  WHERE h.id = p_host_id AND h.status = 'active'
  GROUP BY h.id
$$;


ALTER FUNCTION public.freeplay_host_profile_data(p_host_id uuid) OWNER TO postgres;

--
-- Name: freeplay_my_data(boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.freeplay_my_data(p_history boolean DEFAULT false) RETURNS TABLE(request_id uuid, request_status text, activity_id uuid, host_id uuid, host_name text, description text, start_time timestamp with time zone, end_time timestamp with time zone, venue_name text, street_address text, capacity integer, accepted_count bigint, price_amount numeric, recommended_skills text[], can_write boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT r.id,r.status::text,a.id,h.id,h.display_name,fa.description,a.start_time,a.end_time,
    coalesce(loc.name,fa.venue_name),coalesce(loc.full_address,fa.street_address),fa.capacity,
    (SELECT count(*) FROM public.freeplay_request x WHERE x.activity_id=a.id AND x.status='accepted'),
    r.price_amount,fa.recommended_skills,false
  FROM public.freeplay_request r JOIN public.activity a ON a.id=r.activity_id
  JOIN public.freeplay_activity fa ON fa.activity_id=a.id JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  LEFT JOIN public.location loc ON loc.id=a.location_id
  WHERE r.user_id=auth.uid() AND CASE WHEN p_history THEN
    (a.end_time<=now() OR r.status NOT IN ('pending','accepted'))
    ELSE (a.end_time>now() AND r.status IN ('pending','accepted')) END
  ORDER BY CASE WHEN p_history THEN NULL ELSE a.start_time END,
    CASE WHEN p_history THEN coalesce(r.resolved_at,a.end_time) END DESC
$$;


ALTER FUNCTION public.freeplay_my_data(p_history boolean) OWNER TO postgres;

--
-- Name: freeplay_user_skill(uuid, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.freeplay_user_skill(p_user_id uuid, p_sport_id bigint) RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT CASE p_sport_id
    WHEN 1 THEN (SELECT elo_seed FROM public.soccer_profile WHERE user_id = p_user_id)
    WHEN 2 THEN (SELECT elo_seed FROM public.basketball_profile WHERE user_id = p_user_id)
    WHEN 3 THEN (SELECT elo_seed FROM public.badminton_profile WHERE user_id = p_user_id)
    WHEN 4 THEN (SELECT elo_seed FROM public.tennis_profile WHERE user_id = p_user_id)
    WHEN 5 THEN (SELECT elo_seed FROM public.pickleball_profile WHERE user_id = p_user_id)
  END
$$;


ALTER FUNCTION public.freeplay_user_skill(p_user_id uuid, p_sport_id bigint) OWNER TO postgres;

--
-- Name: friend_data(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.friend_data() RETURNS TABLE(friendship_id uuid, user_id uuid, username text, tag_number text, details jsonb, direction text, created_at timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    select f.id,
           case when f.requester_id = auth.uid() then f.addressee_id else f.requester_id end,
           u.username::text,
           u.tag_number::text,
           u.details,
           case
               when f.status = 'accepted' then 'friend'
               when f.addressee_id = auth.uid() then 'incoming'
               else 'outgoing'
           end,
           f.created_at
    from public.friendship f
    join public."user" u
        on u.id = case when f.requester_id = auth.uid()
                       then f.addressee_id else f.requester_id end
    where auth.uid() in (f.requester_id, f.addressee_id)
      and f.status in ('pending', 'accepted')
      and not public.fn_is_blocked(auth.uid(), u.id)
    order by f.created_at desc;
$$;


ALTER FUNCTION public.friend_data() OWNER TO postgres;

--
-- Name: generate_lobby_invite_link(uuid, interval); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_lobby_invite_link(p_lobby_id uuid, p_expires_in interval DEFAULT NULL::interval) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'extensions'
    AS $$
DECLARE
    v_uid  uuid := auth.uid();
    v_code text;
    v_exp  timestamptz;
BEGIN
    IF NOT public.lobby_can_manage(p_lobby_id, v_uid) THEN
        RAISE EXCEPTION 'Not authorized to manage this lobby';
    END IF;

    UPDATE public.lobby_invite_link
       SET revoked_at = now()
     WHERE lobby_id = p_lobby_id AND revoked_at IS NULL;

    v_exp := CASE WHEN p_expires_in IS NULL THEN NULL ELSE now() + p_expires_in END;
    v_code := extensions.nanoid(10);

    INSERT INTO public.lobby_invite_link (lobby_id, code, created_by, expires_at)
    VALUES (p_lobby_id, v_code, v_uid, v_exp)
    RETURNING code, expires_at INTO v_code, v_exp;

    RETURN jsonb_build_object('code', v_code, 'expires_at', v_exp);
END;
$$;


ALTER FUNCTION public.generate_lobby_invite_link(p_lobby_id uuid, p_expires_in interval) OWNER TO postgres;

--
-- Name: get_lobby_befriend_invite_preview(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_lobby_befriend_invite_preview(p_record_id uuid) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_uid uuid := auth.uid();
    v_rec record;
    v_result jsonb;
    v_friend_status public.lobby_befriend_status;
    v_addressee uuid;
    v_relationship text;
BEGIN
    IF v_uid IS NULL THEN
        RETURN jsonb_build_object('valid', false, 'reason', 'not_found');
    END IF;

    SELECT bfr.status, bfr.target_lobby_id,
           l.name AS lobby_name, l.details AS lobby_details, l.visibility,
           l.sport_id, l.captain_id, l.home_ground, l.playtime, l.mmr,
           cap.username AS captain_username,
           ini.username AS inviter_username
      INTO v_rec
      FROM public.lobby_befriend_record bfr
      JOIN public.lobby l ON l.id = bfr.target_lobby_id
      JOIN public."user" cap ON cap.id = l.captain_id
      JOIN public."user" ini ON ini.id = bfr.initiator_user_id
     WHERE bfr.id = p_record_id
       AND bfr.target_user_id = v_uid
       AND bfr.interaction_type = 'invite';

    IF v_rec IS NULL THEN
        RETURN jsonb_build_object('valid', false, 'reason', 'not_found');
    END IF;

    -- Base tier: shown regardless of the lobby's visibility.
    v_result := jsonb_build_object(
        'valid', true,
        'status', v_rec.status,
        'lobby_id', v_rec.target_lobby_id,
        'lobby_name', v_rec.lobby_name,
        'has_avatar', coalesce((v_rec.lobby_details ->> 'hasAvatar')::boolean, false),
        'visibility', v_rec.visibility,
        'inviter_username', v_rec.inviter_username
    );

    IF v_rec.visibility IN ('discoverable', 'public') THEN
        SELECT f.status, f.addressee_id INTO v_friend_status, v_addressee
          FROM public.friendship f
         WHERE f.status IN ('pending', 'accepted')
           AND least(f.requester_id, f.addressee_id) = least(v_uid, v_rec.captain_id)
           AND greatest(f.requester_id, f.addressee_id) = greatest(v_uid, v_rec.captain_id);

        v_relationship := CASE
            WHEN public.fn_is_blocked(v_uid, v_rec.captain_id) THEN 'blocked'
            WHEN v_friend_status = 'accepted' THEN 'friend'
            WHEN v_friend_status = 'pending' AND v_addressee = v_uid THEN 'incoming'
            WHEN v_friend_status = 'pending' THEN 'outgoing'
            ELSE 'none'
        END;

        v_result := v_result || jsonb_build_object(
            'member_count', (
                SELECT count(*) FROM public.lobby_member lm
                 WHERE lm.lobby_id = v_rec.target_lobby_id
            ),
            'captain_username', v_rec.captain_username,
            'relationship', v_relationship,
            'fitscore', public.calculate_profile_compat_score(
                v_uid, v_rec.target_lobby_id, v_rec.sport_id
            )
        );
    END IF;

    IF v_rec.visibility = 'public' THEN
        v_result := v_result || jsonb_build_object(
            'home_ground_name', (
                SELECT loc.name FROM public.location loc
                 WHERE loc.id = v_rec.home_ground
            ),
            'playtime', v_rec.playtime,
            'mmr', v_rec.mmr,
            'is_mmr_calibrated', EXISTS(
                SELECT 1 FROM public.lobby_match lm
                 WHERE lm.lobby_id = v_rec.target_lobby_id
                   AND lm.opponent_lobby_id IS NOT NULL
            ),
            'members', (
                SELECT coalesce(
                    jsonb_agg(
                        jsonb_build_object(
                            'username', u.username, 'tag_number', u.tag_number
                        ) ORDER BY u.username
                    ),
                    '[]'::jsonb
                )
                  FROM public.lobby_member lm2
                  JOIN public."user" u ON u.id = lm2.user_id
                 WHERE lm2.lobby_id = v_rec.target_lobby_id
            )
        );
    END IF;

    RETURN v_result;
END;
$$;


ALTER FUNCTION public.get_lobby_befriend_invite_preview(p_record_id uuid) OWNER TO postgres;

--
-- Name: get_lobby_invite_preview(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_lobby_invite_preview(p_code text) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_link record;
BEGIN
    SELECT lil.*, l.name AS lobby_name, l.sport_id, l.member_count, u.username AS captain_username
      INTO v_link
      FROM public.lobby_invite_link lil
      JOIN public.lobby l ON l.id = lil.lobby_id
      JOIN public."user" u ON u.id = l.captain_id
     WHERE lil.code = p_code;

    IF v_link IS NULL THEN
        RETURN jsonb_build_object('valid', false, 'reason', 'not_found');
    ELSIF v_link.revoked_at IS NOT NULL THEN
        RETURN jsonb_build_object('valid', false, 'reason', 'revoked');
    ELSIF v_link.expires_at IS NOT NULL AND v_link.expires_at <= now() THEN
        RETURN jsonb_build_object('valid', false, 'reason', 'expired');
    END IF;

    RETURN jsonb_build_object(
        'valid', true,
        'lobby_id', v_link.lobby_id,
        'lobby_name', v_link.lobby_name,
        'sport_id', v_link.sport_id,
        'member_count', v_link.member_count,
        'captain_username', v_link.captain_username
    );
END;
$$;


ALTER FUNCTION public.get_lobby_invite_preview(p_code text) OWNER TO postgres;

--
-- Name: get_my_friend_ids(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_my_friend_ids() RETURNS SETOF uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    select case when requester_id = auth.uid() then addressee_id else requester_id end
    from public.friendship
    where status = 'accepted'
      and auth.uid() in (requester_id, addressee_id);
$$;


ALTER FUNCTION public.get_my_friend_ids() OWNER TO postgres;

--
-- Name: get_my_lobby_ids(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_my_lobby_ids() RETURNS SETOF uuid
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN QUERY SELECT lobby_id FROM public.lobby_member WHERE user_id = auth.uid();
END;
$$;


ALTER FUNCTION public.get_my_lobby_ids() OWNER TO postgres;

--
-- Name: get_my_lobbymate_ids(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_my_lobbymate_ids() RETURNS SETOF uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    select distinct m.user_id
    from public.lobby_member m
    where m.lobby_id in (select public.get_my_lobby_ids())
      and m.user_id <> auth.uid();
$$;


ALTER FUNCTION public.get_my_lobbymate_ids() OWNER TO postgres;

--
-- Name: get_payment_info(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_payment_info(p_user_id uuid) RETURNS TABLE(id uuid, bank_id text, bank_display_name text, value text, account_name text, created_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
    if auth.uid() is null then
        return;   -- unauthenticated: empty result, not an error
    end if;

    if p_user_id <> auth.uid() and (
        public.fn_is_blocked(auth.uid(), p_user_id)
        or (
            p_user_id not in (select public.get_my_friend_ids())
            and p_user_id not in (select public.get_my_lobbymate_ids())
        )
    ) then
        return;   -- not authorized: empty result, not an error
    end if;

    return query
    select i.id, i.bank_id, i.bank_display_name,
           v_value.decrypted_secret, v_name.decrypted_secret, i.created_at
    from public.user_payment_info i
    join vault.decrypted_secrets v_value on v_value.id = i.value_secret_id
    left join vault.decrypted_secrets v_name on v_name.id = i.account_name_secret_id
    where i.user_id = p_user_id
    order by i.created_at;
end;
$$;


ALTER FUNCTION public.get_payment_info(p_user_id uuid) OWNER TO postgres;

--
-- Name: get_popular_networks(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_popular_networks(limit_count integer DEFAULT 5) RETURNS TABLE(id bigint, name text, category text)
    LANGUAGE sql
    SET search_path TO ''
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


ALTER FUNCTION public.get_popular_networks(limit_count integer) OWNER TO postgres;

--
-- Name: health_capture_candidates(timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.health_capture_candidates(p_window_start timestamp with time zone) RETURNS TABLE(activity_id uuid, start_time timestamp with time zone, end_time timestamp with time zone, sport_id bigint, source text, confirmed boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid();
BEGIN
  RETURN QUERY SELECT a.id, a.start_time, a.end_time, a.sport_id,
    CASE WHEN a.course_id IS NOT NULL THEN 'professional'
      WHEN a.freeplay_host_id IS NOT NULL THEN 'freeplay'
      WHEN a.lobby_id IS NOT NULL THEN 'lobby' ELSE 'self' END,
    EXISTS(SELECT 1 FROM public.activity_confirmation ac
           WHERE ac.activity_id = a.id AND ac.user_id = v_uid)
  FROM public.activity a
  WHERE a.end_time IS NOT NULL AND a.end_time < now() AND a.end_time >= p_window_start
    AND (a.user_id = v_uid
      OR EXISTS(SELECT 1 FROM public.activity_confirmation ac
                WHERE ac.activity_id = a.id AND ac.user_id = v_uid))
    AND NOT EXISTS(SELECT 1 FROM public.activity_health_metrics m
                   WHERE m.activity_id = a.id AND m.user_id = v_uid)
  ORDER BY a.end_time DESC;
END
$$;


ALTER FUNCTION public.health_capture_candidates(p_window_start timestamp with time zone) OWNER TO postgres;

--
-- Name: home_challenger_lobby_data(uuid, bigint, integer, character varying[], text, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_search text DEFAULT NULL::text, p_mmr_window integer DEFAULT 200, p_page_size integer DEFAULT 10, p_page_number integer DEFAULT 1) RETURNS TABLE(id uuid, name text, homeground_name text, playtime jsonb, details jsonb, visibility public.lobby_visibility, member_count integer, lobby_mmr integer, favorability text, profile_compat_score numeric, match_factors text[], offer_time timestamp with time zone, offer_location_name text, offer_cost numeric, rated_match_count integer)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
    c_home_adv  constant integer := 50;
    c_w_compat  constant numeric := 0.6;
    c_w_even    constant numeric := 0.4;
    v_mmr     integer;
    v_net     bigint[];
    v_active  bigint[];
    v_ind     integer[];
    v_pt      text[];
    v_lat     double precision;
    v_lon     double precision;
    v_window  integer := p_mmr_window;
    v_cnt     integer;
BEGIN
    SELECT l.mmr, l.network_ids, l.active_network_ids, l.industry_ids, l.playtime_keys,
           loc.lat, loc.lon
      INTO v_mmr, v_net, v_active, v_ind, v_pt, v_lat, v_lon
      FROM public.lobby l
      LEFT JOIN public.location loc ON l.home_ground = loc.id
     WHERE l.id = p_context_lobby_id;
    v_mmr := COALESCE(v_mmr, 1000);

    -- ── Search mode: sport + challenger gate + visibility + identity gates only ──
    IF p_search IS NOT NULL AND p_search <> '' THEN
        RETURN QUERY
        WITH candidate AS (
            SELECT
                l.id, l.name, hloc.name AS homeground_name, l.playtime, l.details, l.visibility,
                l.member_count, l.mmr AS cand_mmr,
                l.network_ids, l.active_network_ids, l.industry_ids, l.playtime_keys,
                l.challenge_offer_time, l.challenge_offer_cost, l.rated_match_count,
                oloc.name AS offer_location_name,
                oloc.district, oloc.lat, oloc.lon
            FROM public.lobby l
            JOIN public.location oloc ON oloc.id = l.challenge_offer_location
            LEFT JOIN public.location hloc ON hloc.id = l.home_ground
            WHERE l.sport_id = p_sport_id AND l.open_to_challengers AND l.visibility <> 'private'
              AND l.challenge_offer_time > now()
              AND l.id <> p_context_lobby_id
              AND l.id NOT IN (SELECT public.get_my_lobby_ids())
              AND (
                   l.name ILIKE '%' || p_search || '%'
                   OR extensions.unaccent(l.name) ILIKE '%' || extensions.unaccent(p_search) || '%'
                   OR l.searchable_id ILIKE '%' || p_search || '%'
              )
        ),
        scored AS (
            SELECT
                c.*,
                1.0 / (1.0 + power(10.0, ((c.cand_mmr + c_home_adv - v_mmr)::numeric / 400.0))) AS away_expected,
                (c.network_ids && v_net) AS f_network,
                ((SELECT count(*) FROM (SELECT unnest(c.playtime_keys) INTERSECT SELECT unnest(v_pt)) x) > 0) AS f_playtime,
                ((c.district = ANY(p_districts))
                    OR (v_lat IS NOT NULL AND c.lat IS NOT NULL
                        AND abs(c.lat - v_lat) + abs(c.lon - v_lon) < 0.1)) AS f_location,
                (c.industry_ids && v_ind) AS f_industry,
                (
                    (CASE WHEN c.network_ids && v_net THEN 3 ELSE 0 END)
                  + (CASE WHEN c.active_network_ids && v_active THEN 2 ELSE 0 END)
                  + LEAST(2, cardinality(ARRAY(
                        SELECT unnest(c.playtime_keys) INTERSECT SELECT unnest(v_pt))))
                  + (CASE WHEN (c.district = ANY(p_districts))
                            OR (v_lat IS NOT NULL AND c.lat IS NOT NULL
                                AND abs(c.lat - v_lat) + abs(c.lon - v_lon) < 0.1)
                          THEN 1 ELSE 0 END)
                  + (CASE WHEN c.industry_ids && v_ind THEN 1 ELSE 0 END)
                )::numeric AS compat_raw
            FROM candidate c
        )
        SELECT
            s.id, s.name::text, s.homeground_name::text, s.playtime, s.details, s.visibility,
            s.member_count, s.cand_mmr AS lobby_mmr,
            CASE WHEN s.away_expected > 0.55 THEN 'favored'
                 WHEN s.away_expected < 0.45 THEN 'underdog'
                 ELSE 'even' END AS favorability,
            (2.5 + (s.compat_raw / 9.0) * 2.5) AS profile_compat_score,
            ARRAY_REMOVE(ARRAY[
                CASE WHEN s.f_network  THEN 'network'  END,
                CASE WHEN s.f_playtime THEN 'playtime' END,
                CASE WHEN s.f_location THEN 'location' END,
                CASE WHEN s.f_industry THEN 'industry' END
            ], NULL) AS match_factors,
            s.challenge_offer_time, s.offer_location_name::text, s.challenge_offer_cost,
            s.rated_match_count
        FROM scored s
        ORDER BY (
            c_w_compat * (s.compat_raw / 9.0)
          + c_w_even * (1.0 - 2.0 * abs(s.away_expected - 0.5))
        ) DESC
        LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
        RETURN;
    END IF;

    -- ── Non-search mode: existing logic, unchanged ──
    SELECT count(*) INTO v_cnt
      FROM public.lobby l
      JOIN public.location oloc ON oloc.id = l.challenge_offer_location
     WHERE l.sport_id = p_sport_id AND l.open_to_challengers AND l.visibility <> 'private'
       AND l.challenge_offer_time > now()
       AND oloc.city_cluster = p_city AND l.id <> p_context_lobby_id
       AND l.id NOT IN (SELECT public.get_my_lobby_ids())
       AND l.mmr BETWEEN v_mmr - v_window AND v_mmr + v_window;
    IF v_cnt < p_page_size THEN
        v_window := v_window * 2;
        SELECT count(*) INTO v_cnt
          FROM public.lobby l
          JOIN public.location oloc ON oloc.id = l.challenge_offer_location
         WHERE l.sport_id = p_sport_id AND l.open_to_challengers AND l.visibility <> 'private'
           AND l.challenge_offer_time > now()
           AND oloc.city_cluster = p_city AND l.id <> p_context_lobby_id
           AND l.id NOT IN (SELECT public.get_my_lobby_ids())
           AND l.mmr BETWEEN v_mmr - v_window AND v_mmr + v_window;
        IF v_cnt < p_page_size THEN
            v_window := 1000000;
        END IF;
    END IF;

    RETURN QUERY
    WITH candidate AS (
        SELECT
            l.id, l.name, hloc.name AS homeground_name, l.playtime, l.details, l.visibility,
            l.member_count, l.mmr AS cand_mmr,
            l.network_ids, l.active_network_ids, l.industry_ids, l.playtime_keys,
            l.challenge_offer_time, l.challenge_offer_cost, l.rated_match_count,
            oloc.name AS offer_location_name,
            oloc.district, oloc.lat, oloc.lon
        FROM public.lobby l
        JOIN public.location oloc ON oloc.id = l.challenge_offer_location
        LEFT JOIN public.location hloc ON hloc.id = l.home_ground
        WHERE l.sport_id = p_sport_id AND l.open_to_challengers AND l.visibility <> 'private'
          AND l.challenge_offer_time > now()
          AND oloc.city_cluster = p_city AND l.id <> p_context_lobby_id
          AND l.id NOT IN (SELECT public.get_my_lobby_ids())
          AND l.mmr BETWEEN v_mmr - v_window AND v_mmr + v_window
    ),
    scored AS (
        SELECT
            c.*,
            1.0 / (1.0 + power(10.0, ((c.cand_mmr + c_home_adv - v_mmr)::numeric / 400.0))) AS away_expected,
            (c.network_ids && v_net) AS f_network,
            ((SELECT count(*) FROM (SELECT unnest(c.playtime_keys) INTERSECT SELECT unnest(v_pt)) x) > 0) AS f_playtime,
            ((c.district = ANY(p_districts))
                OR (v_lat IS NOT NULL AND c.lat IS NOT NULL
                    AND abs(c.lat - v_lat) + abs(c.lon - v_lon) < 0.1)) AS f_location,
            (c.industry_ids && v_ind) AS f_industry,
            (
                (CASE WHEN c.network_ids && v_net THEN 3 ELSE 0 END)
              + (CASE WHEN c.active_network_ids && v_active THEN 2 ELSE 0 END)
              + LEAST(2, cardinality(ARRAY(
                    SELECT unnest(c.playtime_keys) INTERSECT SELECT unnest(v_pt))))
              + (CASE WHEN (c.district = ANY(p_districts))
                        OR (v_lat IS NOT NULL AND c.lat IS NOT NULL
                            AND abs(c.lat - v_lat) + abs(c.lon - v_lon) < 0.1)
                      THEN 1 ELSE 0 END)
              + (CASE WHEN c.industry_ids && v_ind THEN 1 ELSE 0 END)
            )::numeric AS compat_raw
        FROM candidate c
    )
    SELECT
        s.id, s.name::text, s.homeground_name::text, s.playtime, s.details, s.visibility,
        s.member_count, s.cand_mmr AS lobby_mmr,
        CASE WHEN s.away_expected > 0.55 THEN 'favored'
             WHEN s.away_expected < 0.45 THEN 'underdog'
             ELSE 'even' END AS favorability,
        (2.5 + (s.compat_raw / 9.0) * 2.5) AS profile_compat_score,
        ARRAY_REMOVE(ARRAY[
            CASE WHEN s.f_network  THEN 'network'  END,
            CASE WHEN s.f_playtime THEN 'playtime' END,
            CASE WHEN s.f_location THEN 'location' END,
            CASE WHEN s.f_industry THEN 'industry' END
        ], NULL) AS match_factors,
        s.challenge_offer_time, s.offer_location_name::text, s.challenge_offer_cost,
        s.rated_match_count
    FROM scored s
    ORDER BY (
        c_w_compat * (s.compat_raw / 9.0)
      + c_w_even * (1.0 - 2.0 * abs(s.away_expected - 0.5))
    ) DESC
    LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
END;
$$;


ALTER FUNCTION public.home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_search text, p_mmr_window integer, p_page_size integer, p_page_number integer) OWNER TO postgres;

--
-- Name: home_freeplay_data(bigint, jsonb, integer, character varying[], text, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.home_freeplay_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text DEFAULT ''::text, p_page_size integer DEFAULT 20, p_page_number integer DEFAULT 1) RETURNS TABLE(activity_id uuid, host_id uuid, host_name text, host_avatar_url text, description text, start_time timestamp with time zone, end_time timestamp with time zone, location_id uuid, venue_name text, street_address text, city_cluster bigint, ward text, capacity integer, accepted_count bigint, male_price numeric, female_price numeric, recommended_skills text[], my_skill text, my_request_id uuid, my_request_status text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  WITH candidate AS (
    SELECT a.id, a.freeplay_host_id, a.start_time, a.end_time, a.location_id,
      a.created_at AS activity_created_at,
      fa.description, fa.capacity, fa.male_price, fa.female_price,
      fa.recommended_skills, h.display_name, h.avatar_url,
      coalesce(loc.name,fa.venue_name) resolved_venue,
      coalesce(loc.full_address,fa.street_address) resolved_address,
      coalesce(loc.city_cluster,fa.city_cluster) resolved_city,
      coalesce(fa.ward,loc.district) resolved_ward,
      (SELECT count(*) FROM public.freeplay_request ar WHERE ar.activity_id=a.id AND ar.status='accepted') accepted,
      CASE extract(isodow FROM a.start_time AT TIME ZONE 'Asia/Ho_Chi_Minh')::int
        WHEN 1 THEN 'mon' WHEN 2 THEN 'tue' WHEN 3 THEN 'wed' WHEN 4 THEN 'thu'
        WHEN 5 THEN 'fri' WHEN 6 THEN 'sat' ELSE 'sun' END slot_day,
      CASE WHEN extract(hour FROM a.start_time AT TIME ZONE 'Asia/Ho_Chi_Minh')<9 THEN 'early'
        WHEN extract(hour FROM a.start_time AT TIME ZONE 'Asia/Ho_Chi_Minh')<14 THEN 'midday'
        WHEN extract(hour FROM a.start_time AT TIME ZONE 'Asia/Ho_Chi_Minh')<18 THEN 'noon' ELSE 'night' END slot_chunk
    FROM public.activity a JOIN public.freeplay_activity fa ON fa.activity_id=a.id
    JOIN public.freeplay_host h ON h.id=a.freeplay_host_id AND h.status='active'
    LEFT JOIN public.location loc ON loc.id=a.location_id
    WHERE a.sport_id=p_sport_id AND a.end_time>now() AND a.start_time<=now()+interval '7 days'
      AND fa.cancelled_at IS NULL AND fa.intake_closed_at IS NULL
      AND coalesce(loc.city_cluster,fa.city_cluster)=p_city
      AND (auth.uid() IS NULL OR NOT public.fn_is_blocked(auth.uid(),h.user_id))
  )
  SELECT c.id,c.freeplay_host_id,c.display_name,c.avatar_url,c.description,c.start_time,c.end_time,c.location_id,
    c.resolved_venue,c.resolved_address,c.resolved_city,c.resolved_ward,c.capacity,c.accepted,
    c.male_price,c.female_price,c.recommended_skills,public.freeplay_user_skill(auth.uid(),p_sport_id),
    mr.id,mr.status::text
  FROM candidate c
  LEFT JOIN LATERAL (SELECT r.id,r.status FROM public.freeplay_request r WHERE r.activity_id=c.id AND r.user_id=auth.uid()
    ORDER BY r.created_at DESC LIMIT 1) mr ON true
  WHERE c.accepted<c.capacity
    AND (coalesce(cardinality(p_districts),0)=0 OR c.resolved_ward=ANY(p_districts))
    AND (coalesce(p_search,'')='' OR public.immutable_unaccent(c.display_name||' '||c.resolved_venue||' '||coalesce(c.resolved_address,''))
      ILIKE '%'||public.immutable_unaccent(p_search)||'%')
    AND (p_timeslots='{}'::jsonb OR coalesce((p_timeslots->c.slot_day) ? c.slot_chunk,false))
  ORDER BY c.start_time,c.activity_created_at
  LIMIT greatest(1,least(p_page_size,50)) OFFSET greatest(0,(p_page_number-1)*p_page_size)
$$;


ALTER FUNCTION public.home_freeplay_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text, p_page_size integer, p_page_number integer) OWNER TO postgres;

--
-- Name: home_professional_data(bigint, jsonb, integer, text[], text, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.home_professional_data(p_sport_id bigint, p_timeslots jsonb DEFAULT '{}'::jsonb, p_city integer DEFAULT NULL::integer, p_districts text[] DEFAULT NULL::text[], p_search text DEFAULT NULL::text, p_page_size integer DEFAULT 20, p_page_number integer DEFAULT 1) RETURNS TABLE(id uuid, display_name text, professional_role public.professional_role, bio text, sports bigint[], experience_years integer, average_rating numeric, review_count integer, is_verified boolean, price_from numeric, price_from_kind text, timeslot_compat_score integer, linked_user_id uuid, generated_avatar text)
    LANGUAGE plpgsql STABLE
    SET search_path TO ''
    AS $$
BEGIN
    IF p_search IS NOT NULL AND p_search <> '' THEN
        RETURN QUERY
            SELECT p.id, p.display_name::text, p.professional_role, p.bio,
                   p.sports, p.experience_years, p.average_rating,
                   p.review_count, p.is_verified,
                   price.price_amount, price.pricing_kind,
                   COALESCE(ts.ts_score, 0),
                   p.linked_user_id, cu.details->>'generatedAvatar'
            FROM public.professional p
            CROSS JOIN LATERAL (
                SELECT public.calculate_timeslot_compat_score(
                    p_timeslots,
                    public.fn_playtime_to_dict(COALESCE(p.schedule, '[]'::jsonb))
                ) AS ts_score
            ) ts
            LEFT JOIN LATERAL (
                SELECT ps.price_amount, ps.pricing_kind
                FROM public.professional_service ps
                WHERE ps.professional_id = p.id
                  AND ps.sport_id = p_sport_id
                  AND ps.is_active
                ORDER BY ps.price_amount NULLS LAST, ps.created_at, ps.id
                LIMIT 1
            ) price ON true
            LEFT JOIN public."user" cu ON cu.id = p.linked_user_id
            WHERE p.sports @> ARRAY[p_sport_id]::bigint[]
              AND p.linked_user_id IS DISTINCT FROM auth.uid()
              AND (
                  p.display_name ILIKE '%' || p_search || '%'
                  OR extensions.unaccent(p.display_name)
                     ILIKE '%' || extensions.unaccent(p_search) || '%'
              )
            ORDER BY p.is_verified DESC, p.average_rating DESC,
                     p.review_count DESC
            LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
        RETURN;
    END IF;

    RETURN QUERY
        SELECT p.id, p.display_name::text, p.professional_role, p.bio,
               p.sports, p.experience_years, p.average_rating,
               p.review_count, p.is_verified,
               price.price_amount, price.pricing_kind,
               COALESCE(ts.ts_score, 0),
               p.linked_user_id, cu.details->>'generatedAvatar'
        FROM public.professional p
        CROSS JOIN LATERAL (
            SELECT public.calculate_timeslot_compat_score(
                p_timeslots,
                public.fn_playtime_to_dict(COALESCE(p.schedule, '[]'::jsonb))
            ) AS ts_score
        ) ts
        LEFT JOIN LATERAL (
            SELECT ps.price_amount, ps.pricing_kind
            FROM public.professional_service ps
            WHERE ps.professional_id = p.id
              AND ps.sport_id = p_sport_id
              AND ps.is_active
            ORDER BY ps.price_amount NULLS LAST, ps.created_at, ps.id
            LIMIT 1
        ) price ON true
        LEFT JOIN public."user" cu ON cu.id = p.linked_user_id
        WHERE p.sports @> ARRAY[p_sport_id]::bigint[]
          AND p.linked_user_id IS DISTINCT FROM auth.uid()
          AND (
              p_city IS NULL
              OR p.preferred_city_cluster IS NULL
              OR p.preferred_city_cluster = p_city
          )
          AND (
              p_districts IS NULL OR cardinality(p_districts) = 0
              OR p.preferred_districts IS NULL
              OR cardinality(p.preferred_districts) = 0
              OR p.preferred_districts && p_districts
          )
          AND (
              p_timeslots = '{}'::jsonb
              OR p.schedule IS NULL
              OR p.schedule = '[]'::jsonb
              OR ts.ts_score >= 4
          )
        ORDER BY p.is_verified DESC, p.average_rating DESC,
                 p.review_count DESC
        LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
END;
$$;


ALTER FUNCTION public.home_professional_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts text[], p_search text, p_page_size integer, p_page_number integer) OWNER TO postgres;

--
-- Name: home_teammate_lobby_data(bigint, jsonb, integer, character varying[], text, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text DEFAULT NULL::text, p_page_size integer DEFAULT 10, p_page_number integer DEFAULT 1) RETURNS TABLE(id uuid, name text, homeground_name text, playtime jsonb, details jsonb, visibility public.lobby_visibility, member_count integer, timeslot_compat_score integer, profile_compat_score numeric, match_factors text[], already_requested boolean)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
    v_ts_floor integer := 4;
    v_cnt      integer;
BEGIN
    -- ── Search mode: sport + visibility + identity gates only ──
    IF p_search IS NOT NULL AND p_search <> '' THEN
        RETURN QUERY
            SELECT
                l.id,
                l.name::text,
                loc.name::text AS homeground_name,
                l.playtime,
                l.details,
                l.visibility,
                l.member_count,
                ts.ts_score AS timeslot_compat_score,
                (ps.compat->>'score')::numeric AS profile_compat_score,
                (
                    ARRAY(SELECT jsonb_array_elements_text(ps.compat->'factors'))
                    || CASE WHEN ts.ts_score >= 4 THEN ARRAY['playtime'] ELSE ARRAY[]::text[] END
                ) AS match_factors,
                EXISTS (
                    SELECT 1 FROM public.lobby_befriend_record r
                    WHERE r.initiator_user_id = auth.uid()
                      AND r.target_lobby_id = l.id
                      AND r.interaction_type = 'request'
                      AND r.status = 'pending'
                ) AS already_requested
            FROM
                public.lobby l
                    LEFT JOIN
                public.location loc ON l.home_ground = loc.id
                    CROSS JOIN LATERAL (
                    SELECT public.calculate_timeslot_compat_score(p_timeslots, public.fn_playtime_to_dict(l.playtime)) AS ts_score
                    ) ts
                    CROSS JOIN LATERAL (
                    SELECT public.calculate_profile_compat(auth.uid(), l.id, l.sport_id) AS compat
                    ) ps
            WHERE
                l.sport_id = p_sport_id
              AND l.visibility != 'private'
              AND l.id NOT IN (SELECT public.get_my_lobby_ids())
              AND (
                    l.name ILIKE '%' || p_search || '%'
                    OR extensions.unaccent(l.name) ILIKE '%' || extensions.unaccent(p_search) || '%'
                    OR l.searchable_id ILIKE '%' || p_search || '%'
                )
              AND NOT EXISTS (
                    SELECT 1 FROM public.lobby_befriend_record r
                    WHERE r.initiator_user_id = auth.uid()
                      AND r.target_lobby_id = l.id
                      AND r.interaction_type = 'request'
                      AND r.status = 'declined'
                )
            ORDER BY
                profile_compat_score DESC,
                timeslot_compat_score DESC
            LIMIT p_page_size
                OFFSET (p_page_number - 1) * p_page_size;
        RETURN;
    END IF;

    -- ── Non-search mode: existing logic, unchanged ──
    IF p_timeslots <> '{}'::jsonb THEN
        SELECT count(*) INTO v_cnt
        FROM public.lobby l
        LEFT JOIN public.location loc ON l.home_ground = loc.id
        CROSS JOIN LATERAL (
            SELECT public.calculate_timeslot_compat_score(
                       p_timeslots, public.fn_playtime_to_dict(l.playtime)
                   ) AS ts_score
        ) ts
        WHERE l.sport_id = p_sport_id
          AND l.visibility != 'private'
          AND (loc.city_cluster = p_city OR loc.id IS NULL)
          AND l.id NOT IN (SELECT public.get_my_lobby_ids())
          AND (p_districts IS NULL OR cardinality(p_districts) = 0 OR loc.district = ANY(p_districts))
          AND ts.ts_score >= v_ts_floor
          AND NOT EXISTS (
                SELECT 1 FROM public.lobby_befriend_record r
                WHERE r.initiator_user_id = auth.uid()
                  AND r.target_lobby_id = l.id
                  AND r.interaction_type = 'request'
                  AND r.status = 'declined'
            );

        IF v_cnt < p_page_size THEN
            v_ts_floor := 2;
            SELECT count(*) INTO v_cnt
            FROM public.lobby l
            LEFT JOIN public.location loc ON l.home_ground = loc.id
            CROSS JOIN LATERAL (
                SELECT public.calculate_timeslot_compat_score(
                           p_timeslots, public.fn_playtime_to_dict(l.playtime)
                       ) AS ts_score
            ) ts
            WHERE l.sport_id = p_sport_id
              AND l.visibility != 'private'
              AND (loc.city_cluster = p_city OR loc.id IS NULL)
              AND l.id NOT IN (SELECT public.get_my_lobby_ids())
              AND (p_districts IS NULL OR cardinality(p_districts) = 0 OR loc.district = ANY(p_districts))
              AND ts.ts_score >= v_ts_floor
              AND NOT EXISTS (
                    SELECT 1 FROM public.lobby_befriend_record r
                    WHERE r.initiator_user_id = auth.uid()
                      AND r.target_lobby_id = l.id
                      AND r.interaction_type = 'request'
                      AND r.status = 'declined'
                );

            IF v_cnt < p_page_size THEN
                v_ts_floor := 0;
            END IF;
        END IF;
    END IF;

    RETURN QUERY
        SELECT
            l.id,
            l.name::text,
            loc.name::text AS homeground_name,
            l.playtime,
            l.details,
            l.visibility,
            l.member_count,
            ts.ts_score AS timeslot_compat_score,
            (ps.compat->>'score')::numeric AS profile_compat_score,
            (
                ARRAY(SELECT jsonb_array_elements_text(ps.compat->'factors'))
                || CASE WHEN ts.ts_score >= 4 THEN ARRAY['playtime'] ELSE ARRAY[]::text[] END
            ) AS match_factors,
            EXISTS (
                SELECT 1 FROM public.lobby_befriend_record r
                WHERE r.initiator_user_id = auth.uid()
                  AND r.target_lobby_id = l.id
                  AND r.interaction_type = 'request'
                  AND r.status = 'pending'
            ) AS already_requested
        FROM
            public.lobby l
                LEFT JOIN
            public.location loc ON l.home_ground = loc.id
                CROSS JOIN LATERAL (
                SELECT public.calculate_timeslot_compat_score(p_timeslots, public.fn_playtime_to_dict(l.playtime)) AS ts_score
                ) ts
                CROSS JOIN LATERAL (
                SELECT public.calculate_profile_compat(auth.uid(), l.id, l.sport_id) AS compat
                ) ps
        WHERE
            l.sport_id = p_sport_id
          AND l.visibility != 'private'
          AND (loc.city_cluster = p_city OR loc.id IS NULL)
          AND l.id NOT IN (SELECT public.get_my_lobby_ids())
          AND (p_districts IS NULL OR cardinality(p_districts) = 0 OR loc.district = ANY(p_districts))
          AND (p_timeslots = '{}'::jsonb OR ts.ts_score >= v_ts_floor)
          AND NOT EXISTS (
                SELECT 1 FROM public.lobby_befriend_record r
                WHERE r.initiator_user_id = auth.uid()
                  AND r.target_lobby_id = l.id
                  AND r.interaction_type = 'request'
                  AND r.status = 'declined'
            )
        ORDER BY
            profile_compat_score DESC,
            timeslot_compat_score DESC
        LIMIT p_page_size
            OFFSET (p_page_number - 1) * p_page_size;
END;
$$;


ALTER FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text, p_page_size integer, p_page_number integer) OWNER TO postgres;

--
-- Name: immutable_unaccent(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.immutable_unaccent(text) RETURNS text
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $_$
SELECT extensions.unaccent($1)
$_$;


ALTER FUNCTION public.immutable_unaccent(text) OWNER TO postgres;

--
-- Name: is_booking_attached_to_my_lobby_activity(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_booking_attached_to_my_lobby_activity(p_booking_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.activity a
    WHERE a.referee_booking_id = p_booking_id
      AND a.lobby_id IN (SELECT public.get_my_lobby_ids())
  );
END;
$$;


ALTER FUNCTION public.is_booking_attached_to_my_lobby_activity(p_booking_id uuid) OWNER TO postgres;

--
-- Name: leave_course(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.leave_course(p_course_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_username text; v_was_enrolled boolean;
BEGIN
  SELECT (m.status = 'enrolled') INTO v_was_enrolled FROM public.course_member m
  WHERE m.course_id = p_course_id AND m.user_id = v_uid AND m.left_at IS NULL;

  UPDATE public.course_member SET status = 'left', left_at = now()
  WHERE course_id = p_course_id AND user_id = v_uid AND left_at IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'membership not found'; END IF;

  UPDATE public.conversation_member SET left_at = now()
  WHERE user_id = v_uid
    AND conversation_id = (SELECT id FROM public.conversation WHERE course_id = p_course_id);

  SELECT u.username::text INTO v_username FROM public."user" u WHERE u.id = v_uid;
  PERFORM public.fn_course_system_message(p_course_id, 'member_left',
    jsonb_build_object('username', v_username));

  PERFORM public.fn_course_prompt_if_no_students(p_course_id, coalesce(v_was_enrolled, false));
END
$$;


ALTER FUNCTION public.leave_course(p_course_id uuid) OWNER TO postgres;

--
-- Name: lobby_add_captain_as_member(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.lobby_add_captain_as_member() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
    INSERT INTO public.lobby_member (user_id, lobby_id)
    VALUES (NEW.captain_id, NEW.id)
    ON CONFLICT (user_id, lobby_id) DO NOTHING;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.lobby_add_captain_as_member() OWNER TO postgres;

--
-- Name: lobby_before_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.lobby_before_delete() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_other_members int;
BEGIN
    SELECT COUNT(*)
        INTO v_other_members
        FROM public.lobby_member
        WHERE lobby_id = OLD.id
          AND user_id <> OLD.captain_id;

    IF v_other_members > 0 THEN
        RAISE EXCEPTION
            'Cannot delete lobby % while % other member(s) remain — they must leave first',
            OLD.id, v_other_members;
    END IF;

    -- Whitelist the captain-leave check for the cascade that's about
    -- to run on lobby_member. `true` makes the setting tx-local.
    PERFORM set_config('app.lobby_being_deleted', OLD.id::text, true);

    RETURN OLD;
END;
$$;


ALTER FUNCTION public.lobby_before_delete() OWNER TO postgres;

--
-- Name: lobby_befriend_accepted_trigger_fn(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.lobby_befriend_accepted_trigger_fn() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    new_lobby_id       uuid;
    initiator_username text;
    target_username    text;
    lobby_name         text;
    sport_id           bigint;
BEGIN
    IF NEW.status = 'accepted' AND (OLD.status IS NULL OR OLD.status != 'accepted') THEN

        -- 'request' / 'invite' add the relevant user to an existing lobby.
        IF NEW.interaction_type = 'request' AND NEW.target_lobby_id IS NOT NULL THEN
            INSERT INTO public.lobby_member (user_id, lobby_id)
            VALUES (NEW.initiator_user_id, NEW.target_lobby_id)
            ON CONFLICT DO NOTHING;

        ELSIF NEW.interaction_type = 'invite' AND NEW.target_user_id IS NOT NULL THEN
            INSERT INTO public.lobby_member (user_id, lobby_id)
            VALUES (NEW.target_user_id, NEW.target_lobby_id)
            ON CONFLICT DO NOTHING;

        -- 'pair' creates a brand-new lobby. The captain (initiator) is
        -- joined automatically by lobby_add_captain_as_member; we only
        -- need to add the OTHER user.
        ELSIF NEW.interaction_type = 'pair' AND NEW.target_user_id IS NOT NULL THEN
            IF NEW.details ? 'sport_id' THEN
                sport_id := (NEW.details ->> 'sport_id')::bigint;

                SELECT username INTO initiator_username
                    FROM public."user" WHERE id = NEW.initiator_user_id;
                SELECT username INTO target_username
                    FROM public."user" WHERE id = NEW.target_user_id;
                lobby_name := initiator_username || ' & ' || target_username;

                INSERT INTO public.lobby (captain_id, name, sport_id)
                VALUES (NEW.initiator_user_id, lobby_name, sport_id)
                RETURNING id INTO new_lobby_id;

                INSERT INTO public.lobby_member (user_id, lobby_id)
                VALUES (NEW.target_user_id, new_lobby_id)
                ON CONFLICT DO NOTHING;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.lobby_befriend_accepted_trigger_fn() OWNER TO postgres;

--
-- Name: lobby_befriend_record_before_insert_trigger_fn(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.lobby_befriend_record_before_insert_trigger_fn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    existing_record            lobby_befriend_record%ROWTYPE;
    lobby_member_exists        BOOLEAN := FALSE;
    target_lobby_member_exists BOOLEAN := FALSE;
BEGIN
    -- Requests: Check if initiator is a member of target lobby
    IF NEW.interaction_type = 'request' AND NEW.target_lobby_id IS NOT NULL THEN
        SELECT EXISTS(SELECT 1
                      FROM lobby_member lm
                      WHERE lm.lobby_id = NEW.target_lobby_id
                        AND lm.user_id = NEW.initiator_user_id)
        INTO lobby_member_exists;

        IF lobby_member_exists THEN
            RAISE EXCEPTION 'Cannot create request: user is already a member of the target lobby';
        END IF;
    END IF;

    -- Invites: Check if target user is a member of target lobby
    IF NEW.interaction_type = 'invite' AND NEW.target_user_id IS NOT NULL THEN
        SELECT EXISTS(SELECT 1
                      FROM lobby_member lm
                      WHERE lm.lobby_id = NEW.target_lobby_id AND lm.user_id = NEW.target_user_id)
        INTO target_lobby_member_exists;

        IF target_lobby_member_exists THEN
            RAISE EXCEPTION 'Cannot create invite: target user is already a member of the lobby';
        END IF;
    END IF;

    -- Check for existing identical record in pending or declined state
    SELECT *
    INTO existing_record
    FROM lobby_befriend_record
    WHERE initiator_user_id = NEW.initiator_user_id
      AND (
        (target_user_id = NEW.target_user_id AND NEW.target_user_id IS NOT NULL) OR
        (target_lobby_id = NEW.target_lobby_id AND NEW.target_lobby_id IS NOT NULL)
        )
      AND interaction_type = NEW.interaction_type
      AND status IN ('pending', 'declined');

    IF FOUND THEN
        RAISE EXCEPTION 'Cannot create record: identical % already exists in % state',
            NEW.interaction_type, existing_record.status;
    END IF;

    -- Check for reciprocal invite/request to auto-accept
    IF NEW.interaction_type = 'request' AND NEW.target_lobby_id IS NOT NULL THEN
        -- Look for pending invite from anyone to this user for this specific lobby
        SELECT *
        INTO existing_record
        FROM lobby_befriend_record lbr
        WHERE lbr.target_user_id = NEW.initiator_user_id
          AND lbr.target_lobby_id = NEW.target_lobby_id
          AND lbr.interaction_type = 'invite'
          AND lbr.status = 'pending';

        IF FOUND THEN
            -- Update existing invite to accepted instead of creating new record
            UPDATE lobby_befriend_record
            SET status     = 'accepted',
                updated_at = NOW()
            WHERE id = existing_record.id;

            -- Return NULL to cancel the insert
            RETURN NULL;
        END IF;
    END IF;

    IF NEW.interaction_type = 'invite' AND NEW.target_user_id IS NOT NULL AND NEW.target_lobby_id IS NOT NULL THEN
        -- Look for pending request from target user to this specific lobby
        SELECT *
        INTO existing_record
        FROM lobby_befriend_record lbr
        WHERE lbr.initiator_user_id = NEW.target_user_id
          AND lbr.target_lobby_id = NEW.target_lobby_id
          AND lbr.interaction_type = 'request'
          AND lbr.status = 'pending';

        IF FOUND THEN
            -- Update existing request to accepted instead of creating new record
            UPDATE lobby_befriend_record
            SET status     = 'accepted',
                updated_at = NOW()
            WHERE id = existing_record.id;

            -- Return NULL to cancel the insert
            RETURN NULL;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.lobby_befriend_record_before_insert_trigger_fn() OWNER TO postgres;

--
-- Name: lobby_can_manage(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.lobby_can_manage(p_lobby_id uuid, p_user_id uuid DEFAULT auth.uid()) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.lobby l
        WHERE l.id = p_lobby_id AND l.captain_id = p_user_id
    ) OR EXISTS (
        SELECT 1 FROM public.lobby_member lm
        WHERE lm.lobby_id = p_lobby_id AND lm.user_id = p_user_id AND lm.role = 'coordinator'
    );
$$;


ALTER FUNCTION public.lobby_can_manage(p_lobby_id uuid, p_user_id uuid) OWNER TO postgres;

--
-- Name: lobby_challenge_data(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.lobby_challenge_data(p_lobby_id uuid) RETURNS TABLE(id uuid, direction text, other_lobby_id uuid, other_lobby_name text, other_lobby_mmr integer, sport_id bigint, status public.lobby_challenge_status, proposed_time timestamp with time zone, proposed_location_name text, agreed_cost numeric, note text, activity_id uuid, referee_booked boolean, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    SET search_path TO ''
    AS $$
    SELECT c.id,
           CASE WHEN c.target_lobby_id = p_lobby_id THEN 'incoming' ELSE 'outgoing' END,
           CASE WHEN c.target_lobby_id = p_lobby_id THEN c.initiator_lobby_id ELSE c.target_lobby_id END,
           ol.name, ol.mmr, c.sport_id, c.status, c.proposed_time,
           loc.name::text, c.agreed_cost, c.note,
           mine.id,
           EXISTS (SELECT 1 FROM public.activity a2
                    WHERE a2.challenge_id = c.id AND a2.referee_booking_id IS NOT NULL),
           c.created_at
    FROM public.lobby_challenge c
    JOIN public.lobby ol
        ON ol.id = CASE WHEN c.target_lobby_id = p_lobby_id
                        THEN c.initiator_lobby_id ELSE c.target_lobby_id END
    LEFT JOIN public.location loc ON loc.id = c.proposed_location
    LEFT JOIN public.activity mine
        ON mine.challenge_id = c.id AND mine.lobby_id = p_lobby_id
    WHERE (c.initiator_lobby_id = p_lobby_id OR c.target_lobby_id = p_lobby_id)
      AND c.status IN ('requested', 'accepted', 'scheduled')
    ORDER BY c.created_at DESC;
$$;


ALTER FUNCTION public.lobby_challenge_data(p_lobby_id uuid) OWNER TO postgres;

--
-- Name: lobby_feed_data(uuid, integer, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.lobby_feed_data(p_lobby_id uuid, p_page_size integer DEFAULT 50, p_before timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS TABLE(id uuid, author_id uuid, author_username character varying, kind public.lobby_feed_item_kind, payload jsonb, created_at timestamp with time zone, poll_tallies jsonb, my_vote integer, payment_payees jsonb, author_generated_avatar text, activity_id uuid)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
RETURN QUERY SELECT * FROM (
    SELECT fi.id,fi.author_id,u.username,fi.kind,fi.payload,fi.created_at,
      CASE WHEN fi.kind='poll' THEN (SELECT jsonb_object_agg(option_index::text,c)
        FROM (SELECT option_index,count(*) c FROM public.lobby_feed_poll_vote v
          WHERE v.feed_item_id=fi.id GROUP BY option_index)t) END,
      CASE WHEN fi.kind='poll' THEN (SELECT v.option_index FROM public.lobby_feed_poll_vote v
        WHERE v.feed_item_id=fi.id AND v.user_id=auth.uid()) END,
      CASE WHEN fi.kind='payment_request' THEN (SELECT jsonb_agg(jsonb_build_object(
        'user_id',pr.user_id,'username',pu.username,'generated_avatar',pu.details->>'generatedAvatar',
        'amount_owed',pr.amount_owed,'status',pr.status::text,'paid',pr.status<>'outstanding'
      ) ORDER BY pu.username,pr.user_id)
        FROM public.lobby_payment_request_payee pr JOIN public."user" pu ON pu.id=pr.user_id
        WHERE pr.feed_item_id=fi.id) END,
      u.details->>'generatedAvatar',fi.activity_id
    FROM public.lobby_feed_item fi LEFT JOIN public."user" u ON u.id=fi.author_id
    WHERE fi.lobby_id=p_lobby_id AND fi.kind<>'photo'
      AND (p_before IS NULL OR fi.created_at<p_before)
    UNION ALL
    SELECT p.id,p.author_id,au.username,'photo'::public.lobby_feed_item_kind,
      jsonb_build_object(
        'id',p.id,'author_id',p.author_id,'author_username',au.username,
        'author_tag_number',au.tag_number,'author_details',au.details,
        'sport_id',p.sport_id,'lobby_id',p.lobby_id,'source_label',p.source_label,
        'source_start_time',p.source_start_time,'source_venue_name',p.source_venue_name,
        'caption',p.caption,'media',p.media,'created_at',p.created_at,'expires_at',p.expires_at,
        'tags',COALESCE((SELECT jsonb_agg(jsonb_build_object(
          'user_id',tu.id,'username',tu.username,'tag_number',tu.tag_number))
          FROM public.wall_post_tag t JOIN public."user" tu ON tu.id=t.user_id
          WHERE t.post_id=p.id),'[]'::jsonb),
        'reactions',COALESCE((SELECT jsonb_object_agg(r.emoji,r.n)
          FROM (SELECT emoji,count(*) n FROM public.wall_post_reaction
            WHERE post_id=p.id GROUP BY emoji)r),'{}'::jsonb),
        'my_reactions',COALESCE((SELECT jsonb_agg(r.emoji ORDER BY r.created_at)
          FROM public.wall_post_reaction r WHERE r.post_id=p.id AND r.user_id=auth.uid()),'[]'::jsonb)
      ),p.created_at,NULL::jsonb,NULL::integer,NULL::jsonb,
      au.details->>'generatedAvatar',NULL::uuid
    FROM public.wall_post p JOIN public."user" au ON au.id=p.author_id
    WHERE p.lobby_id=p_lobby_id AND p.hidden_at IS NULL AND p.expires_at>now()
      AND (p_before IS NULL OR p.created_at<p_before)
) merged ORDER BY merged.created_at DESC LIMIT p_page_size;
END;
$$;


ALTER FUNCTION public.lobby_feed_data(p_lobby_id uuid, p_page_size integer, p_before timestamp with time zone) OWNER TO postgres;

--
-- Name: lobby_match_history_data(uuid, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.lobby_match_history_data(p_lobby_id uuid, p_page_size integer DEFAULT 50, p_page_number integer DEFAULT 1) RETURNS TABLE(id uuid, activity_id uuid, opponent_lobby_id uuid, opponent_name text, opponent_tag text, result public.lobby_match_result, sets jsonb, mvp_username character varying, note text, venue_label text, played_at timestamp with time zone, duration_label text, member_usernames text[], referee_booking_id uuid, referee_name text)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    RETURN QUERY
    WITH mine AS (
        SELECT m.*, false AS flipped, m.opponent_lobby_id AS other_id
          FROM public.lobby_match m
         WHERE m.lobby_id = p_lobby_id
        UNION ALL
        SELECT m.*, true AS flipped, m.lobby_id AS other_id
          FROM public.lobby_match m
         WHERE m.opponent_lobby_id = p_lobby_id
    )
    SELECT x.id,
           x.activity_id,
           x.other_id AS opponent_lobby_id,
           ol.name::text AS opponent_name,
           (CASE WHEN x.flipped THEN COALESCE(ol.name, x.opponent_tag) ELSE x.opponent_tag END)::text,
           CASE WHEN NOT x.flipped THEN x.result
                WHEN x.result = 'win'  THEN 'loss'::public.lobby_match_result
                WHEN x.result = 'loss' THEN 'win'::public.lobby_match_result
                ELSE x.result END AS result,
           CASE WHEN NOT x.flipped OR x.sets IS NULL THEN x.sets
                ELSE (SELECT jsonb_agg(jsonb_build_array(s->1, s->0))
                        FROM jsonb_array_elements(x.sets) s) END AS sets,
           u.username AS mvp_username,
           x.note,
           x.venue_label,
           x.played_at,
           x.duration_label,
           ARRAY(
               SELECT mu.username::text
                 FROM public.lobby_member lm
                 JOIN public."user" mu ON mu.id = lm.user_id
                WHERE lm.lobby_id = p_lobby_id
           ) AS member_usernames,
           x.referee_booking_id,
           ref.display_name AS referee_name
      FROM mine x
      LEFT JOIN public.lobby ol ON ol.id = x.other_id
      LEFT JOIN public."user" u ON u.id = x.mvp_user_id
      LEFT JOIN public.referee_booking rb ON rb.id = x.referee_booking_id
      LEFT JOIN public.professional ref ON ref.id = rb.professional_id
     ORDER BY x.played_at DESC
     LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
END;
$$;


ALTER FUNCTION public.lobby_match_history_data(p_lobby_id uuid, p_page_size integer, p_page_number integer) OWNER TO postgres;

--
-- Name: lobby_match_referee_role_check(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.lobby_match_referee_role_check() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
    booked_role public.professional_role;
BEGIN
    IF NEW.referee_booking_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT p.professional_role
        INTO booked_role
        FROM public.referee_booking pb
                 JOIN public.professional p ON p.id = pb.professional_id
        WHERE pb.id = NEW.referee_booking_id;

    IF booked_role IS DISTINCT FROM 'referee' THEN
        RAISE EXCEPTION
            'lobby_match.referee_booking_id must reference a booking whose professional is a referee (got: %)',
            booked_role;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.lobby_match_referee_role_check() OWNER TO postgres;

--
-- Name: lobby_member_prevent_captain_leave(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.lobby_member_prevent_captain_leave() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
    v_captain_id     uuid;
    v_being_deleted  text;
BEGIN
    SELECT captain_id
        INTO v_captain_id
        FROM public.lobby
        WHERE id = OLD.lobby_id;

    -- Lobby is already gone (e.g. a different cascade path) — let the
    -- delete through.
    IF v_captain_id IS NULL THEN
        RETURN OLD;
    END IF;

    -- Non-captain leaving: always OK.
    IF v_captain_id <> OLD.user_id THEN
        RETURN OLD;
    END IF;

    -- Captain leaving: only allowed when the lobby itself is being
    -- deleted in this same transaction (signal set by lobby_before_delete).
    v_being_deleted := current_setting('app.lobby_being_deleted', true);
    IF v_being_deleted = OLD.lobby_id::text THEN
        RETURN OLD;
    END IF;

    RAISE EXCEPTION
        'Captain cannot leave lobby % — transfer captaincy first', OLD.lobby_id;
END;
$$;


ALTER FUNCTION public.lobby_member_prevent_captain_leave() OWNER TO postgres;

--
-- Name: lobby_money_data(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.lobby_money_data(p_lobby_id uuid) RETURNS TABLE(counterparty_id uuid, username text, generated_avatar text, signed_total numeric, entries jsonb)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid();
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    IF p_lobby_id NOT IN (SELECT public.get_my_lobby_ids()) THEN RAISE EXCEPTION 'not a lobby member'; END IF;
    RETURN QUERY
    WITH relevant AS (
        SELECT pr.id obligation_id,fi.id source_feed_item_id,fi.activity_id source_activity_id,
               COALESCE(a.start_time,fi.created_at) source_date,
               CASE WHEN pr.user_id=v_uid THEN pr.recipient_id ELSE pr.user_id END other_id,
               CASE WHEN pr.user_id=v_uid THEN -pr.amount_owed ELSE pr.amount_owed END signed_amount
          FROM public.lobby_payment_request_payee pr
          JOIN public.lobby_feed_item fi ON fi.id=pr.feed_item_id
          LEFT JOIN public.activity a ON a.id=fi.activity_id
         WHERE fi.lobby_id=p_lobby_id AND pr.status='outstanding'
           AND (pr.user_id=v_uid OR pr.recipient_id=v_uid)
    )
    SELECT r.other_id,u.username::text,u.details->>'generatedAvatar',SUM(r.signed_amount),
           jsonb_agg(jsonb_build_object(
               'obligation_id',r.obligation_id,'feed_item_id',r.source_feed_item_id,
               'activity_id',r.source_activity_id,'activity_date',r.source_date,
               'signed_amount',r.signed_amount
           ) ORDER BY r.source_date,r.obligation_id)
      FROM relevant r JOIN public."user" u ON u.id=r.other_id
     GROUP BY r.other_id,u.username,u.details->>'generatedAvatar'
     ORDER BY u.username;
END;
$$;


ALTER FUNCTION public.lobby_money_data(p_lobby_id uuid) OWNER TO postgres;

--
-- Name: mark_conversation_read(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.mark_conversation_read(p_conversation_id uuid) RETURNS void
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO ''
    AS $$
  UPDATE public.conversation_member
  SET last_read_at = now()
  WHERE conversation_id = p_conversation_id AND user_id = auth.uid();
$$;


ALTER FUNCTION public.mark_conversation_read(p_conversation_id uuid) OWNER TO postgres;

--
-- Name: mark_payment_request_paid(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.mark_payment_request_paid(p_feed_item_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_uid uuid:=auth.uid(); v_status public.lobby_payment_status; v_payload jsonb;
    v_lobby_id uuid; v_activity_id uuid; v_recipient uuid;
    v_total_payees int; v_total_resolved int;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    SELECT pr.status INTO v_status FROM public.lobby_payment_request_payee pr
     WHERE pr.feed_item_id=p_feed_item_id AND pr.user_id=v_uid FOR UPDATE;
    IF v_status IS NULL THEN RAISE EXCEPTION 'not a payer on this request'; END IF;
    IF v_status='paid_direct' THEN RETURN; END IF;
    IF v_status<>'outstanding' THEN RAISE EXCEPTION 'payment was already cleared together'; END IF;

    UPDATE public.lobby_payment_request_payee SET status='paid_direct',paid_at=now()
     WHERE feed_item_id=p_feed_item_id AND user_id=v_uid;
    INSERT INTO public.lobby_feed_item_reaction(feed_item_id,user_id,emoji)
    VALUES(p_feed_item_id,v_uid,'✅') ON CONFLICT(feed_item_id,user_id) DO NOTHING;

    SELECT count(*),count(*) FILTER(WHERE status<>'outstanding')
      INTO v_total_payees,v_total_resolved FROM public.lobby_payment_request_payee
     WHERE feed_item_id=p_feed_item_id;
    IF v_total_payees>0 AND v_total_resolved>=v_total_payees THEN
        SELECT payload,lobby_id,activity_id INTO v_payload,v_lobby_id,v_activity_id
          FROM public.lobby_feed_item WHERE id=p_feed_item_id;
        v_recipient:=(v_payload->>'recipient_id')::uuid;
        IF v_recipient IS NOT NULL THEN
            PERFORM public.fn_enqueue_notification('debt_collected',ARRAY[v_recipient],
                'Đã thu đủ tiền','Mọi người đã xác nhận thanh toán',
                jsonb_build_object('lobby_id',v_lobby_id,'feed_item_id',p_feed_item_id,'activity_id',v_activity_id));
        END IF;
    END IF;
END;
$$;


ALTER FUNCTION public.mark_payment_request_paid(p_feed_item_id uuid) OWNER TO postgres;

--
-- Name: message_coach(uuid, bigint, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.message_coach(p_professional_id uuid, p_sport_id bigint, p_body text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_course uuid; v_coach uuid; v_conversation uuid;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;

  SELECT p.linked_user_id INTO v_coach FROM public.professional p
  WHERE p.id = p_professional_id AND p.professional_role = 'coach';
  IF NOT FOUND THEN RAISE EXCEPTION 'coach not found'; END IF;
  IF v_coach = v_uid THEN RAISE EXCEPTION 'cannot coach yourself'; END IF;
  IF v_coach IS NOT NULL AND public.fn_is_blocked(v_uid, v_coach) THEN
    RAISE EXCEPTION 'not allowed';
  END IF;

  SELECT m.course_id INTO v_course FROM public.course_member m
  WHERE m.user_id = v_uid AND m.professional_id = p_professional_id
    AND m.sport_id = p_sport_id AND m.status IN ('inquiring','enrolled');

  IF v_course IS NULL THEN
    INSERT INTO public.course(professional_id, sport_id)
    VALUES (p_professional_id, p_sport_id) RETURNING id INTO v_course;

    INSERT INTO public.conversation(kind, course_id) VALUES ('course', v_course)
    RETURNING id INTO v_conversation;

    IF v_coach IS NOT NULL THEN
      INSERT INTO public.conversation_member(conversation_id, user_id)
      VALUES (v_conversation, v_coach);
    END IF;
    PERFORM public.fn_course_add_member(v_course, v_uid, 'inquiring');
  ELSE
    SELECT c.id INTO v_conversation FROM public.conversation c WHERE c.course_id = v_course;
  END IF;

  PERFORM public.send_message(v_conversation, p_body);

  RETURN v_course;
END
$$;


ALTER FUNCTION public.message_coach(p_professional_id uuid, p_sport_id bigint, p_body text) OWNER TO postgres;

--
-- Name: my_courses_data(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.my_courses_data() RETURNS TABLE(course_id uuid, conversation_id uuid, name text, status text, member_status text, professional_id uuid, coach_name text, coach_avatar text, coach_user_id uuid, sport_id bigint, target_session_count integer, held_session_count integer, next_activity_id uuid, next_start_time timestamp with time zone, last_message_at timestamp with time zone, last_message_body text, last_message_kind text, last_message_payload jsonb, unread_count integer, pending_offer_id uuid, pending_rsvp_count integer)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT c.id, conv.id, c.name, c.status::text, m.status::text,
         c.professional_id, p.display_name, cu.details->>'generatedAvatar',
         p.linked_user_id,
         c.sport_id, c.target_session_count, public.fn_course_held_sessions(c.id),
         nxt.id, nxt.start_time,
         last_msg.created_at, last_msg.body, last_msg.kind::text, last_msg.payload,
         (SELECT count(*)::integer FROM public.message x
          WHERE x.conversation_id = conv.id
            AND x.created_at > cm.last_read_at
            AND x.created_at >= cm.joined_at
            AND (cm.left_at IS NULL OR x.created_at <= cm.left_at)),
         (SELECT o.id FROM public.course_enrollment_offer o
          WHERE o.course_id = c.id AND o.user_id = m.user_id AND o.status = 'pending'
          LIMIT 1),
         (SELECT count(*)::integer FROM public.activity a
          WHERE a.course_id = c.id AND a.proposal_status = 'approved'
            AND a.start_time > now()
            AND NOT EXISTS (SELECT 1 FROM public.activity_confirmation ac
                            WHERE ac.activity_id = a.id AND ac.user_id = m.user_id))
  FROM public.course_member m
  JOIN public.course c ON c.id = m.course_id
  JOIN public.professional p ON p.id = c.professional_id
  LEFT JOIN public."user" cu ON cu.id = p.linked_user_id
  LEFT JOIN public.conversation conv ON conv.course_id = c.id
  LEFT JOIN public.conversation_member cm
         ON cm.conversation_id = conv.id AND cm.user_id = m.user_id
  LEFT JOIN LATERAL (
    SELECT a.id, a.start_time FROM public.activity a
    WHERE a.course_id = c.id AND a.proposal_status = 'approved' AND a.start_time > now()
    ORDER BY a.start_time LIMIT 1
  ) nxt ON true
  LEFT JOIN LATERAL (
    SELECT x.created_at, x.body, x.kind, x.payload FROM public.message x
    WHERE x.conversation_id = conv.id
      AND x.created_at >= cm.joined_at
      AND (cm.left_at IS NULL OR x.created_at <= cm.left_at)
    ORDER BY x.created_at DESC LIMIT 1
  ) last_msg ON true
  WHERE m.user_id = auth.uid() AND m.left_at IS NULL
  ORDER BY coalesce(last_msg.created_at, c.created_at) DESC;
$$;


ALTER FUNCTION public.my_courses_data() OWNER TO postgres;

--
-- Name: my_freeplay_host(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.my_freeplay_host() RETURNS TABLE(id uuid, user_id uuid, display_name text, avatar_url text, bio text, status text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT h.id, h.user_id, h.display_name, h.avatar_url, h.bio, h.status::text
  FROM public.freeplay_host h
  WHERE h.user_id = auth.uid() AND h.status = 'active'
$$;


ALTER FUNCTION public.my_freeplay_host() OWNER TO postgres;

--
-- Name: my_schedule_data(bigint, timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.my_schedule_data(p_sport_id bigint, p_from timestamp with time zone, p_to timestamp with time zone) RETURNS TABLE(id uuid, start_time timestamp with time zone, end_time timestamp with time zone, title text, meta text, tone text, recurrence_day_of_week smallint)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid();
BEGIN
  RETURN QUERY
    SELECT a.id, a.start_time, a.end_time, l.name::text,
           COALESCE(loc.name, '')::text, 'sport'::text, a.recurrence_day_of_week
    FROM public.activity a
    JOIN public.lobby l ON l.id = a.lobby_id
    LEFT JOIN public.location loc ON loc.id = COALESCE(a.location_id, l.home_ground)
    WHERE (p_sport_id IS NULL OR a.sport_id = p_sport_id)
      AND a.lobby_id IN (SELECT lobby_id FROM public.lobby_member WHERE user_id = v_uid)
      AND a.start_time >= p_from AND a.start_time <= p_to

    UNION ALL

    SELECT a.id, a.start_time, a.end_time,
           coalesce(h.display_name, 'Xé vé')::text,
           COALESCE(loc.name, fa.venue_name, '')::text, 'freeplay'::text,
           a.recurrence_day_of_week
    FROM public.activity a
    JOIN public.freeplay_activity fa ON fa.activity_id = a.id
    LEFT JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
    LEFT JOIN public.location loc ON loc.id = a.location_id
    WHERE (p_sport_id IS NULL OR a.sport_id = p_sport_id)
      AND a.start_time >= p_from AND a.start_time <= p_to
      AND EXISTS (SELECT 1 FROM public.freeplay_request r
                  WHERE r.activity_id = a.id AND r.user_id = v_uid AND r.status = 'accepted')

    UNION ALL

    SELECT a.id, a.start_time, a.end_time,
           coalesce(c.name, p.display_name)::text,
           COALESCE(loc.name, '')::text, 'coach'::text, a.recurrence_day_of_week
    FROM public.activity a
    JOIN public.course c ON c.id = a.course_id
    JOIN public.professional p ON p.id = c.professional_id
    LEFT JOIN public.location loc ON loc.id = a.location_id
    WHERE (p_sport_id IS NULL OR a.sport_id = p_sport_id)
      AND a.proposal_status = 'approved'
      AND a.start_time >= p_from AND a.start_time <= p_to
      AND (
        EXISTS (SELECT 1 FROM public.course_member m
                WHERE m.course_id = c.id AND m.user_id = v_uid AND m.left_at IS NULL)
        OR p.linked_user_id = v_uid
      );
END
$$;


ALTER FUNCTION public.my_schedule_data(p_sport_id bigint, p_from timestamp with time zone, p_to timestamp with time zone) OWNER TO postgres;

--
-- Name: nanoid(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.nanoid(size integer DEFAULT 10, alphabet text DEFAULT '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'::text) RETURNS text
    LANGUAGE sql STABLE
    AS $$
    SELECT extensions.nanoid(size, alphabet);
$$;


ALTER FUNCTION public.nanoid(size integer, alphabet text) OWNER TO postgres;

--
-- Name: new_user_created_trigger_fn(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.new_user_created_trigger_fn() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
    insert into public.user(id, username)
    values (new.id,
            substring(split_part(new.email, '@', 1), 1, 16));
    return new;
end;
$$;


ALTER FUNCTION public.new_user_created_trigger_fn() OWNER TO postgres;

--
-- Name: post_activity_note(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.post_activity_note(p_activity_id uuid, p_note text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_uid uuid := auth.uid();
    v_lobby_id uuid;
    v_note text := btrim(p_note);
    v_feed_item_id uuid;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not authenticated';
    END IF;

    IF p_note IS NULL OR v_note = '' OR char_length(v_note) > 72 THEN
        RAISE EXCEPTION 'note must contain 1 to 72 characters'
            USING ERRCODE = '22023';
    END IF;

    SELECT a.lobby_id
      INTO v_lobby_id
      FROM public.activity a
     WHERE a.id = p_activity_id
       AND a.lobby_id IS NOT NULL;

    IF v_lobby_id IS NULL THEN
        RAISE EXCEPTION 'activity not found';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM public.lobby_member lm
         WHERE lm.lobby_id = v_lobby_id
           AND lm.user_id = v_uid
    ) THEN
        RAISE EXCEPTION 'must be a lobby member'
            USING ERRCODE = '42501';
    END IF;

    INSERT INTO public.lobby_feed_item (
        lobby_id,
        author_id,
        kind,
        activity_id,
        payload
    ) VALUES (
        v_lobby_id,
        v_uid,
        'personal',
        p_activity_id,
        jsonb_build_object('action_kind', 'note', 'detail', v_note)
    )
    RETURNING id INTO v_feed_item_id;

    RETURN v_feed_item_id;
END;
$$;


ALTER FUNCTION public.post_activity_note(p_activity_id uuid, p_note text) OWNER TO postgres;

--
-- Name: postable_activities(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.postable_activities() RETURNS TABLE(activity_id uuid, course_id uuid, sport_id bigint, lobby_id uuid, source_label text, start_time timestamp with time zone, venue_name text, already_posted boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT a.id, a.course_id, a.sport_id, a.lobby_id,
    coalesce(l.name, h.display_name, co.name, pr.display_name, 'Xé vé'),
    a.start_time, coalesce(loc.name, fa.venue_name),
    EXISTS(SELECT 1 FROM public.wall_post w
           WHERE w.activity_id = a.id AND w.author_id = auth.uid())
  FROM public.activity a
  JOIN public.activity_confirmation c
    ON c.activity_id = a.id AND c.user_id = auth.uid() AND c.attendance = 'going'
  LEFT JOIN public.lobby l ON l.id = a.lobby_id
  LEFT JOIN public.freeplay_activity fa ON fa.activity_id = a.id
  LEFT JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
  LEFT JOIN public.course co ON co.id = a.course_id
  LEFT JOIN public.professional pr ON pr.id = co.professional_id
  LEFT JOIN public.location loc ON loc.id = a.location_id
  WHERE a.start_time < now() AND a.start_time > now() - interval '7 days'
    AND (a.course_id IS NULL OR a.proposal_status = 'approved')
  ORDER BY a.start_time DESC
$$;


ALTER FUNCTION public.postable_activities() OWNER TO postgres;

--
-- Name: pro_courses_data(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pro_courses_data() RETURNS TABLE(course_id uuid, conversation_id uuid, name text, status text, sport_id bigint, student_count integer, inquiring_count integer, target_session_count integer, held_session_count integer, next_activity_id uuid, next_start_time timestamp with time zone, last_message_at timestamp with time zone, last_message_body text, last_message_kind text, last_message_payload jsonb, unread_count integer, pending_proposal_count integer, pending_report_count integer, student_name text, student_user_id uuid, student_avatar text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT c.id, conv.id, c.name, c.status::text, c.sport_id,
         (SELECT count(*)::integer FROM public.course_member m
          WHERE m.course_id = c.id AND m.status = 'enrolled'),
         (SELECT count(*)::integer FROM public.course_member m
          WHERE m.course_id = c.id AND m.status = 'inquiring'),
         c.target_session_count, public.fn_course_held_sessions(c.id),
         nxt.id, nxt.start_time,
         last_msg.created_at, last_msg.body, last_msg.kind::text, last_msg.payload,
         (SELECT count(*)::integer FROM public.message x
          WHERE x.conversation_id = conv.id
            AND x.created_at > cm.last_read_at
            AND x.created_at >= cm.joined_at),
         (SELECT count(*)::integer FROM public.activity a
          WHERE a.course_id = c.id AND a.proposal_status = 'pending'),
         (SELECT count(*)::integer
          FROM public.activity a
          JOIN public.activity_confirmation ac ON ac.activity_id = a.id
          WHERE a.course_id = c.id AND a.proposal_status = 'approved'
            AND coalesce(a.end_time, a.start_time) < now()
            AND ac.attendance = 'going'
            AND NOT EXISTS (SELECT 1 FROM public.course_session_report r
                            WHERE r.activity_id = a.id AND r.student_id = ac.user_id)),
         student.username, student.user_id, student.avatar
  FROM public.course c
  JOIN public.professional p ON p.id = c.professional_id
  LEFT JOIN public.conversation conv ON conv.course_id = c.id
  LEFT JOIN public.conversation_member cm
         ON cm.conversation_id = conv.id AND cm.user_id = auth.uid()
  LEFT JOIN LATERAL (
    SELECT a.id, a.start_time FROM public.activity a
    WHERE a.course_id = c.id AND a.proposal_status = 'approved' AND a.start_time > now()
    ORDER BY a.start_time LIMIT 1
  ) nxt ON true
  LEFT JOIN LATERAL (
    SELECT x.created_at, x.body, x.kind, x.payload FROM public.message x
    WHERE x.conversation_id = conv.id ORDER BY x.created_at DESC LIMIT 1
  ) last_msg ON true
  LEFT JOIN LATERAL (
    SELECT cu.id AS user_id, cu.username::text AS username,
           cu.details->>'generatedAvatar' AS avatar
    FROM public.course_member m
    JOIN public."user" cu ON cu.id = m.user_id
    WHERE m.course_id = c.id AND m.left_at IS NULL
    ORDER BY m.joined_at ASC
    LIMIT 1
  ) student ON true
  WHERE p.linked_user_id = auth.uid()
  ORDER BY coalesce(last_msg.created_at, c.created_at) DESC;
$$;


ALTER FUNCTION public.pro_courses_data() OWNER TO postgres;

--
-- Name: propose_course_activity(uuid, timestamp with time zone, timestamp with time zone, uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.propose_course_activity(p_course_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_location_id uuid DEFAULT NULL::uuid, p_note text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_id uuid; v_is_coach boolean; v_sport bigint;
        v_coach uuid; v_username text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.course WHERE id = p_course_id AND status = 'active') THEN
    RAISE EXCEPTION 'course is not active';
  END IF;
  v_is_coach := public.fn_is_course_coach(p_course_id, v_uid);
  IF NOT v_is_coach AND NOT public.fn_is_enrolled_course_member(p_course_id, v_uid) THEN
    RAISE EXCEPTION 'course access required';
  END IF;
  IF p_end IS NOT NULL AND p_end <= p_start THEN RAISE EXCEPTION 'invalid time range'; END IF;
  IF p_start <= now() THEN RAISE EXCEPTION 'cannot schedule in the past'; END IF;

  SELECT c.sport_id INTO v_sport FROM public.course c WHERE c.id = p_course_id;

  INSERT INTO public.activity(
    user_id, sport_id, start_time, end_time, location_id, note,
    course_id, proposed_by, proposal_status)
  VALUES (v_uid, v_sport, p_start, p_end, p_location_id, nullif(btrim(p_note),''),
          p_course_id, v_uid,
          (CASE WHEN v_is_coach THEN 'approved' ELSE 'pending' END)
            ::public.activity_proposal_status)
  RETURNING id INTO v_id;

  SELECT u.username::text INTO v_username FROM public."user" u WHERE u.id = v_uid;

  IF v_is_coach THEN
    PERFORM public.fn_course_system_message(p_course_id, 'activity_scheduled',
      jsonb_build_object('activity_id', v_id));
    PERFORM public.fn_enqueue_notification('course_activity_approved',
      (SELECT array_agg(m.user_id) FROM public.course_member m
       WHERE m.course_id = p_course_id AND m.status = 'enrolled'),
      'Buổi tập mới', 'Huấn luyện viên đã đặt lịch một buổi tập.',
      jsonb_build_object('course_id', p_course_id, 'activity_id', v_id));
  ELSE
    PERFORM public.fn_course_system_message(p_course_id, 'activity_proposed',
      jsonb_build_object('activity_id', v_id, 'username', v_username));
    SELECT p.linked_user_id INTO v_coach FROM public.professional p
    JOIN public.course c ON c.professional_id = p.id WHERE c.id = p_course_id;
    IF v_coach IS NOT NULL THEN
      PERFORM public.fn_enqueue_notification('course_activity_proposed', ARRAY[v_coach],
        'Đề xuất buổi tập', coalesce(v_username,'') || ' đề xuất một buổi tập.',
        jsonb_build_object('course_id', p_course_id, 'activity_id', v_id));
    END IF;
  END IF;

  RETURN v_id;
END
$$;


ALTER FUNCTION public.propose_course_activity(p_course_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_location_id uuid, p_note text) OWNER TO postgres;

--
-- Name: react_to_wall_post(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.react_to_wall_post(p_post_id uuid, p_emoji text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
    IF auth.uid() IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    IF p_emoji IS NULL OR char_length(p_emoji) NOT BETWEEN 1 AND 8 THEN
        RAISE EXCEPTION 'reaction emoji must be 1-8 characters';
    END IF;
    IF NOT public.fn_can_see_wall_post(p_post_id) THEN
        RAISE EXCEPTION 'post not visible';
    END IF;

    DELETE FROM public.wall_post_reaction
    WHERE post_id = p_post_id
      AND user_id = auth.uid()
      AND emoji = p_emoji;

    IF NOT FOUND THEN
        INSERT INTO public.wall_post_reaction (post_id, user_id, emoji)
        VALUES (p_post_id, auth.uid(), p_emoji);
    END IF;
END;
$$;


ALTER FUNCTION public.react_to_wall_post(p_post_id uuid, p_emoji text) OWNER TO postgres;

--
-- Name: record_challenge_match(uuid, text, jsonb, uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.record_challenge_match(p_challenge_id uuid, p_result text, p_sets jsonb DEFAULT NULL::jsonb, p_mvp_user_id uuid DEFAULT NULL::uuid, p_note text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_uid        uuid := auth.uid();
    v_home       uuid;
    v_away       uuid;
    v_status     public.lobby_challenge_status;
    v_home_act   uuid;
    v_end        timestamptz;
    v_start      timestamptz;
    v_ref_book   uuid;
    v_venue      text;
    v_match      uuid;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    IF p_result NOT IN ('win', 'loss', 'draw') THEN
        RAISE EXCEPTION 'invalid result %', p_result;
    END IF;

    SELECT target_lobby_id, initiator_lobby_id, status
      INTO v_home, v_away, v_status
      FROM public.lobby_challenge WHERE id = p_challenge_id;
    IF v_home IS NULL THEN RAISE EXCEPTION 'challenge not found'; END IF;
    IF v_status = 'played' THEN RAISE EXCEPTION 'this match already has a result'; END IF;
    IF v_status NOT IN ('accepted', 'scheduled') THEN
        RAISE EXCEPTION 'challenge is not in a playable state';
    END IF;

    SELECT a.id, a.start_time, a.end_time, a.referee_booking_id
      INTO v_home_act, v_start, v_end, v_ref_book
      FROM public.activity a
     WHERE a.challenge_id = p_challenge_id AND a.lobby_id = v_home;

    IF v_ref_book IS NULL THEN
        SELECT a.referee_booking_id INTO v_ref_book
          FROM public.activity a
         WHERE a.challenge_id = p_challenge_id AND a.lobby_id = v_away
           AND a.referee_booking_id IS NOT NULL;
    END IF;
    IF v_ref_book IS NULL THEN
        RAISE EXCEPTION 'no referee is booked for this match';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM public.referee_booking pb
          JOIN public.professional pr ON pr.id = pb.professional_id
         WHERE pb.id = v_ref_book AND pr.linked_user_id = v_uid
    ) THEN
        RAISE EXCEPTION 'only the booked referee can record this result';
    END IF;

    IF COALESCE(v_end, v_start) > now() THEN
        RAISE EXCEPTION 'the match has not finished yet';
    END IF;

    SELECT loc.name INTO v_venue
      FROM public.activity a
      LEFT JOIN public.location loc ON loc.id = a.location_id
     WHERE a.id = v_home_act;

    INSERT INTO public.lobby_match
        (lobby_id, activity_id, opponent_lobby_id, opponent_tag, result, sets,
         mvp_user_id, note, venue_label, played_at, referee_booking_id)
    VALUES (v_home, v_home_act, v_away,
            COALESCE((SELECT name FROM public.lobby WHERE id = v_away), '—'),
            p_result::public.lobby_match_result, p_sets,
            p_mvp_user_id, p_note, COALESCE(v_venue, '—'),
            COALESCE(v_start, now()), v_ref_book)
    RETURNING id INTO v_match;

    UPDATE public.lobby_challenge
       SET status = 'played', updated_at = now() WHERE id = p_challenge_id;

    PERFORM public.fn_enqueue_notification(
        'match_result_recorded',
        ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = v_home),
        'Kết quả trận đấu',
        'Trọng tài đã ghi nhận kết quả trận thách đấu',
        jsonb_build_object('lobby_id', v_home, 'challenge_id', p_challenge_id));
    PERFORM public.fn_enqueue_notification(
        'match_result_recorded',
        ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = v_away),
        'Kết quả trận đấu',
        'Trọng tài đã ghi nhận kết quả trận thách đấu',
        jsonb_build_object('lobby_id', v_away, 'challenge_id', p_challenge_id));

    RETURN v_match;
END;
$$;


ALTER FUNCTION public.record_challenge_match(p_challenge_id uuid, p_result text, p_sets jsonb, p_mvp_user_id uuid, p_note text) OWNER TO postgres;

--
-- Name: redeem_lobby_invite_link(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.redeem_lobby_invite_link(p_code text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_uid  uuid := auth.uid();
    v_link record;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT lil.*, l.name AS lobby_name
      INTO v_link
      FROM public.lobby_invite_link lil
      JOIN public.lobby l ON l.id = lil.lobby_id
     WHERE lil.code = p_code;

    IF v_link IS NULL THEN
        RETURN jsonb_build_object('status', 'invalid', 'reason', 'not_found');
    ELSIF v_link.revoked_at IS NOT NULL THEN
        RETURN jsonb_build_object('status', 'invalid', 'reason', 'revoked');
    ELSIF v_link.expires_at IS NOT NULL AND v_link.expires_at <= now() THEN
        RETURN jsonb_build_object('status', 'invalid', 'reason', 'expired');
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.lobby_member lm
        WHERE lm.lobby_id = v_link.lobby_id AND lm.user_id = v_uid
    ) THEN
        RETURN jsonb_build_object(
            'status', 'already_member',
            'lobby_id', v_link.lobby_id,
            'lobby_name', v_link.lobby_name
        );
    END IF;

    INSERT INTO public.lobby_member (user_id, lobby_id) VALUES (v_uid, v_link.lobby_id);

    UPDATE public.lobby_invite_link
       SET use_count = use_count + 1
     WHERE id = v_link.id;

    RETURN jsonb_build_object(
        'status', 'joined',
        'lobby_id', v_link.lobby_id,
        'lobby_name', v_link.lobby_name
    );
END;
$$;


ALTER FUNCTION public.redeem_lobby_invite_link(p_code text) OWNER TO postgres;

--
-- Name: referee_booking_conflicts(uuid, timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.referee_booking_conflicts(p_professional_id uuid, p_start timestamp with time zone, p_end timestamp with time zone) RETURNS TABLE(id uuid, booking_time_start timestamp with time zone, booking_time_end timestamp with time zone)
    LANGUAGE sql STABLE
    SET search_path TO ''
    AS $$
    SELECT pb.id, pb.booking_time_start, pb.booking_time_end
    FROM public.referee_booking pb
    WHERE pb.professional_id = p_professional_id
      AND pb.status = 'confirmed'
      AND pb.booking_time_start < p_end
      AND pb.booking_time_end > p_start;
$$;


ALTER FUNCTION public.referee_booking_conflicts(p_professional_id uuid, p_start timestamp with time zone, p_end timestamp with time zone) OWNER TO postgres;

--
-- Name: referee_booking_review_updated_trigger_fn(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.referee_booking_review_updated_trigger_fn() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        UPDATE public.professional
        SET
            average_rating = (
                SELECT COALESCE(AVG(rating), 0.00)
                FROM public.referee_booking_review
                WHERE professional_id = NEW.professional_id
            ),
            review_count = (
                SELECT COUNT(*)
                FROM public.referee_booking_review
                WHERE professional_id = NEW.professional_id
            )
        WHERE id = NEW.professional_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.professional
        SET
            average_rating = (
                SELECT COALESCE(AVG(rating), 0.00)
                FROM public.referee_booking_review
                WHERE professional_id = OLD.professional_id
            ),
            review_count = (
                SELECT COUNT(*)
                FROM public.referee_booking_review
                WHERE professional_id = OLD.professional_id
            )
        WHERE id = OLD.professional_id;
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.referee_booking_review_updated_trigger_fn() OWNER TO postgres;

--
-- Name: register_device_token(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.register_device_token(p_fcm_token text, p_platform text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    if (select auth.uid()) is null then
        raise exception 'register_device_token: not authenticated';
    end if;
    if p_platform not in ('ios', 'android') then
        raise exception 'register_device_token: bad platform %', p_platform;
    end if;
    insert into public.user_device_token (fcm_token, user_id, platform, updated_at)
    values (p_fcm_token, (select auth.uid()), p_platform, now())
    on conflict (fcm_token) do update
        set user_id    = excluded.user_id,
            platform   = excluded.platform,
            updated_at = now();
end;
$$;


ALTER FUNCTION public.register_device_token(p_fcm_token text, p_platform text) OWNER TO postgres;

--
-- Name: reject_referee_booking(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reject_referee_booking(p_booking_id uuid, p_reason text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_booking record;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'reject_referee_booking: authentication required';
    END IF;

    SELECT pb.professional_id, pb.status
    INTO v_booking
    FROM public.referee_booking pb
    WHERE pb.id = p_booking_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'reject_referee_booking: booking % not found', p_booking_id;
    END IF;
    IF NOT EXISTS (
        SELECT 1
        FROM public.professional p
        WHERE p.id = v_booking.professional_id
          AND p.linked_user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'reject_referee_booking: caller is not the linked professional';
    END IF;
    IF v_booking.status <> 'requested' THEN
        RAISE EXCEPTION 'reject_referee_booking: request is no longer actionable';
    END IF;

    UPDATE public.referee_booking
    SET status = 'rejected',
        professional_notes = NULLIF(btrim(p_reason), '')
    WHERE id = p_booking_id;
END;
$$;


ALTER FUNCTION public.reject_referee_booking(p_booking_id uuid, p_reason text) OWNER TO postgres;

--
-- Name: remove_course_member(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.remove_course_member(p_course_id uuid, p_user_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_username text; v_was_enrolled boolean;
BEGIN
  IF NOT public.fn_is_course_coach(p_course_id, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;

  SELECT (m.status = 'enrolled') INTO v_was_enrolled FROM public.course_member m
  WHERE m.course_id = p_course_id AND m.user_id = p_user_id AND m.left_at IS NULL;

  UPDATE public.course_member SET status = 'removed', left_at = now()
  WHERE course_id = p_course_id AND user_id = p_user_id AND left_at IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'membership not found'; END IF;

  UPDATE public.conversation_member SET left_at = now()
  WHERE user_id = p_user_id
    AND conversation_id = (SELECT id FROM public.conversation WHERE course_id = p_course_id);

  SELECT u.username::text INTO v_username FROM public."user" u WHERE u.id = p_user_id;
  PERFORM public.fn_course_system_message(p_course_id, 'member_removed',
    jsonb_build_object('username', v_username));
  PERFORM public.fn_enqueue_notification('course_member_removed', ARRAY[p_user_id],
    'Bạn đã rời khoá học', 'Huấn luyện viên đã kết thúc khoá học với bạn.',
    jsonb_build_object('course_id', p_course_id));

  PERFORM public.fn_course_prompt_if_no_students(p_course_id, coalesce(v_was_enrolled, false));
END
$$;


ALTER FUNCTION public.remove_course_member(p_course_id uuid, p_user_id uuid) OWNER TO postgres;

--
-- Name: request_freeplay_seat(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.request_freeplay_seat(p_activity_id uuid, p_message text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid:=auth.uid(); v_row record; v_gender text; v_skill text; v_id uuid;
        v_count integer; v_conversation uuid;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;
  SELECT a.sport_id,a.end_time,fa.capacity,fa.male_price,fa.female_price,fa.intake_closed_at,fa.cancelled_at,
    h.user_id host_user_id INTO v_row
  FROM public.activity a JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id AND h.status='active'
  WHERE a.id=p_activity_id FOR UPDATE OF fa;
  IF NOT FOUND OR v_row.cancelled_at IS NOT NULL OR v_row.end_time<=now() OR v_row.intake_closed_at IS NOT NULL THEN
    RAISE EXCEPTION 'activity is not accepting requests';
  END IF;
  IF v_uid=v_row.host_user_id OR public.fn_is_blocked(v_uid,v_row.host_user_id) THEN RAISE EXCEPTION 'request not allowed'; END IF;
  IF EXISTS(SELECT 1 FROM public.freeplay_request WHERE activity_id=p_activity_id AND user_id=v_uid AND status='declined') THEN
    RAISE EXCEPTION 'declined request is terminal';
  END IF;
  IF EXISTS(SELECT 1 FROM public.freeplay_request WHERE activity_id=p_activity_id AND user_id=v_uid AND status IN ('pending','accepted')) THEN
    RAISE EXCEPTION 'active request already exists';
  END IF;
  SELECT count(*) INTO v_count FROM public.freeplay_request WHERE activity_id=p_activity_id AND status='accepted';
  IF v_count>=v_row.capacity THEN RAISE EXCEPTION 'activity is full'; END IF;
  SELECT coalesce(details->>'gender','male') INTO v_gender FROM public."user" WHERE id=v_uid;
  IF v_gender NOT IN ('male','female') THEN v_gender:='male'; END IF;
  v_skill:=public.freeplay_user_skill(v_uid,v_row.sport_id);
  INSERT INTO public.freeplay_request(activity_id,user_id,price_amount,gender,skill)
  VALUES(p_activity_id,v_uid,CASE WHEN v_gender='female' THEN v_row.female_price ELSE v_row.male_price END,v_gender,v_skill)
  RETURNING id INTO v_id;

  v_conversation := public.fn_ensure_freeplay_conversation(v_id);
  IF nullif(btrim(p_message),'') IS NOT NULL THEN
    INSERT INTO public.message(conversation_id,sender_id,kind,body)
    VALUES(v_conversation,v_uid,'text',btrim(p_message));
  END IF;

  PERFORM public.fn_enqueue_notification('freeplay_request_received',ARRAY[v_row.host_user_id],
    'Yêu cầu Xé vé mới','Có người muốn tham gia buổi chơi của bạn.',
    jsonb_build_object('activity_id',p_activity_id,'request_id',v_id));
  RETURN v_id;
END
$$;


ALTER FUNCTION public.request_freeplay_seat(p_activity_id uuid, p_message text) OWNER TO postgres;

--
-- Name: request_referee_booking(uuid, uuid, timestamp with time zone, timestamp with time zone, text, uuid, uuid[], uuid, boolean, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.request_referee_booking(p_professional_id uuid, p_service_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_notes text DEFAULT NULL::text, p_location_id uuid DEFAULT NULL::uuid, p_participant_user_ids uuid[] DEFAULT '{}'::uuid[], p_existing_package_id uuid DEFAULT NULL::uuid, p_create_package boolean DEFAULT false, p_activity_id uuid DEFAULT NULL::uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_uid uuid := auth.uid();
    v_role public.professional_role;
    v_linked_user_id uuid;
    v_sports bigint[];
    v_service_sport bigint;
    v_price_amount numeric;
    v_pricing_kind text;
    v_min_duration integer;
    v_max_participants integer;
    v_session_count integer;
    v_participants uuid[] := COALESCE(p_participant_user_ids, '{}'::uuid[]);
    v_participant_count integer;
    v_agreed_rate numeric(10, 2);
    v_package_total numeric(10, 2);
    v_package_id uuid := p_existing_package_id;
    v_package record;
    v_booking_id uuid;
    v_activity record;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'request_referee_booking: authentication required';
    END IF;
    IF p_end <= p_start THEN
        RAISE EXCEPTION 'request_referee_booking: end must be after start';
    END IF;
    IF p_start <= now() THEN
        RAISE EXCEPTION 'request_referee_booking: start must be in the future';
    END IF;

    SELECT p.professional_role, p.linked_user_id, p.sports,
           s.sport_id, s.price_amount, s.pricing_kind,
           s.min_duration_minutes, COALESCE(s.max_participants, 1),
           s.session_count
    INTO v_role, v_linked_user_id, v_sports,
         v_service_sport, v_price_amount, v_pricing_kind,
         v_min_duration, v_max_participants, v_session_count
    FROM public.professional_service s
    JOIN public.professional p ON p.id = s.professional_id
    WHERE s.id = p_service_id
      AND s.professional_id = p_professional_id
      AND s.is_active
      AND p.is_verified;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'request_referee_booking: service is unavailable';
    END IF;
    IF v_linked_user_id = v_uid THEN
        RAISE EXCEPTION 'request_referee_booking: professionals cannot book themselves';
    END IF;
    IF NOT (v_sports @> ARRAY[v_service_sport]::bigint[]) THEN
        RAISE EXCEPTION 'request_referee_booking: service sport is not offered by professional';
    END IF;
    IF v_min_duration IS NOT NULL
       AND p_end - p_start < make_interval(mins => v_min_duration) THEN
        RAISE EXCEPTION 'request_referee_booking: duration is below service minimum';
    END IF;
    IF p_location_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM public.location location WHERE location.id = p_location_id
    ) THEN
        RAISE EXCEPTION 'request_referee_booking: location not found';
    END IF;
    IF v_role <> 'referee' THEN
        RAISE EXCEPTION 'request_referee_booking: only referees can be booked';
    END IF;

    IF cardinality(v_participants) <> (
        SELECT count(DISTINCT participant.participant_id)
        FROM unnest(v_participants) AS participant(participant_id)
    ) THEN
        RAISE EXCEPTION 'request_referee_booking: duplicate participants';
    END IF;
    IF v_uid = ANY(v_participants) THEN
        RAISE EXCEPTION 'request_referee_booking: client cannot be an additional participant';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM unnest(v_participants) AS participant(participant_id)
        LEFT JOIN public."user" u ON u.id = participant.participant_id
        WHERE u.id IS NULL
    ) THEN
        RAISE EXCEPTION 'request_referee_booking: participant not found';
    END IF;

    v_participant_count := cardinality(v_participants) + 1;
    IF v_participant_count > v_max_participants THEN
        RAISE EXCEPTION 'request_referee_booking: participant limit exceeded';
    END IF;

    IF v_price_amount IS NOT NULL THEN
        v_agreed_rate := CASE v_pricing_kind
            WHEN 'hourly' THEN round(
                v_price_amount * (extract(epoch FROM (p_end - p_start)) / 3600.0),
                2
            )
            WHEN 'per_session' THEN v_price_amount
            ELSE NULL
        END;
        v_package_total := round(v_agreed_rate * v_session_count, 2);
    END IF;

    IF v_package_id IS NOT NULL OR p_create_package THEN
        RAISE EXCEPTION 'request_referee_booking: packages are not supported';
    END IF;

    INSERT INTO public.referee_booking (
        client_user_id, professional_id, service_id, location_id,
        booking_time_start, booking_time_end,
        agreed_rate, status, client_notes
    ) VALUES (
        v_uid, p_professional_id, p_service_id, p_location_id,
        p_start, p_end,
        v_agreed_rate, 'requested', NULLIF(btrim(p_notes), '')
    )
    RETURNING id INTO v_booking_id;

    IF cardinality(v_participants) > 0 THEN
        INSERT INTO public.referee_booking_additional_users (booking_id, user_id)
        SELECT v_booking_id, participant.participant_id
        FROM unnest(v_participants) AS participant(participant_id);
    END IF;

    IF p_activity_id IS NOT NULL THEN
        SELECT a.id, a.lobby_id, a.sport_id, a.referee_booking_id
        INTO v_activity
        FROM public.activity a
        WHERE a.id = p_activity_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'request_referee_booking: activity not found';
        END IF;
        IF v_activity.lobby_id IS NULL
           OR NOT public.lobby_can_manage(v_activity.lobby_id) THEN
            RAISE EXCEPTION 'request_referee_booking: caller cannot manage activity';
        END IF;
        IF v_activity.sport_id <> v_service_sport THEN
            RAISE EXCEPTION 'request_referee_booking: activity sport does not match service';
        END IF;

        IF v_activity.referee_booking_id IS NOT NULL THEN
            RAISE EXCEPTION 'request_referee_booking: activity already has a referee booking';
        END IF;
        UPDATE public.activity
        SET referee_booking_id = v_booking_id
        WHERE id = p_activity_id;
    END IF;

    RETURN v_booking_id;
END;
$$;


ALTER FUNCTION public.request_referee_booking(p_professional_id uuid, p_service_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_notes text, p_location_id uuid, p_participant_user_ids uuid[], p_existing_package_id uuid, p_create_package boolean, p_activity_id uuid) OWNER TO postgres;

--
-- Name: reschedule_course_activity(uuid, timestamp with time zone, timestamp with time zone, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reschedule_course_activity(p_activity_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_location_id uuid DEFAULT NULL::uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_course uuid;
BEGIN
  SELECT a.course_id INTO v_course FROM public.activity a
  WHERE a.id = p_activity_id AND a.proposal_status = 'approved' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'approved session not found'; END IF;
  IF NOT public.fn_is_course_coach(v_course, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;
  IF p_end IS NOT NULL AND p_end <= p_start THEN RAISE EXCEPTION 'invalid time range'; END IF;

  UPDATE public.activity
  SET start_time = p_start, end_time = p_end,
      location_id = coalesce(p_location_id, location_id)
  WHERE id = p_activity_id;

  DELETE FROM public.activity_confirmation WHERE activity_id = p_activity_id;

  PERFORM public.fn_course_system_message(v_course, 'activity_rescheduled',
    jsonb_build_object('activity_id', p_activity_id));
  PERFORM public.fn_enqueue_notification('course_activity_changed',
    (SELECT array_agg(m.user_id) FROM public.course_member m
     WHERE m.course_id = v_course AND m.status = 'enrolled'),
    'Buổi tập đổi giờ', 'Huấn luyện viên đã dời buổi tập.',
    jsonb_build_object('course_id', v_course, 'activity_id', p_activity_id));
END
$$;


ALTER FUNCTION public.reschedule_course_activity(p_activity_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_location_id uuid) OWNER TO postgres;

--
-- Name: resolve_at_risk_activity_organizer(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.resolve_at_risk_activity_organizer(p_activity_id uuid, p_action text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_uid              uuid := auth.uid();
    v_lobby_id         uuid;
    v_lobby_name       text;
    v_at_risk          timestamptz;
    v_override         timestamptz;
    v_going_recipients uuid[];
BEGIN
    IF p_action NOT IN ('confirm', 'cancel') THEN
        RAISE EXCEPTION 'resolve_at_risk_activity_organizer: invalid action %', p_action;
    END IF;

    SELECT a.lobby_id, a.at_risk_notified_at, a.threshold_override_at
        INTO v_lobby_id, v_at_risk, v_override
        FROM public.activity a WHERE a.id = p_activity_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'resolve_at_risk_activity_organizer: activity not found';
    END IF;
    IF v_at_risk IS NULL OR v_override IS NOT NULL THEN
        RAISE EXCEPTION 'resolve_at_risk_activity_organizer: activity is not awaiting resolution';
    END IF;
    IF NOT public.lobby_can_manage(v_lobby_id, v_uid) THEN
        RAISE EXCEPTION 'resolve_at_risk_activity_organizer: caller cannot manage this lobby';
    END IF;

    SELECT name INTO v_lobby_name FROM public.lobby WHERE id = v_lobby_id;

    IF p_action = 'confirm' THEN
        UPDATE public.activity SET threshold_override_at = now() WHERE id = p_activity_id;

        INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
        VALUES (v_lobby_id, v_uid, 'update',
            jsonb_build_object(
                'title', 'Đã xác nhận dù chưa đủ người',
                'kind',  'threshold_confirmed',
                'tone',  'blue',
                'fields', jsonb_build_array()));
    ELSE
        SELECT array_agg(DISTINCT ac.user_id) INTO v_going_recipients
            FROM public.activity_confirmation ac
            WHERE ac.activity_id = p_activity_id AND ac.attendance = 'going';

        DELETE FROM public.activity WHERE id = p_activity_id;

        INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
        VALUES (v_lobby_id, v_uid, 'update',
            jsonb_build_object(
                'title', 'Đã hủy buổi chơi',
                'kind',  'cancelled',
                'tone',  'crimson',
                'fields', jsonb_build_array()));

        IF v_going_recipients IS NOT NULL THEN
            PERFORM public.fn_enqueue_notification(
                'activity_cancelled_low_turnout',
                v_going_recipients,
                'Buổi chơi đã bị hủy',
                COALESCE(v_lobby_name, 'Lobby') || ' đã hủy buổi chơi do không đủ người xác nhận',
                jsonb_build_object('lobby_id', v_lobby_id::text));
        END IF;
    END IF;
END;
$$;


ALTER FUNCTION public.resolve_at_risk_activity_organizer(p_activity_id uuid, p_action text) OWNER TO postgres;

--
-- Name: resolve_at_risk_activity_rsvp(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.resolve_at_risk_activity_rsvp(p_activity_id uuid, p_attendance text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_uid      uuid := auth.uid();
    v_lobby_id uuid;
    v_at_risk  timestamptz;
    v_override timestamptz;
    v_current  text;
BEGIN
    IF p_attendance NOT IN ('going', 'out') THEN
        RAISE EXCEPTION 'resolve_at_risk_activity_rsvp: invalid attendance %', p_attendance;
    END IF;

    SELECT a.lobby_id, a.at_risk_notified_at, a.threshold_override_at
        INTO v_lobby_id, v_at_risk, v_override
        FROM public.activity a WHERE a.id = p_activity_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'resolve_at_risk_activity_rsvp: activity not found';
    END IF;
    IF v_at_risk IS NULL OR v_override IS NOT NULL THEN
        RAISE EXCEPTION 'resolve_at_risk_activity_rsvp: activity is not awaiting resolution';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM public.lobby_member lm
        WHERE lm.lobby_id = v_lobby_id AND lm.user_id = v_uid
    ) THEN
        RAISE EXCEPTION 'resolve_at_risk_activity_rsvp: caller is not a lobby member';
    END IF;

    SELECT attendance::text INTO v_current
        FROM public.activity_confirmation
        WHERE activity_id = p_activity_id AND user_id = v_uid;
    IF v_current = 'out' THEN
        RAISE EXCEPTION 'resolve_at_risk_activity_rsvp: already opted out';
    END IF;

    INSERT INTO public.activity_confirmation (activity_id, user_id, attendance)
    VALUES (p_activity_id, v_uid, p_attendance::public.activity_attendance)
    ON CONFLICT (activity_id, user_id) DO UPDATE SET attendance = excluded.attendance;
END;
$$;


ALTER FUNCTION public.resolve_at_risk_activity_rsvp(p_activity_id uuid, p_attendance text) OWNER TO postgres;

--
-- Name: respond_challenge(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.respond_challenge(p_challenge_id uuid, p_action text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    c_match_minutes constant integer := 90;
    v_uid         uuid := auth.uid();
    v_init        uuid;
    v_target      uuid;
    v_status      public.lobby_challenge_status;
    v_sport       bigint;
    v_time        timestamptz;
    v_loc         uuid;
    v_cost        numeric;
    v_target_name text;
    v_init_name   text;
    v_recipients  uuid[];
    v_deadline    timestamptz;
    v_end         timestamptz;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;

    SELECT initiator_lobby_id, target_lobby_id, status, sport_id,
           proposed_time, proposed_location, agreed_cost
      INTO v_init, v_target, v_status, v_sport, v_time, v_loc, v_cost
      FROM public.lobby_challenge WHERE id = p_challenge_id;

    IF v_init IS NULL THEN RAISE EXCEPTION 'challenge not found'; END IF;
    IF NOT public.lobby_can_manage(v_target, v_uid) THEN
        RAISE EXCEPTION 'not a manager of the target lobby';
    END IF;
    IF v_status <> 'requested' THEN RAISE EXCEPTION 'challenge is no longer open'; END IF;

    SELECT name INTO v_target_name FROM public.lobby WHERE id = v_target;
    SELECT name INTO v_init_name   FROM public.lobby WHERE id = v_init;

    IF p_action = 'accept' THEN
        IF v_time <= now() THEN RAISE EXCEPTION 'that kickoff has already passed'; END IF;

        v_end := v_time + make_interval(mins => c_match_minutes);
        v_deadline := GREATEST(v_time - interval '2 days', now() + interval '1 hour');
        IF v_deadline >= v_time THEN
            v_deadline := v_time - interval '1 minute';
        END IF;

        UPDATE public.lobby_challenge
            SET status = 'accepted', updated_at = now() WHERE id = p_challenge_id;

        INSERT INTO public.activity
            (user_id, sport_id, lobby_id, challenge_id, start_time, end_time, location_id,
             prepayment_required, payment_type, prepayment_amount,
             confirmation_threshold, confirmation_deadline)
        SELECT l.captain_id, v_sport, l.id, p_challenge_id, v_time, v_end, v_loc,
               (COALESCE(v_cost, 0) > 0),
               CASE WHEN COALESCE(v_cost, 0) > 0 THEN 'manual'::public.activity_payment_type END,
               CASE WHEN COALESCE(v_cost, 0) > 0 THEN v_cost END,
               GREATEST(2, ceil(l.member_count / 2.0)::integer),
               v_deadline
          FROM public.lobby l
         WHERE l.id IN (v_init, v_target);

        UPDATE public.lobby
           SET open_to_challengers    = false,
               challenge_offer_time     = NULL,
               challenge_offer_location = NULL,
               challenge_offer_cost     = NULL
         WHERE id = v_target;

        UPDATE public.lobby_challenge
           SET status = 'declined', updated_at = now()
         WHERE target_lobby_id = v_target
           AND status = 'requested'
           AND id <> p_challenge_id;

        SELECT array_agg(user_id) INTO v_recipients
            FROM public.lobby_member WHERE lobby_id = v_init;
        PERFORM public.fn_enqueue_notification(
            'challenger_confirmed', v_recipients,
            'Thách đấu được chấp nhận',
            COALESCE(v_target_name, 'Đối thủ') || ' đã chấp nhận lời thách đấu',
            jsonb_build_object('lobby_id', v_init, 'challenge_id', p_challenge_id));

        INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
        SELECT l.id, l.captain_id, 'update',
               jsonb_build_object(
                   'title', 'Trận thách đấu',
                   'kind',  'scheduled',
                   'tone',  'blue',
                   'fields', jsonb_build_array(
                       jsonb_build_array('Đối thủ',
                           CASE WHEN l.id = v_target THEN COALESCE(v_init_name, '—')
                                ELSE COALESCE(v_target_name, '—') END),
                       jsonb_build_array('Sân', COALESCE(
                           (SELECT loc.name FROM public.location loc WHERE loc.id = v_loc), '—'))
                   ))
          FROM public.lobby l
         WHERE l.id IN (v_init, v_target);

    ELSIF p_action = 'decline' THEN
        UPDATE public.lobby_challenge
            SET status = 'declined', updated_at = now() WHERE id = p_challenge_id;
        SELECT array_agg(uid) INTO v_recipients FROM (
            SELECT captain_id AS uid FROM public.lobby WHERE id = v_init
            UNION
            SELECT user_id FROM public.lobby_member
                WHERE lobby_id = v_init AND role = 'coordinator'
        ) s;
        PERFORM public.fn_enqueue_notification(
            'challenge_declined', v_recipients,
            'Thách đấu bị từ chối',
            COALESCE(v_target_name, 'Đối thủ') || ' đã từ chối lời thách đấu',
            jsonb_build_object('lobby_id', v_init, 'challenge_id', p_challenge_id));
    ELSE
        RAISE EXCEPTION 'invalid action %', p_action;
    END IF;
END;
$$;


ALTER FUNCTION public.respond_challenge(p_challenge_id uuid, p_action text) OWNER TO postgres;

--
-- Name: respond_course_proposal(uuid, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.respond_course_proposal(p_activity_id uuid, p_approve boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_course uuid; v_proposer uuid;
BEGIN
  SELECT a.course_id, a.proposed_by INTO v_course, v_proposer
  FROM public.activity a
  WHERE a.id = p_activity_id AND a.proposal_status = 'pending' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'pending proposal not found'; END IF;
  IF NOT public.fn_is_course_coach(v_course, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;

  UPDATE public.activity
  SET proposal_status = (CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END)
        ::public.activity_proposal_status
  WHERE id = p_activity_id;

  PERFORM public.fn_course_system_message(v_course,
    CASE WHEN p_approve THEN 'activity_approved' ELSE 'activity_rejected' END,
    jsonb_build_object('activity_id', p_activity_id));

  IF p_approve THEN
    PERFORM public.fn_enqueue_notification('course_activity_approved',
      (SELECT array_agg(m.user_id) FROM public.course_member m
       WHERE m.course_id = v_course AND m.status = 'enrolled'),
      'Buổi tập đã được duyệt', 'Đề xuất buổi tập đã được duyệt.',
      jsonb_build_object('course_id', v_course, 'activity_id', p_activity_id));
  ELSIF v_proposer IS NOT NULL THEN
    PERFORM public.fn_enqueue_notification('course_activity_changed', ARRAY[v_proposer],
      'Đề xuất bị từ chối', 'Huấn luyện viên đã từ chối đề xuất của bạn.',
      jsonb_build_object('course_id', v_course, 'activity_id', p_activity_id));
  END IF;
END
$$;


ALTER FUNCTION public.respond_course_proposal(p_activity_id uuid, p_approve boolean) OWNER TO postgres;

--
-- Name: respond_enrollment_offer(uuid, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.respond_enrollment_offer(p_offer_id uuid, p_accept boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_offer record; v_coach uuid; v_username text;
BEGIN
  SELECT o.*, c.professional_id, c.sport_id INTO v_offer
  FROM public.course_enrollment_offer o
  JOIN public.course c ON c.id = o.course_id
  WHERE o.id = p_offer_id AND o.user_id = v_uid AND o.status = 'pending'
  FOR UPDATE OF o;
  IF NOT FOUND THEN RAISE EXCEPTION 'pending offer not found'; END IF;

  IF NOT p_accept THEN
    UPDATE public.course_enrollment_offer
    SET status = 'declined', responded_at = now() WHERE id = p_offer_id;
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.course_member m
    WHERE m.user_id = v_uid AND m.sport_id = v_offer.sport_id
      AND m.status = 'enrolled' AND m.course_id <> v_offer.course_id
  ) THEN
    RAISE EXCEPTION 'already enrolled with a coach for this sport';
  END IF;

  UPDATE public.course_enrollment_offer
  SET status = 'accepted', responded_at = now() WHERE id = p_offer_id;

  UPDATE public.course_member SET status = 'enrolled'
  WHERE course_id = v_offer.course_id AND user_id = v_uid;

  UPDATE public.course SET
    name = coalesce(name, v_offer.name),
    description = coalesce(description, v_offer.description),
    target_session_count = coalesce(target_session_count, v_offer.target_session_count)
  WHERE id = v_offer.course_id;

  SELECT u.username::text INTO v_username FROM public."user" u WHERE u.id = v_uid;
  PERFORM public.fn_course_system_message(v_offer.course_id, 'enrollment_accepted',
    jsonb_build_object('username', v_username));

  SELECT p.linked_user_id INTO v_coach FROM public.professional p
  WHERE p.id = v_offer.professional_id;
  IF v_coach IS NOT NULL THEN
    PERFORM public.fn_enqueue_notification('course_enrollment_accepted', ARRAY[v_coach],
      'Học viên đã tham gia', coalesce(v_username,'') || ' đã tham gia khoá học.',
      jsonb_build_object('course_id', v_offer.course_id));
  END IF;
END
$$;


ALTER FUNCTION public.respond_enrollment_offer(p_offer_id uuid, p_accept boolean) OWNER TO postgres;

--
-- Name: respond_freeplay_request(uuid, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.respond_freeplay_request(p_request_id uuid, p_accept boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid:=auth.uid(); v_row record; v_count integer; v_conversation uuid;
BEGIN
  SELECT r.*,fa.capacity,a.end_time,h.user_id host_user_id INTO v_row
  FROM public.freeplay_request r JOIN public.freeplay_activity fa ON fa.activity_id=r.activity_id
  JOIN public.activity a ON a.id=r.activity_id JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE r.id=p_request_id AND h.user_id=v_uid FOR UPDATE OF r,fa;
  IF NOT FOUND OR v_row.status<>'pending' THEN RAISE EXCEPTION 'pending request not found'; END IF;
  IF v_row.end_time<=now() THEN RAISE EXCEPTION 'activity ended'; END IF;
  v_conversation := public.fn_ensure_freeplay_conversation(p_request_id);
  IF p_accept THEN
    SELECT count(*) INTO v_count FROM public.freeplay_request WHERE activity_id=v_row.activity_id AND status='accepted';
    IF v_count>=v_row.capacity THEN RAISE EXCEPTION 'activity is full'; END IF;
    UPDATE public.freeplay_request SET status='accepted',resolved_at=now(),updated_at=now() WHERE id=p_request_id;
    INSERT INTO public.activity_confirmation(activity_id,user_id,attendance)
    VALUES(v_row.activity_id,v_row.user_id,'going') ON CONFLICT(activity_id,user_id)
    DO UPDATE SET attendance='going',confirmed_at=now();
    INSERT INTO public.message(conversation_id,kind,body)
    VALUES(v_conversation,'system','request_accepted');
    PERFORM public.fn_enqueue_notification('freeplay_request_accepted',ARRAY[v_row.user_id],
      'Đã nhận chỗ Xé vé','Host đã duyệt yêu cầu của bạn.',jsonb_build_object('activity_id',v_row.activity_id,'request_id',p_request_id));
  ELSE
    UPDATE public.freeplay_request SET status='declined',resolved_at=now(),updated_at=now() WHERE id=p_request_id;
    INSERT INTO public.message(conversation_id,kind,body)
    VALUES(v_conversation,'system','request_declined');
    PERFORM public.fn_enqueue_notification('freeplay_request_declined',ARRAY[v_row.user_id],
      'Yêu cầu Xé vé bị từ chối','Host đã từ chối yêu cầu của bạn.',jsonb_build_object('activity_id',v_row.activity_id,'request_id',p_request_id));
  END IF;
END
$$;


ALTER FUNCTION public.respond_freeplay_request(p_request_id uuid, p_accept boolean) OWNER TO postgres;

--
-- Name: respond_friend_request(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.respond_friend_request(p_friendship_id uuid, p_action text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_uid       uuid := auth.uid();
    v_requester uuid;
    v_addressee uuid;
    v_status    public.friendship_status;
    v_label     text;
begin
    if v_uid is null then raise exception 'not authenticated'; end if;

    select requester_id, addressee_id, status
        into v_requester, v_addressee, v_status
        from public.friendship where id = p_friendship_id;

    if v_requester is null then raise exception 'request not found'; end if;
    if v_addressee <> v_uid then raise exception 'not yours to answer'; end if;
    if v_status <> 'pending' then raise exception 'request is no longer open'; end if;

    if p_action = 'accept' then
        update public.friendship
            set status = 'accepted', responded_at = now()
            where id = p_friendship_id;

        select u.username || '#' || u.tag_number into v_label
            from public."user" u where u.id = v_uid;

        perform public.fn_enqueue_notification(
            'friend_accepted',
            array[v_requester],
            'Đã thành bạn bè',
            coalesce(v_label, 'Một người chơi') || ' đã chấp nhận lời mời kết bạn',
            jsonb_build_object('user_id', v_uid::text));
    elsif p_action = 'decline' then
        update public.friendship
            set status = 'declined', responded_at = now()
            where id = p_friendship_id;
    else
        raise exception 'invalid action %', p_action;
    end if;
end;
$$;


ALTER FUNCTION public.respond_friend_request(p_friendship_id uuid, p_action text) OWNER TO postgres;

--
-- Name: revoke_lobby_invite_link(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.revoke_lobby_invite_link(p_lobby_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
    IF NOT public.lobby_can_manage(p_lobby_id, auth.uid()) THEN
        RAISE EXCEPTION 'Not authorized to manage this lobby';
    END IF;

    UPDATE public.lobby_invite_link
       SET revoked_at = now()
     WHERE lobby_id = p_lobby_id AND revoked_at IS NULL;
END;
$$;


ALTER FUNCTION public.revoke_lobby_invite_link(p_lobby_id uuid) OWNER TO postgres;

--
-- Name: search_locations(text, character varying[], bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.search_locations(search_term text, p_districts character varying[] DEFAULT NULL::character varying[], p_city_cluster bigint DEFAULT NULL::bigint) RETURNS TABLE(id uuid, name text, full_address text, street_number text, street_name text, district text, city text, lat double precision, lon double precision, tags text[], city_cluster bigint)
    LANGUAGE plpgsql STABLE
    SET search_path TO ''
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        l.id,
        l.name,
        l.full_address,
        l.street_number,
        l.street_name,
        l.district,
        l.city,
        l.lat,
        l.lon,
        l.tags,
        l.city_cluster
    FROM public.location l
    WHERE
        (p_city_cluster IS NULL OR l.city_cluster = p_city_cluster)
        AND (
            (
                char_length(search_term) >= 8 AND (
                    extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.name))) > 0.3
                    OR extensions.word_similarity(LOWER(search_term), LOWER(l.name)) > 0.3
                    OR extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.full_address))) > 0.3
                    OR extensions.word_similarity(LOWER(search_term), LOWER(l.full_address)) > 0.3
                )
            )
            OR (
                char_length(search_term) >= 2 AND (
                    extensions.unaccent(LOWER(l.name)) LIKE '%' || extensions.unaccent(LOWER(search_term)) || '%'
                    OR extensions.unaccent(LOWER(COALESCE(l.full_address, ''))) LIKE '%' || extensions.unaccent(LOWER(search_term)) || '%'
                )
            )
            OR (p_districts IS NOT NULL AND cardinality(p_districts) > 0 AND l.district = ANY(p_districts))
        )
    ORDER BY
        GREATEST(
            extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.name))),
            extensions.word_similarity(LOWER(search_term), LOWER(l.name)),
            extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.full_address))),
            extensions.word_similarity(LOWER(search_term), LOWER(l.full_address))
        ) DESC,
        l.name ASC
    LIMIT 60;
END;
$$;


ALTER FUNCTION public.search_locations(search_term text, p_districts character varying[], p_city_cluster bigint) OWNER TO postgres;

--
-- Name: search_networks_unaccent(text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.search_networks_unaccent(search_term text, result_limit integer DEFAULT 20) RETURNS TABLE(id bigint, name text, category text, city text)
    LANGUAGE sql
    SET search_path TO ''
    AS $$
SELECT
    n.id,
    n.name,
    n.category,
    scc.name AS city
FROM public.network n
JOIN public.supported_city_cluster scc on n.city = scc.id
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


ALTER FUNCTION public.search_networks_unaccent(search_term text, result_limit integer) OWNER TO postgres;

--
-- Name: search_networks_unaccent(text, integer, bigint[], text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.search_networks_unaccent(search_term text, result_limit integer DEFAULT 20, filter_cities bigint[] DEFAULT NULL::bigint[], filter_categories text[] DEFAULT NULL::text[]) RETURNS TABLE(id bigint, name text, category text, city bigint)
    LANGUAGE sql
    SET search_path TO ''
    AS $$
SELECT
    n.id,
    n.name,
    n.category, n.city
FROM public.network n
WHERE
    char_length(search_term) >= 3
    AND (
        extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(n.name))) > 0.3
        OR extensions.word_similarity(LOWER(search_term), LOWER(n.name)) > 0.3
    )
    AND (coalesce(cardinality(filter_cities), 0) = 0 OR n.city = ANY(filter_cities))
    AND (coalesce(cardinality(filter_categories), 0) = 0 OR n.category = ANY(filter_categories))
ORDER BY
    greatest(
        extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(n.name))),
        extensions.word_similarity(LOWER(search_term), LOWER(n.name))
    ) DESC,
    n.name
LIMIT result_limit;
$$;


ALTER FUNCTION public.search_networks_unaccent(search_term text, result_limit integer, filter_cities bigint[], filter_categories text[]) OWNER TO postgres;

--
-- Name: seeded_sport_id(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.seeded_sport_id(p_user_id uuid) RETURNS bigint
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT sport_id FROM (
    SELECT 1 AS sport_id FROM public.soccer_profile WHERE user_id = p_user_id AND elo_seed IS NOT NULL
    UNION ALL
    SELECT 2 FROM public.basketball_profile WHERE user_id = p_user_id AND elo_seed IS NOT NULL
    UNION ALL
    SELECT 3 FROM public.badminton_profile WHERE user_id = p_user_id AND elo_seed IS NOT NULL
    UNION ALL
    SELECT 4 FROM public.tennis_profile WHERE user_id = p_user_id AND elo_seed IS NOT NULL
    UNION ALL
    SELECT 5 FROM public.pickleball_profile WHERE user_id = p_user_id AND elo_seed IS NOT NULL
  ) seeded
  LIMIT 1;
$$;


ALTER FUNCTION public.seeded_sport_id(p_user_id uuid) OWNER TO postgres;

--
-- Name: send_challenge(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.send_challenge(p_initiator_lobby uuid, p_target_lobby uuid, p_note text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_uid          uuid := auth.uid();
    v_sport        bigint;
    v_target_open  boolean;
    v_target_sport bigint;
    v_offer_time   timestamptz;
    v_offer_loc    uuid;
    v_offer_cost   numeric;
    v_id           uuid;
    v_recipients   uuid[];
    v_init_name    text;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    IF p_initiator_lobby = p_target_lobby THEN
        RAISE EXCEPTION 'cannot challenge your own lobby';
    END IF;
    IF NOT public.lobby_can_manage(p_initiator_lobby, v_uid) THEN
        RAISE EXCEPTION 'not a manager of the initiating lobby';
    END IF;

    SELECT sport_id INTO v_sport FROM public.lobby WHERE id = p_initiator_lobby;
    SELECT open_to_challengers, sport_id,
           challenge_offer_time, challenge_offer_location, challenge_offer_cost
      INTO v_target_open, v_target_sport, v_offer_time, v_offer_loc, v_offer_cost
      FROM public.lobby WHERE id = p_target_lobby;

    IF v_target_sport IS NULL THEN RAISE EXCEPTION 'target lobby not found'; END IF;
    IF v_sport IS DISTINCT FROM v_target_sport THEN RAISE EXCEPTION 'sport mismatch'; END IF;
    IF NOT COALESCE(v_target_open, false) THEN
        RAISE EXCEPTION 'target lobby is not open to challengers';
    END IF;
    IF v_offer_time <= now() THEN
        RAISE EXCEPTION 'that offer has expired';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.lobby_challenge
        WHERE initiator_lobby_id = p_initiator_lobby
          AND target_lobby_id = p_target_lobby
          AND status = 'requested'
    ) THEN
        RAISE EXCEPTION 'a challenge is already pending for this lobby';
    END IF;

    INSERT INTO public.lobby_challenge
        (initiator_lobby_id, target_lobby_id, sport_id,
         proposed_time, proposed_location, agreed_cost, note)
    VALUES (p_initiator_lobby, p_target_lobby, v_sport,
            v_offer_time, v_offer_loc, v_offer_cost, p_note)
    RETURNING id INTO v_id;

    SELECT array_agg(uid) INTO v_recipients FROM (
        SELECT captain_id AS uid FROM public.lobby WHERE id = p_target_lobby
        UNION
        SELECT user_id FROM public.lobby_member
            WHERE lobby_id = p_target_lobby AND role = 'coordinator'
    ) s;

    SELECT name INTO v_init_name FROM public.lobby WHERE id = p_initiator_lobby;

    PERFORM public.fn_enqueue_notification(
        'challenge_received',
        v_recipients,
        'Lời thách đấu mới',
        COALESCE(v_init_name, 'Một đội') || ' muốn thách đấu với bạn',
        jsonb_build_object('lobby_id', p_target_lobby, 'challenge_id', v_id)
    );

    RETURN v_id;
END;
$$;


ALTER FUNCTION public.send_challenge(p_initiator_lobby uuid, p_target_lobby uuid, p_note text) OWNER TO postgres;

--
-- Name: send_enrollment_offer(uuid, uuid, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.send_enrollment_offer(p_course_id uuid, p_user_id uuid, p_name text, p_description text DEFAULT NULL::text, p_target_session_count integer DEFAULT NULL::integer) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_id uuid;
BEGIN
  IF NOT public.fn_is_course_coach(p_course_id, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.course WHERE id = p_course_id AND status = 'active') THEN
    RAISE EXCEPTION 'course is not active';
  END IF;
  IF nullif(btrim(p_name),'') IS NULL THEN RAISE EXCEPTION 'name required'; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.course_member m
    WHERE m.course_id = p_course_id AND m.user_id = p_user_id AND m.left_at IS NULL
  ) THEN
    PERFORM public.fn_course_add_member(p_course_id, p_user_id, 'inquiring');
  END IF;

  INSERT INTO public.course_enrollment_offer(
    course_id, user_id, name, description, target_session_count)
  VALUES (p_course_id, p_user_id, btrim(p_name), p_description, p_target_session_count)
  RETURNING id INTO v_id;

  PERFORM public.fn_enqueue_notification('course_enrollment_offer', ARRAY[p_user_id],
    'Lời mời tham gia khoá học', btrim(p_name),
    jsonb_build_object('course_id', p_course_id, 'offer_id', v_id));
  RETURN v_id;
END
$$;


ALTER FUNCTION public.send_enrollment_offer(p_course_id uuid, p_user_id uuid, p_name text, p_description text, p_target_session_count integer) OWNER TO postgres;

--
-- Name: send_friend_request(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.send_friend_request(p_user_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_uid    uuid := auth.uid();
    v_id     uuid;
    v_status public.friendship_status;
    v_owner  uuid;
    v_label  text;
begin
    if v_uid is null then raise exception 'not authenticated'; end if;
    if p_user_id is null then raise exception 'no target user'; end if;
    if p_user_id = v_uid then raise exception 'cannot befriend yourself'; end if;
    if not exists (select 1 from public."user" u where u.id = p_user_id) then
        raise exception 'user not found';
    end if;
    if public.fn_is_blocked(v_uid, p_user_id) then
        raise exception 'blocked';
    end if;

    select id, status, requester_id into v_id, v_status, v_owner
        from public.friendship
        where status in ('pending', 'accepted')
          and least(requester_id, addressee_id) = least(v_uid, p_user_id)
          and greatest(requester_id, addressee_id) = greatest(v_uid, p_user_id);

    if v_status = 'accepted' then
        return v_id;
    elsif v_status = 'pending' and v_owner = v_uid then
        return v_id;
    elsif v_status = 'pending' then
        update public.friendship
            set status = 'accepted', responded_at = now()
            where id = v_id;

        select u.username || '#' || u.tag_number into v_label
            from public."user" u where u.id = v_uid;

        perform public.fn_enqueue_notification(
            'friend_accepted',
            array[p_user_id],
            'Đã thành bạn bè',
            coalesce(v_label, 'Một người chơi') || ' đã chấp nhận lời mời kết bạn',
            jsonb_build_object('user_id', v_uid::text));
        return v_id;
    end if;

    insert into public.friendship (requester_id, addressee_id)
        values (v_uid, p_user_id)
        returning id into v_id;

    select u.username || '#' || u.tag_number into v_label
        from public."user" u where u.id = v_uid;

    perform public.fn_enqueue_notification(
        'friend_request',
        array[p_user_id],
        'Lời mời kết bạn',
        coalesce(v_label, 'Một người chơi') || ' muốn kết bạn với bạn',
        jsonb_build_object('user_id', v_uid::text));

    return v_id;
end;
$$;


ALTER FUNCTION public.send_friend_request(p_user_id uuid) OWNER TO postgres;

--
-- Name: send_message(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.send_message(p_conversation_id uuid, p_body text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_id uuid; v_kind public.conversation_kind;
        v_data jsonb;
BEGIN
  IF NOT coalesce(public.fn_can_write_conversation(p_conversation_id, v_uid), false) THEN
    RAISE EXCEPTION 'chat is read-only';
  END IF;
  IF nullif(btrim(p_body),'') IS NULL OR char_length(btrim(p_body)) > 2000 THEN
    RAISE EXCEPTION 'invalid message';
  END IF;

  INSERT INTO public.message(conversation_id, sender_id, kind, body)
  VALUES (p_conversation_id, v_uid, 'text', btrim(p_body))
  RETURNING id INTO v_id;

  SELECT c.kind INTO v_kind FROM public.conversation c WHERE c.id = p_conversation_id;

  IF v_kind = 'freeplay' THEN
    SELECT jsonb_build_object('activity_id', r.activity_id, 'request_id', r.id)
    INTO v_data FROM public.freeplay_request r
    JOIN public.conversation c ON c.freeplay_request_id = r.id
    WHERE c.id = p_conversation_id;
    PERFORM public.fn_notify_new_message(p_conversation_id, v_id,
      'freeplay_chat_message', v_uid, 'Tin nhắn Xé vé mới', 'Bạn có tin nhắn mới.', v_data);
  ELSE
    SELECT jsonb_build_object('course_id', c.course_id) INTO v_data
    FROM public.conversation c WHERE c.id = p_conversation_id;
    PERFORM public.fn_notify_new_message(p_conversation_id, v_id,
      'course_message', v_uid, 'Tin nhắn mới', 'Bạn có tin nhắn mới.', v_data);
  END IF;

  RETURN v_id;
END
$$;


ALTER FUNCTION public.send_message(p_conversation_id uuid, p_body text) OWNER TO postgres;

--
-- Name: set_freeplay_intake(uuid, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_freeplay_intake(p_activity_id uuid, p_closed boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid:=auth.uid(); v_start timestamptz;
BEGIN
  SELECT a.start_time INTO v_start FROM public.activity a JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE a.id=p_activity_id AND h.user_id=v_uid;
  IF NOT FOUND THEN RAISE EXCEPTION 'activity not found or not owned'; END IF;
  IF NOT p_closed AND now()>=v_start THEN RAISE EXCEPTION 'cannot reopen after activity starts'; END IF;
  UPDATE public.freeplay_activity SET intake_closed_at=CASE WHEN p_closed THEN now() END,updated_at=now()
  WHERE activity_id=p_activity_id AND cancelled_at IS NULL;
END
$$;


ALTER FUNCTION public.set_freeplay_intake(p_activity_id uuid, p_closed boolean) OWNER TO postgres;

--
-- Name: set_lobby_challenge_offer(uuid, boolean, timestamp with time zone, uuid, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_lobby_challenge_offer(p_lobby_id uuid, p_open boolean, p_time timestamp with time zone DEFAULT NULL::timestamp with time zone, p_location uuid DEFAULT NULL::uuid, p_cost numeric DEFAULT NULL::numeric) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_uid uuid := auth.uid();
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    IF NOT public.lobby_can_manage(p_lobby_id, v_uid) THEN
        RAISE EXCEPTION 'not a manager of this lobby';
    END IF;

    IF p_open THEN
        IF p_time IS NULL OR p_location IS NULL OR p_cost IS NULL THEN
            RAISE EXCEPTION 'an open challenge offer needs a time, a location and a cost';
        END IF;
        IF p_time <= now() THEN
            RAISE EXCEPTION 'the offered kickoff is in the past';
        END IF;
        IF p_cost < 0 THEN
            RAISE EXCEPTION 'cost cannot be negative';
        END IF;

        UPDATE public.lobby
           SET open_to_challengers    = true,
               challenge_offer_time     = p_time,
               challenge_offer_location = p_location,
               challenge_offer_cost     = p_cost
         WHERE id = p_lobby_id;
    ELSE
        UPDATE public.lobby
           SET open_to_challengers    = false,
               challenge_offer_time     = NULL,
               challenge_offer_location = NULL,
               challenge_offer_cost     = NULL
         WHERE id = p_lobby_id;
    END IF;
END;
$$;


ALTER FUNCTION public.set_lobby_challenge_offer(p_lobby_id uuid, p_open boolean, p_time timestamp with time zone, p_location uuid, p_cost numeric) OWNER TO postgres;

--
-- Name: set_lobby_member_role(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_lobby_member_role(p_lobby_id uuid, p_member_user_id uuid, p_role text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.lobby WHERE id = p_lobby_id AND captain_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'set_lobby_member_role: caller is not the lobby captain';
    END IF;
    IF p_member_user_id = auth.uid() THEN
        RAISE EXCEPTION 'set_lobby_member_role: captain cannot change their own role';
    END IF;
    IF p_role NOT IN ('member', 'coordinator') THEN
        RAISE EXCEPTION 'set_lobby_member_role: invalid role %', p_role;
    END IF;

    UPDATE public.lobby_member
    SET role = p_role::public.lobby_member_role
    WHERE lobby_id = p_lobby_id AND user_id = p_member_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'set_lobby_member_role: % is not a member of this lobby', p_member_user_id;
    END IF;
END;
$$;


ALTER FUNCTION public.set_lobby_member_role(p_lobby_id uuid, p_member_user_id uuid, p_role text) OWNER TO postgres;

--
-- Name: settle_lobby_money(uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.settle_lobby_money(p_lobby_id uuid, p_counterparty_id uuid, p_idempotency_key uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_uid uuid := auth.uid();
    v_existing_id uuid;
    v_settlement_id uuid;
    v_i_owe numeric(12, 2);
    v_they_owe numeric(12, 2);
    v_payer_id uuid;
    v_recipient_id uuid;
    v_payer_gross numeric(12, 2);
    v_recipient_gross numeric(12, 2);
    v_transfer numeric(12, 2);
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not authenticated';
    END IF;
    IF p_counterparty_id IS NULL OR p_counterparty_id = v_uid THEN
        RAISE EXCEPTION 'invalid counterparty';
    END IF;
    IF p_idempotency_key IS NULL THEN
        RAISE EXCEPTION 'idempotency key is required';
    END IF;
    IF p_lobby_id NOT IN (SELECT public.get_my_lobby_ids()) THEN
        RAISE EXCEPTION 'not a lobby member';
    END IF;

    SELECT s.id INTO v_existing_id
      FROM public.lobby_payment_settlement s
     WHERE s.lobby_id = p_lobby_id
       AND s.idempotency_key = p_idempotency_key
       AND (
           s.payer_id = v_uid
           OR s.recipient_id = v_uid
       );
    IF v_existing_id IS NOT NULL THEN
        RETURN v_existing_id;
    END IF;

    -- Serialize direct confirmations and pair settlements on the same rows.
    PERFORM 1
      FROM public.lobby_payment_request_payee pr
      JOIN public.lobby_feed_item fi ON fi.id = pr.feed_item_id
     WHERE fi.lobby_id = p_lobby_id
       AND pr.status = 'outstanding'
       AND (
           (pr.user_id = v_uid AND pr.recipient_id = p_counterparty_id)
           OR
           (pr.user_id = p_counterparty_id AND pr.recipient_id = v_uid)
       )
     FOR UPDATE OF pr;

    SELECT COALESCE(SUM(pr.amount_owed) FILTER (
               WHERE pr.user_id = v_uid
                 AND pr.recipient_id = p_counterparty_id
           ), 0),
           COALESCE(SUM(pr.amount_owed) FILTER (
               WHERE pr.user_id = p_counterparty_id
                 AND pr.recipient_id = v_uid
           ), 0)
      INTO v_i_owe, v_they_owe
      FROM public.lobby_payment_request_payee pr
      JOIN public.lobby_feed_item fi ON fi.id = pr.feed_item_id
     WHERE fi.lobby_id = p_lobby_id
       AND pr.status = 'outstanding'
       AND (
           (pr.user_id = v_uid AND pr.recipient_id = p_counterparty_id)
           OR
           (pr.user_id = p_counterparty_id AND pr.recipient_id = v_uid)
       );

    IF v_i_owe = 0 AND v_they_owe = 0 THEN
        RAISE EXCEPTION 'nothing to settle';
    END IF;

    IF v_i_owe >= v_they_owe THEN
        v_payer_id := v_uid;
        v_recipient_id := p_counterparty_id;
        v_payer_gross := v_i_owe;
        v_recipient_gross := v_they_owe;
    ELSE
        v_payer_id := p_counterparty_id;
        v_recipient_id := v_uid;
        v_payer_gross := v_they_owe;
        v_recipient_gross := v_i_owe;
    END IF;
    v_transfer := v_payer_gross - v_recipient_gross;

    INSERT INTO public.lobby_payment_settlement (
        lobby_id, payer_id, recipient_id, payer_gross, recipient_gross,
        transferred_amount, idempotency_key
    ) VALUES (
        p_lobby_id, v_payer_id, v_recipient_id, v_payer_gross,
        v_recipient_gross, v_transfer, p_idempotency_key
    ) RETURNING id INTO v_settlement_id;

    INSERT INTO public.lobby_payment_settlement_item (
        settlement_id, obligation_id, source_feed_item_id,
        source_activity_id, debtor_id, recipient_id, amount
    )
    SELECT v_settlement_id, pr.id, fi.id, fi.activity_id,
           pr.user_id, pr.recipient_id, pr.amount_owed
      FROM public.lobby_payment_request_payee pr
      JOIN public.lobby_feed_item fi ON fi.id = pr.feed_item_id
     WHERE fi.lobby_id = p_lobby_id
       AND pr.status = 'outstanding'
       AND (
           (pr.user_id = v_uid AND pr.recipient_id = p_counterparty_id)
           OR
           (pr.user_id = p_counterparty_id AND pr.recipient_id = v_uid)
       );

    UPDATE public.lobby_payment_request_payee pr
       SET status = 'cleared_together',
           paid_at = now()
      FROM public.lobby_feed_item fi
     WHERE fi.id = pr.feed_item_id
       AND fi.lobby_id = p_lobby_id
       AND pr.status = 'outstanding'
       AND (
           (pr.user_id = v_uid AND pr.recipient_id = p_counterparty_id)
           OR
           (pr.user_id = p_counterparty_id AND pr.recipient_id = v_uid)
       );

    RETURN v_settlement_id;
END;
$$;


ALTER FUNCTION public.settle_lobby_money(p_lobby_id uuid, p_counterparty_id uuid, p_idempotency_key uuid) OWNER TO postgres;

--
-- Name: share_conversation_payment_info(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.share_conversation_payment_info(p_conversation_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_info uuid; v_id uuid; v_request uuid;
        v_activity uuid; v_recipient uuid;
BEGIN
  IF NOT coalesce(public.fn_can_write_conversation(p_conversation_id, v_uid), false) THEN
    RAISE EXCEPTION 'chat is read-only';
  END IF;
  SELECT i.id INTO v_info FROM public.user_payment_info i WHERE i.user_id = v_uid;
  IF v_info IS NULL THEN RAISE EXCEPTION 'payment info not configured'; END IF;

  SELECT c.freeplay_request_id INTO v_request
  FROM public.conversation c WHERE c.id = p_conversation_id AND c.kind = 'freeplay';
  IF v_request IS NULL THEN RAISE EXCEPTION 'not a freeplay conversation'; END IF;

  SELECT r.activity_id, r.user_id INTO v_activity, v_recipient
  FROM public.freeplay_request r
  JOIN public.activity a ON a.id = r.activity_id
  JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
  WHERE r.id = v_request AND h.user_id = v_uid;
  IF NOT FOUND THEN RAISE EXCEPTION 'Host access required'; END IF;

  INSERT INTO public.message(conversation_id, sender_id, kind, payment_info_id)
  VALUES (p_conversation_id, v_uid, 'payment_info', v_info)
  RETURNING id INTO v_id;

  PERFORM public.fn_enqueue_notification('freeplay_chat_message', ARRAY[v_recipient],
    'Host đã gửi thông tin thanh toán','Mở chat Xé vé để xem VietQR.',
    jsonb_build_object('activity_id',v_activity,'request_id',v_request,
                       'conversation_id',p_conversation_id));
  RETURN v_id;
END
$$;


ALTER FUNCTION public.share_conversation_payment_info(p_conversation_id uuid) OWNER TO postgres;

--
-- Name: submit_course_review(uuid, smallint, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.submit_course_review(p_course_id uuid, p_rating smallint, p_comment text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_id uuid; v_eligible boolean;
BEGIN
  IF p_rating IS NULL OR p_rating < 1 OR p_rating > 5 THEN
    RAISE EXCEPTION 'invalid rating';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.course_member m
    JOIN public.course c ON c.id = m.course_id
    WHERE m.course_id = p_course_id AND m.user_id = v_uid
      AND (c.status = 'ended' OR m.status IN ('left','removed'))
  ) INTO v_eligible;
  IF NOT v_eligible THEN RAISE EXCEPTION 'course not reviewable yet'; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.activity a
    JOIN public.activity_confirmation ac ON ac.activity_id = a.id
    WHERE a.course_id = p_course_id AND ac.user_id = v_uid
      AND ac.attendance = 'going' AND a.proposal_status = 'approved'
      AND coalesce(a.end_time, a.start_time) < now()
  ) THEN RAISE EXCEPTION 'no attended session to review'; END IF;

  IF EXISTS (
    SELECT 1 FROM public.course_review r
    WHERE r.course_id = p_course_id AND r.student_id = v_uid
  ) THEN RAISE EXCEPTION 'already reviewed'; END IF;

  INSERT INTO public.course_review(course_id, student_id, rating, comment)
  VALUES (p_course_id, v_uid, p_rating, nullif(btrim(p_comment),''))
  RETURNING id INTO v_id;
  RETURN v_id;
END
$$;


ALTER FUNCTION public.submit_course_review(p_course_id uuid, p_rating smallint, p_comment text) OWNER TO postgres;

--
-- Name: submit_session_report(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.submit_session_report(p_activity_id uuid, p_student_id uuid, p_body text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_course uuid; v_id uuid;
BEGIN
  SELECT a.course_id INTO v_course FROM public.activity a
  WHERE a.id = p_activity_id AND a.proposal_status = 'approved'
    AND coalesce(a.end_time, a.start_time) < now();
  IF NOT FOUND THEN RAISE EXCEPTION 'finished session not found'; END IF;
  IF NOT public.fn_is_course_coach(v_course, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.activity_confirmation ac
    WHERE ac.activity_id = p_activity_id AND ac.user_id = p_student_id
      AND ac.attendance = 'going'
  ) THEN RAISE EXCEPTION 'student did not attend'; END IF;
  IF nullif(btrim(p_body),'') IS NULL OR char_length(btrim(p_body)) > 1000 THEN
    RAISE EXCEPTION 'invalid report';
  END IF;

  INSERT INTO public.course_session_report(course_id, activity_id, student_id, body)
  VALUES (v_course, p_activity_id, p_student_id, btrim(p_body))
  RETURNING id INTO v_id;

  PERFORM public.fn_enqueue_notification('course_session_report', ARRAY[p_student_id],
    'Nhận xét buổi tập', 'Huấn luyện viên đã gửi nhận xét cho bạn.',
    jsonb_build_object('course_id', v_course, 'activity_id', p_activity_id));
  RETURN v_id;
END
$$;


ALTER FUNCTION public.submit_session_report(p_activity_id uuid, p_student_id uuid, p_body text) OWNER TO postgres;

--
-- Name: taggable_users(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.taggable_users(p_activity_id uuid) RETURNS TABLE(user_id uuid, username text, tag_number text, details jsonb, attended boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    v_uid uuid := auth.uid();
    v_allowed boolean;
BEGIN
    IF v_uid IS NULL OR p_activity_id IS NULL THEN
        RETURN;
    END IF;

    SELECT EXISTS(
        SELECT 1 FROM public.activity a
        JOIN public.lobby_member m ON m.lobby_id = a.lobby_id
        WHERE a.id = p_activity_id AND m.user_id = v_uid
        UNION ALL
        SELECT 1 FROM public.activity a
        JOIN public.course_member cm ON cm.course_id = a.course_id
        WHERE a.id = p_activity_id AND cm.user_id = v_uid AND cm.left_at IS NULL
        UNION ALL
        SELECT 1 FROM public.activity a
        JOIN public.course c ON c.id = a.course_id
        JOIN public.professional p ON p.id = c.professional_id
        WHERE a.id = p_activity_id AND p.linked_user_id = v_uid
    ) INTO v_allowed;

    IF NOT v_allowed THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT u.id, u.username::text, u.tag_number::text, u.details,
           bool_or(x.attended)
    FROM (
        SELECT c.user_id AS uid, true AS attended
            FROM public.activity_confirmation c
            WHERE c.activity_id = p_activity_id AND c.attendance = 'going'
        UNION ALL
        SELECT m.user_id, false
            FROM public.lobby_member m
            JOIN public.activity a ON a.lobby_id = m.lobby_id
            WHERE a.id = p_activity_id
        UNION ALL
        SELECT cm.user_id, false
            FROM public.course_member cm
            JOIN public.activity a ON a.course_id = cm.course_id
            WHERE a.id = p_activity_id AND cm.left_at IS NULL
        UNION ALL
        SELECT p.linked_user_id, true
            FROM public.activity a
            JOIN public.course c ON c.id = a.course_id
            JOIN public.professional p ON p.id = c.professional_id
            WHERE a.id = p_activity_id AND p.linked_user_id IS NOT NULL
    ) x
    JOIN public."user" u ON u.id = x.uid
    WHERE u.id <> v_uid
    GROUP BY u.id, u.username, u.tag_number, u.details
    ORDER BY bool_or(x.attended) DESC, u.username;
END;
$$;


ALTER FUNCTION public.taggable_users(p_activity_id uuid) OWNER TO postgres;

--
-- Name: transfer_lobby_captaincy(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.transfer_lobby_captaincy(p_lobby_id uuid, p_new_captain_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_captain uuid;
BEGIN
    SELECT captain_id INTO v_captain FROM public.lobby WHERE id = p_lobby_id;
    IF v_captain IS NULL THEN
        RAISE EXCEPTION 'Lobby % not found', p_lobby_id;
    END IF;
    IF v_captain <> auth.uid() THEN
        RAISE EXCEPTION 'Only the captain can transfer captaincy';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM public.lobby_member
        WHERE lobby_id = p_lobby_id AND user_id = p_new_captain_id
    ) THEN
        RAISE EXCEPTION 'New captain must be a member of the lobby';
    END IF;
    UPDATE public.lobby SET captain_id = p_new_captain_id WHERE id = p_lobby_id;
END;
$$;


ALTER FUNCTION public.transfer_lobby_captaincy(p_lobby_id uuid, p_new_captain_id uuid) OWNER TO postgres;

--
-- Name: trg_lobby_match_rated_count(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_lobby_match_rated_count() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
    IF TG_OP <> 'INSERT' THEN
        PERFORM public.fn_lobby_recompute_rated_matches(OLD.lobby_id);
        PERFORM public.fn_lobby_recompute_rated_matches(OLD.opponent_lobby_id);
    END IF;
    IF TG_OP <> 'DELETE' THEN
        PERFORM public.fn_lobby_recompute_rated_matches(NEW.lobby_id);
        PERFORM public.fn_lobby_recompute_rated_matches(NEW.opponent_lobby_id);
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION public.trg_lobby_match_rated_count() OWNER TO postgres;

--
-- Name: trg_lobby_match_rating(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_lobby_match_rating() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
    PERFORM public.fn_apply_match_rating(NEW.id);
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_lobby_match_rating() OWNER TO postgres;

--
-- Name: trg_lobby_member_recompute(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_lobby_member_recompute() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM public.fn_lobby_recompute_stats(OLD.lobby_id);
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.lobby_id IS DISTINCT FROM OLD.lobby_id THEN
            PERFORM public.fn_lobby_recompute_stats(OLD.lobby_id);
        END IF;
        PERFORM public.fn_lobby_recompute_stats(NEW.lobby_id);
        RETURN NEW;
    ELSE
        PERFORM public.fn_lobby_recompute_stats(NEW.lobby_id);
        RETURN NEW;
    END IF;
END;
$$;


ALTER FUNCTION public.trg_lobby_member_recompute() OWNER TO postgres;

--
-- Name: trg_lobby_playtime_keys(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_lobby_playtime_keys() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    NEW.playtime_keys := public.fn_lobby_playtime_keys(NEW.playtime);
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_lobby_playtime_keys() OWNER TO postgres;

--
-- Name: trg_user_affiliation_recompute(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_user_affiliation_recompute() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    r record;
    v_user uuid := COALESCE(NEW.user_id, OLD.user_id);
BEGIN
    FOR r IN
        SELECT lobby_id FROM public.lobby_member WHERE user_id = v_user
    LOOP
        PERFORM public.fn_lobby_recompute_stats(r.lobby_id);
    END LOOP;
    RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION public.trg_user_affiliation_recompute() OWNER TO postgres;

--
-- Name: trg_user_rating_recompute(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_user_rating_recompute() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    r record;
BEGIN
    IF TG_OP = 'UPDATE' AND NOT (OLD.elo IS DISTINCT FROM NEW.elo) THEN
        RETURN NEW;
    END IF;
    FOR r IN
        SELECT lm.lobby_id
        FROM public.lobby_member lm
        JOIN public.lobby l ON l.id = lm.lobby_id
        WHERE lm.user_id = NEW.user_id
          AND public.fn_sport_name(l.sport_id) = NEW.sport
    LOOP
        PERFORM public.fn_lobby_recompute_stats(r.lobby_id);
    END LOOP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_user_rating_recompute() OWNER TO postgres;

--
-- Name: unblock_user(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.unblock_user(p_user_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    if auth.uid() is null then raise exception 'not authenticated'; end if;
    delete from public.user_block
        where blocker_id = auth.uid() and blocked_id = p_user_id;
end;
$$;


ALTER FUNCTION public.unblock_user(p_user_id uuid) OWNER TO postgres;

--
-- Name: unfriend(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.unfriend(p_user_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_uid uuid := auth.uid();
begin
    if v_uid is null then raise exception 'not authenticated'; end if;

    update public.friendship
        set status = 'cancelled', responded_at = now()
        where status in ('pending', 'accepted')
          and least(requester_id, addressee_id) = least(v_uid, p_user_id)
          and greatest(requester_id, addressee_id) = greatest(v_uid, p_user_id);
end;
$$;


ALTER FUNCTION public.unfriend(p_user_id uuid) OWNER TO postgres;

--
-- Name: update_freeplay_activity(uuid, timestamp with time zone, timestamp with time zone, integer, numeric, numeric, text[], text, uuid, text, text, bigint, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_freeplay_activity(p_activity_id uuid, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid DEFAULT NULL::uuid, p_venue_name text DEFAULT NULL::text, p_street_address text DEFAULT NULL::text, p_city_cluster bigint DEFAULT NULL::bigint, p_ward text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_row record; v_has_requests boolean; v_loc_city bigint; v_loc_ward text;
BEGIN
  SELECT a.*, fa.capacity, fa.male_price, fa.female_price, fa.cancelled_at
  INTO v_row FROM public.activity a JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE a.id=p_activity_id AND h.user_id=v_uid FOR UPDATE OF a,fa;
  IF NOT FOUND THEN RAISE EXCEPTION 'activity not found or not owned'; END IF;
  IF v_row.cancelled_at IS NOT NULL THEN RAISE EXCEPTION 'activity cancelled'; END IF;
  SELECT EXISTS(SELECT 1 FROM public.freeplay_request WHERE activity_id=p_activity_id) INTO v_has_requests;
  IF v_has_requests AND (p_start_time<>v_row.start_time OR p_end_time<>v_row.end_time
      OR p_male_price<>v_row.male_price OR p_female_price<>v_row.female_price
      OR p_location_id IS DISTINCT FROM v_row.location_id OR p_capacity<v_row.capacity) THEN
    RAISE EXCEPTION 'requested activity only allows capacity increase, description and skill changes';
  END IF;
  IF p_capacity < (SELECT count(*) FROM public.freeplay_request WHERE activity_id=p_activity_id AND status='accepted') THEN
    RAISE EXCEPTION 'capacity below accepted attendance';
  END IF;
  IF p_location_id IS NOT NULL THEN
    SELECT city_cluster,district INTO v_loc_city,v_loc_ward FROM public.location WHERE id=p_location_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'location not found'; END IF;
  ELSIF nullif(btrim(p_venue_name),'') IS NULL OR nullif(btrim(p_street_address),'') IS NULL
     OR p_city_cluster IS NULL OR nullif(btrim(p_ward),'') IS NULL THEN
    RAISE EXCEPTION 'free venue requires name, address, city and ward';
  END IF;
  UPDATE public.activity SET start_time=p_start_time,end_time=p_end_time,location_id=p_location_id WHERE id=p_activity_id;
  UPDATE public.freeplay_activity SET description=coalesce(p_description,''),capacity=p_capacity,
    male_price=p_male_price,female_price=p_female_price,recommended_skills=p_recommended_skills,
    venue_name=CASE WHEN p_location_id IS NULL THEN btrim(p_venue_name) END,
    street_address=CASE WHEN p_location_id IS NULL THEN btrim(p_street_address) END,
    city_cluster=coalesce(p_city_cluster,v_loc_city),ward=CASE WHEN p_location_id IS NULL THEN p_ward ELSE v_loc_ward END,
    updated_at=now() WHERE activity_id=p_activity_id;
END
$$;


ALTER FUNCTION public.update_freeplay_activity(p_activity_id uuid, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid, p_venue_name text, p_street_address text, p_city_cluster bigint, p_ward text) OWNER TO postgres;

--
-- Name: update_lobby(uuid, text, text, jsonb, jsonb, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_lobby(p_lobby_id uuid, p_name text, p_visibility text, p_playtime jsonb DEFAULT NULL::jsonb, p_details jsonb DEFAULT NULL::jsonb, p_home_ground_id uuid DEFAULT NULL::uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.lobby WHERE id = p_lobby_id AND captain_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'update_lobby: caller is not the lobby captain';
    END IF;

    UPDATE public.lobby
    SET name        = p_name,
        visibility  = p_visibility::public.lobby_visibility,
        playtime    = p_playtime,
        details     = p_details,
        home_ground = p_home_ground_id
    WHERE id = p_lobby_id;
END;
$$;


ALTER FUNCTION public.update_lobby(p_lobby_id uuid, p_name text, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid) OWNER TO postgres;

--
-- Name: user_level_summary(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_level_summary(p_user_id uuid) RETURNS TABLE(level integer, xp_total bigint, current_floor bigint, next_floor bigint)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_xp bigint; v_level int;
BEGIN
  SELECT COALESCE(u.xp, 0) INTO v_xp FROM public."user" u WHERE u.id = p_user_id;
  v_xp := COALESCE(v_xp, 0);
  v_level := public._achievement_level_for_xp(v_xp);
  RETURN QUERY SELECT
    v_level,
    v_xp,
    public._achievement_level_floor(v_level),
    CASE WHEN v_level >= 50 THEN NULL
         ELSE public._achievement_level_floor(v_level + 1) END;
END;
$$;


ALTER FUNCTION public.user_level_summary(p_user_id uuid) OWNER TO postgres;

--
-- Name: user_profile_data(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_profile_data(p_user_id uuid) RETURNS TABLE(user_id uuid, username text, tag_number text, details jsonb, friendship_id uuid, friend_state text, friend_count integer, shared_lobby_count integer)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    select u.id,
           u.username::text,
           u.tag_number::text,
           u.details,
           f.id,
           case
               when public.fn_is_blocked(auth.uid(), u.id) then 'blocked'
               when f.status = 'accepted' then 'friend'
               when f.status = 'pending' and f.addressee_id = auth.uid() then 'incoming'
               when f.status = 'pending' then 'outgoing'
               else 'none'
           end,
           (select count(*)::int from public.friendship af
             where af.status = 'accepted'
               and u.id in (af.requester_id, af.addressee_id)),
           (select count(*)::int from public.lobby_member lm
             where lm.user_id = u.id
               and lm.lobby_id in (select public.get_my_lobby_ids()))
    from public."user" u
    left join public.friendship f
        on f.status in ('pending', 'accepted')
       and least(f.requester_id, f.addressee_id) = least(auth.uid(), u.id)
       and greatest(f.requester_id, f.addressee_id) = greatest(auth.uid(), u.id)
    where u.id = p_user_id;
$$;


ALTER FUNCTION public.user_profile_data(p_user_id uuid) OWNER TO postgres;

--
-- Name: user_wall_data(uuid, text, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_wall_data(p_user_id uuid, p_mode text DEFAULT 'authored'::text, p_page_size integer DEFAULT 20, p_page_number integer DEFAULT 0) RETURNS TABLE(id uuid, author_id uuid, author_username text, author_tag_number text, author_details jsonb, sport_id bigint, lobby_id uuid, source_label text, source_start_time timestamp with time zone, source_venue_name text, caption text, media jsonb, created_at timestamp with time zone, expires_at timestamp with time zone, tags jsonb, reactions jsonb, my_reactions jsonb)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    SELECT p.id, p.author_id, u.username::text, u.tag_number::text, u.details,
           p.sport_id, p.lobby_id, p.source_label, p.source_start_time,
           p.source_venue_name, p.caption, p.media, p.created_at, p.expires_at,
           COALESCE((SELECT jsonb_agg(jsonb_build_object('user_id', tu.id,
                'username', tu.username, 'tag_number', tu.tag_number))
             FROM public.wall_post_tag t JOIN public."user" tu ON tu.id = t.user_id
             WHERE t.post_id = p.id), '[]'::jsonb),
           COALESCE((SELECT jsonb_object_agg(r.emoji, r.n)
             FROM (SELECT emoji, count(*) AS n FROM public.wall_post_reaction
                   WHERE post_id = p.id GROUP BY emoji) r), '{}'::jsonb),
           COALESCE((SELECT jsonb_agg(r.emoji ORDER BY r.created_at)
             FROM public.wall_post_reaction r
             WHERE r.post_id = p.id AND r.user_id = auth.uid()), '[]'::jsonb)
    FROM public.wall_post p JOIN public."user" u ON u.id = p.author_id
    WHERE public.fn_can_see_wall_post(p.id)
      AND CASE WHEN p_mode = 'tagged' THEN EXISTS (
            SELECT 1 FROM public.wall_post_tag t
            WHERE t.post_id = p.id AND t.user_id = p_user_id)
          ELSE p.author_id = p_user_id END
    ORDER BY p.created_at DESC
    LIMIT greatest(p_page_size, 1)
    OFFSET greatest(p_page_number, 0) * greatest(p_page_size, 1);
$$;


ALTER FUNCTION public.user_wall_data(p_user_id uuid, p_mode text, p_page_size integer, p_page_number integer) OWNER TO postgres;

--
-- Name: vitality_score_summary(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.vitality_score_summary(p_user_id uuid) RETURNS TABLE(date date, score real, consistency_component real, load_component real, recovery_component real, volume_component real, streak_bonus real, ctl real, atl real)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT date, score, consistency_component, load_component,
         recovery_component, volume_component, streak_bonus, ctl, atl
  FROM public.vitality_score
  WHERE user_id = p_user_id AND user_id = auth.uid()
  ORDER BY date DESC
  LIMIT 1;
$$;


ALTER FUNCTION public.vitality_score_summary(p_user_id uuid) OWNER TO postgres;

--
-- Name: vote_message_poll(uuid, smallint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.vote_message_poll(p_message_id uuid, p_option_index smallint) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_conversation uuid; v_options int;
BEGIN
  SELECT m.conversation_id, jsonb_array_length(m.payload->'options')
  INTO v_conversation, v_options
  FROM public.message m WHERE m.id = p_message_id AND m.kind = 'poll';
  IF NOT FOUND THEN RAISE EXCEPTION 'poll not found'; END IF;
  IF NOT coalesce(public.fn_can_write_conversation(v_conversation, v_uid), false) THEN
    RAISE EXCEPTION 'chat is read-only';
  END IF;
  IF p_option_index < 0 OR p_option_index >= v_options THEN
    RAISE EXCEPTION 'invalid option';
  END IF;

  INSERT INTO public.message_poll_vote(message_id, user_id, option_index)
  VALUES (p_message_id, v_uid, p_option_index)
  ON CONFLICT (message_id, user_id) DO UPDATE SET option_index = excluded.option_index;
END
$$;


ALTER FUNCTION public.vote_message_poll(p_message_id uuid, p_option_index smallint) OWNER TO postgres;

--
-- Name: wall_feed_data(bigint, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.wall_feed_data(p_sport_id bigint DEFAULT NULL::bigint, p_page_size integer DEFAULT 20, p_page_number integer DEFAULT 0) RETURNS TABLE(id uuid, author_id uuid, author_username text, author_tag_number text, author_details jsonb, sport_id bigint, lobby_id uuid, source_label text, source_start_time timestamp with time zone, source_venue_name text, caption text, media jsonb, created_at timestamp with time zone, expires_at timestamp with time zone, tags jsonb, reactions jsonb, my_reactions jsonb)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    v_page_size integer := LEAST(GREATEST(COALESCE(p_page_size, 20), 1), 50);
    v_page_number integer := COALESCE(p_page_number, 0);
BEGIN
    IF v_page_number < 0 OR v_page_number > 100 THEN
        RETURN;
    END IF;

    RETURN QUERY
    WITH me AS (SELECT auth.uid() AS uid),
    friends AS (SELECT uid FROM public.get_my_friend_ids() AS uid),
    lobbymates AS (SELECT uid FROM public.get_my_lobbymate_ids() AS uid),
    visible AS (
        SELECT p.*
        FROM public.wall_post p, me
        WHERE p.hidden_at IS NULL
          AND p.expires_at > now()
          AND NOT public.fn_is_blocked(me.uid, p.author_id)
          AND (p_sport_id IS NULL OR p.sport_id = p_sport_id)
          AND (
              p.author_id = me.uid
              OR p.author_id IN (SELECT uid FROM friends)
              OR p.author_id IN (SELECT uid FROM lobbymates)
              OR EXISTS (
                  SELECT 1
                  FROM public.wall_post_tag t
                  WHERE t.post_id = p.id
                    AND (
                        t.user_id = me.uid
                        OR t.user_id IN (SELECT uid FROM friends)
                    )
              )
          )
    )
    SELECT
        v.id,
        v.author_id,
        u.username::text,
        u.tag_number::text,
        u.details,
        v.sport_id,
        v.lobby_id,
        v.source_label,
        v.source_start_time,
        v.source_venue_name,
        v.caption,
        v.media,
        v.created_at,
        v.expires_at,
        COALESCE((
            SELECT jsonb_agg(jsonb_build_object(
                'user_id', tu.id,
                'username', tu.username,
                'tag_number', tu.tag_number
            ))
            FROM public.wall_post_tag t
            JOIN public."user" tu ON tu.id = t.user_id
            WHERE t.post_id = v.id
        ), '[]'::jsonb),
        COALESCE((
            SELECT jsonb_object_agg(r.emoji, r.n)
            FROM (
                SELECT emoji, count(*) AS n
                FROM public.wall_post_reaction
                WHERE post_id = v.id
                GROUP BY emoji
            ) r
        ), '{}'::jsonb),
        COALESCE((
            SELECT jsonb_agg(r.emoji ORDER BY r.created_at)
            FROM public.wall_post_reaction r
            WHERE r.post_id = v.id
              AND r.user_id = (SELECT uid FROM me)
        ), '[]'::jsonb)
    FROM visible v
    JOIN public."user" u ON u.id = v.author_id
    ORDER BY v.created_at DESC
    LIMIT v_page_size
    OFFSET v_page_number * v_page_size;
END;
$$;


ALTER FUNCTION public.wall_feed_data(p_sport_id bigint, p_page_size integer, p_page_number integer) OWNER TO postgres;

--
-- Name: FUNCTION wall_feed_data(p_sport_id bigint, p_page_size integer, p_page_number integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.wall_feed_data(p_sport_id bigint, p_page_size integer, p_page_number integer) IS 'Returns visible wall posts with page size clamped to 1..50 and page number restricted to 0..100.';


--
-- Name: wall_feed_has_unread(timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.wall_feed_has_unread(p_since timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    with me as (select auth.uid() as uid),
    friends as (select uid from public.get_my_friend_ids() as uid),
    lobbymates as (select uid from public.get_my_lobbymate_ids() as uid)
    select exists (
        select 1
        from public.wall_post p, me
        where p.hidden_at is null
          and p.expires_at > now()
          and p.author_id <> me.uid
          and p.created_at > coalesce(p_since, 'epoch'::timestamptz)
          and not public.fn_is_blocked(me.uid, p.author_id)
          and (
            p.author_id in (select uid from friends)
            or p.author_id in (select uid from lobbymates)
            or exists (
                select 1 from public.wall_post_tag t
                where t.post_id = p.id
                  and (t.user_id = me.uid or t.user_id in (select uid from friends))
            )
          )
    );
$$;


ALTER FUNCTION public.wall_feed_has_unread(p_since timestamp with time zone) OWNER TO postgres;

--
-- Name: withdraw_course_proposal(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.withdraw_course_proposal(p_activity_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_course uuid;
BEGIN
  SELECT a.course_id INTO v_course FROM public.activity a
  WHERE a.id = p_activity_id AND a.proposal_status = 'pending'
    AND a.proposed_by = v_uid;
  IF NOT FOUND THEN RAISE EXCEPTION 'own pending proposal not found'; END IF;

  UPDATE public.activity SET proposal_status = 'withdrawn' WHERE id = p_activity_id;
  PERFORM public.fn_course_system_message(v_course, 'activity_withdrawn',
    jsonb_build_object('activity_id', p_activity_id));
END
$$;


ALTER FUNCTION public.withdraw_course_proposal(p_activity_id uuid) OWNER TO postgres;

--
-- Name: apply_rls(jsonb, integer); Type: FUNCTION; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer DEFAULT (1024 * 1024)) RETURNS SETOF realtime.wal_rls
    LANGUAGE plpgsql
    AS $$
declare
    -- Regclass of the table e.g. public.notes
    entity_ regclass = (quote_ident(wal ->> 'schema') || '.' || quote_ident(wal ->> 'table'))::regclass;

    -- I, U, D, T: insert, update ...
    action realtime.action = (
        case wal ->> 'action'
            when 'I' then 'INSERT'
            when 'U' then 'UPDATE'
            when 'D' then 'DELETE'
            else 'ERROR'
        end
    );

    -- Is row level security enabled for the table
    is_rls_enabled bool = relrowsecurity from pg_class where oid = entity_;

    subscriptions realtime.subscription[] = array_agg(subs)
        from
            realtime.subscription subs
        where
            subs.entity = entity_
            -- Filter by action early - only get subscriptions interested in this action
            -- action_filter column can be: '*' (all), 'INSERT', 'UPDATE', or 'DELETE'
            and (subs.action_filter = '*' or subs.action_filter = action::text);

    -- Subscription vars
    working_role regrole;
    working_selected_columns text[];
    claimed_role regrole;
    claims jsonb;

    subscription_id uuid;
    subscription_has_access bool;
    visible_to_subscription_ids uuid[] = '{}';

    -- structured info for wal's columns
    columns realtime.wal_column[];
    -- previous identity values for update/delete
    old_columns realtime.wal_column[];

    error_record_exceeds_max_size boolean = octet_length(wal::text) > max_record_bytes;

    -- Primary jsonb output for record
    output jsonb;

    -- Loop record for iterating unique roles (outer loop)
    role_record record;
    -- Loop record for iterating unique selected_columns within a role (inner loop)
    cols_record record;
    -- Subscription ids visible at the role level (before fanning out by selected_columns)
    visible_role_sub_ids uuid[] = '{}';

begin
    perform set_config('role', null, true);

    columns =
        array_agg(
            (
                x->>'name',
                x->>'type',
                x->>'typeoid',
                realtime.cast(
                    (x->'value') #>> '{}',
                    coalesce(
                        (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                        (x->>'type')::regtype
                    )
                ),
                (pks ->> 'name') is not null,
                true
            )::realtime.wal_column
        )
        from
            jsonb_array_elements(wal -> 'columns') x
            left join jsonb_array_elements(wal -> 'pk') pks
                on (x ->> 'name') = (pks ->> 'name');

    old_columns =
        array_agg(
            (
                x->>'name',
                x->>'type',
                x->>'typeoid',
                realtime.cast(
                    (x->'value') #>> '{}',
                    coalesce(
                        (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                        (x->>'type')::regtype
                    )
                ),
                (pks ->> 'name') is not null,
                true
            )::realtime.wal_column
        )
        from
            jsonb_array_elements(wal -> 'identity') x
            left join jsonb_array_elements(wal -> 'pk') pks
                on (x ->> 'name') = (pks ->> 'name');

    for role_record in
        select claims_role
        from (select distinct claims_role from unnest(subscriptions)) t
        order by claims_role::text
    loop
        working_role := role_record.claims_role;

        -- Update `is_selectable` for columns and old_columns (once per role)
        columns =
            array_agg(
                (
                    c.name,
                    c.type_name,
                    c.type_oid,
                    c.value,
                    c.is_pkey,
                    pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                )::realtime.wal_column
            )
            from
                unnest(columns) c;

        old_columns =
                array_agg(
                    (
                        c.name,
                        c.type_name,
                        c.type_oid,
                        c.value,
                        c.is_pkey,
                        pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                    )::realtime.wal_column
                )
                from
                    unnest(old_columns) c;

        if action <> 'DELETE' and count(1) = 0 from unnest(columns) c where c.is_pkey then
            -- Fan out 400 error per distinct selected_columns for this role
            for cols_record in
                select selected_columns
                from (select distinct selected_columns from unnest(subscriptions) s where s.claims_role = working_role) t
                order by coalesce(array_to_string(selected_columns, ','), '')
            loop
                working_selected_columns := cols_record.selected_columns;
                return next (
                    jsonb_build_object(
                        'schema', wal ->> 'schema',
                        'table', wal ->> 'table',
                        'type', action
                    ),
                    is_rls_enabled,
                    (select array_agg(s.subscription_id) from unnest(subscriptions) as s where s.claims_role = working_role and (s.selected_columns is not distinct from working_selected_columns)),
                    array['Error 400: Bad Request, no primary key']
                )::realtime.wal_rls;
            end loop;

        -- The claims role does not have SELECT permission to the primary key of entity
        elsif action <> 'DELETE' and sum(c.is_selectable::int) <> count(1) from unnest(columns) c where c.is_pkey then
            -- Fan out 401 error per distinct selected_columns for this role
            for cols_record in
                select selected_columns
                from (select distinct selected_columns from unnest(subscriptions) s where s.claims_role = working_role) t
                order by coalesce(array_to_string(selected_columns, ','), '')
            loop
                working_selected_columns := cols_record.selected_columns;
                return next (
                    jsonb_build_object(
                        'schema', wal ->> 'schema',
                        'table', wal ->> 'table',
                        'type', action
                    ),
                    is_rls_enabled,
                    (select array_agg(s.subscription_id) from unnest(subscriptions) as s where s.claims_role = working_role and (s.selected_columns is not distinct from working_selected_columns)),
                    array['Error 401: Unauthorized']
                )::realtime.wal_rls;
            end loop;

        else
            -- Create the prepared statement (once per role)
            if is_rls_enabled and action <> 'DELETE' then
                if (select 1 from pg_prepared_statements where name = 'walrus_rls_stmt' limit 1) > 0 then
                    deallocate walrus_rls_stmt;
                end if;
                execute realtime.build_prepared_statement_sql('walrus_rls_stmt', entity_, columns);
            end if;

            -- Collect all visible subscription IDs for this role (filter check + RLS check)
            visible_role_sub_ids = '{}';

            for subscription_id, claims in (
                    select
                        subs.subscription_id,
                        subs.claims
                    from
                        unnest(subscriptions) subs
                    where
                        subs.entity = entity_
                        and subs.claims_role = working_role
                        and (
                            realtime.is_visible_through_filters(columns, subs.filters)
                            or (
                              action = 'DELETE'
                              and realtime.is_visible_through_filters(old_columns, subs.filters)
                            )
                        )
            ) loop

                if not is_rls_enabled or action = 'DELETE' then
                    visible_role_sub_ids = visible_role_sub_ids || subscription_id;
                else
                    -- Check if RLS allows the role to see the record
                    perform
                        -- Trim leading and trailing quotes from working_role because set_config
                        -- doesn't recognize the role as valid if they are included
                        set_config('role', trim(both '"' from working_role::text), true),
                        set_config('request.jwt.claims', claims::text, true);

                    execute 'execute walrus_rls_stmt' into subscription_has_access;

                    -- Reset the role on every FOR..LOOP batch execution.
                    -- The first batch of 10 rows is pre-fetched using the current connection role (PG internal behaviour)
                    -- then we have to reset it again otherwise it would use the role defined in the `set_config` above
                    -- to fetch the remaining rows when rows>10, which could be a user-defined role that lacks execution grants.
                    -- The flow is:
                    --   1. run batch with conn role
                    --   2. set_config working_role
                    --   3. execute walrus
                    --   4. reset role (revert)
                    --   5. repeat
                    perform set_config('role', null, true);

                    if subscription_has_access then
                        visible_role_sub_ids = visible_role_sub_ids || subscription_id;
                    end if;
                end if;
            end loop;

            perform set_config('role', null, true);

            -- Inner loop: per distinct selected_columns for this role
            for cols_record in
                select selected_columns
                from (select distinct selected_columns from unnest(subscriptions) s where s.claims_role = working_role) t
                order by coalesce(array_to_string(selected_columns, ','), '')
            loop
                working_selected_columns := cols_record.selected_columns;

                output = jsonb_build_object(
                    'schema', wal ->> 'schema',
                    'table', wal ->> 'table',
                    'type', action,
                    'commit_timestamp', to_char(
                        ((wal ->> 'timestamp')::timestamptz at time zone 'utc'),
                        'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
                    ),
                    'columns', (
                        select
                            jsonb_agg(
                                jsonb_build_object(
                                    'name', pa.attname,
                                    'type', pt.typname
                                )
                                order by pa.attnum asc
                            )
                        from
                            pg_attribute pa
                            join pg_type pt
                                on pa.atttypid = pt.oid
                            left join (
                                select unnest(conkey) as pkey_attnum
                                from pg_constraint
                                where conrelid = entity_ and contype = 'p'
                            ) pk on pk.pkey_attnum = pa.attnum
                        where
                            attrelid = entity_
                            and attnum > 0
                            and pg_catalog.has_column_privilege(working_role, entity_, pa.attname, 'SELECT')
                            and (working_selected_columns is null or pa.attname = any(working_selected_columns) or pk.pkey_attnum is not null)
                    )
                )
                -- Add "record" key for insert and update
                || case
                    when action in ('INSERT', 'UPDATE') then
                        jsonb_build_object(
                            'record',
                            (
                                select
                                    jsonb_object_agg(
                                        -- if unchanged toast, get column name and value from old record
                                        coalesce((c).name, (oc).name),
                                        case
                                            when (c).name is null then (oc).value
                                            else (c).value
                                        end
                                    )
                                from
                                    unnest(columns) c
                                    full outer join unnest(old_columns) oc
                                        on (c).name = (oc).name
                                where
                                    coalesce((c).is_selectable, (oc).is_selectable)
                                    and (working_selected_columns is null or coalesce((c).name, (oc).name) = any(working_selected_columns) or coalesce((c).is_pkey, (oc).is_pkey))
                                    and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                            )
                        )
                    else '{}'::jsonb
                end
                -- Add "old_record" key for update and delete
                || case
                    when action = 'UPDATE' then
                        jsonb_build_object(
                                'old_record',
                                (
                                    select jsonb_object_agg((c).name, (c).value)
                                    from unnest(old_columns) c
                                    where
                                        (c).is_selectable
                                        and (working_selected_columns is null or (c).name = any(working_selected_columns) or (c).is_pkey)
                                        and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                                )
                            )
                    when action = 'DELETE' then
                        jsonb_build_object(
                            'old_record',
                            (
                                select jsonb_object_agg((c).name, (c).value)
                                from unnest(old_columns) c
                                where
                                    (c).is_selectable
                                    and (working_selected_columns is null or (c).name = any(working_selected_columns) or (c).is_pkey)
                                    and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                                    and ( not is_rls_enabled or (c).is_pkey ) -- if RLS enabled, we can't secure deletes so filter to pkey
                            )
                        )
                    else '{}'::jsonb
                end;

                -- Filter visible_role_sub_ids to those matching the current selected_columns group
                visible_to_subscription_ids = coalesce(
                    (
                        select array_agg(s.subscription_id)
                        from unnest(subscriptions) s
                        where s.claims_role = working_role
                          and (s.selected_columns is not distinct from working_selected_columns)
                          and s.subscription_id = any(visible_role_sub_ids)
                    ),
                    '{}'::uuid[]
                );

                return next (
                    output,
                    is_rls_enabled,
                    visible_to_subscription_ids,
                    case
                        when error_record_exceeds_max_size then array['Error 413: Payload Too Large']
                        else '{}'
                    end
                )::realtime.wal_rls;
            end loop;

        end if;
    end loop;

    perform set_config('role', null, true);
end;
$$;


ALTER FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) OWNER TO supabase_realtime_admin;

--
-- Name: broadcast_changes(text, text, text, text, text, record, record, text); Type: FUNCTION; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text DEFAULT 'ROW'::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- Declare a variable to hold the JSONB representation of the row
    row_data jsonb := '{}'::jsonb;
BEGIN
    IF level = 'STATEMENT' THEN
        RAISE EXCEPTION 'function can only be triggered for each row, not for each statement';
    END IF;
    -- Check the operation type and handle accordingly
    IF operation = 'INSERT' OR operation = 'UPDATE' OR operation = 'DELETE' THEN
        row_data := jsonb_build_object('old_record', OLD, 'record', NEW, 'operation', operation, 'table', table_name, 'schema', table_schema);
        PERFORM realtime.send (row_data, event_name, topic_name);
    ELSE
        RAISE EXCEPTION 'Unexpected operation type: %', operation;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to process the row: %', SQLERRM;
END;

$$;


ALTER FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text) OWNER TO supabase_realtime_admin;

--
-- Name: build_prepared_statement_sql(text, regclass, realtime.wal_column[]); Type: FUNCTION; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) RETURNS text
    LANGUAGE sql
    AS $$
      /*
      Builds a sql string that, if executed, creates a prepared statement to
      tests retrive a row from *entity* by its primary key columns.
      Example
          select realtime.build_prepared_statement_sql('public.notes', '{"id"}'::text[], '{"bigint"}'::text[])
      */
          select
      'prepare ' || prepared_statement_name || ' as
          select
              exists(
                  select
                      1
                  from
                      ' || entity || '
                  where
                      ' || string_agg(quote_ident(pkc.name) || '=' || quote_nullable(pkc.value #>> '{}') , ' and ') || '
              )'
          from
              unnest(columns) pkc
          where
              pkc.is_pkey
          group by
              entity
      $$;


ALTER FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) OWNER TO supabase_realtime_admin;

--
-- Name: cast(text, regtype); Type: FUNCTION; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE FUNCTION realtime."cast"(val text, type_ regtype) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
  res jsonb;
begin
  if type_::text = 'bytea' then
    return to_jsonb(val);
  end if;
  execute format('select to_jsonb(%L::'|| type_::text || ')', val) into res;
  return res;
end
$$;


ALTER FUNCTION realtime."cast"(val text, type_ regtype) OWNER TO supabase_realtime_admin;

--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text); Type: FUNCTION; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/*
Casts *val_1* and *val_2* as type *type_* and check the *op* condition for truthiness
*/
declare
    op_symbol text = (
        case
            when op = 'eq' then '='
            when op = 'neq' then '!='
            when op = 'lt' then '<'
            when op = 'lte' then '<='
            when op = 'gt' then '>'
            when op = 'gte' then '>='
            when op = 'in' then '= any'
            else 'UNKNOWN OP'
        end
    );
    res boolean;
begin
    execute format(
        'select %L::'|| type_::text || ' ' || op_symbol
        || ' ( %L::'
        || (
            case
                when op = 'in' then type_::text || '[]'
                else type_::text end
        )
        || ')', val_1, val_2) into res;
    return res;
end;
$$;


ALTER FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) OWNER TO supabase_realtime_admin;

--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text, negate boolean) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
declare
    op_symbol text;
    res boolean;
begin
    -- IS DISTINCT FROM / IS NOT DISTINCT FROM: infix, both sides typed literals
    if op = 'isdistinct' then
        execute format(
            'select %L::%s %s %L::%s',
            val_1,
            type_::text,
            case when negate then 'IS NOT DISTINCT FROM' else 'IS DISTINCT FROM' end,
            val_2,
            type_::text
        ) into res;
        return res;
    end if;

    -- IS requires a keyword RHS (NULL, TRUE, FALSE, UNKNOWN), not a typed literal
    if op = 'is' then
        if val_2 not in ('null', 'true', 'false', 'unknown') then
            raise exception 'invalid value for is filter: must be null, true, false, or unknown';
        end if;
        execute format(
            'select %L::%s %s %s',
            val_1,
            type_::text,
            case when negate then 'IS NOT' else 'IS' end,
            upper(val_2)
        ) into res;
        return res;
    end if;

    op_symbol = case
        when op = 'eq'    then '='
        when op = 'neq'   then '!='
        when op = 'lt'    then '<'
        when op = 'lte'   then '<='
        when op = 'gt'    then '>'
        when op = 'gte'   then '>='
        when op = 'in'    then '= any'
        when op = 'like'   then 'LIKE'
        when op = 'ilike'  then 'ILIKE'
        when op = 'match'  then '~'
        when op = 'imatch' then '~*'
        else null
    end;

    if op_symbol is null then
        raise exception 'unsupported equality operator: %', op::text;
    end if;

    execute format(
        'select %L::%s %s (%L::%s)',
        val_1,
        type_::text,
        op_symbol,
        val_2,
        case when op = 'in' then type_::text || '[]' else type_::text end
    ) into res;

    return case when negate then not res else res end;
end;
$$;


ALTER FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text, negate boolean) OWNER TO supabase_realtime_admin;

--
-- Name: is_visible_through_filters(realtime.wal_column[], realtime.user_defined_filter[]); Type: FUNCTION; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
    select
        filters is null
        or array_length(filters, 1) is null
        or coalesce(
            count(col.name) = count(1)
            and sum(
                realtime.check_equality_op(
                    op:=f.op,
                    type_:=coalesce(col.type_oid::regtype, col.type_name::regtype),
                    val_1:=col.value #>> '{}',
                    val_2:=f.value,
                    negate:=coalesce(f.negate, false)
                )::int
            ) filter (where col.name is not null) = count(col.name),
            false
        )
    from
        unnest(filters) f
        left join unnest(columns) col
            on f.column_name = col.name;
$$;


ALTER FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) OWNER TO supabase_realtime_admin;

--
-- Name: list_changes(name, name, integer, integer); Type: FUNCTION; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) RETURNS TABLE(wal jsonb, is_rls_enabled boolean, subscription_ids uuid[], errors text[], slot_changes_count bigint)
    LANGUAGE sql
    SET log_min_messages TO 'fatal'
    AS $$
  WITH pub AS (
    SELECT
      concat_ws(
        ',',
        CASE WHEN bool_or(pubinsert) THEN 'insert' ELSE NULL END,
        CASE WHEN bool_or(pubupdate) THEN 'update' ELSE NULL END,
        CASE WHEN bool_or(pubdelete) THEN 'delete' ELSE NULL END
      ) AS w2j_actions,
      coalesce(
        string_agg(
          realtime.quote_wal2json(format('%I.%I', schemaname, tablename)::regclass),
          ','
        ) filter (WHERE ppt.tablename IS NOT NULL),
        ''
      ) AS w2j_add_tables
    FROM pg_publication pp
    LEFT JOIN pg_publication_tables ppt ON pp.pubname = ppt.pubname
    WHERE pp.pubname = publication
    GROUP BY pp.pubname
    LIMIT 1
  ),
  -- MATERIALIZED ensures pg_logical_slot_get_changes is called exactly once
  w2j AS MATERIALIZED (
    SELECT x.*, pub.w2j_add_tables
    FROM pub,
         pg_logical_slot_get_changes(
           slot_name, null, max_changes,
           'include-pk', 'true',
           'include-transaction', 'false',
           'include-timestamp', 'true',
           'include-type-oids', 'true',
           'format-version', '2',
           'actions', pub.w2j_actions,
           'add-tables', pub.w2j_add_tables
         ) x
  ),
  slot_count AS (
    SELECT count(*)::bigint AS cnt
    FROM w2j
    WHERE w2j.w2j_add_tables <> ''
  ),
  rls_filtered AS (
    SELECT xyz.wal, xyz.is_rls_enabled, xyz.subscription_ids, xyz.errors
    FROM w2j,
         realtime.apply_rls(
           wal := w2j.data::jsonb,
           max_record_bytes := max_record_bytes
         ) xyz(wal, is_rls_enabled, subscription_ids, errors)
    WHERE w2j.w2j_add_tables <> ''
      AND xyz.subscription_ids[1] IS NOT NULL
  )
  SELECT rf.wal, rf.is_rls_enabled, rf.subscription_ids, rf.errors, sc.cnt
  FROM rls_filtered rf, slot_count sc

  UNION ALL

  SELECT null, null, null, null, sc.cnt
  FROM slot_count sc
  WHERE NOT EXISTS (SELECT 1 FROM rls_filtered)
$$;


ALTER FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) OWNER TO supabase_realtime_admin;

--
-- Name: quote_wal2json(regclass); Type: FUNCTION; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE FUNCTION realtime.quote_wal2json(entity regclass) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
  SELECT
    realtime.wal2json_escape_identifier(nsp.nspname::text)
    || '.'
    || realtime.wal2json_escape_identifier(pc.relname::text)
  FROM pg_class pc
  JOIN pg_namespace nsp ON pc.relnamespace = nsp.oid
  WHERE pc.oid = entity
$$;


ALTER FUNCTION realtime.quote_wal2json(entity regclass) OWNER TO supabase_realtime_admin;

--
-- Name: send(jsonb, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  generated_id uuid;
  final_payload jsonb;
BEGIN
  BEGIN
    generated_id := gen_random_uuid();

    -- Check if payload has an 'id' key, if not, add the generated UUID
    IF payload ? 'id' THEN
      final_payload := payload;
    ELSE
      final_payload := jsonb_set(payload, '{id}', to_jsonb(generated_id));
    END IF;

    -- Set the topic configuration
    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    INSERT INTO realtime.messages (id, payload, event, topic, private, extension)
    VALUES (generated_id, final_payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING 'WarnSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


ALTER FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean) OWNER TO supabase_realtime_admin;

--
-- Name: send_binary(bytea, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE FUNCTION realtime.send_binary(payload bytea, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  generated_id uuid;
BEGIN
  BEGIN
    generated_id := gen_random_uuid();

    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    INSERT INTO realtime.messages (id, binary_payload, event, topic, private, extension)
    VALUES (generated_id, payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING 'WarnSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


ALTER FUNCTION realtime.send_binary(payload bytea, event text, topic text, private boolean) OWNER TO supabase_realtime_admin;

--
-- Name: subscription_check_filters(); Type: FUNCTION; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE FUNCTION realtime.subscription_check_filters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
    col_names text[] = coalesce(
            array_agg(a.attname order by a.attnum),
            '{}'::text[]
        )
        from
            pg_catalog.pg_attribute a
        where
            a.attrelid = new.entity
            and a.attnum > 0
            and not a.attisdropped
            and pg_catalog.has_column_privilege(
                (new.claims ->> 'role'),
                a.attrelid,
                a.attnum,
                'SELECT'
            );
    filter realtime.user_defined_filter;
    col_type regtype;
    in_val jsonb;
    selected_col text;
begin
    for filter in select * from unnest(new.filters) loop
        if not filter.column_name = any(col_names) then
            raise exception 'invalid column for filter %', filter.column_name;
        end if;

        col_type = (
            select atttypid::regtype
            from pg_catalog.pg_attribute
            where attrelid = new.entity
                  and attname = filter.column_name
        );
        if col_type is null then
            raise exception 'failed to lookup type for column %', filter.column_name;
        end if;

        if filter.op = 'in'::realtime.equality_op then
            in_val = realtime.cast(filter.value, (col_type::text || '[]')::regtype);
            if coalesce(jsonb_array_length(in_val), 0) > 100 then
                raise exception 'too many values for `in` filter. Maximum 100';
            end if;
        elsif filter.op = 'is'::realtime.equality_op then
            -- `is` requires a keyword RHS rather than a typed literal
            if filter.value not in ('null', 'true', 'false', 'unknown') then
                raise exception 'invalid value for is filter: must be null, true, false, or unknown';
            end if;
            -- IS NULL works for any type, but IS TRUE/FALSE/UNKNOWN require a boolean
            -- operand. Reject the non-null keywords on non-boolean columns here so they
            -- don't abort apply_rls at WAL time.
            if filter.value <> 'null' and col_type <> 'boolean'::regtype then
                raise exception 'is % filter requires a boolean column, got %', filter.value, col_type::text;
            end if;
        elsif filter.op in ('like'::realtime.equality_op, 'ilike'::realtime.equality_op) then
            -- like/ilike apply the text pattern operator (~~); reject column types that
            -- have no such operator instead of failing at WAL time
            if not exists (
                select 1 from pg_catalog.pg_operator
                where oprname = '~~' and oprleft = col_type
            ) then
                raise exception 'operator % requires a text-compatible column type, got %', filter.op::text, col_type::text;
            end if;
        elsif filter.op in ('match'::realtime.equality_op, 'imatch'::realtime.equality_op) then
            -- match/imatch apply the regex operators ~ / ~*; reject column types that have
            -- no such operator (e.g. integer) instead of failing at WAL time, mirroring the
            -- like/ilike guard above.
            if not exists (
                select 1 from pg_catalog.pg_operator
                where oprname = case when filter.op = 'imatch'::realtime.equality_op then '~*' else '~' end
                  and oprleft = col_type
                  and oprright = col_type
                  and oprresult = 'boolean'::regtype
            ) then
                raise exception 'operator % requires a text-compatible column type, got %', filter.op::text, col_type::text;
            end if;
            -- validate the regex eagerly so a bad pattern is rejected here, not inside
            -- apply_rls where it would abort the WAL stream for the entity
            begin
                perform '' ~ filter.value;
            exception when others then
                raise exception 'invalid regular expression for % filter: %', filter.op::text, sqlerrm;
            end;
        else
            -- eq/neq/lt/lte/gt/gte: value must be coercable to the type
            perform realtime.cast(filter.value, col_type);
        end if;
    end loop;

    if new.selected_columns is not null then
        for selected_col in select * from unnest(new.selected_columns) loop
            if not selected_col = any(col_names) then
                raise exception 'invalid column for select %', selected_col;
            end if;
        end loop;
    end if;

    -- Apply consistent order to filters so the unique constraint can't be tricked by a
    -- different filter order. negate is part of the sort key.
    new.filters = coalesce(
        array_agg(f order by f.column_name, f.op, f.value, f.negate),
        '{}'
    ) from unnest(new.filters) f;

    new.selected_columns = (
        select array_agg(c order by c)
        from unnest(new.selected_columns) c
    );

    return new;
end;
$$;


ALTER FUNCTION realtime.subscription_check_filters() OWNER TO supabase_realtime_admin;

--
-- Name: to_regrole(text); Type: FUNCTION; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE FUNCTION realtime.to_regrole(role_name text) RETURNS regrole
    LANGUAGE sql IMMUTABLE
    AS $$ select role_name::regrole $$;


ALTER FUNCTION realtime.to_regrole(role_name text) OWNER TO supabase_realtime_admin;

--
-- Name: topic(); Type: FUNCTION; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE FUNCTION realtime.topic() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select nullif(current_setting('realtime.topic', true), '')::text;
$$;


ALTER FUNCTION realtime.topic() OWNER TO supabase_realtime_admin;

--
-- Name: wal2json_escape_identifier(text); Type: FUNCTION; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE FUNCTION realtime.wal2json_escape_identifier(name text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
  -- Prefix `\`, `,`, `.`, and any whitespace with `\`
  SELECT regexp_replace(name, '([\\,.[:space:]])', '\\\1', 'g')
$$;


ALTER FUNCTION realtime.wal2json_escape_identifier(name text) OWNER TO supabase_realtime_admin;

--
-- Name: allow_any_operation(text[]); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.allow_any_operation(expected_operations text[]) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  WITH current_operation AS (
    SELECT storage.operation() AS raw_operation
  ),
  normalized AS (
    SELECT CASE
      WHEN raw_operation LIKE 'storage.%' THEN substr(raw_operation, 9)
      ELSE raw_operation
    END AS current_operation
    FROM current_operation
  )
  SELECT EXISTS (
    SELECT 1
    FROM normalized n
    CROSS JOIN LATERAL unnest(expected_operations) AS expected_operation
    WHERE expected_operation IS NOT NULL
      AND expected_operation <> ''
      AND n.current_operation = CASE
        WHEN expected_operation LIKE 'storage.%' THEN substr(expected_operation, 9)
        ELSE expected_operation
      END
  );
$$;


ALTER FUNCTION storage.allow_any_operation(expected_operations text[]) OWNER TO supabase_storage_admin;

--
-- Name: allow_only_operation(text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.allow_only_operation(expected_operation text) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  WITH current_operation AS (
    SELECT storage.operation() AS raw_operation
  ),
  normalized AS (
    SELECT
      CASE
        WHEN raw_operation LIKE 'storage.%' THEN substr(raw_operation, 9)
        ELSE raw_operation
      END AS current_operation,
      CASE
        WHEN expected_operation LIKE 'storage.%' THEN substr(expected_operation, 9)
        ELSE expected_operation
      END AS requested_operation
    FROM current_operation
  )
  SELECT CASE
    WHEN requested_operation IS NULL OR requested_operation = '' THEN FALSE
    ELSE COALESCE(current_operation = requested_operation, FALSE)
  END
  FROM normalized;
$$;


ALTER FUNCTION storage.allow_only_operation(expected_operation text) OWNER TO supabase_storage_admin;

--
-- Name: can_insert_object(text, text, uuid, jsonb); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


ALTER FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) OWNER TO supabase_storage_admin;

--
-- Name: enforce_bucket_name_length(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.enforce_bucket_name_length() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    if length(new.name) > 100 then
        raise exception 'bucket name "%" is too long (% characters). Max is 100.', new.name, length(new.name);
    end if;
    return new;
end;
$$;


ALTER FUNCTION storage.enforce_bucket_name_length() OWNER TO supabase_storage_admin;

--
-- Name: extension(text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.extension(name text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
    _filename text;
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Get the last path segment (the actual filename)
    SELECT _parts[array_length(_parts, 1)] INTO _filename;
    -- Extract extension: reverse, split on '.', then reverse again
    RETURN reverse(split_part(reverse(_filename), '.', 1));
END
$$;


ALTER FUNCTION storage.extension(name text) OWNER TO supabase_storage_admin;

--
-- Name: filename(text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.filename(name text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
BEGIN
    SELECT string_to_array(name, '/') INTO _parts;
    RETURN _parts[array_length(_parts, 1)];
END
$$;


ALTER FUNCTION storage.filename(name text) OWNER TO supabase_storage_admin;

--
-- Name: foldername(text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.foldername(name text) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Return everything except the last segment
    RETURN _parts[1 : array_length(_parts,1) - 1];
END
$$;


ALTER FUNCTION storage.foldername(name text) OWNER TO supabase_storage_admin;

--
-- Name: get_common_prefix(text, text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.get_common_prefix(p_key text, p_prefix text, p_delimiter text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
SELECT CASE
    WHEN position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)) > 0
    THEN left(p_key, length(p_prefix) + position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)))
    ELSE NULL
END;
$$;


ALTER FUNCTION storage.get_common_prefix(p_key text, p_prefix text, p_delimiter text) OWNER TO supabase_storage_admin;

--
-- Name: get_size_by_bucket(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.get_size_by_bucket() RETURNS TABLE(size bigint, bucket_id text)
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::bigint)::bigint as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


ALTER FUNCTION storage.get_size_by_bucket() OWNER TO supabase_storage_admin;

--
-- Name: list_multipart_uploads_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, next_key_token text DEFAULT ''::text, next_upload_token text DEFAULT ''::text) RETURNS TABLE(key text, id text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(key COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                        substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1)))
                    ELSE
                        key
                END AS key, id, created_at
            FROM
                storage.s3_multipart_uploads
            WHERE
                bucket_id = $5 AND
                key ILIKE $1 || ''%'' AND
                CASE
                    WHEN $4 != '''' AND $6 = '''' THEN
                        CASE
                            WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                                substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                key COLLATE "C" > $4
                            END
                    ELSE
                        true
                END AND
                CASE
                    WHEN $6 != '''' THEN
                        id COLLATE "C" > $6
                    ELSE
                        true
                    END
            ORDER BY
                key COLLATE "C" ASC, created_at ASC) as e order by key COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_key_token, bucket_id, next_upload_token;
END;
$_$;


ALTER FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer, next_key_token text, next_upload_token text) OWNER TO supabase_storage_admin;

--
-- Name: list_objects_with_delimiter(text, text, text, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.list_objects_with_delimiter(_bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, start_after text DEFAULT ''::text, next_token text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, metadata jsonb, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;

    -- Configuration
    v_is_asc BOOLEAN;
    v_prefix TEXT;
    v_start TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_is_asc := lower(coalesce(sort_order, 'asc')) = 'asc';
    v_prefix := coalesce(prefix_param, '');
    v_start := CASE WHEN coalesce(next_token, '') <> '' THEN next_token ELSE coalesce(start_after, '') END;
    v_file_batch_size := LEAST(GREATEST(max_keys * 2, 100), 1000);

    -- Calculate upper bound for prefix filtering (bytewise, using COLLATE "C")
    IF v_prefix = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix, 1) = delimiter_param THEN
        v_upper_bound := left(v_prefix, -1) || chr(ascii(delimiter_param) + 1);
    ELSE
        v_upper_bound := left(v_prefix, -1) || chr(ascii(right(v_prefix, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'AND o.name COLLATE "C" < $3 ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'AND o.name COLLATE "C" >= $3 ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- ========================================================================
    -- SEEK INITIALIZATION: Determine starting position
    -- ========================================================================
    IF v_start = '' THEN
        IF v_is_asc THEN
            v_next_seek := v_prefix;
        ELSE
            -- DESC without cursor: find the last item in range
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;

            IF v_next_seek IS NOT NULL THEN
                v_next_seek := v_next_seek || delimiter_param;
            ELSE
                RETURN;
            END IF;
        END IF;
    ELSE
        -- Cursor provided: determine if it refers to a folder or leaf
        IF EXISTS (
            SELECT 1 FROM storage.objects o
            WHERE o.bucket_id = _bucket_id
              AND o.name COLLATE "C" LIKE v_start || delimiter_param || '%'
            LIMIT 1
        ) THEN
            -- Cursor refers to a folder
            IF v_is_asc THEN
                v_next_seek := v_start || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_start || delimiter_param;
            END IF;
        ELSE
            -- Cursor refers to a leaf object
            IF v_is_asc THEN
                v_next_seek := v_start || delimiter_param;
            ELSE
                v_next_seek := v_start;
            END IF;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= max_keys;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(v_peek_name, v_prefix, delimiter_param);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Emit and skip to next folder (no heap access needed)
            name := rtrim(v_common_prefix, delimiter_param);
            id := NULL;
            updated_at := NULL;
            created_at := NULL;
            last_accessed_at := NULL;
            metadata := NULL;
            RETURN NEXT;
            v_count := v_count + 1;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := left(v_common_prefix, -1) || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_common_prefix;
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query USING _bucket_id, v_next_seek,
                CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix) ELSE v_prefix END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(v_current.name, v_prefix, delimiter_param);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := v_current.name;
                    EXIT;
                END IF;

                -- Emit file
                name := v_current.name;
                id := v_current.id;
                updated_at := v_current.updated_at;
                created_at := v_current.created_at;
                last_accessed_at := v_current.last_accessed_at;
                metadata := v_current.metadata;
                RETURN NEXT;
                v_count := v_count + 1;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := v_current.name || delimiter_param;
                ELSE
                    v_next_seek := v_current.name;
                END IF;

                EXIT WHEN v_count >= max_keys;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


ALTER FUNCTION storage.list_objects_with_delimiter(_bucket_id text, prefix_param text, delimiter_param text, max_keys integer, start_after text, next_token text, sort_order text) OWNER TO supabase_storage_admin;

--
-- Name: operation(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.operation() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN current_setting('storage.operation', true);
END;
$$;


ALTER FUNCTION storage.operation() OWNER TO supabase_storage_admin;

--
-- Name: protect_delete(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.protect_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if storage.allow_delete_query is set to 'true'
    IF COALESCE(current_setting('storage.allow_delete_query', true), 'false') != 'true' THEN
        RAISE EXCEPTION 'Direct deletion from storage tables is not allowed. Use the Storage API instead.'
            USING HINT = 'This prevents accidental data loss from orphaned objects.',
                  ERRCODE = '42501';
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION storage.protect_delete() OWNER TO supabase_storage_admin;

--
-- Name: search(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.search(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;
    v_delimiter CONSTANT TEXT := '/';

    -- Configuration
    v_limit INT;
    v_prefix TEXT;
    v_prefix_lower TEXT;
    v_is_asc BOOLEAN;
    v_order_by TEXT;
    v_sort_order TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;
    v_skipped INT := 0;
BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_limit := LEAST(coalesce(limits, 100), 1500);
    v_prefix := coalesce(prefix, '') || coalesce(search, '');
    v_prefix_lower := lower(v_prefix);
    v_is_asc := lower(coalesce(sortorder, 'asc')) = 'asc';
    v_file_batch_size := LEAST(GREATEST(v_limit * 2, 100), 1000);

    -- Validate sort column
    CASE lower(coalesce(sortcolumn, 'name'))
        WHEN 'name' THEN v_order_by := 'name';
        WHEN 'updated_at' THEN v_order_by := 'updated_at';
        WHEN 'created_at' THEN v_order_by := 'created_at';
        WHEN 'last_accessed_at' THEN v_order_by := 'last_accessed_at';
        ELSE v_order_by := 'name';
    END CASE;

    v_sort_order := CASE WHEN v_is_asc THEN 'asc' ELSE 'desc' END;

    -- ========================================================================
    -- NON-NAME SORTING: Use path_tokens approach (unchanged)
    -- ========================================================================
    IF v_order_by != 'name' THEN
        RETURN QUERY EXECUTE format(
            $sql$
            WITH folders AS (
                SELECT path_tokens[$1] AS folder
                FROM storage.objects
                WHERE objects.name ILIKE $2 || '%%'
                  AND bucket_id = $3
                  AND array_length(objects.path_tokens, 1) <> $1
                GROUP BY folder
                ORDER BY folder %s
            )
            (SELECT folder AS "name",
                   NULL::uuid AS id,
                   NULL::timestamptz AS updated_at,
                   NULL::timestamptz AS created_at,
                   NULL::timestamptz AS last_accessed_at,
                   NULL::jsonb AS metadata FROM folders)
            UNION ALL
            (SELECT path_tokens[$1] AS "name",
                   id, updated_at, created_at, last_accessed_at, metadata
             FROM storage.objects
             WHERE objects.name ILIKE $2 || '%%'
               AND bucket_id = $3
               AND array_length(objects.path_tokens, 1) = $1
             ORDER BY %I %s)
            LIMIT $4 OFFSET $5
            $sql$, v_sort_order, v_order_by, v_sort_order
        ) USING levels, v_prefix, bucketname, v_limit, offsets;
        RETURN;
    END IF;

    -- ========================================================================
    -- NAME SORTING: Hybrid skip-scan with batch optimization
    -- ========================================================================

    -- Calculate upper bound for prefix filtering
    IF v_prefix_lower = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix_lower, 1) = v_delimiter THEN
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(v_delimiter) + 1);
    ELSE
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(right(v_prefix_lower, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'AND lower(o.name) COLLATE "C" < $3 ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'AND lower(o.name) COLLATE "C" >= $3 ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- Initialize seek position
    IF v_is_asc THEN
        v_next_seek := v_prefix_lower;
    ELSE
        -- DESC: find the last item in range first (static SQL)
        IF v_upper_bound IS NOT NULL THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower AND lower(o.name) COLLATE "C" < v_upper_bound
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSIF v_prefix_lower <> '' THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSE
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        END IF;

        IF v_peek_name IS NOT NULL THEN
            v_next_seek := lower(v_peek_name) || v_delimiter;
        ELSE
            RETURN;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= v_limit;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek AND lower(o.name) COLLATE "C" < v_upper_bound
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix_lower <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(lower(v_peek_name), v_prefix_lower, v_delimiter);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Handle offset, emit if needed, skip to next folder
            IF v_skipped < offsets THEN
                v_skipped := v_skipped + 1;
            ELSE
                name := split_part(rtrim(storage.get_common_prefix(v_peek_name, v_prefix, v_delimiter), v_delimiter), v_delimiter, levels);
                id := NULL;
                updated_at := NULL;
                created_at := NULL;
                last_accessed_at := NULL;
                metadata := NULL;
                RETURN NEXT;
                v_count := v_count + 1;
            END IF;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := lower(left(v_common_prefix, -1)) || chr(ascii(v_delimiter) + 1);
            ELSE
                v_next_seek := lower(v_common_prefix);
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix_lower is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query
                USING bucketname, v_next_seek,
                    CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix_lower) ELSE v_prefix_lower END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(lower(v_current.name), v_prefix_lower, v_delimiter);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := lower(v_current.name);
                    EXIT;
                END IF;

                -- Handle offset skipping
                IF v_skipped < offsets THEN
                    v_skipped := v_skipped + 1;
                ELSE
                    -- Emit file
                    name := split_part(v_current.name, v_delimiter, levels);
                    id := v_current.id;
                    updated_at := v_current.updated_at;
                    created_at := v_current.created_at;
                    last_accessed_at := v_current.last_accessed_at;
                    metadata := v_current.metadata;
                    RETURN NEXT;
                    v_count := v_count + 1;
                END IF;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := lower(v_current.name) || v_delimiter;
                ELSE
                    v_next_seek := lower(v_current.name);
                END IF;

                EXIT WHEN v_count >= v_limit;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


ALTER FUNCTION storage.search(prefix text, bucketname text, limits integer, levels integer, offsets integer, search text, sortcolumn text, sortorder text) OWNER TO supabase_storage_admin;

--
-- Name: search_by_timestamp(text, text, integer, integer, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.search_by_timestamp(p_prefix text, p_bucket_id text, p_limit integer, p_level integer, p_start_after text, p_sort_order text, p_sort_column text, p_sort_column_after text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_cursor_op text;
    v_query text;
    v_prefix text;
BEGIN
    v_prefix := coalesce(p_prefix, '');

    IF p_sort_order = 'asc' THEN
        v_cursor_op := '>';
    ELSE
        v_cursor_op := '<';
    END IF;

    v_query := format($sql$
        WITH raw_objects AS (
            SELECT
                o.name AS obj_name,
                o.id AS obj_id,
                o.updated_at AS obj_updated_at,
                o.created_at AS obj_created_at,
                o.last_accessed_at AS obj_last_accessed_at,
                o.metadata AS obj_metadata,
                storage.get_common_prefix(o.name, $1, '/') AS common_prefix
            FROM storage.objects o
            WHERE o.bucket_id = $2
              AND o.name COLLATE "C" LIKE $1 || '%%'
        ),
        -- Aggregate common prefixes (folders)
        -- Both created_at and updated_at use MIN(obj_created_at) to match the old prefixes table behavior
        aggregated_prefixes AS (
            SELECT
                rtrim(common_prefix, '/') AS name,
                NULL::uuid AS id,
                MIN(obj_created_at) AS updated_at,
                MIN(obj_created_at) AS created_at,
                NULL::timestamptz AS last_accessed_at,
                NULL::jsonb AS metadata,
                TRUE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NOT NULL
            GROUP BY common_prefix
        ),
        leaf_objects AS (
            SELECT
                obj_name AS name,
                obj_id AS id,
                obj_updated_at AS updated_at,
                obj_created_at AS created_at,
                obj_last_accessed_at AS last_accessed_at,
                obj_metadata AS metadata,
                FALSE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NULL
        ),
        combined AS (
            SELECT * FROM aggregated_prefixes
            UNION ALL
            SELECT * FROM leaf_objects
        ),
        filtered AS (
            SELECT *
            FROM combined
            WHERE (
                $5 = ''
                OR ROW(
                    date_trunc('milliseconds', %I),
                    name COLLATE "C"
                ) %s ROW(
                    COALESCE(NULLIF($6, '')::timestamptz, 'epoch'::timestamptz),
                    $5
                )
            )
        )
        SELECT
            split_part(name, '/', $3) AS key,
            name,
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
        FROM filtered
        ORDER BY
            COALESCE(date_trunc('milliseconds', %I), 'epoch'::timestamptz) %s,
            name COLLATE "C" %s
        LIMIT $4
    $sql$,
        p_sort_column,
        v_cursor_op,
        p_sort_column,
        p_sort_order,
        p_sort_order
    );

    RETURN QUERY EXECUTE v_query
    USING v_prefix, p_bucket_id, p_level, p_limit, p_start_after, p_sort_column_after;
END;
$_$;


ALTER FUNCTION storage.search_by_timestamp(p_prefix text, p_bucket_id text, p_limit integer, p_level integer, p_start_after text, p_sort_order text, p_sort_column text, p_sort_column_after text) OWNER TO supabase_storage_admin;

--
-- Name: search_v2(text, text, integer, integer, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.search_v2(prefix text, bucket_name text, limits integer DEFAULT 100, levels integer DEFAULT 1, start_after text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text, sort_column text DEFAULT 'name'::text, sort_column_after text DEFAULT ''::text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    v_sort_col text;
    v_sort_ord text;
    v_limit int;
BEGIN
    -- Cap limit to maximum of 1500 records
    v_limit := LEAST(coalesce(limits, 100), 1500);

    -- Validate and normalize sort_order
    v_sort_ord := lower(coalesce(sort_order, 'asc'));
    IF v_sort_ord NOT IN ('asc', 'desc') THEN
        v_sort_ord := 'asc';
    END IF;

    -- Validate and normalize sort_column
    v_sort_col := lower(coalesce(sort_column, 'name'));
    IF v_sort_col NOT IN ('name', 'updated_at', 'created_at') THEN
        v_sort_col := 'name';
    END IF;

    -- Route to appropriate implementation
    IF v_sort_col = 'name' THEN
        -- Use list_objects_with_delimiter for name sorting (most efficient: O(k * log n))
        RETURN QUERY
        SELECT
            split_part(l.name, '/', levels) AS key,
            l.name AS name,
            l.id,
            l.updated_at,
            l.created_at,
            l.last_accessed_at,
            l.metadata
        FROM storage.list_objects_with_delimiter(
            bucket_name,
            coalesce(prefix, ''),
            '/',
            v_limit,
            start_after,
            '',
            v_sort_ord
        ) l;
    ELSE
        -- Use aggregation approach for timestamp sorting
        -- Not efficient for large datasets but supports correct pagination
        RETURN QUERY SELECT * FROM storage.search_by_timestamp(
            prefix, bucket_name, v_limit, levels, start_after,
            v_sort_ord, v_sort_col, sort_column_after
        );
    END IF;
END;
$$;


ALTER FUNCTION storage.search_v2(prefix text, bucket_name text, limits integer, levels integer, start_after text, sort_order text, sort_column text, sort_column_after text) OWNER TO supabase_storage_admin;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


ALTER FUNCTION storage.update_updated_at_column() OWNER TO supabase_storage_admin;

--
-- Name: secrets_encrypt_secret_secret(); Type: FUNCTION; Schema: vault; Owner: supabase_admin
--

CREATE FUNCTION vault.secrets_encrypt_secret_secret() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
		BEGIN
		        new.secret = CASE WHEN new.secret IS NULL THEN NULL ELSE
			CASE WHEN new.key_id IS NULL THEN NULL ELSE pg_catalog.encode(
			  pgsodium.crypto_aead_det_encrypt(
				pg_catalog.convert_to(new.secret, 'utf8'),
				pg_catalog.convert_to((new.id::text || new.description::text || new.created_at::text || new.updated_at::text)::text, 'utf8'),
				new.key_id::uuid,
				new.nonce
			  ),
				'base64') END END;
		RETURN new;
		END;
		$$;


ALTER FUNCTION vault.secrets_encrypt_secret_secret() OWNER TO supabase_admin;

--
-- Name: vietnamese; Type: TEXT SEARCH CONFIGURATION; Schema: public; Owner: postgres
--

CREATE TEXT SEARCH CONFIGURATION public.vietnamese (
    PARSER = pg_catalog."default" );

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR asciiword WITH extensions.unaccent, simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR word WITH extensions.unaccent, simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR numword WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR email WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR url WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR host WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR sfloat WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR version WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR hword_numpart WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR hword_part WITH extensions.unaccent, simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR hword_asciipart WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR numhword WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR asciihword WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR hword WITH extensions.unaccent, simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR url_path WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR file WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR "float" WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR "int" WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR uint WITH simple;


ALTER TEXT SEARCH CONFIGURATION public.vietnamese OWNER TO postgres;

--
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE auth.audit_log_entries OWNER TO supabase_auth_admin;

--
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- Name: custom_oauth_providers; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.custom_oauth_providers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider_type text NOT NULL,
    identifier text NOT NULL,
    name text NOT NULL,
    client_id text NOT NULL,
    client_secret text NOT NULL,
    acceptable_client_ids text[] DEFAULT '{}'::text[] NOT NULL,
    scopes text[] DEFAULT '{}'::text[] NOT NULL,
    pkce_enabled boolean DEFAULT true NOT NULL,
    attribute_mapping jsonb DEFAULT '{}'::jsonb NOT NULL,
    authorization_params jsonb DEFAULT '{}'::jsonb NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    email_optional boolean DEFAULT false NOT NULL,
    issuer text,
    discovery_url text,
    skip_nonce_check boolean DEFAULT false NOT NULL,
    cached_discovery jsonb,
    discovery_cached_at timestamp with time zone,
    authorization_url text,
    token_url text,
    userinfo_url text,
    jwks_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    custom_claims_allowlist text[] DEFAULT '{}'::text[] NOT NULL,
    CONSTRAINT custom_oauth_providers_authorization_url_https CHECK (((authorization_url IS NULL) OR (authorization_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_authorization_url_length CHECK (((authorization_url IS NULL) OR (char_length(authorization_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_client_id_length CHECK (((char_length(client_id) >= 1) AND (char_length(client_id) <= 512))),
    CONSTRAINT custom_oauth_providers_discovery_url_length CHECK (((discovery_url IS NULL) OR (char_length(discovery_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_identifier_format CHECK ((identifier ~ '^[a-z0-9][a-z0-9:-]{0,48}[a-z0-9]$'::text)),
    CONSTRAINT custom_oauth_providers_issuer_length CHECK (((issuer IS NULL) OR ((char_length(issuer) >= 1) AND (char_length(issuer) <= 2048)))),
    CONSTRAINT custom_oauth_providers_jwks_uri_https CHECK (((jwks_uri IS NULL) OR (jwks_uri ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_jwks_uri_length CHECK (((jwks_uri IS NULL) OR (char_length(jwks_uri) <= 2048))),
    CONSTRAINT custom_oauth_providers_name_length CHECK (((char_length(name) >= 1) AND (char_length(name) <= 100))),
    CONSTRAINT custom_oauth_providers_oauth2_requires_endpoints CHECK (((provider_type <> 'oauth2'::text) OR ((authorization_url IS NOT NULL) AND (token_url IS NOT NULL) AND (userinfo_url IS NOT NULL)))),
    CONSTRAINT custom_oauth_providers_oidc_discovery_url_https CHECK (((provider_type <> 'oidc'::text) OR (discovery_url IS NULL) OR (discovery_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_oidc_issuer_https CHECK (((provider_type <> 'oidc'::text) OR (issuer IS NULL) OR (issuer ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_oidc_requires_issuer CHECK (((provider_type <> 'oidc'::text) OR (issuer IS NOT NULL))),
    CONSTRAINT custom_oauth_providers_provider_type_check CHECK ((provider_type = ANY (ARRAY['oauth2'::text, 'oidc'::text]))),
    CONSTRAINT custom_oauth_providers_token_url_https CHECK (((token_url IS NULL) OR (token_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_token_url_length CHECK (((token_url IS NULL) OR (char_length(token_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_userinfo_url_https CHECK (((userinfo_url IS NULL) OR (userinfo_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_userinfo_url_length CHECK (((userinfo_url IS NULL) OR (char_length(userinfo_url) <= 2048)))
);


ALTER TABLE auth.custom_oauth_providers OWNER TO supabase_auth_admin;

--
-- Name: flow_state; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.flow_state (
    id uuid NOT NULL,
    user_id uuid,
    auth_code text,
    code_challenge_method auth.code_challenge_method,
    code_challenge text,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    authentication_method text NOT NULL,
    auth_code_issued_at timestamp with time zone,
    invite_token text,
    referrer text,
    oauth_client_state_id uuid,
    linking_target_id uuid,
    email_optional boolean DEFAULT false NOT NULL
);


ALTER TABLE auth.flow_state OWNER TO supabase_auth_admin;

--
-- Name: TABLE flow_state; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.flow_state IS 'Stores metadata for all OAuth/SSO login flows';


--
-- Name: identities; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.identities (
    provider_id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE auth.identities OWNER TO supabase_auth_admin;

--
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- Name: COLUMN identities.email; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.identities.email IS 'Auth: Email is a generated column that references the optional email property in the identity_data';


--
-- Name: instances; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE auth.instances OWNER TO supabase_auth_admin;

--
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- Name: mfa_amr_claims; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.mfa_amr_claims (
    session_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    authentication_method text NOT NULL,
    id uuid NOT NULL
);


ALTER TABLE auth.mfa_amr_claims OWNER TO supabase_auth_admin;

--
-- Name: TABLE mfa_amr_claims; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.mfa_amr_claims IS 'auth: stores authenticator method reference claims for multi factor authentication';


--
-- Name: mfa_challenges; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.mfa_challenges (
    id uuid NOT NULL,
    factor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    ip_address inet NOT NULL,
    otp_code text,
    web_authn_session_data jsonb
);


ALTER TABLE auth.mfa_challenges OWNER TO supabase_auth_admin;

--
-- Name: TABLE mfa_challenges; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.mfa_challenges IS 'auth: stores metadata about challenge requests made';


--
-- Name: mfa_factors; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.mfa_factors (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    secret text,
    phone text,
    last_challenged_at timestamp with time zone,
    web_authn_credential jsonb,
    web_authn_aaguid uuid,
    last_webauthn_challenge_data jsonb
);


ALTER TABLE auth.mfa_factors OWNER TO supabase_auth_admin;

--
-- Name: TABLE mfa_factors; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.mfa_factors IS 'auth: stores metadata about factors';


--
-- Name: COLUMN mfa_factors.last_webauthn_challenge_data; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.mfa_factors.last_webauthn_challenge_data IS 'Stores the latest WebAuthn challenge data including attestation/assertion for customer verification';


--
-- Name: oauth_authorizations; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.oauth_authorizations (
    id uuid NOT NULL,
    authorization_id text NOT NULL,
    client_id uuid NOT NULL,
    user_id uuid,
    redirect_uri text NOT NULL,
    scope text NOT NULL,
    state text,
    resource text,
    code_challenge text,
    code_challenge_method auth.code_challenge_method,
    response_type auth.oauth_response_type DEFAULT 'code'::auth.oauth_response_type NOT NULL,
    status auth.oauth_authorization_status DEFAULT 'pending'::auth.oauth_authorization_status NOT NULL,
    authorization_code text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '00:03:00'::interval) NOT NULL,
    approved_at timestamp with time zone,
    nonce text,
    CONSTRAINT oauth_authorizations_authorization_code_length CHECK ((char_length(authorization_code) <= 255)),
    CONSTRAINT oauth_authorizations_code_challenge_length CHECK ((char_length(code_challenge) <= 128)),
    CONSTRAINT oauth_authorizations_expires_at_future CHECK ((expires_at > created_at)),
    CONSTRAINT oauth_authorizations_nonce_length CHECK ((char_length(nonce) <= 255)),
    CONSTRAINT oauth_authorizations_redirect_uri_length CHECK ((char_length(redirect_uri) <= 2048)),
    CONSTRAINT oauth_authorizations_resource_length CHECK ((char_length(resource) <= 2048)),
    CONSTRAINT oauth_authorizations_scope_length CHECK ((char_length(scope) <= 4096)),
    CONSTRAINT oauth_authorizations_state_length CHECK ((char_length(state) <= 4096))
);


ALTER TABLE auth.oauth_authorizations OWNER TO supabase_auth_admin;

--
-- Name: oauth_client_states; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.oauth_client_states (
    id uuid NOT NULL,
    provider_type text NOT NULL,
    code_verifier text,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE auth.oauth_client_states OWNER TO supabase_auth_admin;

--
-- Name: TABLE oauth_client_states; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.oauth_client_states IS 'Stores OAuth states for third-party provider authentication flows where Supabase acts as the OAuth client.';


--
-- Name: oauth_clients; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.oauth_clients (
    id uuid NOT NULL,
    client_secret_hash text,
    registration_type auth.oauth_registration_type NOT NULL,
    redirect_uris text NOT NULL,
    grant_types text NOT NULL,
    client_name text,
    client_uri text,
    logo_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    client_type auth.oauth_client_type DEFAULT 'confidential'::auth.oauth_client_type NOT NULL,
    token_endpoint_auth_method text NOT NULL,
    CONSTRAINT oauth_clients_client_name_length CHECK ((char_length(client_name) <= 1024)),
    CONSTRAINT oauth_clients_client_uri_length CHECK ((char_length(client_uri) <= 2048)),
    CONSTRAINT oauth_clients_logo_uri_length CHECK ((char_length(logo_uri) <= 2048)),
    CONSTRAINT oauth_clients_token_endpoint_auth_method_check CHECK ((token_endpoint_auth_method = ANY (ARRAY['client_secret_basic'::text, 'client_secret_post'::text, 'none'::text])))
);


ALTER TABLE auth.oauth_clients OWNER TO supabase_auth_admin;

--
-- Name: oauth_consents; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.oauth_consents (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    client_id uuid NOT NULL,
    scopes text NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    CONSTRAINT oauth_consents_revoked_after_granted CHECK (((revoked_at IS NULL) OR (revoked_at >= granted_at))),
    CONSTRAINT oauth_consents_scopes_length CHECK ((char_length(scopes) <= 2048)),
    CONSTRAINT oauth_consents_scopes_not_empty CHECK ((char_length(TRIM(BOTH FROM scopes)) > 0))
);


ALTER TABLE auth.oauth_consents OWNER TO supabase_auth_admin;

--
-- Name: one_time_tokens; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.one_time_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_type auth.one_time_token_type NOT NULL,
    token_hash text NOT NULL,
    relates_to text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT one_time_tokens_token_hash_check CHECK ((char_length(token_hash) > 0))
);


ALTER TABLE auth.one_time_tokens OWNER TO supabase_auth_admin;

--
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255),
    session_id uuid
);


ALTER TABLE auth.refresh_tokens OWNER TO supabase_auth_admin;

--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: supabase_auth_admin
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE auth.refresh_tokens_id_seq OWNER TO supabase_auth_admin;

--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: supabase_auth_admin
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- Name: saml_providers; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.saml_providers (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name_id_format text,
    CONSTRAINT "entity_id not empty" CHECK ((char_length(entity_id) > 0)),
    CONSTRAINT "metadata_url not empty" CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK ((char_length(metadata_xml) > 0))
);


ALTER TABLE auth.saml_providers OWNER TO supabase_auth_admin;

--
-- Name: TABLE saml_providers; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.saml_providers IS 'Auth: Manages SAML Identity Provider connections.';


--
-- Name: saml_relay_states; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.saml_relay_states (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    flow_state_id uuid,
    CONSTRAINT "request_id not empty" CHECK ((char_length(request_id) > 0))
);


ALTER TABLE auth.saml_relay_states OWNER TO supabase_auth_admin;

--
-- Name: TABLE saml_relay_states; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.saml_relay_states IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';


--
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


ALTER TABLE auth.schema_migrations OWNER TO supabase_auth_admin;

--
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- Name: sessions; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    factor_id uuid,
    aal auth.aal_level,
    not_after timestamp with time zone,
    refreshed_at timestamp without time zone,
    user_agent text,
    ip inet,
    tag text,
    oauth_client_id uuid,
    refresh_token_hmac_key text,
    refresh_token_counter bigint,
    scopes text,
    CONSTRAINT sessions_scopes_length CHECK ((char_length(scopes) <= 4096))
);


ALTER TABLE auth.sessions OWNER TO supabase_auth_admin;

--
-- Name: TABLE sessions; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.sessions IS 'Auth: Stores session data associated to a user.';


--
-- Name: COLUMN sessions.not_after; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.sessions.not_after IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';


--
-- Name: COLUMN sessions.refresh_token_hmac_key; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.sessions.refresh_token_hmac_key IS 'Holds a HMAC-SHA256 key used to sign refresh tokens for this session.';


--
-- Name: COLUMN sessions.refresh_token_counter; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.sessions.refresh_token_counter IS 'Holds the ID (counter) of the last issued refresh token.';


--
-- Name: sso_domains; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.sso_domains (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK ((char_length(domain) > 0))
);


ALTER TABLE auth.sso_domains OWNER TO supabase_auth_admin;

--
-- Name: TABLE sso_domains; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.sso_domains IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';


--
-- Name: sso_providers; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.sso_providers (
    id uuid NOT NULL,
    resource_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    disabled boolean,
    CONSTRAINT "resource_id not empty" CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
);


ALTER TABLE auth.sso_providers OWNER TO supabase_auth_admin;

--
-- Name: TABLE sso_providers; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.sso_providers IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';


--
-- Name: COLUMN sso_providers.resource_id; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.sso_providers.resource_id IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';


--
-- Name: users; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    is_anonymous boolean DEFAULT false NOT NULL,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


ALTER TABLE auth.users OWNER TO supabase_auth_admin;

--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


--
-- Name: webauthn_challenges; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.webauthn_challenges (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    challenge_type text NOT NULL,
    session_data jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    CONSTRAINT webauthn_challenges_challenge_type_check CHECK ((challenge_type = ANY (ARRAY['signup'::text, 'registration'::text, 'authentication'::text])))
);


ALTER TABLE auth.webauthn_challenges OWNER TO supabase_auth_admin;

--
-- Name: webauthn_credentials; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.webauthn_credentials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    credential_id bytea NOT NULL,
    public_key bytea NOT NULL,
    attestation_type text DEFAULT ''::text NOT NULL,
    aaguid uuid,
    sign_count bigint DEFAULT 0 NOT NULL,
    transports jsonb DEFAULT '[]'::jsonb NOT NULL,
    backup_eligible boolean DEFAULT false NOT NULL,
    backed_up boolean DEFAULT false NOT NULL,
    friendly_name text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    last_used_at timestamp with time zone
);


ALTER TABLE auth.webauthn_credentials OWNER TO supabase_auth_admin;

--
-- Name: achievement; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.achievement (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    sport bigint,
    xp_reward bigint NOT NULL,
    repeatable boolean DEFAULT false NOT NULL,
    code text NOT NULL,
    criteria jsonb NOT NULL,
    difficulty smallint,
    consistency smallint,
    CONSTRAINT achievement_criteria_valid CHECK (((criteria IS NULL) OR (((criteria ->> 'source'::text) = ANY (ARRAY['daily'::text, 'activity'::text, 'special'::text, 'social'::text])) AND ((criteria ->> 'agg'::text) = ANY (ARRAY['sum'::text, 'count'::text, 'max'::text, 'session_streak'::text, 'special'::text])) AND (((criteria ->> 'window'::text) IS NULL) OR ((criteria ->> 'window'::text) = ANY (ARRAY['day'::text, 'week'::text, 'month'::text, 'all_time'::text]))) AND ((repeatable IS NOT TRUE) OR ((criteria ->> 'window'::text) = ANY (ARRAY['week'::text, 'month'::text]))) AND (((criteria ->> 'agg'::text) <> 'session_streak'::text) OR (((criteria ->> 'source'::text) = 'activity'::text) AND (criteria ? 'session_min'::text))) AND (((criteria ->> 'source'::text) = 'special'::text) = ((criteria ->> 'agg'::text) = 'special'::text))))),
    CONSTRAINT achievement_tier_valid CHECK ((((difficulty IS NULL) OR ((difficulty >= 1) AND (difficulty <= 3))) AND ((consistency IS NULL) OR ((consistency >= 1) AND (consistency <= 3)))))
);


ALTER TABLE public.achievement OWNER TO postgres;

--
-- Name: TABLE achievement; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.achievement IS 'activities for users to earn XP and level up';


--
-- Name: activity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activity (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    sport_id bigint NOT NULL,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone,
    lobby_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    location_id uuid,
    confirmation_threshold integer,
    confirmation_deadline timestamp with time zone,
    recurrence_day_of_week smallint,
    referee_booking_id uuid,
    challenge_id uuid,
    manager_confirmed_at timestamp with time zone,
    cost_type public.activity_cost_type,
    cost_amount numeric(10,2),
    series_id uuid,
    freeplay_host_id uuid,
    course_id uuid,
    proposed_by uuid,
    proposal_status public.activity_proposal_status,
    note text,
    at_risk_notified_at timestamp with time zone,
    threshold_override_at timestamp with time zone,
    CONSTRAINT activity_confirmation_deadline_validity CHECK (((confirmation_deadline IS NULL) OR (confirmation_deadline < start_time))),
    CONSTRAINT activity_confirmation_threshold_validity CHECK (((confirmation_threshold IS NULL) OR (confirmation_threshold > 0))),
    CONSTRAINT activity_cost_validity CHECK ((((cost_type IS NULL) = (cost_amount IS NULL)) AND ((cost_amount IS NULL) OR (cost_amount > (0)::numeric)))),
    CONSTRAINT activity_course_has_proposal_status CHECK (((course_id IS NULL) = (proposal_status IS NULL))),
    CONSTRAINT activity_note_length CHECK (((note IS NULL) OR (char_length(note) <= 280))),
    CONSTRAINT activity_recurrence_day_validity CHECK (((recurrence_day_of_week IS NULL) OR ((recurrence_day_of_week >= 0) AND (recurrence_day_of_week <= 6)))),
    CONSTRAINT activity_source_exclusivity CHECK ((num_nonnulls(lobby_id, freeplay_host_id, course_id) <= 1)),
    CONSTRAINT activity_time_validity CHECK (((end_time IS NULL) OR (end_time > start_time)))
);


ALTER TABLE public.activity OWNER TO postgres;

--
-- Name: TABLE activity; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.activity IS 'User activity sessions - can be linked to lobby or professional booking';


--
-- Name: COLUMN activity.location_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.activity.location_id IS 'Where the session is held. App defaults this to the lobby''s home_ground when creating an activity.';


--
-- Name: COLUMN activity.confirmation_threshold; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.activity.confirmation_threshold IS 'Minimum confirmed members for the activity to be "official". NULL = no threshold.';


--
-- Name: COLUMN activity.confirmation_deadline; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.activity.confirmation_deadline IS 'Cutoff for accepting confirmations. NULL = no cutoff. Form defaults this to 2 days before start_time; auto-off when the session is less than 2 days out.';


--
-- Name: COLUMN activity.recurrence_day_of_week; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.activity.recurrence_day_of_week IS 'Weekly recurrence anchor (0=Mon … 6=Sun, ISO ordering). NULL = one-off. Recurrence is virtual — occurrences aren''t materialised; the app derives next-occurrence from start_time + this day.';


--
-- Name: COLUMN activity.manager_confirmed_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.activity.manager_confirmed_at IS 'A challenge activity becomes official on RSVP quorum AND an explicit manager confirmation; this is the second half. NULL on ordinary activities, whose "official" is derived from the going-count vs confirmation_threshold alone.';


--
-- Name: COLUMN activity.cost_amount; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.activity.cost_amount IS 'Informational cost, settled post-session by the payment-request feature — not a deposit or a charge at scheduling time.';


--
-- Name: COLUMN activity.at_risk_notified_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.activity.at_risk_notified_at IS 'Set once by fn_sweep_activity_thresholds when confirmation_deadline passes while still under confirmation_threshold. Doubles as the once-only notify flag and the sticky post-deadline RLS freeze on activity_confirmation (see the policies below).';


--
-- Name: COLUMN activity.threshold_override_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.activity.threshold_override_at IS 'Set by resolve_at_risk_activity_organizer(''confirm''). Once set, activity_is_confirmed() treats the activity as permanently confirmed regardless of going count — same footing as naturally reaching quorum.';


--
-- Name: activity_confirmation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activity_confirmation (
    activity_id uuid NOT NULL,
    user_id uuid NOT NULL,
    confirmed_at timestamp with time zone DEFAULT now() NOT NULL,
    deposit_da integer DEFAULT 0 NOT NULL,
    attendance public.activity_attendance DEFAULT 'going'::public.activity_attendance NOT NULL,
    CONSTRAINT activity_confirmation_deposit_da_check CHECK ((deposit_da >= 0))
);


ALTER TABLE public.activity_confirmation OWNER TO postgres;

--
-- Name: TABLE activity_confirmation; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.activity_confirmation IS 'Members who have committed to attending an activity. Row count is compared against activity.confirmation_threshold to determine whether the session is "official". deposit_da records the Đá held when activity.payment_type = ''da''.';


--
-- Name: activity_hr_sample; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activity_hr_sample (
    id bigint NOT NULL,
    activity_id uuid NOT NULL,
    "timestamp" timestamp with time zone NOT NULL,
    bpm smallint NOT NULL,
    CONSTRAINT hr_sample_bpm_validity CHECK (((bpm >= 30) AND (bpm <= 250)))
);


ALTER TABLE public.activity_hr_sample OWNER TO postgres;

--
-- Name: TABLE activity_hr_sample; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.activity_hr_sample IS 'Raw heart rate samples during activities - enables HR curve reconstruction and detailed analysis';


--
-- Name: activity_hr_sample_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.activity_hr_sample ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.activity_hr_sample_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: activity_reminder_sent; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activity_reminder_sent (
    activity_id uuid NOT NULL,
    sent_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.activity_reminder_sent OWNER TO postgres;

--
-- Name: activity_series_frontier; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activity_series_frontier (
    series_id uuid NOT NULL,
    frontier_start timestamp with time zone NOT NULL
);


ALTER TABLE public.activity_series_frontier OWNER TO postgres;

--
-- Name: badminton_profile; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.badminton_profile (
    user_id uuid NOT NULL,
    dominant_hand text,
    discipline text[] DEFAULT '{}'::text[] NOT NULL,
    elo_seed text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.badminton_profile OWNER TO postgres;

--
-- Name: basketball_profile; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.basketball_profile (
    user_id uuid NOT NULL,
    "position" text[] DEFAULT '{}'::text[] NOT NULL,
    pitch text[] DEFAULT '{}'::text[] NOT NULL,
    elo_seed text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.basketball_profile OWNER TO postgres;

--
-- Name: conversation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conversation (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    kind public.conversation_kind NOT NULL,
    freeplay_request_id uuid,
    course_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT conversation_kind_matches_owner CHECK ((((kind = 'freeplay'::public.conversation_kind) AND (freeplay_request_id IS NOT NULL)) OR ((kind = 'course'::public.conversation_kind) AND (course_id IS NOT NULL)))),
    CONSTRAINT conversation_owner_exclusivity CHECK ((num_nonnulls(freeplay_request_id, course_id) = 1))
);


ALTER TABLE public.conversation OWNER TO postgres;

--
-- Name: conversation_member; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conversation_member (
    conversation_id uuid NOT NULL,
    user_id uuid NOT NULL,
    joined_at timestamp with time zone DEFAULT now() NOT NULL,
    left_at timestamp with time zone,
    last_read_at timestamp with time zone DEFAULT '-infinity'::timestamp with time zone NOT NULL,
    CONSTRAINT conversation_member_window CHECK (((left_at IS NULL) OR (left_at >= joined_at)))
);


ALTER TABLE public.conversation_member OWNER TO postgres;

--
-- Name: course; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    professional_id uuid NOT NULL,
    sport_id bigint NOT NULL,
    name text,
    description text,
    target_session_count integer,
    status public.course_status DEFAULT 'active'::public.course_status NOT NULL,
    target_reached_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    ended_at timestamp with time zone,
    CONSTRAINT course_description_check CHECK (((description IS NULL) OR (char_length(description) <= 2000))),
    CONSTRAINT course_ended_has_timestamp CHECK (((status = 'ended'::public.course_status) = (ended_at IS NOT NULL))),
    CONSTRAINT course_name_check CHECK (((name IS NULL) OR ((char_length(btrim(name)) >= 1) AND (char_length(btrim(name)) <= 80)))),
    CONSTRAINT course_target_session_count_check CHECK (((target_session_count IS NULL) OR ((target_session_count >= 1) AND (target_session_count <= 200))))
);


ALTER TABLE public.course OWNER TO postgres;

--
-- Name: course_enrollment_offer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course_enrollment_offer (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    course_id uuid NOT NULL,
    user_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    target_session_count integer,
    status public.course_offer_status DEFAULT 'pending'::public.course_offer_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    responded_at timestamp with time zone,
    CONSTRAINT course_enrollment_offer_description_check CHECK (((description IS NULL) OR (char_length(description) <= 2000))),
    CONSTRAINT course_enrollment_offer_name_check CHECK (((char_length(btrim(name)) >= 1) AND (char_length(btrim(name)) <= 80))),
    CONSTRAINT course_enrollment_offer_target_session_count_check CHECK (((target_session_count IS NULL) OR ((target_session_count >= 1) AND (target_session_count <= 200))))
);


ALTER TABLE public.course_enrollment_offer OWNER TO postgres;

--
-- Name: course_member; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course_member (
    course_id uuid NOT NULL,
    user_id uuid NOT NULL,
    status public.course_member_status DEFAULT 'inquiring'::public.course_member_status NOT NULL,
    professional_id uuid NOT NULL,
    sport_id bigint NOT NULL,
    joined_at timestamp with time zone DEFAULT now() NOT NULL,
    left_at timestamp with time zone,
    CONSTRAINT course_member_departed_has_timestamp CHECK (((status = ANY (ARRAY['left'::public.course_member_status, 'removed'::public.course_member_status])) = (left_at IS NOT NULL)))
);


ALTER TABLE public.course_member OWNER TO postgres;

--
-- Name: course_review; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course_review (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    course_id uuid NOT NULL,
    student_id uuid NOT NULL,
    rating smallint NOT NULL,
    comment text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT course_review_comment_check CHECK (((comment IS NULL) OR (char_length(comment) <= 1000))),
    CONSTRAINT course_review_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.course_review OWNER TO postgres;

--
-- Name: course_session_report; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course_session_report (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    course_id uuid NOT NULL,
    activity_id uuid NOT NULL,
    student_id uuid NOT NULL,
    body text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT course_session_report_body_check CHECK (((char_length(btrim(body)) >= 1) AND (char_length(btrim(body)) <= 1000)))
);


ALTER TABLE public.course_session_report OWNER TO postgres;

--
-- Name: daily_health_summary; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.daily_health_summary (
    user_id uuid NOT NULL,
    date date NOT NULL,
    resting_heart_rate integer,
    hrv_sdnn_ms real,
    steps integer,
    distance_meters real,
    active_calories real,
    total_calories real,
    sleep_minutes integer,
    sleep_quality_score real,
    weight_kg real,
    activity_count integer DEFAULT 0,
    total_activity_minutes integer DEFAULT 0,
    synced_at timestamp with time zone DEFAULT now() NOT NULL,
    hrv_rmssd_ms real,
    CONSTRAINT resting_hr_validity CHECK (((resting_heart_rate IS NULL) OR ((resting_heart_rate >= 30) AND (resting_heart_rate <= 150))))
);


ALTER TABLE public.daily_health_summary OWNER TO postgres;

--
-- Name: TABLE daily_health_summary; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.daily_health_summary IS 'Daily health metrics for long-term trend analysis';


--
-- Name: enabled_notification_kind; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.enabled_notification_kind (
    kind public.notification_kind NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.enabled_notification_kind OWNER TO postgres;

--
-- Name: freeplay_activity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.freeplay_activity (
    activity_id uuid NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    capacity integer NOT NULL,
    male_price numeric(10,2) NOT NULL,
    female_price numeric(10,2) NOT NULL,
    recommended_skills text[] NOT NULL,
    venue_name text,
    street_address text,
    city_cluster bigint,
    ward text,
    intake_closed_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT freeplay_activity_capacity_check CHECK (((capacity >= 1) AND (capacity <= 200))),
    CONSTRAINT freeplay_activity_description_check CHECK ((char_length(description) <= 2000)),
    CONSTRAINT freeplay_activity_female_price_check CHECK ((female_price > (0)::numeric)),
    CONSTRAINT freeplay_activity_male_price_check CHECK ((male_price > (0)::numeric)),
    CONSTRAINT freeplay_activity_recommended_skills_check CHECK (((cardinality(recommended_skills) > 0) AND (recommended_skills <@ ARRAY['beginner'::text, 'casual'::text, 'fair'::text, 'good'::text, 'advanced'::text]))),
    CONSTRAINT freeplay_free_venue_complete CHECK ((((venue_name IS NULL) AND (street_address IS NULL) AND (ward IS NULL)) OR ((char_length(btrim(venue_name)) > 0) AND (char_length(btrim(street_address)) > 0) AND (city_cluster IS NOT NULL) AND (char_length(btrim(ward)) > 0))))
);


ALTER TABLE public.freeplay_activity OWNER TO postgres;

--
-- Name: freeplay_host; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.freeplay_host (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    display_name text NOT NULL,
    avatar_url text,
    bio text DEFAULT ''::text NOT NULL,
    status public.freeplay_host_status DEFAULT 'active'::public.freeplay_host_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT freeplay_host_bio_check CHECK ((char_length(bio) <= 500)),
    CONSTRAINT freeplay_host_display_name_check CHECK (((char_length(btrim(display_name)) >= 1) AND (char_length(btrim(display_name)) <= 80)))
);


ALTER TABLE public.freeplay_host OWNER TO postgres;

--
-- Name: COLUMN freeplay_host.display_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.freeplay_host.display_name IS 'Public Host name, independent from the linked user account username.';


--
-- Name: freeplay_request; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.freeplay_request (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    activity_id uuid NOT NULL,
    user_id uuid NOT NULL,
    status public.freeplay_request_status DEFAULT 'pending'::public.freeplay_request_status NOT NULL,
    price_amount numeric(10,2) NOT NULL,
    gender text NOT NULL,
    skill text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    resolved_at timestamp with time zone,
    CONSTRAINT freeplay_request_gender_check CHECK ((gender = ANY (ARRAY['male'::text, 'female'::text]))),
    CONSTRAINT freeplay_request_price_amount_check CHECK ((price_amount > (0)::numeric)),
    CONSTRAINT freeplay_request_skill_check CHECK (((skill IS NULL) OR (skill = ANY (ARRAY['beginner'::text, 'casual'::text, 'fair'::text, 'good'::text, 'advanced'::text]))))
);


ALTER TABLE public.freeplay_request OWNER TO postgres;

--
-- Name: friendship; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.friendship (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    requester_id uuid NOT NULL,
    addressee_id uuid NOT NULL,
    status public.friendship_status DEFAULT 'pending'::public.friendship_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    responded_at timestamp with time zone,
    CONSTRAINT friendship_distinct CHECK ((requester_id <> addressee_id))
);


ALTER TABLE public.friendship OWNER TO postgres;

--
-- Name: industry; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.industry (
    id integer NOT NULL,
    name character varying(128) NOT NULL
);


ALTER TABLE public.industry OWNER TO postgres;

--
-- Name: industry_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.industry_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.industry_id_seq OWNER TO postgres;

--
-- Name: industry_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.industry_id_seq OWNED BY public.industry.id;


--
-- Name: lobby; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lobby (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    captain_id uuid NOT NULL,
    searchable_id text DEFAULT public.nanoid(8) NOT NULL,
    name text NOT NULL,
    sport_id bigint NOT NULL,
    playtime jsonb,
    details jsonb,
    home_ground uuid,
    visibility public.lobby_visibility DEFAULT 'discoverable'::public.lobby_visibility,
    open_to_challengers boolean DEFAULT false NOT NULL,
    mmr integer DEFAULT 1000 NOT NULL,
    member_count integer DEFAULT 0 NOT NULL,
    network_ids bigint[] DEFAULT '{}'::bigint[] NOT NULL,
    active_network_ids bigint[] DEFAULT '{}'::bigint[] NOT NULL,
    industry_ids integer[] DEFAULT '{}'::integer[] NOT NULL,
    playtime_keys text[] DEFAULT '{}'::text[] NOT NULL,
    challenge_offer_time timestamp with time zone,
    challenge_offer_location uuid,
    challenge_offer_cost numeric(10,2),
    rated_match_count integer DEFAULT 0 NOT NULL,
    CONSTRAINT lobby_challenge_offer_complete CHECK (((NOT open_to_challengers) OR ((challenge_offer_time IS NOT NULL) AND (challenge_offer_location IS NOT NULL) AND (challenge_offer_cost IS NOT NULL))))
);


ALTER TABLE public.lobby OWNER TO postgres;

--
-- Name: COLUMN lobby.challenge_offer_cost; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.lobby.challenge_offer_cost IS 'Cost per team for the offered match, EXCLUDING the referee fee (the referee is hired separately by the home team and settled out of band). Informational — there is no ledger.';


--
-- Name: lobby_befriend_record; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lobby_befriend_record (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    initiator_user_id uuid NOT NULL,
    target_user_id uuid,
    target_lobby_id uuid,
    interaction_type public.lobby_befriend_interaction NOT NULL,
    status public.lobby_befriend_status DEFAULT 'pending'::public.lobby_befriend_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now(),
    details jsonb,
    CONSTRAINT befriend_record_invite_conditions CHECK (((interaction_type <> 'invite'::public.lobby_befriend_interaction) OR (target_user_id IS NOT NULL))),
    CONSTRAINT befriend_record_pair_conditions CHECK (((interaction_type <> 'pair'::public.lobby_befriend_interaction) OR ((target_user_id IS NOT NULL) AND (target_lobby_id IS NULL) AND (initiator_user_id <> target_user_id)))),
    CONSTRAINT befriend_record_request_conditions CHECK (((interaction_type <> 'request'::public.lobby_befriend_interaction) OR ((target_user_id IS NULL) AND (target_lobby_id IS NOT NULL))))
);


ALTER TABLE public.lobby_befriend_record OWNER TO postgres;

--
-- Name: lobby_challenge; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lobby_challenge (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    initiator_lobby_id uuid NOT NULL,
    target_lobby_id uuid NOT NULL,
    sport_id bigint NOT NULL,
    status public.lobby_challenge_status DEFAULT 'requested'::public.lobby_challenge_status NOT NULL,
    proposed_time timestamp with time zone,
    proposed_location uuid,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    agreed_cost numeric(10,2),
    CONSTRAINT lobby_challenge_distinct CHECK ((initiator_lobby_id <> target_lobby_id))
);


ALTER TABLE public.lobby_challenge OWNER TO postgres;

--
-- Name: lobby_feed_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lobby_feed_item (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lobby_id uuid NOT NULL,
    author_id uuid,
    kind public.lobby_feed_item_kind NOT NULL,
    payload jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    activity_id uuid,
    CONSTRAINT lobby_feed_item_activity_note_shape CHECK (((kind <> 'personal'::public.lobby_feed_item_kind) OR ((payload ->> 'action_kind'::text) <> 'note'::text) OR ((activity_id IS NOT NULL) AND (jsonb_typeof((payload -> 'detail'::text)) = 'string'::text) AND ((char_length(btrim((payload ->> 'detail'::text))) >= 1) AND (char_length(btrim((payload ->> 'detail'::text))) <= 72))))),
    CONSTRAINT lobby_feed_item_payload_shape CHECK ((((kind = 'update'::public.lobby_feed_item_kind) AND (payload ? 'title'::text) AND (payload ? 'kind'::text) AND (payload ? 'tone'::text) AND (payload ? 'fields'::text)) OR ((kind = 'personal'::public.lobby_feed_item_kind) AND (payload ? 'action_kind'::text)) OR ((kind = 'system'::public.lobby_feed_item_kind) AND (payload ? 'text'::text)) OR ((kind = 'poll'::public.lobby_feed_item_kind) AND (payload ? 'question'::text) AND (payload ? 'options'::text)) OR ((kind = 'photo'::public.lobby_feed_item_kind) AND (payload ? 'storage_path'::text)) OR ((kind = 'payment_request'::public.lobby_feed_item_kind) AND (payload ? 'type'::text) AND (payload ? 'recipient_id'::text) AND (payload ? 'total_amount'::text) AND (payload ? 'per_person_amount'::text))))
);


ALTER TABLE public.lobby_feed_item OWNER TO postgres;

--
-- Name: TABLE lobby_feed_item; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.lobby_feed_item IS 'Action-stream entries for a lobby''s activity tab. Payload shape varies by kind — see CHECK constraint and lib/manage_tab/lobby_section/activity/feed.dart for the canonical schemas.';


--
-- Name: lobby_feed_item_reaction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lobby_feed_item_reaction (
    feed_item_id uuid NOT NULL,
    user_id uuid NOT NULL,
    emoji text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT lobby_feed_item_reaction_emoji_check CHECK (((char_length(emoji) >= 1) AND (char_length(emoji) <= 8)))
);


ALTER TABLE public.lobby_feed_item_reaction OWNER TO postgres;

--
-- Name: lobby_feed_poll_vote; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lobby_feed_poll_vote (
    feed_item_id uuid NOT NULL,
    user_id uuid NOT NULL,
    option_index integer NOT NULL,
    voted_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT lobby_feed_poll_vote_option_index_check CHECK ((option_index >= 0))
);


ALTER TABLE public.lobby_feed_poll_vote OWNER TO postgres;

--
-- Name: TABLE lobby_feed_poll_vote; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.lobby_feed_poll_vote IS 'Member votes against a feed-item poll. option_index points into the payload.options array of the parent lobby_feed_item.';


--
-- Name: lobby_invite_link; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lobby_invite_link (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lobby_id uuid NOT NULL,
    code text NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    revoked_at timestamp with time zone,
    use_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.lobby_invite_link OWNER TO postgres;

--
-- Name: lobby_match; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lobby_match (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lobby_id uuid NOT NULL,
    activity_id uuid,
    opponent_lobby_id uuid,
    opponent_tag text NOT NULL,
    result public.lobby_match_result NOT NULL,
    sets jsonb,
    mvp_user_id uuid,
    note text,
    venue_label text NOT NULL,
    played_at timestamp with time zone NOT NULL,
    duration_label text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    referee_booking_id uuid,
    CONSTRAINT lobby_match_referee_required_for_scored_challenge CHECK (((opponent_lobby_id IS NULL) OR (result = 'practice'::public.lobby_match_result) OR (referee_booking_id IS NOT NULL))),
    CONSTRAINT lobby_match_sets_only_when_decided CHECK ((((result = 'practice'::public.lobby_match_result) AND (sets IS NULL)) OR (result <> 'practice'::public.lobby_match_result)))
);


ALTER TABLE public.lobby_match OWNER TO postgres;

--
-- Name: TABLE lobby_match; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.lobby_match IS 'Recorded match results for a lobby. sets is a JSON array of [us, them] tuples; venue_label / duration_label are denormalised copies for fast list rendering.';


--
-- Name: COLUMN lobby_match.referee_booking_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.lobby_match.referee_booking_id IS 'FK to the professional_booking that hired the referee for this match. Required for challenge matches (see lobby_match_referee_required_for_challenge). RESTRICT on delete because the booking row is the historical record of the hire — deleting it would orphan the audit trail.';


--
-- Name: lobby_member; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lobby_member (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    lobby_id uuid NOT NULL,
    role public.lobby_member_role DEFAULT 'member'::public.lobby_member_role NOT NULL
);


ALTER TABLE public.lobby_member OWNER TO postgres;

--
-- Name: TABLE lobby_member; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.lobby_member IS 'join table between user and lobby';


--
-- Name: lobby_member_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.lobby_member ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.lobby_member_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: lobby_payment_request_payee; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lobby_payment_request_payee (
    feed_item_id uuid NOT NULL,
    user_id uuid NOT NULL,
    amount_owed numeric(10,2) NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    recipient_id uuid NOT NULL,
    status public.lobby_payment_status DEFAULT 'outstanding'::public.lobby_payment_status NOT NULL,
    paid_at timestamp with time zone,
    CONSTRAINT lobby_payment_request_payee_amount_owed_check CHECK ((amount_owed > (0)::numeric)),
    CONSTRAINT lobby_payment_request_payee_status_time_check CHECK ((((status = 'outstanding'::public.lobby_payment_status) AND (paid_at IS NULL)) OR ((status = ANY (ARRAY['paid_direct'::public.lobby_payment_status, 'cleared_together'::public.lobby_payment_status])) AND (paid_at IS NOT NULL))))
);


ALTER TABLE public.lobby_payment_request_payee OWNER TO postgres;

--
-- Name: TABLE lobby_payment_request_payee; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.lobby_payment_request_payee IS 'Who owes what on a lobby_feed_item(kind = payment_request). Written only by create_ancillary_payment_request() / fn_sweep_activity_payment_requests() — no client INSERT policy.';


--
-- Name: lobby_payment_settlement; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lobby_payment_settlement (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lobby_id uuid NOT NULL,
    payer_id uuid NOT NULL,
    recipient_id uuid NOT NULL,
    payer_gross numeric(12,2) NOT NULL,
    recipient_gross numeric(12,2) NOT NULL,
    transferred_amount numeric(12,2) NOT NULL,
    idempotency_key uuid NOT NULL,
    feed_item_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT lobby_payment_settlement_amount_check CHECK (((payer_gross > (0)::numeric) AND (payer_gross >= recipient_gross) AND (transferred_amount = (payer_gross - recipient_gross)))),
    CONSTRAINT lobby_payment_settlement_payer_gross_check CHECK ((payer_gross >= (0)::numeric)),
    CONSTRAINT lobby_payment_settlement_people_check CHECK ((payer_id <> recipient_id)),
    CONSTRAINT lobby_payment_settlement_recipient_gross_check CHECK ((recipient_gross >= (0)::numeric)),
    CONSTRAINT lobby_payment_settlement_transferred_amount_check CHECK ((transferred_amount >= (0)::numeric))
);


ALTER TABLE public.lobby_payment_settlement OWNER TO postgres;

--
-- Name: lobby_payment_settlement_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lobby_payment_settlement_item (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    settlement_id uuid NOT NULL,
    obligation_id uuid,
    source_feed_item_id uuid,
    source_activity_id uuid,
    debtor_id uuid NOT NULL,
    recipient_id uuid NOT NULL,
    amount numeric(10,2) NOT NULL,
    CONSTRAINT lobby_payment_settlement_item_amount_check CHECK ((amount > (0)::numeric))
);


ALTER TABLE public.lobby_payment_settlement_item OWNER TO postgres;

--
-- Name: location; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.location (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    external_id text,
    name text NOT NULL,
    full_address text,
    street_number text,
    street_name text,
    district text,
    city text,
    lat double precision,
    lon double precision,
    tags text[] DEFAULT '{}'::text[] NOT NULL,
    city_cluster bigint,
    source text DEFAULT 'directory'::text NOT NULL,
    submitted_by uuid,
    is_verified boolean DEFAULT true NOT NULL,
    CONSTRAINT location_source_check CHECK ((source = ANY (ARRAY['directory'::text, 'user_submitted'::text])))
);


ALTER TABLE public.location OWNER TO postgres;

--
-- Name: COLUMN location.lat; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.location.lat IS 'latitude';


--
-- Name: COLUMN location.lon; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.location.lon IS 'longitude';


--
-- Name: message; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.message (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    conversation_id uuid NOT NULL,
    sender_id uuid,
    kind public.message_kind NOT NULL,
    body text,
    payload jsonb,
    payment_info_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT message_shape CHECK ((((kind = 'text'::public.message_kind) AND (sender_id IS NOT NULL) AND ((char_length(btrim(body)) >= 1) AND (char_length(btrim(body)) <= 2000)) AND (payment_info_id IS NULL) AND (payload IS NULL)) OR ((kind = 'system'::public.message_kind) AND (sender_id IS NULL) AND ((char_length(btrim(body)) >= 1) AND (char_length(btrim(body)) <= 500)) AND (payment_info_id IS NULL)) OR ((kind = 'payment_info'::public.message_kind) AND (sender_id IS NOT NULL) AND (payment_info_id IS NOT NULL) AND (body IS NULL) AND (payload IS NULL)) OR ((kind = 'poll'::public.message_kind) AND (sender_id IS NOT NULL) AND (body IS NULL) AND (payment_info_id IS NULL) AND (jsonb_typeof((payload -> 'question'::text)) = 'string'::text) AND ((char_length((payload ->> 'question'::text)) >= 1) AND (char_length((payload ->> 'question'::text)) <= 200)) AND (jsonb_typeof((payload -> 'options'::text)) = 'array'::text) AND ((jsonb_array_length((payload -> 'options'::text)) >= 2) AND (jsonb_array_length((payload -> 'options'::text)) <= 6)))))
);


ALTER TABLE public.message OWNER TO postgres;

--
-- Name: message_poll_vote; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.message_poll_vote (
    message_id uuid NOT NULL,
    user_id uuid NOT NULL,
    option_index smallint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT message_poll_vote_option_index_check CHECK ((option_index >= 0))
);


ALTER TABLE public.message_poll_vote OWNER TO postgres;

--
-- Name: network; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.network (
    id bigint NOT NULL,
    name text NOT NULL,
    category text,
    city bigint,
    name_fts tsvector GENERATED ALWAYS AS (to_tsvector('public.vietnamese'::regconfig, public.immutable_unaccent(name))) STORED,
    CONSTRAINT network_category_check CHECK ((category = ANY (ARRAY['high school'::text, 'gifted high school'::text, 'university'::text, 'company'::text])))
);


ALTER TABLE public.network OWNER TO postgres;

--
-- Name: TABLE network; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.network IS 'entities/ organizations that users may share';


--
-- Name: network_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.network ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.network_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: notification_outbox_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.notification_outbox ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.notification_outbox_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pickleball_profile; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pickleball_profile (
    user_id uuid NOT NULL,
    dominant_hand text,
    discipline text[] DEFAULT '{}'::text[] NOT NULL,
    elo_seed text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.pickleball_profile OWNER TO postgres;

--
-- Name: professional; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.professional (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    linked_user_id uuid,
    professional_role public.professional_role NOT NULL,
    display_name text NOT NULL,
    bio text,
    contact_details jsonb,
    certifications jsonb,
    schedule jsonb,
    schedule_note text,
    is_verified boolean DEFAULT false NOT NULL,
    sports bigint[] NOT NULL,
    experience_years integer,
    average_rating numeric(3,2) DEFAULT 0.00,
    review_count integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    preferred_city_cluster bigint,
    preferred_districts text[],
    CONSTRAINT professional_display_name_check CHECK (((char_length(btrim(display_name)) >= 1) AND (char_length(btrim(display_name)) <= 80))),
    CONSTRAINT professional_experience_years_check CHECK ((experience_years >= 0)),
    CONSTRAINT professional_sports_check CHECK ((array_length(sports, 1) > 0))
);


ALTER TABLE public.professional OWNER TO postgres;

--
-- Name: COLUMN professional.display_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.professional.display_name IS 'Public professional name, independent from the linked user account username.';


--
-- Name: professional_preferred_location; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.professional_preferred_location (
    professional_id uuid NOT NULL,
    location_id uuid NOT NULL
);


ALTER TABLE public.professional_preferred_location OWNER TO postgres;

--
-- Name: TABLE professional_preferred_location; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.professional_preferred_location IS 'Courts a coach teaches at, surfaced in the booking sheet for the student to pick from. Set
     out-of-app (admin/DB-direct) — no self-service UI in this pass, mirrors linked_user_id.';


--
-- Name: professional_service; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.professional_service (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    professional_id uuid NOT NULL,
    sport_id bigint NOT NULL,
    service_type text NOT NULL,
    service_description text,
    price_amount numeric(10,2),
    min_duration_minutes integer,
    max_participants integer,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    session_count integer DEFAULT 1 NOT NULL,
    pricing_kind text DEFAULT 'hourly'::text NOT NULL,
    CONSTRAINT professional_service_max_participants_check CHECK ((max_participants >= 1)),
    CONSTRAINT professional_service_min_duration_minutes_check CHECK ((min_duration_minutes > 0)),
    CONSTRAINT professional_service_price_amount_check CHECK ((price_amount >= (0)::numeric)),
    CONSTRAINT professional_service_pricing_kind_check CHECK ((pricing_kind = ANY (ARRAY['hourly'::text, 'per_session'::text]))),
    CONSTRAINT professional_service_session_count_check CHECK ((session_count >= 1))
);


ALTER TABLE public.professional_service OWNER TO postgres;

--
-- Name: COLUMN professional_service.price_amount; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.professional_service.price_amount IS 'Advertised amount charged according to pricing_kind.';


--
-- Name: COLUMN professional_service.session_count; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.professional_service.session_count IS 'Number of sessions in this offering. 1 = a plain single booking; >1 = a rolling package.';


--
-- Name: COLUMN professional_service.pricing_kind; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.professional_service.pricing_kind IS 'hourly scales price_amount by session duration; per_session is a fixed session price.';


--
-- Name: referee_booking; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.referee_booking (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    client_user_id uuid NOT NULL,
    service_id uuid NOT NULL,
    professional_id uuid NOT NULL,
    event_id uuid,
    location_id uuid,
    booking_time_start timestamp with time zone NOT NULL,
    booking_time_end timestamp with time zone NOT NULL,
    agreed_rate numeric(10,2),
    status public.professional_booking_status DEFAULT 'requested'::public.professional_booking_status NOT NULL,
    client_notes text,
    professional_notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    reminder_sent_at timestamp with time zone,
    package_id uuid,
    CONSTRAINT booking_times_validity CHECK ((booking_time_end > booking_time_start)),
    CONSTRAINT professional_booking_agreed_rate_check CHECK ((agreed_rate >= (0)::numeric))
);


ALTER TABLE public.referee_booking OWNER TO postgres;

--
-- Name: referee_booking_additional_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.referee_booking_additional_users (
    booking_id uuid NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.referee_booking_additional_users OWNER TO postgres;

--
-- Name: referee_booking_review; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.referee_booking_review (
    booking_id uuid NOT NULL,
    reviewer_user_id uuid NOT NULL,
    professional_id uuid NOT NULL,
    rating numeric(2,1) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    comment text,
    package_id uuid,
    CONSTRAINT professional_booking_review_rating_check CHECK (((rating >= 0.5) AND (rating <= 5.0) AND ((rating * (2)::numeric) = floor((rating * (2)::numeric)))))
);


ALTER TABLE public.referee_booking_review OWNER TO postgres;

--
-- Name: soccer_profile; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.soccer_profile (
    user_id uuid NOT NULL,
    "position" text[] DEFAULT '{}'::text[] NOT NULL,
    pitch text[] DEFAULT '{}'::text[] NOT NULL,
    elo_seed text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.soccer_profile OWNER TO postgres;

--
-- Name: social_event; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.social_event (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    kind text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT social_event_kind_check CHECK ((kind = ANY (ARRAY['post_created'::text, 'reaction_received'::text, 'reaction_given'::text])))
);


ALTER TABLE public.social_event OWNER TO postgres;

--
-- Name: social_event_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.social_event ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.social_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sport; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sport (
    id bigint NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.sport OWNER TO postgres;

--
-- Name: sport_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.sport ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.sport_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: supported_city_cluster; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.supported_city_cluster (
    id bigint NOT NULL,
    country public.country DEFAULT 'VN'::public.country NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.supported_city_cluster OWNER TO postgres;

--
-- Name: supported_city_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.supported_city_cluster ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.supported_city_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tennis_profile; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tennis_profile (
    user_id uuid NOT NULL,
    dominant_hand text,
    discipline text[] DEFAULT '{}'::text[] NOT NULL,
    elo_seed text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tennis_profile OWNER TO postgres;

--
-- Name: user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."user" (
    id uuid DEFAULT auth.uid() NOT NULL,
    username character varying(16) DEFAULT public.nanoid(16) NOT NULL,
    tag_number character varying(4) DEFAULT lpad((((floor((random() * (10000)::double precision)))::integer)::character varying)::text, 4, '0'::text) NOT NULL,
    details jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    xp bigint DEFAULT 0 NOT NULL,
    level integer DEFAULT 1 NOT NULL,
    has_password boolean DEFAULT false NOT NULL,
    CONSTRAINT user_details_schema CHECK (extensions.jsonb_matches_schema('{
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "description": "Freeform data for user profile",
      "type": "object",
      "properties": {
        "gender":         { "type": "string" },
        "ageGroup":       { "type": "string" },
        "playtime":       { "type": "array" },
        "generatedAvatar":{ "type": "string" },
        "location": {
          "type": "object",
          "properties": {
            "city":      { "type": "integer" },
            "districts": { "type": "array", "items": { "type": "string" } }
          }
        }
      }
    }'::json, details)),
    CONSTRAINT user_username_alphanumeric CHECK (((username)::text ~ '^[a-zA-Z0-9]+$'::text))
);


ALTER TABLE public."user" OWNER TO postgres;

--
-- Name: user_achievement; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_achievement (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    achievement_id uuid NOT NULL,
    period_key text NOT NULL,
    xp_granted bigint NOT NULL,
    earned_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.user_achievement OWNER TO postgres;

--
-- Name: TABLE user_achievement; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_achievement IS 'Per-user achievement unlock ledger; xp_granted snapshots achievement.xp_reward at earn time.';


--
-- Name: user_block; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_block (
    blocker_id uuid NOT NULL,
    blocked_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT user_block_distinct CHECK ((blocker_id <> blocked_id))
);


ALTER TABLE public.user_block OWNER TO postgres;

--
-- Name: user_contact; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_contact (
    user_id uuid NOT NULL,
    zalo text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    zalo_public boolean DEFAULT false NOT NULL,
    CONSTRAINT user_contact_zalo_length CHECK (((zalo IS NULL) OR ((char_length(btrim(zalo)) >= 1) AND (char_length(btrim(zalo)) <= 32))))
);


ALTER TABLE public.user_contact OWNER TO postgres;

--
-- Name: user_device_token; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_device_token (
    fcm_token text NOT NULL,
    user_id uuid NOT NULL,
    platform text NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT user_device_token_platform_check CHECK ((platform = ANY (ARRAY['ios'::text, 'android'::text])))
);


ALTER TABLE public.user_device_token OWNER TO postgres;

--
-- Name: user_health_link; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_health_link (
    user_id uuid NOT NULL,
    platform public.health_platform NOT NULL,
    linked_at timestamp with time zone DEFAULT now() NOT NULL,
    last_sync_at timestamp with time zone,
    max_heart_rate integer,
    lt1_bpm integer,
    lt2_bpm integer
);


ALTER TABLE public.user_health_link OWNER TO postgres;

--
-- Name: TABLE user_health_link; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_health_link IS 'Tracks user health service (Apple Health/Google Fit) linking status';


--
-- Name: COLUMN user_health_link.lt1_bpm; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.user_health_link.lt1_bpm IS 'User-declared aerobic threshold (bpm). NULL → app estimates ~80% of max HR and renders zones as "estimated".';


--
-- Name: COLUMN user_health_link.lt2_bpm; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.user_health_link.lt2_bpm IS 'User-declared anaerobic threshold (bpm). NULL → app estimates ~88% of max HR.';


--
-- Name: user_industry; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_industry (
    id bigint NOT NULL,
    user_id uuid,
    industry_id integer
);


ALTER TABLE public.user_industry OWNER TO postgres;

--
-- Name: TABLE user_industry; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_industry IS 'join table for `user` and `industry`';


--
-- Name: user_industry_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.user_industry ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.user_industry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_network; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_network (
    id bigint NOT NULL,
    user_id uuid,
    network_id bigint,
    alumni boolean DEFAULT true NOT NULL
);


ALTER TABLE public.user_network OWNER TO postgres;

--
-- Name: TABLE user_network; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_network IS 'join table for `user` and `network`';


--
-- Name: user_network_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.user_network ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.user_network_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_payment_info; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_payment_info (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    bank_id text NOT NULL,
    bank_display_name text NOT NULL,
    value_secret_id uuid NOT NULL,
    account_name_secret_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.user_payment_info OWNER TO postgres;

--
-- Name: user_rating; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_rating (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    sport text NOT NULL,
    format text,
    elo integer NOT NULL,
    games_played integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.user_rating OWNER TO postgres;

--
-- Name: vitality_daily_load; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vitality_daily_load (
    user_id uuid NOT NULL,
    date date NOT NULL,
    session_load real DEFAULT 0 NOT NULL,
    session_count integer DEFAULT 0 NOT NULL,
    computed_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.vitality_daily_load OWNER TO postgres;

--
-- Name: vitality_score; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vitality_score (
    user_id uuid NOT NULL,
    date date NOT NULL,
    score real,
    consistency_component real,
    load_component real,
    recovery_component real,
    volume_component real,
    streak_bonus real DEFAULT 0 NOT NULL,
    ctl real,
    atl real,
    computed_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.vitality_score OWNER TO postgres;

--
-- Name: wall_post; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wall_post (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    author_id uuid DEFAULT auth.uid() NOT NULL,
    activity_id uuid,
    sport_id bigint NOT NULL,
    lobby_id uuid,
    source_label text,
    source_start_time timestamp with time zone NOT NULL,
    source_venue_name text,
    caption text,
    ttl_days smallint DEFAULT 7 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    hidden_at timestamp with time zone,
    media jsonb NOT NULL,
    CONSTRAINT wall_post_caption_length CHECK (((caption IS NULL) OR (char_length(caption) <= 140))),
    CONSTRAINT wall_post_ttl_choice CHECK ((ttl_days = ANY (ARRAY[1, 3, 7])))
);


ALTER TABLE public.wall_post OWNER TO postgres;

--
-- Name: wall_post_gc; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wall_post_gc (
    path text NOT NULL,
    queued_at timestamp with time zone DEFAULT now() NOT NULL,
    bucket_id text NOT NULL
);


ALTER TABLE public.wall_post_gc OWNER TO postgres;

--
-- Name: wall_post_moderation_queue; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.wall_post_moderation_queue AS
SELECT
    NULL::uuid AS id,
    NULL::uuid AS author_id,
    NULL::text AS caption,
    NULL::jsonb AS media,
    NULL::timestamp with time zone AS created_at,
    NULL::timestamp with time zone AS expires_at,
    NULL::timestamp with time zone AS hidden_at,
    NULL::bigint AS report_count,
    NULL::text[] AS reasons;


ALTER VIEW public.wall_post_moderation_queue OWNER TO postgres;

--
-- Name: wall_post_reaction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wall_post_reaction (
    post_id uuid NOT NULL,
    user_id uuid NOT NULL,
    emoji text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT wall_post_reaction_emoji_length CHECK (((char_length(emoji) >= 1) AND (char_length(emoji) <= 8)))
);


ALTER TABLE public.wall_post_reaction OWNER TO postgres;

--
-- Name: wall_post_report; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wall_post_report (
    post_id uuid NOT NULL,
    reporter_id uuid DEFAULT auth.uid() NOT NULL,
    reason text NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT wall_post_report_note_length CHECK (((note IS NULL) OR (char_length(note) <= 280))),
    CONSTRAINT wall_post_report_reason CHECK ((reason = ANY (ARRAY['spam'::text, 'harassment'::text, 'nudity'::text, 'violence'::text, 'impersonation'::text, 'other'::text])))
);


ALTER TABLE public.wall_post_report OWNER TO postgres;

--
-- Name: wall_post_tag; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wall_post_tag (
    post_id uuid NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.wall_post_tag OWNER TO postgres;

--
-- Name: messages; Type: TABLE; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE TABLE realtime.messages (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea
)
PARTITION BY RANGE (inserted_at);


ALTER TABLE realtime.messages OWNER TO supabase_realtime_admin;

--
-- Name: messages_2026_08_12; Type: TABLE; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE TABLE realtime.messages_2026_08_12 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


ALTER TABLE realtime.messages_2026_08_12 OWNER TO supabase_realtime_admin;

--
-- Name: messages_2026_08_13; Type: TABLE; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE TABLE realtime.messages_2026_08_13 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


ALTER TABLE realtime.messages_2026_08_13 OWNER TO supabase_realtime_admin;

--
-- Name: messages_2026_08_14; Type: TABLE; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE TABLE realtime.messages_2026_08_14 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


ALTER TABLE realtime.messages_2026_08_14 OWNER TO supabase_realtime_admin;

--
-- Name: messages_2026_08_15; Type: TABLE; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE TABLE realtime.messages_2026_08_15 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


ALTER TABLE realtime.messages_2026_08_15 OWNER TO supabase_realtime_admin;

--
-- Name: messages_2026_08_16; Type: TABLE; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE TABLE realtime.messages_2026_08_16 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


ALTER TABLE realtime.messages_2026_08_16 OWNER TO supabase_realtime_admin;

--
-- Name: messages_2026_08_17; Type: TABLE; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE TABLE realtime.messages_2026_08_17 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


ALTER TABLE realtime.messages_2026_08_17 OWNER TO supabase_realtime_admin;

--
-- Name: messages_2026_08_18; Type: TABLE; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE TABLE realtime.messages_2026_08_18 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


ALTER TABLE realtime.messages_2026_08_18 OWNER TO supabase_realtime_admin;

--
-- Name: schema_migrations; Type: TABLE; Schema: realtime; Owner: supabase_admin
--

CREATE TABLE realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


ALTER TABLE realtime.schema_migrations OWNER TO supabase_admin;

--
-- Name: subscription; Type: TABLE; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE TABLE realtime.subscription (
    id bigint NOT NULL,
    subscription_id uuid NOT NULL,
    entity regclass NOT NULL,
    filters realtime.user_defined_filter[] DEFAULT '{}'::realtime.user_defined_filter[] NOT NULL,
    claims jsonb NOT NULL,
    claims_role regrole GENERATED ALWAYS AS (realtime.to_regrole((claims ->> 'role'::text))) STORED NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    action_filter text DEFAULT '*'::text,
    selected_columns text[],
    CONSTRAINT subscription_action_filter_check CHECK ((action_filter = ANY (ARRAY['*'::text, 'INSERT'::text, 'UPDATE'::text, 'DELETE'::text])))
);


ALTER TABLE realtime.subscription OWNER TO supabase_realtime_admin;

--
-- Name: subscription_id_seq; Type: SEQUENCE; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE realtime.subscription ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME realtime.subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: buckets; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.buckets (
    id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    public boolean DEFAULT false,
    avif_autodetection boolean DEFAULT false,
    file_size_limit bigint,
    allowed_mime_types text[],
    owner_id text,
    type storage.buckettype DEFAULT 'STANDARD'::storage.buckettype NOT NULL
);


ALTER TABLE storage.buckets OWNER TO supabase_storage_admin;

--
-- Name: COLUMN buckets.owner; Type: COMMENT; Schema: storage; Owner: supabase_storage_admin
--

COMMENT ON COLUMN storage.buckets.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: buckets_analytics; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.buckets_analytics (
    name text NOT NULL,
    type storage.buckettype DEFAULT 'ANALYTICS'::storage.buckettype NOT NULL,
    format text DEFAULT 'ICEBERG'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE storage.buckets_analytics OWNER TO supabase_storage_admin;

--
-- Name: buckets_vectors; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.buckets_vectors (
    id text NOT NULL,
    type storage.buckettype DEFAULT 'VECTOR'::storage.buckettype NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE storage.buckets_vectors OWNER TO supabase_storage_admin;

--
-- Name: migrations; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE storage.migrations OWNER TO supabase_storage_admin;

--
-- Name: objects; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.objects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bucket_id text,
    name text,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_accessed_at timestamp with time zone DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/'::text)) STORED,
    version text,
    owner_id text,
    user_metadata jsonb
);


ALTER TABLE storage.objects OWNER TO supabase_storage_admin;

--
-- Name: COLUMN objects.owner; Type: COMMENT; Schema: storage; Owner: supabase_storage_admin
--

COMMENT ON COLUMN storage.objects.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: s3_multipart_uploads; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.s3_multipart_uploads (
    id text NOT NULL,
    in_progress_size bigint DEFAULT 0 NOT NULL,
    upload_signature text NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    version text NOT NULL,
    owner_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_metadata jsonb,
    metadata jsonb
);


ALTER TABLE storage.s3_multipart_uploads OWNER TO supabase_storage_admin;

--
-- Name: s3_multipart_uploads_parts; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.s3_multipart_uploads_parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    upload_id text NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    part_number integer NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    etag text NOT NULL,
    owner_id text,
    version text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE storage.s3_multipart_uploads_parts OWNER TO supabase_storage_admin;

--
-- Name: vector_indexes; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.vector_indexes (
    id text DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL COLLATE pg_catalog."C",
    bucket_id text NOT NULL,
    data_type text NOT NULL,
    dimension integer NOT NULL,
    distance_metric text NOT NULL,
    metadata_configuration jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE storage.vector_indexes OWNER TO supabase_storage_admin;

--
-- Name: schema_migrations; Type: TABLE; Schema: supabase_migrations; Owner: postgres
--

CREATE TABLE supabase_migrations.schema_migrations (
    version text NOT NULL,
    statements text[],
    name text,
    created_by text,
    idempotency_key text,
    rollback text[]
);


ALTER TABLE supabase_migrations.schema_migrations OWNER TO postgres;

--
-- Name: seed_files; Type: TABLE; Schema: supabase_migrations; Owner: postgres
--

CREATE TABLE supabase_migrations.seed_files (
    path text NOT NULL,
    hash text NOT NULL
);


ALTER TABLE supabase_migrations.seed_files OWNER TO postgres;

--
-- Name: messages_2026_08_12; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_08_12 FOR VALUES FROM ('2026-08-12 00:00:00') TO ('2026-08-13 00:00:00');


--
-- Name: messages_2026_08_13; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_08_13 FOR VALUES FROM ('2026-08-13 00:00:00') TO ('2026-08-14 00:00:00');


--
-- Name: messages_2026_08_14; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_08_14 FOR VALUES FROM ('2026-08-14 00:00:00') TO ('2026-08-15 00:00:00');


--
-- Name: messages_2026_08_15; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_08_15 FOR VALUES FROM ('2026-08-15 00:00:00') TO ('2026-08-16 00:00:00');


--
-- Name: messages_2026_08_16; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_08_16 FOR VALUES FROM ('2026-08-16 00:00:00') TO ('2026-08-17 00:00:00');


--
-- Name: messages_2026_08_17; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_08_17 FOR VALUES FROM ('2026-08-17 00:00:00') TO ('2026-08-18 00:00:00');


--
-- Name: messages_2026_08_18; Type: TABLE ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_08_18 FOR VALUES FROM ('2026-08-18 00:00:00') TO ('2026-08-19 00:00:00');


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Name: industry id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.industry ALTER COLUMN id SET DEFAULT nextval('public.industry_id_seq'::regclass);


--
-- Name: mfa_amr_claims amr_id_pk; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT amr_id_pk PRIMARY KEY (id);


--
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- Name: custom_oauth_providers custom_oauth_providers_identifier_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.custom_oauth_providers
    ADD CONSTRAINT custom_oauth_providers_identifier_key UNIQUE (identifier);


--
-- Name: custom_oauth_providers custom_oauth_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.custom_oauth_providers
    ADD CONSTRAINT custom_oauth_providers_pkey PRIMARY KEY (id);


--
-- Name: flow_state flow_state_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.flow_state
    ADD CONSTRAINT flow_state_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: identities identities_provider_id_provider_unique; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_provider_id_provider_unique UNIQUE (provider_id, provider);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_authentication_method_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey UNIQUE (session_id, authentication_method);


--
-- Name: mfa_challenges mfa_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_pkey PRIMARY KEY (id);


--
-- Name: mfa_factors mfa_factors_last_challenged_at_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_last_challenged_at_key UNIQUE (last_challenged_at);


--
-- Name: mfa_factors mfa_factors_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_pkey PRIMARY KEY (id);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_code_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_code_key UNIQUE (authorization_code);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_id_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_id_key UNIQUE (authorization_id);


--
-- Name: oauth_authorizations oauth_authorizations_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_pkey PRIMARY KEY (id);


--
-- Name: oauth_client_states oauth_client_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_client_states
    ADD CONSTRAINT oauth_client_states_pkey PRIMARY KEY (id);


--
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_user_client_unique; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_client_unique UNIQUE (user_id, client_id);


--
-- Name: one_time_tokens one_time_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- Name: saml_providers saml_providers_entity_id_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);


--
-- Name: saml_providers saml_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);


--
-- Name: saml_relay_states saml_relay_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sso_domains sso_domains_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_pkey PRIMARY KEY (id);


--
-- Name: sso_providers sso_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sso_providers
    ADD CONSTRAINT sso_providers_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: webauthn_challenges webauthn_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.webauthn_challenges
    ADD CONSTRAINT webauthn_challenges_pkey PRIMARY KEY (id);


--
-- Name: webauthn_credentials webauthn_credentials_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_pkey PRIMARY KEY (id);


--
-- Name: achievement achievement_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.achievement
    ADD CONSTRAINT achievement_pkey PRIMARY KEY (id);


--
-- Name: activity_confirmation activity_confirmation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_confirmation
    ADD CONSTRAINT activity_confirmation_pkey PRIMARY KEY (activity_id, user_id);


--
-- Name: activity_health_metrics activity_health_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_health_metrics
    ADD CONSTRAINT activity_health_metrics_pkey PRIMARY KEY (id);


--
-- Name: activity_health_metrics activity_health_metrics_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_health_metrics
    ADD CONSTRAINT activity_health_metrics_unique UNIQUE (user_id, activity_id);


--
-- Name: activity_hr_sample activity_hr_sample_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_hr_sample
    ADD CONSTRAINT activity_hr_sample_pkey PRIMARY KEY (id);


--
-- Name: activity activity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_pkey PRIMARY KEY (id);


--
-- Name: activity_reminder_sent activity_reminder_sent_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_reminder_sent
    ADD CONSTRAINT activity_reminder_sent_pkey PRIMARY KEY (activity_id);


--
-- Name: activity_series_frontier activity_series_frontier_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_series_frontier
    ADD CONSTRAINT activity_series_frontier_pkey PRIMARY KEY (series_id);


--
-- Name: badminton_profile badminton_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.badminton_profile
    ADD CONSTRAINT badminton_profile_pkey PRIMARY KEY (user_id);


--
-- Name: basketball_profile basketball_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.basketball_profile
    ADD CONSTRAINT basketball_profile_pkey PRIMARY KEY (user_id);


--
-- Name: referee_booking_additional_users booking_additional_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referee_booking_additional_users
    ADD CONSTRAINT booking_additional_users_pkey PRIMARY KEY (booking_id, user_id);


--
-- Name: conversation_member conversation_member_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversation_member
    ADD CONSTRAINT conversation_member_pkey PRIMARY KEY (conversation_id, user_id);


--
-- Name: conversation conversation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversation
    ADD CONSTRAINT conversation_pkey PRIMARY KEY (id);


--
-- Name: course_enrollment_offer course_enrollment_offer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_enrollment_offer
    ADD CONSTRAINT course_enrollment_offer_pkey PRIMARY KEY (id);


--
-- Name: course_member course_member_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_member
    ADD CONSTRAINT course_member_pkey PRIMARY KEY (course_id, user_id);


--
-- Name: course course_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course
    ADD CONSTRAINT course_pkey PRIMARY KEY (id);


--
-- Name: course_review course_review_course_id_student_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_review
    ADD CONSTRAINT course_review_course_id_student_id_key UNIQUE (course_id, student_id);


--
-- Name: course_review course_review_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_review
    ADD CONSTRAINT course_review_pkey PRIMARY KEY (id);


--
-- Name: course_session_report course_session_report_activity_id_student_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_session_report
    ADD CONSTRAINT course_session_report_activity_id_student_id_key UNIQUE (activity_id, student_id);


--
-- Name: course_session_report course_session_report_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_session_report
    ADD CONSTRAINT course_session_report_pkey PRIMARY KEY (id);


--
-- Name: daily_health_summary daily_health_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_health_summary
    ADD CONSTRAINT daily_health_summary_pkey PRIMARY KEY (user_id, date);


--
-- Name: enabled_notification_kind enabled_notification_kind_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enabled_notification_kind
    ADD CONSTRAINT enabled_notification_kind_pkey PRIMARY KEY (kind);


--
-- Name: freeplay_activity freeplay_activity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.freeplay_activity
    ADD CONSTRAINT freeplay_activity_pkey PRIMARY KEY (activity_id);


--
-- Name: freeplay_host freeplay_host_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.freeplay_host
    ADD CONSTRAINT freeplay_host_pkey PRIMARY KEY (id);


--
-- Name: freeplay_host freeplay_host_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.freeplay_host
    ADD CONSTRAINT freeplay_host_user_id_key UNIQUE (user_id);


--
-- Name: freeplay_request freeplay_request_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.freeplay_request
    ADD CONSTRAINT freeplay_request_pkey PRIMARY KEY (id);


--
-- Name: friendship friendship_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendship
    ADD CONSTRAINT friendship_pkey PRIMARY KEY (id);


--
-- Name: industry industry_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.industry
    ADD CONSTRAINT industry_name_key UNIQUE (name);


--
-- Name: industry industry_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.industry
    ADD CONSTRAINT industry_pkey PRIMARY KEY (id);


--
-- Name: lobby_befriend_record lobby_befriend_record_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_befriend_record
    ADD CONSTRAINT lobby_befriend_record_pkey PRIMARY KEY (id);


--
-- Name: lobby_challenge lobby_challenge_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_challenge
    ADD CONSTRAINT lobby_challenge_pkey PRIMARY KEY (id);


--
-- Name: lobby_feed_item lobby_feed_item_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_feed_item
    ADD CONSTRAINT lobby_feed_item_pkey PRIMARY KEY (id);


--
-- Name: lobby_feed_item_reaction lobby_feed_item_reaction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_feed_item_reaction
    ADD CONSTRAINT lobby_feed_item_reaction_pkey PRIMARY KEY (feed_item_id, user_id);


--
-- Name: lobby_feed_poll_vote lobby_feed_poll_vote_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_feed_poll_vote
    ADD CONSTRAINT lobby_feed_poll_vote_pkey PRIMARY KEY (feed_item_id, user_id);


--
-- Name: lobby_invite_link lobby_invite_link_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_invite_link
    ADD CONSTRAINT lobby_invite_link_code_key UNIQUE (code);


--
-- Name: lobby_invite_link lobby_invite_link_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_invite_link
    ADD CONSTRAINT lobby_invite_link_pkey PRIMARY KEY (id);


--
-- Name: lobby_match lobby_match_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_match
    ADD CONSTRAINT lobby_match_pkey PRIMARY KEY (id);


--
-- Name: lobby_member lobby_member_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_member
    ADD CONSTRAINT lobby_member_pkey PRIMARY KEY (id);


--
-- Name: lobby_member lobby_member_user_lobby_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_member
    ADD CONSTRAINT lobby_member_user_lobby_uniq UNIQUE (user_id, lobby_id);


--
-- Name: lobby_payment_request_payee lobby_payment_request_payee_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_payment_request_payee
    ADD CONSTRAINT lobby_payment_request_payee_id_key UNIQUE (id);


--
-- Name: lobby_payment_request_payee lobby_payment_request_payee_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_payment_request_payee
    ADD CONSTRAINT lobby_payment_request_payee_pkey PRIMARY KEY (feed_item_id, user_id);


--
-- Name: lobby_payment_settlement lobby_payment_settlement_feed_item_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_payment_settlement
    ADD CONSTRAINT lobby_payment_settlement_feed_item_id_key UNIQUE (feed_item_id);


--
-- Name: lobby_payment_settlement lobby_payment_settlement_idempotency_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_payment_settlement
    ADD CONSTRAINT lobby_payment_settlement_idempotency_key UNIQUE (payer_id, idempotency_key);


--
-- Name: lobby_payment_settlement_item lobby_payment_settlement_item_obligation_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_payment_settlement_item
    ADD CONSTRAINT lobby_payment_settlement_item_obligation_id_key UNIQUE (obligation_id);


--
-- Name: lobby_payment_settlement_item lobby_payment_settlement_item_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_payment_settlement_item
    ADD CONSTRAINT lobby_payment_settlement_item_pkey PRIMARY KEY (id);


--
-- Name: lobby_payment_settlement lobby_payment_settlement_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_payment_settlement
    ADD CONSTRAINT lobby_payment_settlement_pkey PRIMARY KEY (id);


--
-- Name: lobby lobby_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby
    ADD CONSTRAINT lobby_pkey PRIMARY KEY (id);


--
-- Name: location location_external_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT location_external_id_key UNIQUE (external_id);


--
-- Name: location location_full_address_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT location_full_address_key UNIQUE (full_address);


--
-- Name: location location_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT location_pkey PRIMARY KEY (id);


--
-- Name: message message_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_pkey PRIMARY KEY (id);


--
-- Name: message_poll_vote message_poll_vote_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message_poll_vote
    ADD CONSTRAINT message_poll_vote_pkey PRIMARY KEY (message_id, user_id);


--
-- Name: network network_name_city_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.network
    ADD CONSTRAINT network_name_city_key UNIQUE (name, city);


--
-- Name: network network_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.network
    ADD CONSTRAINT network_pkey PRIMARY KEY (id);


--
-- Name: notification_outbox notification_outbox_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_outbox
    ADD CONSTRAINT notification_outbox_pkey PRIMARY KEY (id);


--
-- Name: pickleball_profile pickleball_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pickleball_profile
    ADD CONSTRAINT pickleball_profile_pkey PRIMARY KEY (user_id);


--
-- Name: referee_booking professional_booking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referee_booking
    ADD CONSTRAINT professional_booking_pkey PRIMARY KEY (id);


--
-- Name: referee_booking_review professional_booking_review_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referee_booking_review
    ADD CONSTRAINT professional_booking_review_pkey PRIMARY KEY (booking_id);


--
-- Name: professional professional_linked_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional
    ADD CONSTRAINT professional_linked_user_id_key UNIQUE (linked_user_id);


--
-- Name: professional professional_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional
    ADD CONSTRAINT professional_pkey PRIMARY KEY (id);


--
-- Name: professional_preferred_location professional_preferred_location_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional_preferred_location
    ADD CONSTRAINT professional_preferred_location_pkey PRIMARY KEY (professional_id, location_id);


--
-- Name: professional_service professional_service_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional_service
    ADD CONSTRAINT professional_service_pkey PRIMARY KEY (id);


--
-- Name: soccer_profile soccer_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.soccer_profile
    ADD CONSTRAINT soccer_profile_pkey PRIMARY KEY (user_id);


--
-- Name: social_event social_event_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.social_event
    ADD CONSTRAINT social_event_pkey PRIMARY KEY (id);


--
-- Name: sport sport_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sport
    ADD CONSTRAINT sport_name_key UNIQUE (name);


--
-- Name: sport sport_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sport
    ADD CONSTRAINT sport_pkey PRIMARY KEY (id);


--
-- Name: supported_city_cluster supported_city_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.supported_city_cluster
    ADD CONSTRAINT supported_city_pkey PRIMARY KEY (id);


--
-- Name: tennis_profile tennis_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tennis_profile
    ADD CONSTRAINT tennis_profile_pkey PRIMARY KEY (user_id);


--
-- Name: user_achievement user_achievement_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_achievement
    ADD CONSTRAINT user_achievement_pkey PRIMARY KEY (id);


--
-- Name: user_achievement user_achievement_user_id_achievement_id_period_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_achievement
    ADD CONSTRAINT user_achievement_user_id_achievement_id_period_key_key UNIQUE (user_id, achievement_id, period_key);


--
-- Name: user_block user_block_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_block
    ADD CONSTRAINT user_block_pkey PRIMARY KEY (blocker_id, blocked_id);


--
-- Name: user_contact user_contact_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_contact
    ADD CONSTRAINT user_contact_pkey PRIMARY KEY (user_id);


--
-- Name: user_device_token user_device_token_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_device_token
    ADD CONSTRAINT user_device_token_pkey PRIMARY KEY (fcm_token);


--
-- Name: user_health_link user_health_link_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_health_link
    ADD CONSTRAINT user_health_link_pkey PRIMARY KEY (user_id);


--
-- Name: user_industry user_industry_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_industry
    ADD CONSTRAINT user_industry_pkey PRIMARY KEY (id);


--
-- Name: user_network user_network_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_network
    ADD CONSTRAINT user_network_pkey PRIMARY KEY (id);


--
-- Name: user_payment_info user_payment_info_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_payment_info
    ADD CONSTRAINT user_payment_info_pkey PRIMARY KEY (id);


--
-- Name: user_payment_info user_payment_info_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_payment_info
    ADD CONSTRAINT user_payment_info_user_id_key UNIQUE (user_id);


--
-- Name: user user_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pk UNIQUE (username, tag_number);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- Name: user_rating user_rating_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_rating
    ADD CONSTRAINT user_rating_pkey PRIMARY KEY (id);


--
-- Name: user_rating user_rating_user_id_sport_format_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_rating
    ADD CONSTRAINT user_rating_user_id_sport_format_key UNIQUE (user_id, sport, format);


--
-- Name: vitality_daily_load vitality_daily_load_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vitality_daily_load
    ADD CONSTRAINT vitality_daily_load_pkey PRIMARY KEY (user_id, date);


--
-- Name: vitality_score vitality_score_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vitality_score
    ADD CONSTRAINT vitality_score_pkey PRIMARY KEY (user_id, date);


--
-- Name: wall_post_gc wall_post_gc_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wall_post_gc
    ADD CONSTRAINT wall_post_gc_pkey PRIMARY KEY (bucket_id, path);


--
-- Name: wall_post wall_post_media_shape; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public.wall_post
    ADD CONSTRAINT wall_post_media_shape CHECK (public.fn_valid_wall_post_media(media)) NOT VALID;


--
-- Name: wall_post wall_post_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wall_post
    ADD CONSTRAINT wall_post_pkey PRIMARY KEY (id);


--
-- Name: wall_post_reaction wall_post_reaction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wall_post_reaction
    ADD CONSTRAINT wall_post_reaction_pkey PRIMARY KEY (post_id, user_id, emoji);


--
-- Name: wall_post_report wall_post_report_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wall_post_report
    ADD CONSTRAINT wall_post_report_pkey PRIMARY KEY (post_id, reporter_id);


--
-- Name: wall_post wall_post_requires_activity; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public.wall_post
    ADD CONSTRAINT wall_post_requires_activity CHECK ((activity_id IS NOT NULL)) NOT VALID;


--
-- Name: wall_post_tag wall_post_tag_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wall_post_tag
    ADD CONSTRAINT wall_post_tag_pkey PRIMARY KEY (post_id, user_id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_08_12 messages_2026_08_12_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.messages_2026_08_12
    ADD CONSTRAINT messages_2026_08_12_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_08_13 messages_2026_08_13_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.messages_2026_08_13
    ADD CONSTRAINT messages_2026_08_13_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_08_14 messages_2026_08_14_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.messages_2026_08_14
    ADD CONSTRAINT messages_2026_08_14_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_08_15 messages_2026_08_15_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.messages_2026_08_15
    ADD CONSTRAINT messages_2026_08_15_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_08_16 messages_2026_08_16_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.messages_2026_08_16
    ADD CONSTRAINT messages_2026_08_16_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_08_17 messages_2026_08_17_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.messages_2026_08_17
    ADD CONSTRAINT messages_2026_08_17_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_08_18 messages_2026_08_18_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.messages_2026_08_18
    ADD CONSTRAINT messages_2026_08_18_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages messages_payload_exclusive; Type: CHECK CONSTRAINT; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE realtime.messages
    ADD CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL))) NOT VALID;


--
-- Name: subscription pk_subscription; Type: CONSTRAINT; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.subscription
    ADD CONSTRAINT pk_subscription PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_admin
--

ALTER TABLE ONLY realtime.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: buckets_analytics buckets_analytics_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.buckets_analytics
    ADD CONSTRAINT buckets_analytics_pkey PRIMARY KEY (id);


--
-- Name: buckets buckets_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_pkey PRIMARY KEY (id);


--
-- Name: buckets_vectors buckets_vectors_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.buckets_vectors
    ADD CONSTRAINT buckets_vectors_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: objects objects_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_pkey PRIMARY KEY (id);


--
-- Name: vector_indexes vector_indexes_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.vector_indexes
    ADD CONSTRAINT vector_indexes_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_idempotency_key_key; Type: CONSTRAINT; Schema: supabase_migrations; Owner: postgres
--

ALTER TABLE ONLY supabase_migrations.schema_migrations
    ADD CONSTRAINT schema_migrations_idempotency_key_key UNIQUE (idempotency_key);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: supabase_migrations; Owner: postgres
--

ALTER TABLE ONLY supabase_migrations.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: seed_files seed_files_pkey; Type: CONSTRAINT; Schema: supabase_migrations; Owner: postgres
--

ALTER TABLE ONLY supabase_migrations.seed_files
    ADD CONSTRAINT seed_files_pkey PRIMARY KEY (path);


--
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: custom_oauth_providers_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX custom_oauth_providers_created_at_idx ON auth.custom_oauth_providers USING btree (created_at);


--
-- Name: custom_oauth_providers_enabled_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX custom_oauth_providers_enabled_idx ON auth.custom_oauth_providers USING btree (enabled);


--
-- Name: custom_oauth_providers_identifier_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX custom_oauth_providers_identifier_idx ON auth.custom_oauth_providers USING btree (identifier);


--
-- Name: custom_oauth_providers_provider_type_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX custom_oauth_providers_provider_type_idx ON auth.custom_oauth_providers USING btree (provider_type);


--
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- Name: factor_id_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);


--
-- Name: flow_state_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);


--
-- Name: identities_email_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);


--
-- Name: INDEX identities_email_idx; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON INDEX auth.identities_email_idx IS 'Auth: Ensures indexed queries on the email column';


--
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- Name: idx_auth_code; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);


--
-- Name: idx_oauth_client_states_created_at; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX idx_oauth_client_states_created_at ON auth.oauth_client_states USING btree (created_at);


--
-- Name: idx_user_id_auth_method; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);


--
-- Name: mfa_challenge_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);


--
-- Name: mfa_factors_user_friendly_name_unique; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);


--
-- Name: mfa_factors_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);


--
-- Name: oauth_auth_pending_exp_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_auth_pending_exp_idx ON auth.oauth_authorizations USING btree (expires_at) WHERE (status = 'pending'::auth.oauth_authorization_status);


--
-- Name: oauth_clients_deleted_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_clients_deleted_at_idx ON auth.oauth_clients USING btree (deleted_at);


--
-- Name: oauth_consents_active_client_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_consents_active_client_idx ON auth.oauth_consents USING btree (client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_active_user_client_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_consents_active_user_client_idx ON auth.oauth_consents USING btree (user_id, client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_user_order_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX oauth_consents_user_order_idx ON auth.oauth_consents USING btree (user_id, granted_at DESC);


--
-- Name: one_time_tokens_relates_to_hash_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);


--
-- Name: one_time_tokens_token_hash_hash_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);


--
-- Name: one_time_tokens_user_id_token_type_key; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);


--
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- Name: refresh_tokens_session_id_revoked_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);


--
-- Name: refresh_tokens_updated_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);


--
-- Name: saml_providers_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);


--
-- Name: saml_relay_states_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);


--
-- Name: saml_relay_states_for_email_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);


--
-- Name: saml_relay_states_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);


--
-- Name: sessions_not_after_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);


--
-- Name: sessions_oauth_client_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sessions_oauth_client_id_idx ON auth.sessions USING btree (oauth_client_id);


--
-- Name: sessions_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);


--
-- Name: sso_domains_domain_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));


--
-- Name: sso_domains_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);


--
-- Name: sso_providers_resource_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));


--
-- Name: sso_providers_resource_id_pattern_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX sso_providers_resource_id_pattern_idx ON auth.sso_providers USING btree (resource_id text_pattern_ops);


--
-- Name: unique_phone_factor_per_user; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);


--
-- Name: user_id_created_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);


--
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: users_is_anonymous_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);


--
-- Name: webauthn_challenges_expires_at_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX webauthn_challenges_expires_at_idx ON auth.webauthn_challenges USING btree (expires_at);


--
-- Name: webauthn_challenges_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX webauthn_challenges_user_id_idx ON auth.webauthn_challenges USING btree (user_id);


--
-- Name: webauthn_credentials_credential_id_key; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE UNIQUE INDEX webauthn_credentials_credential_id_key ON auth.webauthn_credentials USING btree (credential_id);


--
-- Name: webauthn_credentials_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX webauthn_credentials_user_id_idx ON auth.webauthn_credentials USING btree (user_id);


--
-- Name: achievement_code_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX achievement_code_key ON public.achievement USING btree (code);


--
-- Name: activity_challenge_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activity_challenge_idx ON public.activity USING btree (challenge_id) WHERE (challenge_id IS NOT NULL);


--
-- Name: activity_confirmation_user_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activity_confirmation_user_idx ON public.activity_confirmation USING btree (user_id);


--
-- Name: activity_course_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activity_course_idx ON public.activity USING btree (course_id, start_time) WHERE (course_id IS NOT NULL);


--
-- Name: activity_freeplay_host_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activity_freeplay_host_idx ON public.activity USING btree (freeplay_host_id) WHERE (freeplay_host_id IS NOT NULL);


--
-- Name: activity_referee_booking_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activity_referee_booking_id_idx ON public.activity USING btree (referee_booking_id);


--
-- Name: basketball_profile_pitch_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX basketball_profile_pitch_idx ON public.basketball_profile USING gin (pitch);


--
-- Name: basketball_profile_position_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX basketball_profile_position_idx ON public.basketball_profile USING gin ("position");


--
-- Name: conversation_member_user_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX conversation_member_user_idx ON public.conversation_member USING btree (user_id);


--
-- Name: conversation_one_per_course; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX conversation_one_per_course ON public.conversation USING btree (course_id) WHERE (course_id IS NOT NULL);


--
-- Name: conversation_one_per_freeplay_request; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX conversation_one_per_freeplay_request ON public.conversation USING btree (freeplay_request_id) WHERE (freeplay_request_id IS NOT NULL);


--
-- Name: course_member_one_coach_per_sport; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX course_member_one_coach_per_sport ON public.course_member USING btree (user_id, sport_id) WHERE (status = 'enrolled'::public.course_member_status);


--
-- Name: course_member_one_live_thread; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX course_member_one_live_thread ON public.course_member USING btree (user_id, professional_id, sport_id) WHERE (status = ANY (ARRAY['inquiring'::public.course_member_status, 'enrolled'::public.course_member_status]));


--
-- Name: course_member_user_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX course_member_user_idx ON public.course_member USING btree (user_id);


--
-- Name: course_offer_one_pending; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX course_offer_one_pending ON public.course_enrollment_offer USING btree (course_id, user_id) WHERE (status = 'pending'::public.course_offer_status);


--
-- Name: course_professional_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX course_professional_idx ON public.course USING btree (professional_id, status);


--
-- Name: freeplay_activity_city_cluster_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX freeplay_activity_city_cluster_idx ON public.freeplay_activity USING btree (city_cluster) WHERE (city_cluster IS NOT NULL);


--
-- Name: freeplay_request_activity_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX freeplay_request_activity_status_idx ON public.freeplay_request USING btree (activity_id, status, created_at);


--
-- Name: freeplay_request_one_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX freeplay_request_one_active ON public.freeplay_request USING btree (activity_id, user_id) WHERE (status = ANY (ARRAY['pending'::public.freeplay_request_status, 'accepted'::public.freeplay_request_status]));


--
-- Name: freeplay_request_user_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX freeplay_request_user_idx ON public.freeplay_request USING btree (user_id, created_at DESC);


--
-- Name: friendship_addressee_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX friendship_addressee_idx ON public.friendship USING btree (addressee_id, status);


--
-- Name: friendship_one_live_per_pair; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX friendship_one_live_per_pair ON public.friendship USING btree (LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id)) WHERE (status = ANY (ARRAY['pending'::public.friendship_status, 'accepted'::public.friendship_status]));


--
-- Name: friendship_requester_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX friendship_requester_idx ON public.friendship USING btree (requester_id, status);


--
-- Name: idx_activity_health_metrics_activity_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_health_metrics_activity_id ON public.activity_health_metrics USING btree (activity_id);


--
-- Name: idx_activity_health_metrics_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_health_metrics_user_id ON public.activity_health_metrics USING btree (user_id);


--
-- Name: idx_activity_hr_sample_activity_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_hr_sample_activity_timestamp ON public.activity_hr_sample USING btree (activity_id, "timestamp");


--
-- Name: idx_activity_series_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_series_id ON public.activity USING btree (series_id) WHERE (series_id IS NOT NULL);


--
-- Name: idx_activity_sport_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_sport_id ON public.activity USING btree (sport_id);


--
-- Name: idx_activity_start_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_start_time ON public.activity USING btree (start_time);


--
-- Name: idx_activity_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_user_id ON public.activity USING btree (user_id);


--
-- Name: idx_booking_additional_users_booking_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_booking_additional_users_booking_id ON public.referee_booking_additional_users USING btree (booking_id);


--
-- Name: idx_booking_additional_users_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_booking_additional_users_user_id ON public.referee_booking_additional_users USING btree (user_id);


--
-- Name: idx_bookings_client_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_client_user_id ON public.referee_booking USING btree (client_user_id);


--
-- Name: idx_bookings_professional_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_professional_id ON public.referee_booking USING btree (professional_id);


--
-- Name: idx_bookings_service_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_service_id ON public.referee_booking USING btree (service_id);


--
-- Name: idx_bookings_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_status ON public.referee_booking USING btree (status);


--
-- Name: idx_daily_health_summary_user_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_daily_health_summary_user_date ON public.daily_health_summary USING btree (user_id, date DESC);


--
-- Name: idx_listed_professionals_is_verified; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_listed_professionals_is_verified ON public.professional USING btree (is_verified);


--
-- Name: idx_listed_professionals_linked_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_listed_professionals_linked_user_id ON public.professional USING btree (linked_user_id) WHERE (linked_user_id IS NOT NULL);


--
-- Name: idx_listed_professionals_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_listed_professionals_role ON public.professional USING btree (professional_role);


--
-- Name: idx_lobby_befriend_record_initiator; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lobby_befriend_record_initiator ON public.lobby_befriend_record USING btree (initiator_user_id);


--
-- Name: idx_lobby_befriend_record_interaction_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lobby_befriend_record_interaction_type ON public.lobby_befriend_record USING btree (interaction_type);


--
-- Name: idx_lobby_befriend_record_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lobby_befriend_record_status ON public.lobby_befriend_record USING btree (status);


--
-- Name: idx_lobby_befriend_record_target_lobby; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lobby_befriend_record_target_lobby ON public.lobby_befriend_record USING btree (target_lobby_id);


--
-- Name: idx_lobby_befriend_record_target_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lobby_befriend_record_target_user ON public.lobby_befriend_record USING btree (target_user_id);


--
-- Name: idx_lobby_captain_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lobby_captain_id ON public.lobby USING btree (captain_id);


--
-- Name: idx_lobby_home_ground; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lobby_home_ground ON public.lobby USING btree (home_ground);


--
-- Name: idx_lobby_invite_link_lobby_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lobby_invite_link_lobby_id ON public.lobby_invite_link USING btree (lobby_id);


--
-- Name: idx_lobby_member_lobby_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lobby_member_lobby_id ON public.lobby_member USING btree (lobby_id);


--
-- Name: idx_lobby_member_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lobby_member_user_id ON public.lobby_member USING btree (user_id);


--
-- Name: idx_lobby_sport_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lobby_sport_id ON public.lobby USING btree (sport_id);


--
-- Name: idx_location_city_cluster; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_location_city_cluster ON public.location USING btree (city_cluster);


--
-- Name: idx_location_full_address_trgm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_location_full_address_trgm ON public.location USING gin (public.immutable_unaccent(lower(full_address)) extensions.gin_trgm_ops);


--
-- Name: idx_location_name_trgm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_location_name_trgm ON public.location USING gin (public.immutable_unaccent(lower(name)) extensions.gin_trgm_ops);


--
-- Name: idx_network_city; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_network_city ON public.network USING btree (city);


--
-- Name: idx_professional_booking_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_professional_booking_location_id ON public.referee_booking USING btree (location_id);


--
-- Name: idx_professional_booking_package_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_professional_booking_package_id ON public.referee_booking USING btree (package_id);


--
-- Name: idx_professional_preferred_city_cluster; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_professional_preferred_city_cluster ON public.professional USING btree (preferred_city_cluster);


--
-- Name: idx_professional_preferred_location_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_professional_preferred_location_location ON public.professional_preferred_location USING btree (location_id);


--
-- Name: idx_professional_review_professional_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_professional_review_professional_id ON public.referee_booking_review USING btree (professional_id);


--
-- Name: idx_professional_review_reviewer_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_professional_review_reviewer_user_id ON public.referee_booking_review USING btree (reviewer_user_id);


--
-- Name: idx_professional_services_is_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_professional_services_is_active ON public.professional_service USING btree (is_active);


--
-- Name: idx_professional_services_listed_professional_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_professional_services_listed_professional_id ON public.professional_service USING btree (professional_id);


--
-- Name: idx_professional_services_sport_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_professional_services_sport_id ON public.professional_service USING btree (sport_id);


--
-- Name: idx_user_industry_industry_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_industry_industry_id ON public.user_industry USING btree (industry_id);


--
-- Name: idx_user_industry_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_industry_user_id ON public.user_industry USING btree (user_id);


--
-- Name: idx_user_network_network_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_network_network_id ON public.user_network USING btree (network_id);


--
-- Name: idx_user_network_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_network_user_id ON public.user_network USING btree (user_id);


--
-- Name: idx_vitality_daily_load_user_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vitality_daily_load_user_date ON public.vitality_daily_load USING btree (user_id, date DESC);


--
-- Name: idx_vitality_score_user_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vitality_score_user_date ON public.vitality_score USING btree (user_id, date DESC);


--
-- Name: lobby_challenge_offer_time_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX lobby_challenge_offer_time_idx ON public.lobby USING btree (challenge_offer_time) WHERE open_to_challengers;


--
-- Name: lobby_challenge_one_open; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX lobby_challenge_one_open ON public.lobby_challenge USING btree (initiator_lobby_id, target_lobby_id) WHERE (status = 'requested'::public.lobby_challenge_status);


--
-- Name: lobby_challenge_target_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX lobby_challenge_target_idx ON public.lobby_challenge USING btree (target_lobby_id, status);


--
-- Name: lobby_feed_item_activity_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX lobby_feed_item_activity_id_idx ON public.lobby_feed_item USING btree (activity_id) WHERE (activity_id IS NOT NULL);


--
-- Name: lobby_feed_item_lobby_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX lobby_feed_item_lobby_idx ON public.lobby_feed_item USING btree (lobby_id, created_at DESC);


--
-- Name: lobby_feed_item_one_late_per_activity_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX lobby_feed_item_one_late_per_activity_idx ON public.lobby_feed_item USING btree (activity_id, author_id) WHERE ((kind = 'personal'::public.lobby_feed_item_kind) AND ((payload ->> 'action_kind'::text) = 'late'::text));


--
-- Name: lobby_feed_item_one_note_per_activity_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX lobby_feed_item_one_note_per_activity_idx ON public.lobby_feed_item USING btree (activity_id, author_id) WHERE ((kind = 'personal'::public.lobby_feed_item_kind) AND ((payload ->> 'action_kind'::text) = 'note'::text));


--
-- Name: lobby_match_lobby_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX lobby_match_lobby_idx ON public.lobby_match USING btree (lobby_id, played_at DESC);


--
-- Name: lobby_match_opponent_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX lobby_match_opponent_idx ON public.lobby_match USING btree (opponent_lobby_id, played_at DESC) WHERE (opponent_lobby_id IS NOT NULL);


--
-- Name: lobby_open_challenger_mmr_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX lobby_open_challenger_mmr_idx ON public.lobby USING btree (sport_id, mmr) WHERE open_to_challengers;


--
-- Name: lobby_payment_request_payee_outstanding_user_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX lobby_payment_request_payee_outstanding_user_idx ON public.lobby_payment_request_payee USING btree (user_id, recipient_id) WHERE (status = 'outstanding'::public.lobby_payment_status);


--
-- Name: lobby_payment_request_payee_recipient_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX lobby_payment_request_payee_recipient_idx ON public.lobby_payment_request_payee USING btree (recipient_id);


--
-- Name: lobby_payment_request_payee_user_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX lobby_payment_request_payee_user_idx ON public.lobby_payment_request_payee USING btree (user_id);


--
-- Name: lobby_payment_settlement_item_settlement_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX lobby_payment_settlement_item_settlement_idx ON public.lobby_payment_settlement_item USING btree (settlement_id);


--
-- Name: lobby_payment_settlement_lobby_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX lobby_payment_settlement_lobby_idx ON public.lobby_payment_settlement USING btree (lobby_id);


--
-- Name: lobby_payment_settlement_recipient_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX lobby_payment_settlement_recipient_idx ON public.lobby_payment_settlement USING btree (recipient_id);


--
-- Name: message_conversation_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX message_conversation_created_idx ON public.message USING btree (conversation_id, created_at);


--
-- Name: network_name_lower_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX network_name_lower_idx ON public.network USING btree (lower(name) text_pattern_ops);


--
-- Name: network_name_partial_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX network_name_partial_idx ON public.network USING btree (name text_pattern_ops);


--
-- Name: network_name_trgm_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX network_name_trgm_idx ON public.network USING gin (lower(name) extensions.gin_trgm_ops);


--
-- Name: network_name_unaccent_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX network_name_unaccent_idx ON public.network USING btree (public.immutable_unaccent(lower(name)) text_pattern_ops);


--
-- Name: network_name_unaccent_trgm_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX network_name_unaccent_trgm_idx ON public.network USING gin (public.immutable_unaccent(lower(name)) extensions.gin_trgm_ops);


--
-- Name: notification_outbox_pending_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notification_outbox_pending_idx ON public.notification_outbox USING btree (created_at) WHERE (status = ANY (ARRAY['pending'::text, 'sending'::text]));


--
-- Name: notification_outbox_recipient_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notification_outbox_recipient_idx ON public.notification_outbox USING btree (recipient_user_id, created_at DESC);


--
-- Name: professional_booking_review_one_per_package; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX professional_booking_review_one_per_package ON public.referee_booking_review USING btree (package_id) WHERE (package_id IS NOT NULL);


--
-- Name: soccer_profile_pitch_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX soccer_profile_pitch_idx ON public.soccer_profile USING gin (pitch);


--
-- Name: soccer_profile_position_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX soccer_profile_position_idx ON public.soccer_profile USING gin ("position");


--
-- Name: social_event_user_kind_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX social_event_user_kind_idx ON public.social_event USING btree (user_id, kind, created_at);


--
-- Name: user_block_blocked_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_block_blocked_idx ON public.user_block USING btree (blocked_id);


--
-- Name: user_device_token_user_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_device_token_user_idx ON public.user_device_token USING btree (user_id);


--
-- Name: user_payment_info_user_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_payment_info_user_idx ON public.user_payment_info USING btree (user_id);


--
-- Name: user_rating_user_sport_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_rating_user_sport_idx ON public.user_rating USING btree (user_id, sport);


--
-- Name: wall_post_author_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX wall_post_author_created_idx ON public.wall_post USING btree (author_id, created_at DESC);


--
-- Name: wall_post_expiry_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX wall_post_expiry_idx ON public.wall_post USING btree (expires_at);


--
-- Name: wall_post_lobby_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX wall_post_lobby_idx ON public.wall_post USING btree (lobby_id) WHERE (lobby_id IS NOT NULL);


--
-- Name: wall_post_one_per_activity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX wall_post_one_per_activity ON public.wall_post USING btree (author_id, activity_id) WHERE (activity_id IS NOT NULL);


--
-- Name: wall_post_report_post_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX wall_post_report_post_idx ON public.wall_post_report USING btree (post_id);


--
-- Name: wall_post_tag_user_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX wall_post_tag_user_idx ON public.wall_post_tag USING btree (user_id);


--
-- Name: ix_realtime_subscription_entity; Type: INDEX; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE INDEX ix_realtime_subscription_entity ON realtime.subscription USING btree (entity);


--
-- Name: messages_inserted_at_topic_index; Type: INDEX; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE INDEX messages_inserted_at_topic_index ON ONLY realtime.messages USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_08_12_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE INDEX messages_2026_08_12_inserted_at_topic_idx ON realtime.messages_2026_08_12 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_08_13_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE INDEX messages_2026_08_13_inserted_at_topic_idx ON realtime.messages_2026_08_13 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_08_14_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE INDEX messages_2026_08_14_inserted_at_topic_idx ON realtime.messages_2026_08_14 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_08_15_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE INDEX messages_2026_08_15_inserted_at_topic_idx ON realtime.messages_2026_08_15 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_08_16_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE INDEX messages_2026_08_16_inserted_at_topic_idx ON realtime.messages_2026_08_16 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_08_17_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE INDEX messages_2026_08_17_inserted_at_topic_idx ON realtime.messages_2026_08_17 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_08_18_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE INDEX messages_2026_08_18_inserted_at_topic_idx ON realtime.messages_2026_08_18 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: subscription_subscription_id_entity_filters_action_filter_selec; Type: INDEX; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE UNIQUE INDEX subscription_subscription_id_entity_filters_action_filter_selec ON realtime.subscription USING btree (subscription_id, entity, filters, action_filter, COALESCE(selected_columns, '{}'::text[]));


--
-- Name: bname; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE UNIQUE INDEX bname ON storage.buckets USING btree (name);


--
-- Name: bucketid_objname; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE UNIQUE INDEX bucketid_objname ON storage.objects USING btree (bucket_id, name);


--
-- Name: buckets_analytics_unique_name_idx; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE UNIQUE INDEX buckets_analytics_unique_name_idx ON storage.buckets_analytics USING btree (name) WHERE (deleted_at IS NULL);


--
-- Name: idx_multipart_uploads_list; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE INDEX idx_multipart_uploads_list ON storage.s3_multipart_uploads USING btree (bucket_id, key, created_at);


--
-- Name: idx_objects_bucket_id_name; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE INDEX idx_objects_bucket_id_name ON storage.objects USING btree (bucket_id, name COLLATE "C");


--
-- Name: idx_objects_bucket_id_name_lower; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE INDEX idx_objects_bucket_id_name_lower ON storage.objects USING btree (bucket_id, lower(name) COLLATE "C");


--
-- Name: name_prefix_search; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE INDEX name_prefix_search ON storage.objects USING btree (name text_pattern_ops);


--
-- Name: vector_indexes_name_bucket_id_idx; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE UNIQUE INDEX vector_indexes_name_bucket_id_idx ON storage.vector_indexes USING btree (name, bucket_id);


--
-- Name: messages_2026_08_12_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_08_12_inserted_at_topic_idx;


--
-- Name: messages_2026_08_12_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_08_12_pkey;


--
-- Name: messages_2026_08_13_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_08_13_inserted_at_topic_idx;


--
-- Name: messages_2026_08_13_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_08_13_pkey;


--
-- Name: messages_2026_08_14_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_08_14_inserted_at_topic_idx;


--
-- Name: messages_2026_08_14_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_08_14_pkey;


--
-- Name: messages_2026_08_15_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_08_15_inserted_at_topic_idx;


--
-- Name: messages_2026_08_15_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_08_15_pkey;


--
-- Name: messages_2026_08_16_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_08_16_inserted_at_topic_idx;


--
-- Name: messages_2026_08_16_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_08_16_pkey;


--
-- Name: messages_2026_08_17_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_08_17_inserted_at_topic_idx;


--
-- Name: messages_2026_08_17_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_08_17_pkey;


--
-- Name: messages_2026_08_18_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_08_18_inserted_at_topic_idx;


--
-- Name: messages_2026_08_18_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_08_18_pkey;


--
-- Name: wall_post_moderation_queue _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.wall_post_moderation_queue WITH (security_invoker='true') AS
 SELECT p.id,
    p.author_id,
    p.caption,
    p.media,
    p.created_at,
    p.expires_at,
    p.hidden_at,
    count(r.*) AS report_count,
    array_agg(DISTINCT r.reason) AS reasons
   FROM (public.wall_post p
     JOIN public.wall_post_report r ON ((r.post_id = p.id)))
  GROUP BY p.id
  ORDER BY (count(r.*)) DESC, p.created_at DESC;


--
-- Name: users on_auth_user_created; Type: TRIGGER; Schema: auth; Owner: supabase_auth_admin
--

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.new_user_created_trigger_fn();


--
-- Name: activity activity_attachment_role_check; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER activity_attachment_role_check BEFORE INSERT OR UPDATE OF referee_booking_id ON public.activity FOR EACH ROW EXECUTE FUNCTION public.fn_activity_attachment_role_check();


--
-- Name: activity_confirmation activity_confirmed_emit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER activity_confirmed_emit AFTER INSERT OR UPDATE ON public.activity_confirmation FOR EACH ROW EXECUTE FUNCTION public.fn_emit_activity_confirmed();


--
-- Name: activity activity_scheduled_emit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER activity_scheduled_emit AFTER INSERT ON public.activity FOR EACH ROW EXECUTE FUNCTION public.fn_emit_activity_scheduled();


--
-- Name: activity activity_series_frontier_bump; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER activity_series_frontier_bump AFTER INSERT OR UPDATE OF series_id, start_time ON public.activity FOR EACH ROW WHEN ((new.series_id IS NOT NULL)) EXECUTE FUNCTION public.fn_bump_series_frontier();


--
-- Name: badminton_profile badminton_elo_seed; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER badminton_elo_seed AFTER INSERT OR UPDATE OF elo_seed ON public.badminton_profile FOR EACH ROW EXECUTE FUNCTION public.fn_seed_initial_elo();


--
-- Name: basketball_profile basketball_elo_seed; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER basketball_elo_seed AFTER INSERT OR UPDATE OF elo_seed ON public.basketball_profile FOR EACH ROW EXECUTE FUNCTION public.fn_seed_initial_elo();


--
-- Name: lobby_payment_request_payee fill_payment_request_recipient; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER fill_payment_request_recipient BEFORE INSERT OR UPDATE OF feed_item_id, user_id ON public.lobby_payment_request_payee FOR EACH ROW EXECUTE FUNCTION public.fn_fill_payment_request_recipient();


--
-- Name: user_block freeplay_block_cleanup; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER freeplay_block_cleanup AFTER INSERT ON public.user_block FOR EACH ROW EXECUTE FUNCTION public.fn_freeplay_block_cleanup();


--
-- Name: lobby lobby_add_captain_as_member; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER lobby_add_captain_as_member AFTER INSERT ON public.lobby FOR EACH ROW EXECUTE FUNCTION public.lobby_add_captain_as_member();


--
-- Name: lobby lobby_before_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER lobby_before_delete BEFORE DELETE ON public.lobby FOR EACH ROW EXECUTE FUNCTION public.lobby_before_delete();


--
-- Name: lobby_befriend_record lobby_befriend_accepted_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER lobby_befriend_accepted_trigger AFTER UPDATE ON public.lobby_befriend_record FOR EACH ROW EXECUTE FUNCTION public.lobby_befriend_accepted_trigger_fn();


--
-- Name: lobby_befriend_record lobby_befriend_invite_notify; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER lobby_befriend_invite_notify AFTER INSERT ON public.lobby_befriend_record FOR EACH ROW WHEN ((new.interaction_type = 'invite'::public.lobby_befriend_interaction)) EXECUTE FUNCTION public.fn_notify_lobby_invite();


--
-- Name: lobby_befriend_record lobby_befriend_record_before_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER lobby_befriend_record_before_insert BEFORE INSERT ON public.lobby_befriend_record FOR EACH ROW EXECUTE FUNCTION public.lobby_befriend_record_before_insert_trigger_fn();


--
-- Name: lobby_befriend_record lobby_join_request_notify; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER lobby_join_request_notify AFTER INSERT ON public.lobby_befriend_record FOR EACH ROW WHEN (((new.interaction_type = 'request'::public.lobby_befriend_interaction) AND (new.status = 'pending'::public.lobby_befriend_status))) EXECUTE FUNCTION public.fn_emit_lobby_join_request();


--
-- Name: lobby_befriend_record lobby_join_request_response_notify; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER lobby_join_request_response_notify AFTER UPDATE OF status ON public.lobby_befriend_record FOR EACH ROW WHEN (((new.interaction_type = 'request'::public.lobby_befriend_interaction) AND (old.status = 'pending'::public.lobby_befriend_status) AND (new.status = ANY (ARRAY['accepted'::public.lobby_befriend_status, 'declined'::public.lobby_befriend_status])))) EXECUTE FUNCTION public.fn_emit_lobby_join_request_response();


--
-- Name: lobby_match lobby_match_apply_rating; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER lobby_match_apply_rating AFTER INSERT ON public.lobby_match FOR EACH ROW WHEN (((new.opponent_lobby_id IS NOT NULL) AND (new.result <> 'practice'::public.lobby_match_result) AND (new.referee_booking_id IS NOT NULL))) EXECUTE FUNCTION public.trg_lobby_match_rating();


--
-- Name: lobby_match lobby_match_complete_referee_booking; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER lobby_match_complete_referee_booking AFTER INSERT ON public.lobby_match FOR EACH ROW WHEN ((new.referee_booking_id IS NOT NULL)) EXECUTE FUNCTION public.fn_complete_referee_booking_on_match();


--
-- Name: lobby_match lobby_match_rated_count; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER lobby_match_rated_count AFTER INSERT OR DELETE OR UPDATE ON public.lobby_match FOR EACH ROW EXECUTE FUNCTION public.trg_lobby_match_rated_count();


--
-- Name: lobby_match lobby_match_referee_role_check; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER lobby_match_referee_role_check BEFORE INSERT OR UPDATE OF referee_booking_id ON public.lobby_match FOR EACH ROW EXECUTE FUNCTION public.lobby_match_referee_role_check();


--
-- Name: lobby_member lobby_member_kicked_emit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER lobby_member_kicked_emit AFTER DELETE ON public.lobby_member FOR EACH ROW EXECUTE FUNCTION public.fn_emit_member_kicked();


--
-- Name: lobby_member lobby_member_prevent_captain_leave; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER lobby_member_prevent_captain_leave BEFORE DELETE ON public.lobby_member FOR EACH ROW EXECUTE FUNCTION public.lobby_member_prevent_captain_leave();


--
-- Name: lobby_member lobby_member_recompute_stats; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER lobby_member_recompute_stats AFTER INSERT OR DELETE OR UPDATE ON public.lobby_member FOR EACH ROW EXECUTE FUNCTION public.trg_lobby_member_recompute();


--
-- Name: lobby lobby_playtime_keys_biu; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER lobby_playtime_keys_biu BEFORE INSERT OR UPDATE OF playtime ON public.lobby FOR EACH ROW EXECUTE FUNCTION public.trg_lobby_playtime_keys();


--
-- Name: notification_outbox notification_outbox_poke; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER notification_outbox_poke AFTER INSERT ON public.notification_outbox FOR EACH STATEMENT EXECUTE FUNCTION public.fn_outbox_poke();


--
-- Name: pickleball_profile pickleball_elo_seed; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER pickleball_elo_seed AFTER INSERT OR UPDATE OF elo_seed ON public.pickleball_profile FOR EACH ROW EXECUTE FUNCTION public.fn_seed_initial_elo();


--
-- Name: referee_booking_review professional_review_stats_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER professional_review_stats_trigger AFTER INSERT OR DELETE OR UPDATE ON public.referee_booking_review FOR EACH ROW EXECUTE FUNCTION public.referee_booking_review_updated_trigger_fn();


--
-- Name: referee_booking referee_booking_created_notify; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER referee_booking_created_notify AFTER INSERT ON public.referee_booking FOR EACH ROW EXECUTE FUNCTION public.fn_notify_referee_booking_created();


--
-- Name: referee_booking_review referee_booking_review_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER referee_booking_review_guard BEFORE INSERT OR UPDATE ON public.referee_booking_review FOR EACH ROW EXECUTE FUNCTION public.fn_guard_referee_booking_review();


--
-- Name: referee_booking referee_booking_status_changed_notify; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER referee_booking_status_changed_notify AFTER UPDATE ON public.referee_booking FOR EACH ROW WHEN (((new.status IS DISTINCT FROM old.status) AND (new.status = ANY (ARRAY['confirmed'::public.professional_booking_status, 'rejected'::public.professional_booking_status])))) EXECUTE FUNCTION public.fn_notify_referee_booking_status_changed();


--
-- Name: soccer_profile soccer_elo_seed; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER soccer_elo_seed AFTER INSERT OR UPDATE OF elo_seed ON public.soccer_profile FOR EACH ROW EXECUTE FUNCTION public.fn_seed_initial_elo();


--
-- Name: tennis_profile tennis_elo_seed; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tennis_elo_seed AFTER INSERT OR UPDATE OF elo_seed ON public.tennis_profile FOR EACH ROW EXECUTE FUNCTION public.fn_seed_initial_elo();


--
-- Name: message trg_broadcast_message; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_broadcast_message AFTER INSERT ON public.message FOR EACH ROW EXECUTE FUNCTION public.fn_broadcast_message();


--
-- Name: course_member trg_course_member_denormalise; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_course_member_denormalise BEFORE INSERT ON public.course_member FOR EACH ROW EXECUTE FUNCTION public.fn_course_member_denormalise();


--
-- Name: course_review trg_course_review_rollup; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_course_review_rollup AFTER INSERT ON public.course_review FOR EACH ROW EXECUTE FUNCTION public.fn_course_review_rollup();


--
-- Name: referee_booking trg_referee_booking_role_check; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_referee_booking_role_check BEFORE INSERT OR UPDATE OF professional_id ON public.referee_booking FOR EACH ROW EXECUTE FUNCTION public.fn_referee_booking_role_check();


--
-- Name: lobby_befriend_record trg_reject_pair_befriend; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_reject_pair_befriend BEFORE INSERT ON public.lobby_befriend_record FOR EACH ROW EXECUTE FUNCTION public.fn_reject_pair_befriend();


--
-- Name: wall_post trg_social_event_on_post; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_social_event_on_post AFTER INSERT ON public.wall_post FOR EACH ROW EXECUTE FUNCTION public._fn_social_event_on_post();


--
-- Name: wall_post_reaction trg_social_event_on_reaction; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_social_event_on_reaction AFTER INSERT ON public.wall_post_reaction FOR EACH ROW EXECUTE FUNCTION public._fn_social_event_on_reaction();


--
-- Name: user_contact trg_user_contact_touch; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_user_contact_touch BEFORE UPDATE ON public.user_contact FOR EACH ROW EXECUTE FUNCTION public.fn_touch_user_contact();


--
-- Name: wall_post_report trg_wall_post_autohide; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_wall_post_autohide AFTER INSERT ON public.wall_post_report FOR EACH ROW EXECUTE FUNCTION public.fn_wall_post_autohide();


--
-- Name: wall_post_tag trg_wall_post_tag_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_wall_post_tag_guard BEFORE INSERT ON public.wall_post_tag FOR EACH ROW EXECUTE FUNCTION public.fn_wall_post_tag_guard();


--
-- Name: user_industry user_industry_recompute_lobby; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER user_industry_recompute_lobby AFTER INSERT OR DELETE OR UPDATE ON public.user_industry FOR EACH ROW EXECUTE FUNCTION public.trg_user_affiliation_recompute();


--
-- Name: user_network user_network_recompute_lobby; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER user_network_recompute_lobby AFTER INSERT OR DELETE OR UPDATE ON public.user_network FOR EACH ROW EXECUTE FUNCTION public.trg_user_affiliation_recompute();


--
-- Name: user_rating user_rating_recompute_lobby; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER user_rating_recompute_lobby AFTER INSERT OR UPDATE OF elo ON public.user_rating FOR EACH ROW EXECUTE FUNCTION public.trg_user_rating_recompute();


--
-- Name: lobby_feed_item validate_activity_feed_item_scope; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER validate_activity_feed_item_scope BEFORE INSERT OR UPDATE OF lobby_id, activity_id ON public.lobby_feed_item FOR EACH ROW EXECUTE FUNCTION public.fn_validate_activity_feed_item_scope();


--
-- Name: subscription tr_check_filters; Type: TRIGGER; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE TRIGGER tr_check_filters BEFORE INSERT OR UPDATE ON realtime.subscription FOR EACH ROW EXECUTE FUNCTION realtime.subscription_check_filters();


--
-- Name: buckets enforce_bucket_name_length_trigger; Type: TRIGGER; Schema: storage; Owner: supabase_storage_admin
--

CREATE TRIGGER enforce_bucket_name_length_trigger BEFORE INSERT OR UPDATE OF name ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.enforce_bucket_name_length();


--
-- Name: buckets protect_buckets_delete; Type: TRIGGER; Schema: storage; Owner: supabase_storage_admin
--

CREATE TRIGGER protect_buckets_delete BEFORE DELETE ON storage.buckets FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


--
-- Name: objects protect_objects_delete; Type: TRIGGER; Schema: storage; Owner: supabase_storage_admin
--

CREATE TRIGGER protect_objects_delete BEFORE DELETE ON storage.objects FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


--
-- Name: objects update_objects_updated_at; Type: TRIGGER; Schema: storage; Owner: supabase_storage_admin
--

CREATE TRIGGER update_objects_updated_at BEFORE UPDATE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.update_updated_at_column();


--
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: mfa_challenges mfa_challenges_auth_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- Name: mfa_factors mfa_factors_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: one_time_tokens one_time_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: saml_providers saml_providers_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_flow_state_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_flow_state_id_fkey FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_oauth_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_oauth_client_id_fkey FOREIGN KEY (oauth_client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sso_domains sso_domains_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: webauthn_challenges webauthn_challenges_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.webauthn_challenges
    ADD CONSTRAINT webauthn_challenges_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: webauthn_credentials webauthn_credentials_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: achievement achievement_sport_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.achievement
    ADD CONSTRAINT achievement_sport_fkey FOREIGN KEY (sport) REFERENCES public.sport(id);


--
-- Name: activity activity_challenge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_challenge_id_fkey FOREIGN KEY (challenge_id) REFERENCES public.lobby_challenge(id) ON DELETE SET NULL;


--
-- Name: activity_confirmation activity_confirmation_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_confirmation
    ADD CONSTRAINT activity_confirmation_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: activity_confirmation activity_confirmation_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_confirmation
    ADD CONSTRAINT activity_confirmation_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: activity activity_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: activity activity_freeplay_host_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_freeplay_host_id_fkey FOREIGN KEY (freeplay_host_id) REFERENCES public.freeplay_host(id) ON DELETE RESTRICT;


--
-- Name: activity_health_metrics activity_health_metrics_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_health_metrics
    ADD CONSTRAINT activity_health_metrics_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: activity_health_metrics activity_health_metrics_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_health_metrics
    ADD CONSTRAINT activity_health_metrics_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: activity_hr_sample activity_hr_sample_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_hr_sample
    ADD CONSTRAINT activity_hr_sample_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: activity activity_lobby_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES public.lobby(id) ON DELETE SET NULL;


--
-- Name: activity activity_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.location(id) ON DELETE SET NULL;


--
-- Name: activity activity_proposed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_proposed_by_fkey FOREIGN KEY (proposed_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: activity activity_referee_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_referee_booking_id_fkey FOREIGN KEY (referee_booking_id) REFERENCES public.referee_booking(id) ON DELETE SET NULL;


--
-- Name: activity_reminder_sent activity_reminder_sent_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_reminder_sent
    ADD CONSTRAINT activity_reminder_sent_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: activity activity_sport_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_sport_id_fkey FOREIGN KEY (sport_id) REFERENCES public.sport(id);


--
-- Name: activity activity_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: badminton_profile badminton_profile_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.badminton_profile
    ADD CONSTRAINT badminton_profile_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: basketball_profile basketball_profile_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.basketball_profile
    ADD CONSTRAINT basketball_profile_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: referee_booking_additional_users booking_additional_users_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referee_booking_additional_users
    ADD CONSTRAINT booking_additional_users_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.referee_booking(id) ON DELETE CASCADE;


--
-- Name: referee_booking_additional_users booking_additional_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referee_booking_additional_users
    ADD CONSTRAINT booking_additional_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: conversation conversation_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversation
    ADD CONSTRAINT conversation_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: conversation conversation_freeplay_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversation
    ADD CONSTRAINT conversation_freeplay_request_id_fkey FOREIGN KEY (freeplay_request_id) REFERENCES public.freeplay_request(id) ON DELETE CASCADE;


--
-- Name: conversation_member conversation_member_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversation_member
    ADD CONSTRAINT conversation_member_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversation(id) ON DELETE CASCADE;


--
-- Name: conversation_member conversation_member_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversation_member
    ADD CONSTRAINT conversation_member_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: course_enrollment_offer course_enrollment_offer_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_enrollment_offer
    ADD CONSTRAINT course_enrollment_offer_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: course_enrollment_offer course_enrollment_offer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_enrollment_offer
    ADD CONSTRAINT course_enrollment_offer_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: course_member course_member_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_member
    ADD CONSTRAINT course_member_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: course_member course_member_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_member
    ADD CONSTRAINT course_member_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: course course_professional_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course
    ADD CONSTRAINT course_professional_id_fkey FOREIGN KEY (professional_id) REFERENCES public.professional(id) ON DELETE CASCADE;


--
-- Name: course_review course_review_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_review
    ADD CONSTRAINT course_review_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: course_review course_review_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_review
    ADD CONSTRAINT course_review_student_id_fkey FOREIGN KEY (student_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: course_session_report course_session_report_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_session_report
    ADD CONSTRAINT course_session_report_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: course_session_report course_session_report_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_session_report
    ADD CONSTRAINT course_session_report_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: course_session_report course_session_report_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_session_report
    ADD CONSTRAINT course_session_report_student_id_fkey FOREIGN KEY (student_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: course course_sport_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course
    ADD CONSTRAINT course_sport_id_fkey FOREIGN KEY (sport_id) REFERENCES public.sport(id);


--
-- Name: daily_health_summary daily_health_summary_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_health_summary
    ADD CONSTRAINT daily_health_summary_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: freeplay_activity freeplay_activity_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.freeplay_activity
    ADD CONSTRAINT freeplay_activity_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: freeplay_activity freeplay_activity_city_cluster_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.freeplay_activity
    ADD CONSTRAINT freeplay_activity_city_cluster_fkey FOREIGN KEY (city_cluster) REFERENCES public.supported_city_cluster(id);


--
-- Name: freeplay_host freeplay_host_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.freeplay_host
    ADD CONSTRAINT freeplay_host_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE RESTRICT;


--
-- Name: freeplay_request freeplay_request_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.freeplay_request
    ADD CONSTRAINT freeplay_request_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.freeplay_activity(activity_id) ON DELETE CASCADE;


--
-- Name: freeplay_request freeplay_request_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.freeplay_request
    ADD CONSTRAINT freeplay_request_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: friendship friendship_addressee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendship
    ADD CONSTRAINT friendship_addressee_id_fkey FOREIGN KEY (addressee_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: friendship friendship_requester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendship
    ADD CONSTRAINT friendship_requester_id_fkey FOREIGN KEY (requester_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: lobby_befriend_record lobby_befriend_record_initiator_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_befriend_record
    ADD CONSTRAINT lobby_befriend_record_initiator_user_id_fkey FOREIGN KEY (initiator_user_id) REFERENCES public."user"(id) ON UPDATE CASCADE;


--
-- Name: lobby_befriend_record lobby_befriend_record_target_lobby_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_befriend_record
    ADD CONSTRAINT lobby_befriend_record_target_lobby_id_fkey FOREIGN KEY (target_lobby_id) REFERENCES public.lobby(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: lobby_befriend_record lobby_befriend_record_target_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_befriend_record
    ADD CONSTRAINT lobby_befriend_record_target_user_id_fkey FOREIGN KEY (target_user_id) REFERENCES public."user"(id) ON UPDATE CASCADE;


--
-- Name: lobby lobby_captain_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby
    ADD CONSTRAINT lobby_captain_id_fkey FOREIGN KEY (captain_id) REFERENCES public."user"(id) ON UPDATE CASCADE;


--
-- Name: lobby_challenge lobby_challenge_initiator_lobby_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_challenge
    ADD CONSTRAINT lobby_challenge_initiator_lobby_id_fkey FOREIGN KEY (initiator_lobby_id) REFERENCES public.lobby(id) ON DELETE CASCADE;


--
-- Name: lobby lobby_challenge_offer_location_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby
    ADD CONSTRAINT lobby_challenge_offer_location_fkey FOREIGN KEY (challenge_offer_location) REFERENCES public.location(id);


--
-- Name: lobby_challenge lobby_challenge_proposed_location_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_challenge
    ADD CONSTRAINT lobby_challenge_proposed_location_fkey FOREIGN KEY (proposed_location) REFERENCES public.location(id);


--
-- Name: lobby_challenge lobby_challenge_target_lobby_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_challenge
    ADD CONSTRAINT lobby_challenge_target_lobby_id_fkey FOREIGN KEY (target_lobby_id) REFERENCES public.lobby(id) ON DELETE CASCADE;


--
-- Name: lobby_feed_item lobby_feed_item_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_feed_item
    ADD CONSTRAINT lobby_feed_item_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE SET NULL;


--
-- Name: lobby_feed_item lobby_feed_item_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_feed_item
    ADD CONSTRAINT lobby_feed_item_author_id_fkey FOREIGN KEY (author_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: lobby_feed_item lobby_feed_item_lobby_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_feed_item
    ADD CONSTRAINT lobby_feed_item_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES public.lobby(id) ON DELETE CASCADE;


--
-- Name: lobby_feed_item_reaction lobby_feed_item_reaction_feed_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_feed_item_reaction
    ADD CONSTRAINT lobby_feed_item_reaction_feed_item_id_fkey FOREIGN KEY (feed_item_id) REFERENCES public.lobby_feed_item(id) ON DELETE CASCADE;


--
-- Name: lobby_feed_item_reaction lobby_feed_item_reaction_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_feed_item_reaction
    ADD CONSTRAINT lobby_feed_item_reaction_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: lobby_feed_poll_vote lobby_feed_poll_vote_feed_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_feed_poll_vote
    ADD CONSTRAINT lobby_feed_poll_vote_feed_item_id_fkey FOREIGN KEY (feed_item_id) REFERENCES public.lobby_feed_item(id) ON DELETE CASCADE;


--
-- Name: lobby_feed_poll_vote lobby_feed_poll_vote_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_feed_poll_vote
    ADD CONSTRAINT lobby_feed_poll_vote_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: lobby lobby_home_ground_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby
    ADD CONSTRAINT lobby_home_ground_fkey FOREIGN KEY (home_ground) REFERENCES public.location(id);


--
-- Name: lobby_invite_link lobby_invite_link_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_invite_link
    ADD CONSTRAINT lobby_invite_link_created_by_fkey FOREIGN KEY (created_by) REFERENCES public."user"(id);


--
-- Name: lobby_invite_link lobby_invite_link_lobby_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_invite_link
    ADD CONSTRAINT lobby_invite_link_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES public.lobby(id) ON DELETE CASCADE;


--
-- Name: lobby_match lobby_match_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_match
    ADD CONSTRAINT lobby_match_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE SET NULL;


--
-- Name: lobby_match lobby_match_lobby_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_match
    ADD CONSTRAINT lobby_match_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES public.lobby(id) ON DELETE CASCADE;


--
-- Name: lobby_match lobby_match_mvp_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_match
    ADD CONSTRAINT lobby_match_mvp_user_id_fkey FOREIGN KEY (mvp_user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: lobby_match lobby_match_opponent_lobby_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_match
    ADD CONSTRAINT lobby_match_opponent_lobby_id_fkey FOREIGN KEY (opponent_lobby_id) REFERENCES public.lobby(id) ON DELETE SET NULL;


--
-- Name: lobby_match lobby_match_referee_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_match
    ADD CONSTRAINT lobby_match_referee_booking_id_fkey FOREIGN KEY (referee_booking_id) REFERENCES public.referee_booking(id) ON DELETE RESTRICT;


--
-- Name: lobby_member lobby_member_lobby_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_member
    ADD CONSTRAINT lobby_member_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES public.lobby(id) ON DELETE CASCADE;


--
-- Name: lobby_member lobby_member_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_member
    ADD CONSTRAINT lobby_member_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id);


--
-- Name: lobby_payment_request_payee lobby_payment_request_payee_feed_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_payment_request_payee
    ADD CONSTRAINT lobby_payment_request_payee_feed_item_id_fkey FOREIGN KEY (feed_item_id) REFERENCES public.lobby_feed_item(id) ON DELETE CASCADE;


--
-- Name: lobby_payment_request_payee lobby_payment_request_payee_recipient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_payment_request_payee
    ADD CONSTRAINT lobby_payment_request_payee_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: lobby_payment_request_payee lobby_payment_request_payee_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_payment_request_payee
    ADD CONSTRAINT lobby_payment_request_payee_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: lobby_payment_settlement lobby_payment_settlement_feed_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_payment_settlement
    ADD CONSTRAINT lobby_payment_settlement_feed_item_id_fkey FOREIGN KEY (feed_item_id) REFERENCES public.lobby_feed_item(id) ON DELETE SET NULL;


--
-- Name: lobby_payment_settlement_item lobby_payment_settlement_item_obligation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_payment_settlement_item
    ADD CONSTRAINT lobby_payment_settlement_item_obligation_id_fkey FOREIGN KEY (obligation_id) REFERENCES public.lobby_payment_request_payee(id) ON DELETE SET NULL;


--
-- Name: lobby_payment_settlement_item lobby_payment_settlement_item_settlement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_payment_settlement_item
    ADD CONSTRAINT lobby_payment_settlement_item_settlement_id_fkey FOREIGN KEY (settlement_id) REFERENCES public.lobby_payment_settlement(id) ON DELETE CASCADE;


--
-- Name: lobby_payment_settlement lobby_payment_settlement_lobby_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_payment_settlement
    ADD CONSTRAINT lobby_payment_settlement_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES public.lobby(id) ON DELETE CASCADE;


--
-- Name: lobby_payment_settlement lobby_payment_settlement_payer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_payment_settlement
    ADD CONSTRAINT lobby_payment_settlement_payer_id_fkey FOREIGN KEY (payer_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: lobby_payment_settlement lobby_payment_settlement_recipient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_payment_settlement
    ADD CONSTRAINT lobby_payment_settlement_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: lobby lobby_sport_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby
    ADD CONSTRAINT lobby_sport_id_fkey FOREIGN KEY (sport_id) REFERENCES public.sport(id);


--
-- Name: location location_city_cluster_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT location_city_cluster_fkey FOREIGN KEY (city_cluster) REFERENCES public.supported_city_cluster(id);


--
-- Name: location location_submitted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT location_submitted_by_fkey FOREIGN KEY (submitted_by) REFERENCES public."user"(id);


--
-- Name: message message_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversation(id) ON DELETE CASCADE;


--
-- Name: message message_payment_info_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_payment_info_id_fkey FOREIGN KEY (payment_info_id) REFERENCES public.user_payment_info(id) ON DELETE SET NULL;


--
-- Name: message_poll_vote message_poll_vote_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message_poll_vote
    ADD CONSTRAINT message_poll_vote_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.message(id) ON DELETE CASCADE;


--
-- Name: message_poll_vote message_poll_vote_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message_poll_vote
    ADD CONSTRAINT message_poll_vote_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: message message_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: network network_city_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.network
    ADD CONSTRAINT network_city_fkey FOREIGN KEY (city) REFERENCES public.supported_city_cluster(id);


--
-- Name: notification_outbox notification_outbox_recipient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_outbox
    ADD CONSTRAINT notification_outbox_recipient_user_id_fkey FOREIGN KEY (recipient_user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: pickleball_profile pickleball_profile_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pickleball_profile
    ADD CONSTRAINT pickleball_profile_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: referee_booking professional_booking_client_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referee_booking
    ADD CONSTRAINT professional_booking_client_user_id_fkey FOREIGN KEY (client_user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: referee_booking professional_booking_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referee_booking
    ADD CONSTRAINT professional_booking_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.location(id);


--
-- Name: referee_booking professional_booking_professional_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referee_booking
    ADD CONSTRAINT professional_booking_professional_id_fkey FOREIGN KEY (professional_id) REFERENCES public.professional(id);


--
-- Name: referee_booking_review professional_booking_review_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referee_booking_review
    ADD CONSTRAINT professional_booking_review_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.referee_booking(id) ON DELETE RESTRICT;


--
-- Name: referee_booking_review professional_booking_review_professional_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referee_booking_review
    ADD CONSTRAINT professional_booking_review_professional_id_fkey FOREIGN KEY (professional_id) REFERENCES public.professional(id) ON DELETE CASCADE;


--
-- Name: referee_booking_review professional_booking_review_reviewer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referee_booking_review
    ADD CONSTRAINT professional_booking_review_reviewer_user_id_fkey FOREIGN KEY (reviewer_user_id) REFERENCES public."user"(id) ON DELETE RESTRICT;


--
-- Name: referee_booking professional_booking_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referee_booking
    ADD CONSTRAINT professional_booking_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.professional_service(id);


--
-- Name: professional professional_linked_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional
    ADD CONSTRAINT professional_linked_user_id_fkey FOREIGN KEY (linked_user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: professional professional_preferred_city_cluster_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional
    ADD CONSTRAINT professional_preferred_city_cluster_fkey FOREIGN KEY (preferred_city_cluster) REFERENCES public.supported_city_cluster(id);


--
-- Name: professional_preferred_location professional_preferred_location_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional_preferred_location
    ADD CONSTRAINT professional_preferred_location_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.location(id) ON DELETE CASCADE;


--
-- Name: professional_preferred_location professional_preferred_location_professional_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional_preferred_location
    ADD CONSTRAINT professional_preferred_location_professional_id_fkey FOREIGN KEY (professional_id) REFERENCES public.professional(id) ON DELETE CASCADE;


--
-- Name: professional_service professional_service_professional_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional_service
    ADD CONSTRAINT professional_service_professional_id_fkey FOREIGN KEY (professional_id) REFERENCES public.professional(id) ON DELETE CASCADE;


--
-- Name: professional_service professional_service_sport_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional_service
    ADD CONSTRAINT professional_service_sport_id_fkey FOREIGN KEY (sport_id) REFERENCES public.sport(id);


--
-- Name: soccer_profile soccer_profile_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.soccer_profile
    ADD CONSTRAINT soccer_profile_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: social_event social_event_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.social_event
    ADD CONSTRAINT social_event_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: tennis_profile tennis_profile_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tennis_profile
    ADD CONSTRAINT tennis_profile_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_achievement user_achievement_achievement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_achievement
    ADD CONSTRAINT user_achievement_achievement_id_fkey FOREIGN KEY (achievement_id) REFERENCES public.achievement(id) ON DELETE CASCADE;


--
-- Name: user_achievement user_achievement_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_achievement
    ADD CONSTRAINT user_achievement_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user_block user_block_blocked_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_block
    ADD CONSTRAINT user_block_blocked_id_fkey FOREIGN KEY (blocked_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user_block user_block_blocker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_block
    ADD CONSTRAINT user_block_blocker_id_fkey FOREIGN KEY (blocker_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user_contact user_contact_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_contact
    ADD CONSTRAINT user_contact_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user_device_token user_device_token_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_device_token
    ADD CONSTRAINT user_device_token_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user_health_link user_health_link_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_health_link
    ADD CONSTRAINT user_health_link_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON UPDATE CASCADE;


--
-- Name: user_industry user_industry_industry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_industry
    ADD CONSTRAINT user_industry_industry_id_fkey FOREIGN KEY (industry_id) REFERENCES public.industry(id);


--
-- Name: user_industry user_industry_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_industry
    ADD CONSTRAINT user_industry_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id);


--
-- Name: user_network user_network_network_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_network
    ADD CONSTRAINT user_network_network_id_fkey FOREIGN KEY (network_id) REFERENCES public.network(id);


--
-- Name: user_network user_network_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_network
    ADD CONSTRAINT user_network_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id);


--
-- Name: user_payment_info user_payment_info_account_name_secret_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_payment_info
    ADD CONSTRAINT user_payment_info_account_name_secret_id_fkey FOREIGN KEY (account_name_secret_id) REFERENCES vault.secrets(id);


--
-- Name: user_payment_info user_payment_info_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_payment_info
    ADD CONSTRAINT user_payment_info_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user_payment_info user_payment_info_value_secret_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_payment_info
    ADD CONSTRAINT user_payment_info_value_secret_id_fkey FOREIGN KEY (value_secret_id) REFERENCES vault.secrets(id);


--
-- Name: user_rating user_rating_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_rating
    ADD CONSTRAINT user_rating_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: vitality_daily_load vitality_daily_load_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vitality_daily_load
    ADD CONSTRAINT vitality_daily_load_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: vitality_score vitality_score_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vitality_score
    ADD CONSTRAINT vitality_score_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: wall_post wall_post_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wall_post
    ADD CONSTRAINT wall_post_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE SET NULL;


--
-- Name: wall_post wall_post_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wall_post
    ADD CONSTRAINT wall_post_author_id_fkey FOREIGN KEY (author_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: wall_post wall_post_lobby_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wall_post
    ADD CONSTRAINT wall_post_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES public.lobby(id) ON DELETE SET NULL;


--
-- Name: wall_post_reaction wall_post_reaction_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wall_post_reaction
    ADD CONSTRAINT wall_post_reaction_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.wall_post(id) ON DELETE CASCADE;


--
-- Name: wall_post_reaction wall_post_reaction_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wall_post_reaction
    ADD CONSTRAINT wall_post_reaction_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: wall_post_report wall_post_report_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wall_post_report
    ADD CONSTRAINT wall_post_report_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.wall_post(id) ON DELETE CASCADE;


--
-- Name: wall_post_report wall_post_report_reporter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wall_post_report
    ADD CONSTRAINT wall_post_report_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: wall_post_tag wall_post_tag_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wall_post_tag
    ADD CONSTRAINT wall_post_tag_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.wall_post(id) ON DELETE CASCADE;


--
-- Name: wall_post_tag wall_post_tag_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wall_post_tag
    ADD CONSTRAINT wall_post_tag_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: objects objects_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_upload_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES storage.s3_multipart_uploads(id) ON DELETE CASCADE;


--
-- Name: vector_indexes vector_indexes_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.vector_indexes
    ADD CONSTRAINT vector_indexes_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets_vectors(id);


--
-- Name: audit_log_entries; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.audit_log_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: flow_state; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.flow_state ENABLE ROW LEVEL SECURITY;

--
-- Name: identities; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;

--
-- Name: instances; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.instances ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_amr_claims; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.mfa_amr_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_challenges; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.mfa_challenges ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_factors; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.mfa_factors ENABLE ROW LEVEL SECURITY;

--
-- Name: one_time_tokens; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.one_time_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: refresh_tokens; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_providers; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.saml_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_relay_states; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.saml_relay_states ENABLE ROW LEVEL SECURITY;

--
-- Name: schema_migrations; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.schema_migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_domains; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.sso_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_providers; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.sso_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

--
-- Name: referee_booking_additional_users Additional users can see bookings they are part of; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Additional users can see bookings they are part of" ON public.referee_booking_additional_users FOR SELECT TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: professional Authenticated users can read professional profiles; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Authenticated users can read professional profiles" ON public.professional FOR SELECT TO authenticated USING (true);


--
-- Name: lobby_feed_item Author or captain or coordinator can delete a feed item; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Author or captain or coordinator can delete a feed item" ON public.lobby_feed_item FOR DELETE TO authenticated USING (((author_id = auth.uid()) OR public.lobby_can_manage(lobby_id)));


--
-- Name: wall_post Authors can delete their own posts; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Authors can delete their own posts" ON public.wall_post FOR DELETE TO authenticated USING ((author_id = ( SELECT auth.uid() AS uid)));


--
-- Name: wall_post Authors can write their own posts; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Authors can write their own posts" ON public.wall_post FOR INSERT TO authenticated WITH CHECK ((author_id = ( SELECT auth.uid() AS uid)));


--
-- Name: wall_post_tag Authors manage their post's tags; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Authors manage their post's tags" ON public.wall_post_tag FOR INSERT TO authenticated WITH CHECK ((EXISTS ( SELECT 1
   FROM public.wall_post p
  WHERE ((p.id = wall_post_tag.post_id) AND (p.author_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: wall_post_tag Authors remove their post's tags; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Authors remove their post's tags" ON public.wall_post_tag FOR DELETE TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.wall_post p
  WHERE ((p.id = wall_post_tag.post_id) AND (p.author_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: user_block Blocker can read their blocks; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Blocker can read their blocks" ON public.user_block FOR SELECT TO authenticated USING ((blocker_id = ( SELECT auth.uid() AS uid)));


--
-- Name: lobby Captain can delete their lobby; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Captain can delete their lobby" ON public.lobby FOR DELETE TO authenticated USING ((captain_id = ( SELECT auth.uid() AS uid)));


--
-- Name: lobby_match Captain or coordinator can delete their lobby's matches; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Captain or coordinator can delete their lobby's matches" ON public.lobby_match FOR DELETE TO authenticated USING (public.lobby_can_manage(lobby_id));


--
-- Name: lobby_match Captain or coordinator can edit their lobby's matches; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Captain or coordinator can edit their lobby's matches" ON public.lobby_match FOR UPDATE TO authenticated USING (public.lobby_can_manage(lobby_id)) WITH CHECK (public.lobby_can_manage(lobby_id));


--
-- Name: lobby_feed_item Captain or coordinator can post updates and polls; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Captain or coordinator can post updates and polls" ON public.lobby_feed_item FOR INSERT TO authenticated WITH CHECK (((author_id = auth.uid()) AND (kind = ANY (ARRAY['update'::public.lobby_feed_item_kind, 'poll'::public.lobby_feed_item_kind])) AND public.lobby_can_manage(lobby_id)));


--
-- Name: lobby_match Captain or coordinator can record matches for their lobby; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Captain or coordinator can record matches for their lobby" ON public.lobby_match FOR INSERT TO authenticated WITH CHECK (public.lobby_can_manage(lobby_id));


--
-- Name: wall_post_reaction Change your own reaction; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Change your own reaction" ON public.wall_post_reaction FOR UPDATE TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid))) WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: referee_booking_review Clients can create reviews for their completed bookings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Clients can create reviews for their completed bookings" ON public.referee_booking_review FOR INSERT TO authenticated WITH CHECK (((reviewer_user_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1
   FROM public.referee_booking pb
  WHERE ((pb.id = referee_booking_review.booking_id) AND (pb.client_user_id = ( SELECT auth.uid() AS uid)) AND (pb.professional_id = referee_booking_review.professional_id) AND (pb.status = 'completed'::public.professional_booking_status))))));


--
-- Name: referee_booking_additional_users Clients can view additional users for their bookings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Clients can view additional users for their bookings" ON public.referee_booking_additional_users FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.referee_booking pb
  WHERE ((pb.id = referee_booking_additional_users.booking_id) AND (pb.client_user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: referee_booking_review Clients can view their own booking reviews; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Clients can view their own booking reviews" ON public.referee_booking_review FOR SELECT TO authenticated USING ((reviewer_user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: referee_booking Clients can view their own bookings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Clients can view their own bookings" ON public.referee_booking FOR SELECT TO authenticated USING ((( SELECT auth.uid() AS uid) = client_user_id));


--
-- Name: activity_confirmation Course members can change own attendance; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Course members can change own attendance" ON public.activity_confirmation FOR UPDATE TO authenticated USING (((user_id = ( SELECT auth.uid() AS uid)) AND public.fn_can_access_course_activity(activity_id, ( SELECT auth.uid() AS uid)))) WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) AND public.fn_can_access_course_activity(activity_id, ( SELECT auth.uid() AS uid))));


--
-- Name: activity_confirmation Course members can retract own attendance; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Course members can retract own attendance" ON public.activity_confirmation FOR DELETE TO authenticated USING (((user_id = ( SELECT auth.uid() AS uid)) AND public.fn_can_access_course_activity(activity_id, ( SELECT auth.uid() AS uid))));


--
-- Name: activity_confirmation Course members can set own attendance; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Course members can set own attendance" ON public.activity_confirmation FOR INSERT TO authenticated WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) AND public.fn_can_access_course_activity(activity_id, ( SELECT auth.uid() AS uid))));


--
-- Name: activity_confirmation Course members can view attendance; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Course members can view attendance" ON public.activity_confirmation FOR SELECT TO authenticated USING (public.fn_can_access_course_activity(activity_id, ( SELECT auth.uid() AS uid)));


--
-- Name: lobby Enable insert for authenticated users only; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable insert for authenticated users only" ON public.lobby FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: achievement Enable read access for all users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read access for all users" ON public.achievement FOR SELECT USING (true);


--
-- Name: industry Enable read access for all users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read access for all users" ON public.industry FOR SELECT USING (true);


--
-- Name: lobby Enable read access for all users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read access for all users" ON public.lobby FOR SELECT USING (true);


--
-- Name: location Enable read access for all users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read access for all users" ON public.location FOR SELECT USING (true);


--
-- Name: network Enable read access for all users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read access for all users" ON public.network FOR SELECT USING (true);


--
-- Name: professional_preferred_location Enable read access for all users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read access for all users" ON public.professional_preferred_location FOR SELECT USING (true);


--
-- Name: sport Enable read access for all users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read access for all users" ON public.sport FOR SELECT USING (true);


--
-- Name: supported_city_cluster Enable read access for all users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read access for all users" ON public.supported_city_cluster FOR SELECT USING (true);


--
-- Name: user_industry Enable read access for authenticated user; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read access for authenticated user" ON public.user_industry FOR SELECT TO authenticated USING (true);


--
-- Name: user Enable read access for authenticated users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read access for authenticated users" ON public."user" FOR SELECT TO authenticated USING (true);


--
-- Name: user_network Enable read access for authenticated users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read access for authenticated users" ON public.user_network FOR SELECT TO authenticated USING (true);


--
-- Name: professional Enable read access for verified professional profiles; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read access for verified professional profiles" ON public.professional FOR SELECT TO anon USING ((is_verified = true));


--
-- Name: professional_service Enable read for active services by verified professionals; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read for active services by verified professionals" ON public.professional_service FOR SELECT TO anon, authenticated USING (((is_active = true) AND (EXISTS ( SELECT 1
   FROM public.professional p
  WHERE ((p.id = professional_service.professional_id) AND (p.is_verified = true))))));


--
-- Name: user Enable user to update their own profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable user to update their own profile" ON public."user" FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) = id)) WITH CHECK ((( SELECT auth.uid() AS uid) = id));


--
-- Name: freeplay_activity Freeplay Activity is RPC only; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Freeplay Activity is RPC only" ON public.freeplay_activity AS RESTRICTIVE USING (false) WITH CHECK (false);


--
-- Name: freeplay_request Freeplay Request is RPC only; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Freeplay Request is RPC only" ON public.freeplay_request AS RESTRICTIVE USING (false) WITH CHECK (false);


--
-- Name: user_contact Friends, public, freeplay hosts, and pros contacts are readable; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Friends, public, freeplay hosts, and pros contacts are readable" ON public.user_contact FOR SELECT TO authenticated USING ((zalo_public OR (user_id IN ( SELECT public.get_my_friend_ids() AS get_my_friend_ids)) OR public.fn_is_active_freeplay_host(user_id) OR public.fn_is_linked_professional(user_id)));


--
-- Name: freeplay_host Hosts can read their own display name; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Hosts can read their own display name" ON public.freeplay_host FOR SELECT TO authenticated USING ((( SELECT auth.uid() AS uid) = user_id));


--
-- Name: freeplay_host Hosts can update their own display name; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Hosts can update their own display name" ON public.freeplay_host FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) = user_id)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));


--
-- Name: professional_service Linked professionals can manage their own services; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Linked professionals can manage their own services" ON public.professional_service TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.professional p
  WHERE ((p.id = professional_service.professional_id) AND (p.linked_user_id = ( SELECT auth.uid() AS uid)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.professional p
  WHERE ((p.id = professional_service.professional_id) AND (p.linked_user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: activity Linked professionals can view their attached activities; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Linked professionals can view their attached activities" ON public.activity FOR SELECT TO authenticated USING (((referee_booking_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM (public.referee_booking pb
     JOIN public.professional pr ON ((pr.id = pb.professional_id)))
  WHERE ((pb.id = activity.referee_booking_id) AND (pr.linked_user_id = ( SELECT auth.uid() AS uid)))))));


--
-- Name: referee_booking Linked professionals can view their bookings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Linked professionals can view their bookings" ON public.referee_booking FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.professional p
  WHERE ((p.id = referee_booking.professional_id) AND (p.linked_user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: professional Linked users can update their own professional details; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Linked users can update their own professional details" ON public.professional FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) = linked_user_id)) WITH CHECK ((( SELECT auth.uid() AS uid) = linked_user_id));


--
-- Name: lobby_feed_item_reaction Lobby members can read feed item reactions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Lobby members can read feed item reactions" ON public.lobby_feed_item_reaction FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.lobby_feed_item fi
  WHERE ((fi.id = lobby_feed_item_reaction.feed_item_id) AND (fi.lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids))))));


--
-- Name: lobby_payment_request_payee Lobby members can read payment request payees; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Lobby members can read payment request payees" ON public.lobby_payment_request_payee FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.lobby_feed_item fi
  WHERE ((fi.id = lobby_payment_request_payee.feed_item_id) AND (fi.lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids))))));


--
-- Name: referee_booking Lobby members can view attached bookings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Lobby members can view attached bookings" ON public.referee_booking FOR SELECT USING (public.is_booking_attached_to_my_lobby_activity(id));


--
-- Name: activity Lobby members can view their lobby's activities; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Lobby members can view their lobby's activities" ON public.activity FOR SELECT TO authenticated USING (((lobby_id IS NOT NULL) AND (lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids))));


--
-- Name: lobby_member Lobby membership deletion policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Lobby membership deletion policy" ON public.lobby_member FOR DELETE TO authenticated USING ((((user_id = ( SELECT auth.uid() AS uid)) AND (NOT (EXISTS ( SELECT 1
   FROM public.lobby
  WHERE ((lobby.id = lobby_member.lobby_id) AND (lobby.captain_id = ( SELECT auth.uid() AS uid))))))) OR ((user_id <> ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1
   FROM public.lobby
  WHERE ((lobby.id = lobby_member.lobby_id) AND (lobby.captain_id = ( SELECT auth.uid() AS uid))))))));


--
-- Name: lobby_feed_poll_vote Members can cast a vote in their lobby's polls; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Members can cast a vote in their lobby's polls" ON public.lobby_feed_poll_vote FOR INSERT TO authenticated WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1
   FROM public.lobby_feed_item fi
  WHERE ((fi.id = lobby_feed_poll_vote.feed_item_id) AND (fi.kind = 'poll'::public.lobby_feed_item_kind) AND (fi.lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)))))));


--
-- Name: activity_confirmation Members can change their own attendance; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Members can change their own attendance" ON public.activity_confirmation FOR UPDATE TO authenticated USING (((user_id = ( SELECT auth.uid() AS uid)) AND (NOT ((attendance = 'going'::public.activity_attendance) AND public.activity_is_confirmed(activity_id))) AND (NOT (EXISTS ( SELECT 1
   FROM public.activity a
  WHERE ((a.id = activity_confirmation.activity_id) AND (a.at_risk_notified_at IS NOT NULL))))))) WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1
   FROM public.activity a
  WHERE ((a.id = activity_confirmation.activity_id) AND (a.lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)))))));


--
-- Name: activity_confirmation Members can confirm their own attendance; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Members can confirm their own attendance" ON public.activity_confirmation FOR INSERT TO authenticated WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1
   FROM public.activity a
  WHERE ((a.id = activity_confirmation.activity_id) AND (a.lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)) AND (a.at_risk_notified_at IS NULL))))));


--
-- Name: lobby_feed_item Members can post personal or photo items; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Members can post personal or photo items" ON public.lobby_feed_item FOR INSERT TO authenticated WITH CHECK (((author_id = ( SELECT auth.uid() AS uid)) AND (lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)) AND (kind = ANY (ARRAY['personal'::public.lobby_feed_item_kind, 'photo'::public.lobby_feed_item_kind]))));


--
-- Name: activity_confirmation Members can read confirmations in their lobby; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Members can read confirmations in their lobby" ON public.activity_confirmation FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.activity a
  WHERE ((a.id = activity_confirmation.activity_id) AND (a.lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids))))));


--
-- Name: lobby_feed_item Members can read feed items in their lobby; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Members can read feed items in their lobby" ON public.lobby_feed_item FOR SELECT TO authenticated USING ((lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)));


--
-- Name: lobby_feed_poll_vote Members can read poll votes in their lobby; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Members can read poll votes in their lobby" ON public.lobby_feed_poll_vote FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.lobby_feed_item fi
  WHERE ((fi.id = lobby_feed_poll_vote.feed_item_id) AND (fi.lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids))))));


--
-- Name: activity_confirmation Members can retract their own confirmation; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Members can retract their own confirmation" ON public.activity_confirmation FOR DELETE TO authenticated USING (((user_id = ( SELECT auth.uid() AS uid)) AND (NOT ((attendance = 'going'::public.activity_attendance) AND public.activity_is_confirmed(activity_id))) AND (NOT (EXISTS ( SELECT 1
   FROM public.activity a
  WHERE ((a.id = activity_confirmation.activity_id) AND (a.at_risk_notified_at IS NOT NULL)))))));


--
-- Name: lobby_invite_link Members can view their lobby's invite links; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Members can view their lobby's invite links" ON public.lobby_invite_link FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.lobby_member lm
  WHERE ((lm.lobby_id = lobby_invite_link.lobby_id) AND (lm.user_id = auth.uid())))));


--
-- Name: lobby_challenge Members of either lobby can read challenges; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Members of either lobby can read challenges" ON public.lobby_challenge FOR SELECT TO authenticated USING (((initiator_lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)) OR (target_lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids))));


--
-- Name: lobby_match Members of either lobby can read the match; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Members of either lobby can read the match" ON public.lobby_match FOR SELECT TO authenticated USING (((lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)) OR ((opponent_lobby_id IS NOT NULL) AND (opponent_lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)))));


--
-- Name: user_contact Owner can manage their contact info; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Owner can manage their contact info" ON public.user_contact TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: activity Owner or lobby manager can delete activities; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Owner or lobby manager can delete activities" ON public.activity FOR DELETE TO authenticated USING (((user_id = auth.uid()) OR ((lobby_id IS NOT NULL) AND public.lobby_can_manage(lobby_id))));


--
-- Name: activity Owner or lobby manager can update activities; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Owner or lobby manager can update activities" ON public.activity FOR UPDATE TO authenticated USING (((user_id = auth.uid()) OR ((lobby_id IS NOT NULL) AND public.lobby_can_manage(lobby_id)))) WITH CHECK (((user_id = auth.uid()) OR ((lobby_id IS NOT NULL) AND public.lobby_can_manage(lobby_id))));


--
-- Name: friendship Parties can read their friendship rows; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Parties can read their friendship rows" ON public.friendship FOR SELECT TO authenticated USING (((auth.uid() = requester_id) OR (auth.uid() = addressee_id)));


--
-- Name: wall_post_reaction React to visible posts; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "React to visible posts" ON public.wall_post_reaction FOR INSERT TO authenticated WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) AND public.fn_can_see_wall_post(post_id)));


--
-- Name: wall_post_reaction Reactions follow their post; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Reactions follow their post" ON public.wall_post_reaction FOR SELECT TO authenticated USING (public.fn_can_see_wall_post(post_id));


--
-- Name: wall_post_reaction Remove your own reaction; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Remove your own reaction" ON public.wall_post_reaction FOR DELETE TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: wall_post_report Report a visible post; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Report a visible post" ON public.wall_post_report FOR INSERT TO authenticated WITH CHECK (((reporter_id = ( SELECT auth.uid() AS uid)) AND public.fn_can_see_wall_post(post_id)));


--
-- Name: wall_post_report Reporters can see their own reports; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Reporters can see their own reports" ON public.wall_post_report FOR SELECT TO authenticated USING ((reporter_id = ( SELECT auth.uid() AS uid)));


--
-- Name: wall_post_tag Tags follow their post; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Tags follow their post" ON public.wall_post_tag FOR SELECT TO authenticated USING (public.fn_can_see_wall_post(post_id));


--
-- Name: lobby_feed_poll_vote Users can change their own vote; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can change their own vote" ON public.lobby_feed_poll_vote FOR UPDATE TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid))) WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: lobby_befriend_record Users can create befriend records with restrictions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can create befriend records with restrictions" ON public.lobby_befriend_record FOR INSERT TO authenticated WITH CHECK ((true AND ((interaction_type <> 'request'::public.lobby_befriend_interaction) OR (NOT (EXISTS ( SELECT 1
   FROM public.lobby
  WHERE ((lobby.id = lobby_befriend_record.target_lobby_id) AND (lobby.visibility = 'private'::public.lobby_visibility))))))));


--
-- Name: activity Users can create their own activities; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can create their own activities" ON public.activity FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()));


--
-- Name: activity_hr_sample Users can delete HR samples for their activities; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can delete HR samples for their activities" ON public.activity_hr_sample FOR DELETE TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.activity a
  WHERE ((a.id = activity_hr_sample.activity_id) AND (a.user_id = auth.uid())))));


--
-- Name: user_industry Users can delete their own data; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can delete their own data" ON public.user_industry FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) = user_id));


--
-- Name: user_health_link Users can delete their own health link; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can delete their own health link" ON public.user_health_link FOR DELETE TO authenticated USING ((user_id = auth.uid()));


--
-- Name: activity_health_metrics Users can delete their own health metrics; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can delete their own health metrics" ON public.activity_health_metrics FOR DELETE TO authenticated USING ((user_id = auth.uid()));


--
-- Name: user_network Users can delete their own rows; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can delete their own rows" ON public.user_network FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) = user_id));


--
-- Name: activity_hr_sample Users can insert HR samples for their activities; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert HR samples for their activities" ON public.activity_hr_sample FOR INSERT TO authenticated WITH CHECK ((EXISTS ( SELECT 1
   FROM public.activity a
  WHERE ((a.id = activity_hr_sample.activity_id) AND (a.user_id = auth.uid())))));


--
-- Name: user_industry Users can insert their own data; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert their own data" ON public.user_industry FOR INSERT TO authenticated WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));


--
-- Name: user_health_link Users can insert their own health link; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert their own health link" ON public.user_health_link FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()));


--
-- Name: activity_health_metrics Users can insert their own health metrics; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert their own health metrics" ON public.activity_health_metrics FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()));


--
-- Name: user_network Users can insert their own rows; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert their own rows" ON public.user_network FOR INSERT TO authenticated WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));


--
-- Name: lobby_feed_poll_vote Users can retract their own vote; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can retract their own vote" ON public.lobby_feed_poll_vote FOR DELETE TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: lobby_member Users can see lobby members in shared lobbies; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can see lobby members in shared lobbies" ON public.lobby_member FOR SELECT TO authenticated USING ((lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)));


--
-- Name: daily_health_summary Users can update their own daily summaries; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own daily summaries" ON public.daily_health_summary FOR UPDATE TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


--
-- Name: user_health_link Users can update their own health link; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own health link" ON public.user_health_link FOR UPDATE TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


--
-- Name: activity_health_metrics Users can update their own health metrics; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own health metrics" ON public.activity_health_metrics FOR UPDATE TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


--
-- Name: user_network Users can update their own rows; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own rows" ON public.user_network FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) = user_id)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));


--
-- Name: daily_health_summary Users can upsert their own daily summaries; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can upsert their own daily summaries" ON public.daily_health_summary FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()));


--
-- Name: activity_hr_sample Users can view HR samples for their activities; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view HR samples for their activities" ON public.activity_hr_sample FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.activity a
  WHERE ((a.id = activity_hr_sample.activity_id) AND (a.user_id = auth.uid())))));


--
-- Name: lobby_befriend_record Users can view befriend records; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view befriend records" ON public.lobby_befriend_record FOR SELECT TO authenticated USING (((( SELECT auth.uid() AS uid) = target_user_id) OR (( SELECT auth.uid() AS uid) = initiator_user_id) OR (target_lobby_id IN ( SELECT lobby_member.lobby_id
   FROM public.lobby_member
  WHERE (lobby_member.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: activity Users can view their own activities; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their own activities" ON public.activity FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: daily_health_summary Users can view their own daily summaries; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their own daily summaries" ON public.daily_health_summary FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: user_health_link Users can view their own health link; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their own health link" ON public.user_health_link FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: activity_health_metrics Users can view their own health metrics; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their own health metrics" ON public.activity_health_metrics FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: lobby_befriend_record Users involved can update befriend record status; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users involved can update befriend record status" ON public.lobby_befriend_record FOR UPDATE TO authenticated USING (((auth.uid() = initiator_user_id) OR (auth.uid() = target_user_id) OR ((target_lobby_id IS NOT NULL) AND public.lobby_can_manage(target_lobby_id)))) WITH CHECK (true);


--
-- Name: user_achievement Users see their own achievements; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users see their own achievements" ON public.user_achievement FOR SELECT TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: vitality_daily_load Users see their own daily load; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users see their own daily load" ON public.vitality_daily_load FOR SELECT TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: vitality_score Users see their own vitality score; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users see their own vitality score" ON public.vitality_score FOR SELECT TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: wall_post Visible posts are readable; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Visible posts are readable" ON public.wall_post FOR SELECT TO authenticated USING (public.fn_can_see_wall_post(id));


--
-- Name: achievement; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.achievement ENABLE ROW LEVEL SECURITY;

--
-- Name: activity; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.activity ENABLE ROW LEVEL SECURITY;

--
-- Name: activity_confirmation; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.activity_confirmation ENABLE ROW LEVEL SECURITY;

--
-- Name: activity_health_metrics; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.activity_health_metrics ENABLE ROW LEVEL SECURITY;

--
-- Name: activity_hr_sample; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.activity_hr_sample ENABLE ROW LEVEL SECURITY;

--
-- Name: activity_reminder_sent; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.activity_reminder_sent ENABLE ROW LEVEL SECURITY;

--
-- Name: activity_series_frontier; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.activity_series_frontier ENABLE ROW LEVEL SECURITY;

--
-- Name: badminton_profile badminton profiles are publicly readable; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "badminton profiles are publicly readable" ON public.badminton_profile FOR SELECT USING (true);


--
-- Name: badminton_profile; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.badminton_profile ENABLE ROW LEVEL SECURITY;

--
-- Name: basketball_profile basketball profiles are publicly readable; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "basketball profiles are publicly readable" ON public.basketball_profile FOR SELECT USING (true);


--
-- Name: basketball_profile; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.basketball_profile ENABLE ROW LEVEL SECURITY;

--
-- Name: conversation; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.conversation ENABLE ROW LEVEL SECURITY;

--
-- Name: conversation_member; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.conversation_member ENABLE ROW LEVEL SECURITY;

--
-- Name: conversation conversation_member_can_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY conversation_member_can_select ON public.conversation FOR SELECT TO authenticated USING (public.fn_is_conversation_member(id, auth.uid()));


--
-- Name: conversation_member conversation_member_self_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY conversation_member_self_select ON public.conversation_member FOR SELECT TO authenticated USING (public.fn_is_conversation_member(conversation_id, auth.uid()));


--
-- Name: course; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.course ENABLE ROW LEVEL SECURITY;

--
-- Name: course_enrollment_offer; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.course_enrollment_offer ENABLE ROW LEVEL SECURITY;

--
-- Name: course_member; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.course_member ENABLE ROW LEVEL SECURITY;

--
-- Name: course_review; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.course_review ENABLE ROW LEVEL SECURITY;

--
-- Name: course_session_report; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.course_session_report ENABLE ROW LEVEL SECURITY;

--
-- Name: daily_health_summary; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.daily_health_summary ENABLE ROW LEVEL SECURITY;

--
-- Name: user_device_token device tokens: delete own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "device tokens: delete own" ON public.user_device_token FOR DELETE TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: user_device_token device tokens: read own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "device tokens: read own" ON public.user_device_token FOR SELECT TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: user_rating elo ratings are publicly readable; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "elo ratings are publicly readable" ON public.user_rating FOR SELECT USING (true);


--
-- Name: enabled_notification_kind; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.enabled_notification_kind ENABLE ROW LEVEL SECURITY;

--
-- Name: freeplay_activity; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.freeplay_activity ENABLE ROW LEVEL SECURITY;

--
-- Name: freeplay_host; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.freeplay_host ENABLE ROW LEVEL SECURITY;

--
-- Name: freeplay_request; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.freeplay_request ENABLE ROW LEVEL SECURITY;

--
-- Name: friendship; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.friendship ENABLE ROW LEVEL SECURITY;

--
-- Name: industry; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.industry ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.lobby ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_befriend_record; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.lobby_befriend_record ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_challenge; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.lobby_challenge ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_feed_item; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.lobby_feed_item ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_feed_item_reaction; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.lobby_feed_item_reaction ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_feed_poll_vote; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.lobby_feed_poll_vote ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_invite_link; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.lobby_invite_link ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_match; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.lobby_match ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_member; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.lobby_member ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_payment_request_payee; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.lobby_payment_request_payee ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_payment_settlement; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.lobby_payment_settlement ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_payment_settlement_item; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.lobby_payment_settlement_item ENABLE ROW LEVEL SECURITY;

--
-- Name: location; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.location ENABLE ROW LEVEL SECURITY;

--
-- Name: message; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.message ENABLE ROW LEVEL SECURITY;

--
-- Name: message_poll_vote; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.message_poll_vote ENABLE ROW LEVEL SECURITY;

--
-- Name: message_poll_vote message_poll_vote_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY message_poll_vote_select ON public.message_poll_vote FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.message m
  WHERE ((m.id = message_poll_vote.message_id) AND public.fn_can_see_message(m.conversation_id, m.created_at, auth.uid())))));


--
-- Name: message message_visible_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY message_visible_select ON public.message FOR SELECT TO authenticated USING (public.fn_can_see_message(conversation_id, created_at, auth.uid()));


--
-- Name: network; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.network ENABLE ROW LEVEL SECURITY;

--
-- Name: notification_outbox; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.notification_outbox ENABLE ROW LEVEL SECURITY;

--
-- Name: notification_outbox outbox: read own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "outbox: read own" ON public.notification_outbox FOR SELECT TO authenticated USING ((recipient_user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: pickleball_profile pickleball profiles are publicly readable; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "pickleball profiles are publicly readable" ON public.pickleball_profile FOR SELECT USING (true);


--
-- Name: pickleball_profile; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.pickleball_profile ENABLE ROW LEVEL SECURITY;

--
-- Name: professional; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.professional ENABLE ROW LEVEL SECURITY;

--
-- Name: professional_preferred_location; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.professional_preferred_location ENABLE ROW LEVEL SECURITY;

--
-- Name: professional_service; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.professional_service ENABLE ROW LEVEL SECURITY;

--
-- Name: referee_booking; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.referee_booking ENABLE ROW LEVEL SECURITY;

--
-- Name: referee_booking_additional_users; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.referee_booking_additional_users ENABLE ROW LEVEL SECURITY;

--
-- Name: referee_booking_review; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.referee_booking_review ENABLE ROW LEVEL SECURITY;

--
-- Name: soccer_profile; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.soccer_profile ENABLE ROW LEVEL SECURITY;

--
-- Name: social_event; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.social_event ENABLE ROW LEVEL SECURITY;

--
-- Name: sport; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.sport ENABLE ROW LEVEL SECURITY;

--
-- Name: soccer_profile sport profiles are publicly readable; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "sport profiles are publicly readable" ON public.soccer_profile FOR SELECT USING (true);


--
-- Name: supported_city_cluster; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.supported_city_cluster ENABLE ROW LEVEL SECURITY;

--
-- Name: tennis_profile tennis profiles are publicly readable; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "tennis profiles are publicly readable" ON public.tennis_profile FOR SELECT USING (true);


--
-- Name: tennis_profile; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.tennis_profile ENABLE ROW LEVEL SECURITY;

--
-- Name: user; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."user" ENABLE ROW LEVEL SECURITY;

--
-- Name: user_achievement; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_achievement ENABLE ROW LEVEL SECURITY;

--
-- Name: user_block; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_block ENABLE ROW LEVEL SECURITY;

--
-- Name: user_contact; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_contact ENABLE ROW LEVEL SECURITY;

--
-- Name: user_device_token; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_device_token ENABLE ROW LEVEL SECURITY;

--
-- Name: user_health_link; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_health_link ENABLE ROW LEVEL SECURITY;

--
-- Name: user_industry; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_industry ENABLE ROW LEVEL SECURITY;

--
-- Name: user_network; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_network ENABLE ROW LEVEL SECURITY;

--
-- Name: user_payment_info; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_payment_info ENABLE ROW LEVEL SECURITY;

--
-- Name: user_rating; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_rating ENABLE ROW LEVEL SECURITY;

--
-- Name: badminton_profile users manage own badminton profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "users manage own badminton profile" ON public.badminton_profile USING ((auth.uid() = user_id));


--
-- Name: basketball_profile users manage own basketball profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "users manage own basketball profile" ON public.basketball_profile USING ((auth.uid() = user_id));


--
-- Name: pickleball_profile users manage own pickleball profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "users manage own pickleball profile" ON public.pickleball_profile USING ((auth.uid() = user_id));


--
-- Name: soccer_profile users manage own soccer profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "users manage own soccer profile" ON public.soccer_profile USING ((auth.uid() = user_id));


--
-- Name: tennis_profile users manage own tennis profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "users manage own tennis profile" ON public.tennis_profile USING ((auth.uid() = user_id));


--
-- Name: vitality_daily_load; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.vitality_daily_load ENABLE ROW LEVEL SECURITY;

--
-- Name: vitality_score; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.vitality_score ENABLE ROW LEVEL SECURITY;

--
-- Name: wall_post; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.wall_post ENABLE ROW LEVEL SECURITY;

--
-- Name: wall_post_gc; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.wall_post_gc ENABLE ROW LEVEL SECURITY;

--
-- Name: wall_post_reaction; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.wall_post_reaction ENABLE ROW LEVEL SECURITY;

--
-- Name: wall_post_report; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.wall_post_report ENABLE ROW LEVEL SECURITY;

--
-- Name: wall_post_tag; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.wall_post_tag ENABLE ROW LEVEL SECURITY;

--
-- Name: messages conversation_member_can_receive_broadcast; Type: POLICY; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE POLICY conversation_member_can_receive_broadcast ON realtime.messages FOR SELECT TO authenticated USING (((extension = 'broadcast'::text) AND public.fn_can_receive_conversation_topic(( SELECT realtime.topic() AS topic), ( SELECT auth.uid() AS uid))));


--
-- Name: messages; Type: ROW SECURITY; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE realtime.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_analytics; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.buckets_analytics ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_vectors; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.buckets_vectors ENABLE ROW LEVEL SECURITY;

--
-- Name: objects lobby_avatar: captain can delete; Type: POLICY; Schema: storage; Owner: supabase_storage_admin
--

CREATE POLICY "lobby_avatar: captain can delete" ON storage.objects FOR DELETE TO authenticated USING (((bucket_id = 'lobby_avatar'::text) AND (EXISTS ( SELECT 1
   FROM public.lobby l
  WHERE ((l.id = (split_part(l.name, '.'::text, 1))::uuid) AND (l.captain_id = auth.uid()))))));


--
-- Name: objects lobby_avatar: captain can replace; Type: POLICY; Schema: storage; Owner: supabase_storage_admin
--

CREATE POLICY "lobby_avatar: captain can replace" ON storage.objects FOR UPDATE TO authenticated USING (((bucket_id = 'lobby_avatar'::text) AND (EXISTS ( SELECT 1
   FROM public.lobby l
  WHERE ((l.id = (split_part(l.name, '.'::text, 1))::uuid) AND (l.captain_id = auth.uid())))))) WITH CHECK (((bucket_id = 'lobby_avatar'::text) AND (EXISTS ( SELECT 1
   FROM public.lobby l
  WHERE ((l.id = (split_part(l.name, '.'::text, 1))::uuid) AND (l.captain_id = auth.uid()))))));


--
-- Name: objects lobby_avatar: captain can upload; Type: POLICY; Schema: storage; Owner: supabase_storage_admin
--

CREATE POLICY "lobby_avatar: captain can upload" ON storage.objects FOR INSERT TO authenticated WITH CHECK (((bucket_id = 'lobby_avatar'::text) AND (EXISTS ( SELECT 1
   FROM public.lobby l
  WHERE ((l.id = (split_part(l.name, '.'::text, 1))::uuid) AND (l.captain_id = auth.uid()))))));


--
-- Name: objects lobby_avatar: public read; Type: POLICY; Schema: storage; Owner: supabase_storage_admin
--

CREATE POLICY "lobby_avatar: public read" ON storage.objects FOR SELECT USING ((bucket_id = 'lobby_avatar'::text));


--
-- Name: migrations; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: objects; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.s3_multipart_uploads ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads_parts; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.s3_multipart_uploads_parts ENABLE ROW LEVEL SECURITY;

--
-- Name: objects user_avatar: owner can delete; Type: POLICY; Schema: storage; Owner: supabase_storage_admin
--

CREATE POLICY "user_avatar: owner can delete" ON storage.objects FOR DELETE TO authenticated USING (((bucket_id = 'user_avatar'::text) AND (split_part(name, '.'::text, 1) = (auth.uid())::text)));


--
-- Name: objects user_avatar: owner can replace; Type: POLICY; Schema: storage; Owner: supabase_storage_admin
--

CREATE POLICY "user_avatar: owner can replace" ON storage.objects FOR UPDATE TO authenticated USING (((bucket_id = 'user_avatar'::text) AND (split_part(name, '.'::text, 1) = (auth.uid())::text))) WITH CHECK (((bucket_id = 'user_avatar'::text) AND (split_part(name, '.'::text, 1) = (auth.uid())::text)));


--
-- Name: objects user_avatar: owner can upload; Type: POLICY; Schema: storage; Owner: supabase_storage_admin
--

CREATE POLICY "user_avatar: owner can upload" ON storage.objects FOR INSERT TO authenticated WITH CHECK (((bucket_id = 'user_avatar'::text) AND (split_part(name, '.'::text, 1) = (auth.uid())::text)));


--
-- Name: objects user_avatar: public read; Type: POLICY; Schema: storage; Owner: supabase_storage_admin
--

CREATE POLICY "user_avatar: public read" ON storage.objects FOR SELECT USING ((bucket_id = 'user_avatar'::text));


--
-- Name: vector_indexes; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.vector_indexes ENABLE ROW LEVEL SECURITY;

--
-- Name: objects wall_post: owner can delete; Type: POLICY; Schema: storage; Owner: supabase_storage_admin
--

CREATE POLICY "wall_post: owner can delete" ON storage.objects FOR DELETE TO authenticated USING (((bucket_id = 'wall_post'::text) AND (split_part(name, '/'::text, 1) = (auth.uid())::text)));


--
-- Name: objects wall_post: owner can upload; Type: POLICY; Schema: storage; Owner: supabase_storage_admin
--

CREATE POLICY "wall_post: owner can upload" ON storage.objects FOR INSERT TO authenticated WITH CHECK (((bucket_id = 'wall_post'::text) AND (split_part(name, '/'::text, 1) = (auth.uid())::text)));


--
-- Name: objects wall_post_video: owner can delete; Type: POLICY; Schema: storage; Owner: supabase_storage_admin
--

CREATE POLICY "wall_post_video: owner can delete" ON storage.objects FOR DELETE TO authenticated USING (((bucket_id = 'wall_post_video'::text) AND (split_part(name, '/'::text, 1) = (auth.uid())::text)));


--
-- Name: objects wall_post_video: owner can upload; Type: POLICY; Schema: storage; Owner: supabase_storage_admin
--

CREATE POLICY "wall_post_video: owner can upload" ON storage.objects FOR INSERT TO authenticated WITH CHECK (((bucket_id = 'wall_post_video'::text) AND (split_part(name, '/'::text, 1) = (auth.uid())::text)));


--
-- Name: supabase_realtime; Type: PUBLICATION; Schema: -; Owner: postgres
--

CREATE PUBLICATION supabase_realtime WITH (publish = 'insert, update, delete, truncate');


ALTER PUBLICATION supabase_realtime OWNER TO postgres;

--
-- Name: supabase_realtime_messages_publication; Type: PUBLICATION; Schema: -; Owner: supabase_admin
--

CREATE PUBLICATION supabase_realtime_messages_publication WITH (publish = 'insert, update, delete, truncate');


ALTER PUBLICATION supabase_realtime_messages_publication OWNER TO supabase_admin;

--
-- Name: supabase_realtime_messages_publication messages; Type: PUBLICATION TABLE; Schema: realtime; Owner: supabase_admin
--

ALTER PUBLICATION supabase_realtime_messages_publication ADD TABLE ONLY realtime.messages;


--
-- Name: SCHEMA auth; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA auth TO anon;
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT USAGE ON SCHEMA auth TO service_role;
GRANT ALL ON SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON SCHEMA auth TO dashboard_user;
GRANT USAGE ON SCHEMA auth TO postgres;


--
-- Name: SCHEMA cron; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA cron TO postgres WITH GRANT OPTION;


--
-- Name: SCHEMA extensions; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA extensions TO anon;
GRANT USAGE ON SCHEMA extensions TO authenticated;
GRANT USAGE ON SCHEMA extensions TO service_role;
GRANT ALL ON SCHEMA extensions TO dashboard_user;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;


--
-- Name: SCHEMA net; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA net TO supabase_functions_admin;
GRANT USAGE ON SCHEMA net TO postgres;
GRANT USAGE ON SCHEMA net TO anon;
GRANT USAGE ON SCHEMA net TO authenticated;
GRANT USAGE ON SCHEMA net TO service_role;


--
-- Name: SCHEMA realtime; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA realtime TO postgres WITH GRANT OPTION;
GRANT USAGE ON SCHEMA realtime TO anon;
GRANT USAGE ON SCHEMA realtime TO authenticated;
GRANT USAGE ON SCHEMA realtime TO service_role;
GRANT ALL ON SCHEMA realtime TO supabase_realtime_admin;


--
-- Name: SCHEMA storage; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA storage TO postgres;
GRANT USAGE ON SCHEMA storage TO anon;
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT USAGE ON SCHEMA storage TO service_role;
GRANT ALL ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON SCHEMA storage TO dashboard_user;


--
-- Name: SCHEMA vault; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA vault TO postgres WITH GRANT OPTION;
GRANT USAGE ON SCHEMA vault TO service_role;


--
-- Name: FUNCTION gtrgm_in(cstring); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gtrgm_in(cstring) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_out(extensions.gtrgm); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gtrgm_out(extensions.gtrgm) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION email(); Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON FUNCTION auth.email() TO dashboard_user;
GRANT ALL ON FUNCTION auth.email() TO postgres;


--
-- Name: FUNCTION jwt(); Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON FUNCTION auth.jwt() TO postgres;
GRANT ALL ON FUNCTION auth.jwt() TO dashboard_user;


--
-- Name: FUNCTION role(); Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON FUNCTION auth.role() TO dashboard_user;
GRANT ALL ON FUNCTION auth.role() TO postgres;


--
-- Name: FUNCTION uid(); Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON FUNCTION auth.uid() TO dashboard_user;
GRANT ALL ON FUNCTION auth.uid() TO postgres;


--
-- Name: FUNCTION alter_job(job_id bigint, schedule text, command text, database text, username text, active boolean); Type: ACL; Schema: cron; Owner: supabase_admin
--

GRANT ALL ON FUNCTION cron.alter_job(job_id bigint, schedule text, command text, database text, username text, active boolean) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION job_cache_invalidate(); Type: ACL; Schema: cron; Owner: supabase_admin
--

GRANT ALL ON FUNCTION cron.job_cache_invalidate() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION schedule(schedule text, command text); Type: ACL; Schema: cron; Owner: supabase_admin
--

GRANT ALL ON FUNCTION cron.schedule(schedule text, command text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION schedule(job_name text, schedule text, command text); Type: ACL; Schema: cron; Owner: supabase_admin
--

GRANT ALL ON FUNCTION cron.schedule(job_name text, schedule text, command text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION schedule_in_database(job_name text, schedule text, command text, database text, username text, active boolean); Type: ACL; Schema: cron; Owner: supabase_admin
--

GRANT ALL ON FUNCTION cron.schedule_in_database(job_name text, schedule text, command text, database text, username text, active boolean) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION unschedule(job_id bigint); Type: ACL; Schema: cron; Owner: supabase_admin
--

GRANT ALL ON FUNCTION cron.unschedule(job_id bigint) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION unschedule(job_name text); Type: ACL; Schema: cron; Owner: supabase_admin
--

GRANT ALL ON FUNCTION cron.unschedule(job_name text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION armor(bytea); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.armor(bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.armor(bytea) TO dashboard_user;


--
-- Name: FUNCTION armor(bytea, text[], text[]); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.armor(bytea, text[], text[]) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.armor(bytea, text[], text[]) TO dashboard_user;


--
-- Name: FUNCTION crypt(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.crypt(text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.crypt(text, text) TO dashboard_user;


--
-- Name: FUNCTION dearmor(text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.dearmor(text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.dearmor(text) TO dashboard_user;


--
-- Name: FUNCTION decrypt(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.decrypt(bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.decrypt(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION decrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.decrypt_iv(bytea, bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.decrypt_iv(bytea, bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION digest(bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.digest(bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.digest(bytea, text) TO dashboard_user;


--
-- Name: FUNCTION digest(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.digest(text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.digest(text, text) TO dashboard_user;


--
-- Name: FUNCTION encrypt(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.encrypt(bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.encrypt(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION encrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.encrypt_iv(bytea, bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.encrypt_iv(bytea, bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION gen_random_bytes(integer); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gen_random_bytes(integer) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.gen_random_bytes(integer) TO dashboard_user;


--
-- Name: FUNCTION gen_random_uuid(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gen_random_uuid() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.gen_random_uuid() TO dashboard_user;


--
-- Name: FUNCTION gen_salt(text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gen_salt(text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.gen_salt(text) TO dashboard_user;


--
-- Name: FUNCTION gen_salt(text, integer); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gen_salt(text, integer) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.gen_salt(text, integer) TO dashboard_user;


--
-- Name: FUNCTION gin_extract_query_trgm(text, internal, smallint, internal, internal, internal, internal); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gin_extract_query_trgm(text, internal, smallint, internal, internal, internal, internal) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION gin_extract_value_trgm(text, internal); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gin_extract_value_trgm(text, internal) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION gin_trgm_consistent(internal, smallint, text, integer, internal, internal, internal, internal); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gin_trgm_consistent(internal, smallint, text, integer, internal, internal, internal, internal) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION gin_trgm_triconsistent(internal, smallint, text, integer, internal, internal, internal); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gin_trgm_triconsistent(internal, smallint, text, integer, internal, internal, internal) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION grant_pg_cron_access(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

REVOKE ALL ON FUNCTION extensions.grant_pg_cron_access() FROM supabase_admin;
GRANT ALL ON FUNCTION extensions.grant_pg_cron_access() TO supabase_admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.grant_pg_cron_access() TO dashboard_user;
GRANT ALL ON FUNCTION extensions.grant_pg_cron_access() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION grant_pg_graphql_access(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.grant_pg_graphql_access() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION grant_pg_net_access(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

REVOKE ALL ON FUNCTION extensions.grant_pg_net_access() FROM supabase_admin;
GRANT ALL ON FUNCTION extensions.grant_pg_net_access() TO supabase_admin WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.grant_pg_net_access() TO dashboard_user;
GRANT ALL ON FUNCTION extensions.grant_pg_net_access() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_compress(internal); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gtrgm_compress(internal) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_consistent(internal, text, smallint, oid, internal); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gtrgm_consistent(internal, text, smallint, oid, internal) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_decompress(internal); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gtrgm_decompress(internal) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_distance(internal, text, smallint, oid, internal); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gtrgm_distance(internal, text, smallint, oid, internal) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_options(internal); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gtrgm_options(internal) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_penalty(internal, internal, internal); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gtrgm_penalty(internal, internal, internal) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_picksplit(internal, internal); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gtrgm_picksplit(internal, internal) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_same(extensions.gtrgm, extensions.gtrgm, internal); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gtrgm_same(extensions.gtrgm, extensions.gtrgm, internal) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION gtrgm_union(internal, internal); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.gtrgm_union(internal, internal) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION hmac(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.hmac(bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.hmac(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION hmac(text, text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.hmac(text, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.hmac(text, text, text) TO dashboard_user;


--
-- Name: FUNCTION json_matches_schema(schema json, instance json); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.json_matches_schema(schema json, instance json) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION jsonb_matches_schema(schema json, instance jsonb); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.jsonb_matches_schema(schema json, instance jsonb) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION jsonschema_is_valid(schema json); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.jsonschema_is_valid(schema json) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION jsonschema_validation_errors(schema json, instance json); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.jsonschema_validation_errors(schema json, instance json) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION nanoid(size integer, alphabet text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.nanoid(size integer, alphabet text) TO authenticated;
GRANT ALL ON FUNCTION extensions.nanoid(size integer, alphabet text) TO anon;
GRANT ALL ON FUNCTION extensions.nanoid(size integer, alphabet text) TO service_role;


--
-- Name: FUNCTION pg_stat_statements(showtext boolean, OUT userid oid, OUT dbid oid, OUT toplevel boolean, OUT queryid bigint, OUT query text, OUT plans bigint, OUT total_plan_time double precision, OUT min_plan_time double precision, OUT max_plan_time double precision, OUT mean_plan_time double precision, OUT stddev_plan_time double precision, OUT calls bigint, OUT total_exec_time double precision, OUT min_exec_time double precision, OUT max_exec_time double precision, OUT mean_exec_time double precision, OUT stddev_exec_time double precision, OUT rows bigint, OUT shared_blks_hit bigint, OUT shared_blks_read bigint, OUT shared_blks_dirtied bigint, OUT shared_blks_written bigint, OUT local_blks_hit bigint, OUT local_blks_read bigint, OUT local_blks_dirtied bigint, OUT local_blks_written bigint, OUT temp_blks_read bigint, OUT temp_blks_written bigint, OUT shared_blk_read_time double precision, OUT shared_blk_write_time double precision, OUT local_blk_read_time double precision, OUT local_blk_write_time double precision, OUT temp_blk_read_time double precision, OUT temp_blk_write_time double precision, OUT wal_records bigint, OUT wal_fpi bigint, OUT wal_bytes numeric, OUT jit_functions bigint, OUT jit_generation_time double precision, OUT jit_inlining_count bigint, OUT jit_inlining_time double precision, OUT jit_optimization_count bigint, OUT jit_optimization_time double precision, OUT jit_emission_count bigint, OUT jit_emission_time double precision, OUT jit_deform_count bigint, OUT jit_deform_time double precision, OUT stats_since timestamp with time zone, OUT minmax_stats_since timestamp with time zone); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pg_stat_statements(showtext boolean, OUT userid oid, OUT dbid oid, OUT toplevel boolean, OUT queryid bigint, OUT query text, OUT plans bigint, OUT total_plan_time double precision, OUT min_plan_time double precision, OUT max_plan_time double precision, OUT mean_plan_time double precision, OUT stddev_plan_time double precision, OUT calls bigint, OUT total_exec_time double precision, OUT min_exec_time double precision, OUT max_exec_time double precision, OUT mean_exec_time double precision, OUT stddev_exec_time double precision, OUT rows bigint, OUT shared_blks_hit bigint, OUT shared_blks_read bigint, OUT shared_blks_dirtied bigint, OUT shared_blks_written bigint, OUT local_blks_hit bigint, OUT local_blks_read bigint, OUT local_blks_dirtied bigint, OUT local_blks_written bigint, OUT temp_blks_read bigint, OUT temp_blks_written bigint, OUT shared_blk_read_time double precision, OUT shared_blk_write_time double precision, OUT local_blk_read_time double precision, OUT local_blk_write_time double precision, OUT temp_blk_read_time double precision, OUT temp_blk_write_time double precision, OUT wal_records bigint, OUT wal_fpi bigint, OUT wal_bytes numeric, OUT jit_functions bigint, OUT jit_generation_time double precision, OUT jit_inlining_count bigint, OUT jit_inlining_time double precision, OUT jit_optimization_count bigint, OUT jit_optimization_time double precision, OUT jit_emission_count bigint, OUT jit_emission_time double precision, OUT jit_deform_count bigint, OUT jit_deform_time double precision, OUT stats_since timestamp with time zone, OUT minmax_stats_since timestamp with time zone) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pg_stat_statements_info(OUT dealloc bigint, OUT stats_reset timestamp with time zone); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pg_stat_statements_info(OUT dealloc bigint, OUT stats_reset timestamp with time zone) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pg_stat_statements_info(OUT dealloc bigint, OUT stats_reset timestamp with time zone) TO dashboard_user;


--
-- Name: FUNCTION pgp_armor_headers(text, OUT key text, OUT value text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_armor_headers(text, OUT key text, OUT value text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_armor_headers(text, OUT key text, OUT value text) TO dashboard_user;


--
-- Name: FUNCTION pgp_key_id(bytea); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_key_id(bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_key_id(bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgrst_ddl_watch(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgrst_ddl_watch() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgrst_drop_watch(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.pgrst_drop_watch() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION set_graphql_placeholder(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.set_graphql_placeholder() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION set_limit(real); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.set_limit(real) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION show_limit(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.show_limit() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION show_trgm(text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.show_trgm(text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION similarity(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.similarity(text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION similarity_dist(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.similarity_dist(text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION similarity_op(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.similarity_op(text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION strict_word_similarity(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.strict_word_similarity(text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION strict_word_similarity_commutator_op(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.strict_word_similarity_commutator_op(text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION strict_word_similarity_dist_commutator_op(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.strict_word_similarity_dist_commutator_op(text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION strict_word_similarity_dist_op(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.strict_word_similarity_dist_op(text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION strict_word_similarity_op(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.strict_word_similarity_op(text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION unaccent(text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.unaccent(text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION unaccent(regdictionary, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.unaccent(regdictionary, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION unaccent_init(internal); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.unaccent_init(internal) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION unaccent_lexize(internal, internal, internal, internal); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.unaccent_lexize(internal, internal, internal, internal) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION uuid_generate_v1(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v1() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_generate_v1() TO dashboard_user;


--
-- Name: FUNCTION uuid_generate_v1mc(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v1mc() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_generate_v1mc() TO dashboard_user;


--
-- Name: FUNCTION uuid_generate_v3(namespace uuid, name text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v3(namespace uuid, name text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_generate_v3(namespace uuid, name text) TO dashboard_user;


--
-- Name: FUNCTION uuid_generate_v4(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v4() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_generate_v4() TO dashboard_user;


--
-- Name: FUNCTION uuid_generate_v5(namespace uuid, name text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v5(namespace uuid, name text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_generate_v5(namespace uuid, name text) TO dashboard_user;


--
-- Name: FUNCTION uuid_nil(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_nil() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_nil() TO dashboard_user;


--
-- Name: FUNCTION uuid_ns_dns(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_ns_dns() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_ns_dns() TO dashboard_user;


--
-- Name: FUNCTION uuid_ns_oid(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_ns_oid() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_ns_oid() TO dashboard_user;


--
-- Name: FUNCTION uuid_ns_url(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_ns_url() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_ns_url() TO dashboard_user;


--
-- Name: FUNCTION uuid_ns_x500(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.uuid_ns_x500() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_ns_x500() TO dashboard_user;


--
-- Name: FUNCTION word_similarity(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.word_similarity(text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION word_similarity_commutator_op(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.word_similarity_commutator_op(text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION word_similarity_dist_commutator_op(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.word_similarity_dist_commutator_op(text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION word_similarity_dist_op(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.word_similarity_dist_op(text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION word_similarity_op(text, text); Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT ALL ON FUNCTION extensions.word_similarity_op(text, text) TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION graphql("operationName" text, query text, variables jsonb, extensions jsonb); Type: ACL; Schema: graphql_public; Owner: supabase_admin
--

GRANT ALL ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO postgres;
GRANT ALL ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO anon;
GRANT ALL ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO authenticated;
GRANT ALL ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO service_role;


--
-- Name: FUNCTION http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer); Type: ACL; Schema: net; Owner: supabase_admin
--

REVOKE ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
GRANT ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin;
GRANT ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO postgres;
GRANT ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO anon;
GRANT ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO authenticated;
GRANT ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO service_role;


--
-- Name: FUNCTION http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer); Type: ACL; Schema: net; Owner: supabase_admin
--

REVOKE ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
GRANT ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin;
GRANT ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO postgres;
GRANT ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO anon;
GRANT ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO authenticated;
GRANT ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO service_role;


--
-- Name: FUNCTION get_auth(p_usename text); Type: ACL; Schema: pgbouncer; Owner: supabase_admin
--

REVOKE ALL ON FUNCTION pgbouncer.get_auth(p_usename text) FROM PUBLIC;
GRANT ALL ON FUNCTION pgbouncer.get_auth(p_usename text) TO pgbouncer;
GRANT ALL ON FUNCTION pgbouncer.get_auth(p_usename text) TO postgres;


--
-- Name: FUNCTION crypto_aead_det_decrypt(message bytea, additional bytea, key_uuid uuid, nonce bytea); Type: ACL; Schema: pgsodium; Owner: pgsodium_keymaker
--

GRANT ALL ON FUNCTION pgsodium.crypto_aead_det_decrypt(message bytea, additional bytea, key_uuid uuid, nonce bytea) TO service_role;


--
-- Name: FUNCTION crypto_aead_det_encrypt(message bytea, additional bytea, key_uuid uuid, nonce bytea); Type: ACL; Schema: pgsodium; Owner: pgsodium_keymaker
--

GRANT ALL ON FUNCTION pgsodium.crypto_aead_det_encrypt(message bytea, additional bytea, key_uuid uuid, nonce bytea) TO service_role;


--
-- Name: FUNCTION crypto_aead_det_keygen(); Type: ACL; Schema: pgsodium; Owner: supabase_admin
--

GRANT ALL ON FUNCTION pgsodium.crypto_aead_det_keygen() TO service_role;


--
-- Name: FUNCTION _achievement_current_value(p_user_id uuid, p_criteria jsonb, p_eligible_from timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public._achievement_current_value(p_user_id uuid, p_criteria jsonb, p_eligible_from timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public._achievement_current_value(p_user_id uuid, p_criteria jsonb, p_eligible_from timestamp with time zone) TO service_role;


--
-- Name: FUNCTION _achievement_level_floor(p_level integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._achievement_level_floor(p_level integer) TO anon;
GRANT ALL ON FUNCTION public._achievement_level_floor(p_level integer) TO authenticated;
GRANT ALL ON FUNCTION public._achievement_level_floor(p_level integer) TO service_role;


--
-- Name: FUNCTION _achievement_level_for_xp(p_xp bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._achievement_level_for_xp(p_xp bigint) TO anon;
GRANT ALL ON FUNCTION public._achievement_level_for_xp(p_xp bigint) TO authenticated;
GRANT ALL ON FUNCTION public._achievement_level_for_xp(p_xp bigint) TO service_role;


--
-- Name: FUNCTION _achievement_period_key(p_criteria jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._achievement_period_key(p_criteria jsonb) TO anon;
GRANT ALL ON FUNCTION public._achievement_period_key(p_criteria jsonb) TO authenticated;
GRANT ALL ON FUNCTION public._achievement_period_key(p_criteria jsonb) TO service_role;


--
-- Name: TABLE activity_health_metrics; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.activity_health_metrics TO anon;
GRANT ALL ON TABLE public.activity_health_metrics TO authenticated;
GRANT ALL ON TABLE public.activity_health_metrics TO service_role;


--
-- Name: FUNCTION _activity_metric_value(m public.activity_health_metrics, p_metric text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._activity_metric_value(m public.activity_health_metrics, p_metric text) TO anon;
GRANT ALL ON FUNCTION public._activity_metric_value(m public.activity_health_metrics, p_metric text) TO authenticated;
GRANT ALL ON FUNCTION public._activity_metric_value(m public.activity_health_metrics, p_metric text) TO service_role;


--
-- Name: FUNCTION _fn_social_event_on_post(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._fn_social_event_on_post() TO anon;
GRANT ALL ON FUNCTION public._fn_social_event_on_post() TO authenticated;
GRANT ALL ON FUNCTION public._fn_social_event_on_post() TO service_role;


--
-- Name: FUNCTION _fn_social_event_on_reaction(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._fn_social_event_on_reaction() TO anon;
GRANT ALL ON FUNCTION public._fn_social_event_on_reaction() TO authenticated;
GRANT ALL ON FUNCTION public._fn_social_event_on_reaction() TO service_role;


--
-- Name: FUNCTION _vitality_daily_load_series(p_user_id uuid, p_from date, p_to date); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public._vitality_daily_load_series(p_user_id uuid, p_from date, p_to date) FROM PUBLIC;
GRANT ALL ON FUNCTION public._vitality_daily_load_series(p_user_id uuid, p_from date, p_to date) TO service_role;


--
-- Name: FUNCTION _vitality_ewma(p_user_id uuid, p_as_of date, p_window_days integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public._vitality_ewma(p_user_id uuid, p_as_of date, p_window_days integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public._vitality_ewma(p_user_id uuid, p_as_of date, p_window_days integer) TO service_role;


--
-- Name: FUNCTION _vitality_scale(p_value real, p_breaks real[], p_scores real[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._vitality_scale(p_value real, p_breaks real[], p_scores real[]) TO anon;
GRANT ALL ON FUNCTION public._vitality_scale(p_value real, p_breaks real[], p_scores real[]) TO authenticated;
GRANT ALL ON FUNCTION public._vitality_scale(p_value real, p_breaks real[], p_scores real[]) TO service_role;


--
-- Name: FUNCTION accept_referee_booking(p_booking_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.accept_referee_booking(p_booking_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.accept_referee_booking(p_booking_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.accept_referee_booking(p_booking_id uuid) TO service_role;


--
-- Name: FUNCTION achievement_progress(p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.achievement_progress(p_user_id uuid) TO anon;
GRANT ALL ON FUNCTION public.achievement_progress(p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.achievement_progress(p_user_id uuid) TO service_role;


--
-- Name: FUNCTION activity_confirmation_status(p_activity_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.activity_confirmation_status(p_activity_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.activity_confirmation_status(p_activity_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.activity_confirmation_status(p_activity_id uuid) TO service_role;


--
-- Name: FUNCTION activity_health_data(p_sport_id bigint); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.activity_health_data(p_sport_id bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION public.activity_health_data(p_sport_id bigint) TO authenticated;
GRANT ALL ON FUNCTION public.activity_health_data(p_sport_id bigint) TO service_role;


--
-- Name: FUNCTION activity_is_confirmed(p_activity_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.activity_is_confirmed(p_activity_id uuid) TO anon;
GRANT ALL ON FUNCTION public.activity_is_confirmed(p_activity_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.activity_is_confirmed(p_activity_id uuid) TO service_role;


--
-- Name: FUNCTION add_payment_info(p_bank_id text, p_bank_display_name text, p_value text, p_account_name text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.add_payment_info(p_bank_id text, p_bank_display_name text, p_value text, p_account_name text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.add_payment_info(p_bank_id text, p_bank_display_name text, p_value text, p_account_name text) TO authenticated;
GRANT ALL ON FUNCTION public.add_payment_info(p_bank_id text, p_bank_display_name text, p_value text, p_account_name text) TO service_role;


--
-- Name: FUNCTION block_user(p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.block_user(p_user_id uuid) TO anon;
GRANT ALL ON FUNCTION public.block_user(p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.block_user(p_user_id uuid) TO service_role;


--
-- Name: FUNCTION calculate_profile_compat(p_user_id uuid, p_target_id uuid, p_sport_id bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.calculate_profile_compat(p_user_id uuid, p_target_id uuid, p_sport_id bigint) TO anon;
GRANT ALL ON FUNCTION public.calculate_profile_compat(p_user_id uuid, p_target_id uuid, p_sport_id bigint) TO authenticated;
GRANT ALL ON FUNCTION public.calculate_profile_compat(p_user_id uuid, p_target_id uuid, p_sport_id bigint) TO service_role;


--
-- Name: FUNCTION calculate_profile_compat_score(p_user_id uuid, p_target_id uuid, p_sport_id bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.calculate_profile_compat_score(p_user_id uuid, p_target_id uuid, p_sport_id bigint) TO anon;
GRANT ALL ON FUNCTION public.calculate_profile_compat_score(p_user_id uuid, p_target_id uuid, p_sport_id bigint) TO authenticated;
GRANT ALL ON FUNCTION public.calculate_profile_compat_score(p_user_id uuid, p_target_id uuid, p_sport_id bigint) TO service_role;


--
-- Name: FUNCTION calculate_timeslot_compat_score(source jsonb, target jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.calculate_timeslot_compat_score(source jsonb, target jsonb) TO anon;
GRANT ALL ON FUNCTION public.calculate_timeslot_compat_score(source jsonb, target jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.calculate_timeslot_compat_score(source jsonb, target jsonb) TO service_role;


--
-- Name: FUNCTION can_write_conversation(p_conversation_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.can_write_conversation(p_conversation_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.can_write_conversation(p_conversation_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.can_write_conversation(p_conversation_id uuid) TO service_role;


--
-- Name: FUNCTION cancel_challenge(p_challenge_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.cancel_challenge(p_challenge_id uuid) TO anon;
GRANT ALL ON FUNCTION public.cancel_challenge(p_challenge_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.cancel_challenge(p_challenge_id uuid) TO service_role;


--
-- Name: FUNCTION cancel_course_activity(p_activity_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.cancel_course_activity(p_activity_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.cancel_course_activity(p_activity_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.cancel_course_activity(p_activity_id uuid) TO service_role;


--
-- Name: FUNCTION cancel_freeplay_activity(p_activity_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.cancel_freeplay_activity(p_activity_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.cancel_freeplay_activity(p_activity_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.cancel_freeplay_activity(p_activity_id uuid) TO service_role;


--
-- Name: FUNCTION cancel_freeplay_request(p_request_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.cancel_freeplay_request(p_request_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.cancel_freeplay_request(p_request_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.cancel_freeplay_request(p_request_id uuid) TO service_role;


--
-- Name: FUNCTION cancel_referee_booking(p_booking_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.cancel_referee_booking(p_booking_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.cancel_referee_booking(p_booking_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.cancel_referee_booking(p_booking_id uuid) TO service_role;


--
-- Name: FUNCTION complete_referee_booking(p_booking_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.complete_referee_booking(p_booking_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.complete_referee_booking(p_booking_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.complete_referee_booking(p_booking_id uuid) TO service_role;


--
-- Name: FUNCTION confirm_challenge_activity(p_activity_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.confirm_challenge_activity(p_activity_id uuid) TO anon;
GRANT ALL ON FUNCTION public.confirm_challenge_activity(p_activity_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.confirm_challenge_activity(p_activity_id uuid) TO service_role;


--
-- Name: FUNCTION conversation_data(p_conversation_id uuid, p_since timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.conversation_data(p_conversation_id uuid, p_since timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.conversation_data(p_conversation_id uuid, p_since timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.conversation_data(p_conversation_id uuid, p_since timestamp with time zone) TO service_role;


--
-- Name: FUNCTION course_activity_conflicts(p_professional_id uuid, p_start timestamp with time zone, p_end timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.course_activity_conflicts(p_professional_id uuid, p_start timestamp with time zone, p_end timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.course_activity_conflicts(p_professional_id uuid, p_start timestamp with time zone, p_end timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.course_activity_conflicts(p_professional_id uuid, p_start timestamp with time zone, p_end timestamp with time zone) TO service_role;


--
-- Name: FUNCTION course_detail_data(p_course_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.course_detail_data(p_course_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.course_detail_data(p_course_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.course_detail_data(p_course_id uuid) TO service_role;


--
-- Name: FUNCTION create_ancillary_payment_request(p_activity_id uuid, p_total_amount numeric, p_note text, p_tagged_users uuid[]); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.create_ancillary_payment_request(p_activity_id uuid, p_total_amount numeric, p_note text, p_tagged_users uuid[]) FROM PUBLIC;
GRANT ALL ON FUNCTION public.create_ancillary_payment_request(p_activity_id uuid, p_total_amount numeric, p_note text, p_tagged_users uuid[]) TO authenticated;
GRANT ALL ON FUNCTION public.create_ancillary_payment_request(p_activity_id uuid, p_total_amount numeric, p_note text, p_tagged_users uuid[]) TO service_role;


--
-- Name: FUNCTION create_freeplay_activity(p_sport_id bigint, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.create_freeplay_activity(p_sport_id bigint, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.create_freeplay_activity(p_sport_id bigint, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid) TO anon;
GRANT ALL ON FUNCTION public.create_freeplay_activity(p_sport_id bigint, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.create_freeplay_activity(p_sport_id bigint, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid) TO service_role;


--
-- Name: FUNCTION create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid) TO anon;
GRANT ALL ON FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid) TO service_role;


--
-- Name: FUNCTION create_location(p_name text, p_street_number text, p_street_name text, p_district text, p_city text, p_city_cluster bigint); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.create_location(p_name text, p_street_number text, p_street_name text, p_district text, p_city text, p_city_cluster bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION public.create_location(p_name text, p_street_number text, p_street_name text, p_district text, p_city text, p_city_cluster bigint) TO anon;
GRANT ALL ON FUNCTION public.create_location(p_name text, p_street_number text, p_street_name text, p_district text, p_city text, p_city_cluster bigint) TO authenticated;
GRANT ALL ON FUNCTION public.create_location(p_name text, p_street_number text, p_street_name text, p_district text, p_city text, p_city_cluster bigint) TO service_role;


--
-- Name: FUNCTION create_message_poll(p_conversation_id uuid, p_question text, p_options text[]); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.create_message_poll(p_conversation_id uuid, p_question text, p_options text[]) FROM PUBLIC;
GRANT ALL ON FUNCTION public.create_message_poll(p_conversation_id uuid, p_question text, p_options text[]) TO authenticated;
GRANT ALL ON FUNCTION public.create_message_poll(p_conversation_id uuid, p_question text, p_options text[]) TO service_role;


--
-- Name: FUNCTION create_wall_post(p_activity_id uuid, p_media jsonb, p_caption text, p_ttl_days smallint, p_tagged_users uuid[]); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.create_wall_post(p_activity_id uuid, p_media jsonb, p_caption text, p_ttl_days smallint, p_tagged_users uuid[]) FROM PUBLIC;
GRANT ALL ON FUNCTION public.create_wall_post(p_activity_id uuid, p_media jsonb, p_caption text, p_ttl_days smallint, p_tagged_users uuid[]) TO authenticated;
GRANT ALL ON FUNCTION public.create_wall_post(p_activity_id uuid, p_media jsonb, p_caption text, p_ttl_days smallint, p_tagged_users uuid[]) TO service_role;


--
-- Name: FUNCTION delete_payment_info(p_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.delete_payment_info(p_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.delete_payment_info(p_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.delete_payment_info(p_id uuid) TO service_role;


--
-- Name: FUNCTION delete_wall_post(p_post_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.delete_wall_post(p_post_id uuid) TO anon;
GRANT ALL ON FUNCTION public.delete_wall_post(p_post_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.delete_wall_post(p_post_id uuid) TO service_role;


--
-- Name: FUNCTION edit_freeplay_listing(p_activity_id uuid, p_capacity integer, p_description text, p_recommended_skills text[], p_location_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.edit_freeplay_listing(p_activity_id uuid, p_capacity integer, p_description text, p_recommended_skills text[], p_location_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.edit_freeplay_listing(p_activity_id uuid, p_capacity integer, p_description text, p_recommended_skills text[], p_location_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.edit_freeplay_listing(p_activity_id uuid, p_capacity integer, p_description text, p_recommended_skills text[], p_location_id uuid) TO service_role;


--
-- Name: FUNCTION end_course(p_course_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.end_course(p_course_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.end_course(p_course_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.end_course(p_course_id uuid) TO service_role;


--
-- Name: FUNCTION evaluate_achievements(p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.evaluate_achievements(p_user_id uuid) TO anon;
GRANT ALL ON FUNCTION public.evaluate_achievements(p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.evaluate_achievements(p_user_id uuid) TO service_role;


--
-- Name: FUNCTION evaluate_vitality_score(p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.evaluate_vitality_score(p_user_id uuid) TO anon;
GRANT ALL ON FUNCTION public.evaluate_vitality_score(p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.evaluate_vitality_score(p_user_id uuid) TO service_role;


--
-- Name: FUNCTION expire_past_activities(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.expire_past_activities() TO anon;
GRANT ALL ON FUNCTION public.expire_past_activities() TO authenticated;
GRANT ALL ON FUNCTION public.expire_past_activities() TO service_role;


--
-- Name: FUNCTION find_course_with_coach(p_professional_id uuid, p_sport_id bigint); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.find_course_with_coach(p_professional_id uuid, p_sport_id bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION public.find_course_with_coach(p_professional_id uuid, p_sport_id bigint) TO authenticated;
GRANT ALL ON FUNCTION public.find_course_with_coach(p_professional_id uuid, p_sport_id bigint) TO service_role;


--
-- Name: FUNCTION fn_activity_attachment_role_check(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_activity_attachment_role_check() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_activity_attachment_role_check() TO service_role;


--
-- Name: FUNCTION fn_apply_match_rating(p_match_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_apply_match_rating(p_match_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_apply_match_rating(p_match_id uuid) TO service_role;


--
-- Name: FUNCTION fn_broadcast_message(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_broadcast_message() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_broadcast_message() TO service_role;


--
-- Name: FUNCTION fn_bump_series_frontier(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_bump_series_frontier() TO anon;
GRANT ALL ON FUNCTION public.fn_bump_series_frontier() TO authenticated;
GRANT ALL ON FUNCTION public.fn_bump_series_frontier() TO service_role;


--
-- Name: FUNCTION fn_can_access_course_activity(p_activity_id uuid, p_uid uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_can_access_course_activity(p_activity_id uuid, p_uid uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_can_access_course_activity(p_activity_id uuid, p_uid uuid) TO authenticated;
GRANT ALL ON FUNCTION public.fn_can_access_course_activity(p_activity_id uuid, p_uid uuid) TO service_role;


--
-- Name: FUNCTION fn_can_receive_conversation_topic(p_topic text, p_uid uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_can_receive_conversation_topic(p_topic text, p_uid uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_can_receive_conversation_topic(p_topic text, p_uid uuid) TO authenticated;
GRANT ALL ON FUNCTION public.fn_can_receive_conversation_topic(p_topic text, p_uid uuid) TO service_role;


--
-- Name: FUNCTION fn_can_see_message(p_conversation_id uuid, p_created_at timestamp with time zone, p_uid uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_can_see_message(p_conversation_id uuid, p_created_at timestamp with time zone, p_uid uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_can_see_message(p_conversation_id uuid, p_created_at timestamp with time zone, p_uid uuid) TO service_role;


--
-- Name: FUNCTION fn_can_see_wall_post(p_post_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_can_see_wall_post(p_post_id uuid) TO anon;
GRANT ALL ON FUNCTION public.fn_can_see_wall_post(p_post_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.fn_can_see_wall_post(p_post_id uuid) TO service_role;


--
-- Name: FUNCTION fn_can_write_conversation(p_conversation_id uuid, p_uid uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_can_write_conversation(p_conversation_id uuid, p_uid uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_can_write_conversation(p_conversation_id uuid, p_uid uuid) TO service_role;


--
-- Name: TABLE notification_outbox; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.notification_outbox TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.notification_outbox TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.notification_outbox TO service_role;


--
-- Name: FUNCTION fn_claim_outbox(p_limit integer, p_max_attempts integer, p_stale text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_claim_outbox(p_limit integer, p_max_attempts integer, p_stale text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_claim_outbox(p_limit integer, p_max_attempts integer, p_stale text) TO service_role;


--
-- Name: FUNCTION fn_clear_read_notifications(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_clear_read_notifications() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_clear_read_notifications() TO anon;
GRANT ALL ON FUNCTION public.fn_clear_read_notifications() TO authenticated;
GRANT ALL ON FUNCTION public.fn_clear_read_notifications() TO service_role;


--
-- Name: FUNCTION fn_complete_referee_booking_on_match(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_complete_referee_booking_on_match() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_complete_referee_booking_on_match() TO service_role;


--
-- Name: FUNCTION fn_course_add_member(p_course_id uuid, p_user_id uuid, p_status public.course_member_status); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_course_add_member(p_course_id uuid, p_user_id uuid, p_status public.course_member_status) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_course_add_member(p_course_id uuid, p_user_id uuid, p_status public.course_member_status) TO service_role;


--
-- Name: FUNCTION fn_course_held_sessions(p_course_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_course_held_sessions(p_course_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_course_held_sessions(p_course_id uuid) TO service_role;


--
-- Name: FUNCTION fn_course_member_denormalise(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_course_member_denormalise() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_course_member_denormalise() TO service_role;


--
-- Name: FUNCTION fn_course_prompt_if_no_students(p_course_id uuid, p_was_enrolled boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_course_prompt_if_no_students(p_course_id uuid, p_was_enrolled boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_course_prompt_if_no_students(p_course_id uuid, p_was_enrolled boolean) TO service_role;


--
-- Name: FUNCTION fn_course_review_rollup(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_course_review_rollup() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_course_review_rollup() TO service_role;


--
-- Name: FUNCTION fn_course_system_message(p_course_id uuid, p_code text, p_payload jsonb); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_course_system_message(p_course_id uuid, p_code text, p_payload jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_course_system_message(p_course_id uuid, p_code text, p_payload jsonb) TO service_role;


--
-- Name: FUNCTION fn_cron_tick(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_cron_tick() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_cron_tick() TO service_role;


--
-- Name: FUNCTION fn_delete_notification(p_id bigint); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_delete_notification(p_id bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_delete_notification(p_id bigint) TO anon;
GRANT ALL ON FUNCTION public.fn_delete_notification(p_id bigint) TO authenticated;
GRANT ALL ON FUNCTION public.fn_delete_notification(p_id bigint) TO service_role;


--
-- Name: FUNCTION fn_emit_activity_confirmed(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_emit_activity_confirmed() TO anon;
GRANT ALL ON FUNCTION public.fn_emit_activity_confirmed() TO authenticated;
GRANT ALL ON FUNCTION public.fn_emit_activity_confirmed() TO service_role;


--
-- Name: FUNCTION fn_emit_activity_scheduled(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_emit_activity_scheduled() TO anon;
GRANT ALL ON FUNCTION public.fn_emit_activity_scheduled() TO authenticated;
GRANT ALL ON FUNCTION public.fn_emit_activity_scheduled() TO service_role;


--
-- Name: FUNCTION fn_emit_lobby_join_request(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_emit_lobby_join_request() TO anon;
GRANT ALL ON FUNCTION public.fn_emit_lobby_join_request() TO authenticated;
GRANT ALL ON FUNCTION public.fn_emit_lobby_join_request() TO service_role;


--
-- Name: FUNCTION fn_emit_lobby_join_request_response(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_emit_lobby_join_request_response() TO anon;
GRANT ALL ON FUNCTION public.fn_emit_lobby_join_request_response() TO authenticated;
GRANT ALL ON FUNCTION public.fn_emit_lobby_join_request_response() TO service_role;


--
-- Name: FUNCTION fn_emit_member_kicked(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_emit_member_kicked() TO anon;
GRANT ALL ON FUNCTION public.fn_emit_member_kicked() TO authenticated;
GRANT ALL ON FUNCTION public.fn_emit_member_kicked() TO service_role;


--
-- Name: FUNCTION fn_enqueue_notification(p_kind public.notification_kind, p_recipients uuid[], p_title text, p_body text, p_data jsonb); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_enqueue_notification(p_kind public.notification_kind, p_recipients uuid[], p_title text, p_body text, p_data jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_enqueue_notification(p_kind public.notification_kind, p_recipients uuid[], p_title text, p_body text, p_data jsonb) TO service_role;


--
-- Name: FUNCTION fn_ensure_freeplay_conversation(p_request_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_ensure_freeplay_conversation(p_request_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_ensure_freeplay_conversation(p_request_id uuid) TO service_role;


--
-- Name: FUNCTION fn_fill_payment_request_recipient(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_fill_payment_request_recipient() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_fill_payment_request_recipient() TO service_role;


--
-- Name: FUNCTION fn_freeplay_block_cleanup(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_freeplay_block_cleanup() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_freeplay_block_cleanup() TO service_role;


--
-- Name: FUNCTION fn_freeplay_host_zalo(p_host_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_freeplay_host_zalo(p_host_id uuid) TO anon;
GRANT ALL ON FUNCTION public.fn_freeplay_host_zalo(p_host_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.fn_freeplay_host_zalo(p_host_id uuid) TO service_role;


--
-- Name: FUNCTION fn_guard_referee_booking_review(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_guard_referee_booking_review() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_guard_referee_booking_review() TO service_role;


--
-- Name: FUNCTION fn_invoke_send_push(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_invoke_send_push() TO anon;
GRANT ALL ON FUNCTION public.fn_invoke_send_push() TO authenticated;
GRANT ALL ON FUNCTION public.fn_invoke_send_push() TO service_role;


--
-- Name: FUNCTION fn_is_active_freeplay_host(p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_is_active_freeplay_host(p_user_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_is_active_freeplay_host(p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.fn_is_active_freeplay_host(p_user_id uuid) TO service_role;


--
-- Name: FUNCTION fn_is_blocked(p_a uuid, p_b uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_is_blocked(p_a uuid, p_b uuid) TO anon;
GRANT ALL ON FUNCTION public.fn_is_blocked(p_a uuid, p_b uuid) TO authenticated;
GRANT ALL ON FUNCTION public.fn_is_blocked(p_a uuid, p_b uuid) TO service_role;


--
-- Name: FUNCTION fn_is_conversation_member(p_conversation_id uuid, p_uid uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_is_conversation_member(p_conversation_id uuid, p_uid uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_is_conversation_member(p_conversation_id uuid, p_uid uuid) TO service_role;


--
-- Name: FUNCTION fn_is_course_coach(p_course_id uuid, p_uid uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_is_course_coach(p_course_id uuid, p_uid uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_is_course_coach(p_course_id uuid, p_uid uuid) TO service_role;


--
-- Name: FUNCTION fn_is_course_member(p_course_id uuid, p_uid uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_is_course_member(p_course_id uuid, p_uid uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_is_course_member(p_course_id uuid, p_uid uuid) TO service_role;


--
-- Name: FUNCTION fn_is_enrolled_course_member(p_course_id uuid, p_uid uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_is_enrolled_course_member(p_course_id uuid, p_uid uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_is_enrolled_course_member(p_course_id uuid, p_uid uuid) TO service_role;


--
-- Name: FUNCTION fn_is_linked_professional(p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_is_linked_professional(p_user_id uuid) TO anon;
GRANT ALL ON FUNCTION public.fn_is_linked_professional(p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.fn_is_linked_professional(p_user_id uuid) TO service_role;


--
-- Name: FUNCTION fn_lobby_playtime_keys(p_playtime jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_lobby_playtime_keys(p_playtime jsonb) TO anon;
GRANT ALL ON FUNCTION public.fn_lobby_playtime_keys(p_playtime jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.fn_lobby_playtime_keys(p_playtime jsonb) TO service_role;


--
-- Name: FUNCTION fn_lobby_recompute_rated_matches(p_lobby_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_lobby_recompute_rated_matches(p_lobby_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_lobby_recompute_rated_matches(p_lobby_id uuid) TO service_role;


--
-- Name: FUNCTION fn_lobby_recompute_stats(p_lobby_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_lobby_recompute_stats(p_lobby_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_lobby_recompute_stats(p_lobby_id uuid) TO service_role;


--
-- Name: FUNCTION fn_mark_all_notifications_read(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_mark_all_notifications_read() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_mark_all_notifications_read() TO anon;
GRANT ALL ON FUNCTION public.fn_mark_all_notifications_read() TO authenticated;
GRANT ALL ON FUNCTION public.fn_mark_all_notifications_read() TO service_role;


--
-- Name: FUNCTION fn_mark_notification_read(p_id bigint); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_mark_notification_read(p_id bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_mark_notification_read(p_id bigint) TO anon;
GRANT ALL ON FUNCTION public.fn_mark_notification_read(p_id bigint) TO authenticated;
GRANT ALL ON FUNCTION public.fn_mark_notification_read(p_id bigint) TO service_role;


--
-- Name: FUNCTION fn_notification_presentation(p_kind public.notification_kind, p_data jsonb, p_body text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_notification_presentation(p_kind public.notification_kind, p_data jsonb, p_body text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_notification_presentation(p_kind public.notification_kind, p_data jsonb, p_body text) TO service_role;


--
-- Name: FUNCTION fn_notify_lobby_invite(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_notify_lobby_invite() TO anon;
GRANT ALL ON FUNCTION public.fn_notify_lobby_invite() TO authenticated;
GRANT ALL ON FUNCTION public.fn_notify_lobby_invite() TO service_role;


--
-- Name: FUNCTION fn_notify_new_message(p_conversation_id uuid, p_message_id uuid, p_kind public.notification_kind, p_sender uuid, p_title text, p_body text, p_data jsonb); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_notify_new_message(p_conversation_id uuid, p_message_id uuid, p_kind public.notification_kind, p_sender uuid, p_title text, p_body text, p_data jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_notify_new_message(p_conversation_id uuid, p_message_id uuid, p_kind public.notification_kind, p_sender uuid, p_title text, p_body text, p_data jsonb) TO service_role;


--
-- Name: FUNCTION fn_notify_referee_booking_created(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_notify_referee_booking_created() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_notify_referee_booking_created() TO service_role;


--
-- Name: FUNCTION fn_notify_referee_booking_status_changed(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_notify_referee_booking_status_changed() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_notify_referee_booking_status_changed() TO service_role;


--
-- Name: FUNCTION fn_outbox_poke(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_outbox_poke() TO anon;
GRANT ALL ON FUNCTION public.fn_outbox_poke() TO authenticated;
GRANT ALL ON FUNCTION public.fn_outbox_poke() TO service_role;


--
-- Name: FUNCTION fn_playtime_to_dict(p_playtime jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_playtime_to_dict(p_playtime jsonb) TO anon;
GRANT ALL ON FUNCTION public.fn_playtime_to_dict(p_playtime jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.fn_playtime_to_dict(p_playtime jsonb) TO service_role;


--
-- Name: FUNCTION fn_poke_wall_gc(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_poke_wall_gc() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_poke_wall_gc() TO anon;
GRANT ALL ON FUNCTION public.fn_poke_wall_gc() TO service_role;


--
-- Name: FUNCTION fn_process_reminders(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_process_reminders() TO anon;
GRANT ALL ON FUNCTION public.fn_process_reminders() TO authenticated;
GRANT ALL ON FUNCTION public.fn_process_reminders() TO service_role;


--
-- Name: FUNCTION fn_referee_booking_role_check(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_referee_booking_role_check() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_referee_booking_role_check() TO service_role;


--
-- Name: FUNCTION fn_reject_pair_befriend(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_reject_pair_befriend() TO anon;
GRANT ALL ON FUNCTION public.fn_reject_pair_befriend() TO authenticated;
GRANT ALL ON FUNCTION public.fn_reject_pair_befriend() TO service_role;


--
-- Name: FUNCTION fn_seed_initial_elo(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_seed_initial_elo() TO anon;
GRANT ALL ON FUNCTION public.fn_seed_initial_elo() TO authenticated;
GRANT ALL ON FUNCTION public.fn_seed_initial_elo() TO service_role;


--
-- Name: FUNCTION fn_sport_name(p_sport_id bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_sport_name(p_sport_id bigint) TO anon;
GRANT ALL ON FUNCTION public.fn_sport_name(p_sport_id bigint) TO authenticated;
GRANT ALL ON FUNCTION public.fn_sport_name(p_sport_id bigint) TO service_role;


--
-- Name: FUNCTION fn_sweep_activity_payment_requests(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_sweep_activity_payment_requests() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_sweep_activity_payment_requests() TO service_role;


--
-- Name: FUNCTION fn_sweep_activity_thresholds(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_sweep_activity_thresholds() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_sweep_activity_thresholds() TO service_role;


--
-- Name: FUNCTION fn_sweep_challenges(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_sweep_challenges() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_sweep_challenges() TO service_role;


--
-- Name: FUNCTION fn_sweep_course_targets(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_sweep_course_targets() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_sweep_course_targets() TO service_role;


--
-- Name: FUNCTION fn_sweep_expired_wall_posts(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_sweep_expired_wall_posts() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_sweep_expired_wall_posts() TO anon;
GRANT ALL ON FUNCTION public.fn_sweep_expired_wall_posts() TO service_role;


--
-- Name: FUNCTION fn_sweep_freeplay(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_sweep_freeplay() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_sweep_freeplay() TO service_role;


--
-- Name: FUNCTION fn_sweep_recurring_activities(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_sweep_recurring_activities() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_sweep_recurring_activities() TO service_role;


--
-- Name: FUNCTION fn_touch_user_contact(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_touch_user_contact() TO anon;
GRANT ALL ON FUNCTION public.fn_touch_user_contact() TO authenticated;
GRANT ALL ON FUNCTION public.fn_touch_user_contact() TO service_role;


--
-- Name: FUNCTION fn_valid_wall_post_media(p_media jsonb); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_valid_wall_post_media(p_media jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_valid_wall_post_media(p_media jsonb) TO anon;
GRANT ALL ON FUNCTION public.fn_valid_wall_post_media(p_media jsonb) TO service_role;


--
-- Name: FUNCTION fn_validate_activity_feed_item_scope(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_validate_activity_feed_item_scope() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_validate_activity_feed_item_scope() TO service_role;


--
-- Name: FUNCTION fn_wall_cron_tick(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_wall_cron_tick() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_wall_cron_tick() TO anon;
GRANT ALL ON FUNCTION public.fn_wall_cron_tick() TO service_role;


--
-- Name: FUNCTION fn_wall_post_autohide(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_wall_post_autohide() TO anon;
GRANT ALL ON FUNCTION public.fn_wall_post_autohide() TO authenticated;
GRANT ALL ON FUNCTION public.fn_wall_post_autohide() TO service_role;


--
-- Name: FUNCTION fn_wall_post_media_gc_paths(p_media jsonb); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_wall_post_media_gc_paths(p_media jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_wall_post_media_gc_paths(p_media jsonb) TO anon;
GRANT ALL ON FUNCTION public.fn_wall_post_media_gc_paths(p_media jsonb) TO service_role;


--
-- Name: FUNCTION fn_wall_post_tag_guard(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_wall_post_tag_guard() TO anon;
GRANT ALL ON FUNCTION public.fn_wall_post_tag_guard() TO authenticated;
GRANT ALL ON FUNCTION public.fn_wall_post_tag_guard() TO service_role;


--
-- Name: FUNCTION freeplay_activity_detail_data(p_activity_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.freeplay_activity_detail_data(p_activity_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.freeplay_activity_detail_data(p_activity_id uuid) TO anon;
GRANT ALL ON FUNCTION public.freeplay_activity_detail_data(p_activity_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.freeplay_activity_detail_data(p_activity_id uuid) TO service_role;


--
-- Name: FUNCTION freeplay_activity_requests(p_activity_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.freeplay_activity_requests(p_activity_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.freeplay_activity_requests(p_activity_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.freeplay_activity_requests(p_activity_id uuid) TO service_role;


--
-- Name: FUNCTION freeplay_chat_counterpart_data(p_request_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.freeplay_chat_counterpart_data(p_request_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.freeplay_chat_counterpart_data(p_request_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.freeplay_chat_counterpart_data(p_request_id uuid) TO service_role;


--
-- Name: FUNCTION freeplay_conversation_id(p_request_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.freeplay_conversation_id(p_request_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.freeplay_conversation_id(p_request_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.freeplay_conversation_id(p_request_id uuid) TO service_role;


--
-- Name: FUNCTION freeplay_host_data(p_history boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.freeplay_host_data(p_history boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.freeplay_host_data(p_history boolean) TO authenticated;
GRANT ALL ON FUNCTION public.freeplay_host_data(p_history boolean) TO service_role;


--
-- Name: FUNCTION freeplay_host_management_data(p_history boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.freeplay_host_management_data(p_history boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.freeplay_host_management_data(p_history boolean) TO authenticated;
GRANT ALL ON FUNCTION public.freeplay_host_management_data(p_history boolean) TO service_role;


--
-- Name: FUNCTION freeplay_host_open_data(p_host_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.freeplay_host_open_data(p_host_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.freeplay_host_open_data(p_host_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.freeplay_host_open_data(p_host_id uuid) TO service_role;
GRANT ALL ON FUNCTION public.freeplay_host_open_data(p_host_id uuid) TO anon;


--
-- Name: FUNCTION freeplay_host_profile_data(p_host_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.freeplay_host_profile_data(p_host_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.freeplay_host_profile_data(p_host_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.freeplay_host_profile_data(p_host_id uuid) TO service_role;
GRANT ALL ON FUNCTION public.freeplay_host_profile_data(p_host_id uuid) TO anon;


--
-- Name: FUNCTION freeplay_my_data(p_history boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.freeplay_my_data(p_history boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.freeplay_my_data(p_history boolean) TO authenticated;
GRANT ALL ON FUNCTION public.freeplay_my_data(p_history boolean) TO service_role;


--
-- Name: FUNCTION freeplay_user_skill(p_user_id uuid, p_sport_id bigint); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.freeplay_user_skill(p_user_id uuid, p_sport_id bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION public.freeplay_user_skill(p_user_id uuid, p_sport_id bigint) TO service_role;


--
-- Name: FUNCTION friend_data(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.friend_data() TO anon;
GRANT ALL ON FUNCTION public.friend_data() TO authenticated;
GRANT ALL ON FUNCTION public.friend_data() TO service_role;


--
-- Name: FUNCTION generate_lobby_invite_link(p_lobby_id uuid, p_expires_in interval); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.generate_lobby_invite_link(p_lobby_id uuid, p_expires_in interval) TO anon;
GRANT ALL ON FUNCTION public.generate_lobby_invite_link(p_lobby_id uuid, p_expires_in interval) TO authenticated;
GRANT ALL ON FUNCTION public.generate_lobby_invite_link(p_lobby_id uuid, p_expires_in interval) TO service_role;


--
-- Name: FUNCTION get_lobby_befriend_invite_preview(p_record_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_lobby_befriend_invite_preview(p_record_id uuid) TO anon;
GRANT ALL ON FUNCTION public.get_lobby_befriend_invite_preview(p_record_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_lobby_befriend_invite_preview(p_record_id uuid) TO service_role;


--
-- Name: FUNCTION get_lobby_invite_preview(p_code text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_lobby_invite_preview(p_code text) TO anon;
GRANT ALL ON FUNCTION public.get_lobby_invite_preview(p_code text) TO authenticated;
GRANT ALL ON FUNCTION public.get_lobby_invite_preview(p_code text) TO service_role;


--
-- Name: FUNCTION get_my_friend_ids(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_my_friend_ids() TO anon;
GRANT ALL ON FUNCTION public.get_my_friend_ids() TO authenticated;
GRANT ALL ON FUNCTION public.get_my_friend_ids() TO service_role;


--
-- Name: FUNCTION get_my_lobby_ids(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_my_lobby_ids() TO anon;
GRANT ALL ON FUNCTION public.get_my_lobby_ids() TO authenticated;
GRANT ALL ON FUNCTION public.get_my_lobby_ids() TO service_role;


--
-- Name: FUNCTION get_my_lobbymate_ids(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_my_lobbymate_ids() TO anon;
GRANT ALL ON FUNCTION public.get_my_lobbymate_ids() TO authenticated;
GRANT ALL ON FUNCTION public.get_my_lobbymate_ids() TO service_role;


--
-- Name: FUNCTION get_payment_info(p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_payment_info(p_user_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_payment_info(p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_payment_info(p_user_id uuid) TO service_role;


--
-- Name: FUNCTION get_popular_networks(limit_count integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_popular_networks(limit_count integer) TO anon;
GRANT ALL ON FUNCTION public.get_popular_networks(limit_count integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_popular_networks(limit_count integer) TO service_role;


--
-- Name: FUNCTION health_capture_candidates(p_window_start timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.health_capture_candidates(p_window_start timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.health_capture_candidates(p_window_start timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.health_capture_candidates(p_window_start timestamp with time zone) TO service_role;


--
-- Name: FUNCTION home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_search text, p_mmr_window integer, p_page_size integer, p_page_number integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_search text, p_mmr_window integer, p_page_size integer, p_page_number integer) TO anon;
GRANT ALL ON FUNCTION public.home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_search text, p_mmr_window integer, p_page_size integer, p_page_number integer) TO authenticated;
GRANT ALL ON FUNCTION public.home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_search text, p_mmr_window integer, p_page_size integer, p_page_number integer) TO service_role;


--
-- Name: FUNCTION home_freeplay_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text, p_page_size integer, p_page_number integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.home_freeplay_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text, p_page_size integer, p_page_number integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.home_freeplay_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text, p_page_size integer, p_page_number integer) TO authenticated;
GRANT ALL ON FUNCTION public.home_freeplay_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text, p_page_size integer, p_page_number integer) TO service_role;
GRANT ALL ON FUNCTION public.home_freeplay_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text, p_page_size integer, p_page_number integer) TO anon;


--
-- Name: FUNCTION home_professional_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts text[], p_search text, p_page_size integer, p_page_number integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.home_professional_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts text[], p_search text, p_page_size integer, p_page_number integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.home_professional_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts text[], p_search text, p_page_size integer, p_page_number integer) TO authenticated;
GRANT ALL ON FUNCTION public.home_professional_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts text[], p_search text, p_page_size integer, p_page_number integer) TO service_role;


--
-- Name: FUNCTION home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text, p_page_size integer, p_page_number integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text, p_page_size integer, p_page_number integer) TO anon;
GRANT ALL ON FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text, p_page_size integer, p_page_number integer) TO authenticated;
GRANT ALL ON FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text, p_page_size integer, p_page_number integer) TO service_role;


--
-- Name: FUNCTION immutable_unaccent(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.immutable_unaccent(text) TO anon;
GRANT ALL ON FUNCTION public.immutable_unaccent(text) TO authenticated;
GRANT ALL ON FUNCTION public.immutable_unaccent(text) TO service_role;


--
-- Name: FUNCTION is_booking_attached_to_my_lobby_activity(p_booking_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_booking_attached_to_my_lobby_activity(p_booking_id uuid) TO anon;
GRANT ALL ON FUNCTION public.is_booking_attached_to_my_lobby_activity(p_booking_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.is_booking_attached_to_my_lobby_activity(p_booking_id uuid) TO service_role;


--
-- Name: FUNCTION leave_course(p_course_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.leave_course(p_course_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.leave_course(p_course_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.leave_course(p_course_id uuid) TO service_role;


--
-- Name: FUNCTION lobby_add_captain_as_member(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.lobby_add_captain_as_member() TO anon;
GRANT ALL ON FUNCTION public.lobby_add_captain_as_member() TO authenticated;
GRANT ALL ON FUNCTION public.lobby_add_captain_as_member() TO service_role;


--
-- Name: FUNCTION lobby_before_delete(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.lobby_before_delete() TO anon;
GRANT ALL ON FUNCTION public.lobby_before_delete() TO authenticated;
GRANT ALL ON FUNCTION public.lobby_before_delete() TO service_role;


--
-- Name: FUNCTION lobby_befriend_accepted_trigger_fn(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.lobby_befriend_accepted_trigger_fn() TO anon;
GRANT ALL ON FUNCTION public.lobby_befriend_accepted_trigger_fn() TO authenticated;
GRANT ALL ON FUNCTION public.lobby_befriend_accepted_trigger_fn() TO service_role;


--
-- Name: FUNCTION lobby_befriend_record_before_insert_trigger_fn(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.lobby_befriend_record_before_insert_trigger_fn() TO anon;
GRANT ALL ON FUNCTION public.lobby_befriend_record_before_insert_trigger_fn() TO authenticated;
GRANT ALL ON FUNCTION public.lobby_befriend_record_before_insert_trigger_fn() TO service_role;


--
-- Name: FUNCTION lobby_can_manage(p_lobby_id uuid, p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.lobby_can_manage(p_lobby_id uuid, p_user_id uuid) TO anon;
GRANT ALL ON FUNCTION public.lobby_can_manage(p_lobby_id uuid, p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.lobby_can_manage(p_lobby_id uuid, p_user_id uuid) TO service_role;


--
-- Name: FUNCTION lobby_challenge_data(p_lobby_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.lobby_challenge_data(p_lobby_id uuid) TO anon;
GRANT ALL ON FUNCTION public.lobby_challenge_data(p_lobby_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.lobby_challenge_data(p_lobby_id uuid) TO service_role;


--
-- Name: FUNCTION lobby_feed_data(p_lobby_id uuid, p_page_size integer, p_before timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.lobby_feed_data(p_lobby_id uuid, p_page_size integer, p_before timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.lobby_feed_data(p_lobby_id uuid, p_page_size integer, p_before timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.lobby_feed_data(p_lobby_id uuid, p_page_size integer, p_before timestamp with time zone) TO service_role;


--
-- Name: FUNCTION lobby_match_history_data(p_lobby_id uuid, p_page_size integer, p_page_number integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.lobby_match_history_data(p_lobby_id uuid, p_page_size integer, p_page_number integer) TO anon;
GRANT ALL ON FUNCTION public.lobby_match_history_data(p_lobby_id uuid, p_page_size integer, p_page_number integer) TO authenticated;
GRANT ALL ON FUNCTION public.lobby_match_history_data(p_lobby_id uuid, p_page_size integer, p_page_number integer) TO service_role;


--
-- Name: FUNCTION lobby_match_referee_role_check(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.lobby_match_referee_role_check() FROM PUBLIC;
GRANT ALL ON FUNCTION public.lobby_match_referee_role_check() TO service_role;


--
-- Name: FUNCTION lobby_member_prevent_captain_leave(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.lobby_member_prevent_captain_leave() TO anon;
GRANT ALL ON FUNCTION public.lobby_member_prevent_captain_leave() TO authenticated;
GRANT ALL ON FUNCTION public.lobby_member_prevent_captain_leave() TO service_role;


--
-- Name: FUNCTION lobby_money_data(p_lobby_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.lobby_money_data(p_lobby_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.lobby_money_data(p_lobby_id uuid) TO service_role;
GRANT ALL ON FUNCTION public.lobby_money_data(p_lobby_id uuid) TO authenticated;


--
-- Name: FUNCTION mark_conversation_read(p_conversation_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.mark_conversation_read(p_conversation_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.mark_conversation_read(p_conversation_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.mark_conversation_read(p_conversation_id uuid) TO service_role;


--
-- Name: FUNCTION mark_payment_request_paid(p_feed_item_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.mark_payment_request_paid(p_feed_item_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.mark_payment_request_paid(p_feed_item_id uuid) TO service_role;
GRANT ALL ON FUNCTION public.mark_payment_request_paid(p_feed_item_id uuid) TO authenticated;


--
-- Name: FUNCTION message_coach(p_professional_id uuid, p_sport_id bigint, p_body text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.message_coach(p_professional_id uuid, p_sport_id bigint, p_body text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.message_coach(p_professional_id uuid, p_sport_id bigint, p_body text) TO authenticated;
GRANT ALL ON FUNCTION public.message_coach(p_professional_id uuid, p_sport_id bigint, p_body text) TO service_role;


--
-- Name: FUNCTION my_courses_data(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.my_courses_data() FROM PUBLIC;
GRANT ALL ON FUNCTION public.my_courses_data() TO authenticated;
GRANT ALL ON FUNCTION public.my_courses_data() TO service_role;


--
-- Name: FUNCTION my_freeplay_host(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.my_freeplay_host() FROM PUBLIC;
GRANT ALL ON FUNCTION public.my_freeplay_host() TO authenticated;
GRANT ALL ON FUNCTION public.my_freeplay_host() TO service_role;


--
-- Name: FUNCTION my_schedule_data(p_sport_id bigint, p_from timestamp with time zone, p_to timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.my_schedule_data(p_sport_id bigint, p_from timestamp with time zone, p_to timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.my_schedule_data(p_sport_id bigint, p_from timestamp with time zone, p_to timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.my_schedule_data(p_sport_id bigint, p_from timestamp with time zone, p_to timestamp with time zone) TO service_role;


--
-- Name: FUNCTION nanoid(size integer, alphabet text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.nanoid(size integer, alphabet text) TO anon;
GRANT ALL ON FUNCTION public.nanoid(size integer, alphabet text) TO authenticated;
GRANT ALL ON FUNCTION public.nanoid(size integer, alphabet text) TO service_role;


--
-- Name: FUNCTION new_user_created_trigger_fn(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.new_user_created_trigger_fn() TO anon;
GRANT ALL ON FUNCTION public.new_user_created_trigger_fn() TO authenticated;
GRANT ALL ON FUNCTION public.new_user_created_trigger_fn() TO service_role;


--
-- Name: FUNCTION post_activity_note(p_activity_id uuid, p_note text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.post_activity_note(p_activity_id uuid, p_note text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.post_activity_note(p_activity_id uuid, p_note text) TO authenticated;
GRANT ALL ON FUNCTION public.post_activity_note(p_activity_id uuid, p_note text) TO service_role;


--
-- Name: FUNCTION postable_activities(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postable_activities() TO anon;
GRANT ALL ON FUNCTION public.postable_activities() TO authenticated;
GRANT ALL ON FUNCTION public.postable_activities() TO service_role;


--
-- Name: FUNCTION pro_courses_data(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.pro_courses_data() FROM PUBLIC;
GRANT ALL ON FUNCTION public.pro_courses_data() TO authenticated;
GRANT ALL ON FUNCTION public.pro_courses_data() TO service_role;


--
-- Name: FUNCTION propose_course_activity(p_course_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_location_id uuid, p_note text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.propose_course_activity(p_course_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_location_id uuid, p_note text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.propose_course_activity(p_course_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_location_id uuid, p_note text) TO authenticated;
GRANT ALL ON FUNCTION public.propose_course_activity(p_course_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_location_id uuid, p_note text) TO service_role;


--
-- Name: FUNCTION react_to_wall_post(p_post_id uuid, p_emoji text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.react_to_wall_post(p_post_id uuid, p_emoji text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.react_to_wall_post(p_post_id uuid, p_emoji text) TO authenticated;
GRANT ALL ON FUNCTION public.react_to_wall_post(p_post_id uuid, p_emoji text) TO service_role;


--
-- Name: FUNCTION record_challenge_match(p_challenge_id uuid, p_result text, p_sets jsonb, p_mvp_user_id uuid, p_note text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.record_challenge_match(p_challenge_id uuid, p_result text, p_sets jsonb, p_mvp_user_id uuid, p_note text) TO anon;
GRANT ALL ON FUNCTION public.record_challenge_match(p_challenge_id uuid, p_result text, p_sets jsonb, p_mvp_user_id uuid, p_note text) TO authenticated;
GRANT ALL ON FUNCTION public.record_challenge_match(p_challenge_id uuid, p_result text, p_sets jsonb, p_mvp_user_id uuid, p_note text) TO service_role;


--
-- Name: FUNCTION redeem_lobby_invite_link(p_code text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.redeem_lobby_invite_link(p_code text) TO anon;
GRANT ALL ON FUNCTION public.redeem_lobby_invite_link(p_code text) TO authenticated;
GRANT ALL ON FUNCTION public.redeem_lobby_invite_link(p_code text) TO service_role;


--
-- Name: FUNCTION referee_booking_conflicts(p_professional_id uuid, p_start timestamp with time zone, p_end timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.referee_booking_conflicts(p_professional_id uuid, p_start timestamp with time zone, p_end timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.referee_booking_conflicts(p_professional_id uuid, p_start timestamp with time zone, p_end timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.referee_booking_conflicts(p_professional_id uuid, p_start timestamp with time zone, p_end timestamp with time zone) TO service_role;


--
-- Name: FUNCTION referee_booking_review_updated_trigger_fn(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.referee_booking_review_updated_trigger_fn() FROM PUBLIC;
GRANT ALL ON FUNCTION public.referee_booking_review_updated_trigger_fn() TO service_role;


--
-- Name: FUNCTION register_device_token(p_fcm_token text, p_platform text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.register_device_token(p_fcm_token text, p_platform text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.register_device_token(p_fcm_token text, p_platform text) TO anon;
GRANT ALL ON FUNCTION public.register_device_token(p_fcm_token text, p_platform text) TO authenticated;
GRANT ALL ON FUNCTION public.register_device_token(p_fcm_token text, p_platform text) TO service_role;


--
-- Name: FUNCTION reject_referee_booking(p_booking_id uuid, p_reason text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.reject_referee_booking(p_booking_id uuid, p_reason text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.reject_referee_booking(p_booking_id uuid, p_reason text) TO authenticated;
GRANT ALL ON FUNCTION public.reject_referee_booking(p_booking_id uuid, p_reason text) TO service_role;


--
-- Name: FUNCTION remove_course_member(p_course_id uuid, p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.remove_course_member(p_course_id uuid, p_user_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.remove_course_member(p_course_id uuid, p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.remove_course_member(p_course_id uuid, p_user_id uuid) TO service_role;


--
-- Name: FUNCTION request_freeplay_seat(p_activity_id uuid, p_message text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.request_freeplay_seat(p_activity_id uuid, p_message text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.request_freeplay_seat(p_activity_id uuid, p_message text) TO authenticated;
GRANT ALL ON FUNCTION public.request_freeplay_seat(p_activity_id uuid, p_message text) TO service_role;


--
-- Name: FUNCTION request_referee_booking(p_professional_id uuid, p_service_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_notes text, p_location_id uuid, p_participant_user_ids uuid[], p_existing_package_id uuid, p_create_package boolean, p_activity_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.request_referee_booking(p_professional_id uuid, p_service_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_notes text, p_location_id uuid, p_participant_user_ids uuid[], p_existing_package_id uuid, p_create_package boolean, p_activity_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.request_referee_booking(p_professional_id uuid, p_service_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_notes text, p_location_id uuid, p_participant_user_ids uuid[], p_existing_package_id uuid, p_create_package boolean, p_activity_id uuid) TO anon;
GRANT ALL ON FUNCTION public.request_referee_booking(p_professional_id uuid, p_service_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_notes text, p_location_id uuid, p_participant_user_ids uuid[], p_existing_package_id uuid, p_create_package boolean, p_activity_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.request_referee_booking(p_professional_id uuid, p_service_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_notes text, p_location_id uuid, p_participant_user_ids uuid[], p_existing_package_id uuid, p_create_package boolean, p_activity_id uuid) TO service_role;


--
-- Name: FUNCTION reschedule_course_activity(p_activity_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_location_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.reschedule_course_activity(p_activity_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_location_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.reschedule_course_activity(p_activity_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_location_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.reschedule_course_activity(p_activity_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_location_id uuid) TO service_role;


--
-- Name: FUNCTION resolve_at_risk_activity_organizer(p_activity_id uuid, p_action text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.resolve_at_risk_activity_organizer(p_activity_id uuid, p_action text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.resolve_at_risk_activity_organizer(p_activity_id uuid, p_action text) TO authenticated;
GRANT ALL ON FUNCTION public.resolve_at_risk_activity_organizer(p_activity_id uuid, p_action text) TO service_role;


--
-- Name: FUNCTION resolve_at_risk_activity_rsvp(p_activity_id uuid, p_attendance text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.resolve_at_risk_activity_rsvp(p_activity_id uuid, p_attendance text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.resolve_at_risk_activity_rsvp(p_activity_id uuid, p_attendance text) TO authenticated;
GRANT ALL ON FUNCTION public.resolve_at_risk_activity_rsvp(p_activity_id uuid, p_attendance text) TO service_role;


--
-- Name: FUNCTION respond_challenge(p_challenge_id uuid, p_action text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.respond_challenge(p_challenge_id uuid, p_action text) TO anon;
GRANT ALL ON FUNCTION public.respond_challenge(p_challenge_id uuid, p_action text) TO authenticated;
GRANT ALL ON FUNCTION public.respond_challenge(p_challenge_id uuid, p_action text) TO service_role;


--
-- Name: FUNCTION respond_course_proposal(p_activity_id uuid, p_approve boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.respond_course_proposal(p_activity_id uuid, p_approve boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.respond_course_proposal(p_activity_id uuid, p_approve boolean) TO authenticated;
GRANT ALL ON FUNCTION public.respond_course_proposal(p_activity_id uuid, p_approve boolean) TO service_role;


--
-- Name: FUNCTION respond_enrollment_offer(p_offer_id uuid, p_accept boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.respond_enrollment_offer(p_offer_id uuid, p_accept boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.respond_enrollment_offer(p_offer_id uuid, p_accept boolean) TO authenticated;
GRANT ALL ON FUNCTION public.respond_enrollment_offer(p_offer_id uuid, p_accept boolean) TO service_role;


--
-- Name: FUNCTION respond_freeplay_request(p_request_id uuid, p_accept boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.respond_freeplay_request(p_request_id uuid, p_accept boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.respond_freeplay_request(p_request_id uuid, p_accept boolean) TO authenticated;
GRANT ALL ON FUNCTION public.respond_freeplay_request(p_request_id uuid, p_accept boolean) TO service_role;


--
-- Name: FUNCTION respond_friend_request(p_friendship_id uuid, p_action text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.respond_friend_request(p_friendship_id uuid, p_action text) TO anon;
GRANT ALL ON FUNCTION public.respond_friend_request(p_friendship_id uuid, p_action text) TO authenticated;
GRANT ALL ON FUNCTION public.respond_friend_request(p_friendship_id uuid, p_action text) TO service_role;


--
-- Name: FUNCTION revoke_lobby_invite_link(p_lobby_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.revoke_lobby_invite_link(p_lobby_id uuid) TO anon;
GRANT ALL ON FUNCTION public.revoke_lobby_invite_link(p_lobby_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.revoke_lobby_invite_link(p_lobby_id uuid) TO service_role;


--
-- Name: FUNCTION search_locations(search_term text, p_districts character varying[], p_city_cluster bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.search_locations(search_term text, p_districts character varying[], p_city_cluster bigint) TO anon;
GRANT ALL ON FUNCTION public.search_locations(search_term text, p_districts character varying[], p_city_cluster bigint) TO authenticated;
GRANT ALL ON FUNCTION public.search_locations(search_term text, p_districts character varying[], p_city_cluster bigint) TO service_role;


--
-- Name: FUNCTION search_networks_unaccent(search_term text, result_limit integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.search_networks_unaccent(search_term text, result_limit integer) TO anon;
GRANT ALL ON FUNCTION public.search_networks_unaccent(search_term text, result_limit integer) TO authenticated;
GRANT ALL ON FUNCTION public.search_networks_unaccent(search_term text, result_limit integer) TO service_role;


--
-- Name: FUNCTION search_networks_unaccent(search_term text, result_limit integer, filter_cities bigint[], filter_categories text[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.search_networks_unaccent(search_term text, result_limit integer, filter_cities bigint[], filter_categories text[]) TO anon;
GRANT ALL ON FUNCTION public.search_networks_unaccent(search_term text, result_limit integer, filter_cities bigint[], filter_categories text[]) TO authenticated;
GRANT ALL ON FUNCTION public.search_networks_unaccent(search_term text, result_limit integer, filter_cities bigint[], filter_categories text[]) TO service_role;


--
-- Name: FUNCTION seeded_sport_id(p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.seeded_sport_id(p_user_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.seeded_sport_id(p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.seeded_sport_id(p_user_id uuid) TO service_role;


--
-- Name: FUNCTION send_challenge(p_initiator_lobby uuid, p_target_lobby uuid, p_note text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.send_challenge(p_initiator_lobby uuid, p_target_lobby uuid, p_note text) TO anon;
GRANT ALL ON FUNCTION public.send_challenge(p_initiator_lobby uuid, p_target_lobby uuid, p_note text) TO authenticated;
GRANT ALL ON FUNCTION public.send_challenge(p_initiator_lobby uuid, p_target_lobby uuid, p_note text) TO service_role;


--
-- Name: FUNCTION send_enrollment_offer(p_course_id uuid, p_user_id uuid, p_name text, p_description text, p_target_session_count integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.send_enrollment_offer(p_course_id uuid, p_user_id uuid, p_name text, p_description text, p_target_session_count integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.send_enrollment_offer(p_course_id uuid, p_user_id uuid, p_name text, p_description text, p_target_session_count integer) TO authenticated;
GRANT ALL ON FUNCTION public.send_enrollment_offer(p_course_id uuid, p_user_id uuid, p_name text, p_description text, p_target_session_count integer) TO service_role;


--
-- Name: FUNCTION send_friend_request(p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.send_friend_request(p_user_id uuid) TO anon;
GRANT ALL ON FUNCTION public.send_friend_request(p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.send_friend_request(p_user_id uuid) TO service_role;


--
-- Name: FUNCTION send_message(p_conversation_id uuid, p_body text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.send_message(p_conversation_id uuid, p_body text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.send_message(p_conversation_id uuid, p_body text) TO authenticated;
GRANT ALL ON FUNCTION public.send_message(p_conversation_id uuid, p_body text) TO service_role;


--
-- Name: FUNCTION set_freeplay_intake(p_activity_id uuid, p_closed boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.set_freeplay_intake(p_activity_id uuid, p_closed boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.set_freeplay_intake(p_activity_id uuid, p_closed boolean) TO authenticated;
GRANT ALL ON FUNCTION public.set_freeplay_intake(p_activity_id uuid, p_closed boolean) TO service_role;


--
-- Name: FUNCTION set_lobby_challenge_offer(p_lobby_id uuid, p_open boolean, p_time timestamp with time zone, p_location uuid, p_cost numeric); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.set_lobby_challenge_offer(p_lobby_id uuid, p_open boolean, p_time timestamp with time zone, p_location uuid, p_cost numeric) TO anon;
GRANT ALL ON FUNCTION public.set_lobby_challenge_offer(p_lobby_id uuid, p_open boolean, p_time timestamp with time zone, p_location uuid, p_cost numeric) TO authenticated;
GRANT ALL ON FUNCTION public.set_lobby_challenge_offer(p_lobby_id uuid, p_open boolean, p_time timestamp with time zone, p_location uuid, p_cost numeric) TO service_role;


--
-- Name: FUNCTION set_lobby_member_role(p_lobby_id uuid, p_member_user_id uuid, p_role text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.set_lobby_member_role(p_lobby_id uuid, p_member_user_id uuid, p_role text) TO anon;
GRANT ALL ON FUNCTION public.set_lobby_member_role(p_lobby_id uuid, p_member_user_id uuid, p_role text) TO authenticated;
GRANT ALL ON FUNCTION public.set_lobby_member_role(p_lobby_id uuid, p_member_user_id uuid, p_role text) TO service_role;


--
-- Name: FUNCTION settle_lobby_money(p_lobby_id uuid, p_counterparty_id uuid, p_idempotency_key uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.settle_lobby_money(p_lobby_id uuid, p_counterparty_id uuid, p_idempotency_key uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.settle_lobby_money(p_lobby_id uuid, p_counterparty_id uuid, p_idempotency_key uuid) TO service_role;
GRANT ALL ON FUNCTION public.settle_lobby_money(p_lobby_id uuid, p_counterparty_id uuid, p_idempotency_key uuid) TO authenticated;


--
-- Name: FUNCTION share_conversation_payment_info(p_conversation_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.share_conversation_payment_info(p_conversation_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.share_conversation_payment_info(p_conversation_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.share_conversation_payment_info(p_conversation_id uuid) TO service_role;


--
-- Name: FUNCTION submit_course_review(p_course_id uuid, p_rating smallint, p_comment text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.submit_course_review(p_course_id uuid, p_rating smallint, p_comment text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.submit_course_review(p_course_id uuid, p_rating smallint, p_comment text) TO authenticated;
GRANT ALL ON FUNCTION public.submit_course_review(p_course_id uuid, p_rating smallint, p_comment text) TO service_role;


--
-- Name: FUNCTION submit_session_report(p_activity_id uuid, p_student_id uuid, p_body text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.submit_session_report(p_activity_id uuid, p_student_id uuid, p_body text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.submit_session_report(p_activity_id uuid, p_student_id uuid, p_body text) TO authenticated;
GRANT ALL ON FUNCTION public.submit_session_report(p_activity_id uuid, p_student_id uuid, p_body text) TO service_role;


--
-- Name: FUNCTION taggable_users(p_activity_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.taggable_users(p_activity_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.taggable_users(p_activity_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.taggable_users(p_activity_id uuid) TO service_role;


--
-- Name: FUNCTION transfer_lobby_captaincy(p_lobby_id uuid, p_new_captain_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.transfer_lobby_captaincy(p_lobby_id uuid, p_new_captain_id uuid) TO anon;
GRANT ALL ON FUNCTION public.transfer_lobby_captaincy(p_lobby_id uuid, p_new_captain_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.transfer_lobby_captaincy(p_lobby_id uuid, p_new_captain_id uuid) TO service_role;


--
-- Name: FUNCTION trg_lobby_match_rated_count(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.trg_lobby_match_rated_count() FROM PUBLIC;
GRANT ALL ON FUNCTION public.trg_lobby_match_rated_count() TO service_role;


--
-- Name: FUNCTION trg_lobby_match_rating(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.trg_lobby_match_rating() FROM PUBLIC;
GRANT ALL ON FUNCTION public.trg_lobby_match_rating() TO service_role;


--
-- Name: FUNCTION trg_lobby_member_recompute(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.trg_lobby_member_recompute() FROM PUBLIC;
GRANT ALL ON FUNCTION public.trg_lobby_member_recompute() TO service_role;


--
-- Name: FUNCTION trg_lobby_playtime_keys(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.trg_lobby_playtime_keys() FROM PUBLIC;
GRANT ALL ON FUNCTION public.trg_lobby_playtime_keys() TO service_role;


--
-- Name: FUNCTION trg_user_affiliation_recompute(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.trg_user_affiliation_recompute() FROM PUBLIC;
GRANT ALL ON FUNCTION public.trg_user_affiliation_recompute() TO service_role;


--
-- Name: FUNCTION trg_user_rating_recompute(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.trg_user_rating_recompute() FROM PUBLIC;
GRANT ALL ON FUNCTION public.trg_user_rating_recompute() TO service_role;


--
-- Name: FUNCTION unblock_user(p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.unblock_user(p_user_id uuid) TO anon;
GRANT ALL ON FUNCTION public.unblock_user(p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.unblock_user(p_user_id uuid) TO service_role;


--
-- Name: FUNCTION unfriend(p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.unfriend(p_user_id uuid) TO anon;
GRANT ALL ON FUNCTION public.unfriend(p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.unfriend(p_user_id uuid) TO service_role;


--
-- Name: FUNCTION update_freeplay_activity(p_activity_id uuid, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid, p_venue_name text, p_street_address text, p_city_cluster bigint, p_ward text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.update_freeplay_activity(p_activity_id uuid, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid, p_venue_name text, p_street_address text, p_city_cluster bigint, p_ward text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.update_freeplay_activity(p_activity_id uuid, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid, p_venue_name text, p_street_address text, p_city_cluster bigint, p_ward text) TO authenticated;
GRANT ALL ON FUNCTION public.update_freeplay_activity(p_activity_id uuid, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid, p_venue_name text, p_street_address text, p_city_cluster bigint, p_ward text) TO service_role;


--
-- Name: FUNCTION update_lobby(p_lobby_id uuid, p_name text, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_lobby(p_lobby_id uuid, p_name text, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid) TO anon;
GRANT ALL ON FUNCTION public.update_lobby(p_lobby_id uuid, p_name text, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.update_lobby(p_lobby_id uuid, p_name text, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid) TO service_role;


--
-- Name: FUNCTION user_level_summary(p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.user_level_summary(p_user_id uuid) TO anon;
GRANT ALL ON FUNCTION public.user_level_summary(p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.user_level_summary(p_user_id uuid) TO service_role;


--
-- Name: FUNCTION user_profile_data(p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.user_profile_data(p_user_id uuid) TO anon;
GRANT ALL ON FUNCTION public.user_profile_data(p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.user_profile_data(p_user_id uuid) TO service_role;


--
-- Name: FUNCTION user_wall_data(p_user_id uuid, p_mode text, p_page_size integer, p_page_number integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.user_wall_data(p_user_id uuid, p_mode text, p_page_size integer, p_page_number integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.user_wall_data(p_user_id uuid, p_mode text, p_page_size integer, p_page_number integer) TO authenticated;
GRANT ALL ON FUNCTION public.user_wall_data(p_user_id uuid, p_mode text, p_page_size integer, p_page_number integer) TO service_role;


--
-- Name: FUNCTION vitality_score_summary(p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.vitality_score_summary(p_user_id uuid) TO anon;
GRANT ALL ON FUNCTION public.vitality_score_summary(p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.vitality_score_summary(p_user_id uuid) TO service_role;


--
-- Name: FUNCTION vote_message_poll(p_message_id uuid, p_option_index smallint); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.vote_message_poll(p_message_id uuid, p_option_index smallint) FROM PUBLIC;
GRANT ALL ON FUNCTION public.vote_message_poll(p_message_id uuid, p_option_index smallint) TO authenticated;
GRANT ALL ON FUNCTION public.vote_message_poll(p_message_id uuid, p_option_index smallint) TO service_role;


--
-- Name: FUNCTION wall_feed_data(p_sport_id bigint, p_page_size integer, p_page_number integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.wall_feed_data(p_sport_id bigint, p_page_size integer, p_page_number integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.wall_feed_data(p_sport_id bigint, p_page_size integer, p_page_number integer) TO authenticated;
GRANT ALL ON FUNCTION public.wall_feed_data(p_sport_id bigint, p_page_size integer, p_page_number integer) TO service_role;


--
-- Name: FUNCTION wall_feed_has_unread(p_since timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.wall_feed_has_unread(p_since timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.wall_feed_has_unread(p_since timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.wall_feed_has_unread(p_since timestamp with time zone) TO service_role;


--
-- Name: FUNCTION withdraw_course_proposal(p_activity_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.withdraw_course_proposal(p_activity_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.withdraw_course_proposal(p_activity_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.withdraw_course_proposal(p_activity_id uuid) TO service_role;


--
-- Name: FUNCTION apply_rls(wal jsonb, max_record_bytes integer); Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO postgres;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO anon;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO authenticated;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO service_role;


--
-- Name: FUNCTION broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text); Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text) TO postgres;
GRANT ALL ON FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text) TO dashboard_user;


--
-- Name: FUNCTION build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]); Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO postgres;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO anon;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO authenticated;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO service_role;


--
-- Name: FUNCTION "cast"(val text, type_ regtype); Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO postgres;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO dashboard_user;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO anon;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO authenticated;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO service_role;


--
-- Name: FUNCTION check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text); Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO postgres;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO anon;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO authenticated;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO service_role;


--
-- Name: FUNCTION check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text, negate boolean); Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text, negate boolean) TO postgres;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text, negate boolean) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text, negate boolean) TO anon;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text, negate boolean) TO authenticated;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text, negate boolean) TO service_role;


--
-- Name: FUNCTION is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]); Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO postgres;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO anon;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO authenticated;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO service_role;


--
-- Name: FUNCTION list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer); Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO postgres;
GRANT ALL ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO dashboard_user;


--
-- Name: FUNCTION quote_wal2json(entity regclass); Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO postgres;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO anon;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO authenticated;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO service_role;


--
-- Name: FUNCTION send(payload jsonb, event text, topic text, private boolean); Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean) TO postgres;
GRANT ALL ON FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean) TO dashboard_user;


--
-- Name: FUNCTION send_binary(payload bytea, event text, topic text, private boolean); Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON FUNCTION realtime.send_binary(payload bytea, event text, topic text, private boolean) TO postgres;
GRANT ALL ON FUNCTION realtime.send_binary(payload bytea, event text, topic text, private boolean) TO dashboard_user;


--
-- Name: FUNCTION subscription_check_filters(); Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO postgres;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO dashboard_user;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO anon;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO authenticated;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO service_role;


--
-- Name: FUNCTION to_regrole(role_name text); Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO postgres;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO anon;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO authenticated;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO service_role;


--
-- Name: FUNCTION topic(); Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON FUNCTION realtime.topic() TO postgres;
GRANT ALL ON FUNCTION realtime.topic() TO dashboard_user;


--
-- Name: FUNCTION wal2json_escape_identifier(name text); Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON FUNCTION realtime.wal2json_escape_identifier(name text) TO postgres;
GRANT ALL ON FUNCTION realtime.wal2json_escape_identifier(name text) TO dashboard_user;


--
-- Name: FUNCTION can_insert_object(bucketid text, name text, owner uuid, metadata jsonb); Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) TO postgres;


--
-- Name: FUNCTION extension(name text); Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON FUNCTION storage.extension(name text) TO postgres;


--
-- Name: FUNCTION filename(name text); Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON FUNCTION storage.filename(name text) TO postgres;


--
-- Name: FUNCTION foldername(name text); Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON FUNCTION storage.foldername(name text) TO postgres;


--
-- Name: FUNCTION get_size_by_bucket(); Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON FUNCTION storage.get_size_by_bucket() TO postgres;


--
-- Name: FUNCTION list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer, next_key_token text, next_upload_token text); Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer, next_key_token text, next_upload_token text) TO postgres;


--
-- Name: FUNCTION operation(); Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON FUNCTION storage.operation() TO postgres;


--
-- Name: FUNCTION search(prefix text, bucketname text, limits integer, levels integer, offsets integer, search text, sortcolumn text, sortorder text); Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON FUNCTION storage.search(prefix text, bucketname text, limits integer, levels integer, offsets integer, search text, sortcolumn text, sortorder text) TO postgres;


--
-- Name: FUNCTION update_updated_at_column(); Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON FUNCTION storage.update_updated_at_column() TO postgres;


--
-- Name: FUNCTION _crypto_aead_det_decrypt(message bytea, additional bytea, key_id bigint, context bytea, nonce bytea); Type: ACL; Schema: vault; Owner: supabase_admin
--

GRANT ALL ON FUNCTION vault._crypto_aead_det_decrypt(message bytea, additional bytea, key_id bigint, context bytea, nonce bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION vault._crypto_aead_det_decrypt(message bytea, additional bytea, key_id bigint, context bytea, nonce bytea) TO service_role;


--
-- Name: FUNCTION create_secret(new_secret text, new_name text, new_description text, new_key_id uuid); Type: ACL; Schema: vault; Owner: supabase_admin
--

GRANT ALL ON FUNCTION vault.create_secret(new_secret text, new_name text, new_description text, new_key_id uuid) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION vault.create_secret(new_secret text, new_name text, new_description text, new_key_id uuid) TO service_role;


--
-- Name: FUNCTION update_secret(secret_id uuid, new_secret text, new_name text, new_description text, new_key_id uuid); Type: ACL; Schema: vault; Owner: supabase_admin
--

GRANT ALL ON FUNCTION vault.update_secret(secret_id uuid, new_secret text, new_name text, new_description text, new_key_id uuid) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION vault.update_secret(secret_id uuid, new_secret text, new_name text, new_description text, new_key_id uuid) TO service_role;


--
-- Name: TABLE audit_log_entries; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.audit_log_entries TO dashboard_user;
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.audit_log_entries TO postgres;
GRANT SELECT ON TABLE auth.audit_log_entries TO postgres WITH GRANT OPTION;


--
-- Name: TABLE custom_oauth_providers; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.custom_oauth_providers TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.custom_oauth_providers TO dashboard_user;


--
-- Name: TABLE flow_state; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.flow_state TO postgres;
GRANT SELECT ON TABLE auth.flow_state TO postgres WITH GRANT OPTION;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.flow_state TO dashboard_user;


--
-- Name: TABLE identities; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.identities TO postgres;
GRANT SELECT ON TABLE auth.identities TO postgres WITH GRANT OPTION;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.identities TO dashboard_user;


--
-- Name: TABLE instances; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.instances TO dashboard_user;
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.instances TO postgres;
GRANT SELECT ON TABLE auth.instances TO postgres WITH GRANT OPTION;


--
-- Name: TABLE mfa_amr_claims; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.mfa_amr_claims TO postgres;
GRANT SELECT ON TABLE auth.mfa_amr_claims TO postgres WITH GRANT OPTION;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.mfa_amr_claims TO dashboard_user;


--
-- Name: TABLE mfa_challenges; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.mfa_challenges TO postgres;
GRANT SELECT ON TABLE auth.mfa_challenges TO postgres WITH GRANT OPTION;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.mfa_challenges TO dashboard_user;


--
-- Name: TABLE mfa_factors; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.mfa_factors TO postgres;
GRANT SELECT ON TABLE auth.mfa_factors TO postgres WITH GRANT OPTION;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.mfa_factors TO dashboard_user;


--
-- Name: TABLE oauth_authorizations; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.oauth_authorizations TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.oauth_authorizations TO dashboard_user;


--
-- Name: TABLE oauth_client_states; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.oauth_client_states TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.oauth_client_states TO dashboard_user;


--
-- Name: TABLE oauth_clients; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.oauth_clients TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.oauth_clients TO dashboard_user;


--
-- Name: TABLE oauth_consents; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.oauth_consents TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.oauth_consents TO dashboard_user;


--
-- Name: TABLE one_time_tokens; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.one_time_tokens TO postgres;
GRANT SELECT ON TABLE auth.one_time_tokens TO postgres WITH GRANT OPTION;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.one_time_tokens TO dashboard_user;


--
-- Name: TABLE refresh_tokens; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.refresh_tokens TO dashboard_user;
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.refresh_tokens TO postgres;
GRANT SELECT ON TABLE auth.refresh_tokens TO postgres WITH GRANT OPTION;


--
-- Name: SEQUENCE refresh_tokens_id_seq; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON SEQUENCE auth.refresh_tokens_id_seq TO dashboard_user;
GRANT ALL ON SEQUENCE auth.refresh_tokens_id_seq TO postgres;


--
-- Name: TABLE saml_providers; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.saml_providers TO postgres;
GRANT SELECT ON TABLE auth.saml_providers TO postgres WITH GRANT OPTION;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.saml_providers TO dashboard_user;


--
-- Name: TABLE saml_relay_states; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.saml_relay_states TO postgres;
GRANT SELECT ON TABLE auth.saml_relay_states TO postgres WITH GRANT OPTION;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.saml_relay_states TO dashboard_user;


--
-- Name: TABLE sessions; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.sessions TO postgres;
GRANT SELECT ON TABLE auth.sessions TO postgres WITH GRANT OPTION;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.sessions TO dashboard_user;


--
-- Name: TABLE sso_domains; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.sso_domains TO postgres;
GRANT SELECT ON TABLE auth.sso_domains TO postgres WITH GRANT OPTION;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.sso_domains TO dashboard_user;


--
-- Name: TABLE sso_providers; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.sso_providers TO postgres;
GRANT SELECT ON TABLE auth.sso_providers TO postgres WITH GRANT OPTION;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.sso_providers TO dashboard_user;


--
-- Name: TABLE users; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.users TO dashboard_user;
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.users TO postgres;
GRANT SELECT ON TABLE auth.users TO postgres WITH GRANT OPTION;


--
-- Name: TABLE webauthn_challenges; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.webauthn_challenges TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.webauthn_challenges TO dashboard_user;


--
-- Name: TABLE webauthn_credentials; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.webauthn_credentials TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.webauthn_credentials TO dashboard_user;


--
-- Name: TABLE job; Type: ACL; Schema: cron; Owner: supabase_admin
--

GRANT SELECT ON TABLE cron.job TO postgres WITH GRANT OPTION;


--
-- Name: TABLE job_run_details; Type: ACL; Schema: cron; Owner: supabase_admin
--

GRANT ALL ON TABLE cron.job_run_details TO postgres WITH GRANT OPTION;


--
-- Name: TABLE pg_stat_statements_info; Type: ACL; Schema: extensions; Owner: supabase_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE extensions.pg_stat_statements_info TO postgres WITH GRANT OPTION;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE extensions.pg_stat_statements_info TO dashboard_user;


--
-- Name: TABLE decrypted_key; Type: ACL; Schema: pgsodium; Owner: supabase_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE pgsodium.decrypted_key TO pgsodium_keyholder;


--
-- Name: TABLE masking_rule; Type: ACL; Schema: pgsodium; Owner: supabase_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE pgsodium.masking_rule TO pgsodium_keyholder;


--
-- Name: TABLE mask_columns; Type: ACL; Schema: pgsodium; Owner: supabase_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE pgsodium.mask_columns TO pgsodium_keyholder;


--
-- Name: TABLE achievement; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.achievement TO anon;
GRANT SELECT ON TABLE public.achievement TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.achievement TO service_role;


--
-- Name: TABLE activity; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.activity TO anon;
GRANT ALL ON TABLE public.activity TO authenticated;
GRANT ALL ON TABLE public.activity TO service_role;


--
-- Name: TABLE activity_confirmation; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.activity_confirmation TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.activity_confirmation TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.activity_confirmation TO service_role;


--
-- Name: TABLE activity_hr_sample; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.activity_hr_sample TO anon;
GRANT ALL ON TABLE public.activity_hr_sample TO authenticated;
GRANT ALL ON TABLE public.activity_hr_sample TO service_role;


--
-- Name: SEQUENCE activity_hr_sample_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.activity_hr_sample_id_seq TO anon;
GRANT ALL ON SEQUENCE public.activity_hr_sample_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.activity_hr_sample_id_seq TO service_role;


--
-- Name: TABLE activity_reminder_sent; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.activity_reminder_sent TO service_role;


--
-- Name: TABLE activity_series_frontier; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.activity_series_frontier TO service_role;


--
-- Name: TABLE badminton_profile; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.badminton_profile TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.badminton_profile TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.badminton_profile TO service_role;


--
-- Name: TABLE basketball_profile; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.basketball_profile TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.basketball_profile TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.basketball_profile TO service_role;


--
-- Name: TABLE conversation; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.conversation TO service_role;


--
-- Name: TABLE conversation_member; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.conversation_member TO service_role;


--
-- Name: TABLE course; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.course TO service_role;


--
-- Name: TABLE course_enrollment_offer; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.course_enrollment_offer TO service_role;


--
-- Name: TABLE course_member; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.course_member TO service_role;


--
-- Name: TABLE course_review; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.course_review TO service_role;


--
-- Name: TABLE course_session_report; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.course_session_report TO service_role;


--
-- Name: TABLE daily_health_summary; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.daily_health_summary TO anon;
GRANT ALL ON TABLE public.daily_health_summary TO authenticated;
GRANT ALL ON TABLE public.daily_health_summary TO service_role;


--
-- Name: TABLE enabled_notification_kind; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.enabled_notification_kind TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.enabled_notification_kind TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.enabled_notification_kind TO service_role;


--
-- Name: TABLE freeplay_activity; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.freeplay_activity TO service_role;


--
-- Name: TABLE freeplay_host; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.freeplay_host TO service_role;


--
-- Name: COLUMN freeplay_host.id; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(id) ON TABLE public.freeplay_host TO authenticated;


--
-- Name: COLUMN freeplay_host.user_id; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(user_id) ON TABLE public.freeplay_host TO authenticated;


--
-- Name: COLUMN freeplay_host.display_name; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(display_name),UPDATE(display_name) ON TABLE public.freeplay_host TO authenticated;


--
-- Name: TABLE freeplay_request; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.freeplay_request TO service_role;


--
-- Name: TABLE friendship; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.friendship TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.friendship TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.friendship TO service_role;


--
-- Name: TABLE industry; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.industry TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.industry TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.industry TO service_role;


--
-- Name: SEQUENCE industry_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.industry_id_seq TO anon;
GRANT ALL ON SEQUENCE public.industry_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.industry_id_seq TO service_role;


--
-- Name: TABLE lobby; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby TO service_role;


--
-- Name: TABLE lobby_befriend_record; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_befriend_record TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_befriend_record TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_befriend_record TO service_role;


--
-- Name: TABLE lobby_challenge; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_challenge TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_challenge TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_challenge TO service_role;


--
-- Name: TABLE lobby_feed_item; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_feed_item TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_feed_item TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_feed_item TO service_role;


--
-- Name: TABLE lobby_feed_item_reaction; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_feed_item_reaction TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_feed_item_reaction TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_feed_item_reaction TO service_role;


--
-- Name: TABLE lobby_feed_poll_vote; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_feed_poll_vote TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_feed_poll_vote TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_feed_poll_vote TO service_role;


--
-- Name: TABLE lobby_invite_link; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_invite_link TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_invite_link TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_invite_link TO service_role;


--
-- Name: TABLE lobby_match; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_match TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_match TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_match TO service_role;


--
-- Name: TABLE lobby_member; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_member TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_member TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_member TO service_role;


--
-- Name: SEQUENCE lobby_member_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.lobby_member_id_seq TO anon;
GRANT ALL ON SEQUENCE public.lobby_member_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.lobby_member_id_seq TO service_role;


--
-- Name: TABLE lobby_payment_request_payee; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_payment_request_payee TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_payment_request_payee TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_payment_request_payee TO service_role;


--
-- Name: TABLE lobby_payment_settlement; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_payment_settlement TO service_role;


--
-- Name: TABLE lobby_payment_settlement_item; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_payment_settlement_item TO service_role;


--
-- Name: TABLE location; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.location TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.location TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.location TO service_role;


--
-- Name: TABLE message; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.message TO service_role;


--
-- Name: TABLE message_poll_vote; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.message_poll_vote TO service_role;


--
-- Name: TABLE network; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.network TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.network TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.network TO service_role;


--
-- Name: SEQUENCE network_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.network_id_seq TO anon;
GRANT ALL ON SEQUENCE public.network_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.network_id_seq TO service_role;


--
-- Name: SEQUENCE notification_outbox_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.notification_outbox_id_seq TO anon;
GRANT ALL ON SEQUENCE public.notification_outbox_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.notification_outbox_id_seq TO service_role;


--
-- Name: TABLE pickleball_profile; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pickleball_profile TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pickleball_profile TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pickleball_profile TO service_role;


--
-- Name: TABLE professional; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE ON TABLE public.professional TO anon;
GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE ON TABLE public.professional TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional TO service_role;


--
-- Name: COLUMN professional.display_name; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE(display_name) ON TABLE public.professional TO authenticated;


--
-- Name: COLUMN professional.bio; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE(bio) ON TABLE public.professional TO authenticated;


--
-- Name: COLUMN professional.contact_details; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE(contact_details) ON TABLE public.professional TO authenticated;


--
-- Name: COLUMN professional.schedule; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE(schedule) ON TABLE public.professional TO authenticated;


--
-- Name: COLUMN professional.schedule_note; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE(schedule_note) ON TABLE public.professional TO authenticated;


--
-- Name: TABLE professional_preferred_location; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional_preferred_location TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional_preferred_location TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional_preferred_location TO service_role;


--
-- Name: TABLE professional_service; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional_service TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional_service TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional_service TO service_role;


--
-- Name: TABLE referee_booking; Type: ACL; Schema: public; Owner: postgres
--

GRANT REFERENCES,TRIGGER,TRUNCATE ON TABLE public.referee_booking TO anon;
GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE ON TABLE public.referee_booking TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.referee_booking TO service_role;


--
-- Name: TABLE referee_booking_additional_users; Type: ACL; Schema: public; Owner: postgres
--

GRANT REFERENCES,TRIGGER,TRUNCATE ON TABLE public.referee_booking_additional_users TO anon;
GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE ON TABLE public.referee_booking_additional_users TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.referee_booking_additional_users TO service_role;


--
-- Name: TABLE referee_booking_review; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,TRIGGER,TRUNCATE ON TABLE public.referee_booking_review TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.referee_booking_review TO service_role;


--
-- Name: TABLE soccer_profile; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.soccer_profile TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.soccer_profile TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.soccer_profile TO service_role;


--
-- Name: TABLE social_event; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.social_event TO service_role;


--
-- Name: SEQUENCE social_event_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.social_event_id_seq TO anon;
GRANT ALL ON SEQUENCE public.social_event_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.social_event_id_seq TO service_role;


--
-- Name: TABLE sport; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.sport TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.sport TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.sport TO service_role;


--
-- Name: SEQUENCE sport_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.sport_id_seq TO anon;
GRANT ALL ON SEQUENCE public.sport_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.sport_id_seq TO service_role;


--
-- Name: TABLE supported_city_cluster; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.supported_city_cluster TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.supported_city_cluster TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.supported_city_cluster TO service_role;


--
-- Name: SEQUENCE supported_city_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.supported_city_id_seq TO anon;
GRANT ALL ON SEQUENCE public.supported_city_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.supported_city_id_seq TO service_role;


--
-- Name: TABLE tennis_profile; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.tennis_profile TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.tennis_profile TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.tennis_profile TO service_role;


--
-- Name: TABLE "user"; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public."user" TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public."user" TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public."user" TO service_role;


--
-- Name: TABLE user_achievement; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_achievement TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_achievement TO authenticated;
GRANT ALL ON TABLE public.user_achievement TO service_role;


--
-- Name: TABLE user_block; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_block TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_block TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_block TO service_role;


--
-- Name: TABLE user_contact; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_contact TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_contact TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_contact TO service_role;


--
-- Name: TABLE user_device_token; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_device_token TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_device_token TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_device_token TO service_role;


--
-- Name: TABLE user_health_link; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_health_link TO anon;
GRANT ALL ON TABLE public.user_health_link TO authenticated;
GRANT ALL ON TABLE public.user_health_link TO service_role;


--
-- Name: TABLE user_industry; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_industry TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_industry TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_industry TO service_role;


--
-- Name: SEQUENCE user_industry_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.user_industry_id_seq TO anon;
GRANT ALL ON SEQUENCE public.user_industry_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.user_industry_id_seq TO service_role;


--
-- Name: TABLE user_network; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_network TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_network TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_network TO service_role;


--
-- Name: SEQUENCE user_network_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.user_network_id_seq TO anon;
GRANT ALL ON SEQUENCE public.user_network_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.user_network_id_seq TO service_role;


--
-- Name: TABLE user_payment_info; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_payment_info TO service_role;


--
-- Name: TABLE user_rating; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_rating TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_rating TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_rating TO service_role;


--
-- Name: TABLE vitality_daily_load; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.vitality_daily_load TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.vitality_daily_load TO authenticated;
GRANT ALL ON TABLE public.vitality_daily_load TO service_role;


--
-- Name: TABLE vitality_score; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.vitality_score TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.vitality_score TO authenticated;
GRANT ALL ON TABLE public.vitality_score TO service_role;


--
-- Name: TABLE wall_post; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.wall_post TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.wall_post TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.wall_post TO service_role;


--
-- Name: TABLE wall_post_gc; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.wall_post_gc TO service_role;


--
-- Name: TABLE wall_post_moderation_queue; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.wall_post_moderation_queue TO service_role;


--
-- Name: TABLE wall_post_reaction; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.wall_post_reaction TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.wall_post_reaction TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.wall_post_reaction TO service_role;


--
-- Name: TABLE wall_post_report; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.wall_post_report TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.wall_post_report TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.wall_post_report TO service_role;


--
-- Name: TABLE wall_post_tag; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.wall_post_tag TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.wall_post_tag TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.wall_post_tag TO service_role;


--
-- Name: TABLE messages; Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.messages TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.messages TO dashboard_user;
GRANT SELECT,INSERT,UPDATE ON TABLE realtime.messages TO anon;
GRANT SELECT,INSERT,UPDATE ON TABLE realtime.messages TO authenticated;
GRANT SELECT,INSERT,UPDATE ON TABLE realtime.messages TO service_role;


--
-- Name: TABLE messages_2026_08_12; Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.messages_2026_08_12 TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.messages_2026_08_12 TO dashboard_user;


--
-- Name: TABLE messages_2026_08_13; Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.messages_2026_08_13 TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.messages_2026_08_13 TO dashboard_user;


--
-- Name: TABLE messages_2026_08_14; Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.messages_2026_08_14 TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.messages_2026_08_14 TO dashboard_user;


--
-- Name: TABLE messages_2026_08_15; Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.messages_2026_08_15 TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.messages_2026_08_15 TO dashboard_user;


--
-- Name: TABLE messages_2026_08_16; Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.messages_2026_08_16 TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.messages_2026_08_16 TO dashboard_user;


--
-- Name: TABLE messages_2026_08_17; Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.messages_2026_08_17 TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.messages_2026_08_17 TO dashboard_user;


--
-- Name: TABLE messages_2026_08_18; Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.messages_2026_08_18 TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.messages_2026_08_18 TO dashboard_user;


--
-- Name: TABLE subscription; Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.subscription TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.subscription TO dashboard_user;
GRANT SELECT ON TABLE realtime.subscription TO anon;
GRANT SELECT ON TABLE realtime.subscription TO authenticated;
GRANT SELECT ON TABLE realtime.subscription TO service_role;


--
-- Name: SEQUENCE subscription_id_seq; Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON SEQUENCE realtime.subscription_id_seq TO postgres;
GRANT ALL ON SEQUENCE realtime.subscription_id_seq TO dashboard_user;
GRANT USAGE ON SEQUENCE realtime.subscription_id_seq TO anon;
GRANT USAGE ON SEQUENCE realtime.subscription_id_seq TO authenticated;
GRANT USAGE ON SEQUENCE realtime.subscription_id_seq TO service_role;


--
-- Name: TABLE buckets; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

REVOKE ALL ON TABLE storage.buckets FROM supabase_storage_admin;
GRANT ALL ON TABLE storage.buckets TO supabase_storage_admin WITH GRANT OPTION;
GRANT ALL ON TABLE storage.buckets TO anon;
GRANT ALL ON TABLE storage.buckets TO authenticated;
GRANT ALL ON TABLE storage.buckets TO service_role;
GRANT ALL ON TABLE storage.buckets TO postgres WITH GRANT OPTION;


--
-- Name: TABLE buckets_analytics; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON TABLE storage.buckets_analytics TO service_role;
GRANT ALL ON TABLE storage.buckets_analytics TO authenticated;
GRANT ALL ON TABLE storage.buckets_analytics TO anon;


--
-- Name: TABLE buckets_vectors; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT SELECT ON TABLE storage.buckets_vectors TO service_role;
GRANT SELECT ON TABLE storage.buckets_vectors TO authenticated;
GRANT SELECT ON TABLE storage.buckets_vectors TO anon;


--
-- Name: TABLE objects; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

REVOKE ALL ON TABLE storage.objects FROM supabase_storage_admin;
GRANT ALL ON TABLE storage.objects TO supabase_storage_admin WITH GRANT OPTION;
GRANT ALL ON TABLE storage.objects TO anon;
GRANT ALL ON TABLE storage.objects TO authenticated;
GRANT ALL ON TABLE storage.objects TO service_role;
GRANT ALL ON TABLE storage.objects TO postgres WITH GRANT OPTION;


--
-- Name: TABLE s3_multipart_uploads; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE storage.s3_multipart_uploads TO service_role;
GRANT SELECT ON TABLE storage.s3_multipart_uploads TO authenticated;
GRANT SELECT ON TABLE storage.s3_multipart_uploads TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE storage.s3_multipart_uploads TO postgres;


--
-- Name: TABLE s3_multipart_uploads_parts; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE storage.s3_multipart_uploads_parts TO service_role;
GRANT SELECT ON TABLE storage.s3_multipart_uploads_parts TO authenticated;
GRANT SELECT ON TABLE storage.s3_multipart_uploads_parts TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE storage.s3_multipart_uploads_parts TO postgres;


--
-- Name: TABLE vector_indexes; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT SELECT ON TABLE storage.vector_indexes TO service_role;
GRANT SELECT ON TABLE storage.vector_indexes TO authenticated;
GRANT SELECT ON TABLE storage.vector_indexes TO anon;


--
-- Name: TABLE secrets; Type: ACL; Schema: vault; Owner: supabase_admin
--

GRANT SELECT,REFERENCES,DELETE,TRUNCATE ON TABLE vault.secrets TO postgres WITH GRANT OPTION;
GRANT SELECT,DELETE ON TABLE vault.secrets TO service_role;


--
-- Name: TABLE decrypted_secrets; Type: ACL; Schema: vault; Owner: supabase_admin
--

GRANT SELECT,REFERENCES,DELETE,TRUNCATE ON TABLE vault.decrypted_secrets TO postgres WITH GRANT OPTION;
GRANT SELECT,DELETE ON TABLE vault.decrypted_secrets TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: auth; Owner: supabase_auth_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON SEQUENCES TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: auth; Owner: supabase_auth_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON FUNCTIONS TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: auth; Owner: supabase_auth_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: cron; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA cron GRANT ALL ON SEQUENCES TO postgres WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: cron; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA cron GRANT ALL ON FUNCTIONS TO postgres WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: cron; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA cron GRANT ALL ON TABLES TO postgres WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: extensions; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA extensions GRANT ALL ON SEQUENCES TO postgres WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: extensions; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA extensions GRANT ALL ON FUNCTIONS TO postgres WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: extensions; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA extensions GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO postgres WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: graphql; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: graphql; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: graphql; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: graphql_public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: graphql_public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: graphql_public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: pgsodium; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA pgsodium GRANT ALL ON SEQUENCES TO pgsodium_keyholder;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: pgsodium; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA pgsodium GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO pgsodium_keyholder;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: pgsodium_masks; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA pgsodium_masks GRANT ALL ON SEQUENCES TO pgsodium_keyiduser;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: pgsodium_masks; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA pgsodium_masks GRANT ALL ON FUNCTIONS TO pgsodium_keyiduser;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: pgsodium_masks; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA pgsodium_masks GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO pgsodium_keyiduser;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: realtime; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON SEQUENCES TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: realtime; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON FUNCTIONS TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: realtime; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: storage; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: storage; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: storage; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO service_role;


--
-- Name: issue_graphql_placeholder; Type: EVENT TRIGGER; Schema: -; Owner: supabase_admin
--

CREATE EVENT TRIGGER issue_graphql_placeholder ON sql_drop
         WHEN TAG IN ('DROP EXTENSION')
   EXECUTE FUNCTION extensions.set_graphql_placeholder();


ALTER EVENT TRIGGER issue_graphql_placeholder OWNER TO supabase_admin;

--
-- Name: issue_pg_cron_access; Type: EVENT TRIGGER; Schema: -; Owner: supabase_admin
--

CREATE EVENT TRIGGER issue_pg_cron_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_cron_access();


ALTER EVENT TRIGGER issue_pg_cron_access OWNER TO supabase_admin;

--
-- Name: issue_pg_graphql_access; Type: EVENT TRIGGER; Schema: -; Owner: supabase_admin
--

CREATE EVENT TRIGGER issue_pg_graphql_access ON ddl_command_end
         WHEN TAG IN ('CREATE FUNCTION')
   EXECUTE FUNCTION extensions.grant_pg_graphql_access();


ALTER EVENT TRIGGER issue_pg_graphql_access OWNER TO supabase_admin;

--
-- Name: issue_pg_net_access; Type: EVENT TRIGGER; Schema: -; Owner: supabase_admin
--

CREATE EVENT TRIGGER issue_pg_net_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_net_access();


ALTER EVENT TRIGGER issue_pg_net_access OWNER TO supabase_admin;

--
-- Name: pgrst_ddl_watch; Type: EVENT TRIGGER; Schema: -; Owner: supabase_admin
--

CREATE EVENT TRIGGER pgrst_ddl_watch ON ddl_command_end
   EXECUTE FUNCTION extensions.pgrst_ddl_watch();


ALTER EVENT TRIGGER pgrst_ddl_watch OWNER TO supabase_admin;

--
-- Name: pgrst_drop_watch; Type: EVENT TRIGGER; Schema: -; Owner: supabase_admin
--

CREATE EVENT TRIGGER pgrst_drop_watch ON sql_drop
   EXECUTE FUNCTION extensions.pgrst_drop_watch();


ALTER EVENT TRIGGER pgrst_drop_watch OWNER TO supabase_admin;

--
-- PostgreSQL database dump complete
--

\unrestrict 7BlJnFxfvqmJomhALlsqgvOrJZQtS9WsUGPR3FV0FT0AX6k8ivcYeZfjp93vUmw

