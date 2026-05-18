# Implementation Plan

---

## 1. Home Tab — Feeds

### 1.1 Shared infrastructure
- `LobbyFeedItem` model (id, name, homegroundName, playtime, details, visibility, timeslotCompatScore, profileCompatScore, memberCount)
- `ProfessionalFeedItem` model (id, displayName, role, bio, sports, experienceYears, averageRating, reviewCount, isVerified)
- Reuse existing `Location` model for location feed
- All 4 subtabs already share `FilterData` (city, districts, schedule, search)

### 1.2 Teammate subtab
**Backend**: call existing `home_teammate_lobby_data` RPC with filter params  
**Card shows**: lobby name, home ground, playtime chips, visibility badge, compat score  
**Action**: "Xin vào" button → creates `lobby_befriend_record` (interaction_type=`request`, target_lobby_id)  
**Button state**: disabled + "Đã gửi" after request is sent (optimistic, no re-fetch)  
**Empty state**: prompt user to fill location/schedule in their profile (improves matching)

### 1.3 Challenger subtab
**Schema needed**:
- Add `open_to_challengers boolean DEFAULT false NOT NULL` to `lobby` table (migration in `schema/challenger_support.sql`)
- New `lobby_challenge` table — design TBD (see §4)
- New `home_challenger_lobby_data` Postgres function (filter by sport + city + districts, exclude own lobbies)

**Card shows**: lobby name, home ground, member count, playtime, compat score  
**Action**: "Thách đấu" button — TBD pending `lobby_challenge` table design (placeholder for now)  
**Toggle**: lobby captains can toggle `open_to_challengers` from their lobby detail page

### 1.4 Professional (Neutral) subtab
**Backend**: query `professional` table, filter by `sports @> ARRAY[sport_id]`  
**Card shows**: name, role badge (HLV / Trọng tài), verified checkmark, rating stars, review count, experience years, sport tags  
**Action**: "Xem" → navigate to professional detail page (design TBD in §5)  
**Filter**: role toggle (All / Coach / Referee) above the feed — local filter, no re-fetch

### 1.5 Location subtab
**Backend**:
- If search term present: call `search_locations(search_term)` RPC
- Otherwise: query `location` table filtered by `city_cluster` + `district IN (...)` 
- No sport filter (locations are sport-agnostic)

**Card shows**: name, full address, tags (e.g. "futsal", "indoor")  
**Action**: "Xem bản đồ" — open lat/lon in native maps app (if available); otherwise just informational  
**Note**: tight venue integration (booking, availability) is future work

---

## 2. Lobby System (Manage Tab — existing + extensions)

### 2.1 What's already built
- Lobby feed (user's own lobbies), create/edit form, lobby detail page with members / upcoming / history sections
- `lobby_befriend_record` handles request / invite / pair flows with auto-accept trigger

### 2.2 Lobby detail — missing pieces
- **Invite flow**: captain taps "Mời" on a member slot → opens teammate search → sends `lobby_befriend_record` (interaction_type=`invite`)
- **Accept/decline incoming requests**: notification or in-lobby pending list → captain taps accept/decline → updates `lobby_befriend_record.status`
- **Open to challengers toggle**: switch in lobby edit form → sets `open_to_challengers` flag
- **Challenger request list**: if open_to_challengers, show incoming challenge requests in lobby detail (pending `lobby_challenge` design)

---

## 3. Activity Lifecycle

### 3.1 Proposing a session
- Any lobby member can tap "Lên lịch" from the lobby detail → opens activity form  
- Form fields: date, start time, end time, location (search or free-text), optional note  
- Created with status `proposed`; captain is notified

### 3.2 Confirmation flow
- Members see proposed activities in "Sắp diễn ra" section with Accept / Decline buttons  
- **Confirming costs đá** (amount TBD — see §6 on currency)  
- Activity becomes `confirmed` once a quorum of members accept (quorum rule TBD — e.g. captain + 50%?)  
- Captain can veto (delete) or edit any proposed activity regardless of votes  

### 3.3 Schema changes needed for activity lifecycle
Current `activity` table has no `status`, `proposed_by`, `confirmed_count`, etc.  
Proposed additions (migration needed):
- `status text` — `proposed | confirmed | cancelled | completed`
- `proposed_by uuid` (user_id)
- `location_id uuid` (nullable FK to location)
- `location_note text` (free-text override)
- `activity_rsvp` join table — `(activity_id, user_id, rsvp text: accepted|declined|pending)`

### 3.4 Post-session
- After end_time, activity auto-transitions to `completed` (or captain marks manually)
- History section in lobby detail shows completed activities
- Health metrics can be linked via existing `activity_health_metrics` table

---

## 4. Challenger System

### 4.1 `lobby_challenge` table (to design)
Proposed schema:
```sql
CREATE TABLE public.lobby_challenge (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  initiator_lobby_id uuid NOT NULL REFERENCES public.lobby(id),
  target_lobby_id uuid NOT NULL REFERENCES public.lobby(id),
  sport_id bigint NOT NULL,
  status text NOT NULL DEFAULT 'pending',
    -- pending | accepted | declined | cancelled | completed
  proposed_time timestamp with time zone,
  proposed_location_id uuid REFERENCES public.location(id),
  note text,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT different_lobbies CHECK (initiator_lobby_id != target_lobby_id)
);
```

### 4.2 Challenge handshake flow
1. Lobby B captain sees Lobby A on challenger tab → taps "Thách đấu"
2. Optional: propose time + location, add note → sends `lobby_challenge` (status=`pending`)
3. Lobby A captain gets notified → sees challenge in their lobby detail (new "Thách đấu" section)
4. Lobby A captain accepts → status=`accepted` → both lobbies see a shared upcoming activity
5. Either side can cancel before the match; declining sets status=`declined`

**TvT match format**: TBD (does each lobby's full roster play, or a fixed player count?)

---

## 5. Professional Flow

### 5.1 Professional detail page
- Bio, certifications, sports, schedule overview
- Services list (type, duration, rate, max participants)
- Reviews section (rating breakdown, recent reviews)
- "Đặt lịch" button → booking flow

### 5.2 Booking flow (TBD — two options)
**Option A — App currency**: client pays đá upfront to book; pro confirms; session logged  
**Option B — Scheduling only**: app manages time slot + reminder; payment handled outside  
→ **Decision needed** before implementing

### 5.3 Ongoing courses (Manage tab)
- Manage tab gets a 3rd section: "Khoá học" — lists active professional bookings for the user  
- Shows pro name, sport, session count, next session date  
- Links to pro detail page

### 5.4 Schema gaps
- `professional_booking` has `status` but no push-notification trigger
- No "course" concept (recurring bookings) — bookings are currently one-off

---

## 6. Currency System ("đá" / rocks)

**Not yet in DB schema.** Needs full design before implementation.

Proposed tables:
```sql
CREATE TABLE public.wallet (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id),
  balance bigint DEFAULT 0 NOT NULL,  -- balance in đá
  updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.wallet_transaction (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  user_id uuid NOT NULL,
  amount bigint NOT NULL,  -- positive = credit, negative = debit
  reason text NOT NULL,    -- 'activity_confirm' | 'bill_split' | 'top_up' | 'refund' etc.
  reference_id uuid,       -- activity_id or booking_id
  created_at timestamp with time zone DEFAULT now()
);
```

**Usage flows**:
- Top-up đá: TBD (in-app purchase? bank transfer? seeded for testing)
- Confirm activity: deduct N đá per member → held in escrow until activity completes
- Bill split: at activity completion, captain inputs total cost → splits by member count → deducts from each member's wallet
- Cancel refund: if activity cancelled before it starts, refund the confirmation đá

**Amount per confirmation**: TBD

---

## 7. Notifications

### 7.1 Flag system
Each feature that triggers a push notification opts in explicitly via a constant flag.  
Until push infra is set up, all notifications are in-app only (existing bell icon / `NotificationPage`).

### 7.2 Events that warrant push notifications
| Event | Recipient |
|---|---|
| Lobby join request received | Lobby captain |
| Join request accepted/declined | Requesting user |
| Challenge received | Target lobby captain |
| Challenge accepted/declined | Initiator lobby captain |
| Activity proposed in lobby | All lobby members |
| Activity confirmed (quorum reached) | All lobby members |
| Activity cancelled | All lobby members |
| Professional booking confirmed | Client |
| Professional booking cancelled | Client + Pro |
| Upcoming session reminder (24h before) | All participants |

### 7.3 Infrastructure needed
- Device token storage (table or user details field)
- FCM / APNs setup
- Server-side trigger (Supabase Edge Function or DB trigger → webhook)
- In-app notification model + persistence (currently `NotificationPage` is a stub)

---

## 8. Health Tab (lower priority)

Already has structure (user health trends, activity data, achievements).  
Blocked on: health platform linking is implemented but activity data display is stub.  
Next step: wire `activity_health_metrics` + `daily_health_summary` to actual charts (using `fl_chart`).  
Achievements: `achievement` table exists but no user achievement progress table yet.

---

## 9. Profile Tab (mostly done, gaps)

- Sport profiles: implemented for all 5 sports ✓
- General info: implemented ✓
- Network / industry: implemented ✓
- **Missing**: playtime / schedule display is set but not reflected back to user clearly
- **Missing**: avatar upload (button exists, upload flow TBD)

---

## Implementation Order (suggested)

1. **Home feeds** — all 4 subtabs (models + controllers + cards) — highest user-facing value
2. **Activity lifecycle** — schema migration + propose/confirm/veto UI in lobby detail
3. **Challenger table** — schema design (confirm with user first), then feed action + lobby detail section
4. **Currency (đá)** — schema design (confirm first), then wallet display + confirm flow
5. **Professional detail + booking** — decide Option A vs B first
6. **Notifications** — infrastructure + event triggers
7. **Health tab** — charts + achievements
8. **Profile** — avatar upload
