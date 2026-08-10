-- taggable_users(p_activity_id, p_booking_id) never checked that the CALLER
-- had any relationship to the given activity/booking — only that the listed
-- people did. Anyone who had (or guessed) an activity/booking uuid could pull
-- the full roster (username, tag_number, profile `details`) of a lobby
-- activity or professional booking they had no part in.
--
-- Add the missing membership/participation check on the caller, using the
-- same relations the function already unions over for the candidate list.
-- Unauthorized/anonymous calls now return zero rows instead of the roster.
-- Also drop the stray PUBLIC/anon grant — only authenticated clients compose
-- wall posts (create_wall_post is already authenticated-only), so anon never
-- had a legitimate reason to call this.

CREATE OR REPLACE FUNCTION public.taggable_users(p_activity_id uuid DEFAULT NULL::uuid, p_booking_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(user_id uuid, username text, tag_number text, details jsonb, attended boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_uid uuid := auth.uid();
    v_allowed boolean;
BEGIN
    IF v_uid IS NULL THEN
        RETURN;
    END IF;

    IF p_activity_id IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 FROM public.activity a
            JOIN public.lobby_member m ON m.lobby_id = a.lobby_id
            WHERE a.id = p_activity_id AND m.user_id = v_uid
        ) INTO v_allowed;
    ELSIF p_booking_id IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 FROM public.professional_booking b
            WHERE b.id = p_booking_id AND b.client_user_id = v_uid
            UNION ALL
            SELECT 1 FROM public.booking_additional_users au
            WHERE au.booking_id = p_booking_id AND au.user_id = v_uid
            UNION ALL
            SELECT 1 FROM public.professional p
            JOIN public.professional_booking b2 ON b2.professional_id = p.id
            WHERE b2.id = p_booking_id AND p.linked_user_id = v_uid
        ) INTO v_allowed;
    ELSE
        v_allowed := false;
    END IF;

    IF NOT v_allowed THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT u.id, u.username::text, u.tag_number::text, u.details,
           bool_or(x.attended)
    FROM (
        SELECT c.user_id AS uid, true AS attended
            FROM public.activity_confirmation c
            WHERE p_activity_id IS NOT NULL
              AND c.activity_id = p_activity_id
              AND c.attendance = 'going'
        UNION ALL
        SELECT m.user_id, false
            FROM public.lobby_member m
            JOIN public.activity a ON a.lobby_id = m.lobby_id
            WHERE p_activity_id IS NOT NULL AND a.id = p_activity_id
        UNION ALL
        SELECT b.client_user_id, true
            FROM public.professional_booking b
            WHERE p_booking_id IS NOT NULL AND b.id = p_booking_id
        UNION ALL
        SELECT au.user_id, true
            FROM public.booking_additional_users au
            WHERE p_booking_id IS NOT NULL AND au.booking_id = p_booking_id
        UNION ALL
        SELECT p.linked_user_id, true
            FROM public.professional p
            JOIN public.professional_booking b ON b.professional_id = p.id
            WHERE p_booking_id IS NOT NULL
              AND b.id = p_booking_id
              AND p.linked_user_id IS NOT NULL
    ) x
    JOIN public."user" u ON u.id = x.uid
    WHERE u.id <> v_uid
    GROUP BY u.id, u.username, u.tag_number, u.details
    ORDER BY bool_or(x.attended) DESC, u.username;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.taggable_users(uuid, uuid) FROM PUBLIC, anon;
