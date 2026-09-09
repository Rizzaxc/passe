-- ============================================================================
-- lobby_freeplay_exposure.sql — expose a lobby's activity for freeplay ("Xé vé")
--
-- Until now freeplay was exclusively a curated-Host product: a `freeplay_host`
-- row puts up a standalone drop-in session and strangers request seats. Lobbies
-- schedule activities constantly and routinely come up a player short, with no
-- way to offer that seat to anyone outside the lobby.
--
-- A captain or coordinator of a NON-PRIVATE lobby can now attach a
-- `freeplay_activity` row to one of their scheduled activities. The listing is
-- owned by the LOBBY, not by a host:
--
--   * `activity_source_exclusivity` is untouched — the activity keeps
--     `lobby_id` and `freeplay_host_id` stays NULL. There are no phantom
--     `freeplay_host` rows. Owner kind is derived, never stored.
--   * Every `JOIN freeplay_host` in the freeplay stack becomes a LEFT JOIN,
--     identity is `coalesce(h.display_name, l.name)`, and the return shapes
--     gain an `owner_kind` ('host' | 'lobby') discriminator. Column names
--     host_id/host_name/host_avatar_url are kept for client stability.
--   * `h.user_id = auth.uid()` becomes `fn_freeplay_can_manage()` — the host
--     user, OR anyone passing `lobby_can_manage()` (captain + coordinators).
--
-- The load-bearing decision is that an accepted guest gets NO
-- `activity_confirmation` row on a lobby activity. That row is the lobby's
-- commitment quorum (`activity_is_confirmed`, `fn_emit_activity_confirmed`,
-- `fn_sweep_activity_thresholds`), the basis of `lobby_payment_requests` bill
-- splits, and `wall_post`'s taggable-attendee proof. Outsiders must not move
-- any of those. Guests live only in `freeplay_request`; their schedule already
-- reads from there.
--
-- Apply AFTER: freeplay.sql, freeplay_integrations.sql,
-- freeplay_conversation_migration.sql, freeplay_chat_counterpart.sql,
-- course_freeplay_location_details.sql, lobby_coordinator_role.sql.
-- This file is deliberately the last word on every function it re-creates.
-- Idempotent / re-runnable.
-- ============================================================================


-- ─── 1. Owner resolution ────────────────────────────────────────────────────
-- The whole feature hangs off these two. Internal (SECURITY DEFINER, no client
-- grant) because they read `lobby_member` and `freeplay_host`, both of which
-- are otherwise unreadable to a non-member.

CREATE OR REPLACE FUNCTION public.fn_freeplay_owner_user_ids(p_activity_id uuid)
RETURNS uuid[] LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT CASE
    WHEN a.freeplay_host_id IS NOT NULL THEN
      (SELECT array_agg(h.user_id) FROM public.freeplay_host h WHERE h.id = a.freeplay_host_id)
    WHEN a.lobby_id IS NOT NULL THEN
      (SELECT array_agg(DISTINCT s.uid) FROM (
         SELECT l.captain_id AS uid FROM public.lobby l WHERE l.id = a.lobby_id
         UNION
         SELECT lm.user_id FROM public.lobby_member lm
          WHERE lm.lobby_id = a.lobby_id AND lm.role = 'coordinator'
       ) s WHERE s.uid IS NOT NULL)
  END
  FROM public.activity a WHERE a.id = p_activity_id
$$;
REVOKE ALL ON FUNCTION public.fn_freeplay_owner_user_ids(uuid) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.fn_freeplay_can_manage(p_activity_id uuid, p_uid uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT p_uid IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.activity a
    LEFT JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
    WHERE a.id = p_activity_id
      AND (h.user_id = p_uid
        OR (a.lobby_id IS NOT NULL AND public.lobby_can_manage(a.lobby_id, p_uid)))
  )
$$;
REVOKE ALL ON FUNCTION public.fn_freeplay_can_manage(uuid, uuid) FROM PUBLIC, anon, authenticated;

-- "Does this lobby currently advertise any seats?" — the predicate behind the
-- can't-go-private guard.
CREATE OR REPLACE FUNCTION public.fn_lobby_has_live_freeplay(p_lobby_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.freeplay_activity fa
    JOIN public.activity a ON a.id = fa.activity_id
    WHERE a.lobby_id = p_lobby_id AND fa.cancelled_at IS NULL AND a.end_time > now()
  )
$$;
REVOKE ALL ON FUNCTION public.fn_lobby_has_live_freeplay(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.fn_lobby_has_live_freeplay(uuid) TO authenticated;


-- ─── 2. Owner invariant ─────────────────────────────────────────────────────
-- A cross-table CHECK isn't possible, so this trigger is where "a listing has
-- exactly one owner, and a lobby listing is eligible" actually lives.

CREATE OR REPLACE FUNCTION public.fn_freeplay_activity_owner_guard()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_a record;
BEGIN
  SELECT a.lobby_id, a.freeplay_host_id, a.challenge_id, a.course_id, a.start_time
  INTO v_a FROM public.activity a WHERE a.id = NEW.activity_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'activity not found'; END IF;
  IF num_nonnulls(v_a.lobby_id, v_a.freeplay_host_id) <> 1 THEN
    RAISE EXCEPTION 'a freeplay listing needs exactly one owner (a Host or a lobby)';
  END IF;
  IF v_a.lobby_id IS NOT NULL THEN
    IF v_a.challenge_id IS NOT NULL OR v_a.course_id IS NOT NULL THEN
      RAISE EXCEPTION 'challenge and course activities cannot be exposed';
    END IF;
    IF v_a.start_time <= now() THEN
      RAISE EXCEPTION 'only an upcoming activity can be exposed';
    END IF;
    IF EXISTS (SELECT 1 FROM public.lobby l
               WHERE l.id = v_a.lobby_id AND l.visibility = 'private') THEN
      RAISE EXCEPTION 'a private lobby cannot expose activities';
    END IF;
  END IF;
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS freeplay_activity_owner_guard ON public.freeplay_activity;
CREATE TRIGGER freeplay_activity_owner_guard
BEFORE INSERT ON public.freeplay_activity
FOR EACH ROW EXECUTE FUNCTION public.fn_freeplay_activity_owner_guard();


-- ─── 3. Expose / withdraw ───────────────────────────────────────────────────

-- Shared cancel body, no authorization of its own: called both by
-- `cancel_freeplay_activity` (which checks first) and by the BEFORE DELETE
-- cascade on `activity` (where there is no caller to check).
CREATE OR REPLACE FUNCTION public.fn_cancel_freeplay_listing(p_activity_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_user_ids uuid[]; v_request record;
BEGIN
  UPDATE public.freeplay_activity
  SET cancelled_at = coalesce(cancelled_at, now()),
      intake_closed_at = coalesce(intake_closed_at, now()), updated_at = now()
  WHERE activity_id = p_activity_id;

  UPDATE public.freeplay_request SET status='host_cancelled', resolved_at=now(), updated_at=now()
  WHERE activity_id = p_activity_id AND status IN ('pending','accepted');

  -- Scoped to freeplay guests. The unscoped DELETE this replaces would wipe the
  -- lobby members' own RSVPs on a lobby-owned listing.
  DELETE FROM public.activity_confirmation ac
  WHERE ac.activity_id = p_activity_id
    AND EXISTS (SELECT 1 FROM public.freeplay_request r
                WHERE r.activity_id = p_activity_id AND r.user_id = ac.user_id);

  FOR v_request IN SELECT id FROM public.freeplay_request WHERE activity_id = p_activity_id
  LOOP
    INSERT INTO public.message(conversation_id, kind, body)
    VALUES (public.fn_ensure_freeplay_conversation(v_request.id), 'system', 'activity_cancelled');
  END LOOP;

  SELECT array_agg(DISTINCT user_id) INTO v_user_ids
  FROM public.freeplay_request WHERE activity_id = p_activity_id;
  IF cardinality(v_user_ids) > 0 THEN
    PERFORM public.fn_enqueue_notification('freeplay_activity_cancelled', v_user_ids,
      'Buổi Xé vé đã huỷ', 'Buổi chơi đã bị huỷ.',
      jsonb_build_object('activity_id', p_activity_id));
  END IF;
END
$$;
REVOKE ALL ON FUNCTION public.fn_cancel_freeplay_listing(uuid) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.expose_lobby_activity_freeplay(
  p_activity_id uuid, p_capacity integer, p_male_price numeric, p_female_price numeric,
  p_recommended_skills text[], p_description text DEFAULT ''::text,
  p_location_id uuid DEFAULT NULL::uuid
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_a record; v_loc uuid;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;

  SELECT a.id, a.lobby_id, a.location_id, l.home_ground
  INTO v_a
  FROM public.activity a JOIN public.lobby l ON l.id = a.lobby_id
  WHERE a.id = p_activity_id FOR UPDATE OF a;
  IF NOT FOUND THEN RAISE EXCEPTION 'lobby activity not found'; END IF;

  IF NOT public.lobby_can_manage(v_a.lobby_id, v_uid) THEN
    RAISE EXCEPTION 'caller is not authorized to manage this lobby';
  END IF;
  IF EXISTS (SELECT 1 FROM public.freeplay_activity WHERE activity_id = p_activity_id) THEN
    RAISE EXCEPTION 'activity is already exposed';
  END IF;

  -- Venue materialisation. A lobby activity may carry no `location_id` at all
  -- and lean on the lobby's home ground, but `home_freeplay_data` filters on a
  -- concrete city cluster it resolves through `activity.location_id` — so pin
  -- one now rather than teach the feed a second fallback. `p_location_id` is
  -- the last resort for a lobby with no home ground either.
  v_loc := coalesce(v_a.location_id, v_a.home_ground, p_location_id);
  IF v_loc IS NULL THEN
    RAISE EXCEPTION 'a listing needs a venue: set one on the activity or pick one here';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.location WHERE id = v_loc) THEN
    RAISE EXCEPTION 'location not found';
  END IF;
  IF v_a.location_id IS DISTINCT FROM v_loc THEN
    UPDATE public.activity SET location_id = v_loc WHERE id = p_activity_id;
  END IF;

  -- Every free-venue column stays NULL, which is the shape
  -- `freeplay_free_venue_complete` expects (and what live Host rows look like)
  -- — the address is read off `location` at query time.
  INSERT INTO public.freeplay_activity(activity_id, description, capacity, male_price,
    female_price, recommended_skills)
  VALUES (p_activity_id, coalesce(p_description,''), p_capacity, p_male_price,
    p_female_price, p_recommended_skills);
END
$$;


-- ─── 4. Writes, re-pointed at the owner helpers ─────────────────────────────

CREATE OR REPLACE FUNCTION public.cancel_freeplay_activity(p_activity_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
  IF NOT public.fn_freeplay_can_manage(p_activity_id, auth.uid()) THEN
    RAISE EXCEPTION 'activity not found or not owned';
  END IF;
  PERFORM public.fn_cancel_freeplay_listing(p_activity_id);
END
$$;

CREATE OR REPLACE FUNCTION public.set_freeplay_intake(p_activity_id uuid, p_closed boolean)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_start timestamptz;
BEGIN
  IF NOT public.fn_freeplay_can_manage(p_activity_id, auth.uid()) THEN
    RAISE EXCEPTION 'activity not found or not owned';
  END IF;
  SELECT a.start_time INTO v_start
  FROM public.activity a JOIN public.freeplay_activity fa ON fa.activity_id = a.id
  WHERE a.id = p_activity_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'activity not found or not owned'; END IF;
  IF NOT p_closed AND now() >= v_start THEN RAISE EXCEPTION 'cannot reopen after activity starts'; END IF;
  UPDATE public.freeplay_activity SET intake_closed_at = CASE WHEN p_closed THEN now() END,
    updated_at = now()
  WHERE activity_id = p_activity_id AND cancelled_at IS NULL;
END
$$;

-- Host-only by design: it rewrites the activity's own time and venue, which for
-- a lobby listing belongs to the lobby's scheduling flow, not to the seat
-- listing. Lobby listings edit through `edit_freeplay_listing`.
CREATE OR REPLACE FUNCTION public.update_freeplay_activity(
  p_activity_id uuid, p_start_time timestamptz, p_end_time timestamptz,
  p_capacity integer, p_male_price numeric, p_female_price numeric,
  p_recommended_skills text[], p_description text,
  p_location_id uuid DEFAULT NULL::uuid, p_venue_name text DEFAULT NULL::text,
  p_street_address text DEFAULT NULL::text, p_city_cluster bigint DEFAULT NULL::bigint,
  p_ward text DEFAULT NULL::text
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_row record; v_has_requests boolean;
        v_loc_city bigint; v_loc_ward text;
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
    city_cluster=CASE WHEN p_location_id IS NULL THEN p_city_cluster END,
    ward=CASE WHEN p_location_id IS NULL THEN btrim(p_ward) END,
    updated_at=now() WHERE activity_id=p_activity_id;
END
$$;

-- Widened to any owner, plus optional price edits while nothing is requested
-- yet (a lobby's only way to correct a mistyped price).
DROP FUNCTION IF EXISTS public.edit_freeplay_listing(uuid,integer,text,text[]);
DROP FUNCTION IF EXISTS public.edit_freeplay_listing(uuid,integer,text,text[],uuid);
CREATE OR REPLACE FUNCTION public.edit_freeplay_listing(
  p_activity_id uuid, p_capacity integer, p_description text, p_recommended_skills text[],
  p_location_id uuid DEFAULT NULL::uuid,
  p_male_price numeric DEFAULT NULL::numeric, p_female_price numeric DEFAULT NULL::numeric
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_current_capacity integer; v_current_location uuid;
        v_lobby uuid; v_accepted integer; v_has_requests boolean;
BEGIN
  IF NOT public.fn_freeplay_can_manage(p_activity_id, v_uid) THEN
    RAISE EXCEPTION 'activity not found or not owned';
  END IF;
  SELECT fa.capacity, a.location_id, a.lobby_id
  INTO v_current_capacity, v_current_location, v_lobby
  FROM public.freeplay_activity fa JOIN public.activity a ON a.id = fa.activity_id
  WHERE a.id = p_activity_id AND fa.cancelled_at IS NULL FOR UPDATE OF fa, a;
  IF NOT FOUND THEN RAISE EXCEPTION 'activity not found or not owned'; END IF;

  SELECT count(*)::integer INTO v_accepted
  FROM public.freeplay_request WHERE activity_id=p_activity_id AND status='accepted';
  v_has_requests := EXISTS(SELECT 1 FROM public.freeplay_request
    WHERE activity_id=p_activity_id AND status IN ('pending','accepted'));

  IF p_capacity < v_current_capacity OR p_capacity < v_accepted THEN
    RAISE EXCEPTION 'capacity can only increase';
  END IF;
  IF (p_male_price IS NOT NULL OR p_female_price IS NOT NULL) AND v_has_requests THEN
    RAISE EXCEPTION 'price cannot change after requests';
  END IF;
  -- A lobby listing's venue is the lobby activity's venue; it moves through the
  -- scheduling flow, never through the listing editor.
  IF v_lobby IS NOT NULL AND p_location_id IS DISTINCT FROM v_current_location
     AND p_location_id IS NOT NULL THEN
    RAISE EXCEPTION 'a lobby listing follows the activity venue';
  END IF;
  IF p_location_id IS NOT NULL
     AND NOT EXISTS(SELECT 1 FROM public.location WHERE id=p_location_id) THEN
    RAISE EXCEPTION 'location not found';
  END IF;
  IF v_has_requests AND p_location_id IS DISTINCT FROM v_current_location
     AND p_location_id IS NOT NULL THEN
    RAISE EXCEPTION 'location cannot change after requests';
  END IF;

  IF p_location_id IS NOT NULL AND v_lobby IS NULL THEN
    UPDATE public.activity SET location_id=p_location_id WHERE id=p_activity_id;
  END IF;
  UPDATE public.freeplay_activity
  SET capacity=p_capacity, description=coalesce(p_description,''),
      recommended_skills=p_recommended_skills,
      male_price=coalesce(p_male_price, male_price),
      female_price=coalesce(p_female_price, female_price),
      updated_at=now()
  WHERE activity_id=p_activity_id;
END
$$;

CREATE OR REPLACE FUNCTION public.request_freeplay_seat(p_activity_id uuid, p_message text DEFAULT NULL::text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid(); v_row record; v_gender text; v_skill text; v_id uuid;
        v_count integer; v_conversation uuid; v_owners uuid[];
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;
  SELECT a.sport_id, a.end_time, a.lobby_id, fa.capacity, fa.male_price, fa.female_price,
    fa.intake_closed_at, fa.cancelled_at,
    (a.freeplay_host_id IS NULL OR h.status='active') AS host_ok,
    (a.lobby_id IS NULL OR l.visibility <> 'private') AS lobby_ok
  INTO v_row
  FROM public.activity a
  JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  LEFT JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  LEFT JOIN public.lobby l ON l.id=a.lobby_id
  WHERE a.id=p_activity_id FOR UPDATE OF fa;
  IF NOT FOUND OR v_row.cancelled_at IS NOT NULL OR v_row.end_time<=now()
     OR v_row.intake_closed_at IS NOT NULL OR NOT v_row.host_ok OR NOT v_row.lobby_ok THEN
    RAISE EXCEPTION 'activity is not accepting requests';
  END IF;

  v_owners := coalesce(public.fn_freeplay_owner_user_ids(p_activity_id), '{}'::uuid[]);
  IF v_uid = ANY(v_owners) THEN RAISE EXCEPTION 'request not allowed'; END IF;
  IF EXISTS(SELECT 1 FROM unnest(v_owners) o WHERE public.fn_is_blocked(v_uid, o)) THEN
    RAISE EXCEPTION 'request not allowed';
  END IF;
  -- A member of the lobby is already an attendee: they RSVP, they don't buy a seat.
  IF v_row.lobby_id IS NOT NULL AND EXISTS(
       SELECT 1 FROM public.lobby_member m
       WHERE m.lobby_id=v_row.lobby_id AND m.user_id=v_uid) THEN
    RAISE EXCEPTION 'lobby members join by RSVP, not by seat request';
  END IF;

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

  IF cardinality(v_owners) > 0 THEN
    PERFORM public.fn_enqueue_notification('freeplay_request_received', v_owners,
      'Yêu cầu Xé vé mới','Có người muốn tham gia buổi chơi của bạn.',
      jsonb_build_object('activity_id',p_activity_id,'request_id',v_id));
  END IF;
  RETURN v_id;
END
$$;

CREATE OR REPLACE FUNCTION public.respond_freeplay_request(p_request_id uuid, p_accept boolean)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid(); v_row record; v_count integer; v_conversation uuid;
BEGIN
  SELECT r.*, fa.capacity, a.end_time, a.lobby_id INTO v_row
  FROM public.freeplay_request r
  JOIN public.freeplay_activity fa ON fa.activity_id=r.activity_id
  JOIN public.activity a ON a.id=r.activity_id
  WHERE r.id=p_request_id FOR UPDATE OF r,fa;
  IF NOT FOUND OR NOT public.fn_freeplay_can_manage(v_row.activity_id, v_uid) THEN
    RAISE EXCEPTION 'pending request not found';
  END IF;
  IF v_row.status<>'pending' THEN RAISE EXCEPTION 'pending request not found'; END IF;
  IF v_row.end_time<=now() THEN RAISE EXCEPTION 'activity ended'; END IF;

  v_conversation := public.fn_ensure_freeplay_conversation(p_request_id);
  PERFORM public.fn_sync_freeplay_conversation_members(p_request_id);

  IF p_accept THEN
    SELECT count(*) INTO v_count FROM public.freeplay_request WHERE activity_id=v_row.activity_id AND status='accepted';
    IF v_count>=v_row.capacity THEN RAISE EXCEPTION 'activity is full'; END IF;
    UPDATE public.freeplay_request SET status='accepted',resolved_at=now(),updated_at=now() WHERE id=p_request_id;
    -- Lobby listings deliberately create NO confirmation row: that row is the
    -- lobby's own commitment quorum and bill-split basis, and an outside guest
    -- must not move either. Their seat lives in `freeplay_request`.
    IF v_row.lobby_id IS NULL THEN
      INSERT INTO public.activity_confirmation(activity_id,user_id,attendance)
      VALUES(v_row.activity_id,v_row.user_id,'going') ON CONFLICT(activity_id,user_id)
      DO UPDATE SET attendance='going',confirmed_at=now();
    END IF;
    INSERT INTO public.message(conversation_id,kind,body)
    VALUES(v_conversation,'system','request_accepted');
    PERFORM public.fn_enqueue_notification('freeplay_request_accepted',ARRAY[v_row.user_id],
      'Đã nhận chỗ Xé vé','Yêu cầu của bạn đã được duyệt.',
      jsonb_build_object('activity_id',v_row.activity_id,'request_id',p_request_id));
  ELSE
    UPDATE public.freeplay_request SET status='declined',resolved_at=now(),updated_at=now() WHERE id=p_request_id;
    INSERT INTO public.message(conversation_id,kind,body)
    VALUES(v_conversation,'system','request_declined');
    PERFORM public.fn_enqueue_notification('freeplay_request_declined',ARRAY[v_row.user_id],
      'Yêu cầu Xé vé bị từ chối','Yêu cầu của bạn đã bị từ chối.',
      jsonb_build_object('activity_id',v_row.activity_id,'request_id',p_request_id));
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION public.cancel_freeplay_request(p_request_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid(); v_row record; v_conversation uuid; v_owners uuid[];
BEGIN
  SELECT r.*, a.end_time INTO v_row FROM public.freeplay_request r
  JOIN public.activity a ON a.id=r.activity_id
  WHERE r.id=p_request_id AND r.user_id=v_uid FOR UPDATE OF r;
  IF NOT FOUND OR v_row.status NOT IN ('pending','accepted') OR v_row.end_time<=now() THEN
    RAISE EXCEPTION 'active request not found';
  END IF;
  UPDATE public.freeplay_request SET status='cancelled',resolved_at=now(),updated_at=now() WHERE id=p_request_id;
  DELETE FROM public.activity_confirmation WHERE activity_id=v_row.activity_id AND user_id=v_uid;
  v_conversation := public.fn_ensure_freeplay_conversation(p_request_id);
  INSERT INTO public.message(conversation_id,kind,body)
  VALUES(v_conversation,'system','request_cancelled');
  v_owners := coalesce(public.fn_freeplay_owner_user_ids(v_row.activity_id), '{}'::uuid[]);
  IF cardinality(v_owners) > 0 THEN
    PERFORM public.fn_enqueue_notification('freeplay_request_cancelled', v_owners,
      'Người chơi đã huỷ','Một người chơi đã huỷ yêu cầu Xé vé.',
      jsonb_build_object('activity_id',v_row.activity_id,'request_id',p_request_id));
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION public.fn_freeplay_block_cleanup()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
  UPDATE public.freeplay_request r SET status='blocked',resolved_at=now(),updated_at=now()
  WHERE r.status IN ('pending','accepted')
    AND ((r.user_id=NEW.blocker_id
          AND NEW.blocked_id = ANY(coalesce(public.fn_freeplay_owner_user_ids(r.activity_id),'{}'::uuid[])))
      OR (r.user_id=NEW.blocked_id
          AND NEW.blocker_id = ANY(coalesce(public.fn_freeplay_owner_user_ids(r.activity_id),'{}'::uuid[]))));
  -- Host listings only: a lobby listing never wrote a confirmation row.
  DELETE FROM public.activity_confirmation ac USING public.activity a, public.freeplay_host h
  WHERE ac.activity_id=a.id AND h.id=a.freeplay_host_id
    AND ((ac.user_id=NEW.blocker_id AND h.user_id=NEW.blocked_id)
      OR (ac.user_id=NEW.blocked_id AND h.user_id=NEW.blocker_id));
  RETURN NEW;
END
$$;


-- ─── 5. Conversation membership ─────────────────────────────────────────────
-- A lobby listing's thread is requester + every manager. `joined_at` is
-- deliberately backdated to the request's own creation: the messaging layer's
-- visibility floor exists to keep a late-joining student out of a course's
-- back-story, not to hide a two-day-old seat negotiation from the coordinator
-- who ends up answering it.

CREATE OR REPLACE FUNCTION public.fn_sync_freeplay_conversation_members(p_request_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_conv uuid; v_created timestamptz; v_activity uuid;
BEGIN
  SELECT c.id, r.created_at, r.activity_id INTO v_conv, v_created, v_activity
  FROM public.freeplay_request r
  LEFT JOIN public.conversation c ON c.freeplay_request_id = r.id
  WHERE r.id = p_request_id;
  IF v_conv IS NULL THEN RETURN; END IF;

  INSERT INTO public.conversation_member(conversation_id, user_id, joined_at)
  SELECT v_conv, o, v_created
  FROM unnest(coalesce(public.fn_freeplay_owner_user_ids(v_activity),'{}'::uuid[])) o
  ON CONFLICT DO NOTHING;
END
$$;
REVOKE ALL ON FUNCTION public.fn_sync_freeplay_conversation_members(uuid) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.fn_ensure_freeplay_conversation(p_request_id uuid)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_id uuid; v_requester uuid; v_activity uuid; v_created timestamptz;
BEGIN
  SELECT c.id INTO v_id FROM public.conversation c WHERE c.freeplay_request_id = p_request_id;
  IF v_id IS NOT NULL THEN RETURN v_id; END IF;

  SELECT r.user_id, r.activity_id, r.created_at INTO v_requester, v_activity, v_created
  FROM public.freeplay_request r WHERE r.id = p_request_id;
  IF v_requester IS NULL THEN RAISE EXCEPTION 'freeplay request not found'; END IF;

  -- conversation_one_per_freeplay_request is a PARTIAL unique index, so the
  -- predicate has to be restated or ON CONFLICT inference fails.
  INSERT INTO public.conversation(kind, freeplay_request_id)
  VALUES ('freeplay', p_request_id)
  ON CONFLICT (freeplay_request_id) WHERE freeplay_request_id IS NOT NULL
  DO NOTHING
  RETURNING id INTO v_id;

  IF v_id IS NULL THEN
    SELECT c.id INTO v_id FROM public.conversation c WHERE c.freeplay_request_id = p_request_id;
    RETURN v_id;
  END IF;

  INSERT INTO public.conversation_member(conversation_id, user_id, joined_at)
  SELECT v_id, u, v_created
  FROM unnest(ARRAY[v_requester] ||
              coalesce(public.fn_freeplay_owner_user_ids(v_activity),'{}'::uuid[])) u
  ON CONFLICT DO NOTHING;

  RETURN v_id;
END
$$;

CREATE OR REPLACE FUNCTION public.freeplay_conversation_id(p_request_id uuid)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_id uuid; v_activity uuid;
BEGIN
  SELECT r.activity_id INTO v_activity FROM public.freeplay_request r
  WHERE r.id = p_request_id AND (r.user_id = v_uid
    OR public.fn_freeplay_can_manage(r.activity_id, v_uid));
  IF v_activity IS NULL THEN RAISE EXCEPTION 'chat not found'; END IF;

  v_id := public.fn_ensure_freeplay_conversation(p_request_id);
  -- Lazy sync so a manager promoted after the request still gets the thread.
  PERFORM public.fn_sync_freeplay_conversation_members(p_request_id);
  RETURN v_id;
END
$$;

-- The Zalo deep link resolves one other party. A lobby listing has no single
-- person on the owner side, so the requester simply gets no row (the client
-- already treats a missing counterpart as "no Zalo button").
CREATE OR REPLACE FUNCTION public.freeplay_chat_counterpart_data(p_request_id uuid)
RETURNS TABLE(counterpart_id uuid)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid(); v_counterpart uuid; v_found boolean;
BEGIN
  SELECT CASE WHEN r.user_id=v_uid THEN h.user_id ELSE r.user_id END, true
  INTO v_counterpart, v_found
  FROM public.freeplay_request r
  JOIN public.activity a ON a.id=r.activity_id
  LEFT JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE r.id=p_request_id
    AND (r.user_id=v_uid OR public.fn_freeplay_can_manage(r.activity_id, v_uid));
  IF NOT coalesce(v_found,false) OR v_counterpart IS NULL THEN RETURN; END IF;
  RETURN QUERY SELECT v_counterpart;
END
$$;


-- ─── 6. Reads ───────────────────────────────────────────────────────────────

DROP FUNCTION IF EXISTS public.home_freeplay_data(bigint,jsonb,integer,character varying[],text,integer,integer);
CREATE FUNCTION public.home_freeplay_data(
  p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[],
  p_search text DEFAULT ''::text, p_page_size integer DEFAULT 20, p_page_number integer DEFAULT 1
) RETURNS TABLE(
  activity_id uuid, host_id uuid, host_name text, host_avatar_url text, owner_kind text,
  description text, start_time timestamptz, end_time timestamptz, location_id uuid,
  venue_name text, street_address text, city_cluster bigint, ward text, capacity integer,
  accepted_count bigint, male_price numeric, female_price numeric, recommended_skills text[],
  my_skill text, my_request_id uuid, my_request_status text
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  WITH candidate AS (
    SELECT a.id, a.start_time, a.end_time, a.location_id,
      a.created_at AS activity_created_at,
      CASE WHEN a.freeplay_host_id IS NOT NULL THEN 'host' ELSE 'lobby' END AS owner_kind,
      coalesce(a.freeplay_host_id, a.lobby_id) AS owner_id,
      coalesce(h.display_name, l.name::text) AS owner_name,
      h.avatar_url,
      fa.description, fa.capacity, fa.male_price, fa.female_price, fa.recommended_skills,
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
    FROM public.activity a
    JOIN public.freeplay_activity fa ON fa.activity_id=a.id
    LEFT JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
    LEFT JOIN public.lobby l ON l.id=a.lobby_id
    LEFT JOIN public.location loc ON loc.id=a.location_id
    WHERE a.sport_id=p_sport_id AND a.end_time>now() AND a.start_time<=now()+interval '7 days'
      AND fa.cancelled_at IS NULL AND fa.intake_closed_at IS NULL
      AND coalesce(loc.city_cluster,fa.city_cluster)=p_city
      AND (a.freeplay_host_id IS NULL OR h.status='active')
      AND (a.lobby_id IS NULL OR l.visibility <> 'private')
      AND (auth.uid() IS NULL OR NOT EXISTS(
            SELECT 1 FROM unnest(coalesce(public.fn_freeplay_owner_user_ids(a.id),'{}'::uuid[])) o
            WHERE public.fn_is_blocked(auth.uid(), o)))
  )
  SELECT c.id,c.owner_id,c.owner_name,c.avatar_url,c.owner_kind,c.description,c.start_time,c.end_time,
    c.location_id,c.resolved_venue,c.resolved_address,c.resolved_city,c.resolved_ward,c.capacity,
    c.accepted,c.male_price,c.female_price,c.recommended_skills,
    public.freeplay_user_skill(auth.uid(),p_sport_id),mr.id,mr.status::text
  FROM candidate c
  LEFT JOIN LATERAL (SELECT r.id,r.status FROM public.freeplay_request r
    WHERE r.activity_id=c.id AND r.user_id=auth.uid()
    ORDER BY r.created_at DESC LIMIT 1) mr ON true
  WHERE c.accepted<c.capacity
    AND (coalesce(cardinality(p_districts),0)=0 OR c.resolved_ward=ANY(p_districts))
    AND (coalesce(p_search,'')='' OR public.immutable_unaccent(
        coalesce(c.owner_name,'')||' '||coalesce(c.resolved_venue,'')||' '||coalesce(c.resolved_address,''))
      ILIKE '%'||public.immutable_unaccent(p_search)||'%')
    AND (p_timeslots='{}'::jsonb OR coalesce((p_timeslots->c.slot_day) ? c.slot_chunk,false))
  ORDER BY c.start_time,c.activity_created_at
  LIMIT greatest(1,least(p_page_size,50)) OFFSET greatest(0,(p_page_number-1)*p_page_size)
$$;

DROP FUNCTION IF EXISTS public.freeplay_activity_detail_data(uuid);
CREATE FUNCTION public.freeplay_activity_detail_data(p_activity_id uuid)
RETURNS TABLE(activity_id uuid, host_id uuid, host_name text, host_avatar_url text,
  owner_kind text, description text, start_time timestamptz, end_time timestamptz,
  location_id uuid, venue_name text, street_address text, location_street_number text,
  location_street_name text, location_district text, location_city text,
  location_lat double precision, location_lon double precision, capacity integer,
  accepted_count bigint, male_price numeric, female_price numeric, recommended_skills text[],
  my_request_id uuid, my_request_status text, roster jsonb)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid(); v_allowed boolean;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM public.activity a
    JOIN public.freeplay_activity fa ON fa.activity_id=a.id
    LEFT JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
    LEFT JOIN public.lobby l ON l.id=a.lobby_id
    WHERE a.id=p_activity_id AND (
      h.status='active'
      OR (a.lobby_id IS NOT NULL AND l.visibility <> 'private')
      OR public.fn_freeplay_can_manage(a.id, v_uid)
      OR EXISTS(SELECT 1 FROM public.freeplay_request r
                WHERE r.activity_id=a.id AND r.user_id=v_uid)))
  INTO v_allowed;
  IF NOT v_allowed THEN RETURN; END IF;

  RETURN QUERY
  SELECT a.id, coalesce(a.freeplay_host_id, a.lobby_id),
    coalesce(h.display_name, l.name::text), h.avatar_url,
    CASE WHEN a.freeplay_host_id IS NOT NULL THEN 'host' ELSE 'lobby' END,
    fa.description,a.start_time,a.end_time,
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
    CASE WHEN public.fn_freeplay_can_manage(a.id, v_uid) OR mr.status='accepted' THEN
      (SELECT coalesce(jsonb_agg(jsonb_build_object(
        'id',u.id,'username',u.username,
        'generatedAvatar',u.details->>'generatedAvatar','skill',x.skill)
        ORDER BY u.username),'[]'::jsonb)
       FROM public.freeplay_request x JOIN public."user" u ON u.id=x.user_id
       WHERE x.activity_id=a.id AND x.status='accepted')
    ELSE '[]'::jsonb END
  FROM public.activity a
  JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  LEFT JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  LEFT JOIN public.lobby l ON l.id=a.lobby_id
  LEFT JOIN public.location loc ON loc.id=a.location_id
  LEFT JOIN LATERAL(
    SELECT r.id,r.status FROM public.freeplay_request r
    WHERE r.activity_id=a.id AND r.user_id=v_uid
    ORDER BY r.created_at DESC LIMIT 1
  ) mr ON true
  WHERE a.id=p_activity_id;
END
$$;

CREATE OR REPLACE FUNCTION public.freeplay_activity_requests(p_activity_id uuid)
RETURNS TABLE(request_id uuid, user_id uuid, username text, generated_avatar text, status text,
  gender text, skill text, price_amount numeric, created_at timestamptz)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT r.id,r.user_id,u.username,u.details->>'generatedAvatar',r.status::text,r.gender,r.skill,
    r.price_amount,r.created_at
  FROM public.freeplay_request r JOIN public."user" u ON u.id=r.user_id
  WHERE r.activity_id=p_activity_id
    AND public.fn_freeplay_can_manage(p_activity_id, auth.uid())
  ORDER BY r.created_at
$$;

DROP FUNCTION IF EXISTS public.freeplay_my_data(boolean);
CREATE FUNCTION public.freeplay_my_data(p_history boolean DEFAULT false)
RETURNS TABLE(request_id uuid, request_status text, activity_id uuid, host_id uuid,
  host_name text, owner_kind text, description text, start_time timestamptz,
  end_time timestamptz, venue_name text, street_address text, capacity integer,
  accepted_count bigint, price_amount numeric, recommended_skills text[], can_write boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT r.id,r.status::text,a.id,
    coalesce(a.freeplay_host_id, a.lobby_id),
    coalesce(h.display_name, l.name::text),
    CASE WHEN a.freeplay_host_id IS NOT NULL THEN 'host' ELSE 'lobby' END,
    fa.description,a.start_time,a.end_time,
    coalesce(loc.name,fa.venue_name),coalesce(loc.full_address,fa.street_address),fa.capacity,
    (SELECT count(*) FROM public.freeplay_request x WHERE x.activity_id=a.id AND x.status='accepted'),
    r.price_amount,fa.recommended_skills,false
  FROM public.freeplay_request r
  JOIN public.activity a ON a.id=r.activity_id
  JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  LEFT JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  LEFT JOIN public.lobby l ON l.id=a.lobby_id
  LEFT JOIN public.location loc ON loc.id=a.location_id
  WHERE r.user_id=auth.uid() AND CASE WHEN p_history THEN
    (a.end_time<=now() OR r.status NOT IN ('pending','accepted'))
    ELSE (a.end_time>now() AND r.status IN ('pending','accepted')) END
  ORDER BY CASE WHEN p_history THEN NULL ELSE a.start_time END,
    CASE WHEN p_history THEN coalesce(r.resolved_at,a.end_time) END DESC
$$;

CREATE OR REPLACE FUNCTION public.my_schedule_data(p_sport_id bigint, p_from timestamptz, p_to timestamptz)
RETURNS TABLE(id uuid, start_time timestamptz, end_time timestamptz, title text, meta text,
  tone text, recurrence_day_of_week smallint)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
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
           coalesce(h.display_name, l.name::text, 'Xé vé')::text,
           COALESCE(loc.name, fa.venue_name, '')::text, 'freeplay'::text,
           a.recurrence_day_of_week
    FROM public.activity a
    JOIN public.freeplay_activity fa ON fa.activity_id = a.id
    LEFT JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
    LEFT JOIN public.lobby l ON l.id = a.lobby_id
    LEFT JOIN public.location loc ON loc.id = COALESCE(a.location_id, l.home_ground)
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

-- A guest with an accepted seat played the session, so it stays a health
-- capture candidate for them even though they hold no confirmation row.
CREATE OR REPLACE FUNCTION public.health_capture_candidates(p_window_start timestamptz)
RETURNS TABLE(activity_id uuid, start_time timestamptz, end_time timestamptz, sport_id bigint,
  source text, confirmed boolean)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid();
BEGIN
  RETURN QUERY SELECT a.id, a.start_time, a.end_time, a.sport_id,
    CASE WHEN a.course_id IS NOT NULL THEN 'professional'
      WHEN a.freeplay_host_id IS NOT NULL THEN 'freeplay'
      WHEN a.lobby_id IS NOT NULL THEN 'lobby' ELSE 'self' END,
    (EXISTS(SELECT 1 FROM public.activity_confirmation ac
            WHERE ac.activity_id = a.id AND ac.user_id = v_uid)
     OR EXISTS(SELECT 1 FROM public.freeplay_request r
               WHERE r.activity_id = a.id AND r.user_id = v_uid AND r.status = 'accepted'))
  FROM public.activity a
  WHERE a.end_time IS NOT NULL AND a.end_time < now() AND a.end_time >= p_window_start
    AND (a.user_id = v_uid
      OR EXISTS(SELECT 1 FROM public.activity_confirmation ac
                WHERE ac.activity_id = a.id AND ac.user_id = v_uid)
      OR EXISTS(SELECT 1 FROM public.freeplay_request r
                WHERE r.activity_id = a.id AND r.user_id = v_uid AND r.status = 'accepted'))
    AND NOT EXISTS(SELECT 1 FROM public.activity_health_metrics m
                   WHERE m.activity_id = a.id AND m.user_id = v_uid)
  ORDER BY a.end_time DESC;
END
$$;


-- ─── 7. Coupling: the lobby cannot quietly move or vaporise sold seats ──────

-- Same invariant `update_freeplay_activity` states for Hosts, enforced on the
-- lobby's own scheduling path.
CREATE OR REPLACE FUNCTION public.fn_activity_freeplay_lock()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
  IF (NEW.start_time, NEW.end_time, NEW.location_id)
     IS DISTINCT FROM (OLD.start_time, OLD.end_time, OLD.location_id)
     AND EXISTS (SELECT 1 FROM public.freeplay_activity fa
                 WHERE fa.activity_id = OLD.id AND fa.cancelled_at IS NULL)
     AND EXISTS (SELECT 1 FROM public.freeplay_request r
                 WHERE r.activity_id = OLD.id AND r.status IN ('pending','accepted'))
  THEN
    RAISE EXCEPTION 'activity_freeplay_locked: withdraw the Xé vé listing before changing time or venue';
  END IF;
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS activity_freeplay_lock ON public.activity;
CREATE TRIGGER activity_freeplay_lock
BEFORE UPDATE ON public.activity
FOR EACH ROW EXECUTE FUNCTION public.fn_activity_freeplay_lock();

-- `freeplay_activity` and `freeplay_request` are ON DELETE CASCADE, so without
-- this the threshold sweep's under-turnout auto-cancel (and a manager's plain
-- delete) would erase paid seats with no status and no notification.
CREATE OR REPLACE FUNCTION public.fn_activity_freeplay_cancel_cascade()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.freeplay_activity fa WHERE fa.activity_id = OLD.id) THEN
    PERFORM public.fn_cancel_freeplay_listing(OLD.id);
  END IF;
  RETURN OLD;
END
$$;

DROP TRIGGER IF EXISTS activity_freeplay_cancel_cascade ON public.activity;
CREATE TRIGGER activity_freeplay_cancel_cascade
BEFORE DELETE ON public.activity
FOR EACH ROW EXECUTE FUNCTION public.fn_activity_freeplay_cancel_cascade();

-- Going private would strand outsiders who already hold a seat, so it is a hard
-- error rather than a silent withdrawal: the manager withdraws the listings
-- deliberately, then changes visibility.
CREATE OR REPLACE FUNCTION public.fn_lobby_private_freeplay_guard()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
  IF NEW.visibility = 'private' AND OLD.visibility IS DISTINCT FROM 'private'
     AND public.fn_lobby_has_live_freeplay(OLD.id) THEN
    RAISE EXCEPTION 'lobby_private_blocked_by_freeplay: withdraw the Xé vé listings first';
  END IF;
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS lobby_private_freeplay_guard ON public.lobby;
CREATE TRIGGER lobby_private_freeplay_guard
BEFORE UPDATE ON public.lobby
FOR EACH ROW EXECUTE FUNCTION public.fn_lobby_private_freeplay_guard();


-- ─── 8. Grants ──────────────────────────────────────────────────────────────

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p.oid::regprocedure AS signature
           FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'public' AND p.proname IN (
             'expose_lobby_activity_freeplay','cancel_freeplay_activity','set_freeplay_intake',
             'update_freeplay_activity','edit_freeplay_listing','request_freeplay_seat',
             'respond_freeplay_request','cancel_freeplay_request','freeplay_activity_requests',
             'freeplay_activity_detail_data','freeplay_my_data','freeplay_conversation_id',
             'freeplay_chat_counterpart_data','my_schedule_data','health_capture_candidates')
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon', r.signature);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', r.signature);
  END LOOP;
END
$$;

REVOKE ALL ON FUNCTION public.home_freeplay_data(bigint,jsonb,integer,character varying[],text,integer,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.home_freeplay_data(bigint,jsonb,integer,character varying[],text,integer,integer) TO authenticated, anon;
