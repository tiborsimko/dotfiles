#!/usr/bin/env bash

# Verify the dotfiles environment to ensure that shell loads cleanly,
# mise-managed binaries run, helm-diff plugin is installed.

set -eo pipefail

if [[ -t 1 ]]; then
  RED=$'\033[1;31m'
  GREEN=$'\033[1;32m'
  ORANGE=$'\033[1;33m'
  RESET=$'\033[0m'
else
  RED='' GREEN='' ORANGE='' RESET=''
fi

passed=0
failed=0
warnings=0
dotfiles_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

section() { printf '\n=== %s ===\n' "$1"; }

check() {
  local bin=$1 cmd=$2
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "${ORANGE}WARNING:${RESET} $bin missing"
    warnings=$((warnings + 1))
    return 0
  fi
  if output=$(bash -o pipefail -c "$cmd" 2>&1); then
    printf '%s\n' "$output"
    passed=$((passed + 1))
  else
    echo "${RED}FAIL:${RESET} $bin"
    printf '%s\n' "$output"
    failed=$((failed + 1))
  fi
}

abbrev_keys() {
  local file=$1 marker=$2
  awk -v marker="$marker" '
    index($0, marker) {
      in_table = 1
      next
    }
    in_table && /^[[:space:]]*\)/ {
      exit
    }
    in_table {
      line = $0
      sub(/[[:space:]]*#.*/, "", line)
      sub(/^[[:space:]]*/, "", line)
      if (line == "") {
        next
      }
      if (line ~ /^\[/) {
        sub(/^\[/, "", line)
        sub(/\].*$/, "", line)
      } else {
        sub(/[[:space:]].*$/, "", line)
      }
      print line
    }
  ' "$file"
}

check_abbrev_table() {
  local label=$1 file=$2 marker=$3
  local key keys_seen="" count=0 bad=0

  if ! grep -Fq "$marker" "$file"; then
    echo "${RED}FAIL:${RESET} $label abbreviation table not found"
    failed=$((failed + 1))
    return
  fi

  while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    count=$((count + 1))
    keys_seen="${keys_seen:+$keys_seen }$key"
    if [[ ! "$key" =~ ^[a-z]$ ]]; then
      echo "${RED}FAIL:${RESET} $label abbreviation '$key' is not one lowercase letter"
      bad=1
    fi
  done < <(abbrev_keys "$file" "$marker")

  if ((count == 0)); then
    echo "${RED}FAIL:${RESET} $label abbreviation table is empty"
    failed=$((failed + 1))
  elif ((bad > 0)); then
    failed=$((failed + 1))
  else
    echo "$label: OK ($keys_seen)"
    passed=$((passed + 1))
  fi
}

section "Command abbreviations"
check_abbrev_table "Zsh" "$dotfiles_dir/zsh/.config/zsh/.zshrc" \
  "typeset -gA ZSH_ABBREVS=("
check_abbrev_table "Bash" "$dotfiles_dir/bash/.bashrc" \
  "declare -A BASH_ABBREVS=("

section "Git aliases"
check bash "\"$dotfiles_dir/tests/test-git-aliases.sh\""

section "Git forge shortcuts"
check bash "\"$dotfiles_dir/tests/test-git-forge.sh\""

section "Task capture syntax"
check bash "\"$dotfiles_dir/tests/test-task-capture.sh\""

section "Interactive shell"
stderr=$(bash -lic true 2>&1 1>/dev/null |
  grep -vE "cannot set terminal process group|no job control in this shell" || true)
if [[ -z "$stderr" ]]; then
  echo "OK"
  passed=$((passed + 1))
else
  echo "${RED}FAIL:${RESET} interactive shell"
  printf '%s\n' "$stderr"
  failed=$((failed + 1))
fi

section "Mise activation"
if ! command -v mise >/dev/null 2>&1; then
  echo "${ORANGE}WARNING:${RESET} mise missing"
  warnings=$((warnings + 1))
elif activate=$(mise activate bash 2>/dev/null); then
  eval "$activate"
  echo "OK"
  passed=$((passed + 1))
else
  echo "${RED}FAIL:${RESET} mise activate"
  failed=$((failed + 1))
fi

section "Tool versions"
check nvim "nvim --version | head -1"
check starship "starship --version"
check helm "helm version --short"
check kubectl "kubectl version --client 2>/dev/null | head -1"
check kind "kind version"
check delta "delta --version"
check lazygit "lazygit --version | head -1"
check cr "cr version | head -1"
for v in 3.15 3.14 3.13 3.12 3.11 3.10 3.9 3.8; do
  check "python$v" "python$v --version"
done

if command -v helm >/dev/null 2>&1; then
  section "Helm plugins"
  if output=$(helm plugin list 2>&1); then
    printf '%s\n' "$output"
    if echo "$output" | grep -q '^diff'; then
      passed=$((passed + 1))
    else
      echo "${ORANGE}WARNING:${RESET} helm-diff plugin missing"
      warnings=$((warnings + 1))
    fi
  else
    echo "${RED}FAIL:${RESET} helm plugin list"
    printf '%s\n' "$output"
    failed=$((failed + 1))
  fi
fi

echo
pass_color="" fail_color="" warn_color=""
if ((passed > 0)); then pass_color=$GREEN; fi
if ((failed > 0)); then fail_color=$RED; fi
if ((warnings > 0)); then warn_color=$ORANGE; fi
printf '=== %s%d PASSED%s, %s%d FAILED%s, %s%d WARNINGS%s ===\n' \
  "$pass_color" "$passed" "$RESET" \
  "$fail_color" "$failed" "$RESET" \
  "$warn_color" "$warnings" "$RESET"

if ((failed > 0)); then
  exit 1
fi
