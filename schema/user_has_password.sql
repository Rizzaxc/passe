-- Tracks whether an OAuth-only (Google/Apple) user has since set an
-- account password via the app's "set password" flow (see
-- AuthController.changePassword). Genuine email/password signups are
-- already covered by an `auth.identities` row with provider = 'email' —
-- this column only needs to exist for the OAuth-then-added-password case,
-- since that flow's own Supabase Auth call (updateUser(password: ...))
-- does not add an email identity and user_metadata isn't durable for this
-- (Google/Apple sign-in re-syncs user_metadata from the provider's claims
-- on every login, silently wiping any custom key stored there).
alter table "user" add column has_password boolean not null default false;
