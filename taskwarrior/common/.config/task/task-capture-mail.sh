#!/usr/bin/env bash
#
# Capture a piped RFC822 email as a Taskwarrior task. The Message-ID
# is stored in the `mid` UDA; the description defaults to "From: Subject"
# and is presented for editing with Readline (left/right, backspace,
# etc. all work). Invoked by neomutt's <pipe-message>task-capture-mail.sh.
set -eu

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
  echo "task-capture-mail.sh: no Message-ID header found" >&2
  exit 1
fi

default="Reply ${from_name} on ${subject}"

read -e -r -i "$default" -p "Description: " description < /dev/tty
[ -z "$description" ] && description="$default"

task add +mail mid:"$mid" -- "$description"
