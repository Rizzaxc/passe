"""Read-only access to the live `location` table.

Reads only. RLS grants SELECT on `location` to anon, so this needs nothing
beyond the publishable key already bundled in the app — no service-role key,
no DB password, nothing that could write. Writes are deliberately a separate,
reviewable step: the pipeline emits schema/venue_import.sql and a human
applies it.
"""

from __future__ import annotations

import json
import urllib.parse

import requests

from config import REPO, USER_AGENT

PAGE = 1000


def _env() -> dict[str, str]:
    out: dict[str, str] = {}
    for line in (REPO / ".env").read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            out[k.strip()] = v.strip().strip('"').strip("'")
    return out


def fetch_locations() -> list[dict]:
    env = _env()
    base = env["SUPABASE_URL"].rstrip("/")
    key = env.get("SUPABASE_PUBLIC_KEY") or env["SUPABASE_PUBLISHABLE_KEY"]
    cols = (
        "id,external_id,name,full_address,street_number,street_name,district,"
        "district_legacy,city,lat,lon,tags,city_cluster,source,is_verified"
    )
    rows: list[dict] = []
    offset = 0
    while True:
        url = f"{base}/rest/v1/location?select={urllib.parse.quote(cols)}&order=id.asc"
        resp = requests.get(
            url,
            headers={
                "apikey": key,
                "Authorization": f"Bearer {key}",
                "Range-Unit": "items",
                "Range": f"{offset}-{offset + PAGE - 1}",
                "User-Agent": USER_AGENT,
            },
            timeout=30,
        )
        resp.raise_for_status()
        batch = resp.json()
        rows += batch
        if len(batch) < PAGE:
            return rows
        offset += PAGE
