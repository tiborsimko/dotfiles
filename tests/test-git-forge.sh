#!/usr/bin/env bash

# Exercise the forge-neutral Git shortcuts without network access or mutations.
set -euo pipefail

test_dir=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
dotfiles_dir=$(dirname -- "$test_dir")
forge_script="$dotfiles_dir/git/.config/git/git-forge.sh"
forge_common="$dotfiles_dir/git/.config/git/git-forge-common.sh"
capture_script="$dotfiles_dir/taskwarrior/common/.config/task/task-capture-git.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_equal() {
  local expected=$1
  local actual=$2
  local label=$3

  [ "$actual" = "$expected" ] ||
    fail "$label: expected '$expected', got '$actual'"
}

run_dispatch() {
  local remote_url=$1
  shift

  # The single-quoted program is evaluated by the child Bash process.
  # shellcheck disable=SC2016
  REMOTE_URL="$remote_url" GIT_FORGE_COMMON="$forge_common" \
    SCRIPT="$forge_script" "$BASH" -c '
      git() {
        [ "$#" -eq 3 ] && [ "$1 $2 $3" = "remote get-url origin" ] ||
          return 1
        printf "%s\n" "$REMOTE_URL"
      }
      gh() { printf "gh:%s\n" "$*"; }
      glab() { printf "glab:%s\n" "$*"; }
      open() { printf "open:%s\n" "$*"; }
      # shellcheck disable=SC1090
      source "$SCRIPT"
    ' forge-test "$@"
}

assert_dispatch() {
  local expected=$1
  local remote_url=$2
  shift 2
  local actual

  actual=$(run_dispatch "$remote_url" "$@")
  assert_equal "$expected" "$actual" "git forge $*"
}

assert_rejected() {
  local expected=$1
  shift
  local actual status

  set +e
  actual=$(
    GIT_FORGE_COMMON="$forge_common" "$BASH" "$forge_script" "$@" 2>&1
  )
  status=$?
  set -e

  [ "$status" -ne 0 ] || fail "git forge $* unexpectedly succeeded"
  case "$actual" in
    *"$expected"*) ;;
    *) fail "git forge $*: expected error containing '$expected', got '$actual'" ;;
  esac
}

github_remote=git@github.com:owner/project.git
gitlab_remote=git@gitlab.cern.ch:group/subgroup/project.git

assert_dispatch "gh:repo view" "$github_remote" repo
assert_dispatch "gh:repo view --web" "$github_remote" repo -w
assert_dispatch "gh:issue list" "$github_remote" issue
assert_dispatch "gh:issue view 123" "$github_remote" issue 123
assert_dispatch "gh:issue view 123 --web" "$github_remote" issue 123 -w
assert_dispatch "gh:pr list --web" "$github_remote" pr --web
assert_dispatch "gh:pr view" "$github_remote" pr .
assert_dispatch "gh:pr view --web" "$github_remote" pr . -w

assert_dispatch \
  "open:https://gitlab.cern.ch/group/subgroup/project/-/issues" \
  "$gitlab_remote" issue -w
assert_dispatch \
  "open:https://gitlab.cern.ch/group/subgroup/project/-/merge_requests" \
  "$gitlab_remote" pr -w
assert_dispatch "glab:issue view 42" "$gitlab_remote" issue 42
assert_dispatch "glab:mr view" "$gitlab_remote" pr .
assert_dispatch "glab:repo view --web" "$gitlab_remote" repo -w

task_output=$(
  GIT_FORGE_COMMON="$forge_common" TASK_CAPTURE_GIT=/bin/echo \
    "$BASH" "$forge_script" issue 123 -t
)
assert_equal "capture issue 123" "$task_output" \
  "task capture without modifiers"

task_output=$(
  GIT_FORGE_COMMON="$forge_common" TASK_CAPTURE_GIT=/bin/echo \
    "$BASH" "$forge_script" issue 123 -t +focus project:DOTFILES
)
assert_equal "capture issue 123 +focus project:DOTFILES" "$task_output" \
  "task capture with modifiers"

assert_rejected "--task requires an item number" issue -t
assert_rejected "--web and --task are mutually exclusive" issue 123 -w -t
assert_rejected ". is only valid for a pull or merge request" issue .
assert_rejected "--task requires a numeric item number" pr . -t
assert_rejected "repository view does not accept an item selector" repo 123
assert_rejected "only one item selector is allowed" issue 1 2
assert_rejected "task modifiers require --task" issue 123 +focus
assert_rejected "unknown option: -a" issue -a @me
assert_rejected "unknown option: --state" issue --state closed

capture_output=$(
  # The single-quoted program is evaluated by the child Bash process.
  # shellcheck disable=SC2016
  REMOTE_URL="$github_remote" GIT_FORGE_COMMON="$forge_common" \
    SCRIPT="$capture_script" UUID=12345678-1234-1234-1234-123456789abc \
    "$BASH" -c '
      git() {
        [ "$#" -eq 3 ] && [ "$1 $2 $3" = "remote get-url origin" ] ||
          return 1
        printf "%s\n" "$REMOTE_URL"
      }
      gh() {
        [ "$1 $2 $3" = "issue view 123" ] || return 1
        printf "123\tImprove aliases\tOPEN\thttps://github.com/owner/project/issues/123\n"
      }
      task() {
        if [ "$1" = rc.verbose=new-uuid ] && [ "$2" = add ]; then
          [ "$#" -eq 6 ] && [ "$3" = +focus ] &&
            [ "$4" = project:DOTFILES ] && [ "$5" = -- ] &&
            [ "$6" = "project#123 — Improve aliases" ] || return 1
          printf "Created task %s.\n" "$UUID"
        else
          [ "$1 $2 $3 $4" = "$UUID annotate -- https://github.com/owner/project/issues/123" ]
        fi
      }
      # shellcheck disable=SC1090
      source "$SCRIPT"
    ' capture-test capture issue 123 +focus project:DOTFILES
)
assert_equal \
  "Captured 12345678-1234-1234-1234-123456789abc (OPEN): project#123 — Improve aliases" \
  "$capture_output" "GitHub Taskwarrior capture"

echo "Git forge shortcuts: OK"
