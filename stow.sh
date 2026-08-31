#!/usr/bin/env bash

# Activate dotfiles via GNU Stow.
#
# Packages are uncommented progressively as each is verified via
# `make docker-test`.

set -o errexit
set -o nounset

# Resolve package paths relative to this script so callers need not run it from
# the repository root.
repo_dir=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
cd "$repo_dir"

help() {
  echo "Usage: $0 [options] <target>..."
  echo "Options:"
  echo "  --help        Show this help [default]"
  echo "Targets:"
  echo "  all           Stow all enabled packages"
  echo "  <package>     Stow one or more named packages"
  echo "Packages:"
  printf '  %s\n' "${packages[@]}"
}

detect_os() {
  case "$(uname -s)" in
    Darwin)
      echo macos
      ;;
    Linux)
      echo linux
      ;;
    *)
      echo "Unsupported OS: $(uname -s)" >&2
      exit 1
      ;;
  esac
}

stow_package() {
  local package=$1
  local target_dir=$2

  stow --no-folding --target="$target_dir" "$package"
}

stow_variant_package() {
  local package=$1
  local variant=$2
  local target_dir=$3

  if [ -d "$package/common" ]; then
    stow --no-folding --dir="$package" --target="$target_dir" common
  fi
  if [ -d "$package/$variant" ]; then
    stow --no-folding --dir="$package" --target="$target_dir" "$variant"
  fi
}

stow_folded_package() {
  local package=$1
  local target_dir=$2

  # Codex's skill scanner discovers a skill only when its *directory* is a
  # symlink; a symlinked SKILL.md inside a real directory (what --no-folding
  # produces) is not picked up. (Claude tolerates the file-symlink form, so it
  # stays on the default --no-folding path.) Pre-create the real skills/ parent
  # so stow tree-folds each leaf skill directory into a single directory symlink.
  local leaf
  while IFS= read -r leaf; do
    mkdir -p "$target_dir/$(dirname "$leaf")"
    # A real directory here is the stale --no-folding form, which stow will not
    # re-fold; fail with the one-time cleanup rather than reporting false success.
    if [ -d "$target_dir/$leaf" ] && [ ! -L "$target_dir/$leaf" ]; then
      echo "stow.sh: $target_dir/$leaf is a real directory from an earlier" >&2
      echo "         --no-folding stow; stow cannot fold it. Remove it first:" >&2
      echo "           rm -rf \"$target_dir/$leaf\"" >&2
      exit 1
    fi
  done < <(cd "$package" && find . -type d -path '*/skills/*' -prune -print | sed 's|^\./||')

  stow --target="$target_dir" "$package"
}

packages=(
  aerospace
  alacritty
  bash
  claude
  codex
  colima
  dunst
  # flake8
  fontconfig
  git
  gnupg
  i3
  inputrc
  journal
  karabiner
  lazygit
  mbsync
  mimeapps
  mise
  msmtp
  neomutt
  notmuch
  nvim
  oauth2
  picom
  reclaim
  rsync
  ssh
  sshuttle
  starship
  taskwarrior
  theme
  tmux
  xinit
  xmodmap
  xresources
  # zathura
  zsh
)

if [ $# -eq 0 ]; then
  help
  exit 0
fi

case "$1" in
  --help)
    help
    exit 0
    ;;
  all)
    ;;
  *)
    packages=("$@")
    ;;
esac

os=$(detect_os)
# STOW_TARGET overrides the default home directory; useful for temp-target test runs.
target_dir=${STOW_TARGET:-"$HOME"}

for package in "${packages[@]}"; do
  case "$package" in
    gnupg|mise|taskwarrior)
      stow_variant_package "$package" "$os" "$target_dir"
      ;;
    codex)
      stow_folded_package "$package" "$target_dir"
      ;;
    *)
      stow_package "$package" "$target_dir"
      ;;
  esac
done
