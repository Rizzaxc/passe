"""Fetch post-2025 ward boundaries from OSM and resolve them to District.ids.

Two stages per city: one cheap request for the ward ids and names, then
geometry in bounded batches of ids. Batching by id rather than by sub-bbox is
deliberate — see `ward_geom_query` in wards.py for why the area-chunked
version does not work.

Run once. `data/wards_vn.geojson` is committed, so every later stage is
offline and deterministic, and a reviewer can open it in a GIS viewer to check
a suspicious assignment.

    .venv/bin/python fetch_wards.py
"""

from __future__ import annotations

import difflib
import json
import sys
import time

from shapely.geometry import mapping

from config import CITIES, DATA
from overpass import OverpassError, bbox_str, query
from wards import (
    element_to_geometry,
    load_districts,
    normalize,
    strip_prefix,
    ward_geom_query,
    ward_id_query,
)

FUZZY_REPORT_FLOOR = 0.86   # report-only; nothing is ever auto-applied
SIMPLIFY_DEG = 0.0001       # ~10 m
GEOM_BATCH = 20

# Stop starting new (uncached) batches after this many seconds and exit 2.
# Overpass is slow and occasionally makes us ride the backoff, so a full cold
# run can outlast whatever is supervising it. Re-running is cheap and safe:
# completed batches come straight from the on-disk cache, so each run resumes
# where the last one stopped. `--deadline 0` disables the cap.
DEFAULT_DEADLINE_S = 240


def main(deadline_s: int) -> int:
    started = time.monotonic()
    out_of_time = False
    districts = load_districts()
    features: list[dict] = []
    unmatched: list[str] = []
    seen: set[int] = set()
    failed_batches = 0

    for city, cfg in CITIES.items():
        print(f"== {city} ({cfg['label']})", flush=True)

        try:
            listing = query(ward_id_query(bbox_str(cfg["bbox"])), timeout_s=180)["elements"]
        except OverpassError as exc:
            print(f"  FATAL listing: {exc}", file=sys.stderr)
            return 1

        by_key = districts[city]
        matched_ids: set[str] = set()
        wanted: list[int] = []
        meta: dict[int, dict] = {}
        for el in listing:
            name = (el.get("tags") or {}).get("name")
            if not name or el["id"] in seen:
                continue
            seen.add(el["id"])
            key = normalize(strip_prefix(name))
            row = by_key.get(key)
            if row is None:
                close = difflib.get_close_matches(key, by_key, n=1, cutoff=FUZZY_REPORT_FLOOR)
                hint = f"  ~ {by_key[close[0]]['name']} ({close[0]})" if close else ""
                unmatched.append(f"{city}\trel/{el['id']}\t{name}\t{key}{hint}")
                # Out-of-footprint wards still need geometry: a venue that
                # lands in one must be recognised as out of footprint, not
                # silently left looking like an unassignable HCMC row.
            wanted.append(el["id"])
            meta[el["id"]] = {"name": name, "row": row}

        print(f"  {len(wanted)} ward relations; fetching geometry", flush=True)
        for i in range(0, len(wanted), GEOM_BATCH):
            batch = wanted[i : i + GEOM_BATCH]
            n = i // GEOM_BATCH + 1
            total = (len(wanted) + GEOM_BATCH - 1) // GEOM_BATCH
            if deadline_s and time.monotonic() - started > deadline_s:
                # Cached batches still resolve instantly, so stopping here
                # loses nothing but the not-yet-fetched tail.
                out_of_time = True
                break
            try:
                els = query(ward_geom_query(batch), timeout_s=240)["elements"]
            except OverpassError as exc:
                failed_batches += 1
                print(f"  batch {n}/{total} FAILED: {exc}", file=sys.stderr)
                continue

            for el in els:
                info = meta.get(el["id"])
                if info is None:
                    continue
                geom = element_to_geometry(el)
                if geom is None or geom.is_empty:
                    print(f"  no usable geometry for {info['name']} (rel/{el['id']})", file=sys.stderr)
                    continue
                row = info["row"]
                if row:
                    # Count DISTINCT wards, not polygons: OSM sometimes carries
                    # two relations for one ward, which made this read 107/102.
                    matched_ids.add(row["id"])
                features.append(
                    {
                        "type": "Feature",
                        "properties": {
                            "osm_id": el["id"],
                            "osm_name": info["name"],
                            "city": city,
                            "district_id": row["id"] if row else None,
                            "legacy": row["legacy"] if row else None,
                        },
                        "geometry": mapping(geom.simplify(SIMPLIFY_DEG, preserve_topology=True)),
                    }
                )
            print(f"  batch {n}/{total} ok ({len(features)} polygons)", flush=True)

        if out_of_time:
            print(f"  deadline reached; {len(features)} polygons so far", flush=True)
            break

        expected = cfg["expected_wards"]
        matched = len(matched_ids)
        print(f"  matched_to_enum={matched}/{expected}")
        if matched < expected:
            missing = sorted(
                r["name"] for r in districts[city].values() if r["id"] not in matched_ids
            )
            print(f"  no polygon for: {', '.join(missing)}", file=sys.stderr)
            # Not fatal, but loud: a ward with no polygon silently falls
            # through to the legacy label, and that is invisible in totals.
            print(f"  WARNING: {expected - matched} enum ward(s) have no polygon", file=sys.stderr)

    if out_of_time:
        # Deliberately write NOTHING. A truncated wards_vn.geojson is worse
        # than none: emit_sql would happily consume it and quietly file every
        # venue in the missing wards as "no polygon", which looks like sparse
        # source data rather than an interrupted download. The Overpass cache
        # already holds the completed batches, so a re-run resumes cheaply.
        print(
            f"\nINCOMPLETE: {len(features)} polygons fetched and cached. "
            f"Nothing written — re-run to continue."
        )
        return 2

    (DATA / "wards_vn.geojson").write_text(
        json.dumps({"type": "FeatureCollection", "features": features}), encoding="utf-8"
    )
    (DATA / "unmatched_wards.txt").write_text(
        "# OSM wards with no District.id — expected for anything outside the\n"
        "# old HCMC/Hanoi footprints (Binh Duong, Dong Nai, Hung Yen, ...).\n"
        "# A '~' hint is REPORT ONLY and is never auto-applied: auto-accepting\n"
        "# a fuzzy administrative match is how 'Tan Hung' silently becomes\n"
        "# 'Tan Huong' and 80 venues land in the wrong ward. Promote a genuine\n"
        "# rename into ward_alias.json, keyed by OSM id.\n"
        + "\n".join(sorted(unmatched))
        + "\n",
        encoding="utf-8",
    )
    print(f"\nwrote {len(features)} polygons; {len(unmatched)} unmatched")
    if failed_batches:
        print(f"WARNING: {failed_batches} geometry batch(es) failed — re-run to retry "
              f"(successful batches are cached)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    _d = DEFAULT_DEADLINE_S
    if "--deadline" in sys.argv:
        _d = int(sys.argv[sys.argv.index("--deadline") + 1])
    raise SystemExit(main(_d))
