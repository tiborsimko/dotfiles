#!/bin/sh
#
# Pick a pane by session, command, or directory.

if ! command -v fzf >/dev/null 2>&1 || ! command -v fzf-tmux >/dev/null 2>&1; then
  exec tmux choose-tree -Z
fi

selection=$(
  tmux list-panes -a \
    -F '#{pane_id} [#{session_name}]#{?#{==:#{window_name},#{b:pane_current_path}},,#{?#{==:#{window_name},#{pane_current_command}},, #{window_name}}} #{b:pane_current_path}#{?#{==:#{window_panes},1},,.#{pane_index}}#{?#{s/zsh//:pane_current_command}, @#{pane_current_command},}' |
  fzf-tmux -p 80%,70% \
    --with-nth=2.. \
    --prompt 'pane> ' \
    --border-label ' panes '
)
[ -z "$selection" ] && exit 0

pane_id=$(printf '%s' "$selection" | awk '{print $1}')
tmux switch-client -t "$pane_id"
