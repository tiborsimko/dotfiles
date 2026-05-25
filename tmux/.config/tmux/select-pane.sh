#!/bin/sh
#
# Fuzzy pane switcher across all tmux sessions. Lists every pane with its
# running command and directory; if no pane matches the typed query, creates
# a new session with that query as name.
#
# Usage: select-pane.sh

output=$(
  tmux list-panes -a \
    -F '#{pane_id} [#{session_name}]#{?#{==:#{window_name},#{b:pane_current_path}},,#{?#{==:#{window_name},#{pane_current_command}},, #{window_name}}} #{b:pane_current_path}#{?#{==:#{window_panes},1},,.#{pane_index}}#{?#{s/zsh//:pane_current_command}, @#{pane_current_command},}' |
  fzf-tmux -p 80%,70% \
    --with-nth=2.. \
    --prompt 'pane> ' \
    --border-label ' panes ' \
    --print-query
)
exit_code=$?

# Escape/Ctrl-C — do nothing
[ $exit_code -eq 130 ] && exit 0

query=$(printf '%s\n' "$output" | sed -n '1p')
selection=$(printf '%s\n' "$output" | sed -n '2p')

if [ -n "$selection" ]; then
  # Pane selected — switch to it
  pane_id=$(printf '%s' "$selection" | awk '{print $1}')
  tmux switch-client -t "$pane_id"
elif [ -n "$query" ]; then
  # No match — create new session with query as name
  if ! tmux has-session -t "=$query" 2>/dev/null; then
    tmux new-session -d -s "$query"
  fi
  tmux switch-client -t "$query"
fi

exit 0
