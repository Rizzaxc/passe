-- ============================================================================
-- Cap user_payment_info to one row per user — payment requests need a single
-- unambiguous "pay this person here" target, and a picker between multiple
-- saved accounts adds a step nobody asked for. No preservation of which
-- duplicate "wins": existing extra rows are dropped, keeping only the most
-- recently added one per user.
-- ============================================================================

DO $$
DECLARE
    v_orphaned_secret_ids uuid[];
BEGIN
    SELECT array_agg(value_secret_id) || array_agg(account_name_secret_id)
      INTO v_orphaned_secret_ids
      FROM public.user_payment_info a
     WHERE EXISTS (
         SELECT 1 FROM public.user_payment_info b
          WHERE b.user_id = a.user_id AND b.created_at > a.created_at
     );

    DELETE FROM public.user_payment_info a
     USING public.user_payment_info b
     WHERE a.user_id = b.user_id AND a.created_at < b.created_at;

    DELETE FROM vault.secrets WHERE id = ANY(v_orphaned_secret_ids);
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'user_payment_info_user_id_key'
    ) THEN
        ALTER TABLE public.user_payment_info
            ADD CONSTRAINT user_payment_info_user_id_key UNIQUE (user_id);
    END IF;
END
$$;

-- Write: now an upsert — a second "add" replaces the existing row rather than
-- accumulating a list. The old secrets are deleted, not left orphaned.
CREATE OR REPLACE FUNCTION public.add_payment_info(
    p_bank_id text, p_bank_display_name text, p_value text, p_account_name text DEFAULT NULL
) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE
    v_value_secret_id uuid := vault.create_secret(p_value);
    v_name_secret_id uuid;
    v_old_value_secret_id uuid;
    v_old_name_secret_id uuid;
    v_id uuid;
BEGIN
    IF p_account_name IS NOT NULL THEN
        v_name_secret_id := vault.create_secret(p_account_name);
    END IF;

    SELECT value_secret_id, account_name_secret_id
      INTO v_old_value_secret_id, v_old_name_secret_id
      FROM public.user_payment_info WHERE user_id = auth.uid();

    INSERT INTO public.user_payment_info
        (user_id, bank_id, bank_display_name, value_secret_id, account_name_secret_id)
    VALUES (auth.uid(), p_bank_id, p_bank_display_name, v_value_secret_id, v_name_secret_id)
    ON CONFLICT (user_id) DO UPDATE SET
        bank_id                = excluded.bank_id,
        bank_display_name      = excluded.bank_display_name,
        value_secret_id        = excluded.value_secret_id,
        account_name_secret_id = excluded.account_name_secret_id,
        created_at              = now()
    RETURNING id INTO v_id;

    IF v_old_value_secret_id IS NOT NULL THEN
        DELETE FROM vault.secrets WHERE id IN (v_old_value_secret_id, v_old_name_secret_id);
    END IF;

    RETURN v_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.add_payment_info(text, text, text, text) TO authenticated;
