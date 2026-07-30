# Tibor's bash profile configuration.
# shellcheck shell=bash
# shellcheck disable=SC1090,SC1091  # cached/external sources

# Use brew (cached for faster startup) - macOS only
_brew_cache="$HOME/.cache/bash/brew-shellenv.bash"
if [[ -x /opt/homebrew/bin/brew ]]; then
  if [[ ! -f "$_brew_cache" ]] || [[ /opt/homebrew/bin/brew -nt "$_brew_cache" ]]; then
    mkdir -p "${_brew_cache%/*}"
    /opt/homebrew/bin/brew shellenv >"$_brew_cache"
  fi
  source "$_brew_cache"
fi
unset _brew_cache

# Configure Go path
export GOPATH="$HOME/private/go"

# Configure preferred programs
export BROWSER="open"
export EDITOR="nvim"
export OPENER="open"
export PAGER="less"
export TERMINAL="alacritty"
export VISUAL="nvim"

# System-level locale settings
export LANG="en_GB.UTF-8"
export LC_ALL="en_GB.UTF-8"
export LC_COLLATE="en_GB.UTF-8"

# Tool defaults
export BAT_THEME=ansi
export FZF_DEFAULT_OPTS='--layout=reverse --height 50%'
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
  --color=fg:#ebdbb2,bg:#1c1c1c,hl:#83a598
  --color=fg+:#ebdbb2,bg+:#3c3836,hl+:#83a598,gutter:#1c1c1c
  --color=info:#8ec07c,prompt:#7c6f64,pointer:#8ec07c
  --color=marker:#8ec07c,spinner:#8ec07c,header:#665c54
    '
export K9S_SKIN="gruvbox-dark-hard"

# Less
export LESS='-F -i -M -R -S -z-4'
export LESSCHARSET=utf-8
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[00;47;30m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# Prepend PATH entries without introducing duplicates
_path_prepend() {
  if [[ :$PATH: != *":$1:"* ]]; then
    PATH="$1${PATH:+:$PATH}"
  fi
}
_path_prepend "$HOME/.local/bin"
_path_prepend /usr/local/go/bin
_path_prepend "$GOPATH/bin"
_path_prepend "$HOME/.cargo/bin"
_path_prepend "$HOME/.local/share/nvim/mason/bin"
_path_prepend "${KREW_ROOT:-$HOME/.krew}/bin"
export PATH
unset -f _path_prepend

# Load Cargo
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Load my bash configuration
[[ -f "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
