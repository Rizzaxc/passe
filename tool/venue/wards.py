"""Ward boundaries: fetch, assemble, index, and resolve to District.id."""

from __future__ import annotations

import json
import re
import unicodedata
from dataclasses import dataclass

from shapely.geometry import MultiPolygon, Point, Polygon, shape
from shapely.ops import unary_union
from shapely.strtree import STRtree

from config import DATA, WARD_ADMIN_LEVEL, WARD_PREFIXES

# Assigned when a point falls outside every polygon but within this distance of
# one. Exists solely to absorb geometry simplification and boundary-digitizing
# slop — NOT to guess. Anything further away is left alone.
BOUNDARY_SLOP_M = 200
_M_PER_DEG = 111_320.0


def normalize(raw: str) -> str:
    """The join key between OSM ward names and District.name.

    Must stay behaviourally identical to `_normalize` in
    test/tool/generate_district_fixture_test.dart.
    """
    s = (raw or "").strip()
    # đ/Đ is a distinct Vietnamese letter, not a diacritic — NFD leaves it
    # intact, so it has to be mapped explicitly on both sides of the join.
    s = s.replace("đ", "d").replace("Đ", "D")
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9]+", "", s.lower())


def strip_prefix(name: str) -> str:
    for p in WARD_PREFIXES:
        if name.startswith(p):
            return name[len(p):]
    return name


@dataclass(frozen=True)
class Ward:
    osm_id: int
    osm_name: str
    city: str          # 'hcm' | 'hn'
    district_id: str | None   # District.id, or None when out of footprint
    legacy: str | None


def load_districts() -> dict[str, dict[str, dict]]:
    """districts.json indexed as {city: {name_key: row}}."""
    rows = json.loads((DATA / "districts.json").read_text(encoding="utf-8"))
    out: dict[str, dict[str, dict]] = {}
    for r in rows:
        out.setdefault(r["city"], {})[r["name_key"]] = r
    return out


# ── Overpass → geometry ────────────────────────────────────────────────────

def ward_id_query(bbox_literal: str) -> str:
    """Names and ids only — cheap, one request per city."""
    return (
        f"[out:json][timeout:120];"
        f'rel["boundary"="administrative"]["admin_level"="{WARD_ADMIN_LEVEL}"]({bbox_literal});'
        f"out tags;"
    )


def ward_geom_query(osm_ids: list[int]) -> str:
    """Geometry for a bounded batch of known relations.

    Batching by ID rather than by sub-bbox matters. A bbox-chunked `out geom`
    re-downloads every relation that straddles a chunk edge once per chunk,
    and an administrative boundary with full member geometry is large — nine
    chunks per city turned into a request that never returned. Batching by id
    fetches each ward exactly once, keeps every payload bounded, and lets a
    failure be retried for just the wards it covered.
    """
    ids = ",".join(str(i) for i in osm_ids)
    return f"[out:json][timeout:180];rel(id:{ids});out geom;"


def _rings_from_members(members: list[dict], role: str) -> list[list[tuple]]:
    """Stitch relation member ways into closed rings.

    Overpass returns a boundary relation's outline as unordered, arbitrarily
    directed way fragments. Naively treating each fragment as a ring produces
    slivers, which silently swallow or exclude venues near a ward edge — so
    fragments are walked end-to-end and only closed loops are kept.
    """
    frags = [
        [(p["lon"], p["lat"]) for p in m.get("geometry") or []]
        for m in members
        if m.get("type") == "way" and m.get("role", "outer") == role and m.get("geometry")
    ]
    frags = [f for f in frags if len(f) >= 2]
    rings: list[list[tuple]] = []

    while frags:
        chain = frags.pop(0)
        progressed = True
        while progressed and chain[0] != chain[-1]:
            progressed = False
            for i, f in enumerate(frags):
                if f[0] == chain[-1]:
                    chain += f[1:]
                elif f[-1] == chain[-1]:
                    chain += f[::-1][1:]
                elif f[-1] == chain[0]:
                    chain = f[:-1] + chain
                elif f[0] == chain[0]:
                    chain = f[::-1][:-1] + chain
                else:
                    continue
                frags.pop(i)
                progressed = True
                break
        if len(chain) >= 4 and chain[0] == chain[-1]:
            rings.append(chain)
    return rings


def element_to_geometry(el: dict):
    """A boundary relation or closed way → a (Multi)Polygon, or None."""
    if el["type"] == "way":
        coords = [(p["lon"], p["lat"]) for p in el.get("geometry") or []]
        if len(coords) < 4 or coords[0] != coords[-1]:
            return None
        return Polygon(coords)

    members = el.get("members") or []
    outers = _rings_from_members(members, "outer")
    inners = _rings_from_members(members, "inner")
    if not outers:
        return None
    polys = [Polygon(o, inners if len(outers) == 1 else []) for o in outers]
    polys = [p.buffer(0) for p in polys if p.is_valid or p.buffer(0).is_valid]
    polys = [p for p in polys if not p.is_empty]
    if not polys:
        return None
    merged = unary_union(polys)
    return merged if isinstance(merged, (Polygon, MultiPolygon)) else None


# ── Index ──────────────────────────────────────────────────────────────────

class WardIndex:
    """Point-in-polygon lookup over the assembled ward set, scoped by city.

    Scoping matters: "An Phú" is a real ward name in more than one province,
    and an unscoped name match would file a Biên Hòa pitch into HCMC.
    """

    def __init__(self, features: list[dict]):
        self.wards: list[Ward] = []
        self.geoms = []
        for f in features:
            p = f["properties"]
            self.wards.append(
                Ward(
                    osm_id=p["osm_id"],
                    osm_name=p["osm_name"],
                    city=p["city"],
                    district_id=p.get("district_id"),
                    legacy=p.get("legacy"),
                )
            )
            self.geoms.append(shape(f["geometry"]))
        self.tree = STRtree(self.geoms) if self.geoms else None

    @classmethod
    def load(cls) -> "WardIndex":
        gj = json.loads((DATA / "wards_vn.geojson").read_text(encoding="utf-8"))
        return cls(gj["features"])

    def lookup(self, lat: float, lon: float, city: str | None = None):
        """(Ward, how) where how is 'contains' | 'near' | None."""
        if self.tree is None:
            return None, None
        pt = Point(lon, lat)
        for idx in self.tree.query(pt):
            if self.geoms[idx].contains(pt):
                w = self.wards[idx]
                if city is None or w.city == city:
                    return w, "contains"

        slop_deg = BOUNDARY_SLOP_M / _M_PER_DEG
        best, best_d = None, None
        for idx in self.tree.query(pt.buffer(slop_deg)):
            w = self.wards[idx]
            if city is not None and w.city != city:
                continue
            d = self.geoms[idx].distance(pt)
            if d <= slop_deg and (best_d is None or d < best_d):
                best, best_d = w, d
        return (best, "near") if best else (None, None)
