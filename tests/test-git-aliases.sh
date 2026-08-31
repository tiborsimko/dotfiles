#!/usr/bin/env bash

# Verify the one-letter Git alias vocabulary and its custom helpers.
set -euo pipefail

test_dir=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
dotfiles_dir=$(dirname -- "$test_dir")
git_config="$dotfiles_dir/git/.config/git/config"
branches_script="$dotfiles_dir/git/.config/git/git-branches.sh"
fetch_script="$dotfiles_dir/git/.config/git/git-fetch.sh"
log_script="$dotfiles_dir/git/.config/git/git-log.sh"
x_script="$dotfiles_dir/git/.config/git/git-x.sh"
bash_config="$dotfiles_dir/bash/.bashrc"
zsh_config="$dotfiles_dir/zsh/.config/zsh/.zshrc"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_equal() {
  local expected=$1
  local actual=$2
  local label=$3

  [ "$actual" = "$expected" ] ||
    fail "$label: expected '$expected', got '$actual'"
}

alias_names=$(
  git config --file "$git_config" --name-only --get-regexp '^alias\.' |
    sed 's/^alias\.//' |
    sort |
    tr '\n' ' '
)
assert_equal "a b c d f g i k l p r s x " "$alias_names" \
  "one-letter alias vocabulary"

assert_equal add "$(git config --file "$git_config" alias.a)" "git a"
assert_equal checkout "$(git config --file "$git_config" alias.c)" "git c"
assert_equal diff "$(git config --file "$git_config" alias.d)" "git d"
assert_equal grep "$(git config --file "$git_config" alias.g)" "git g"
assert_equal "status -s" "$(git config --file "$git_config" alias.s)" "git s"

k_alias=$(git config --file "$git_config" alias.k)
case "$k_alias" in
  "log --graph "*" --all") ;;
  *) fail "git k must show the decorated graph for all refs" ;;
esac

for alias_name in b f i l p r x; do
  alias_value=$(git config --file "$git_config" "alias.$alias_name")
  case "$alias_value" in
    \!*) ;;
    *) fail "git $alias_name must dispatch through a helper" ;;
  esac
done

f_alias=$(git config --file "$git_config" alias.f)
case "$f_alias" in
  *git-fetch.sh*) ;;
  *) fail "git f must dispatch through git-fetch.sh" ;;
esac

l_alias=$(git config --file "$git_config" alias.l)
case "$l_alias" in
  *git-log.sh*) ;;
  *) fail "git l must dispatch through git-log.sh" ;;
esac

for shell_config in "$bash_config" "$zsh_config"; do
  grep -Fq '_git_f()' "$shell_config" ||
    fail "${shell_config#"$dotfiles_dir"/} does not map git f completion"
  grep -Fq 'words[__git_cmd_idx]=fetch' "$shell_config" ||
    fail "${shell_config#"$dotfiles_dir"/} does not complete git f as fetch"
  grep -Fq '_git_l()' "$shell_config" ||
    fail "${shell_config#"$dotfiles_dir"/} does not map git l completion"
  grep -Fq 'words[__git_cmd_idx]=log' "$shell_config" ||
    fail "${shell_config#"$dotfiles_dir"/} does not complete git l as log"
  grep -Fq '_git_x()' "$shell_config" ||
    fail "${shell_config#"$dotfiles_dir"/} does not complete git x"
  grep -Fq 'subcommands="land-branch land-pr"' "$shell_config" ||
    fail "${shell_config#"$dotfiles_dir"/} does not complete git x workflows"
  grep -Fq 'land-branch) __gitcomp_nl' "$shell_config" ||
    fail "${shell_config#"$dotfiles_dir"/} does not complete land-branch heads"
  grep -Fq '__git_heads' "$shell_config" ||
    fail "${shell_config#"$dotfiles_dir"/} does not source local heads"
done

run_native_completion() {
  local shell_config=$1
  local alias_name=$2
  local native_command=$3

  # Simulate completion after global Git options have moved the alias away
  # from words[1]. The function body is evaluated by the child Bash process.
  # shellcheck disable=SC2016
  CONFIG="$shell_config" ALIAS_NAME="$alias_name" \
    NATIVE_COMMAND="$native_command" "$BASH" -c '
    eval "$(sed -n "/^_git_${ALIAS_NAME}()/,/^}/p" "$CONFIG")"
    words=(git -C /tmp "$ALIAS_NAME" "")
    __git_cmd_idx=3
    native_completion() {
      printf "%s|%s\n" "${words[1]}" "${words[__git_cmd_idx]}"
    }
    eval "_git_${NATIVE_COMMAND}() { native_completion; }"
    complete_alias() {
      local __git_cmd_idx=3
      "_git_${ALIAS_NAME}"
    }
    complete_alias
  '
}

for shell_config in "$bash_config" "$zsh_config"; do
  shell_label=${shell_config#"$dotfiles_dir"/}
  assert_equal "-C|fetch" \
    "$(run_native_completion "$shell_config" f fetch)" \
    "$shell_label git f completion after global options"
  assert_equal "-C|log" \
    "$(run_native_completion "$shell_config" l log)" \
    "$shell_label git l completion after global options"
done

run_x_completion() {
  local shell_config=$1
  local selected_subcommand=${2:-}

  # Extract only the portable completion function and provide the Git
  # completion helpers it expects. The function body is evaluated by Bash.
  # shellcheck disable=SC2016
  CONFIG="$shell_config" SELECTED_SUBCOMMAND="$selected_subcommand" \
    "$BASH" -c '
      eval "$(sed -n '\''/^_git_x()/,/^}/p'\'' "$CONFIG")"
      __git_find_on_cmdline() { printf "%s" "$SELECTED_SUBCOMMAND"; }
      __gitcomp() { printf "subcommands:%s\n" "$1"; }
      __git_heads() { printf "%s\n" master topic; }
      __gitcomp_nl() { printf "heads:%s\n" "$1"; }
      _git_x
    '
}

for shell_config in "$bash_config" "$zsh_config"; do
  shell_label=${shell_config#"$dotfiles_dir"/}
  assert_equal "subcommands:land-branch land-pr" \
    "$(run_x_completion "$shell_config")" \
    "$shell_label git x workflow completion"
  assert_equal "$(printf 'heads:master\ntopic')" \
    "$(run_x_completion "$shell_config" land-branch)" \
    "$shell_label git x branch completion"
  assert_equal "" "$(run_x_completion "$shell_config" land-pr)" \
    "$shell_label git x pull-request completion"
done

x_alias=$(git config --file "$git_config" alias.x)
case "$x_alias" in
  *git-x.sh*) ;;
  *) fail "git x must dispatch through git-x.sh" ;;
esac

branch_output=$(
  # The function is evaluated by the child Bash process.
  # shellcheck disable=SC2016
  SCRIPT="$branches_script" "$BASH" -c '
    git() { printf "git:%s\n" "$*"; }
    source "$SCRIPT"
  ' branch-test feature
)
assert_equal \
  "git:for-each-ref --format=%(committerdate:short) %(refname) --sort=committerdate refs/heads/*feature*" \
  "$branch_output" "git b filter"

branch_output=$(
  # The function is evaluated by the child Bash process.
  # shellcheck disable=SC2016
  SCRIPT="$branches_script" "$BASH" -c '
    git() { printf "git:%s\n" "$*"; }
    source "$SCRIPT"
  ' branch-test -r origin
)
assert_equal \
  "git:for-each-ref --format=%(committerdate:short) %(refname) --sort=committerdate refs/remotes/origin" \
  "$branch_output" "git b remote"

run_fetch() {
  local mock_remotes=$1
  shift

  # The function is evaluated by the child Bash process.
  # shellcheck disable=SC2016
  MOCK_REMOTES="$mock_remotes" SCRIPT="$fetch_script" "$BASH" -c '
    git() {
      if [ "${1:-} ${2:-}" = "config --get" ]; then
        local remote=${3#remote.}
        remote=${remote%.url}
        case " $MOCK_REMOTES " in
          *" $remote "*) return 0 ;;
          *) return 1 ;;
        esac
      fi
      printf "git:%s\n" "$*"
    }
    source "$SCRIPT"
  ' fetch-test "$@"
}

assert_equal "git:fetch --multiple upstream origin" \
  "$(run_fetch 'upstream origin')" "git f with fork remotes"
assert_equal "git:fetch upstream" "$(run_fetch upstream)" \
  "git f with only upstream"
assert_equal "git:fetch origin" "$(run_fetch origin)" \
  "git f with only origin"
assert_equal "git:fetch" "$(run_fetch '')" "git f without named remotes"
assert_equal "git:fetch origin" "$(run_fetch 'upstream origin' origin)" \
  "git f explicit origin"
assert_equal "git:fetch --all" "$(run_fetch 'upstream origin' --all)" \
  "git f native options"

run_log() {
  # The function is evaluated by the child Bash process.
  # shellcheck disable=SC2016
  SCRIPT="$log_script" "$BASH" -c '
    git() { printf "git:%s\n" "$*"; }
    source "$SCRIPT"
  ' log-test "$@"
}

assert_equal "git:log master.. --stat" "$(run_log)" \
  "git l default stat view"
assert_equal "git:log master.. --stat --author=Tibor" \
  "$(run_log --author=Tibor)" "git l filtering retains stats"
assert_equal "git:log master.. --stat -n 5" "$(run_log -n 5)" \
  "git l count retains stats"
assert_equal "git:log master.. --stat -- README.md" \
  "$(run_log -- README.md)" "git l pathspec retains stats"
assert_equal "git:log master.. --stat -- -p" "$(run_log -- -p)" \
  "git l option-like pathspec retains stats"

for output_option in \
  -p --patch --oneline --pretty --pretty=short --format=oneline --shortstat; do
  assert_equal "git:log master.. $output_option" \
    "$(run_log "$output_option")" \
    "git l output override $output_option"
done

for overriding_option in --name-only --numstat --name-status; do
  assert_equal "git:log master.. --stat $overriding_option" \
    "$(run_log "$overriding_option")" \
    "git l native stat override $overriding_option"
done

assert_equal "git:log master.. --author=Tibor --oneline" \
  "$(run_log --author=Tibor --oneline)" \
  "git l output override with filtering"
assert_equal "git:log master.. --stat -p" "$(run_log --stat -p)" \
  "git l explicit combined output"

run_land() {
  # The function is evaluated by the child Bash process.
  # shellcheck disable=SC2016
  SCRIPT="$x_script" "$BASH" -c '
    git() {
      if [ "$1 $2" = "check-ref-format --branch" ]; then
        return 0
      fi
      printf "git:%s\n" "$*"
    }
    source "$SCRIPT"
  ' land-test "$@"
}

land_output=$(run_land land-branch topic)
assert_equal "$(printf '%s\n' \
  'git:fetch upstream' \
  'git:fetch origin' \
  'git:checkout master' \
  'git:merge --ff-only upstream/master' \
  'git:merge --ff-only topic' \
  'git:branch -d topic' \
  'git:push upstream master' \
  'git:push origin master' \
  'git:push origin --delete topic')" \
  "$land_output" "git x land-branch"

land_output=$(run_land land-pr 123)
assert_equal "$(printf '%s\n' \
  'git:fetch upstream' \
  'git:checkout master' \
  'git:merge --ff-only upstream/master' \
  'git:merge --ff-only upstream/pr/123' \
  'git:branch -d pr-123' \
  'git:push upstream master' \
  'git:push origin master')" \
  "$land_output" "git x land-pr"

if invalid_output=$(run_land land-pr nope 2>&1); then
  fail "git x land-pr accepted a non-numeric pull-request number"
fi
assert_equal "git x: pull-request number must be numeric" "$invalid_output" \
  "git x error attribution"

echo "Git aliases: OK"
