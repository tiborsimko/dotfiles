#!/bin/sh
#
# Tiered tmux session switcher with three stages.
#
# Stage 1 (switch):   pick a running session, or + Create new session.
# Stage 2 (template): pick a predefined template, or + Create new custom session.
# Stage 3 (name):     free-form name entry.
#
# All three stages use prefix-anchored matching with one:accept, so any unique
# prefix jumps straight in — including '+' which uniquely picks the sentinel.
# Create is gated behind explicit stages, so a mistyped query in Stage 1 can't
# silently spawn a phantom session.
#
# Usage: switch-session.sh

predefined="blog_reana_io docs_reana_io dotfiles lxplus ntupling mail opendata reana task www_reana_io"

CREATE_LABEL='+ Create new session'
CUSTOM_LABEL='+ Create new custom session'

create_tmux_session() {
  session=$1
  case "$session" in
  blog_reana_io)
    dir=$HOME/Code/github.com/reanahub/blog.reana.io
    tmux new-session -d -c "$dir" -s "$session"
    tmux send-keys -t "$session:1" "wr" Enter
    tmux new-window -t "$session:2" -c "$dir"
    tmux send-keys -t "$session:2" "wr" Enter
    tmux send-keys -t "$session:2" "hugo server -DF" Enter
    tmux select-window -t "$session:1"
    ;;
  docs_reana_io)
    dir=$HOME/Code/github.com/reanahub/docs.reana.io
    tmux new-session -d -c "$dir" -s "$session"
    tmux send-keys -t "$session:1" "wr" Enter
    tmux new-window -t "$session:2" -c "$dir"
    tmux send-keys -t "$session:2" "workon docs.reana.io" Enter
    tmux send-keys -t "$session:2" "mkdocs serve" Enter
    tmux select-window -t "$session:1"
    ;;
  dotfiles)
    dir=$HOME/Code/github.com/tiborsimko/dotfiles
    tmux new-session -d -c "$dir" -s "$session"
    ;;
  ntupling)
    dir=$HOME/Code/gitlab.cern.ch/cernopendata/lhcb-ntupling-service-frontend
    tmux new-session -d -c "$dir" -s "$session"
    tmux new-window -t "$session:2" -c "$dir/../lhcb-ntupling-service-backend"
    tmux new-window -t "$session:3" -c "$dir/../lhcb-ntupling-service-devops"
    tmux select-window -t "$session:1"
    ;;
  mail)
    dir=$HOME
    tmux new-session -d -c "$dir" -s "$session"
    tmux send-keys -t "$session:1" "neomutt" Enter
    tmux new-window -t "$session:2" -c "$dir"
    tmux send-keys -t "$session:2" "while true; do echo \"==> \$(date)\" && mail-sync inbox archive && echo \"<== \$(date)\" && sleep 300; done" Enter
    tmux select-window -t "$session:1"
    ;;
  opendata)
    dir=$HOME/Code/github.com/cernopendata/opendata.cern.ch
    tmux new-session -d -c "$dir" -s "$session"
    tmux new-window -t "$session:2" -c "$dir/../data-curation"
    ;;
  reana)
    dir=$HOME/Code/github.com/reanahub/reana
    tmux new-session -d -c "$dir" -s "$session"
    tmux send-keys -t "$session:1" "wr" Enter
    tmux new-window -t "$session:2" -c "$dir/../reana-demo-root6-roofit"
    tmux send-keys -t "$session:2" "wr" Enter
    tmux select-window -t "$session:1"
    ;;
  task)
    dir=$HOME
    tmux new-session -d -c "$dir" -s "$session"
    tmux send-keys -t "$session:1" "tasksh" Enter
    ;;
  www_reana_io)
    dir=$HOME/Code/github.com/reanahub/www.reana.io
    tmux new-session -d -c "$dir" -s "$session"
    tmux send-keys -t "$session:1" "wr" Enter
    tmux new-window -t "$session:2" -c "$dir"
    tmux send-keys -t "$session:2" "wr" Enter
    tmux select-window -t "$session:1"
    ;;
  *)
    tmux new-session -d -s "$session"
    ;;
  esac
}

attach_or_switch() {
  if [ -z "$TMUX" ]; then
    tmux attach-session -dt "$1"
  else
    tmux switch-client -t "$1"
  fi
}

# fzf 0.39+ supports the `one` event (auto-accept on unique match);
# older versions (e.g. Debian 12's 0.38) error out, so fall back to
# Enter-to-accept there.
fzf_ver=$(fzf --version 2>/dev/null | head -n1 | awk '{print $1}')
set --
case "$fzf_ver" in
  0.39*|0.[4-9][0-9]*|[1-9]*) set -- --bind one:accept ;;
esac

# ---- Stage 1: pick a running session, or open the create flow ----
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

# ---- Stage 2: pick a predefined template, or open the custom-name prompt ----
templates=$(
  for s in $predefined; do
    if ! tmux has-session -t "=$s" 2>/dev/null; then
      printf '%s\n' "$s"
    fi
  done
)
list=$(printf '%s\n%s\n' "$templates" "$CUSTOM_LABEL")

selection=$(
  printf '%s\n' "$list" |
    fzf-tmux -p 80%,70% \
      --prompt 'create> ' \
      --border-label ' create session ' \
      --exact \
      --query '^' \
      "$@"
)
[ $? -eq 130 ] && exit 0
[ -z "$selection" ] && exit 0

if [ "$selection" != "$CUSTOM_LABEL" ]; then
  session_name="$selection"
else
  # ---- Stage 3: free-form name ----
  session_name=$(
    fzf-tmux -p 60%,5 \
      --prompt 'name> ' \
      --border-label ' new session ' \
      --print-query \
      --no-info \
      </dev/null |
      sed -n '1p'
  )
  [ -z "$session_name" ] && exit 0
fi

if ! tmux has-session -t "=$session_name" 2>/dev/null; then
  create_tmux_session "$session_name"
fi
attach_or_switch "$session_name"
