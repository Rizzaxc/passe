"""Shared configuration for the venue import pipeline.

Everything that encodes a judgement call about the source data lives here, so
there is one place to look when OSM throws a value we have not seen.
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parent
DATA = ROOT / "data"
CACHE = ROOT / ".cache"
REPO = ROOT.parent.parent

# ── Overpass ───────────────────────────────────────────────────────────────
# A real User-Agent is NOT optional: overpass-api.de answers 406 Not Acceptable
# without one. Identify the app and give them a way to reach us, per the OSM
# API usage policy — the same reasoning as the tile User-Agent in
# lib/discover_tab/location_section/main.dart.
USER_AGENT = "passe-venue-import/1.0 (+https://passe.vn; rizzaxc@gmail.com)"

# Rotated on 429/504/timeout. The main instance 504s on large area[...] queries,
# which is why every query in this pipeline is bbox-scoped and chunked.
OVERPASS_MIRRORS = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.private.coffee/api/interpreter",
    "https://overpass.osm.jp/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
]

MIN_REQUEST_INTERVAL_S = 2.0
ATTEMPTS_PER_MIRROR = 2
BACKOFF_S = [5, 20, 60]

# ── Cities ─────────────────────────────────────────────────────────────────
# Bboxes cover the OLD HCMC / Hanoi footprints that VietnamLocationData scopes
# to. They deliberately spill into neighbouring provinces — the ward-name match
# against the 102/126 enum wards is what trims that back, and a venue that
# matches no enum ward is correctly out of footprint.
CITIES = {
    "hcm": {
        "cluster": 1,
        "label": "Thành phố Hồ Chí Minh",
        "bbox": (10.35, 106.35, 11.20, 107.02),
        "expected_wards": 102,
    },
    "hn": {
        "cluster": 2,
        "label": "Thành phố Hà Nội",
        # South edge reaches 20.55, not 20.80: the old Hanoi footprint runs
        # down through Phu Xuyen / Ung Hoa / My Duc, and a tighter box silently
        # leaves those 8 wards with no polygon.
        "bbox": (20.55, 105.25, 21.40, 106.05),
        "expected_wards": 126,
    },
}

# Post-2025-07-01 reform, Vietnam's commune level sits at admin_level 6 in OSM
# (the province→ward flattening removed the tier that used to occupy it).
# Verified: admin_level 9 is khu phố (sub-ward), and 8 returns nothing inside
# HCMC. Getting this wrong yields zero polygons, not wrong ones.
WARD_ADMIN_LEVEL = 6
WARD_PREFIXES = ("Phường ", "Xã ", "Thị trấn ", "Đặc khu ")

# ── Sport mapping ──────────────────────────────────────────────────────────
# Sport.index from lib/core/model/enum.dart: others=0, soccer=1, basketball=2,
# badminton=3, tennis=4, pickleball=5. Reordering that enum corrupts these.
SPORT_IDS = {
    "soccer": 1,
    "basketball": 2,
    "badminton": 3,
    "tennis": 4,
    "pickleball": 5,
}

# OSM `sport=` values → Passe sport. Values absent here still set
# has_declared_sport, which is what hides a volleyball-only court from the
# badminton feed without hiding untagged venues.
OSM_SPORT_TO_PASSE = {
    "soccer": "soccer",
    "football": "soccer",
    "futsal": "soccer",
    "basketball": "basketball",
    "badminton": "badminton",
    "tennis": "tennis",
    "pickleball": "pickleball",
}

# Recognized leisure/amenity values, mirroring _recognizedLeisure in
# lib/core/model/location.dart plus `track`, which the re-scrape now pulls.
RECOGNIZED_AMENITIES = {
    "pitch",
    "sports_centre",
    "stadium",
    "swimming_pool",
    "track",
}
