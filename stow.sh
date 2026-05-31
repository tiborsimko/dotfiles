#!/usr/bin/env bash

# Activate dotfiles via GNU Stow. Run from the dotfiles repo root.
#
# Packages are uncommented progressively as each is verified via
# `make docker-test`; see TODO.md for the rollout order.

set -o errexit
set -o nounset

packages=(
  aerospace
  alacritty
  bash
  # dunst
  # flake8
  # fontconfig
  git
  # gnupg
  # helix
  i3
  inputrc
  karabiner
  # lazygit
  # mbsync
  # mimeapps
  mise
  # msmtp
  # neomutt
  # notmuch
  nvim
  # oauth2
  # picom
  # ssh
  starship
  # taskwarrior
  tmux
  # x1
  # xinit
  # xmodmap
  # xresources
  # zathura
  zsh
)

stow --no-folding "${packages[@]}"
