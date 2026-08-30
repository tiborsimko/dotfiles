#!/usr/bin/env bash
#
# Dispatch explicit, multi-step Git workflows behind `git x`.
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

script_name='git x'

usage() {
  cat >&2 <<EOF
Usage:
  git x land-branch <branch>
  git x land-pr <number>

Fast-forward master through a local branch or upstream pull-request ref, push
the result, and delete the corresponding local branch. land-branch also deletes
the origin branch.
EOF
}

die() {
  echo "$script_name: $*" >&2
  exit 1
}

require_arguments() {
  local expected=$1
  shift
  [ "$#" -eq "$expected" ] || {
    usage
    exit 2
  }
}

land_branch() {
  require_arguments 1 "$@"
  local branch=$1

  git check-ref-format --branch "$branch" >/dev/null 2>&1 ||
    die "invalid branch name: $branch"
  [ "$branch" != master ] || die "refusing to land master into itself"

  git fetch upstream
  git fetch origin
  git checkout master
  git merge --ff-only upstream/master
  git merge --ff-only "$branch"
  git branch -d "$branch"
  git push upstream master
  git push origin master
  git push origin --delete "$branch"
}

land_pr() {
  require_arguments 1 "$@"
  local number=$1

  [[ "$number" =~ ^[0-9]+$ ]] || die "pull-request number must be numeric"

  git fetch upstream
  git checkout master
  git merge --ff-only upstream/master
  git merge --ff-only "upstream/pr/$number"
  git branch -d "pr-$number"
  git push upstream master
  git push origin master
}

case "${1:-}" in
  land-branch)
    shift
    land_branch "$@"
    ;;
  land-pr)
    shift
    land_pr "$@"
    ;;
  -h | --help | help)
    usage
    ;;
  *)
    usage
    exit 2
    ;;
esac
