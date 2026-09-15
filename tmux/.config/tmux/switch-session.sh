#!/bin/sh
#
# Pick a running session or explicitly create a named session.

if ! command -v fzf >/dev/null 2>&1 || ! command -v fzf-tmux >/dev/null 2>&1; then
  exec tmux choose-tree -Zs
fi

CREATE_LABEL='+ Create new session'

attach_or_switch() {
  if [ -z "${TMUX:-}" ]; then
    tmux attach-session -t "=$1:"
  else
    tmux switch-client -t "=$1:"
  fi
}

# Fzf 0.39+ supports the `one` event (auto-accept on unique match);
# older versions (e.g. Debian 12's 0.38) error out, so fall back to
# Enter-to-accept there.
fzf_ver=$(fzf --version 2>/dev/null | head -n1 | awk '{print $1}')
set --
case "$fzf_ver" in
  0.39*|0.[4-9][0-9]*|[1-9]*) set -- --bind one:accept ;;
esac

# Pick a session; creation requires choosing the explicit entry.
running=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)
list=$(printf '%s\n%s\n' "$running" "$CREATE_LABEL")

selection=$(
  printf '%s\n' "$list" |
    fzf-tmux -p 80%,70% \
      --prompt 'session> ' \
      --border-label ' switch session ' \
      --exact \
      --query '^' \
      "$@"
)
[ $? -eq 130 ] && exit 0
[ -z "$selection" ] && exit 0

if [ "$selection" != "$CREATE_LABEL" ]; then
  attach_or_switch "$selection"
  exit 0
fi

# Enter a session name.
session_name=$(
  fzf-tmux -p 60%,5 \
    --prompt 'name> ' \
    --border-label ' new session ' \
    --print-query \
    --no-info \
    </dev/null
)
exit_code=$?
[ "$exit_code" -eq 130 ] && exit 0
session_name=$(printf '%s\n' "$session_name" | sed -n '1p')
[ -z "$session_name" ] && exit 0
case "$session_name" in
  *:*)
    printf '%s\n' 'Session names cannot contain a colon'
    exit 1
    ;;
esac

if ! tmux has-session -t "=$session_name" 2>/dev/null; then
  cwd=$(tmux display-message -p '#{pane_current_path}')
  session_name=$(tmux new-session -d -P -F '#{session_name}' -c "$cwd" -s "$session_name") || exit 1
fi
attach_or_switch "$session_name"
