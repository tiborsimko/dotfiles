#!/bin/sh
#
# Jump to the email referenced by the given Taskwarrior task (looked up
# via the `mid` UDA). Requires a tmux session 'mutt' with a 'neomutt'
# window: drives that neomutt via the `,j` macro (which sources a notmuch
# virtual-folder query prepared in ~/.cache/neomutt-jump.rc) and switches
# focus to it.
set -eu

if [ $# -ne 1 ]; then
  echo "Usage: task-mail-jump.sh <task-id-or-uuid>" >&2
  exit 2
fi

mid=$(task _get "$1.mid" 2>/dev/null || true)

if [ -z "$mid" ]; then
  echo "task-mail-jump.sh: task $1 has no mid attribute" >&2
  exit 1
fi

if ! command -v tmux >/dev/null 2>&1 \
   || ! tmux has-session -t mutt 2>/dev/null \
   || ! tmux list-windows -t mutt -F '#{window_name}' 2>/dev/null | grep -qx neomutt; then
  echo "task-mail-jump.sh: no tmux 'mutt' session with a 'neomutt' window — start it first" >&2
  exit 1
fi

# Refresh notmuch so folder moves since the last mbsync are picked up.
notmuch new --quiet >/dev/null 2>&1 || true

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}"
jump_file="$cache_root/neomutt-jump.rc"
printf 'push "<vfolder-from-query>id:%s<enter>"\n' "$mid" > "$jump_file"
tmux send-keys -t mutt:neomutt -l ',j'
if [ -n "${TMUX:-}" ]; then
  exec tmux switch-client -t mutt
else
  exec tmux attach -t mutt
fi
