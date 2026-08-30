#!/usr/bin/env bash
#
# Capture a GitHub/GitLab issue or pull/merge request from the current
# checkout, or complete a clipboard capture whose whole description is a
# supported forge URL.
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

script_name=${0##*/}
canonical_uuid_re='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
common_file=${GIT_FORGE_COMMON:-"${XDG_CONFIG_HOME:-$HOME/.config}/git/git-forge-common.sh"}

usage() {
  cat >&2 <<EOF
Usage:
  $script_name capture <issue|pr> <number> [task-modifiers...]
  $script_name enrich <task-id-or-uuid>
EOF
}

die() {
  echo "$script_name: $*" >&2
  exit 1
}

[ -r "$common_file" ] || die "shared forge helper not found: $common_file"
# shellcheck source=git/.config/git/git-forge-common.sh
source "$common_file"

validate_modifiers() {
  local modifier

  for modifier in "$@"; do
    case "$modifier" in
      --* | description:* | status:* | uuid:* | rc.*)
        die "unsupported task modifier: $modifier"
        ;;
      +?* | -?* | ?*:*)
        ;;
      *)
        die "expected a Taskwarrior modifier, got: $modifier"
        ;;
    esac
  done
}

create_task() {
  local raw uuid

  if ! raw=$(task rc.verbose=new-uuid add "$@" -- "$forge_description"); then
    die "task creation failed"
  fi

  uuid=$(
    printf '%s\n' "$raw" |
      sed -n 's/^Created task \([0-9a-f]\{8\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}-[0-9a-f]\{12\}\)\.$/\1/p'
  )

  if [[ ! "$uuid" =~ $canonical_uuid_re ]]; then
    die "task may have been created, but its UUID could not be parsed; do not retry automatically (output: $raw)"
  fi

  if ! task "$uuid" annotate -- "$forge_url"; then
    die "task $uuid was created, but URL annotation failed; do not retry capture"
  fi

  printf 'Captured %s (%s): %s\n' "$uuid" "$forge_state" \
    "$forge_description"
}

capture() {
  [ "$#" -ge 2 ] || {
    usage
    exit 2
  }

  local item_kind=$1
  local reference=$2
  shift 2

  case "$item_kind" in
    issue | pr)
      ;;
    *)
      die "item kind must be issue or pr"
      ;;
  esac

  [[ "$reference" =~ ^[0-9]+$ ]] || die "issue or change-request number must be numeric"
  validate_modifiers "$@"
  detect_current_forge
  fetch_metadata "$current_forge" "$item_kind" "$reference" "$current_host"
  create_task "$@"
}

enrich() {
  [ "$#" -eq 1 ] || {
    usage
    exit 2
  }

  local selector=$1
  local uuid description lookup_url

  if [[ ! "$selector" =~ ^[0-9]+$ ]] &&
    [[ ! "$selector" =~ $canonical_uuid_re ]]; then
    die "task selector must be an ID or canonical UUID"
  fi

  uuid=$(task _get "$selector.uuid" 2>/dev/null || true)
  [[ "$uuid" =~ $canonical_uuid_re ]] || die "could not resolve task: $selector"

  description=$(task _get "$uuid.description" 2>/dev/null || true)
  lookup_url=${description%%\?*}
  lookup_url=${lookup_url%%\#*}
  lookup_url=${lookup_url%/}
  classify_url "$lookup_url" ||
    die "task $selector does not have a bare supported forge URL"

  fetch_metadata "$url_forge" "$url_kind" "$url_reference" "$url_host" \
    "$url_project"

  if ! task "$uuid" annotate -- "$description"; then
    die "could not preserve the original URL; description was not changed"
  fi

  if ! task "$uuid" modify -- "$forge_description"; then
    die "URL was annotated, but the readable description could not be applied"
  fi

  printf 'Enriched %s (%s): %s\n' "$uuid" "$forge_state" \
    "$forge_description"
}

require_command task
require_command sed

case "${1:-}" in
  capture)
    shift
    capture "$@"
    ;;
  enrich)
    shift
    enrich "$@"
    ;;
  -h | --help | help)
    usage
    ;;
  *)
    usage
    exit 2
    ;;
esac
