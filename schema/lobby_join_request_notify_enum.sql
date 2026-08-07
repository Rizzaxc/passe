-- Notification kinds for the lobby join-request lifecycle.
--
-- Keep these enum additions in their own migration: PostgreSQL cannot use a
-- newly-added enum value until the transaction that added it has committed.

alter type public.notification_kind
    add value if not exists 'lobby_join_request';

alter type public.notification_kind
    add value if not exists 'lobby_join_request_approved';

alter type public.notification_kind
    add value if not exists 'lobby_join_request_denied';
