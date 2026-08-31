#!/usr/bin/env bash

# Exercise NeoMutt Taskwarrior capture syntax without mutating task data.
set -euo pipefail

test_dir=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
dotfiles_dir=$(dirname -- "$test_dir")
mail_script="$dotfiles_dir/taskwarrior/common/.config/task/task-capture-mail.sh"

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

capture_mail() {
  local description=$1
  local subject=${2:-Release planning}

  printf '%s\n' \
    'From: Alice Example <alice@example.org>' \
    "Subject: $subject" \
    'Message-ID: <capture-123@example.org>' \
    '' \
    'Message body' |
    TASK_CAPTURE_DESCRIPTION="$description" \
      TASK_CAPTURE_TASK=/bin/echo \
      "$mail_script"
}

mail_output=$(capture_mail 'Reply Alice on release planning +reana +focus')
assert_equal \
  'add +mail mid:capture-123@example.org +reana +focus -- Reply Alice on release planning' \
  "$mail_output" "mail capture with multiple tags"

mail_output=$(capture_mail 'Reply Anna +mm+')
assert_equal \
  'add +mail mid:capture-123@example.org +mm+ -- Reply Anna' \
  "$mail_output" "mail capture with punctuation after the tag name"

mail_output=$(capture_mail '+focus')
assert_equal \
  'add +mail mid:capture-123@example.org -- +focus' \
  "$mail_output" "mail capture requiring a nonempty description"

mail_output=$(capture_mail 'Reply Alice +focus   ')
assert_equal \
  'add +mail mid:capture-123@example.org +focus -- Reply Alice' \
  "$mail_output" "mail capture trimming whitespace before splitting tags"

for description in \
  'Call Bob at +41791234567' \
  'Sounds good to me +1' \
  'Ship the release ++urgent' \
  'Keep this literal +.hidden' \
  'Keep this literal +-x' \
  'Use +focus during review'; do
  mail_output=$(capture_mail "$description")
  assert_equal \
    "add +mail mid:capture-123@example.org -- $description" \
    "$mail_output" "mail capture preserving $description"
done

default='Reply Alice Example on Staffing +urgent'
mail_output=$(capture_mail "$default" 'Staffing +urgent')
assert_equal \
  "add +mail mid:capture-123@example.org -- $default" \
  "$mail_output" "mail capture preserving an unchanged default"

echo "Task capture syntax: OK"
