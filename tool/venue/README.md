# Venue import pipeline

Fixes and grows `public.location`, the table behind Discover ▸ Locations.

## Why this exists

The table was a one-off third-party OSM scrape. Measured before this pipeline:

- 406 of 2,050 rows (20%) have a blank `name` — they render as
  "Địa điểm chưa đặt tên" plus a generic map pin.
- 263 of the 997 `city_cluster=1` rows are in Đồng Nai / Bình Dương, not HCMC.
- 557 of those 997 could not be reached by *any* ward filter selection,
  because `district` is free text mixing legacy quận labels, pre-reform ward
  names, and blanks.
- Badminton and pickleball — two of the biggest casual sports in Vietnam — had
  28 and 14 HCMC venues respectively.

Coordinates, by contrast, are good on 2,047 of 2,050 rows. That is the lever:
the ward is derived geometrically, not parsed out of the text.

## Run order

```bash
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt

# 1. Ward list, generated FROM lib/core/model/enum.dart (never hand-copied)
(cd ../.. && flutter test test/tool/generate_district_fixture_test.dart)

# 2. Ward boundaries from OSM. Run once — the output is committed.
.venv/bin/python fetch_wards.py

# 3. Sport venues from OSM. Re-runnable; responses are cached.
.venv/bin/python fetch_venues.py

# 4. Join, resolve wards, dedupe. Inspect before writing anything.
.venv/bin/python emit_sql.py --dry-run
.venv/bin/python emit_sql.py

# 5. Apply schema/venue_import.sql with the Supabase MCP `execute_sql`
#    (data, not schema — same convention as schema/mocked_seed.sql).

# 6. Coverage report
.venv/bin/python verify.py > /tmp/venue_report.sql
```

## What is committed, and why

| Path | Committed | Reason |
|---|---|---|
| `data/districts.json` | yes | Generated from `enum.dart` by a test that also asserts 102+126 and id uniqueness, so the two can't silently desync. |
| `data/wards_vn.geojson` | yes | Fetched once, ever. Makes every later run offline and deterministic, and a reviewer can open it in a GIS viewer. |
| `data/unmatched_wards.txt` | yes | So ward drift shows up in a diff instead of being discovered months later. |
| `data/venues_normalized.csv` | yes | **The human-reviewable source of truth.** This is where you catch "this badminton court is in the wrong ward". |
| `curated_seed.csv` | yes | Hand-sourced venues. Goes through the same pipeline as OSM rows, so it gets ward assignment and dedupe for free and physically cannot duplicate an OSM row. |
| `curated_backlog.csv` | yes | Candidates gathered but not yet imported. Same schema; promote rows into `curated_seed.csv` when verified. |
| `../../schema/venue_import.sql` | yes | Mechanical derivative of the CSV. Skim it; review the CSV. |
| `.venv/`, `.cache/` | no | Local. The cache is what makes a downstream bug cost seconds to retry instead of another 40 minutes of load on a donated public endpoint. |

## Things that will bite you

- **Overpass answers 406 without a real `User-Agent`.** Not a rate limit, not
  a query error — it just refuses.
- **Ward level is `admin_level=6`, not 8 or 9.** The 2025 province→ward
  flattening freed up level 6; level 9 is *khu phố* (sub-ward) and level 8
  returns nothing inside HCMC. Getting this wrong yields zero polygons rather
  than wrong ones, so it fails loudly.
- **Never bbox-chunk an `out geom` boundary query.** It re-downloads every
  relation straddling a chunk edge, once per chunk, and 504s. Geometry is
  fetched in batches of relation *ids* instead.
- **Writes never delete.** Six columns across five tables FK into `location`
  (`activity.location_id`, `lobby_homeground`, `lobby.challenge_offer_location`,
  `lobby_challenge.proposed_location`, `referee_booking.location_id`,
  `professional_preferred_location`). Matches UPDATE in place and preserve
  `location.id`.
- **`source = 'user_submitted'` rows are never touched.** A user typed those
  through `create_location`, and `submitted_by` makes them theirs.
- **`has_declared_sport` is not "sport_ids is empty".** It records whether the
  source named *any* sport, including ones Passe doesn't support. That is what
  lets a volleyball-only court be hidden from the badminton feed while an
  untagged general facility stays visible. Collapsing the two drops ~433 rows
  from every feed.
- **OSM is exhausted as a volume source.** An exhaustive pull over HCMC returns
  1,836 elements of which only 303 are named, and all of OSM HCMC holds 47
  badminton and 18 pickleball venues. Real coverage has to come from
  `curated_seed.csv`.
