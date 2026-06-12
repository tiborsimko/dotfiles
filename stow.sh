#!/usr/bin/env bash

# Activate dotfiles via GNU Stow. Run from the dotfiles repo root.
#
# Packages are uncommented progressively as each is verified via
# `make docker-test`; see TODO.md for the rollout order.

set -o errexit
set -o nounset

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

packages=(
  aerospace
  alacritty
  bash
  colima
  dunst
  emacs
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
  ssh
  starship
  taskwarrior
  tmux
  x1
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
target_dir=${STOW_TARGET:-$(dirname "$PWD")}

for package in "${packages[@]}"; do
  case "$package" in
    gnupg|mise|taskwarrior)
      stow_variant_package "$package" "$os" "$target_dir"
      ;;
    *)
      stow_package "$package" "$target_dir"
      ;;
  esac
done
