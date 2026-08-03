-- ============================================================================
-- Maintenance migrations from the "most normal flow" audit pass (2026-07).
-- All applied to the live project via Supabase apply_migration.
-- ============================================================================

-- 1. Housekeeping off the read path.
-- expire_past_activities() used to run as a mutation on every lobby-list read
-- (UserLobbiesController.build). Moved to a 15-minute pg_cron job so the read
-- path is read-only.
select cron.schedule(
    'expire_past_activities',
    '*/15 * * * *',
    $$ select public.expire_past_activities(); $$
);

-- 2. Drop the stale home_professional_data overload (pre-search signature).
-- The p_search variant supersedes it and the client always passes p_search;
-- two overloads risk PostgREST ambiguity.
drop function if exists public.home_professional_data(
    bigint, jsonb, integer, text[], integer, integer
);

-- 3. activity_confirmed push threshold fix lives in push_notifications.sql
--    (fn_emit_activity_confirmed rewritten to count 'going' only and fire on
--    INSERT OR UPDATE). See that file for the canonical definition.

-- 4. Challenge handshake lives in lobby_challenge.sql (new table + RPCs +
--    notification kinds).
