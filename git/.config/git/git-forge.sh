#!/usr/bin/env bash
#
# Present one forge-neutral interface for GitHub and GitLab repositories,
# issues/work items, and pull/merge requests.
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

script_name=${0##*/}
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
common_file=${GIT_FORGE_COMMON:-"$script_dir/git-forge-common.sh"}
task_capture=${TASK_CAPTURE_GIT:-"${XDG_CONFIG_HOME:-$HOME/.config}/task/task-capture-git.sh"}

usage() {
  cat >&2 <<EOF
Usage:
  git r [-w|--web]
  git i [number] [-w|--web]
  git i <number> [-t|--task] [task-modifiers...]
  git p [<number|.>] [-w|--web]
  git p <number> [-t|--task] [task-modifiers...]

With no number, i and p list items in the terminal. A number displays one
item, and p accepts . for the pull/merge request associated with the current
branch. Use --web to open the same target in a browser or --task to capture a
numbered item as a Taskwarrior task.
EOF
}

die() {
  echo "$script_name: $*" >&2
  exit 1
}

[ -r "$common_file" ] || die "shared forge helper not found: $common_file"
# shellcheck source=git/.config/git/git-forge-common.sh
source "$common_file"

select_mode() {
  local selected=$1

  if [ "$mode" != terminal ] && [ "$mode" != "$selected" ]; then
    die "--web and --task are mutually exclusive"
  fi
  mode=$selected
}

open_url() {
  local url=$1

  if command -v open >/dev/null 2>&1; then
    open "$url"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url"
  else
    die "could not find open or xdg-open to launch a browser"
  fi
}

view_repo() {
  case "$current_forge:$mode" in
    github:terminal)
      require_command gh
      gh repo view
      ;;
    github:web)
      require_command gh
      gh repo view --web
      ;;
    gitlab:terminal)
      require_command glab
      glab repo view
      ;;
    gitlab:web)
      require_command glab
      glab repo view --web
      ;;
    *)
      die "unsupported repository mode: $mode"
      ;;
  esac
}

list_items() {
  case "$current_forge:$item_kind:$mode" in
    github:issue:terminal)
      require_command gh
      gh issue list
      ;;
    github:issue:web)
      require_command gh
      gh issue list --web
      ;;
    github:pr:terminal)
      require_command gh
      gh pr list
      ;;
    github:pr:web)
      require_command gh
      gh pr list --web
      ;;
    gitlab:issue:terminal)
      require_command glab
      glab issue list
      ;;
    gitlab:issue:web)
      open_url "https://$current_host/$current_project/-/issues"
      ;;
    gitlab:pr:terminal)
      require_command glab
      glab mr list
      ;;
    gitlab:pr:web)
      open_url "https://$current_host/$current_project/-/merge_requests"
      ;;
    *)
      die "unsupported item-list mode: $item_kind $mode"
      ;;
  esac
}

view_item() {
  case "$current_forge:$item_kind" in
    github:issue)
      require_command gh
      if [ "$mode" = web ]; then
        gh issue view "$reference" --web
      else
        gh issue view "$reference"
      fi
      ;;
    github:pr)
      require_command gh
      if [ "$reference" = . ]; then
        if [ "$mode" = web ]; then
          gh pr view --web
        else
          gh pr view
        fi
      elif [ "$mode" = web ]; then
        gh pr view "$reference" --web
      else
        gh pr view "$reference"
      fi
      ;;
    gitlab:issue)
      require_command glab
      if [ "$mode" = web ]; then
        glab issue view "$reference" --web
      else
        glab issue view "$reference"
      fi
      ;;
    gitlab:pr)
      require_command glab
      if [ "$reference" = . ]; then
        if [ "$mode" = web ]; then
          glab mr view --web
        else
          glab mr view
        fi
      elif [ "$mode" = web ]; then
        glab mr view "$reference" --web
      else
        glab mr view "$reference"
      fi
      ;;
    *)
      die "unsupported forge item kind: $current_forge $item_kind"
      ;;
  esac
}

case "${1:-}" in
  repo | issue | pr)
    item_kind=$1
    shift
    ;;
  -h | --help | help)
    usage
    exit 0
    ;;
  *)
    usage
    exit 2
    ;;
esac

mode=terminal
reference=
task_modifiers=()
unexpected_argument=

while [ "$#" -gt 0 ]; do
  case "$1" in
    -w | --web)
      select_mode web
      ;;
    -t | --task)
      select_mode task
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      task_modifiers+=("$@")
      break
      ;;
    . | [0-9]*)
      [ -z "$reference" ] || die "only one item selector is allowed"
      if [ "$1" != . ] && [[ ! "$1" =~ ^[0-9]+$ ]]; then
        die "item number must be numeric"
      fi
      reference=$1
      ;;
    +?* | -[!-]* | ?*:*)
      task_modifiers+=("$1")
      ;;
    *)
      [ -n "$unexpected_argument" ] || unexpected_argument=$1
      ;;
  esac
  shift
done

if [ "$mode" != task ] && [ "${#task_modifiers[@]}" -gt 0 ]; then
  for modifier in "${task_modifiers[@]}"; do
    case "$modifier" in
      -*) die "unknown option: $modifier" ;;
    esac
  done
fi

if [ -n "$unexpected_argument" ]; then
  case "$unexpected_argument" in
    -*) die "unknown option: $unexpected_argument" ;;
    *) die "unexpected argument: $unexpected_argument" ;;
  esac
fi

if [ "$item_kind" = repo ]; then
  [ -z "$reference" ] || die "repository view does not accept an item selector"
  [ "$mode" != task ] || die "a repository cannot be captured as a task"
  [ "${#task_modifiers[@]}" -eq 0 ] ||
    die "repository view does not accept task modifiers"
elif [ "$reference" = . ] && [ "$item_kind" != pr ]; then
  die ". is only valid for a pull or merge request"
fi

if [ "$mode" = task ]; then
  [ -n "$reference" ] || die "--task requires an item number"
  [ "$reference" != . ] || die "--task requires a numeric item number"
  [ -x "$task_capture" ] || die "task capture helper not found: $task_capture"
  exec "$task_capture" capture "$item_kind" "$reference" \
    "${task_modifiers[@]}"
fi

[ "${#task_modifiers[@]}" -eq 0 ] ||
  die "task modifiers require --task"

detect_current_forge

if [ "$item_kind" = repo ]; then
  view_repo
elif [ -z "$reference" ]; then
  list_items
else
  view_item
fi
