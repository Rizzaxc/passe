#!/usr/bin/env bash
# Build store-ready Passe artifacts for Android and/or iOS.
#
# Android requires android/key.properties and its referenced upload keystore.
# iOS requires a valid Apple distribution certificate and provisioning setup.

set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"

target="all"
android_format="appbundle"
build_name=""
build_number=""
export_options_plist=""
allow_non_live_env=false
clean_first=false
dry_run=false
run_analyze=true

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [all|android|ios] [options]

Build release artifacts for both platforms (default), or one platform.

Options:
  --android-format FORMAT       appbundle (default), apk, or both
  --build-name VERSION          Override pubspec version name (for example 1.2.0)
  --build-number NUMBER         Override pubspec build number (positive integer)
  --export-options-plist PATH   Custom ExportOptions.plist for the iOS IPA export
  --allow-non-live-env          Permit .env ENV values other than live
  --clean                       Run flutter clean before fetching dependencies
  --skip-analyze                Skip flutter analyze before compiling
  --dry-run                     Print commands without running them
  -h, --help                    Show this help

Artifacts:
  Android AAB  build/app/outputs/bundle/release/app-release.aab
  Android APK  build/app/outputs/flutter-apk/app-release.apk
  iOS IPA      build/ios/ipa/*.ipa

Examples:
  tool/$SCRIPT_NAME
  tool/$SCRIPT_NAME android --build-name 1.2.0 --build-number 42
  tool/$SCRIPT_NAME ios --export-options-plist ios/ExportOptions.plist
EOF
}

log() {
  printf '[release] %s\n' "$*"
}

fail() {
  printf '[release] ERROR: %s\n' "$*" >&2
  exit 1
}

on_error() {
  local -r exit_code=$?
  printf '[release] ERROR: command failed on line %s (exit %s)\n' "${BASH_LINENO[0]}" "$exit_code" >&2
  exit "$exit_code"
}

trap on_error ERR

run() {
  if [[ "$dry_run" == true ]]; then
    printf '[release] DRY RUN:'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

require_command() {
  local -r command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 || fail "Required command not found: $command_name"
}

read_env_value() {
  local -r key="$1"
  local line=""
  local value=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == "$key="* ]] || continue
    value="${line#*=}"
    value="${value%$'\r'}"
    if [[ "$value" == \"*\" && "$value" == *\" ]]; then
      value="${value:1:${#value}-2}"
    elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
      value="${value:1:${#value}-2}"
    fi
    printf '%s' "$value"
    return 0
  done < "$REPO_ROOT/.env"

  return 1
}

validate_environment() {
  local env_name=""
  local required_key=""
  local required_value=""
  local -a required_keys=(SUPABASE_URL SUPABASE_PUBLIC_KEY SENTRY_DSN)

  [[ -f "$REPO_ROOT/.env" ]] || fail "Missing $REPO_ROOT/.env (copy .env.example and fill it in)"

  env_name="$(read_env_value ENV || true)"
  if [[ "$env_name" != "live" && "$allow_non_live_env" != true ]]; then
    fail ".env must contain ENV=live; use --allow-non-live-env only for non-store test builds"
  fi

  for required_key in "${required_keys[@]}"; do
    required_value="$(read_env_value "$required_key" || true)"
    [[ -n "$required_value" ]] || fail ".env value is missing: $required_key"
  done
}

property_value() {
  local -r file_path="$1"
  local -r key="$2"
  local line=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == "$key="* ]] || continue
    printf '%s' "${line#*=}"
    return 0
  done < "$file_path"

  return 1
}

validate_android_signing() {
  local -r properties_file="$REPO_ROOT/android/key.properties"
  local property=""
  local value=""
  local store_file=""
  local -a required_properties=(storePassword keyPassword keyAlias storeFile)

  [[ -f "$properties_file" ]] || fail \
    "Missing android/key.properties (copy android/key.properties.example and fill it in)"

  for property in "${required_properties[@]}"; do
    value="$(property_value "$properties_file" "$property" || true)"
    [[ -n "$value" ]] || fail "android/key.properties value is missing: $property"
  done

  store_file="$(property_value "$properties_file" storeFile)"
  if [[ "$store_file" != /* ]]; then
    store_file="$REPO_ROOT/android/app/$store_file"
  fi
  [[ -f "$store_file" ]] || fail "Android keystore not found at the path configured by storeFile"
}

parse_arguments() {
  if [[ $# -gt 0 && "$1" != -* ]]; then
    target="$1"
    shift
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --android-format)
        [[ $# -ge 2 ]] || fail "--android-format requires a value"
        android_format="$2"
        shift 2
        ;;
      --build-name)
        [[ $# -ge 2 ]] || fail "--build-name requires a value"
        build_name="$2"
        shift 2
        ;;
      --build-number)
        [[ $# -ge 2 ]] || fail "--build-number requires a value"
        build_number="$2"
        shift 2
        ;;
      --export-options-plist)
        [[ $# -ge 2 ]] || fail "--export-options-plist requires a path"
        export_options_plist="$2"
        shift 2
        ;;
      --allow-non-live-env)
        allow_non_live_env=true
        shift
        ;;
      --clean)
        clean_first=true
        shift
        ;;
      --skip-analyze)
        run_analyze=false
        shift
        ;;
      --dry-run)
        dry_run=true
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --)
        shift
        [[ $# -eq 0 ]] || fail "Unexpected positional argument: $1"
        ;;
      *)
        fail "Unknown option: $1 (run $SCRIPT_NAME --help for usage)"
        ;;
    esac
  done
}

validate_arguments() {
  case "$target" in
    all|android|ios) ;;
    *) fail "Target must be all, android, or ios" ;;
  esac

  case "$android_format" in
    appbundle|apk|both) ;;
    *) fail "--android-format must be appbundle, apk, or both" ;;
  esac

  if [[ -n "$build_name" && ! "$build_name" =~ ^[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?$ ]]; then
    fail "--build-name must be a semantic version such as 1.2.0"
  fi
  if [[ -n "$build_number" && ! "$build_number" =~ ^[1-9][0-9]*$ ]]; then
    fail "--build-number must be a positive integer"
  fi
  if [[ -n "$export_options_plist" ]]; then
    [[ "$target" != "android" ]] || fail "--export-options-plist only applies to iOS"
    [[ -f "$export_options_plist" ]] || fail "Export options plist not found: $export_options_plist"
    export_options_plist="$(cd -- "$(dirname -- "$export_options_plist")" && pwd -P)/$(basename -- "$export_options_plist")"
  fi
}

build_android() {
  local -a command=(flutter build)

  if [[ "$android_format" == "appbundle" || "$android_format" == "both" ]]; then
    command=(flutter build appbundle --release --no-pub)
    [[ -z "$build_name" ]] || command+=(--build-name "$build_name")
    [[ -z "$build_number" ]] || command+=(--build-number "$build_number")
    run "${command[@]}"
  fi

  if [[ "$android_format" == "apk" || "$android_format" == "both" ]]; then
    command=(flutter build apk --release --no-pub)
    [[ -z "$build_name" ]] || command+=(--build-name "$build_name")
    [[ -z "$build_number" ]] || command+=(--build-number "$build_number")
    run "${command[@]}"
  fi
}

build_ios() {
  local -a command=(flutter build ipa --release --no-pub)

  [[ -z "$build_name" ]] || command+=(--build-name "$build_name")
  [[ -z "$build_number" ]] || command+=(--build-number "$build_number")
  [[ -z "$export_options_plist" ]] || command+=(--export-options-plist "$export_options_plist")
  run "${command[@]}"
}

main() {
  parse_arguments "$@"
  validate_arguments
  require_command flutter
  validate_environment

  if [[ "$target" == "all" || "$target" == "android" ]]; then
    validate_android_signing
  fi
  if [[ "$target" == "all" || "$target" == "ios" ]]; then
    [[ "$(uname -s)" == "Darwin" ]] || fail "iOS release builds require macOS"
    require_command xcodebuild
  fi

  cd -- "$REPO_ROOT"
  log "Building target: $target"

  if [[ "$clean_first" == true ]]; then
    run flutter clean
  fi
  run flutter pub get
  if [[ "$run_analyze" == true ]]; then
    run flutter analyze
  fi

  if [[ "$target" == "all" || "$target" == "android" ]]; then
    build_android
  fi
  if [[ "$target" == "all" || "$target" == "ios" ]]; then
    build_ios
  fi

  log "Release build completed. See build/app/outputs and build/ios/ipa."
}

main "$@"
