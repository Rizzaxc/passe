"""Join every source, resolve wards, dedupe, and emit the import.

Outputs, in order of who reads them:
  data/venues_normalized.csv  — the human-reviewable source of truth. This is
                                where a reviewer catches "this badminton court
                                is in the wrong ward".
  schema/venue_import.sql     — a mechanical derivative of that CSV, applied
                                with the Supabase MCP execute_sql (data, not
                                schema — see schema/mocked_seed.sql's header).

    .venv/bin/python emit_sql.py            # full run
    .venv/bin/python emit_sql.py --dry-run  # report only, writes nothing
"""

from __future__ import annotations

import csv
import json
import sys
from collections import Counter

from config import CITIES, DATA, REPO
from db import fetch_locations
from dedupe import Matcher
from normalize import classify, osm_tags_to_stored, parse_db_tags
from wards import WardIndex, load_districts

CSV_COLUMNS = [
    "action", "id", "external_id", "source", "name", "city", "city_cluster",
    "lat", "lon", "district", "district_before", "district_how",
    "sport_ids", "amenity_kinds", "has_declared_sport", "in_footprint",
    "full_address", "street_number", "street_name", "tags",
]


def q(v) -> str:
    """Quote a value as a SQL literal.

    Only `None` becomes NULL — an empty string stays `''`. Collapsing the two
    is not safe here: `location.name` is NOT NULL and 406 rows legitimately
    hold `''`, so an empty-string-to-NULL rule aborts the whole import.
    """
    if v is None:
        return "NULL"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v)
    return "'" + str(v).replace("'", "''") + "'"


def arr(values, cast: str) -> str:
    if not values:
        return f"'{{}}'::{cast}[]"
    inner = ", ".join(q(v) for v in values)
    return f"ARRAY[{inner}]::{cast}[]"


def assign_ward(index: WardIndex, lat, lon, city, current, legacy):
    """(district, how, in_footprint) — see the fallback chain in the plan.

    Hard invariant: never blank out a value that currently filters. A legacy
    "Quan 7" label beats an empty string, so every miss returns `current`.
    """
    if lat is None or lon is None:
        return current, "no-coords", None
    ward, how = index.lookup(lat, lon, city=city)
    if ward is None:
        return current, "no-polygon", None
    if ward.district_id:
        return ward.district_id, how, True
    # Polygon hit, but the ward is outside the footprint enum.dart scopes to
    # (Binh Duong, Dong Nai, Hung Yen). Keep whatever already filtered;
    # otherwise the prefixed OSM ward name, which the widened client label set
    # can at least match.
    return (current or legacy or ward.osm_name), "out-of-footprint", False


def main(dry_run: bool) -> int:
    districts = load_districts()
    index = WardIndex.load()

    print("reading live locations...")
    existing = fetch_locations()
    print(f"  {len(existing)} rows")

    raw_path = DATA / "osm_venues_raw.json"
    incoming = json.loads(raw_path.read_text(encoding="utf-8")) if raw_path.exists() else []
    print(f"  {len(incoming)} OSM elements staged")

    matcher = Matcher(existing)
    rows: list[dict] = []
    stats = Counter()

    # ── 1. Re-normalize every existing row ──────────────────────────────
    city_of = {c["cluster"]: k for k, c in CITIES.items()}
    for r in existing:
        if r.get("source") == "user_submitted":
            # A user typed this and `submitted_by` makes it theirs. Never
            # rewrite it — not its name, not its ward.
            stats["skipped_user_submitted"] += 1
            continue
        city = city_of.get(r.get("city_cluster"))
        before = r.get("district")
        district, how, in_fp = assign_ward(
            index, r.get("lat"), r.get("lon"), city, before, r.get("district_legacy")
        )
        sport_ids, amenities, declared = classify(parse_db_tags(r.get("tags")))
        stats[f"ward_{how}"] += 1
        if district != before:
            stats["district_changed"] += 1
        rows.append(
            {
                "action": "update",
                "id": r["id"],
                "external_id": r.get("external_id"),
                "source": r.get("source"),
                "name": r.get("name") or "",
                "city": city or "",
                "city_cluster": r.get("city_cluster"),
                "lat": r.get("lat"),
                "lon": r.get("lon"),
                "district": district,
                "district_before": before,
                "district_how": how,
                "sport_ids": sport_ids,
                "amenity_kinds": amenities,
                "has_declared_sport": declared,
                "in_footprint": in_fp,
                "full_address": r.get("full_address"),
                "street_number": r.get("street_number"),
                "street_name": r.get("street_name"),
                "tags": r.get("tags") or [],
            }
        )

    # ── 2. Merge the OSM pull ───────────────────────────────────────────
    for v in incoming:
        hit, how = matcher.find(
            [v["external_id"], v["bare_id"]], v["name"], v["lat"], v["lon"]
        )
        if hit is not None and hit.get("source") == "user_submitted":
            stats["skipped_user_submitted"] += 1
            continue
        tags = osm_tags_to_stored(v["tags"])
        sport_ids, amenities, declared = classify(parse_db_tags(tags))
        district, ward_how, in_fp = assign_ward(
            index, v["lat"], v["lon"], v["city"], None, None
        )
        if hit is not None:
            stats[f"matched_{how}"] += 1
            # Update in place, preserving `id`: five tables FK into location.
            target = next((r for r in rows if r["id"] == hit["id"]), None)
            if target is None:
                continue
            # Only fill a name we do not already have — the DB's own value may
            # be a curated or hand-corrected one.
            if not target["name"] and v["name"]:
                target["name"] = v["name"]
                stats["name_rescued"] += 1
            if v["external_id"]:
                target["external_id"] = v["external_id"]
            if sport_ids or declared:
                target["sport_ids"] = sorted(set(target["sport_ids"]) | set(sport_ids))
                target["amenity_kinds"] = sorted(set(target["amenity_kinds"]) | set(amenities))
                target["has_declared_sport"] = target["has_declared_sport"] or declared
            continue

        stats["inserted"] += 1
        rows.append(
            {
                "action": "insert",
                "id": None,
                "external_id": v["external_id"],
                "source": "directory",
                "name": v["name"],
                "city": v["city"],
                "city_cluster": v["city_cluster"],
                "lat": v["lat"],
                "lon": v["lon"],
                "district": district,
                "district_before": None,
                "district_how": ward_how,
                "sport_ids": sport_ids,
                "amenity_kinds": amenities,
                "has_declared_sport": declared,
                "in_footprint": in_fp,
                "full_address": None,
                "street_number": None,
                "street_name": None,
                "tags": tags,
            }
        )

    # ── 3. Curated seed, last, wins every conflict ──────────────────────
    seed = DATA.parent / "curated_seed.csv"
    if seed.exists():
        with seed.open(encoding="utf-8") as fh:
            for s in csv.DictReader(fh):
                if not (s.get("slug") or "").strip() or s.get("slug", "").startswith("#"):
                    continue
                lat, lon = float(s["lat"]), float(s["lon"])
                city = s["city"].strip()
                ext = f"passe:{city}-{s['slug'].strip()}"
                hit, how = matcher.find([ext], s["name"], lat, lon)
                sport_ids = sorted(
                    {
                        __import__("config").SPORT_IDS[p.strip()]
                        for p in s["sports"].split("|")
                        if p.strip()
                    }
                )
                district, ward_how, in_fp = assign_ward(index, lat, lon, city, None, None)
                if s.get("ward_hint") and district and s["ward_hint"].strip() != district:
                    print(
                        f"  WARN {s['slug']}: ward_hint={s['ward_hint']} but polygon says {district}",
                        file=sys.stderr,
                    )
                base = {
                    "action": "update" if hit else "insert",
                    "id": hit["id"] if hit else None,
                    "external_id": (hit.get("external_id") if hit else None) or ext,
                    "source": "curated",
                    "name": s["name"].strip(),
                    "city": city,
                    "city_cluster": CITIES[city]["cluster"],
                    "lat": lat,
                    "lon": lon,
                    "district": district,
                    "district_before": hit.get("district") if hit else None,
                    "district_how": ward_how,
                    "sport_ids": sport_ids,
                    "amenity_kinds": [s["leisure"].strip()] if s.get("leisure") else [],
                    "has_declared_sport": bool(sport_ids),
                    "in_footprint": in_fp,
                    "full_address": (s.get("full_address") or "").strip() or None,
                    "street_number": (s.get("street_number") or "").strip() or None,
                    "street_name": (s.get("street_name") or "").strip() or None,
                    "tags": [f"sport:[{', '.join(p.strip() for p in s['sports'].split('|') if p.strip())}]"],
                }
                if hit:
                    rows[:] = [r for r in rows if r["id"] != hit["id"]]
                    stats["curated_merged"] += 1
                else:
                    stats["curated_inserted"] += 1
                rows.append(base)

    print("\n== stats")
    for k, v in sorted(stats.items()):
        print(f"  {k:28} {v}")

    if dry_run:
        print("\n--dry-run: nothing written")
        return 0

    with (DATA / "venues_normalized.csv").open("w", encoding="utf-8", newline="") as fh:
        # lineterminator="\n": the csv module defaults to CRLF, which makes
        # every regenerated diff of this committed file noise.
        w = csv.DictWriter(
            fh, fieldnames=CSV_COLUMNS, extrasaction="ignore", lineterminator="\n"
        )
        w.writeheader()
        for r in sorted(rows, key=lambda r: (r["city"], r["district"] or "", r["name"])):
            w.writerow(
                {
                    **r,
                    "sport_ids": "|".join(str(x) for x in r["sport_ids"]),
                    "amenity_kinds": "|".join(r["amenity_kinds"]),
                    "tags": " ;; ".join(r["tags"]),
                }
            )

    emit_sql(rows)
    print(f"\nwrote data/venues_normalized.csv and schema/venue_import.sql ({len(rows)} rows)")
    return 0


def emit_sql(rows: list[dict]) -> None:
    out = [
        "-- GENERATED by tool/venue/emit_sql.py from data/venues_normalized.csv.",
        "-- Do not hand-edit: edit the CSV (or curated_seed.csv) and re-run.",
        "--",
        "-- This is DATA, not schema. Apply with the Supabase MCP `execute_sql`",
        "-- (runs as postgres, bypasses RLS), NOT `apply_migration` — same",
        "-- convention as schema/mocked_seed.sql.",
        "--",
        "-- Updates preserve `location.id`: activity, lobby_homeground,",
        "-- lobby.challenge_offer_location, lobby_challenge, referee_booking and",
        "-- professional_preferred_location all FK into this table, so a",
        "-- delete-and-reinsert would orphan a scheduled session's venue.",
        "",
        "BEGIN;",
        "",
    ]
    for r in rows:
        if r["action"] == "update":
            out.append(
                "UPDATE public.location SET "
                f"district = {q(r['district'])}, "
                f"sport_ids = {arr(r['sport_ids'], 'bigint')}, "
                f"amenity_kinds = {arr(r['amenity_kinds'], 'text')}, "
                f"has_declared_sport = {q(r['has_declared_sport'])}, "
                f"external_id = {q(r['external_id'])}, "
                f"source = {q(r['source'])}, "
                f"name = {q(r['name'])}"
                + (
                    f", is_verified = false"
                    if r["in_footprint"] is False
                    else ""
                )
                + f" WHERE id = {q(r['id'])} AND source <> 'user_submitted';"
            )
        else:
            out.append(
                "INSERT INTO public.location (external_id, name, full_address, "
                "street_number, street_name, district, city, lat, lon, tags, "
                "city_cluster, source, is_verified, sport_ids, amenity_kinds, "
                "has_declared_sport) VALUES ("
                f"{q(r['external_id'])}, {q(r['name'])}, {q(r['full_address'])}, "
                f"{q(r['street_number'])}, {q(r['street_name'])}, {q(r['district'])}, "
                f"{q(CITIES[r['city']]['label'] if r['city'] in CITIES else None)}, "
                f"{q(r['lat'])}, {q(r['lon'])}, {arr(r['tags'], 'text')}, "
                f"{q(r['city_cluster'])}, {q(r['source'])}, "
                f"{q(r['in_footprint'] is not False)}, {arr(r['sport_ids'], 'bigint')}, "
                f"{arr(r['amenity_kinds'], 'text')}, {q(r['has_declared_sport'])})"
                " ON CONFLICT (external_id) DO UPDATE SET "
                "name = CASE WHEN public.location.name = '' THEN EXCLUDED.name "
                "ELSE public.location.name END, "
                "district = EXCLUDED.district, sport_ids = EXCLUDED.sport_ids, "
                "amenity_kinds = EXCLUDED.amenity_kinds, "
                "has_declared_sport = EXCLUDED.has_declared_sport "
                "WHERE public.location.source <> 'user_submitted';"
            )
    out += ["", "COMMIT;", ""]
    (REPO / "schema" / "venue_import.sql").write_text("\n".join(out), encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main("--dry-run" in sys.argv))
