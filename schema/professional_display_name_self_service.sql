-- A professional's public display name is separate from the linked user's
-- username. Allow linked professionals to manage that name alongside their
-- other self-service profile fields while RLS continues to scope the update
-- to `professional.linked_user_id = auth.uid()`.

GRANT UPDATE (display_name)
    ON TABLE public.professional TO authenticated;

ALTER TABLE public.professional
    ADD CONSTRAINT professional_display_name_check
    CHECK (char_length(btrim(display_name)) BETWEEN 1 AND 80) NOT VALID;

ALTER TABLE public.professional
    VALIDATE CONSTRAINT professional_display_name_check;

COMMENT ON COLUMN public.professional.display_name IS
    'Public professional name, independent from the linked user account username.';
