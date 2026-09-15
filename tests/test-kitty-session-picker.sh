#!/usr/bin/env bash

# Test picker logic using recorded sessions and stubbed commands.
set -euo pipefail

dotfiles_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
picker="$dotfiles_dir/kitty/.config/kitty/session-picker.sh"
test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT

fake_bin="$test_dir/bin"
config_dir="$test_dir/config"
runtime_dir="$test_dir/runtime"
project_dir="$test_dir/project dir"
mkdir -p "$fake_bin" "$config_dir/sessions" "$runtime_dir" "$project_dir"

cat > "$fake_bin/fzf" <<'EOF'
#!/bin/bash
printf '%s\n' "$@" > "$FZF_ARGS_FILE"
cat > "$FZF_INPUT_FILE"
printf '%s\n' "$FZF_OUTPUT"
exit "${FZF_STATUS:-0}"
EOF

cat > "$fake_bin/kitten" <<'EOF'
#!/bin/bash
if [[ $* == '@ ls' ]]; then
  cat "$KITTY_TEST_STATE_FILE"
else
  printf '%s\n' "$*" >> "$KITTY_ACTIONS_FILE"
fi
EOF

cat > "$fake_bin/ps" <<'EOF'
#!/bin/bash
cat <<'PROCESS_TABLE'
  PID  PGID
   10    10
   20    20
   30    30
   31    30
   99    99
PROCESS_TABLE
EOF
chmod +x "$fake_bin/fzf" "$fake_bin/kitten" "$fake_bin/ps"

state_file="$test_dir/state.json"
cat > "$state_file" <<'EOF'
[
  {
    "tabs": [
      {
        "windows": [
          {
            "id": 1,
            "session_name": "dotfiles",
            "last_focused_at": 10,
            "cwd": "/Users/test",
            "cmdline": ["/bin/zsh", "--login"],
            "title": "dotfiles",
            "foreground_processes": [
              {"pid": 10, "cwd": "/Users/test/Code/dotfiles", "cmdline": ["-zsh", "--login"]}
            ]
          },
          {
            "id": 99,
            "session_name": "dotfiles",
            "last_focused_at": 99,
            "cwd": "/Users/test/Code/dotfiles",
            "cmdline": ["fzf"],
            "title": "pane picker",
            "foreground_processes": []
          }
        ]
      },
      {
        "windows": [
          {
            "id": 41,
            "session_name": "reana",
            "last_focused_at": 20,
            "cwd": "/Users/test",
            "cmdline": ["/bin/zsh", "--login"],
            "title": "results.py",
            "foreground_processes": [
              {"pid": 20, "cwd": "/Users/test/Code/reana", "cmdline": ["/opt/homebrew/bin/nvim", "analysis.py"]}
            ]
          },
          {
            "id": 42,
            "session_name": "reana",
            "last_focused_at": 30,
            "cwd": "/Users/test",
            "cmdline": ["/bin/zsh", "--login"],
            "title": "pytest tests --verbose",
            "foreground_processes": [
              {"pid": 31, "cwd": "/Users/test/Code/reana", "cmdline": ["/opt/homebrew/bin/pytest", "tests", "--verbose"]},
              {"pid": 30, "cwd": "/Users/test/Code/reana", "cmdline": ["/opt/homebrew/bin/python"]}
            ]
          }
        ]
      }
    ]
  }
]
EOF

actions_file="$test_dir/actions"
fzf_args_file="$test_dir/fzf-args"
fzf_input_file="$test_dir/fzf-input"
touch "$actions_file" "$fzf_args_file" "$fzf_input_file"

run_picker() {
  local mode=$1 output=$2
  local working_dir=${3:-$project_dir}

  (
    cd "$working_dir"
    env \
      PATH="$fake_bin:/usr/bin:/bin" \
      HOME="$test_dir/home" \
      XDG_RUNTIME_DIR="$runtime_dir" \
      KITTY_CONFIG_DIRECTORY="$config_dir" \
      KITTY_WINDOW_ID=99 \
      KITTY_TEST_STATE_FILE="$state_file" \
      KITTY_ACTIONS_FILE="$actions_file" \
      FZF_ARGS_FILE="$fzf_args_file" \
      FZF_INPUT_FILE="$fzf_input_file" \
      FZF_OUTPUT="$output" \
      "$picker" "$mode" < /dev/null
  )
}

assert_equal() {
  local actual=$1 expected=$2 message=$3

  if [[ $actual != "$expected" ]]; then
    printf 'FAIL: %s\nexpected: %q\nactual:   %q\n' \
      "$message" "$expected" "$actual" >&2
    exit 1
  fi
}

# Cmd-P targets the last-used real pane and never the short-lived picker overlay.
run_picker switch $'reana\t42'
assert_equal "$(cat "$fzf_input_file")" $'dotfiles\t1\nreana\t42' \
  "active session targets"
assert_equal "$(cat "$actions_file")" '@ focus-window --match id:42' \
  "session focus action"
grep -Fqx -- '--bind=one:accept' "$fzf_args_file"
grep -Fqx -- '--query=^' "$fzf_args_file"

# Cmd-G lists every real pane across sessions, labels split siblings, uses the
# foreground process-group leader, and excludes its own overlay window.
# The leader is deliberately not the first foreground process in the fixture.
# Neovim has switched buffers since launch, so its title differs from argv.
: > "$actions_file"
run_picker pane $'[reana] reana.2 @python\t42'
assert_equal "$(cat "$fzf_input_file")" \
  $'[dotfiles] dotfiles\t1\n[reana] reana.1 @nvim results.py\t41\n[reana] reana.2 @python\t42' \
  "active pane targets"
assert_equal "$(cat "$actions_file")" '@ focus-window --match id:42' \
  "pane focus action"
grep -Fqx -- '--nth=1' "$fzf_args_file"
grep -Fqx -- '--with-nth=1' "$fzf_args_file"

# Cmd-N offers predefined sessions while still accepting an arbitrary name and
# generating a minimal session in runtime state.
: > "$actions_file"
touch \
  "$config_dir/sessions/dotfiles.kitty-session" \
  "$config_dir/sessions/journal.kitty-session" \
  "$config_dir/sessions/reana.kitty-session"
run_picker new 'scratch'
generated="$runtime_dir/kitty-sessions-$UID/scratch.kitty-session"
assert_equal "$(cat "$generated")" \
  "$(printf 'new_tab\nlayout splits\ncd %s\nlaunch' "$project_dir")" \
  "generated session"
assert_equal "$(cat "$actions_file")" "@ action goto_session $generated" \
  "custom session action"
assert_equal "$(cat "$fzf_input_file")" $'dotfiles\njournal\nreana' \
  "new-session template choices"
grep -Fqx -- '--bind=enter:accept-or-print-query,alt-enter:print-query' \
  "$fzf_args_file"
if grep -Fqx -- '--query=^' "$fzf_args_file"; then
  echo "FAIL: new-session prompt is seeded with a query" >&2
  exit 1
fi

# Kitty expands dollar-prefixed names in session files. Reject such a working
# directory instead of silently opening the generated session somewhere else.
dollar_dir="$test_dir/project\$literal"
mkdir -p "$dollar_dir"
set +e
dollar_error=$(run_picker new 'unsafe-path' "$dollar_dir" 2>&1)
dollar_status=$?
set -e
assert_equal "$dollar_status" 1 "dollar-sign path status"
if [[ $dollar_error != *"working directory contains a dollar sign"* ]]; then
  echo "FAIL: dollar-sign path error was not reported" >&2
  exit 1
fi
if [[ -e "$runtime_dir/kitty-sessions-$UID/unsafe-path.kitty-session" ]]; then
  echo "FAIL: unsafe session file was created" >&2
  exit 1
fi

# A predefined name uses its tracked template; an active name simply switches.
: > "$actions_file"
run_picker new 'journal'
assert_equal "$(cat "$actions_file")" \
  "@ action goto_session $config_dir/sessions/journal.kitty-session" \
  "predefined session action"

: > "$actions_file"
run_picker new 'reana'
assert_equal "$(cat "$actions_file")" '@ focus-window --match id:42' \
  "active-name creation fallback"

# Cmd-S uses actual session focus recency. Including id 99 is significant: in
# background mode it is the source pane, not an overlay to exclude.
: > "$actions_file"
run_picker last ''
assert_equal "$(cat "$actions_file")" '@ focus-window --match id:42' \
  "previous session action"

# Exercise the same argv cases as the Python tab renderer. Each pane has a
# helper before its process-group leader, and an unrelated window title.
cases_file="$dotfiles_dir/tests/kitty-process-cases.json"
jq '[{tabs: [to_entries[] | {windows: [{
  id: (.key + 100), session_name: "test", cwd: "/projects/test", title: "",
  foreground_processes: [
    {pid: 31, cwd: "/projects/test", cmdline: ["caffeinate"]},
    {pid: 20, cwd: "/projects/test", cmdline: .value.argv}
  ]
}]}]}]' "$cases_file" > "$state_file"
run_picker pane ''
expected=$(jq -r 'to_entries[] | [
  ("[test] test" + (if .value.idle then "" else " @" + .value.name end)),
  ((.key + 100) | tostring)
] | @tsv' "$cases_file")
assert_equal "$(cat "$fzf_input_file")" "$expected" "shared process names"

# Unnamed Neovim buffers must replace a previous filename without displaying
# the placeholder. Missing titles must also leave the process label intact.
for title in '"[No Name]"' '""' 'null'; do
  jq --argjson title "$title" '
    (.[].tabs[].windows[].title) = $title
  ' "$state_file" > "$test_dir/updated-state.json"
  mv "$test_dir/updated-state.json" "$state_file"
  run_picker pane ''
  assert_equal "$(cat "$fzf_input_file")" "$expected" "unnamed or missing title"
done

echo "Kitty session picker: OK"
