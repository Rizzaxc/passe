#!/bin/sh
# Point git at the repo's tracked hooks. Run once after cloning:
#   sh tool/install-git-hooks.sh
#
# core.hooksPath is a *local* git setting (not committed), so each clone must
# opt in. This is idempotent — safe to re-run.

set -e
repo_root=$(git rev-parse --show-toplevel)
git -C "$repo_root" config core.hooksPath .githooks
chmod +x "$repo_root"/.githooks/* 2>/dev/null || true
echo "✓ git hooks installed (core.hooksPath -> .githooks)"
