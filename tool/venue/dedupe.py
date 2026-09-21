"""Match incoming venues against what is already in `location`.

The governing constraint: five tables FK into `location` (activity,
lobby_homeground, lobby.challenge_offer_location, lobby_challenge,
referee_booking, professional_preferred_location). A match therefore UPDATES
the existing row in place and preserves its `id` — never delete-and-reinsert,
which would orphan a scheduled session's venue.
"""

from __future__ import annotations

import math
import re
import unicodedata

# A venue and its "same place" duplicate sit within a building's footprint.
# 60 m is wide enough to bridge a node-vs-way-centroid offset on one complex,
# tight enough not to merge two adjacent five-a-side pitches.
NEAR_M = 60
# Tighter, for the riskier "one side is nameless" case, where there is no
# name evidence at all and only proximity is arguing for the merge.
NEAR_UNNAMED_M = 25
NAME_RATIO = 0.85


def haversine_m(lat1, lon1, lat2, lon2) -> float:
    r = 6_371_000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = p2 - p1
    dl = math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def _key(s: str) -> str:
    s = unicodedata.normalize("NFD", (s or "").replace("đ", "d").replace("Đ", "D"))
    s = "".join(c for c in s if unicodedata.category(c) != "Mn").lower()
    return re.sub(r"[^a-z0-9 ]+", " ", s)


def token_set_ratio(a: str, b: str) -> float:
    """Order-insensitive token overlap (Jaccard).

    Deliberately not a sequence ratio: Vietnamese venue names reorder freely
    ("Sân Cầu Lông Lan Anh" vs "Lan Anh - Sân Cầu Lông") and a positional
    measure scores those far apart.
    """
    ta, tb = set(_key(a).split()), set(_key(b).split())
    if not ta or not tb:
        return 0.0
    return len(ta & tb) / len(ta | tb)


class Matcher:
    """Spatial index over existing rows, bucketed on a ~1.1 km lat/lon grid."""

    CELL = 0.01

    def __init__(self, existing: list[dict]):
        self.by_external: dict[str, dict] = {}
        self.grid: dict[tuple, list[dict]] = {}
        for row in existing:
            if row.get("external_id"):
                self.by_external[row["external_id"]] = row
            if row.get("lat") is not None and row.get("lon") is not None:
                self.grid.setdefault(self._cell(row["lat"], row["lon"]), []).append(row)

    def _cell(self, lat, lon):
        return (int(lat / self.CELL), int(lon / self.CELL))

    def find(self, external_ids: list[str], name: str, lat, lon):
        """(row, how) where how is 'external_id' | 'spatial' | None."""
        for ext in external_ids:
            hit = self.by_external.get(ext)
            if hit:
                return hit, "external_id"

        if lat is None or lon is None:
            return None, None

        ci, cj = self._cell(lat, lon)
        best, best_d = None, None
        for di in (-1, 0, 1):
            for dj in (-1, 0, 1):
                for row in self.grid.get((ci + di, cj + dj), []):
                    d = haversine_m(lat, lon, row["lat"], row["lon"])
                    if d > NEAR_M:
                        continue
                    a, b = (name or "").strip(), (row.get("name") or "").strip()
                    if a and b:
                        ok = token_set_ratio(a, b) >= NAME_RATIO
                    else:
                        # No name evidence on one side — proximity alone has to
                        # carry it, so demand much more of it.
                        ok = d <= NEAR_UNNAMED_M
                    if ok and (best_d is None or d < best_d):
                        best, best_d = row, d
        return (best, "spatial") if best else (None, None)
