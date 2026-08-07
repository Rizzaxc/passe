-- ============================================================================
-- schedule_rpc.sql — my_schedule_data: the current user's activities for the
-- Manage → Schedule calendar.
--
-- Returns, for auth.uid() and the given sport, within [p_from, p_to]:
--   • lobby activities for every lobby the user is a member of   (tone 'sport')
--   • the user's own professional bookings                       (tone 'coach')
-- Recurring rows are real, independently-dated activity rows now (each week
-- is its own materialized row — see schema/recurring_activity_series.sql),
-- so a plain start_time-in-window filter is correct for all of them; there's
-- no more client-side expansion of a single anchor row.
--
-- SECURITY DEFINER because `activity` RLS is owner-only (user_id = auth.uid()),
-- but the schedule needs every activity in the user's lobbies regardless of who
-- proposed it. search_path is locked and the body filters on auth.uid().
--
-- Apply with execute_sql / apply_migration. Idempotent.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.my_schedule_data(
    p_sport_id bigint,
    p_from     timestamptz,
    p_to       timestamptz
) RETURNS TABLE (
    id                     uuid,
    start_time             timestamptz,
    end_time               timestamptz,
    title                  text,
    meta                   text,
    tone                   text,
    recurrence_day_of_week smallint
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO ''
AS $$
DECLARE
    v_uid uuid := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    -- lobby activities for lobbies the user belongs to
    SELECT a.id,
           a.start_time,
           a.end_time,
           l.name::text AS title,
           (CASE WHEN loc.name IS NOT NULL AND loc.name <> '' THEN loc.name || ' · ' ELSE '' END
            || l.member_count || ' người')::text AS meta,
           'sport'::text AS tone,
           a.recurrence_day_of_week
    FROM public.activity a
    JOIN public.lobby l ON l.id = a.lobby_id
    LEFT JOIN public.location loc ON loc.id = COALESCE(a.location_id, l.home_ground)
    WHERE a.sport_id = p_sport_id
      AND a.lobby_id IN (SELECT lobby_id FROM public.lobby_member WHERE user_id = v_uid)
      AND a.start_time >= p_from AND a.start_time <= p_to

    UNION ALL

    -- professional bookings where the user is the client
    SELECT a.id,
           a.start_time,
           a.end_time,
           (p.display_name || ' · ' || ps.service_type)::text AS title,
           COALESCE(loc.name, '')::text AS meta,
           'coach'::text AS tone,
           a.recurrence_day_of_week
    FROM public.activity a
    JOIN public.professional_booking pb ON pb.id = a.professional_booking_id
    JOIN public.professional p ON p.id = pb.professional_id
    JOIN public.professional_service ps ON ps.id = pb.service_id
    LEFT JOIN public.location loc ON loc.id = COALESCE(a.location_id, pb.location_id)
    WHERE a.sport_id = p_sport_id
      AND pb.client_user_id = v_uid
      AND a.start_time >= p_from AND a.start_time <= p_to;
END;
$$;

-- Postgres grants EXECUTE to PUBLIC by default; lock it to authenticated only
-- (the body already returns nothing when auth.uid() is null).
REVOKE EXECUTE ON FUNCTION public.my_schedule_data(bigint, timestamptz, timestamptz) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.my_schedule_data(bigint, timestamptz, timestamptz) TO authenticated;
