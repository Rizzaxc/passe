# App Store / Play capture runbook

Everything needed to shoot the store listing. Written to be followed by someone
who wasn't in the conversation that produced it.

Neither store requires feature coverage: Apple takes up to 10 screenshots per
display size, Play up to 8. The binding constraints are the accuracy ones — the
screenshots must show the app as it actually ships — plus having a working demo
account for App Review. That's why the shot list below is 10 surfaces and not
"every screen".

---

## 0. Before you touch the simulator

```bash
# 1. Structure (cast, lobbies, affiliations). Slow-moving; already live.
#    Only re-run if the seeded data is gone.
psql "$DB" -f schema/shot_seed_structure.sql

# 2. Media. Idempotent (x-upsert), safe to re-run.
sh tool/shot_upload_media.sh

# 3. Timeline. RE-RUN THIS EVERY CAPTURE DAY — see "Why it decays" below.
psql "$DB" -f schema/shot_seed_timeline.sql
```

Connection string comes from `secret/db.env`; the seeds run as `postgres` and
bypass RLS deliberately.

### Why the timeline decays

- `wall_post` hard-expires at **≤ 7 days** — the Feed empties on its own.
- `expire_past_activities()` deletes past *unconfirmed* lobby activities on
  every lobby-list load.
- `fn_cron_tick` auto-cancels any under-threshold activity at kickoff, and
  freezes RSVP once a `confirmation_deadline` passes under threshold.

Re-running the timeline seed re-anchors everything to `now()`. **Run it again
at submission time**, or a reviewer opening the app a week later sees a decayed
account.

---

## 1. Sign in

```
shothero@demo.passe  /  12345678
```

Same credentials go in App Review Information. The account is a captain in one
soccer lobby and a plain member of one pickleball lobby, so both the
manager-side and member-side UI are reachable from one login.

Coach-side shots use the separate pre-existing `democoach1@demo.passe` (same
password) from `schema/demo_coach_seed.sql`.

---

## 2. Clear the onboarding furniture — do this first

The hero is a *fresh* account, so the guide surfaces will sit on top of exactly
the screens being captured:

- the get-started sheet
- coach marks
- the lobby hub tour
- `LobbyGettingStartedCard`, pinned above the lobby feed for a leader

Walk through and dismiss each once. They persist in `SharedPreferences` under
the `ONBOARDING_*` keys, so this survives app relaunches but **not** a
reinstall or a simulator erase. If you reinstall, do it again.

The pinned card also self-clears once a past "scheduled" feed item exists, which
the timeline seed provides — but dismiss it anyway rather than relying on that.

---

## 3. Grant HealthKit once

The Health tab is gated on **link status**, not on data: `HealthController`
calls `requestAuthorization` and renders `HealthNotLinkedView` unless it comes
back granted. The seeded rollups stay invisible until you tap through that sheet
once on the capture device.

Safe to do: the sync engine's `_syncDailySummaries` *breaks* on the first day
the device can't read, so an empty simulator store stops immediately rather than
overwriting the seeded rows with zeroes.

---

## 4. Dress the device

```bash
sh tool/shot_statusbar_ios.sh            # 9:41, full bars, full battery, + location
sh tool/shot_statusbar_android.sh        # SystemUI demo mode equivalent
```

Both are cleared by a reboot — re-run if you restart the device.

The iOS script also sets a simulated position in Bình Thạnh. That matters:
`PDistanceLabel` shows a "see distance" chip until location is granted, and real
kilometres only once there's a fix. Every seeded venue carries real coordinates,
so the distances shown are truthful.

---

## 5. The shots

| # | Screen | Path | What makes it the shot |
|---|---|---|---|
| 1 | Manage ▸ Lobby ▸ *Anh Em Tan Làm* ▸ Planner | tap the lobby, Planner tab | The confirmed session: 6/8 going, past threshold, cost + deadline tags |
| 2 | Discover ▸ Đồng đội | Discover, first subtab | FitScore cards in a believable spread |
| 3 | Manage ▸ Lobby ▸ Feed | same lobby, Feed tab | 8-item action stream: update, 5 personal actions, a poll |
| 4 | Lobby Feed ▸ payment request card | scroll the Feed | "Chia tiền": 5 payees, 2 paid / 3 outstanding |
| 5 | Discover ▸ Thách đấu | Discover subtab 2 | Friendly challenge — **seeded last, see below** |
| 6 | Manage ▸ Khoá học | Manage rail, index 2 | Enrolled course + approved lesson |
| 7 | Health ▸ chỉ số | Health tab | 90 days of trends; resting HR 69 → 62 |
| 8 | Health ▸ thành tích | Health, 3rd subtab | 6 badges, 810 XP, level 4 |
| 9 | Discover ▸ Đồng đội ▸ tap a vibe chip | tap "Chung mạng lưới" on the 4.6 card | `match_factor_sheet` — how matchmaking reads your profile |
| 10 | Discover ▸ Kèo | Discover subtab 3 | 3 open listings, both ownership kinds |

Spare Apple slots (11–12 if wanted): Feed (tab 1) and Discover ▸ Sân bãi.

### Known numbers, so you can tell "wrong" from "different"

- Teammate feed, as the hero: **4.6 / 4.4 / 3.9 / 3.4 / 3.3 / 2.5**. The last
  one renders as a *plain card with no match board* — that is deliberate.
  `isGoodFit` is `score > 2.5`, and a feed where every card glows reads as fake.
- Star card chips: network, skill, age, playtime (4 = the display cap).
- Feed: 4 posts, 3 authors, cross-sport.
- Freeplay: 3 listings — Wed 19:30, Fri 19:30, Sat 16:00.

---

## 6. Capture

```bash
# iOS
xcrun simctl io booted screenshot ~/Desktop/shot_01.png
xcrun simctl io booted recordVideo --codec h264 ~/Desktop/clip_01.mp4   # ctrl-C to stop

# Android
adb exec-out screencap -p > ~/Desktop/shot_01.png
adb shell screenrecord /sdcard/clip.mp4 && adb pull /sdcard/clip.mp4
```

Both produce native-resolution frames, which is what the stores want.

**Not fastlane.** `snapshot` is XCUITest-driven and Flutter paints into a single
`FlutterView`, so driving sheets and the paged feed needs accessibility ids
threaded through the widget tree; Android would need a separate Espresso
harness on top. The committed `ios/fastlane/` scaffolding is unused.

---

## 7. Deliberately empty — don't "fix" these

- **Match history.** The only writer of `lobby_match` is
  `record_challenge_match` (the referee's path), so until a challenge match is
  played there is nothing to show. The app renders a proper empty state.
- **The đá wallet.** No server-side ledger exists; `DaAppbarButton` is unlinked
  from the nav on purpose.
- **Referee hiring.** Iced behind `ClientFeatureFlags.refereeFlow`.
- **Payment/bank details.** `user_payment_info` is intentionally unseeded — the
  QR sheet builds a *live, scannable* `img.vietqr.io` image, and a scannable QR
  in a storefront screenshot is a transfer target. The split card still renders
  in full; only the pay action no-ops, via a toast.

Shoot the **default build** — no dart-defines. Challenger ships as the friendly
(referee-free) mode; the flag now gates only the refereed variant.

---

## 8. Afterwards

The structure seed can stay live until the build is approved — it is also the
reviewer's account. Once approved, run the cleanup block at the top of
`schema/shot_seed_structure.sql` on its own to remove every `5107…` row plus
the two synthetic `network` rows (ids ≥ 990000).
