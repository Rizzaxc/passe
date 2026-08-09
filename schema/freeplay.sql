-- Freeplay / Xé vé: standalone Host activities, seat requests and request chat.
-- Requires schema/freeplay_enums.sql first.

CREATE TABLE IF NOT EXISTS public.freeplay_host (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES public."user"(id) ON DELETE RESTRICT,
  display_name text NOT NULL CHECK (char_length(btrim(display_name)) BETWEEN 1 AND 80),
  avatar_url text,
  bio text NOT NULL DEFAULT '' CHECK (char_length(bio) <= 500),
  status public.freeplay_host_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.activity ADD COLUMN IF NOT EXISTS freeplay_host_id uuid
  REFERENCES public.freeplay_host(id) ON DELETE RESTRICT;

ALTER TABLE public.activity DROP CONSTRAINT IF EXISTS activity_source_exclusivity;
ALTER TABLE public.activity ADD CONSTRAINT activity_source_exclusivity CHECK (
  num_nonnulls(lobby_id, professional_booking_id, freeplay_host_id) <= 1
);

CREATE TABLE IF NOT EXISTS public.freeplay_activity (
  activity_id uuid PRIMARY KEY REFERENCES public.activity(id) ON DELETE CASCADE,
  description text NOT NULL DEFAULT '' CHECK (char_length(description) <= 2000),
  capacity integer NOT NULL CHECK (capacity BETWEEN 1 AND 200),
  male_price numeric(10,2) NOT NULL CHECK (male_price > 0),
  female_price numeric(10,2) NOT NULL CHECK (female_price > 0),
  recommended_skills text[] NOT NULL CHECK (
    cardinality(recommended_skills) > 0
    AND recommended_skills <@ ARRAY['beginner','casual','tryhard']::text[]
  ),
  venue_name text,
  street_address text,
  city_cluster bigint REFERENCES public.supported_city_cluster(id),
  ward text,
  intake_closed_at timestamptz,
  cancelled_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT freeplay_free_venue_complete CHECK (
    (venue_name IS NULL AND street_address IS NULL AND ward IS NULL)
    OR
    (char_length(btrim(venue_name)) > 0 AND char_length(btrim(street_address)) > 0
      AND city_cluster IS NOT NULL AND char_length(btrim(ward)) > 0)
  )
);

CREATE TABLE IF NOT EXISTS public.freeplay_request (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id uuid NOT NULL REFERENCES public.freeplay_activity(activity_id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
  status public.freeplay_request_status NOT NULL DEFAULT 'pending',
  price_amount numeric(10,2) NOT NULL CHECK (price_amount > 0),
  gender text NOT NULL CHECK (gender IN ('male','female')),
  skill text CHECK (skill IS NULL OR skill IN ('beginner','casual','tryhard')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS freeplay_request_one_active
  ON public.freeplay_request(activity_id, user_id)
  WHERE status IN ('pending','accepted');
CREATE INDEX IF NOT EXISTS freeplay_request_activity_status_idx
  ON public.freeplay_request(activity_id, status, created_at);
CREATE INDEX IF NOT EXISTS freeplay_request_user_idx
  ON public.freeplay_request(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.freeplay_chat_message (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid NOT NULL REFERENCES public.freeplay_request(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES public."user"(id) ON DELETE SET NULL,
  kind public.freeplay_message_kind NOT NULL,
  body text,
  payment_info_id uuid REFERENCES public.user_payment_info(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT freeplay_message_shape CHECK (
    (kind = 'text' AND sender_id IS NOT NULL AND char_length(btrim(body)) BETWEEN 1 AND 2000 AND payment_info_id IS NULL)
    OR (kind = 'system' AND sender_id IS NULL AND char_length(btrim(body)) BETWEEN 1 AND 500 AND payment_info_id IS NULL)
    OR (kind = 'payment_info' AND sender_id IS NOT NULL AND payment_info_id IS NOT NULL AND body IS NULL)
  )
);
CREATE INDEX IF NOT EXISTS freeplay_chat_message_request_idx
  ON public.freeplay_chat_message(request_id, created_at);

ALTER TABLE public.freeplay_host ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.freeplay_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.freeplay_request ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.freeplay_chat_message ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.freeplay_host, public.freeplay_activity,
  public.freeplay_request, public.freeplay_chat_message FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.freeplay_user_skill(p_user_id uuid, p_sport_id bigint)
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT CASE p_sport_id
    WHEN 1 THEN (SELECT elo_seed FROM public.soccer_profile WHERE user_id = p_user_id)
    WHEN 2 THEN (SELECT elo_seed FROM public.basketball_profile WHERE user_id = p_user_id)
    WHEN 3 THEN (SELECT elo_seed FROM public.badminton_profile WHERE user_id = p_user_id)
    WHEN 4 THEN (SELECT elo_seed FROM public.tennis_profile WHERE user_id = p_user_id)
    WHEN 5 THEN (SELECT elo_seed FROM public.pickleball_profile WHERE user_id = p_user_id)
  END
$$;
REVOKE ALL ON FUNCTION public.freeplay_user_skill(uuid, bigint) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.my_freeplay_host()
RETURNS TABLE(id uuid, user_id uuid, display_name text, avatar_url text, bio text, status text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT h.id, h.user_id, h.display_name, h.avatar_url, h.bio, h.status::text
  FROM public.freeplay_host h
  WHERE h.user_id = auth.uid() AND h.status = 'active'
$$;

CREATE OR REPLACE FUNCTION public.freeplay_host_profile_data(p_host_id uuid)
RETURNS TABLE(id uuid, display_name text, avatar_url text, bio text, completed_count bigint)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT h.id, h.display_name, h.avatar_url, h.bio,
    count(a.id) FILTER (WHERE a.end_time <= now() AND fa.cancelled_at IS NULL)
  FROM public.freeplay_host h
  LEFT JOIN public.activity a ON a.freeplay_host_id = h.id
  LEFT JOIN public.freeplay_activity fa ON fa.activity_id = a.id
  WHERE h.id = p_host_id AND h.status = 'active'
  GROUP BY h.id
$$;

CREATE OR REPLACE FUNCTION public.create_freeplay_activity(
  p_sport_id bigint, p_start_time timestamptz, p_end_time timestamptz,
  p_capacity integer, p_male_price numeric, p_female_price numeric,
  p_recommended_skills text[], p_description text DEFAULT '',
  p_location_id uuid DEFAULT NULL, p_venue_name text DEFAULT NULL,
  p_street_address text DEFAULT NULL, p_city_cluster bigint DEFAULT NULL,
  p_ward text DEFAULT NULL
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_host uuid; v_activity uuid; v_loc_city bigint; v_loc_ward text;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;
  SELECT id INTO v_host FROM public.freeplay_host WHERE user_id=v_uid AND status='active';
  IF v_host IS NULL THEN RAISE EXCEPTION 'active Host profile required'; END IF;
  IF p_sport_id NOT BETWEEN 1 AND 5 OR p_end_time <= p_start_time OR p_end_time <= now() THEN
    RAISE EXCEPTION 'invalid activity terms';
  END IF;
  IF p_location_id IS NOT NULL THEN
    SELECT city_cluster, district INTO v_loc_city, v_loc_ward FROM public.location WHERE id=p_location_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'location not found'; END IF;
  ELSIF nullif(btrim(p_venue_name),'') IS NULL OR nullif(btrim(p_street_address),'') IS NULL
     OR p_city_cluster IS NULL OR nullif(btrim(p_ward),'') IS NULL THEN
    RAISE EXCEPTION 'free venue requires name, address, city and ward';
  END IF;
  INSERT INTO public.activity(user_id,sport_id,start_time,end_time,location_id,freeplay_host_id)
  VALUES(v_uid,p_sport_id,p_start_time,p_end_time,p_location_id,v_host) RETURNING id INTO v_activity;
  INSERT INTO public.freeplay_activity(activity_id,description,capacity,male_price,female_price,
    recommended_skills,venue_name,street_address,city_cluster,ward)
  VALUES(v_activity,coalesce(p_description,''),p_capacity,p_male_price,p_female_price,
    p_recommended_skills,CASE WHEN p_location_id IS NULL THEN btrim(p_venue_name) END,
    CASE WHEN p_location_id IS NULL THEN btrim(p_street_address) END,
    coalesce(p_city_cluster,v_loc_city),CASE WHEN p_location_id IS NULL THEN p_ward ELSE v_loc_ward END);
  RETURN v_activity;
END
$$;

CREATE OR REPLACE FUNCTION public.update_freeplay_activity(
  p_activity_id uuid, p_start_time timestamptz, p_end_time timestamptz,
  p_capacity integer, p_male_price numeric, p_female_price numeric,
  p_recommended_skills text[], p_description text,
  p_location_id uuid DEFAULT NULL, p_venue_name text DEFAULT NULL,
  p_street_address text DEFAULT NULL, p_city_cluster bigint DEFAULT NULL, p_ward text DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
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

CREATE OR REPLACE FUNCTION public.set_freeplay_intake(p_activity_id uuid, p_closed boolean)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
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

CREATE OR REPLACE FUNCTION public.cancel_freeplay_activity(p_activity_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid(); v_user_ids uuid[];
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.activity a JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
    WHERE a.id=p_activity_id AND h.user_id=v_uid) THEN RAISE EXCEPTION 'activity not found or not owned'; END IF;
  UPDATE public.freeplay_activity SET cancelled_at=coalesce(cancelled_at,now()),intake_closed_at=coalesce(intake_closed_at,now()),updated_at=now()
  WHERE activity_id=p_activity_id;
  UPDATE public.freeplay_request SET status='host_cancelled',resolved_at=now(),updated_at=now()
  WHERE activity_id=p_activity_id AND status IN ('pending','accepted');
  DELETE FROM public.activity_confirmation WHERE activity_id=p_activity_id;
  INSERT INTO public.freeplay_chat_message(request_id,kind,body)
    SELECT id,'system','activity_cancelled' FROM public.freeplay_request WHERE activity_id=p_activity_id;
  SELECT array_agg(DISTINCT user_id) INTO v_user_ids FROM public.freeplay_request WHERE activity_id=p_activity_id;
  IF cardinality(v_user_ids)>0 THEN
    PERFORM public.fn_enqueue_notification('freeplay_activity_cancelled',v_user_ids,'Buổi Xé vé đã huỷ',
      'Host đã huỷ buổi chơi.',jsonb_build_object('activity_id',p_activity_id));
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION public.request_freeplay_seat(p_activity_id uuid, p_message text DEFAULT NULL)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid(); v_row record; v_gender text; v_skill text; v_id uuid; v_count integer;
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
  IF nullif(btrim(p_message),'') IS NOT NULL THEN
    INSERT INTO public.freeplay_chat_message(request_id,sender_id,kind,body) VALUES(v_id,v_uid,'text',btrim(p_message));
  END IF;
  PERFORM public.fn_enqueue_notification('freeplay_request_received',ARRAY[v_row.host_user_id],
    'Yêu cầu Xé vé mới','Có người muốn tham gia buổi chơi của bạn.',
    jsonb_build_object('activity_id',p_activity_id,'request_id',v_id));
  RETURN v_id;
END
$$;

CREATE OR REPLACE FUNCTION public.respond_freeplay_request(p_request_id uuid, p_accept boolean)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid(); v_row record; v_count integer;
BEGIN
  SELECT r.*,fa.capacity,a.end_time,h.user_id host_user_id INTO v_row
  FROM public.freeplay_request r JOIN public.freeplay_activity fa ON fa.activity_id=r.activity_id
  JOIN public.activity a ON a.id=r.activity_id JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE r.id=p_request_id AND h.user_id=v_uid FOR UPDATE OF r,fa;
  IF NOT FOUND OR v_row.status<>'pending' THEN RAISE EXCEPTION 'pending request not found'; END IF;
  IF v_row.end_time<=now() THEN RAISE EXCEPTION 'activity ended'; END IF;
  IF p_accept THEN
    SELECT count(*) INTO v_count FROM public.freeplay_request WHERE activity_id=v_row.activity_id AND status='accepted';
    IF v_count>=v_row.capacity THEN RAISE EXCEPTION 'activity is full'; END IF;
    UPDATE public.freeplay_request SET status='accepted',resolved_at=now(),updated_at=now() WHERE id=p_request_id;
    INSERT INTO public.activity_confirmation(activity_id,user_id,attendance)
    VALUES(v_row.activity_id,v_row.user_id,'going') ON CONFLICT(activity_id,user_id)
    DO UPDATE SET attendance='going',confirmed_at=now();
    INSERT INTO public.freeplay_chat_message(request_id,kind,body) VALUES(p_request_id,'system','request_accepted');
    PERFORM public.fn_enqueue_notification('freeplay_request_accepted',ARRAY[v_row.user_id],
      'Đã nhận chỗ Xé vé','Host đã duyệt yêu cầu của bạn.',jsonb_build_object('activity_id',v_row.activity_id,'request_id',p_request_id));
  ELSE
    UPDATE public.freeplay_request SET status='declined',resolved_at=now(),updated_at=now() WHERE id=p_request_id;
    INSERT INTO public.freeplay_chat_message(request_id,kind,body) VALUES(p_request_id,'system','request_declined');
    PERFORM public.fn_enqueue_notification('freeplay_request_declined',ARRAY[v_row.user_id],
      'Yêu cầu Xé vé bị từ chối','Host đã từ chối yêu cầu của bạn.',jsonb_build_object('activity_id',v_row.activity_id,'request_id',p_request_id));
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION public.cancel_freeplay_request(p_request_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid(); v_row record;
BEGIN
  SELECT r.*,a.end_time,h.user_id host_user_id INTO v_row FROM public.freeplay_request r
  JOIN public.activity a ON a.id=r.activity_id JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE r.id=p_request_id AND r.user_id=v_uid FOR UPDATE OF r;
  IF NOT FOUND OR v_row.status NOT IN ('pending','accepted') OR v_row.end_time<=now() THEN
    RAISE EXCEPTION 'active request not found';
  END IF;
  UPDATE public.freeplay_request SET status='cancelled',resolved_at=now(),updated_at=now() WHERE id=p_request_id;
  DELETE FROM public.activity_confirmation WHERE activity_id=v_row.activity_id AND user_id=v_uid;
  INSERT INTO public.freeplay_chat_message(request_id,kind,body) VALUES(p_request_id,'system','request_cancelled');
  PERFORM public.fn_enqueue_notification('freeplay_request_cancelled',ARRAY[v_row.host_user_id],
    'Người chơi đã huỷ','Một người chơi đã huỷ yêu cầu Xé vé.',jsonb_build_object('activity_id',v_row.activity_id,'request_id',p_request_id));
END
$$;

CREATE OR REPLACE FUNCTION public.freeplay_chat_can_write(p_request_id uuid, p_uid uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT CASE
    WHEN r.status='pending' THEN a.end_time>now()
    WHEN r.status='accepted' THEN a.end_time+interval '7 days'>now()
    WHEN r.status='host_cancelled' THEN a.end_time+interval '7 days'>now()
    ELSE false END
  FROM public.freeplay_request r JOIN public.activity a ON a.id=r.activity_id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE r.id=p_request_id AND (r.user_id=p_uid OR h.user_id=p_uid)
    AND NOT public.fn_is_blocked(r.user_id,h.user_id)
$$;
REVOKE ALL ON FUNCTION public.freeplay_chat_can_write(uuid,uuid) FROM PUBLIC,anon,authenticated;

CREATE OR REPLACE FUNCTION public.send_freeplay_message(p_request_id uuid, p_body text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid(); v_id uuid; v_recipient uuid; v_activity uuid;
BEGIN
  IF NOT coalesce(public.freeplay_chat_can_write(p_request_id,v_uid),false) THEN RAISE EXCEPTION 'chat is read-only'; END IF;
  IF nullif(btrim(p_body),'') IS NULL OR char_length(btrim(p_body))>2000 THEN RAISE EXCEPTION 'invalid message'; END IF;
  INSERT INTO public.freeplay_chat_message(request_id,sender_id,kind,body)
  VALUES(p_request_id,v_uid,'text',btrim(p_body)) RETURNING id INTO v_id;
  SELECT CASE WHEN r.user_id=v_uid THEN h.user_id ELSE r.user_id END,r.activity_id INTO v_recipient,v_activity
  FROM public.freeplay_request r JOIN public.activity a ON a.id=r.activity_id JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE r.id=p_request_id;
  PERFORM public.fn_enqueue_notification('freeplay_chat_message',ARRAY[v_recipient],
    'Tin nhắn Xé vé mới','Bạn có tin nhắn mới.',jsonb_build_object('activity_id',v_activity,'request_id',p_request_id));
  RETURN v_id;
END
$$;

CREATE OR REPLACE FUNCTION public.share_freeplay_payment_info(p_request_id uuid)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid(); v_info uuid; v_id uuid; v_activity uuid; v_recipient uuid;
BEGIN
  IF NOT coalesce(public.freeplay_chat_can_write(p_request_id,v_uid),false) THEN RAISE EXCEPTION 'chat is read-only'; END IF;
  SELECT i.id INTO v_info FROM public.user_payment_info i WHERE i.user_id=v_uid;
  IF v_info IS NULL THEN RAISE EXCEPTION 'payment info not configured'; END IF;
  SELECT r.activity_id,r.user_id INTO v_activity,v_recipient FROM public.freeplay_request r
  JOIN public.activity a ON a.id=r.activity_id JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE r.id=p_request_id AND h.user_id=v_uid;
  IF NOT FOUND THEN RAISE EXCEPTION 'Host access required'; END IF;
  INSERT INTO public.freeplay_chat_message(request_id,sender_id,kind,payment_info_id)
  VALUES(p_request_id,v_uid,'payment_info',v_info) RETURNING id INTO v_id;
  PERFORM public.fn_enqueue_notification('freeplay_chat_message',ARRAY[v_recipient],
    'Host đã gửi thông tin thanh toán','Mở chat Xé vé để xem VietQR.',jsonb_build_object('activity_id',v_activity,'request_id',p_request_id));
  RETURN v_id;
END
$$;

CREATE OR REPLACE FUNCTION public.freeplay_chat_data(p_request_id uuid)
RETURNS TABLE(id uuid, sender_id uuid, kind text, body text, created_at timestamptz, can_write boolean, payment_info jsonb)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid();
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.freeplay_request r JOIN public.activity a ON a.id=r.activity_id
    JOIN public.freeplay_host h ON h.id=a.freeplay_host_id WHERE r.id=p_request_id AND (r.user_id=v_uid OR h.user_id=v_uid)) THEN
    RAISE EXCEPTION 'chat not found';
  END IF;
  RETURN QUERY SELECT m.id,m.sender_id,m.kind::text,m.body,m.created_at,
    coalesce(public.freeplay_chat_can_write(p_request_id,v_uid),false),
    CASE WHEN m.kind='payment_info' THEN jsonb_build_object('id',i.id,'bank_id',i.bank_id,
      'bank_display_name',i.bank_display_name,'value',vv.decrypted_secret,'account_name',vn.decrypted_secret,
      'created_at',i.created_at) END
  FROM public.freeplay_chat_message m
  LEFT JOIN public.user_payment_info i ON i.id=m.payment_info_id
  LEFT JOIN vault.decrypted_secrets vv ON vv.id=i.value_secret_id
  LEFT JOIN vault.decrypted_secrets vn ON vn.id=i.account_name_secret_id
  WHERE m.request_id=p_request_id ORDER BY m.created_at;
END
$$;

CREATE OR REPLACE FUNCTION public.home_freeplay_data(
  p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts varchar[],
  p_search text DEFAULT '', p_page_size integer DEFAULT 20, p_page_number integer DEFAULT 1
) RETURNS TABLE(
  activity_id uuid, host_id uuid, host_name text, host_avatar_url text, description text,
  start_time timestamptz, end_time timestamptz, location_id uuid, venue_name text, street_address text,
  city_cluster bigint, ward text, capacity integer, accepted_count bigint,
  male_price numeric, female_price numeric, recommended_skills text[], my_skill text,
  my_request_id uuid, my_request_status text
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
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

CREATE OR REPLACE FUNCTION public.freeplay_my_data(p_history boolean DEFAULT false)
RETURNS TABLE(
  request_id uuid, request_status text, activity_id uuid, host_id uuid, host_name text, description text,
  start_time timestamptz, end_time timestamptz, venue_name text, street_address text, capacity integer,
  accepted_count bigint, price_amount numeric, recommended_skills text[], can_write boolean
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT r.id,r.status::text,a.id,h.id,h.display_name,fa.description,a.start_time,a.end_time,
    coalesce(loc.name,fa.venue_name),coalesce(loc.full_address,fa.street_address),fa.capacity,
    (SELECT count(*) FROM public.freeplay_request x WHERE x.activity_id=a.id AND x.status='accepted'),
    r.price_amount,fa.recommended_skills,coalesce(public.freeplay_chat_can_write(r.id,auth.uid()),false)
  FROM public.freeplay_request r JOIN public.activity a ON a.id=r.activity_id
  JOIN public.freeplay_activity fa ON fa.activity_id=a.id JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  LEFT JOIN public.location loc ON loc.id=a.location_id
  WHERE r.user_id=auth.uid() AND CASE WHEN p_history THEN
    (a.end_time<=now() OR r.status NOT IN ('pending','accepted'))
    ELSE (a.end_time>now() AND r.status IN ('pending','accepted')) END
  ORDER BY CASE WHEN p_history THEN NULL ELSE a.start_time END,
    CASE WHEN p_history THEN coalesce(r.resolved_at,a.end_time) END DESC
$$;

CREATE OR REPLACE FUNCTION public.freeplay_host_data(p_history boolean DEFAULT false)
RETURNS TABLE(activity_id uuid, description text, start_time timestamptz, end_time timestamptz,
  venue_name text, capacity integer, accepted_count bigint, pending_count bigint, intake_closed boolean, cancelled boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT a.id,fa.description,a.start_time,a.end_time,coalesce(loc.name,fa.venue_name),fa.capacity,
    count(r.id) FILTER(WHERE r.status='accepted'),count(r.id) FILTER(WHERE r.status='pending'),
    fa.intake_closed_at IS NOT NULL,fa.cancelled_at IS NOT NULL
  FROM public.activity a JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id LEFT JOIN public.location loc ON loc.id=a.location_id
  LEFT JOIN public.freeplay_request r ON r.activity_id=a.id
  WHERE h.user_id=auth.uid() AND (p_history=(a.end_time<=now() OR fa.cancelled_at IS NOT NULL))
  GROUP BY a.id,fa.activity_id,loc.name ORDER BY a.start_time DESC
$$;

CREATE OR REPLACE FUNCTION public.freeplay_activity_requests(p_activity_id uuid)
RETURNS TABLE(request_id uuid, user_id uuid, username text, generated_avatar text, status text,
  gender text, skill text, price_amount numeric, created_at timestamptz)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT r.id,r.user_id,u.username,u.details->>'generatedAvatar',r.status::text,r.gender,r.skill,r.price_amount,r.created_at
  FROM public.freeplay_request r JOIN public."user" u ON u.id=r.user_id
  JOIN public.activity a ON a.id=r.activity_id JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE r.activity_id=p_activity_id AND h.user_id=auth.uid() ORDER BY r.created_at
$$;

CREATE OR REPLACE FUNCTION public.freeplay_activity_detail_data(p_activity_id uuid)
RETURNS TABLE(
  activity_id uuid, host_id uuid, host_name text, host_avatar_url text, description text,
  start_time timestamptz, end_time timestamptz, venue_name text, street_address text,
  capacity integer, accepted_count bigint, male_price numeric, female_price numeric,
  recommended_skills text[], my_request_id uuid, my_request_status text, roster jsonb
) LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid(); v_allowed boolean;
BEGIN
  SELECT EXISTS(SELECT 1 FROM public.activity a JOIN public.freeplay_activity fa ON fa.activity_id=a.id
    JOIN public.freeplay_host h ON h.id=a.freeplay_host_id WHERE a.id=p_activity_id AND
    (h.status='active' OR h.user_id=v_uid OR EXISTS(SELECT 1 FROM public.freeplay_request r WHERE r.activity_id=a.id AND r.user_id=v_uid)))
  INTO v_allowed;
  IF NOT v_allowed THEN RETURN; END IF;
  RETURN QUERY SELECT a.id,h.id,h.display_name,h.avatar_url,fa.description,a.start_time,a.end_time,
    coalesce(loc.name,fa.venue_name),coalesce(loc.full_address,fa.street_address),fa.capacity,
    (SELECT count(*) FROM public.freeplay_request x WHERE x.activity_id=a.id AND x.status='accepted'),
    fa.male_price,fa.female_price,fa.recommended_skills,mr.id,mr.status::text,
    CASE WHEN h.user_id=v_uid OR mr.status='accepted' THEN
      (SELECT coalesce(jsonb_agg(jsonb_build_object('id',u.id,'username',u.username,
        'generatedAvatar',u.details->>'generatedAvatar','skill',x.skill) ORDER BY u.username),'[]'::jsonb)
       FROM public.freeplay_request x JOIN public."user" u ON u.id=x.user_id
       WHERE x.activity_id=a.id AND x.status='accepted') ELSE '[]'::jsonb END
  FROM public.activity a JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id LEFT JOIN public.location loc ON loc.id=a.location_id
  LEFT JOIN LATERAL(SELECT r.id,r.status FROM public.freeplay_request r WHERE r.activity_id=a.id AND r.user_id=v_uid
    ORDER BY r.created_at DESC LIMIT 1) mr ON true WHERE a.id=p_activity_id;
END
$$;

CREATE OR REPLACE FUNCTION public.fn_sweep_freeplay()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
  UPDATE public.freeplay_request r SET status='lapsed',resolved_at=now(),updated_at=now()
  FROM public.activity a WHERE a.id=r.activity_id AND r.status='pending' AND a.end_time<=now();
END
$$;
REVOKE ALL ON FUNCTION public.fn_sweep_freeplay() FROM PUBLIC,anon,authenticated;

CREATE OR REPLACE FUNCTION public.fn_freeplay_block_cleanup()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
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
DROP TRIGGER IF EXISTS freeplay_block_cleanup ON public.user_block;
CREATE TRIGGER freeplay_block_cleanup AFTER INSERT ON public.user_block
FOR EACH ROW EXECUTE FUNCTION public.fn_freeplay_block_cleanup();

CREATE OR REPLACE FUNCTION public.my_schedule_data(p_sport_id bigint,p_from timestamptz,p_to timestamptz)
RETURNS TABLE(id uuid,start_time timestamptz,end_time timestamptz,title text,meta text,tone text,recurrence_day_of_week smallint)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid();
BEGIN
  IF v_uid IS NULL THEN RETURN; END IF;
  RETURN QUERY
  SELECT a.id,a.start_time,a.end_time,l.name::text,
    (CASE WHEN loc.name IS NOT NULL AND loc.name<>'' THEN loc.name||' · ' ELSE '' END||l.member_count||' người')::text,
    'sport'::text,a.recurrence_day_of_week
  FROM public.activity a JOIN public.lobby l ON l.id=a.lobby_id LEFT JOIN public.location loc ON loc.id=coalesce(a.location_id,l.home_ground)
  WHERE (p_sport_id IS NULL OR a.sport_id=p_sport_id) AND a.lobby_id IN(SELECT lobby_id FROM public.lobby_member WHERE user_id=v_uid)
    AND a.start_time>=p_from AND a.start_time<=p_to
  UNION ALL
  SELECT a.id,a.start_time,a.end_time,(p.display_name||' · '||ps.service_type)::text,coalesce(loc.name,'')::text,
    'coach'::text,a.recurrence_day_of_week
  FROM public.activity a JOIN public.professional_booking pb ON pb.id=a.professional_booking_id
  JOIN public.professional p ON p.id=pb.professional_id JOIN public.professional_service ps ON ps.id=pb.service_id
  LEFT JOIN public.location loc ON loc.id=coalesce(a.location_id,pb.location_id)
  WHERE (p_sport_id IS NULL OR a.sport_id=p_sport_id) AND pb.client_user_id=v_uid AND a.start_time>=p_from AND a.start_time<=p_to
  UNION ALL
  SELECT a.id,a.start_time,a.end_time,h.display_name,
    coalesce(loc.name,fa.venue_name,'')::text,'freeplay'::text,NULL::smallint
  FROM public.activity a JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id LEFT JOIN public.location loc ON loc.id=a.location_id
  JOIN public.freeplay_request r ON r.activity_id=a.id AND r.user_id=v_uid AND r.status='accepted'
  WHERE (p_sport_id IS NULL OR a.sport_id=p_sport_id) AND fa.cancelled_at IS NULL AND a.start_time>=p_from AND a.start_time<=p_to;
END
$$;

INSERT INTO public.enabled_notification_kind(kind,enabled) VALUES
 ('freeplay_request_received',true),('freeplay_request_accepted',true),
 ('freeplay_request_declined',true),('freeplay_request_cancelled',true),
 ('freeplay_activity_cancelled',true),('freeplay_chat_message',true)
ON CONFLICT(kind) DO UPDATE SET enabled=excluded.enabled;

CREATE OR REPLACE FUNCTION public.fn_cron_tick()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
  PERFORM public.fn_sweep_challenges();
  PERFORM public.fn_sweep_freeplay();
  PERFORM public.fn_process_reminders();
  IF EXISTS(SELECT 1 FROM public.notification_outbox WHERE status IN ('pending','sending')) THEN
    PERFORM public.fn_invoke_send_push();
  END IF;
END
$$;

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p.oid::regprocedure AS signature FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND p.proname IN (
      'my_freeplay_host','freeplay_host_profile_data','create_freeplay_activity','update_freeplay_activity',
      'set_freeplay_intake','cancel_freeplay_activity','request_freeplay_seat','respond_freeplay_request',
      'cancel_freeplay_request','send_freeplay_message','share_freeplay_payment_info','freeplay_chat_data',
      'home_freeplay_data','freeplay_my_data','freeplay_host_data','freeplay_activity_requests',
      'freeplay_activity_detail_data')
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon',r.signature);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated',r.signature);
  END LOOP;
END
$$;
GRANT EXECUTE ON FUNCTION public.home_freeplay_data(bigint,jsonb,integer,varchar[],text,integer,integer) TO anon;
