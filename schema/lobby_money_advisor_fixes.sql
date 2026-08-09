-- Follow-up for the already-applied lobby_money migration: cover every new
-- foreign key and let the read-only balance RPC run under the caller's RLS.

CREATE INDEX IF NOT EXISTS lobby_payment_request_payee_recipient_idx
    ON public.lobby_payment_request_payee (recipient_id);
CREATE INDEX IF NOT EXISTS lobby_payment_settlement_lobby_idx
    ON public.lobby_payment_settlement (lobby_id);
CREATE INDEX IF NOT EXISTS lobby_payment_settlement_recipient_idx
    ON public.lobby_payment_settlement (recipient_id);
CREATE INDEX IF NOT EXISTS lobby_payment_settlement_item_settlement_idx
    ON public.lobby_payment_settlement_item (settlement_id);

ALTER FUNCTION public.lobby_money_data(uuid) SECURITY INVOKER;
