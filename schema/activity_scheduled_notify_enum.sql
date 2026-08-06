-- New notification_kind value for "a lobby put up an activity" (activity creation
-- itself, not the later RSVP-quorum crossing that activity_confirmed already covers).
-- Split into its own file: a new enum value must commit before it can be referenced
-- by the emitter in schema/activity_scheduled_notify.sql (same pattern as
-- challenge_flow_enums.sql / lobby_payment_requests_enums.sql).

alter type public.notification_kind add value if not exists 'activity_scheduled';
