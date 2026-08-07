-- ============================================================================
-- activity_note_action.sql — one short free-text note per member/activity.
--
-- Notes reuse lobby_feed_item(kind = personal) so they appear in the existing
-- per-activity action log. The RPC is the supported write path; constraints
-- and the unique index remain the final backstop for direct/racing clients.
-- Apply with execute_sql / apply_migration.
-- ============================================================================

ALTER TABLE public.lobby_feed_item
    DROP CONSTRAINT IF EXISTS lobby_feed_item_activity_note_shape;

ALTER TABLE public.lobby_feed_item
    ADD CONSTRAINT lobby_feed_item_activity_note_shape CHECK (
        kind <> 'personal'
        OR payload->>'action_kind' <> 'note'
        OR (
            activity_id IS NOT NULL
            AND jsonb_typeof(payload->'detail') = 'string'
            AND char_length(btrim(payload->>'detail')) BETWEEN 1 AND 72
        )
    );

CREATE UNIQUE INDEX IF NOT EXISTS lobby_feed_item_one_note_per_activity_idx
    ON public.lobby_feed_item (activity_id, author_id)
    WHERE kind = 'personal' AND payload->>'action_kind' = 'note';


-- Every activity-scoped feed row must point back to an activity in the same
-- lobby. This also hardens the existing `late` and payment-request paths.
CREATE OR REPLACE FUNCTION public.fn_validate_activity_feed_item_scope()
    RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
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

-- Trigger functions are invoked by PostgreSQL itself; client roles never
-- need direct EXECUTE access through the Data API.
REVOKE ALL ON FUNCTION public.fn_validate_activity_feed_item_scope()
    FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS validate_activity_feed_item_scope
    ON public.lobby_feed_item;
CREATE TRIGGER validate_activity_feed_item_scope
    BEFORE INSERT OR UPDATE OF lobby_id, activity_id
    ON public.lobby_feed_item
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_validate_activity_feed_item_scope();


CREATE OR REPLACE FUNCTION public.post_activity_note(
    p_activity_id uuid,
    p_note text
) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
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

REVOKE ALL ON FUNCTION public.post_activity_note(uuid, text)
    FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.post_activity_note(uuid, text)
    TO authenticated;
