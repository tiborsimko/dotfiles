#!/usr/bin/env bash
#
# Fetch the authoritative fork remotes by default while preserving native
# `git fetch` argument handling.
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

if [ "$#" -gt 0 ]; then
  git fetch "$@"
  exit
fi

has_upstream=false
has_origin=false
git config --get remote.upstream.url >/dev/null 2>&1 && has_upstream=true
git config --get remote.origin.url >/dev/null 2>&1 && has_origin=true

case "$has_upstream:$has_origin" in
  true:true)
    git fetch --multiple upstream origin
    ;;
  true:false)
    git fetch upstream
    ;;
  false:true)
    git fetch origin
    ;;
  false:false)
    git fetch
    ;;
esac
