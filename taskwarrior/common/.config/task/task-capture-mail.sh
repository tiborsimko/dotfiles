#!/usr/bin/env bash
#
# Capture a piped RFC822 email as a Taskwarrior task. The Message-ID
# is stored in the `mid` UDA; the description defaults to "From: Subject"
# and is presented for editing with Readline (left/right, backspace, etc. all
# work). Trailing +tag tokens added while editing become Taskwarrior metadata.
# Invoked by neomutt's <pipe-message>task-capture-mail.sh.
set -eu

script_name=${0##*/}
task_command=${TASK_CAPTURE_TASK:-task}
task_capture_tag_re='^[+][[:alpha:]_][^[:space:]]*$'

# Split deliberately appended tags from the end of an edited description. The
# first character must be a letter or underscore so phone numbers, +1 replies,
# and punctuation-led prose remain text; later non-whitespace characters are
# accepted so established tags such as +mm+ continue to work.
task_capture_split_tags() {
  local input=$1 head tag

  task_capture_description=${input%"${input##*[![:space:]]}"}
  task_capture_tags=()

  while [[ "$task_capture_description" =~ ^(.*[^[:space:]])[[:space:]]+([+][^[:space:]]+)$ ]]; do
    head=${BASH_REMATCH[1]}
    tag=${BASH_REMATCH[2]}
    [[ "$tag" =~ $task_capture_tag_re ]] || break
    task_capture_description=$head

    task_capture_tags=("$tag" "${task_capture_tags[@]}")
  done
}

msg=$(cat)
headers=$(printf '%s\n' "$msg" | awk '
  /^$/ { exit }
  /^[ \t]/ { sub(/^[ \t]+/, " "); printf "%s", $0; next }
  NR > 1 { print "" }
  { printf "%s", $0 }
  END { print "" }
')

get_header() {
  printf '%s\n' "$headers" | grep -i "^$1:" | head -1 | sed -E "s/^[^:]+:[[:space:]]*//"
}

decode_mime() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -c '
import sys
from email.header import decode_header, make_header
raw = sys.stdin.read().strip()
try:
    print(str(make_header(decode_header(raw))))
except Exception:
    print(raw)
'
  else
    cat
  fi
}

mid=$(get_header 'Message-ID' | sed -E 's/^<?([^>[:space:]]+)>?.*/\1/')
subject=$(get_header 'Subject' | decode_mime)
from_raw=$(get_header 'From' | decode_mime)

from_name=$(printf '%s' "$from_raw" | sed -E 's/[[:space:]]*<[^>]*>[[:space:]]*$//' | sed -E 's/^"(.*)"$/\1/')
[ -z "$from_name" ] && from_name=$(printf '%s' "$from_raw" | sed -E 's/^<?([^@]+)@.*/\1/')

if [ -z "$mid" ]; then
  echo "$script_name: no Message-ID header found" >&2
  exit 1
fi

default="Reply ${from_name} on ${subject}"

if [ "${TASK_CAPTURE_DESCRIPTION+x}" = x ]; then
  description=$TASK_CAPTURE_DESCRIPTION
else
  read -e -r -i "$default" -p "Description [+tags]: " description < /dev/tty
fi
[ -z "$description" ] && description="$default"

# Do not interpret subject-derived text when the default is accepted unchanged.
if [ "$description" = "$default" ]; then
  task_capture_description=$description
  task_capture_tags=()
else
  task_capture_split_tags "$description"
fi

"$task_command" add +mail "mid:$mid" "${task_capture_tags[@]}" \
  -- "$task_capture_description"
