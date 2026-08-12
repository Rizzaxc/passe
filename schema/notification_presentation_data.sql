-- Structured presentation values for notification-center rich text.
--
-- Native pushes still receive the same flat title/body required by FCM. At
-- enqueue time we additionally snapshot the domain values that the in-app
-- card may emphasize. The client chooses allowed fields by notification kind
-- and matches these values exactly; it never infers semantics from prose.

create or replace function public.fn_notification_presentation(
    p_kind public.notification_kind,
    p_data jsonb,
    p_body text
) returns jsonb
    language plpgsql stable security definer set search_path to ''
as $$
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
               coalesce(loc.name, b.custom_location_name),
               loc.full_address,
               case when b.agreed_rate is null then null
                    else b.agreed_rate::text || 'đ' end
          into v_start_time, v_location_name, v_address, v_amount
          from public.professional_booking b
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

revoke all on function public.fn_notification_presentation(
    public.notification_kind, jsonb, text
) from public, anon, authenticated;

create or replace function public.fn_enqueue_notification(
    p_kind       public.notification_kind,
    p_recipients uuid[],
    p_title      text,
    p_body       text,
    p_data       jsonb default '{}'::jsonb
) returns void
    language plpgsql security definer set search_path to ''
as $$
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

-- Preserve the server-only write boundary after replacing the function.
revoke all on function public.fn_enqueue_notification(
    public.notification_kind, uuid[], text, text, jsonb
) from public, anon, authenticated;

-- Enrich existing notification-center rows as the presentation contract gains
-- fields. Explicit values already stored on a row win over derived values. No
-- push is emitted because this is a metadata update, not an enqueue.
update public.notification_outbox o
   set data = o.data || jsonb_build_object(
       'presentation',
       public.fn_notification_presentation(o.kind, o.data, o.body)
       || coalesce(o.data->'presentation', '{}'::jsonb)
   ),
       updated_at = now()
 where public.fn_notification_presentation(o.kind, o.data, o.body)
       || coalesce(o.data->'presentation', '{}'::jsonb)
       <> coalesce(o.data->'presentation', '{}'::jsonb);
