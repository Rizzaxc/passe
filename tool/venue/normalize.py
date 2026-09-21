"""Derive sport_ids / amenity_kinds / has_declared_sport from raw tags."""

from __future__ import annotations

from config import OSM_SPORT_TO_PASSE, RECOGNIZED_AMENITIES, SPORT_IDS


def parse_db_tags(tags: list[str] | None) -> dict[str, list[str]]:
    """Parse the stored `"key:[v1, v2]"` format.

    Mirrors `_parseTags` in lib/core/model/location.dart, including its
    tolerance for the bare values the mocked_ seed writes.
    """
    out: dict[str, list[str]] = {}
    for entry in tags or []:
        if ":" not in entry:
            continue
        key, _, rest = entry.partition(":")
        rest = rest.strip()
        if rest.startswith("[") and rest.endswith("]"):
            rest = rest[1:-1]
        values = [v.strip() for v in rest.split(",") if v.strip()]
        if values:
            out[key.strip()] = values
    return out


def classify(tag_map: dict[str, list[str]]) -> tuple[list[int], list[str], bool]:
    """(sport_ids, amenity_kinds, has_declared_sport).

    `has_declared_sport` is true whenever the source named ANY sport, even one
    Passe does not support. That is the whole point: it lets a volleyball-only
    court be hidden from the badminton feed while an untagged general facility
    stays visible. Collapsing the two would drop ~433 rows from every feed.
    """
    declared = [v.lower() for v in tag_map.get("sport", [])]
    ids = sorted(
        {
            SPORT_IDS[OSM_SPORT_TO_PASSE[v]]
            for v in declared
            if v in OSM_SPORT_TO_PASSE
        }
    )
    amenities = sorted(
        {
            v
            for key in ("leisure", "amenity")
            for v in (x.lower() for x in tag_map.get(key, []))
            if v in RECOGNIZED_AMENITIES
        }
    )
    return ids, amenities, bool(declared)


def osm_tags_to_stored(tags: dict[str, str]) -> list[str]:
    """Render an Overpass tag dict into the DB's `"key:[v]"` convention.

    Keeping the stored shape identical to the existing 2,050 rows means the
    client's `_parseTags` fallback keeps working on new rows without a
    migration, and the two sources stay diffable.
    """
    out = []
    for k, v in sorted(tags.items()):
        values = [p.strip() for p in str(v).split(";") if p.strip()]
        if values:
            out.append(f"{k}:[{', '.join(values)}]")
    return out
