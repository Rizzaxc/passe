-- ============================================================================
-- payment_request_payload_shape_check.sql — lobby_feed_item_payload_shape
-- never got a clause for kind = 'payment_request'.
--
-- lobby_payment_requests_enums.sql added the enum value and
-- lobby_payment_requests.sql wired up create_ancillary_payment_request /
-- fn_sweep_activity_payment_requests to INSERT it, but nobody widened this
-- CHECK constraint — so every payment_request insert (both the manual
-- "Đòi Tiền" ancillary flow and the automatic post-session split sweep)
-- has been failing with a 23514 violation since the feature shipped.
--
-- Apply with execute_sql / apply_migration.
-- ============================================================================

ALTER TABLE public.lobby_feed_item
    DROP CONSTRAINT lobby_feed_item_payload_shape;

ALTER TABLE public.lobby_feed_item
    ADD CONSTRAINT lobby_feed_item_payload_shape CHECK (
        (kind = 'update'::public.lobby_feed_item_kind
            AND payload ? 'title' AND payload ? 'kind'
            AND payload ? 'tone' AND payload ? 'fields')
        OR (kind = 'personal'::public.lobby_feed_item_kind
            AND payload ? 'action_kind')
        OR (kind = 'system'::public.lobby_feed_item_kind
            AND payload ? 'text')
        OR (kind = 'poll'::public.lobby_feed_item_kind
            AND payload ? 'question' AND payload ? 'options')
        OR (kind = 'photo'::public.lobby_feed_item_kind
            AND payload ? 'storage_path')
        OR (kind = 'payment_request'::public.lobby_feed_item_kind
            AND payload ? 'type' AND payload ? 'recipient_id'
            AND payload ? 'total_amount' AND payload ? 'per_person_amount')
    );
