#!/usr/bin/env bash
#
# Keep the dominant stat view as the default behind `git l`, while allowing
# explicit output-format options to replace it.
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

default_stat=true
for arg in "$@"; do
  case "$arg" in
    --)
      break
      ;;
    -p | --patch | --oneline | --pretty* | --format=* | --shortstat)
      default_stat=false
      break
      ;;
  esac
done

if [ "$default_stat" = true ]; then
  git log master.. --stat "$@"
else
  git log master.. "$@"
fi
