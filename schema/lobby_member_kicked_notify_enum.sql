-- New notification_kind value for "a captain removed you from their lobby".
-- Split into its own file: a new enum value must commit before it can be
-- referenced by the emitter in schema/lobby_member_kicked_notify.sql (same
-- pattern as challenge_flow_enums.sql / activity_scheduled_notify_enum.sql).

alter type public.notification_kind add value if not exists 'member_kicked';
