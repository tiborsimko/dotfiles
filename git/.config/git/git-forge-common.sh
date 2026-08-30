#!/usr/bin/env bash
# shellcheck disable=SC2034
#
# Shared GitHub/GitLab detection and metadata helpers. This file is sourced by
# the forge viewer and Taskwarrior capture helper; callers provide die().

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

# Set current_forge, current_host, and current_project from the origin remote.
detect_current_forge() {
  local remote_url remote_tail authority host project

  require_command git
  if ! remote_url=$(git remote get-url origin 2>/dev/null); then
    die "could not read the current repository's origin remote"
  fi

  case "$remote_url" in
    *://*)
      remote_tail=${remote_url#*://}
      remote_tail=${remote_tail#*@}
      authority=${remote_tail%%/*}
      [ "$authority" != "$remote_tail" ] ||
        die "could not determine the project from origin remote: $remote_url"
      host=${authority%%:*}
      project=${remote_tail#*/}
      ;;
    *:*)
      remote_tail=${remote_url#*@}
      host=${remote_tail%%:*}
      project=${remote_tail#*:}
      ;;
    *)
      die "unsupported origin remote URL: $remote_url"
      ;;
  esac

  project=${project#/}
  project=${project%.git}
  [ -n "$host" ] && [ -n "$project" ] ||
    die "could not parse the origin remote: $remote_url"

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
  current_project=$project
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
