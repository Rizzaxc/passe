#!/usr/bin/env bash
# Uploads the App Store screenshot photos into the public `wall_post` bucket.
#
# Companion to schema/shot_seed_timeline.sql, which creates the posts that
# reference these objects. Run this FIRST — `wall_post.media` is NOT NULL and
# `fn_valid_wall_post_media` requires a non-empty `path` per entry, so a post
# whose object is missing renders a broken image rather than an empty state.
#
# Downscales to match what the app itself uploads (ComposePostController:
# maxWidth 1440, JPEG quality 80), so a seeded post is byte-for-byte the kind
# of thing a real one is, and the Feed loads at the same speed.
#
# Paths follow the app's convention `<author_uid>/<name>.jpg`: the storage
# policy can only check the first path segment against auth.uid(), so posts are
# user-scoped rather than post-scoped. Names are FIXED (not timestamped like the
# app's) and uploaded with x-upsert, so re-running is idempotent and the SQL can
# reference the paths literally.
#
# Usage:  sh tool/shot_upload_media.sh [SOURCE_DIR]     (default: repo root)
set -euo pipefail

SRC="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUCKET="wall_post"

# SUPABASE_URL is client-safe and lives in .env; the service key is admin-only
# and lives in secret/db.env (git-ignored, never a Flutter asset).
set -a
. "$ROOT/.env"
. "$ROOT/secret/db.env"
set +a

: "${SUPABASE_URL:?SUPABASE_URL missing from .env}"
: "${SUPABASE_SECRET_KEY:?SUPABASE_SECRET_KEY missing from secret/db.env}"

HERO="51070000-0000-4000-8000-000000000001"
FRIEND="51070000-0000-4000-8000-000000000003"
PICKLE_MATE="51070000-0000-4000-8000-000000000058"

# source file -> "<author_uid>/<object name>"
MAP="
soccer1.jpg|$HERO/shot_soccer1.jpg
soccer2.jpg|$FRIEND/shot_soccer2.jpg
pickleball1.jpg|$HERO/shot_pickleball1.jpg
pickleball2.jpg|$PICKLE_MATE/shot_pickleball2.jpg
"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "source:  $SRC"
echo "bucket:  $BUCKET"
echo

missing=0
for row in $MAP; do
  [ -z "$row" ] && continue
  file="${row%%|*}"
  [ -f "$SRC/$file" ] || { echo "MISSING: $SRC/$file"; missing=1; }
done
[ "$missing" -eq 0 ] || { echo; echo "Add the missing photos and re-run."; exit 1; }

for row in $MAP; do
  [ -z "$row" ] && continue
  file="${row%%|*}"
  path="${row##*|}"
  out="$TMP/$(basename "$path")"

  # sips ships with macOS; no ImageMagick dependency. Resamples the LONGEST
  # edge, which is what we want for the portrait shots too.
  sips -s format jpeg -s formatOptions 80 -Z 1440 "$SRC/$file" --out "$out" >/dev/null

  before=$(wc -c < "$SRC/$file" | tr -d ' ')
  after=$(wc -c < "$out" | tr -d ' ')

  code=$(curl -s -o "$TMP/resp.json" -w '%{http_code}' \
    -X POST "$SUPABASE_URL/storage/v1/object/$BUCKET/$path" \
    -H "apikey: $SUPABASE_SECRET_KEY" \
    -H "Authorization: Bearer $SUPABASE_SECRET_KEY" \
    -H "Content-Type: image/jpeg" \
    -H "x-upsert: true" \
    --data-binary "@$out")

  if [ "$code" = "200" ]; then
    printf '  ok   %-28s %6s KB -> %5s KB   %s\n' \
      "$file" "$((before/1024))" "$((after/1024))" "$path"
  else
    printf '  FAIL %-28s HTTP %s\n' "$file" "$code"
    cat "$TMP/resp.json"; echo
    exit 1
  fi
done

echo
echo "Done. Public URLs are:"
echo "  $SUPABASE_URL/storage/v1/object/public/$BUCKET/<path>"
echo "Now apply schema/shot_seed_timeline.sql to create the posts."
