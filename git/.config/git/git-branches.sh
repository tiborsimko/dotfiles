#!/usr/bin/env bash
#
# List recently updated local or remote branches behind `git b`.
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

script_name=${0##*/}
remote=false
selector=

usage() {
  cat >&2 <<EOF
Usage:
  git b [filter]
  git b -r|--remote [remote]

List local branches by commit date, optionally filtering their names. Use
--remote to list all remote-tracking branches or those belonging to one remote.
EOF
}

die() {
  echo "$script_name: $*" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -r | --remote)
      remote=true
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      [ -z "$selector" ] || die "only one filter or remote is allowed"
      selector=$1
      ;;
  esac
  shift
done

if [ "$remote" = true ]; then
  ref_pattern=refs/remotes
  [ -z "$selector" ] || ref_pattern="$ref_pattern/$selector"
else
  ref_pattern=refs/heads
  [ -z "$selector" ] || ref_pattern="$ref_pattern/*$selector*"
fi

git for-each-ref \
  --format='%(committerdate:short) %(refname)' \
  --sort=committerdate "$ref_pattern"
