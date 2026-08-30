#!/usr/bin/env bash
#
# Capture the macOS clipboard as a Taskwarrior task. Invoked by AeroSpace's
# Alt-t binding. Capture is deliberately offline and untagged; metadata can be
# completed during review.
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

script_name=${0##*/}
pbpaste_command=${TASK_CAPTURE_PBPASTE:-pbpaste}
task_command=${TASK_CAPTURE_TASK:-task}
osascript_command=${TASK_CAPTURE_OSASCRIPT:-osascript}
python_command=${TASK_CAPTURE_PYTHON:-python3}
description_limit=120
canonical_uuid_re='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

notify() {
  local title=$1
  local body=$2

  [ "${TASK_CAPTURE_NOTIFY:-1}" = 1 ] || return 0
  command -v "$osascript_command" >/dev/null 2>&1 || return 0

  "$osascript_command" - "$title" "$body" <<'APPLESCRIPT' \
    >/dev/null 2>&1 || true
on run argv
  set notification_title to item 1 of argv
  set notification_body to item 2 of argv
  display notification notification_body with title notification_title
end run
APPLESCRIPT
}

if [ "$#" -ne 0 ]; then
  echo "Usage: $script_name" >&2
  exit 2
fi

if ! command -v "$pbpaste_command" >/dev/null 2>&1; then
  echo "$script_name: clipboard reader not found: $pbpaste_command" >&2
  exit 1
fi

if ! command -v "$task_command" >/dev/null 2>&1; then
  notify "Taskwarrior capture failed" "The task command was not found."
  echo "$script_name: task command not found: $task_command" >&2
  exit 1
fi

if ! clipboard=$("$pbpaste_command"); then
  notify "Taskwarrior capture failed" "The clipboard could not be read."
  echo "$script_name: could not read the clipboard" >&2
  exit 1
fi

# Treat CR, LF, blank lines, and repeated horizontal whitespace uniformly.
# A copied URL has none of these internally, so it remains byte-for-byte intact
# apart from deliberately trimmed surrounding whitespace.
full_text=$(
  printf '%s' "$clipboard" |
    tr '\r' '\n' |
    awk '
      {
        gsub(/^[[:space:]]+/, "")
        gsub(/[[:space:]]+$/, "")
        gsub(/[[:space:]]+/, " ")
        if (length($0)) {
          if (length(output)) output = output " "
          output = output $0
        }
      }
      END { print output }
    '
)

if [ -z "$full_text" ]; then
  notify "Nothing captured" "The clipboard contains no text."
  echo "$script_name: clipboard contains no text" >&2
  exit 1
fi

# Keep complete URLs visible and directly openable. For other long text, use a
# compact summary in reports and preserve the complete normalized text as an
# annotation.
description=$full_text
annotation=
if [[ ! "$full_text" =~ ^https?://[^[:space:]]+$ ]] &&
  command -v "$python_command" >/dev/null 2>&1; then
  if description=$(
    printf '%s' "$full_text" |
      "$python_command" -c '
import sys

text = sys.stdin.read()
limit = int(sys.argv[1])

if len(text) <= limit:
    sys.stdout.write(text)
else:
    summary = text[:limit]
    if not text[limit].isspace() and not summary[-1].isspace():
        words = summary.rsplit(maxsplit=1)
        if len(words) == 2:
            summary = words[0]
    sys.stdout.write(summary.rstrip() + "…")
' "$description_limit"
  ); then
    if [ "$description" != "$full_text" ]; then
      annotation=$full_text
    fi
  else
    # Capture must still succeed when optional summarization fails.
    description=$full_text
  fi
fi

if [ -z "$annotation" ]; then
  if ! "$task_command" add -- "$description" >/dev/null; then
    notify "Taskwarrior capture failed" "The task could not be created."
    echo "$script_name: task creation failed" >&2
    exit 1
  fi
else
  if ! raw=$("$task_command" rc.verbose=new-uuid add -- "$description"); then
    notify "Taskwarrior capture failed" "The task could not be created."
    echo "$script_name: task creation failed" >&2
    exit 1
  fi

  uuid=$(
    printf '%s\n' "$raw" |
      sed -n 's/^Created task \([0-9a-f]\{8\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}-[0-9a-f]\{12\}\)\.$/\1/p'
  )

  if [[ ! "$uuid" =~ $canonical_uuid_re ]]; then
    notify "Taskwarrior capture incomplete" \
      "A task may have been created, but its UUID could not be parsed."
    echo "$script_name: task may have been created, but its UUID could not be parsed; do not retry automatically (output: $raw)" >&2
    exit 1
  fi

  if ! "$task_command" "$uuid" annotate -- "$annotation" >/dev/null; then
    notify "Taskwarrior capture incomplete" \
      "Task $uuid was created without its full-text annotation."
    echo "$script_name: task $uuid was created, but annotation failed; do not retry capture" >&2
    exit 1
  fi
fi

notify "Taskwarrior task captured" "$description"
