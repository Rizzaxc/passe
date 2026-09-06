#!/usr/bin/env bash
# Upload a built iOS IPA to App Store Connect via xcrun altool, authenticated with an
# App Store Connect API key (no Apple ID / 2FA prompt).
#
# Requires secret/appstore.env (copy secret/appstore.env.example and fill it in) and the
# matching AuthKey_<ASC_KEY_ID>.p8 file placed alongside it in secret/.

set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
readonly SECRET_DIR="$REPO_ROOT/secret"
readonly APPSTORE_ENV="$SECRET_DIR/appstore.env"

ipa_path=""
dry_run=false

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [IPA_PATH] [options]

Upload a release IPA to App Store Connect using the API key configured in
$APPSTORE_ENV. Defaults to the single .ipa found under build/ios/ipa/.

Options:
  --dry-run   Print the upload command without running it
  -h, --help  Show this help

Examples:
  tool/$SCRIPT_NAME
  tool/$SCRIPT_NAME build/ios/ipa/passe.ipa
EOF
}

log() {
  printf '[upload] %s\n' "$*"
}

fail() {
  printf '[upload] ERROR: %s\n' "$*" >&2
  exit 1
}

on_error() {
  local -r exit_code=$?
  printf '[upload] ERROR: command failed on line %s (exit %s)\n' "${BASH_LINENO[0]}" "$exit_code" >&2
  exit "$exit_code"
}

trap on_error ERR

parse_arguments() {
  if [[ $# -gt 0 && "$1" != -* ]]; then
    ipa_path="$1"
    shift
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        dry_run=true
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        fail "Unknown option: $1 (run $SCRIPT_NAME --help for usage)"
        ;;
    esac
  done
}

resolve_ipa_path() {
  local -a matches=()

  if [[ -n "$ipa_path" ]]; then
    [[ -f "$ipa_path" ]] || fail "IPA not found: $ipa_path"
    return 0
  fi

  while IFS= read -r -d '' match; do
    matches+=("$match")
  done < <(find "$REPO_ROOT/build/ios/ipa" -maxdepth 1 -name '*.ipa' -print0 2>/dev/null)

  case "${#matches[@]}" in
    0) fail "No .ipa found under build/ios/ipa/ — run tool/build_release.sh ios first, or pass an IPA_PATH" ;;
    1) ipa_path="${matches[0]}" ;;
    *) fail "Multiple .ipa files found under build/ios/ipa/ — pass an explicit IPA_PATH" ;;
  esac
}

load_appstore_env() {
  [[ -f "$APPSTORE_ENV" ]] || fail \
    "Missing $APPSTORE_ENV (copy secret/appstore.env.example and fill it in)"

  # shellcheck disable=SC1090
  set -a
  source "$APPSTORE_ENV"
  set +a

  [[ -n "${ASC_KEY_ID:-}" ]] || fail "ASC_KEY_ID is missing from $APPSTORE_ENV"
  [[ -n "${ASC_ISSUER_ID:-}" ]] || fail "ASC_ISSUER_ID is missing from $APPSTORE_ENV"

  [[ -f "$SECRET_DIR/AuthKey_${ASC_KEY_ID}.p8" ]] || fail \
    "Missing $SECRET_DIR/AuthKey_${ASC_KEY_ID}.p8 (download it from App Store Connect and place it in secret/)"
}

main() {
  parse_arguments "$@"
  [[ "$(uname -s)" == "Darwin" ]] || fail "Uploading via xcrun altool requires macOS"
  command -v xcrun >/dev/null 2>&1 || fail "Required command not found: xcrun"

  resolve_ipa_path
  load_appstore_env

  log "Uploading $ipa_path (key $ASC_KEY_ID)"

  # altool discovers AuthKey_<id>.p8 files via API_PRIVATE_KEYS_DIR rather than a direct path.
  export API_PRIVATE_KEYS_DIR="$SECRET_DIR"

  local -a command=(
    xcrun altool --upload-app --type ios
    -f "$ipa_path"
    --apiKey "$ASC_KEY_ID"
    --apiIssuer "$ASC_ISSUER_ID"
  )

  if [[ "$dry_run" == true ]]; then
    printf '[upload] DRY RUN:'
    printf ' %q' "${command[@]}"
    printf '\n'
    exit 0
  fi

  "${command[@]}"
  log "Upload complete."
}

main "$@"
