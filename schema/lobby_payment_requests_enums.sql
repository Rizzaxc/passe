-- ============================================================================
-- lobby_payment_requests_enums.sql — Part A of the payment-request feature
-- (chia tiền / đòi tiền trà đá).
--
-- Postgres cannot use an enum value in the same transaction that adds it, so
-- every ADD VALUE lives here as its own migration and `lobby_payment_requests.sql`
-- (Part B) consumes them. Same two-step pattern as `challenge_flow_enums.sql`.
--
-- Apply this FIRST, then `lobby_payment_requests.sql`.
-- ============================================================================

-- ─── New feed item kind: a payment request (split-cost or ancillary) ───────
ALTER TYPE public.lobby_feed_item_kind ADD VALUE IF NOT EXISTS 'payment_request';

-- ─── Notification kinds ─────────────────────────────────────────────────────
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'payment_requested';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'debt_collected';
