-- Part 2 of the professional-booking notification wiring — apply this AFTER
-- `schema/professional_booking_notifications.sql` has been applied and committed (its new enum
-- values can't be referenced in the same transaction they were added in).
--
-- Follows the exact shape of `fn_notify_lobby_invite` (schema/lobby_email_invite.sql): a single
-- SECURITY DEFINER trigger function per event, one `fn_enqueue_notification` call, live (not
-- dark-launched) since these are core to the feature, not experimental.

INSERT INTO public.enabled_notification_kind (kind, enabled) VALUES
    ('professional_booking_requested', true),
    ('professional_booking_confirmed', true),
    ('professional_booking_rejected', true)
ON CONFLICT (kind) DO NOTHING;

-- ── Notify the professional when a booking request comes in ────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_notify_professional_booking_created()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    v_professional_user_id uuid;
    v_client_name text;
BEGIN
    SELECT linked_user_id INTO v_professional_user_id
    FROM public.professional
    WHERE id = NEW.professional_id;

    IF v_professional_user_id IS NULL THEN
        RETURN NEW; -- no linked account yet, nothing to notify
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

CREATE TRIGGER professional_booking_created_notify
    AFTER INSERT ON public.professional_booking
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_notify_professional_booking_created();

-- ── Notify the client when the professional confirms or rejects ────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_notify_professional_booking_status_changed()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
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

CREATE TRIGGER professional_booking_status_changed_notify
    AFTER UPDATE ON public.professional_booking
    FOR EACH ROW
    WHEN (NEW.status IS DISTINCT FROM OLD.status AND NEW.status IN ('confirmed', 'rejected'))
    EXECUTE FUNCTION public.fn_notify_professional_booking_status_changed();
