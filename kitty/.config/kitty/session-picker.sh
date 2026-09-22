#!/bin/bash
#
# Fuzzy pane/session switching and name-first creation for native sessions.

set -euo pipefail

mode=${1:-}
config_dir=${KITTY_CONFIG_DIRECTORY:-$HOME/.config/kitty}
template_dir="$config_dir/sessions"
picker_id=${KITTY_WINDOW_ID:-0}
start_dir=$PWD

die() {
  printf '\n%s\n\nPress any key to close.' "$1" >&2
  IFS= read -r -n 1 _ || true
  exit 1
}

for command_name in awk fzf jq kitten ps; do
  command -v "$command_name" >/dev/null 2>&1 ||
    die "session-picker: missing command: $command_name"
done

kitty_state=$(kitten @ ls) || die "session-picker: cannot query Kitty"

# The picker overlay belongs to the current session and is necessarily its
# newest focused window. Exclude it so selecting the current session returns to
# the pane underneath rather than targeting an overlay that is about to close.
excluded_id=0
if [[ $mode == switch || $mode == new || $mode == pane ]]; then
  excluded_id=$picker_id
fi
session_targets=$(
  jq -r --argjson excluded_id "$excluded_id" '
    [
      .[].tabs[].windows[]
      | select(.session_name != "" and .id != $excluded_id)
    ]
    | group_by(.session_name)[]
    | max_by(.last_focused_at // 0)
    | [.session_name, (.id | tostring)]
    | @tsv
  ' <<< "$kitty_state"
)

focus_session() {
  local name=$1
  local target

  target=$(awk -F '\t' -v name="$name" '$1 == name { print $2; exit }' \
    <<< "$session_targets")
  [[ -n "$target" ]] || return 1
  kitten @ focus-window --match "id:$target"
}

focus_previous_session() {
  local target

  target=$(
    jq -r '
      [.[].tabs[].windows[] | select(.session_name != "")]
      | group_by(.session_name)
      | map(max_by(.last_focused_at // 0))
      | sort_by(.last_focused_at // 0)
      | reverse
      | (.[1].id // empty)
    ' <<< "$kitty_state"
  )
  [[ -n "$target" ]] || exit 0
  kitten @ focus-window --match "id:$target"
}

pick_active_session() {
  local selection status target

  [[ -n "$session_targets" ]] || die "session-picker: no active sessions"
  set +e
  selection=$(
    fzf \
      --sync \
      --height=100% \
      --layout=reverse \
      --border \
      --border-label=' switch session ' \
      --prompt='session> ' \
      --delimiter=$'\t' \
      --nth=1 \
      --with-nth=1 \
      --exact \
      --query='^' \
      --bind='one:accept' \
      < <(printf '%s\n' "$session_targets")
  )
  status=$?
  set -e
  [[ $status -eq 130 || -z "$selection" ]] && exit 0
  [[ $status -eq 0 ]] || exit "$status"

  target=${selection##*$'\t'}
  kitten @ focus-window --match "id:$target"
}

pick_active_pane() {
  local leader_pids pane_targets selection status target

  # Kitty reports every process in the foreground process group, but not its
  # leader. Record all system process-group leaders once so helpers such as a
  # TUI's caffeinate child do not replace the program the user launched.
  leader_pids=$(ps -axo pid=,pgid= | awk '$1 == $2 { print $1 }') ||
    die "session-picker: cannot inspect process groups"

  pane_targets=$(
    jq -r --argjson excluded_id "$excluded_id" --arg leader_pids "$leader_pids" '
      def leaf:
        if . == null or . == "" then "?"
        elif . == "/" then "/"
        else rtrimstr("/") | split("/") | last
        end;

      # Match shell detection and script names in tab_bar.py.
      def process_identity:
        . as $argv
        | ($argv[0] | leaf | sub("^-+"; "")) as $name
        | if (["zsh", "bash", "sh", "dash", "fish"] | index($name)) == null
          then {name: $name, idle: false}
          elif (($argv[1] // "") | length) > 0
               and ($argv[1] | startswith("-") | not)
          then {name: ($argv[1] | leaf), idle: false}
          else {name: $name, idle: all($argv[1:][];
            . == "--login" or . == "-l" or . == "-i")}
          end;

      (reduce ($leader_pids | split("\n")[] | select(length > 0)) as $pid
        ({}; .[$pid] = true)) as $leaders
      |
      .[].tabs[]
      | [.windows[] | select(.id != $excluded_id)] as $windows
      | ($windows | length) as $pane_count
      | $windows
      | to_entries[]
      | .key as $pane_index
      | .value as $window
      | ($window.foreground_processes // []) as $processes
      | ($processes
         | map(select($leaders[(.pid | tostring)]))
         | first // $processes[0]) as $process
      | (($process.cwd // $window.cwd) | leaf) as $cwd
      | (($process.cmdline // [])
         | if length == 0 then ($window.cmdline // []) else . end
         | if length == 0 then [$window.title] else . end
         | process_identity) as $identity
      | $identity.name as $command
      # Neovim publishes its current buffer, which can differ from startup argv.
      | ($window.title // "") as $title
      | [
          ("[" + (if $window.session_name == "" then "unassigned"
                   else $window.session_name end) + "] "
           + $cwd
           + (if $pane_count > 1 then "." + (($pane_index + 1) | tostring)
              else "" end)
           + (if $identity.idle then "" else " @" + $command end)
           + (if $command == "nvim" and $title != "" and $title != "[No Name]"
              then " " + $title else "" end)),
          ($window.id | tostring)
        ]
      | @tsv
    ' <<< "$kitty_state"
  )
  [[ -n "$pane_targets" ]] || die "session-picker: no active panes"

  set +e
  selection=$(
    fzf \
      --sync \
      --height=100% \
      --layout=reverse \
      --border \
      --border-label=' switch pane ' \
      --prompt='pane> ' \
      --delimiter=$'\t' \
      --nth=1 \
      --with-nth=1 \
      < <(printf '%s\n' "$pane_targets")
  )
  status=$?
  set -e
  [[ $status -eq 130 || -z "$selection" ]] && exit 0
  [[ $status -eq 0 ]] || exit "$status"

  target=${selection##*$'\t'}
  kitten @ focus-window --match "id:$target"
}

create_session() {
  local choice status name template template_path template_name predefined_sessions=
  local runtime_root runtime_dir session_file

  # Offer every tracked template while retaining fzf's ability to return a
  # query that does not match any candidate. Globbing keeps the menu ordered.
  for template_path in "$template_dir"/*.kitty-session; do
    [[ -f "$template_path" ]] || continue
    template_name=${template_path##*/}
    predefined_sessions+="${template_name%.kitty-session}"$'\n'
  done

  set +e
  choice=$(
    fzf \
      --sync \
      --height=100% \
      --layout=reverse \
      --border \
      --border-label=' new session ' \
      --prompt='name> ' \
      --header='Enter: open match · Option-Enter: use typed name' \
      --exact \
      --bind='enter:accept-or-print-query,alt-enter:print-query' \
      < <(printf '%s' "$predefined_sessions")
  )
  status=$?
  set -e
  [[ $status -eq 130 ]] && exit 0
  [[ $status -eq 0 ]] || exit "$status"

  name=$choice
  [[ -n "$name" ]] || exit 0
  [[ ${#name} -le 80 && "$name" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] ||
    die "session-picker: use at most 80 letters, digits, dots, dashes or underscores"

  # Treat entering an already active name as a switch instead of duplicating it.
  if focus_session "$name"; then
    exit 0
  fi

  # Exact predefined names load their richer templates. Enter returns an
  # unmatched query, while Option-Enter returns any query even if it is a
  # substring of a menu entry; either can create a minimal custom session.
  template="$template_dir/$name.kitty-session"
  if [[ -f "$template" ]]; then
    kitten @ action goto_session "$template"
    exit 0
  fi

  # Kitty identifies sessions by a session file. Custom sessions get a minimal
  # ephemeral file: they survive for the Kitty process lifetime, but neither
  # pollute the dotfiles nor pretend to provide crash persistence.
  # The cd directive is literal except for Kitty's environment expansion;
  # shell quoting would become part of the path, so reject unsafe input.
  [[ $start_dir != *$'\n'* ]] ||
    die "session-picker: working directory contains a newline"
  [[ $start_dir != *'$'* ]] ||
    die "session-picker: working directory contains a dollar sign"
  runtime_root=${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}
  runtime_dir="${runtime_root%/}/kitty-sessions-${UID:-$(id -u)}"
  umask 077
  mkdir -p "$runtime_dir"
  session_file="$runtime_dir/$name.kitty-session"
  {
    printf 'new_tab\n'
    printf 'cd %s\n' "$start_dir"
    printf 'launch\n'
  } > "$session_file"
  kitten @ action goto_session "$session_file"
}

case "$mode" in
  switch) pick_active_session ;;
  new) create_session ;;
  last) focus_previous_session ;;
  pane) pick_active_pane ;;
  *) die "usage: session-picker.sh switch|new|last|pane" ;;
esac
