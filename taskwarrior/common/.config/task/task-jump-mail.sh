#!/bin/sh
#
# Jump to the email referenced by the given Taskwarrior task (looked up
# via the `mid` UDA). Requires a tmux session 'mail' with a 'neomutt'
# window: drives that neomutt via the `,j` macro (which sources a notmuch
# virtual-folder query prepared in ~/.cache/neomutt-jump.rc) and switches
# focus to it.
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

if ! command -v tmux >/dev/null 2>&1 \
   || ! tmux has-session -t mail 2>/dev/null \
   || ! tmux list-windows -t mail -F '#{window_name}' 2>/dev/null | grep -qx neomutt; then
  echo "task-jump-mail.sh: no tmux 'mail' session with a 'neomutt' window — start it first" >&2
  exit 1
fi

# Refresh notmuch so folder moves since the last mbsync are picked up.
notmuch new --quiet >/dev/null 2>&1 || true

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}"
jump_file="$cache_root/neomutt-jump.rc"
printf 'push "<vfolder-from-query>id:%s<enter>"\n' "$mid" > "$jump_file"
tmux send-keys -t mail:neomutt -l ',j'
if [ -n "${TMUX:-}" ]; then
  exec tmux switch-client -t mail
else
  exec tmux attach -t mail
fi
