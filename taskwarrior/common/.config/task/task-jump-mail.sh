#!/bin/sh
#
# Jump to the email referenced by the given Taskwarrior task (looked up via the
# `mid` UDA). Requires Kitty's 'mail' session with a window tagged
# role=neomutt. The `,j` macro sources the Notmuch virtual-folder query prepared
# in ~/.cache/neomutt-jump.rc; Kitty then switches to that window and session.
set -eu

if [ $# -ne 1 ]; then
  echo "Usage: task-jump-mail.sh <task-id-or-uuid>" >&2
  exit 2
fi

mid=$(task _get "$1.mid" 2>/dev/null || true)

if [ -z "$mid" ]; then
  echo "task-jump-mail.sh: task $1 has no mid attribute" >&2
  exit 1
fi

if ! command -v kitten >/dev/null 2>&1 || [ -z "${KITTY_LISTEN_ON:-}" ]; then
  echo "task-jump-mail.sh: not running inside the local Kitty instance" >&2
  exit 1
fi

kitty_match='session:^mail$ and var:role=neomutt'
if ! kitten @ get-text --match "$kitty_match" --extent screen >/dev/null 2>&1; then
  echo "task-jump-mail.sh: no Kitty 'mail' session with a role=neomutt window — start it first" >&2
  exit 1
fi

# Refresh Notmuch so folder moves since the last mbsync are picked up.
notmuch new --quiet >/dev/null 2>&1 || true

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}"
jump_file="$cache_root/neomutt-jump.rc"
printf 'push "<vfolder-from-query>id:%s<enter>"\n' "$mid" > "$jump_file"
kitten @ send-text --match "$kitty_match" ',j'
exec kitten @ focus-window --match "$kitty_match"
