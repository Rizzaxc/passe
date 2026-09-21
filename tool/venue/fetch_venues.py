"""Pull sport venues from OSM for both cities.

Three passes, run independently so the expensive one can fail without taking
the cheap ones with it:

  1. facility tags     — leisure=pitch|sports_centre|stadium|track, etc.
  2. sport tags        — catches rooftop/indoor courts mapped only as buildings
  3. Vietnamese names  — the pass that actually finds badminton and pickleball
                         businesses, which are routinely bare named nodes with
                         no `sport` tag at all

Measured yield for HCMC: ~1,836 elements, of which only ~303 are named. That
is not a bug in the query — it is what OSM contains. Volume has to come from
the curated seed; this pass is for tag/coverage improvements and the named
long tail.

    .venv/bin/python fetch_venues.py
"""

from __future__ import annotations

import json
import sys
import time

from config import CITIES, DATA
from overpass import OverpassError, bbox_str, query, split_bbox

FACILITY = (
    'nwr["leisure"~"^(pitch|sports_centre|stadium|track)$"]({b});'
    'nwr["amenity"="sports_centre"]({b});'
    'nwr["club"="sport"]({b});'
)
SPORT = (
    'nwr["sport"~"soccer|football|futsal|basketball|badminton|tennis|'
    'pickleball|table_tennis|multi"]({b});'
)
NAMES = (
    'nwr["name"~"sân (bóng|cầu lông|tennis|pickleball|bóng rổ|futsal)|'
    'nhà thi đấu|cầu lông|pickleball",i]({b});'
)

# Same resume contract as fetch_wards.py: stop starting uncached chunks after
# this long and write NOTHING, so a partial pull can never be mistaken for a
# complete one. Cached chunks replay instantly, so re-running resumes.
DEFAULT_DEADLINE_S = 240

PASSES = [
    ("facility", FACILITY, 3, 180),
    ("sport", SPORT, 3, 180),
    # Case-insensitive regex over `name` across a bbox is by far the most
    # expensive of the three, so: finer chunks, longer timeout, and failures
    # are tolerated because this pass is purely additive.
    ("names", NAMES, 4, 300),
]


def centre(el: dict):
    if el["type"] == "node":
        return el.get("lat"), el.get("lon")
    c = el.get("center") or {}
    return c.get("lat"), c.get("lon")


def main(deadline_s: int) -> int:
    started = time.monotonic()
    out_of_time = False
    out: dict[str, dict] = {}
    holes: list[str] = []

    for city, cfg in CITIES.items():
        print(f"== {city}")
        for label, body, grid, timeout_s in PASSES:
            chunks = split_bbox(cfg["bbox"], grid)
            got = 0
            for i, box in enumerate(chunks, 1):
                if deadline_s and time.monotonic() - started > deadline_s:
                    out_of_time = True
                    break
                ql = f"[out:json][timeout:{timeout_s}];({body.format(b=bbox_str(box))});out center tags;"
                try:
                    els = query(ql, timeout_s=timeout_s + 60)["elements"]
                except OverpassError as exc:
                    holes.append(f"{city}/{label}/{i}")
                    print(f"  {label} chunk {i}/{len(chunks)} FAILED: {exc}", file=sys.stderr)
                    continue
                for el in els:
                    lat, lon = centre(el)
                    if lat is None or lon is None:
                        continue
                    key = f"{el['type']}/{el['id']}"
                    if key in out:
                        continue
                    out[key] = {
                        "osm_key": key,
                        "external_id": f"osm:{key}",
                        "bare_id": str(el["id"]),
                        "city": city,
                        "city_cluster": cfg["cluster"],
                        "lat": lat,
                        "lon": lon,
                        "name": (el.get("tags") or {}).get("name", "") or "",
                        "tags": el.get("tags") or {},
                    }
                    got += 1
            print(f"  {label}: +{got} (total {len(out)})", flush=True)
            if out_of_time:
                break
        if out_of_time:
            break

    if out_of_time:
        print(
            f"\nINCOMPLETE: {len(out)} elements fetched and cached. "
            f"Nothing written — re-run to continue."
        )
        return 2

    (DATA / "osm_venues_raw.json").write_text(
        json.dumps(list(out.values()), ensure_ascii=False), encoding="utf-8"
    )
    named = sum(1 for v in out.values() if v["name"])
    print(f"\nwrote {len(out)} elements ({named} named, {len(out) - named} nameless)")
    if holes:
        print(f"WARNING: {len(holes)} chunk(s) failed: {', '.join(holes)}", file=sys.stderr)
        print("re-run to retry only those (successful chunks are cached)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    _d = DEFAULT_DEADLINE_S
    if "--deadline" in sys.argv:
        _d = int(sys.argv[sys.argv.index("--deadline") + 1])
    raise SystemExit(main(_d))
