-- Coach/referee surfaces (Discover ▸ Neutrals, the coach profile page, and
-- the player-side course hub card) rendered a plain initials-on-color
-- circle for every pro, even when that pro is self-service-registered and
-- linked to a real `user` account with the same generated/uploaded avatar
-- every other user-facing surface in the app resolves via `PUserAvatar`.
--
-- Fix: surface `professional.linked_user_id` (already FK'd to `user`) and
-- the linked user's `details->>'generatedAvatar'` from the two RPCs behind
-- these cards, so the client can call `PUserAvatar` instead of falling back
-- to initials. `professionalById`'s direct table read (`professional/
-- controller.dart`) needed no SQL change — it already reads `linked_user_id`
-- as a plain column and now embeds the linked user's `details` via
-- PostgREST resource embedding client-side.
--
-- Needs to be applied to the live Supabase project.

-- ── home_professional_data: Discover ▸ Neutrals + the coach profile page's
--    deep-link fallback ────────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.home_professional_data(bigint, jsonb, integer, text[], text, integer, integer);

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

REVOKE ALL ON FUNCTION public.home_professional_data(bigint, jsonb, integer, text[], text, integer, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.home_professional_data(bigint, jsonb, integer, text[], text, integer, integer) TO authenticated;

-- ── my_courses_data: the player-side course hub card's coach avatar ────────
DROP FUNCTION IF EXISTS public.my_courses_data();

CREATE OR REPLACE FUNCTION public.my_courses_data()
RETURNS TABLE(
  course_id uuid, conversation_id uuid, name text, status text,
  member_status text, professional_id uuid, coach_name text, coach_avatar text,
  coach_user_id uuid,
  sport_id bigint, target_session_count integer, held_session_count integer,
  next_activity_id uuid, next_start_time timestamptz,
  last_message_at timestamptz, last_message_body text, last_message_kind text,
  last_message_payload jsonb, unread_count integer,
  pending_offer_id uuid, pending_rsvp_count integer
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
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

REVOKE ALL ON FUNCTION public.my_courses_data() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.my_courses_data() TO authenticated;
