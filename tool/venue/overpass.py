"""Overpass client: mirror rotation, backoff, and an on-disk response cache.

The cache is the point. A ward pull is ~40 minutes of Overpass time; a bug in
the matching code downstream should cost seconds to retry, not another 40
minutes (and not another 40 minutes of load on a donated public endpoint).
"""

from __future__ import annotations

import hashlib
import json
import sys
import time

import requests

from config import (
    ATTEMPTS_PER_MIRROR,
    BACKOFF_S,
    CACHE,
    MIN_REQUEST_INTERVAL_S,
    OVERPASS_MIRRORS,
    USER_AGENT,
)

_last_request_at = 0.0


class OverpassError(RuntimeError):
    pass


def _throttle() -> None:
    global _last_request_at
    wait = MIN_REQUEST_INTERVAL_S - (time.monotonic() - _last_request_at)
    if wait > 0:
        time.sleep(wait)
    _last_request_at = time.monotonic()


def query(ql: str, *, timeout_s: int = 180, use_cache: bool = True) -> dict:
    """Run an Overpass QL query, returning the parsed JSON.

    Raises OverpassError only after every mirror has been tried. Callers that
    can tolerate a hole (the name-regex pass) should catch it and carry on;
    callers that cannot (the ward pull) should let it propagate.
    """
    CACHE.mkdir(exist_ok=True)
    key = hashlib.sha256(ql.encode("utf-8")).hexdigest()[:24]
    cached = CACHE / f"{key}.json"
    if use_cache and cached.exists():
        return json.loads(cached.read_text(encoding="utf-8"))

    errors: list[str] = []
    for attempt in range(ATTEMPTS_PER_MIRROR):
        for mirror in OVERPASS_MIRRORS:
            _throttle()
            try:
                resp = requests.post(
                    mirror,
                    data={"data": ql},
                    headers={"User-Agent": USER_AGENT},
                    timeout=timeout_s,
                )
            except requests.RequestException as exc:
                errors.append(f"{mirror}: {type(exc).__name__}")
                continue

            if resp.status_code == 200:
                try:
                    payload = resp.json()
                except ValueError:
                    # Overpass reports runtime errors (dispatcher busy, out of
                    # memory) as an HTML body with a 200. Treat as retryable.
                    errors.append(f"{mirror}: 200 but non-JSON body")
                    continue
                if use_cache:
                    cached.write_text(json.dumps(payload), encoding="utf-8")
                return payload

            errors.append(f"{mirror}: HTTP {resp.status_code}")
            if resp.status_code in (400, 406):
                # Not retryable: a malformed query, or a missing User-Agent.
                raise OverpassError(f"{mirror} rejected the query: {resp.status_code}\n{ql}")

        delay = BACKOFF_S[min(attempt, len(BACKOFF_S) - 1)]
        print(f"  all mirrors failed, backing off {delay}s", file=sys.stderr)
        time.sleep(delay)

    raise OverpassError("every mirror failed:\n  " + "\n  ".join(errors))


def split_bbox(bbox: tuple[float, float, float, float], n: int) -> list[tuple]:
    """Split a (south, west, north, east) bbox into an n x n grid.

    Overpass costs scale with area; chunking is what keeps a city query under
    the 504 threshold and lets a partial failure be retried cheaply.
    """
    s, w, north, e = bbox
    dlat = (north - s) / n
    dlon = (e - w) / n
    return [
        (s + i * dlat, w + j * dlon, s + (i + 1) * dlat, w + (j + 1) * dlon)
        for i in range(n)
        for j in range(n)
    ]


def bbox_str(bbox: tuple[float, float, float, float]) -> str:
    return ",".join(f"{v:.6f}" for v in bbox)
