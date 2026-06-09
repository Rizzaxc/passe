# Push Notifications — provisioning runbook

The push system is **built, wired, and provisioned**. Steps 1–3 below are **DONE** (APNs key
uploaded, secrets set, Vault configured, DB→function poke verified end-to-end returning
`200 {"processed":0}`). Steps 4–5 (Xcode sanity + device smoke test) remain — they need a real
device. The historical steps are kept for reference / re-provisioning a new environment.

Architecture recap (already in place):

```
domain event (SQL trigger / cron)
  → fn_enqueue_notification  → notification_outbox (one row per recipient)
  → AFTER-INSERT trigger pokes  ─┐
  → pg_cron fn_cron_tick (1 min) ┴→ pg_net POST → Edge Function `send-push`
                                      → FCM HTTP v1 → APNs / Android
```

- DB: `schema/push_notifications.sql` (applied). Tables `user_device_token`,
  `notification_outbox`, `enabled_notification_kind`; emitters for
  `activity_confirmed` (trigger) and `pro_session_reminder` (cron). `challenger_confirmed`
  is reserved + **disabled** in `enabled_notification_kind` until the challenge handshake exists.
- Edge Function `supabase/functions/send-push/` — **deployed** (runs with `verify_jwt = false`;
  authenticates the poke itself via the `PUSH_INVOKE_SECRET` bearer guard — see step 3).
- Client: `lib/notifications/`, init in `lib/main.dart`, soft-ask wired into the
  teammate "Xin vào" CTA. `lib/firebase_options.dart` generated from the committed config.
- iOS entitlements (`aps-environment`) + `UIBackgroundModes` set. Android Gradle already had the
  google-services plugin; `google-services.json` + `GoogleService-Info.plist` are committed.

Project: `passe-498715` (Firebase) / `qlezbnjfuabcxlsxxnrw` (Supabase).

---

## 1. APNs auth key → Firebase  (enables iOS delivery) — ✅ DONE

Without this, iOS pushes silently never arrive (Android works without it).

1. [Apple Developer](https://developer.apple.com/account) → **Certificates, Identifiers &
   Profiles → Keys → +** → enable **Apple Push Notifications service (APNs)** → register →
   **download the `.p8`** (one-time download). Note the **Key ID**.
2. Confirm the App ID `passe.vn.passe` has the **Push Notifications** capability enabled
   (same portal → Identifiers).
3. [Firebase console](https://console.firebase.google.com/project/passe-498715/settings/cloudmessaging)
   → **Cloud Messaging → Apple app configuration → APNs Authentication Key → Upload**.
   Provide the `.p8`, the **Key ID**, and your **Team ID**.

## 2. Service account → the Edge Function can send — ✅ DONE

1. Firebase console → **Project settings → Service accounts → Generate new private key**
   → downloads a JSON file.
2. Set it as the function's secret (CLI, from the repo root):
   ```bash
   supabase secrets set FCM_SERVICE_ACCOUNT="$(cat ~/Downloads/passe-498715-*.json)" \
     --project-ref qlezbnjfuabcxlsxxnrw
   ```
   The value is the **entire JSON blob** (the function parses `client_email` + `private_key`),
   not a single field. (Or Supabase dashboard → Edge Functions → `send-push` → Secrets.) No
   redeploy needed.

## 3. Invocation auth → the DB poke can reach the function — ✅ DONE

> **Auth model = Path B (new-style API keys).** The legacy `service_role` JWT is deprecated, so
> the function runs with **`verify_jwt = false`** and authenticates the caller itself: a
> bearer-token guard in `index.ts` compares the incoming `Authorization: Bearer …` against the
> `PUSH_INVOKE_SECRET` function env var. The DB poke sends the Vault `edge_service_role_key` as
> that bearer. **The two values must be identical** — any long opaque string works (a
> `sb_secret_…` key or just random bytes); they're only ever compared to each other, never
> validated as a JWT.

Set **both** to the same value:

1. Function env (CLI):
   ```bash
   supabase secrets set PUSH_INVOKE_SECRET="<SHARED_SECRET>" \
     --project-ref qlezbnjfuabcxlsxxnrw
   ```
2. Vault (SQL editor, or Claude via MCP):
   ```sql
   select vault.create_secret(
     'https://qlezbnjfuabcxlsxxnrw.supabase.co/functions/v1/send-push',
     'edge_send_push_url');
   select vault.create_secret(
     '<SHARED_SECRET>',          -- must equal PUSH_INVOKE_SECRET above
     'edge_service_role_key');
   ```

The outbox trigger + cron read both Vault rows; until they exist the poke is a safe no-op and
rows just wait. **Verify end-to-end** (passes if `200 {"processed":0}`, not `401`/`500`):

```sql
select fn_invoke_send_push();                         -- fire the poke (pg_net, async)
select status_code, content from net._http_response   -- read the recorded response
  order by id desc limit 1;
```

## 4. iOS Xcode sanity check

- Open `ios/Runner.xcworkspace`. Ensure **`GoogleService-Info.plist` is a member of the Runner
  target** (drag it into the project navigator under Runner if it shows as on-disk-only).
- Target → Signing & Capabilities should list **Push Notifications** and **Background Modes →
  Remote notifications** (the entitlements/Info.plist are already set; this is just the GUI mirror).
- `firebase_messaging` needs **iOS 13+**; bump the Podfile platform if it's lower, then
  `cd ios && pod install`.

## 5. Build & smoke test

```bash
flutter pub get
dart run build_runner build         # regenerates notification_service.g.dart etc.
flutter run
```

1. Sign in (not as guest), open Home → Teammate, tap **Xin vào** on a lobby → the soft-ask
   sheet appears → **Cho phép** → accept the OS prompt. Verify a row lands in
   `public.user_device_token` for your user.
2. End-to-end: have a lobby reach its activity confirmation threshold (insert the final
   `activity_confirmation` row), or set a `professional_booking` to `confirmed` starting within
   the hour. Watch `notification_outbox` flip `pending → sent` and the device receive a banner.
3. If a row is stuck `pending`, check `select * from notification_outbox order by id desc` (the
   `last_error` column), the Edge Function logs (dashboard), and that steps 2–3 are done.

## Operating the flag system

- **Kill a noisy kind without a deploy:**
  `update enabled_notification_kind set enabled = false where kind = 'activity_confirmed';`
- **Light up challenger later:** build the `lobby_challenge` table + accept handshake, add an
  emitter that calls `fn_enqueue_notification('challenger_confirmed', …)`, then
  `update enabled_notification_kind set enabled = true where kind = 'challenger_confirmed';`
- **Add a new kind:** `alter type notification_kind add value '…'`, insert its allowlist row,
  add the enum case in `lib/notifications/notification_kind.dart` + a route in
  `notification_router.dart`, add the emitter.

## Adding more soft-ask call sites

The soft-ask (`notificationServiceProvider.maybePromptAndRegister(context, ref)`) currently
fires after a teammate join request. It's idempotent and no-ops for guests / already-decided
users, so add the same one-liner at the other "first meaningful action" points when they ship:
lobby create, befriend/invite accept, and pro booking confirm.
