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
for v in 3.14 3.13 3.12 3.11 3.10 3.9 3.8; do
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
