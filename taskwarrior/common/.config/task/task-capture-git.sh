#!/usr/bin/env bash
#
# Capture a GitHub/GitLab issue or pull/merge request from the current
# checkout, or complete a clipboard capture whose whole description is a
# supported forge URL.
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

script_name=${0##*/}
canonical_uuid_re='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

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

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

# Set current_forge and current_host from the origin remote. Only the host is
# needed here; each forge client remains responsible for resolving the project.
detect_current_forge() {
  local remote_url host

  require_command git
  if ! remote_url=$(git remote get-url origin 2>/dev/null); then
    die "could not read the current repository's origin remote"
  fi

  host=${remote_url#*://}
  host=${host#*@}
  host=${host%%[:/]*}

  case "$host" in
    github.com)
      current_forge=github
      ;;
    gitlab.com | gitlab.*)
      current_forge=gitlab
      ;;
    *)
      die "unsupported forge host in origin remote: $host"
      ;;
  esac

  current_host=$host
}

# Parse and validate the canonical URL returned by a forge client, then set the
# repo name and human-readable Taskwarrior description.
parse_canonical_url() {
  local expected_forge=$1
  local expected_kind=$2
  local expected_host=$3
  local url_number project_path remote_kind sigil

  case "$expected_forge" in
    github)
      if [[ "$forge_url" =~ ^https://github\.com/([^/]+)/([^/]+)/(issues|pull)/([0-9]+)$ ]]; then
        forge_host=github.com
        forge_repo=${BASH_REMATCH[2]}
        remote_kind=${BASH_REMATCH[3]}
        url_number=${BASH_REMATCH[4]}
      else
        die "GitHub returned an unexpected URL: $forge_url"
      fi

      case "$expected_kind:$remote_kind" in
        issue:issues | pr:pull)
          ;;
        *)
          die "GitHub returned a URL for the wrong item kind: $forge_url"
          ;;
      esac
      sigil='#'
      ;;
    gitlab)
      if [[ "$forge_url" =~ ^https://([^/]+)/(.+)/-/(issues|work_items|merge_requests)/([0-9]+)$ ]]; then
        forge_host=${BASH_REMATCH[1]}
        project_path=${BASH_REMATCH[2]}
        remote_kind=${BASH_REMATCH[3]}
        url_number=${BASH_REMATCH[4]}
        forge_repo=${project_path##*/}
      else
        die "GitLab returned an unexpected URL: $forge_url"
      fi

      case "$expected_kind:$remote_kind" in
        issue:issues | issue:work_items)
          sigil='#'
          ;;
        pr:merge_requests)
          sigil='!'
          ;;
        *)
          die "GitLab returned a URL for the wrong item kind: $forge_url"
          ;;
      esac
      ;;
    *)
      die "unsupported forge: $expected_forge"
      ;;
  esac

  [ "$forge_host" = "$expected_host" ] ||
    die "forge host and canonical URL disagree"
  [ "$url_number" = "$forge_number" ] ||
    die "forge number and canonical URL disagree"

  forge_description="${forge_repo}${sigil}${forge_number} — ${forge_title}"
}

# Set forge_number, forge_title, forge_state, forge_url, forge_repo, and
# forge_description from one CLI lookup.
fetch_metadata() {
  local selected_forge=$1
  local selected_kind=$2
  local reference=$3
  local expected_host=$4
  local selected_project=${5:-}
  local metadata

  case "$selected_forge:$selected_kind" in
    github:issue)
      require_command gh
      if ! metadata=$(
        gh issue view "$reference" --json number,title,state,url \
          --jq '[.number, .title, .state, .url] | @tsv'
      ); then
        die "GitHub issue lookup failed for $reference"
      fi
      ;;
    github:pr)
      require_command gh
      if ! metadata=$(
        gh pr view "$reference" --json number,title,state,url \
          --jq '[.number, .title, .state, .url] | @tsv'
      ); then
        die "GitHub pull-request lookup failed for $reference"
      fi
      ;;
    gitlab:issue)
      require_command glab
      if [ -n "$selected_project" ]; then
        metadata=$(
          glab issue view "$reference" \
            --repo "$expected_host/$selected_project" --output json \
            --jq '[.iid, .title, .state, .web_url] | @tsv'
        ) || die "GitLab issue lookup failed for $reference"
      elif ! metadata=$(
        glab issue view "$reference" --output json \
          --jq '[.iid, .title, .state, .web_url] | @tsv'
      ); then
        die "GitLab issue lookup failed for $reference"
      fi
      ;;
    gitlab:pr)
      require_command glab
      if [ -n "$selected_project" ]; then
        metadata=$(
          glab mr view "$reference" \
            --repo "$expected_host/$selected_project" --output json \
            --jq '[.iid, .title, .state, .web_url] | @tsv'
        ) || die "GitLab merge-request lookup failed for $reference"
      elif ! metadata=$(
        glab mr view "$reference" --output json \
          --jq '[.iid, .title, .state, .web_url] | @tsv'
      ); then
        die "GitLab merge-request lookup failed for $reference"
      fi
      ;;
    *)
      die "unsupported forge item kind: $selected_forge $selected_kind"
      ;;
  esac

  IFS=$'\t' read -r forge_number forge_title forge_state forge_url \
    <<<"$metadata"

  [[ "$forge_number" =~ ^[0-9]+$ ]] || die "forge returned an invalid number"
  [ -n "$forge_title" ] || die "forge returned an empty title"
  [ -n "$forge_state" ] || die "forge returned an empty state"

  parse_canonical_url "$selected_forge" "$selected_kind" "$expected_host"
}

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

classify_url() {
  local url=$1

  url_project=
  url_reference=$url

  if [[ "$url" =~ ^https://github\.com/[^/]+/[^/]+/(issues|pull)/[0-9]+$ ]]; then
    url_forge=github
    url_host=github.com
    case "${BASH_REMATCH[1]}" in
      issues) url_kind='issue' ;;
      pull) url_kind='pr' ;;
    esac
  elif [[ "$url" =~ ^https://([^/]+)/(.+)/-/(issues|work_items|merge_requests)/([0-9]+)$ ]]; then
    url_forge=gitlab
    url_host=${BASH_REMATCH[1]}
    url_project=${BASH_REMATCH[2]}
    url_reference=${BASH_REMATCH[4]}
    case "${BASH_REMATCH[3]}" in
      issues | work_items) url_kind='issue' ;;
      merge_requests) url_kind='pr' ;;
    esac
  else
    return 1
  fi
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
