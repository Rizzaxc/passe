--
-- PostgreSQL database dump
--

\restrict dXnchi3sijuOVkXgi6HCzTdWqATIO4RDKYhAte2aXmfRtJAYZtkbJR90kFB56T1

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
-- Name: pg_graphql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_graphql WITH SCHEMA graphql;


--
-- Name: EXTENSION pg_graphql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_graphql IS 'pg_graphql: GraphQL support';


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
-- Name: activity_payment_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.activity_payment_type AS ENUM (
    'manual',
    'da'
);


ALTER TYPE public.activity_payment_type OWNER TO postgres;

--
-- Name: TYPE activity_payment_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TYPE public.activity_payment_type IS 'How prepayment for a scheduled activity is collected: ''manual'' = out-of-band (cash / bank transfer organised by the captain); ''da'' = held by the app via the Đá ledger.';


--
-- Name: country; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.country AS ENUM (
    'VN'
);


ALTER TYPE public.country OWNER TO postgres;

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
-- Name: lobby_feed_item_kind; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.lobby_feed_item_kind AS ENUM (
    'update',
    'personal',
    'system',
    'poll',
    'photo'
);


ALTER TYPE public.lobby_feed_item_kind OWNER TO postgres;

--
-- Name: lobby_match_result; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.lobby_match_result AS ENUM (
    'win',
    'loss',
    'practice'
);


ALTER TYPE public.lobby_match_result OWNER TO postgres;

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
-- Name: action; Type: TYPE; Schema: realtime; Owner: supabase_admin
--

CREATE TYPE realtime.action AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE',
    'ERROR'
);


ALTER TYPE realtime.action OWNER TO supabase_admin;

--
-- Name: equality_op; Type: TYPE; Schema: realtime; Owner: supabase_admin
--

CREATE TYPE realtime.equality_op AS ENUM (
    'eq',
    'neq',
    'lt',
    'lte',
    'gt',
    'gte',
    'in'
);


ALTER TYPE realtime.equality_op OWNER TO supabase_admin;

--
-- Name: user_defined_filter; Type: TYPE; Schema: realtime; Owner: supabase_admin
--

CREATE TYPE realtime.user_defined_filter AS (
	column_name text,
	op realtime.equality_op,
	value text
);


ALTER TYPE realtime.user_defined_filter OWNER TO supabase_admin;

--
-- Name: wal_column; Type: TYPE; Schema: realtime; Owner: supabase_admin
--

CREATE TYPE realtime.wal_column AS (
	name text,
	type_name text,
	type_oid oid,
	value jsonb,
	is_pkey boolean,
	is_selectable boolean
);


ALTER TYPE realtime.wal_column OWNER TO supabase_admin;

--
-- Name: wal_rls; Type: TYPE; Schema: realtime; Owner: supabase_admin
--

CREATE TYPE realtime.wal_rls AS (
	wal jsonb,
	is_rls_enabled boolean,
	subscription_ids uuid[],
	errors text[]
);


ALTER TYPE realtime.wal_rls OWNER TO supabase_admin;

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

CREATE FUNCTION public.activity_confirmation_status(p_activity_id uuid) RETURNS TABLE(confirmed_count integer, maybe_count integer, threshold integer, my_attendance text, activity_confirmed boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_threshold int; v_going int; v_maybe int; v_mine text;
BEGIN
    SELECT a.confirmation_threshold INTO v_threshold FROM public.activity a WHERE a.id = p_activity_id;
    SELECT COUNT(*) FILTER (WHERE attendance = 'going')::int, COUNT(*) FILTER (WHERE attendance = 'maybe')::int
        INTO v_going, v_maybe FROM public.activity_confirmation WHERE activity_id = p_activity_id;
    SELECT attendance::text INTO v_mine FROM public.activity_confirmation WHERE activity_id = p_activity_id AND user_id = auth.uid();
    RETURN QUERY SELECT COALESCE(v_going,0), COALESCE(v_maybe,0), v_threshold, v_mine, (v_threshold IS NULL OR COALESCE(v_going,0) >= v_threshold);
END; $$;


ALTER FUNCTION public.activity_confirmation_status(p_activity_id uuid) OWNER TO postgres;

--
-- Name: activity_health_data(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.activity_health_data(p_sport_id bigint) RETURNS TABLE(activity_id uuid, start_time timestamp with time zone, end_time timestamp with time zone, duration_minutes integer, location_label text, source text, steps integer, distance_meters real, active_calories real, avg_heart_rate integer, max_heart_rate integer, min_heart_rate integer, hrv_sdnn_ms real, hrv_rmssd_ms real, hr_zone_easy_seconds integer, hr_zone_moderate_seconds integer, hr_zone_hard_seconds integer, training_load real, effort_score real, workout_type text, recorded_at timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  RETURN QUERY
  SELECT
    m.activity_id,
    a.start_time,
    a.end_time,
    CASE WHEN a.end_time IS NOT NULL
      THEN (EXTRACT(EPOCH FROM (a.end_time - a.start_time)) / 60)::int
      ELSE NULL END AS duration_minutes,
    loc.name AS location_label,
    CASE
      WHEN a.professional_booking_id IS NOT NULL THEN 'professional'
      WHEN a.lobby_id IS NOT NULL THEN 'lobby'
      ELSE 'self'
    END AS source,
    m.steps,
    m.distance_meters,
    m.active_calories,
    m.avg_heart_rate,
    m.max_heart_rate,
    m.min_heart_rate,
    m.hrv_sdnn_ms,
    m.hrv_rmssd_ms,
    m.hr_zone_easy_seconds,
    m.hr_zone_moderate_seconds,
    m.hr_zone_hard_seconds,
    m.training_load,
    m.effort_score,
    m.workout_type,
    m.recorded_at
  FROM public.activity_health_metrics m
  JOIN public.activity a ON a.id = m.activity_id
  LEFT JOIN public.location loc ON loc.id = a.location_id
  WHERE m.user_id = v_uid
    AND m.dismissed = false
    AND a.sport_id = p_sport_id
  ORDER BY a.start_time DESC;
END;
$$;


ALTER FUNCTION public.activity_health_data(p_sport_id bigint) OWNER TO postgres;

--
-- Name: activity_is_confirmed(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.activity_is_confirmed(p_activity_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_threshold int; v_count int;
BEGIN
    SELECT a.confirmation_threshold INTO v_threshold FROM public.activity a WHERE a.id = p_activity_id;
    IF NOT FOUND THEN RETURN false; END IF;
    IF v_threshold IS NULL THEN RETURN true; END IF;
    SELECT COUNT(*) INTO v_count FROM public.activity_confirmation WHERE activity_id = p_activity_id AND attendance = 'going';
    RETURN v_count >= v_threshold;
END; $$;


ALTER FUNCTION public.activity_is_confirmed(p_activity_id uuid) OWNER TO postgres;

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
-- Name: create_lobby_with_location(text, integer, text, jsonb, jsonb, uuid, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text DEFAULT 'discoverable'::text, p_playtime jsonb DEFAULT NULL::jsonb, p_details jsonb DEFAULT NULL::jsonb, p_home_ground_id uuid DEFAULT NULL::uuid, p_location_name text DEFAULT NULL::text, p_street_number text DEFAULT NULL::text, p_street_name text DEFAULT NULL::text, p_district text DEFAULT NULL::text, p_city text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'extensions'
    AS $$
DECLARE
    v_user_id  uuid;
    v_loc_id   uuid;
    v_lobby_id uuid;
    v_result   jsonb;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF p_home_ground_id IS NOT NULL THEN
        v_loc_id := p_home_ground_id;
    ELSIF p_location_name IS NOT NULL OR p_street_name IS NOT NULL OR p_city IS NOT NULL THEN
        INSERT INTO public.location (name, street_number, street_name, district, city)
        VALUES (
            NULLIF(TRIM(COALESCE(p_location_name, '')), ''),
            NULLIF(p_street_number, '')::integer,
            NULLIF(p_street_name,   ''),
            NULLIF(p_district,      ''),
            NULLIF(p_city,          '')
        )
        RETURNING id INTO v_loc_id;
    END IF;

    INSERT INTO public.lobby (name, sport_id, visibility, playtime, details, home_ground, captain_id)
    VALUES (
        p_name,
        p_sport_id,
        p_visibility::public.lobby_visibility,
        p_playtime,
        p_details,
        v_loc_id,
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


ALTER FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid, p_location_name text, p_street_number text, p_street_name text, p_district text, p_city text) OWNER TO postgres;

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

  -- Map seed to starting Elo
  v_elo := case NEW.elo_seed
    when 'beginner' then  700
    when 'casual'   then 1000
    when 'tryhard'  then 1300
    else                 1000
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
-- Name: get_my_lobby_ids(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_my_lobby_ids() RETURNS SETOF uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT lobby_id FROM public.lobby_member WHERE user_id = auth.uid();
$$;


ALTER FUNCTION public.get_my_lobby_ids() OWNER TO postgres;

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
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  RETURN QUERY
  SELECT
    a.id,
    a.start_time,
    a.end_time,
    a.sport_id,
    CASE
      WHEN a.professional_booking_id IS NOT NULL THEN 'professional'
      WHEN a.lobby_id IS NOT NULL THEN 'lobby'
      ELSE 'self'
    END AS source,
    EXISTS (
      SELECT 1 FROM public.activity_confirmation ac
      WHERE ac.activity_id = a.id AND ac.user_id = v_uid
    ) AS confirmed
  FROM public.activity a
  WHERE a.end_time IS NOT NULL
    AND a.end_time < now()
    AND a.end_time >= p_window_start
    AND (
      a.user_id = v_uid
      OR EXISTS (
        SELECT 1 FROM public.activity_confirmation ac
        WHERE ac.activity_id = a.id AND ac.user_id = v_uid
      )
      OR (
        a.professional_booking_id IS NOT NULL
        AND EXISTS (
          SELECT 1 FROM public.professional_booking pb
          WHERE pb.id = a.professional_booking_id
            AND (
              pb.client_user_id = v_uid
              OR EXISTS (
                SELECT 1 FROM public.booking_additional_users bau
                WHERE bau.booking_id = pb.id AND bau.user_id = v_uid
              )
            )
        )
      )
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.activity_health_metrics m
      WHERE m.activity_id = a.id AND m.user_id = v_uid
    )
  ORDER BY a.end_time DESC;
END;
$$;


ALTER FUNCTION public.health_capture_candidates(p_window_start timestamp with time zone) OWNER TO postgres;

--
-- Name: home_challenger_lobby_data(uuid, bigint, integer, character varying[], integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_mmr_window integer DEFAULT 200, p_page_size integer DEFAULT 10, p_page_number integer DEFAULT 1) RETURNS TABLE(id uuid, name text, homeground_name text, playtime jsonb, details jsonb, visibility public.lobby_visibility, member_count integer, lobby_mmr integer, favorability text, profile_compat_score numeric, match_factors text[])
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
    SELECT l.mmr, l.network_ids, l.active_network_ids, l.industry_ids, l.playtime_keys, loc.lat, loc.lon
      INTO v_mmr, v_net, v_active, v_ind, v_pt, v_lat, v_lon
      FROM public.lobby l
      LEFT JOIN public.location loc ON l.home_ground = loc.id
     WHERE l.id = p_context_lobby_id;
    v_mmr := COALESCE(v_mmr, 1000);

    SELECT count(*) INTO v_cnt
      FROM public.lobby l
      JOIN public.location loc ON l.home_ground = loc.id
     WHERE l.sport_id = p_sport_id AND l.open_to_challengers AND l.visibility <> 'private'
       AND loc.city_cluster = p_city AND l.id <> p_context_lobby_id
       AND l.id NOT IN (SELECT public.get_my_lobby_ids())
       AND l.mmr BETWEEN v_mmr - v_window AND v_mmr + v_window;
    IF v_cnt < p_page_size THEN
        v_window := v_window * 2;
        SELECT count(*) INTO v_cnt
          FROM public.lobby l
          JOIN public.location loc ON l.home_ground = loc.id
         WHERE l.sport_id = p_sport_id AND l.open_to_challengers AND l.visibility <> 'private'
           AND loc.city_cluster = p_city AND l.id <> p_context_lobby_id
           AND l.id NOT IN (SELECT public.get_my_lobby_ids())
           AND l.mmr BETWEEN v_mmr - v_window AND v_mmr + v_window;
        IF v_cnt < p_page_size THEN
            v_window := 1000000;
        END IF;
    END IF;

    RETURN QUERY
    WITH candidate AS (
        SELECT
            l.id, l.name, loc.name AS homeground_name, l.playtime, l.details, l.visibility,
            l.member_count, l.mmr AS cand_mmr,
            l.network_ids, l.active_network_ids, l.industry_ids, l.playtime_keys,
            loc.district, loc.lat, loc.lon
        FROM public.lobby l
        JOIN public.location loc ON l.home_ground = loc.id
        WHERE l.sport_id = p_sport_id AND l.open_to_challengers AND l.visibility <> 'private'
          AND loc.city_cluster = p_city AND l.id <> p_context_lobby_id
          AND l.id NOT IN (SELECT public.get_my_lobby_ids())
          AND l.mmr BETWEEN v_mmr - v_window AND v_mmr + v_window
    ),
    scored AS (
        SELECT
            c.*,
            1.0 / (1.0 + power(10.0, ((c.cand_mmr + c_home_adv - v_mmr)::numeric / 400.0))) AS away_expected,
            (c.network_ids && v_net)            AS f_network,
            ((SELECT count(*) FROM (SELECT unnest(c.playtime_keys) INTERSECT SELECT unnest(v_pt)) x) > 0) AS f_playtime,
            ((c.district = ANY(p_districts))
                OR (v_lat IS NOT NULL AND c.lat IS NOT NULL
                    AND abs(c.lat - v_lat) + abs(c.lon - v_lon) < 0.1)) AS f_location,
            (c.industry_ids && v_ind)           AS f_industry,
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
        ], NULL) AS match_factors
    FROM scored s
    ORDER BY (
        c_w_compat * (s.compat_raw / 9.0)
      + c_w_even * (1.0 - 2.0 * abs(s.away_expected - 0.5))
    ) DESC
    LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
END;
$$;


ALTER FUNCTION public.home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_mmr_window integer, p_page_size integer, p_page_number integer) OWNER TO postgres;

--
-- Name: home_teammate_lobby_data(bigint, jsonb, integer, character varying[], integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_page_size integer DEFAULT 10, p_page_number integer DEFAULT 1) RETURNS TABLE(id uuid, name text, homeground_name text, playtime jsonb, details jsonb, visibility public.lobby_visibility, member_count integer, timeslot_compat_score integer, profile_compat_score numeric, match_factors text[], already_requested boolean)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
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
                JOIN
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
          AND loc.city_cluster = p_city
          AND l.id NOT IN (SELECT public.get_my_lobby_ids())
          AND (p_districts IS NULL OR cardinality(p_districts) = 0 OR loc.district = ANY(p_districts))
          AND (p_timeslots = '{}'::jsonb OR ts.ts_score >= 4)
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


ALTER FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_page_size integer, p_page_number integer) OWNER TO postgres;

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
-- Name: lobby_feed_data(uuid, integer, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.lobby_feed_data(p_lobby_id uuid, p_page_size integer DEFAULT 50, p_before timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS TABLE(id uuid, author_id uuid, author_username character varying, kind public.lobby_feed_item_kind, payload jsonb, created_at timestamp with time zone, poll_tallies jsonb)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    RETURN QUERY
        SELECT fi.id,
               fi.author_id,
               u.username                             AS author_username,
               fi.kind,
               fi.payload,
               fi.created_at,
               -- Poll tallies: {option_index: count, …}. Null for non-polls.
               CASE WHEN fi.kind = 'poll' THEN
                   (SELECT jsonb_object_agg(option_index::text, c)
                    FROM (
                        SELECT option_index, COUNT(*) AS c
                        FROM public.lobby_feed_poll_vote v
                        WHERE v.feed_item_id = fi.id
                        GROUP BY option_index
                    ) t)
               END                                    AS poll_tallies
        FROM public.lobby_feed_item fi
                 LEFT JOIN public."user" u ON u.id = fi.author_id
        WHERE fi.lobby_id = p_lobby_id
          AND (p_before IS NULL OR fi.created_at < p_before)
        ORDER BY fi.created_at DESC
        LIMIT p_page_size;
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
        SELECT m.id,
               m.activity_id,
               m.opponent_lobby_id,
               ol.name                                AS opponent_name,
               m.opponent_tag,
               m.result,
               m.sets,
               u.username                             AS mvp_username,
               m.note,
               m.venue_label,
               m.played_at,
               m.duration_label,
               ARRAY(
                   SELECT mu.username
                   FROM public.lobby_member lm
                            JOIN public."user" mu ON mu.id = lm.user_id
                   WHERE lm.lobby_id = m.lobby_id
               )                                      AS member_usernames,
               m.referee_booking_id,
               ref.display_name                       AS referee_name
        FROM public.lobby_match m
                 LEFT JOIN public.lobby ol ON ol.id = m.opponent_lobby_id
                 LEFT JOIN public."user" u ON u.id = m.mvp_user_id
                 LEFT JOIN public.professional_booking rb
                     ON rb.id = m.referee_booking_id
                 LEFT JOIN public.professional ref
                     ON ref.id = rb.professional_id
        WHERE m.lobby_id = p_lobby_id
        ORDER BY m.played_at DESC
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
        FROM public.professional_booking pb
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
-- Name: my_schedule_data(bigint, timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.my_schedule_data(p_sport_id bigint, p_from timestamp with time zone, p_to timestamp with time zone) RETURNS TABLE(id uuid, start_time timestamp with time zone, end_time timestamp with time zone, title text, meta text, tone text, recurrence_day_of_week smallint)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid();
BEGIN
    IF v_uid IS NULL THEN RETURN; END IF;
    RETURN QUERY
    SELECT a.id, a.start_time, a.end_time,
           l.name::text,
           (CASE WHEN loc.name IS NOT NULL AND loc.name <> '' THEN loc.name || ' · ' ELSE '' END || l.member_count || ' người')::text,
           'sport'::text, a.recurrence_day_of_week
    FROM public.activity a
    JOIN public.lobby l ON l.id = a.lobby_id
    LEFT JOIN public.location loc ON loc.id = COALESCE(a.location_id, l.home_ground)
    WHERE a.sport_id = p_sport_id
      AND a.lobby_id IN (SELECT lobby_id FROM public.lobby_member WHERE user_id = v_uid)
      AND (a.recurrence_day_of_week IS NOT NULL OR (a.start_time >= p_from AND a.start_time <= p_to))
    UNION ALL
    SELECT a.id, a.start_time, a.end_time,
           (p.display_name || ' · ' || ps.service_type)::text,
           COALESCE(loc.name, '')::text, 'coach'::text, a.recurrence_day_of_week
    FROM public.activity a
    JOIN public.professional_booking pb ON pb.id = a.professional_booking_id
    JOIN public.professional p ON p.id = pb.professional_id
    JOIN public.professional_service ps ON ps.id = pb.service_id
    LEFT JOIN public.location loc ON loc.id = COALESCE(a.location_id, pb.location_id)
    WHERE a.sport_id = p_sport_id AND pb.client_user_id = v_uid
      AND (a.recurrence_day_of_week IS NOT NULL OR (a.start_time >= p_from AND a.start_time <= p_to));
END; $$;


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
-- Name: professional_booking_review_updated_trigger_fn(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.professional_booking_review_updated_trigger_fn() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
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


ALTER FUNCTION public.professional_booking_review_updated_trigger_fn() OWNER TO postgres;

--
-- Name: search_locations(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.search_locations(search_term text) RETURNS TABLE(id uuid, name text, full_address text, street_number integer, street_name text, district text, city text)
    LANGUAGE plpgsql STABLE
    SET search_path TO ''
    AS $$
BEGIN
    IF char_length(search_term) < 8 THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        l.id,
        l.name,
        l.full_address,
        l.street_number,
        l.street_name,
        l.district,
        l.city
    FROM public.location l
    WHERE
        extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.name))) > 0.3
        OR extensions.word_similarity(LOWER(search_term), LOWER(l.name)) > 0.3
        OR extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.full_address))) > 0.3
        OR extensions.word_similarity(LOWER(search_term), LOWER(l.full_address)) > 0.3
    ORDER BY
        GREATEST(
            extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.name))),
            extensions.word_similarity(LOWER(search_term), LOWER(l.name)),
            extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.full_address))),
            extensions.word_similarity(LOWER(search_term), LOWER(l.full_address))
        ) DESC
    LIMIT 10;
END;
$$;


ALTER FUNCTION public.search_locations(search_term text) OWNER TO postgres;

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
-- Name: apply_rls(jsonb, integer); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
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


ALTER FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) OWNER TO supabase_admin;

--
-- Name: broadcast_changes(text, text, text, text, text, record, record, text); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
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


ALTER FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text) OWNER TO supabase_admin;

--
-- Name: build_prepared_statement_sql(text, regclass, realtime.wal_column[]); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
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


ALTER FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) OWNER TO supabase_admin;

--
-- Name: cast(text, regtype); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
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


ALTER FUNCTION realtime."cast"(val text, type_ regtype) OWNER TO supabase_admin;

--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
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


ALTER FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) OWNER TO supabase_admin;

--
-- Name: is_visible_through_filters(realtime.wal_column[], realtime.user_defined_filter[]); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
    /*
    Should the record be visible (true) or filtered out (false) after *filters* are applied
    */
        select
            -- Default to allowed when no filters present
            $2 is null -- no filters. this should not happen because subscriptions has a default
            or array_length($2, 1) is null -- array length of an empty array is null
            or bool_and(
                coalesce(
                    realtime.check_equality_op(
                        op:=f.op,
                        type_:=coalesce(
                            col.type_oid::regtype, -- null when wal2json version <= 2.4
                            col.type_name::regtype
                        ),
                        -- cast jsonb to text
                        val_1:=col.value #>> '{}',
                        val_2:=f.value
                    ),
                    false -- if null, filter does not match
                )
            )
        from
            unnest(filters) f
            join unnest(columns) col
                on f.column_name = col.name;
    $_$;


ALTER FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) OWNER TO supabase_admin;

--
-- Name: list_changes(name, name, integer, integer); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
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


ALTER FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) OWNER TO supabase_admin;

--
-- Name: quote_wal2json(regclass); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
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


ALTER FUNCTION realtime.quote_wal2json(entity regclass) OWNER TO supabase_admin;

--
-- Name: send(jsonb, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  generated_id uuid;
  final_payload jsonb;
BEGIN
  BEGIN
    -- Generate a new UUID for the id
    generated_id := gen_random_uuid();

    -- Check if payload has an 'id' key, if not, add the generated UUID
    IF payload ? 'id' THEN
      final_payload := payload;
    ELSE
      final_payload := jsonb_set(payload, '{id}', to_jsonb(generated_id));
    END IF;

    -- Set the topic configuration
    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    -- Attempt to insert the message
    INSERT INTO realtime.messages (id, payload, event, topic, private, extension)
    VALUES (generated_id, final_payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      -- Capture and notify the error
      RAISE WARNING 'ErrorSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


ALTER FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean) OWNER TO supabase_admin;

--
-- Name: send_binary(bytea, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
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
      RAISE WARNING 'ErrorSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


ALTER FUNCTION realtime.send_binary(payload bytea, event text, topic text, private boolean) OWNER TO supabase_admin;

--
-- Name: subscription_check_filters(); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.subscription_check_filters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
    col_names text[] = coalesce(
            array_agg(c.column_name order by c.ordinal_position),
            '{}'::text[]
        )
        from
            information_schema.columns c
        where
            format('%I.%I', c.table_schema, c.table_name)::regclass = new.entity
            and pg_catalog.has_column_privilege(
                (new.claims ->> 'role'),
                format('%I.%I', c.table_schema, c.table_name)::regclass,
                c.column_name,
                'SELECT'
            );
    table_col_names text[] = coalesce(
            array_agg(pa.attname),
            '{}'::text[]
        )
        from
            pg_attribute pa
        where
            pa.attrelid = new.entity
            and pa.attnum > 0;
    filter realtime.user_defined_filter;
    col_type regtype;
    in_val jsonb;
    selected_col text;
begin
    for filter in select * from unnest(new.filters) loop
        -- Filtered column is valid
        if not filter.column_name = any(col_names) then
            raise exception 'invalid column for filter %', filter.column_name;
        end if;

        -- Type is sanitized and safe for string interpolation
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
        else
            -- raises an exception if value is not coercable to type
            perform realtime.cast(filter.value, col_type);
        end if;
    end loop;

    -- Validate that selected_columns reference columns the role can SELECT
    if new.selected_columns is not null then
        for selected_col in select * from unnest(new.selected_columns) loop
            if not selected_col = any(col_names) then
                raise exception 'invalid column for select %', selected_col;
            end if;
        end loop;
    end if;

    -- Apply consistent order to filters so the unique constraint on
    -- (subscription_id, entity, filters) can't be tricked by a different filter order
    new.filters = coalesce(
        array_agg(f order by f.column_name, f.op, f.value),
        '{}'
    ) from unnest(new.filters) f;

    -- Normalize selected_columns order so ARRAY['a','b'] and ARRAY['b','a'] are
    -- treated as the same subscription group in apply_rls
    new.selected_columns = (
        select array_agg(c order by c)
        from unnest(new.selected_columns) c
    );

    return new;
end;
$$;


ALTER FUNCTION realtime.subscription_check_filters() OWNER TO supabase_admin;

--
-- Name: to_regrole(text); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.to_regrole(role_name text) RETURNS regrole
    LANGUAGE sql IMMUTABLE
    AS $$ select role_name::regrole $$;


ALTER FUNCTION realtime.to_regrole(role_name text) OWNER TO supabase_admin;

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
-- Name: wal2json_escape_identifier(text); Type: FUNCTION; Schema: realtime; Owner: supabase_admin
--

CREATE FUNCTION realtime.wal2json_escape_identifier(name text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
  -- Prefix `\`, `,`, `.`, and any whitespace with `\`
  SELECT regexp_replace(name, '([\\,.[:space:]])', '\\\1', 'g')
$$;


ALTER FUNCTION realtime.wal2json_escape_identifier(name text) OWNER TO supabase_admin;

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
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
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
    CONSTRAINT achievement_criteria_valid CHECK (((criteria IS NULL) OR (((criteria ->> 'source'::text) = ANY (ARRAY['daily'::text, 'activity'::text, 'special'::text])) AND ((criteria ->> 'agg'::text) = ANY (ARRAY['sum'::text, 'count'::text, 'max'::text, 'session_streak'::text, 'special'::text])) AND (((criteria ->> 'window'::text) IS NULL) OR ((criteria ->> 'window'::text) = ANY (ARRAY['day'::text, 'week'::text, 'month'::text, 'all_time'::text]))) AND ((repeatable IS NOT TRUE) OR ((criteria ->> 'window'::text) = ANY (ARRAY['week'::text, 'month'::text]))) AND (((criteria ->> 'agg'::text) <> 'session_streak'::text) OR (((criteria ->> 'source'::text) = 'activity'::text) AND (criteria ? 'session_min'::text))) AND (((criteria ->> 'source'::text) = 'special'::text) = ((criteria ->> 'agg'::text) = 'special'::text))))),
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
    professional_booking_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    location_id uuid,
    prepayment_required boolean DEFAULT false NOT NULL,
    payment_type public.activity_payment_type,
    prepayment_amount numeric(10,2),
    confirmation_threshold integer,
    confirmation_deadline timestamp with time zone,
    recurrence_day_of_week smallint,
    CONSTRAINT activity_confirmation_deadline_validity CHECK (((confirmation_deadline IS NULL) OR (confirmation_deadline < start_time))),
    CONSTRAINT activity_confirmation_threshold_validity CHECK (((confirmation_threshold IS NULL) OR (confirmation_threshold > 0))),
    CONSTRAINT activity_prepayment_terms_validity CHECK ((((prepayment_required = false) AND (payment_type IS NULL) AND (prepayment_amount IS NULL)) OR ((prepayment_required = true) AND (payment_type IS NOT NULL) AND (prepayment_amount IS NOT NULL) AND (prepayment_amount > (0)::numeric)))),
    CONSTRAINT activity_recurrence_day_validity CHECK (((recurrence_day_of_week IS NULL) OR ((recurrence_day_of_week >= 0) AND (recurrence_day_of_week <= 6)))),
    CONSTRAINT activity_source_exclusivity CHECK ((NOT ((lobby_id IS NOT NULL) AND (professional_booking_id IS NOT NULL)))),
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
-- Name: booking_additional_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.booking_additional_users (
    booking_id uuid NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.booking_additional_users OWNER TO postgres;

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
    playtime_keys text[] DEFAULT '{}'::text[] NOT NULL
);


ALTER TABLE public.lobby OWNER TO postgres;

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
-- Name: lobby_feed_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lobby_feed_item (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lobby_id uuid NOT NULL,
    author_id uuid,
    kind public.lobby_feed_item_kind NOT NULL,
    payload jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT lobby_feed_item_payload_shape CHECK ((((kind = 'update'::public.lobby_feed_item_kind) AND (payload ? 'title'::text) AND (payload ? 'kind'::text) AND (payload ? 'tone'::text) AND (payload ? 'fields'::text)) OR ((kind = 'personal'::public.lobby_feed_item_kind) AND (payload ? 'action_kind'::text)) OR ((kind = 'system'::public.lobby_feed_item_kind) AND (payload ? 'text'::text)) OR ((kind = 'poll'::public.lobby_feed_item_kind) AND (payload ? 'question'::text) AND (payload ? 'options'::text)) OR ((kind = 'photo'::public.lobby_feed_item_kind) AND (payload ? 'storage_path'::text))))
);


ALTER TABLE public.lobby_feed_item OWNER TO postgres;

--
-- Name: TABLE lobby_feed_item; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.lobby_feed_item IS 'Action-stream entries for a lobby''s activity tab. Payload shape varies by kind — see CHECK constraint and lib/manage_tab/lobby_section/activity/feed.dart for the canonical schemas.';


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
    CONSTRAINT lobby_match_referee_required_for_challenge CHECK (((opponent_lobby_id IS NULL) OR (referee_booking_id IS NOT NULL))),
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
    lobby_id uuid NOT NULL
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
-- Name: location; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.location (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    external_id text,
    name text NOT NULL,
    full_address text,
    street_number integer,
    street_name text,
    district text,
    city text,
    lat double precision,
    lon double precision,
    tags text[] DEFAULT '{}'::text[] NOT NULL,
    city_cluster bigint
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
    CONSTRAINT professional_experience_years_check CHECK ((experience_years >= 0)),
    CONSTRAINT professional_sports_check CHECK ((array_length(sports, 1) > 0))
);


ALTER TABLE public.professional OWNER TO postgres;

--
-- Name: professional_booking; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.professional_booking (
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
    CONSTRAINT booking_times_validity CHECK ((booking_time_end > booking_time_start)),
    CONSTRAINT professional_booking_agreed_rate_check CHECK ((agreed_rate >= (0)::numeric)),
    CONSTRAINT professional_booking_status_check CHECK ((status <> 'completed'::public.professional_booking_status))
);


ALTER TABLE public.professional_booking OWNER TO postgres;

--
-- Name: professional_booking_review; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.professional_booking_review (
    booking_id uuid NOT NULL,
    reviewer_user_id uuid NOT NULL,
    professional_id uuid NOT NULL,
    rating numeric(2,1) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT professional_booking_review_rating_check CHECK (((rating >= 0.5) AND (rating <= 5.0) AND ((rating * (2)::numeric) = floor((rating * (2)::numeric)))))
);


ALTER TABLE public.professional_booking_review OWNER TO postgres;

--
-- Name: professional_service; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.professional_service (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    professional_id uuid NOT NULL,
    sport_id bigint NOT NULL,
    service_type text NOT NULL,
    service_description text,
    hourly_rate numeric(10,2),
    min_duration_minutes integer,
    max_participants integer,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT professional_service_hourly_rate_check CHECK ((hourly_rate >= (0)::numeric)),
    CONSTRAINT professional_service_max_participants_check CHECK ((max_participants >= 1)),
    CONSTRAINT professional_service_min_duration_minutes_check CHECK ((min_duration_minutes > 0))
);


ALTER TABLE public.professional_service OWNER TO postgres;

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
-- Name: schema_migrations; Type: TABLE; Schema: realtime; Owner: supabase_admin
--

CREATE TABLE realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


ALTER TABLE realtime.schema_migrations OWNER TO supabase_admin;

--
-- Name: subscription; Type: TABLE; Schema: realtime; Owner: supabase_admin
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


ALTER TABLE realtime.subscription OWNER TO supabase_admin;

--
-- Name: subscription_id_seq; Type: SEQUENCE; Schema: realtime; Owner: supabase_admin
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
-- Name: booking_additional_users booking_additional_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking_additional_users
    ADD CONSTRAINT booking_additional_users_pkey PRIMARY KEY (booking_id, user_id);


--
-- Name: daily_health_summary daily_health_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_health_summary
    ADD CONSTRAINT daily_health_summary_pkey PRIMARY KEY (user_id, date);


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
-- Name: lobby_feed_item lobby_feed_item_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_feed_item
    ADD CONSTRAINT lobby_feed_item_pkey PRIMARY KEY (id);


--
-- Name: lobby_feed_poll_vote lobby_feed_poll_vote_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_feed_poll_vote
    ADD CONSTRAINT lobby_feed_poll_vote_pkey PRIMARY KEY (feed_item_id, user_id);


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
-- Name: pickleball_profile pickleball_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pickleball_profile
    ADD CONSTRAINT pickleball_profile_pkey PRIMARY KEY (user_id);


--
-- Name: professional_booking professional_booking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional_booking
    ADD CONSTRAINT professional_booking_pkey PRIMARY KEY (id);


--
-- Name: professional_booking_review professional_booking_review_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional_booking_review
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
-- Name: messages messages_payload_exclusive; Type: CHECK CONSTRAINT; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE realtime.messages
    ADD CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL))) NOT VALID;


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: realtime; Owner: supabase_realtime_admin
--

ALTER TABLE ONLY realtime.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: subscription pk_subscription; Type: CONSTRAINT; Schema: realtime; Owner: supabase_admin
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
-- Name: activity_confirmation_user_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activity_confirmation_user_idx ON public.activity_confirmation USING btree (user_id);


--
-- Name: basketball_profile_pitch_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX basketball_profile_pitch_idx ON public.basketball_profile USING gin (pitch);


--
-- Name: basketball_profile_position_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX basketball_profile_position_idx ON public.basketball_profile USING gin ("position");


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

CREATE INDEX idx_booking_additional_users_booking_id ON public.booking_additional_users USING btree (booking_id);


--
-- Name: idx_booking_additional_users_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_booking_additional_users_user_id ON public.booking_additional_users USING btree (user_id);


--
-- Name: idx_bookings_client_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_client_user_id ON public.professional_booking USING btree (client_user_id);


--
-- Name: idx_bookings_professional_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_professional_id ON public.professional_booking USING btree (professional_id);


--
-- Name: idx_bookings_service_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_service_id ON public.professional_booking USING btree (service_id);


--
-- Name: idx_bookings_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_status ON public.professional_booking USING btree (status);


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

CREATE INDEX idx_professional_booking_location_id ON public.professional_booking USING btree (location_id);


--
-- Name: idx_professional_review_professional_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_professional_review_professional_id ON public.professional_booking_review USING btree (professional_id);


--
-- Name: idx_professional_review_reviewer_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_professional_review_reviewer_user_id ON public.professional_booking_review USING btree (reviewer_user_id);


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
-- Name: lobby_feed_item_lobby_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX lobby_feed_item_lobby_idx ON public.lobby_feed_item USING btree (lobby_id, created_at DESC);


--
-- Name: lobby_match_lobby_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX lobby_match_lobby_idx ON public.lobby_match USING btree (lobby_id, played_at DESC);


--
-- Name: lobby_open_challenger_mmr_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX lobby_open_challenger_mmr_idx ON public.lobby USING btree (sport_id, mmr) WHERE open_to_challengers;


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
-- Name: soccer_profile_pitch_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX soccer_profile_pitch_idx ON public.soccer_profile USING gin (pitch);


--
-- Name: soccer_profile_position_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX soccer_profile_position_idx ON public.soccer_profile USING gin ("position");


--
-- Name: user_rating_user_sport_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_rating_user_sport_idx ON public.user_rating USING btree (user_id, sport);


--
-- Name: ix_realtime_subscription_entity; Type: INDEX; Schema: realtime; Owner: supabase_admin
--

CREATE INDEX ix_realtime_subscription_entity ON realtime.subscription USING btree (entity);


--
-- Name: messages_inserted_at_topic_index; Type: INDEX; Schema: realtime; Owner: supabase_realtime_admin
--

CREATE INDEX messages_inserted_at_topic_index ON ONLY realtime.messages USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: subscription_subscription_id_entity_filters_action_filter_selec; Type: INDEX; Schema: realtime; Owner: supabase_admin
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
-- Name: users on_auth_user_created; Type: TRIGGER; Schema: auth; Owner: supabase_auth_admin
--

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.new_user_created_trigger_fn();


--
-- Name: badminton_profile badminton_elo_seed; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER badminton_elo_seed AFTER INSERT OR UPDATE OF elo_seed ON public.badminton_profile FOR EACH ROW EXECUTE FUNCTION public.fn_seed_initial_elo();


--
-- Name: basketball_profile basketball_elo_seed; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER basketball_elo_seed AFTER INSERT OR UPDATE OF elo_seed ON public.basketball_profile FOR EACH ROW EXECUTE FUNCTION public.fn_seed_initial_elo();


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
-- Name: lobby_befriend_record lobby_befriend_record_before_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER lobby_befriend_record_before_insert BEFORE INSERT ON public.lobby_befriend_record FOR EACH ROW EXECUTE FUNCTION public.lobby_befriend_record_before_insert_trigger_fn();


--
-- Name: lobby_match lobby_match_referee_role_check; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER lobby_match_referee_role_check BEFORE INSERT OR UPDATE OF referee_booking_id ON public.lobby_match FOR EACH ROW EXECUTE FUNCTION public.lobby_match_referee_role_check();


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
-- Name: pickleball_profile pickleball_elo_seed; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER pickleball_elo_seed AFTER INSERT OR UPDATE OF elo_seed ON public.pickleball_profile FOR EACH ROW EXECUTE FUNCTION public.fn_seed_initial_elo();


--
-- Name: professional_booking_review professional_review_stats_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER professional_review_stats_trigger AFTER INSERT OR DELETE OR UPDATE ON public.professional_booking_review FOR EACH ROW EXECUTE FUNCTION public.professional_booking_review_updated_trigger_fn();


--
-- Name: soccer_profile soccer_elo_seed; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER soccer_elo_seed AFTER INSERT OR UPDATE OF elo_seed ON public.soccer_profile FOR EACH ROW EXECUTE FUNCTION public.fn_seed_initial_elo();


--
-- Name: tennis_profile tennis_elo_seed; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tennis_elo_seed AFTER INSERT OR UPDATE OF elo_seed ON public.tennis_profile FOR EACH ROW EXECUTE FUNCTION public.fn_seed_initial_elo();


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
-- Name: subscription tr_check_filters; Type: TRIGGER; Schema: realtime; Owner: supabase_admin
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
-- Name: activity activity_professional_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_professional_booking_id_fkey FOREIGN KEY (professional_booking_id) REFERENCES public.professional_booking(id) ON DELETE SET NULL;


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
-- Name: booking_additional_users booking_additional_users_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking_additional_users
    ADD CONSTRAINT booking_additional_users_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.professional_booking(id) ON DELETE CASCADE;


--
-- Name: booking_additional_users booking_additional_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking_additional_users
    ADD CONSTRAINT booking_additional_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: daily_health_summary daily_health_summary_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_health_summary
    ADD CONSTRAINT daily_health_summary_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: lobby_befriend_record lobby_befriend_record_initiator_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_befriend_record
    ADD CONSTRAINT lobby_befriend_record_initiator_user_id_fkey FOREIGN KEY (initiator_user_id) REFERENCES public."user"(id) ON UPDATE CASCADE;


--
-- Name: lobby_befriend_record lobby_befriend_record_target_lobby_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lobby_befriend_record
    ADD CONSTRAINT lobby_befriend_record_target_lobby_id_fkey FOREIGN KEY (target_lobby_id) REFERENCES public.lobby(id) ON UPDATE CASCADE;


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
    ADD CONSTRAINT lobby_match_referee_booking_id_fkey FOREIGN KEY (referee_booking_id) REFERENCES public.professional_booking(id) ON DELETE RESTRICT;


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
-- Name: network network_city_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.network
    ADD CONSTRAINT network_city_fkey FOREIGN KEY (city) REFERENCES public.supported_city_cluster(id);


--
-- Name: pickleball_profile pickleball_profile_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pickleball_profile
    ADD CONSTRAINT pickleball_profile_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: professional_booking professional_booking_client_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional_booking
    ADD CONSTRAINT professional_booking_client_user_id_fkey FOREIGN KEY (client_user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: professional_booking professional_booking_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional_booking
    ADD CONSTRAINT professional_booking_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.location(id);


--
-- Name: professional_booking professional_booking_professional_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional_booking
    ADD CONSTRAINT professional_booking_professional_id_fkey FOREIGN KEY (professional_id) REFERENCES public.professional(id);


--
-- Name: professional_booking_review professional_booking_review_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional_booking_review
    ADD CONSTRAINT professional_booking_review_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.professional_booking(id) ON DELETE RESTRICT;


--
-- Name: professional_booking_review professional_booking_review_professional_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional_booking_review
    ADD CONSTRAINT professional_booking_review_professional_id_fkey FOREIGN KEY (professional_id) REFERENCES public.professional(id) ON DELETE CASCADE;


--
-- Name: professional_booking_review professional_booking_review_reviewer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional_booking_review
    ADD CONSTRAINT professional_booking_review_reviewer_user_id_fkey FOREIGN KEY (reviewer_user_id) REFERENCES public."user"(id) ON DELETE RESTRICT;


--
-- Name: professional_booking professional_booking_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional_booking
    ADD CONSTRAINT professional_booking_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.professional_service(id);


--
-- Name: professional professional_linked_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.professional
    ADD CONSTRAINT professional_linked_user_id_fkey FOREIGN KEY (linked_user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


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
-- Name: user_rating user_rating_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_rating
    ADD CONSTRAINT user_rating_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


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
-- Name: booking_additional_users Additional users can see bookings they are part of; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Additional users can see bookings they are part of" ON public.booking_additional_users FOR SELECT TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: professional Authenticated users can read professional profiles; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Authenticated users can read professional profiles" ON public.professional FOR SELECT TO authenticated USING (true);


--
-- Name: lobby_feed_item Author or captain can delete a feed item; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Author or captain can delete a feed item" ON public.lobby_feed_item FOR DELETE TO authenticated USING (((author_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
   FROM public.lobby l
  WHERE ((l.id = lobby_feed_item.lobby_id) AND (l.captain_id = ( SELECT auth.uid() AS uid)))))));


--
-- Name: lobby Captain can delete their lobby; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Captain can delete their lobby" ON public.lobby FOR DELETE TO authenticated USING ((captain_id = ( SELECT auth.uid() AS uid)));


--
-- Name: lobby_match Captain can delete their lobby's matches; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Captain can delete their lobby's matches" ON public.lobby_match FOR DELETE TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.lobby l
  WHERE ((l.id = lobby_match.lobby_id) AND (l.captain_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: lobby_match Captain can edit their lobby's matches; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Captain can edit their lobby's matches" ON public.lobby_match FOR UPDATE TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.lobby l
  WHERE ((l.id = lobby_match.lobby_id) AND (l.captain_id = ( SELECT auth.uid() AS uid)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.lobby l
  WHERE ((l.id = lobby_match.lobby_id) AND (l.captain_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: lobby_feed_item Captain can post updates and polls; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Captain can post updates and polls" ON public.lobby_feed_item FOR INSERT TO authenticated WITH CHECK (((author_id = ( SELECT auth.uid() AS uid)) AND (kind = ANY (ARRAY['update'::public.lobby_feed_item_kind, 'poll'::public.lobby_feed_item_kind])) AND (EXISTS ( SELECT 1
   FROM public.lobby l
  WHERE ((l.id = lobby_feed_item.lobby_id) AND (l.captain_id = ( SELECT auth.uid() AS uid)))))));


--
-- Name: lobby_match Captain can record matches for their lobby; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Captain can record matches for their lobby" ON public.lobby_match FOR INSERT TO authenticated WITH CHECK ((EXISTS ( SELECT 1
   FROM public.lobby l
  WHERE ((l.id = lobby_match.lobby_id) AND (l.captain_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: booking_additional_users Client can manage additional users for their bookings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Client can manage additional users for their bookings" ON public.booking_additional_users TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.professional_booking pb
  WHERE ((pb.id = booking_additional_users.booking_id) AND (pb.client_user_id = ( SELECT auth.uid() AS uid)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.professional_booking pb
  WHERE ((pb.id = booking_additional_users.booking_id) AND (pb.client_user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: professional_booking_review Clients can create reviews for their completed bookings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Clients can create reviews for their completed bookings" ON public.professional_booking_review FOR INSERT TO authenticated WITH CHECK (((reviewer_user_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1
   FROM public.professional_booking pb
  WHERE ((pb.id = professional_booking_review.booking_id) AND (pb.client_user_id = ( SELECT auth.uid() AS uid)) AND (pb.status = 'completed'::public.professional_booking_status))))));


--
-- Name: professional_booking Clients can manage their own bookings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Clients can manage their own bookings" ON public.professional_booking TO authenticated USING ((( SELECT auth.uid() AS uid) = client_user_id)) WITH CHECK ((( SELECT auth.uid() AS uid) = client_user_id));


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
-- Name: professional_booking Linked professionals can manage their bookings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Linked professionals can manage their bookings" ON public.professional_booking TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.professional p
  WHERE ((p.id = professional_booking.professional_id) AND (p.linked_user_id = ( SELECT auth.uid() AS uid)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.professional p
  WHERE ((p.id = professional_booking.professional_id) AND (p.linked_user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: professional_service Linked professionals can manage their own services; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Linked professionals can manage their own services" ON public.professional_service TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.professional p
  WHERE ((p.id = professional_service.professional_id) AND (p.linked_user_id = ( SELECT auth.uid() AS uid)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.professional p
  WHERE ((p.id = professional_service.professional_id) AND (p.linked_user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: professional Linked users can manage their own professional profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Linked users can manage their own professional profile" ON public.professional TO authenticated USING ((( SELECT auth.uid() AS uid) = linked_user_id)) WITH CHECK ((( SELECT auth.uid() AS uid) = linked_user_id));


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

CREATE POLICY "Members can change their own attendance" ON public.activity_confirmation FOR UPDATE TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid))) WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1
   FROM public.activity a
  WHERE ((a.id = activity_confirmation.activity_id) AND (a.lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)))))));


--
-- Name: activity_confirmation Members can confirm their own attendance; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Members can confirm their own attendance" ON public.activity_confirmation FOR INSERT TO authenticated WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1
   FROM public.activity a
  WHERE ((a.id = activity_confirmation.activity_id) AND (a.lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)))))));


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

CREATE POLICY "Members can retract their own confirmation" ON public.activity_confirmation FOR DELETE TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: lobby_match Members of either lobby can read the match; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Members of either lobby can read the match" ON public.lobby_match FOR SELECT TO authenticated USING (((lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)) OR ((opponent_lobby_id IS NOT NULL) AND (opponent_lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)))));


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
-- Name: activity Users can delete their own activities; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can delete their own activities" ON public.activity FOR DELETE TO authenticated USING ((user_id = auth.uid()));


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
-- Name: activity Users can update their own activities; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own activities" ON public.activity FOR UPDATE TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


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

CREATE POLICY "Users involved can update befriend record status" ON public.lobby_befriend_record FOR UPDATE TO authenticated USING (((( SELECT auth.uid() AS uid) = initiator_user_id) OR (( SELECT auth.uid() AS uid) = target_user_id) OR ((target_lobby_id IS NOT NULL) AND (target_lobby_id IN ( SELECT lobby.id
   FROM public.lobby
  WHERE (lobby.captain_id = ( SELECT auth.uid() AS uid))))))) WITH CHECK (true);


--
-- Name: user_achievement Users see their own achievements; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users see their own achievements" ON public.user_achievement FOR SELECT TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


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
-- Name: booking_additional_users; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.booking_additional_users ENABLE ROW LEVEL SECURITY;

--
-- Name: daily_health_summary; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.daily_health_summary ENABLE ROW LEVEL SECURITY;

--
-- Name: user_rating elo ratings are publicly readable; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "elo ratings are publicly readable" ON public.user_rating FOR SELECT USING (true);


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
-- Name: lobby_feed_item; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.lobby_feed_item ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_feed_poll_vote; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.lobby_feed_poll_vote ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_match; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.lobby_match ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_member; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.lobby_member ENABLE ROW LEVEL SECURITY;

--
-- Name: location; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.location ENABLE ROW LEVEL SECURITY;

--
-- Name: network; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.network ENABLE ROW LEVEL SECURITY;

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
-- Name: professional_booking; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.professional_booking ENABLE ROW LEVEL SECURITY;

--
-- Name: professional_booking_review; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.professional_booking_review ENABLE ROW LEVEL SECURITY;

--
-- Name: professional_service; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.professional_service ENABLE ROW LEVEL SECURITY;

--
-- Name: soccer_profile; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.soccer_profile ENABLE ROW LEVEL SECURITY;

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
-- Name: vector_indexes; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.vector_indexes ENABLE ROW LEVEL SECURITY;

--
-- Name: supabase_realtime; Type: PUBLICATION; Schema: -; Owner: postgres
--

CREATE PUBLICATION supabase_realtime WITH (publish = 'insert, update, delete, truncate');


ALTER PUBLICATION supabase_realtime OWNER TO postgres;

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
-- Name: SCHEMA realtime; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA realtime TO postgres;
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

GRANT ALL ON FUNCTION public._achievement_current_value(p_user_id uuid, p_criteria jsonb, p_eligible_from timestamp with time zone) TO anon;
GRANT ALL ON FUNCTION public._achievement_current_value(p_user_id uuid, p_criteria jsonb, p_eligible_from timestamp with time zone) TO authenticated;
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

GRANT ALL ON FUNCTION public.activity_health_data(p_sport_id bigint) TO anon;
GRANT ALL ON FUNCTION public.activity_health_data(p_sport_id bigint) TO authenticated;
GRANT ALL ON FUNCTION public.activity_health_data(p_sport_id bigint) TO service_role;


--
-- Name: FUNCTION activity_is_confirmed(p_activity_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.activity_is_confirmed(p_activity_id uuid) TO anon;
GRANT ALL ON FUNCTION public.activity_is_confirmed(p_activity_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.activity_is_confirmed(p_activity_id uuid) TO service_role;


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
-- Name: FUNCTION create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid, p_location_name text, p_street_number text, p_street_name text, p_district text, p_city text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid, p_location_name text, p_street_number text, p_street_name text, p_district text, p_city text) TO anon;
GRANT ALL ON FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid, p_location_name text, p_street_number text, p_street_name text, p_district text, p_city text) TO authenticated;
GRANT ALL ON FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid, p_location_name text, p_street_number text, p_street_name text, p_district text, p_city text) TO service_role;


--
-- Name: FUNCTION evaluate_achievements(p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.evaluate_achievements(p_user_id uuid) TO anon;
GRANT ALL ON FUNCTION public.evaluate_achievements(p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.evaluate_achievements(p_user_id uuid) TO service_role;


--
-- Name: FUNCTION fn_lobby_playtime_keys(p_playtime jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_lobby_playtime_keys(p_playtime jsonb) TO anon;
GRANT ALL ON FUNCTION public.fn_lobby_playtime_keys(p_playtime jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.fn_lobby_playtime_keys(p_playtime jsonb) TO service_role;


--
-- Name: FUNCTION fn_lobby_recompute_stats(p_lobby_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.fn_lobby_recompute_stats(p_lobby_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fn_lobby_recompute_stats(p_lobby_id uuid) TO service_role;


--
-- Name: FUNCTION fn_playtime_to_dict(p_playtime jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_playtime_to_dict(p_playtime jsonb) TO anon;
GRANT ALL ON FUNCTION public.fn_playtime_to_dict(p_playtime jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.fn_playtime_to_dict(p_playtime jsonb) TO service_role;


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
-- Name: FUNCTION get_my_lobby_ids(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_my_lobby_ids() TO anon;
GRANT ALL ON FUNCTION public.get_my_lobby_ids() TO authenticated;
GRANT ALL ON FUNCTION public.get_my_lobby_ids() TO service_role;


--
-- Name: FUNCTION get_popular_networks(limit_count integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_popular_networks(limit_count integer) TO anon;
GRANT ALL ON FUNCTION public.get_popular_networks(limit_count integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_popular_networks(limit_count integer) TO service_role;


--
-- Name: FUNCTION health_capture_candidates(p_window_start timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.health_capture_candidates(p_window_start timestamp with time zone) TO anon;
GRANT ALL ON FUNCTION public.health_capture_candidates(p_window_start timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.health_capture_candidates(p_window_start timestamp with time zone) TO service_role;


--
-- Name: FUNCTION home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_mmr_window integer, p_page_size integer, p_page_number integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_mmr_window integer, p_page_size integer, p_page_number integer) TO anon;
GRANT ALL ON FUNCTION public.home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_mmr_window integer, p_page_size integer, p_page_number integer) TO authenticated;
GRANT ALL ON FUNCTION public.home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_mmr_window integer, p_page_size integer, p_page_number integer) TO service_role;


--
-- Name: FUNCTION home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_page_size integer, p_page_number integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_page_size integer, p_page_number integer) TO anon;
GRANT ALL ON FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_page_size integer, p_page_number integer) TO authenticated;
GRANT ALL ON FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_page_size integer, p_page_number integer) TO service_role;


--
-- Name: FUNCTION immutable_unaccent(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.immutable_unaccent(text) TO anon;
GRANT ALL ON FUNCTION public.immutable_unaccent(text) TO authenticated;
GRANT ALL ON FUNCTION public.immutable_unaccent(text) TO service_role;


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
-- Name: FUNCTION lobby_feed_data(p_lobby_id uuid, p_page_size integer, p_before timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.lobby_feed_data(p_lobby_id uuid, p_page_size integer, p_before timestamp with time zone) TO anon;
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

GRANT ALL ON FUNCTION public.lobby_match_referee_role_check() TO anon;
GRANT ALL ON FUNCTION public.lobby_match_referee_role_check() TO authenticated;
GRANT ALL ON FUNCTION public.lobby_match_referee_role_check() TO service_role;


--
-- Name: FUNCTION lobby_member_prevent_captain_leave(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.lobby_member_prevent_captain_leave() TO anon;
GRANT ALL ON FUNCTION public.lobby_member_prevent_captain_leave() TO authenticated;
GRANT ALL ON FUNCTION public.lobby_member_prevent_captain_leave() TO service_role;


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
-- Name: FUNCTION professional_booking_review_updated_trigger_fn(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.professional_booking_review_updated_trigger_fn() TO anon;
GRANT ALL ON FUNCTION public.professional_booking_review_updated_trigger_fn() TO authenticated;
GRANT ALL ON FUNCTION public.professional_booking_review_updated_trigger_fn() TO service_role;


--
-- Name: FUNCTION search_locations(search_term text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.search_locations(search_term text) TO anon;
GRANT ALL ON FUNCTION public.search_locations(search_term text) TO authenticated;
GRANT ALL ON FUNCTION public.search_locations(search_term text) TO service_role;


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
-- Name: FUNCTION transfer_lobby_captaincy(p_lobby_id uuid, p_new_captain_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.transfer_lobby_captaincy(p_lobby_id uuid, p_new_captain_id uuid) TO anon;
GRANT ALL ON FUNCTION public.transfer_lobby_captaincy(p_lobby_id uuid, p_new_captain_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.transfer_lobby_captaincy(p_lobby_id uuid, p_new_captain_id uuid) TO service_role;


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
-- Name: FUNCTION user_level_summary(p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.user_level_summary(p_user_id uuid) TO anon;
GRANT ALL ON FUNCTION public.user_level_summary(p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.user_level_summary(p_user_id uuid) TO service_role;


--
-- Name: FUNCTION apply_rls(wal jsonb, max_record_bytes integer); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO postgres;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO anon;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO authenticated;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO service_role;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO supabase_realtime_admin;


--
-- Name: FUNCTION broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text) TO postgres;
GRANT ALL ON FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text) TO dashboard_user;


--
-- Name: FUNCTION build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO postgres;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO anon;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO authenticated;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO service_role;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO supabase_realtime_admin;


--
-- Name: FUNCTION "cast"(val text, type_ regtype); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO postgres;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO dashboard_user;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO anon;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO authenticated;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO service_role;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO supabase_realtime_admin;


--
-- Name: FUNCTION check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO postgres;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO anon;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO authenticated;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO service_role;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO supabase_realtime_admin;


--
-- Name: FUNCTION is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO postgres;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO anon;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO authenticated;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO service_role;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO supabase_realtime_admin;


--
-- Name: FUNCTION list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO postgres;
GRANT ALL ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO dashboard_user;


--
-- Name: FUNCTION quote_wal2json(entity regclass); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO postgres;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO anon;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO authenticated;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO service_role;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO supabase_realtime_admin;


--
-- Name: FUNCTION send(payload jsonb, event text, topic text, private boolean); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean) TO postgres;
GRANT ALL ON FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean) TO dashboard_user;


--
-- Name: FUNCTION send_binary(payload bytea, event text, topic text, private boolean); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.send_binary(payload bytea, event text, topic text, private boolean) TO postgres;
GRANT ALL ON FUNCTION realtime.send_binary(payload bytea, event text, topic text, private boolean) TO dashboard_user;


--
-- Name: FUNCTION subscription_check_filters(); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO postgres;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO dashboard_user;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO anon;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO authenticated;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO service_role;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO supabase_realtime_admin;


--
-- Name: FUNCTION to_regrole(role_name text); Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO postgres;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO anon;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO authenticated;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO service_role;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO supabase_realtime_admin;


--
-- Name: FUNCTION topic(); Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT ALL ON FUNCTION realtime.topic() TO postgres;
GRANT ALL ON FUNCTION realtime.topic() TO dashboard_user;


--
-- Name: FUNCTION wal2json_escape_identifier(name text); Type: ACL; Schema: realtime; Owner: supabase_admin
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
-- Name: TABLE booking_additional_users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.booking_additional_users TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.booking_additional_users TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.booking_additional_users TO service_role;


--
-- Name: TABLE daily_health_summary; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.daily_health_summary TO anon;
GRANT ALL ON TABLE public.daily_health_summary TO authenticated;
GRANT ALL ON TABLE public.daily_health_summary TO service_role;


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
-- Name: TABLE lobby_feed_item; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_feed_item TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_feed_item TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_feed_item TO service_role;


--
-- Name: TABLE lobby_feed_poll_vote; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_feed_poll_vote TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_feed_poll_vote TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lobby_feed_poll_vote TO service_role;


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
-- Name: TABLE location; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.location TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.location TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.location TO service_role;


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
-- Name: TABLE pickleball_profile; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pickleball_profile TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pickleball_profile TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pickleball_profile TO service_role;


--
-- Name: TABLE professional; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional TO service_role;


--
-- Name: TABLE professional_booking; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional_booking TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional_booking TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional_booking TO service_role;


--
-- Name: TABLE professional_booking_review; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional_booking_review TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional_booking_review TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional_booking_review TO service_role;


--
-- Name: TABLE professional_service; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional_service TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional_service TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.professional_service TO service_role;


--
-- Name: TABLE soccer_profile; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.soccer_profile TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.soccer_profile TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.soccer_profile TO service_role;


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
-- Name: TABLE user_rating; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_rating TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_rating TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.user_rating TO service_role;


--
-- Name: TABLE messages; Type: ACL; Schema: realtime; Owner: supabase_realtime_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.messages TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.messages TO dashboard_user;
GRANT SELECT,INSERT,UPDATE ON TABLE realtime.messages TO anon;
GRANT SELECT,INSERT,UPDATE ON TABLE realtime.messages TO authenticated;
GRANT SELECT,INSERT,UPDATE ON TABLE realtime.messages TO service_role;


--
-- Name: TABLE schema_migrations; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.schema_migrations TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.schema_migrations TO dashboard_user;
GRANT SELECT ON TABLE realtime.schema_migrations TO anon;
GRANT SELECT ON TABLE realtime.schema_migrations TO authenticated;
GRANT SELECT ON TABLE realtime.schema_migrations TO service_role;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.schema_migrations TO supabase_realtime_admin;


--
-- Name: TABLE subscription; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.subscription TO postgres;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.subscription TO dashboard_user;
GRANT SELECT ON TABLE realtime.subscription TO anon;
GRANT SELECT ON TABLE realtime.subscription TO authenticated;
GRANT SELECT ON TABLE realtime.subscription TO service_role;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE realtime.subscription TO supabase_realtime_admin;


--
-- Name: SEQUENCE subscription_id_seq; Type: ACL; Schema: realtime; Owner: supabase_admin
--

GRANT ALL ON SEQUENCE realtime.subscription_id_seq TO postgres;
GRANT ALL ON SEQUENCE realtime.subscription_id_seq TO dashboard_user;
GRANT USAGE ON SEQUENCE realtime.subscription_id_seq TO anon;
GRANT USAGE ON SEQUENCE realtime.subscription_id_seq TO authenticated;
GRANT USAGE ON SEQUENCE realtime.subscription_id_seq TO service_role;
GRANT ALL ON SEQUENCE realtime.subscription_id_seq TO supabase_realtime_admin;


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

\unrestrict dXnchi3sijuOVkXgi6HCzTdWqATIO4RDKYhAte2aXmfRtJAYZtkbJR90kFB56T1

