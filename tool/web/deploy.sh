#!/usr/bin/env bash
# Build the Flutter web showcase and deploy it to app.passe.vn
# (Cloudflare Worker, static assets only — see tool/web/wrangler.jsonc).
#
#   tool/web/deploy.sh            build + deploy
#   tool/web/deploy.sh --build    build only (serve build/web locally to test)
#
# .env is bundled into the web build as a public asset, exactly as it is into
# the app binaries, so the same "client-safe values only" rule applies.

set -Eeuo pipefail

readonly REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
cd "$REPO_ROOT"

env_value="$(grep -E '^ENV=' .env | head -1 | cut -d= -f2- | tr -d '[:space:]')"
if [[ "$env_value" != "live" && "${ALLOW_NON_LIVE_ENV:-}" != "1" ]]; then
  echo "[web] ERROR: .env has ENV=$env_value; set ENV=live (or ALLOW_NON_LIVE_ENV=1)." >&2
  exit 1
fi

flutter build web --release --base-href /

if [[ "${1:-}" == "--build" ]]; then
  echo "[web] built build/web (not deployed)"
  exit 0
fi

# Reuse website/'s pinned wrangler rather than a global install.
(cd website && npx wrangler deploy --config ../tool/web/wrangler.jsonc)
