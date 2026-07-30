#!/bin/sh
#
# Jump to the most recently active window carrying a tmux alert, even when it
# belongs to another session. A pane ID lets switch-client select the session,
# window, and active pane in one step.

target=$(
  tmux list-windows -a \
    -f '#{||:#{window_bell_flag},#{||:#{window_activity_flag},#{window_silence_flag}}}' \
    -F '#{window_activity} #{pane_id}' |
    awk 'NR == 1 || $1 > max { max = $1; id = $2 } END { print id }'
)

if [ -z "$target" ]; then
  tmux display-message 'No urgent windows'
  exit 0
fi

tmux switch-client -t "$target"
