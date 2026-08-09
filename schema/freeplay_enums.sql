-- Freeplay / Xé vé enum prelude.
-- PostgreSQL enum additions must commit before functions can use the values,
-- so apply this migration before schema/freeplay.sql.

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'freeplay_host_status') THEN
    CREATE TYPE public.freeplay_host_status AS ENUM ('active', 'suspended');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'freeplay_request_status') THEN
    CREATE TYPE public.freeplay_request_status AS ENUM (
      'pending', 'accepted', 'declined', 'cancelled', 'host_cancelled', 'lapsed', 'blocked'
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'freeplay_message_kind') THEN
    CREATE TYPE public.freeplay_message_kind AS ENUM ('text', 'system', 'payment_info');
  END IF;
END
$$;

ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'freeplay_request_received';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'freeplay_request_accepted';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'freeplay_request_declined';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'freeplay_request_cancelled';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'freeplay_activity_cancelled';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'freeplay_chat_message';
