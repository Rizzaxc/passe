-- Push notifications for the professional booking pro-side flow: notify the professional when a
-- booking request comes in, notify the client when the professional confirms or rejects it.
--
-- Postgres forbids using a newly-added enum value inside the same transaction that added it, so
-- this ADD VALUE step must be applied and committed *before*
-- `schema/professional_booking_notifications_triggers.sql` (which references these values) runs —
-- same precedent as `schema/lobby_email_invite.sql`'s `lobby_invite` addition. Apply this file
-- first, as its own migration, then apply the triggers file separately.

ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'professional_booking_requested';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'professional_booking_confirmed';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'professional_booking_rejected';
