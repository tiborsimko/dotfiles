# Tibor's bash configuration.
# shellcheck shell=bash
# shellcheck disable=SC1090,SC1091  # cached/dynamic/external sources

# If not running interactively, do not do anything
case $- in
*i*) ;;
*) return ;;
esac

# Do not put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth

# Append to the history file, do not overwrite it
shopt -s histappend

# Enlarge shell history
HISTSIZE=90000
HISTFILESIZE=90000

# Check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Make less more friendly for non-text input files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  if [ -r ~/.dircolors ]; then
    eval "$(dircolors -b ~/.dircolors)"
  else
    eval "$(dircolors -b)"
  fi
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# Enable programmable completion features - lazy loaded on first tab
_bash_completion_lazy_load() {
  # Remove the default completion that triggered this
  complete -r
  # Load bash-completion
  if [[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]]; then
    . "/opt/homebrew/etc/profile.d/bash_completion.sh"
  elif [[ -f /usr/share/bash-completion/bash_completion ]]; then
    . /usr/share/bash-completion/bash_completion
  elif [[ -f /etc/bash_completion ]]; then
    . /etc/bash_completion
  fi
  return 124 # Signal to retry completion
}

# Set default completion to trigger lazy load
complete -D -F _bash_completion_lazy_load

# Virtualenv helpers (replacing virtualenvwrapper)
workon() { source ~/.virtualenvs/"${1}"/bin/activate; }
mkvirtualenv() {
  local python_bin="python3"
  local OPTIND opt
  while getopts "p:" opt; do
    case $opt in
    p) python_bin="$OPTARG" ;;
    *) ;;
    esac
  done
  shift $((OPTIND - 1))
  local name=$1
  "${python_bin}" -m venv ~/.virtualenvs/"${name}" && workon "${name}"
}
lsvirtualenvs() {
  local d
  for d in ~/.virtualenvs/*/; do [ -d "$d" ] && basename "$d"; done
}
rmvirtualenv() { rm -rf ~/.virtualenvs/"${1}"; }

# Override EDITOR and VISUAL inside Emacs
if [[ -n "$INSIDE_EMACS" ]]; then
  export EDITOR="emacsclient -c"
  export VISUAL="emacsclient -c"
fi

# Configure useful aliases
alias b='$BROWSER'
alias cp='cp -i'
alias e="emacsclient -t"
alias ec="emacsclient -t -e '(org-capture)'"
alias ee="emacsclient -c -n"
alias gg="lazygit"
alias i3lock="i3lock -c 000000"
# Kubectl completion - lazy loaded
__kubectl_lazy_load() {
  unset -f kubectl 2>/dev/null
  unalias kubectl 2>/dev/null
  # Load bash-completion first if not already loaded (kubectl completion depends on it)
  if ! type _get_comp_words_by_ref &>/dev/null; then
    if [[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]]; then
      . "/opt/homebrew/etc/profile.d/bash_completion.sh"
    elif [[ -f /usr/share/bash-completion/bash_completion ]]; then
      . /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
      . /etc/bash_completion
    fi
  fi
  source <(command kubectl completion bash)
  export _kubectl_completion_loaded=1
}

kubectl() {
  __kubectl_lazy_load
  command kubectl "$@"
}
alias kgd="kubectl get deployments"
alias kgdw="kubectl get deployments -o wide"
alias kgj="kubectl get jobs"
alias kgjw="kubectl get jobs -o wide"
alias kgn="kubectl get nodes -o wide"
alias kgnw="kubectl get nodes -o wide --show-labels"
alias kgp="kubectl get pods"
alias kgpw="kubectl get pods -o wide"
alias kgpwa="kubectl get pods -o wide --all-namespaces"
alias kgs="kubectl get services"
alias kgsw="kubectl get services -o wide"
alias kgx="kubectl get secrets"
alias kgxw="kubectl get secrets -o wide"
alias l="ls -la --color"
alias ll="ls -l --color"
alias mv='mv -i'
alias o='$OPENER'
alias open='$OPENER'
alias rm='rm -i'
alias t="tmux"
alias v="nvim"
alias vim="nvim"
alias wr='workon reana && if [ $(docker ps | grep kind-control-plane | grep -cv Paused) -gt 0 ]; then eval "$(reana-dev client-setup-environment)"; fi'
alias wrm='workon reana && if [ $(docker ps | grep kind-control-plane | grep -cv Paused) -gt 0 ]; then eval "$(reana-dev client-setup-environment -n myreana)"; fi'

alias rg='command rg --line-number --with-filename --no-heading --hidden --glob "!.git/"'

# Command abbreviations: only expands when the entire pre-cursor input matches
# a key. Synthetic `\C-x\C-a` runs the expander via `bind -x`; Enter/Tab chain
# it via macros that end with non-recursing readline commands (`\C-j` =
# accept-line, `\C-x\C-c` = complete). Space uses `bind -x` directly to avoid
# macro recursion on a literal space.
declare -A BASH_ABBREVS=(
  [d]=docker
  [g]=git
  [gl]=glab
  [k]=kubectl
  [p]=podman
  [pc]=podman-compose
  [rc]=reana-client
  [rcg]=reana-client-go
  [rd]=reana-dev
)
_expand_abbrev() {
  if [[ -n $READLINE_LINE && -n ${BASH_ABBREVS[$READLINE_LINE]+x} ]]; then
    READLINE_LINE=${BASH_ABBREVS[$READLINE_LINE]}
    READLINE_POINT=${#READLINE_LINE}
  fi
}
_expand_abbrev_space() {
  _expand_abbrev
  READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT} ${READLINE_LINE:$READLINE_POINT}"
  READLINE_POINT=$((READLINE_POINT + 1))
}
_expand_abbrev_tab() {
  local before=$READLINE_LINE
  _expand_abbrev
  # Append a space after expansion so completion sees `kubectl ` (complete
  # args), not `kubectl` (complete the command name itself).
  if [[ $READLINE_LINE != "$before" ]]; then
    READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT} ${READLINE_LINE:$READLINE_POINT}"
    READLINE_POINT=$((READLINE_POINT + 1))
  fi
}
bind -x '"\C-x\C-a": _expand_abbrev'
bind -x '"\C-x\C-t": _expand_abbrev_tab'
bind -x '" ": _expand_abbrev_space'
bind '"\C-x\C-c": complete'
bind '"\C-m": "\C-x\C-a\C-j"'
bind '"\e\C-m": "\C-x\C-a\C-j"'
bind '"\C-i": "\C-x\C-t\C-x\C-c"'

# GPG terminal for pinentry
GPG_TTY=$(tty)
export GPG_TTY

# Claude Code client
export COLORTERM=truecolor

# Load fuzzy finder - cached for faster startup
_fzf_cache="$HOME/.cache/bash/fzf-init.bash"
if [[ ! -f "$_fzf_cache" ]] || [[ $(command -v fzf) -nt "$_fzf_cache" ]]; then
  mkdir -p "${_fzf_cache%/*}"
  fzf --bash >"$_fzf_cache" 2>/dev/null
fi
[[ -f "$_fzf_cache" ]] && source "$_fzf_cache"
unset _fzf_cache

# Fzf with rg
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'

# Fzf to use fd instead of find to list path candidates
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

# Use mise activate for full PATH/env management (hooks, auto-venv, etc.)
eval "$(mise activate bash)"

# Load Starship - cached for faster startup
_starship_cache="$HOME/.cache/bash/starship-init.bash"
if [[ ! -f "$_starship_cache" ]] || [[ $(command -v starship) -nt "$_starship_cache" ]]; then
  mkdir -p "${_starship_cache%/*}"
  starship init bash >"$_starship_cache" 2>/dev/null
fi
[[ -f "$_starship_cache" ]] && source "$_starship_cache"
unset _starship_cache

# Configure dynamic terminal window titles
set_terminal_window_title() {
  local cmd="$1"
  # Skip hooks, internal functions, and starship
  if [[ "$cmd" != *"_hook"* ]] &&
    [[ "$cmd" != "set_terminal_window_title"* ]] &&
    [[ "$cmd" != "__bp_"* ]] &&
    [[ "$cmd" != "starship_precmd"* ]]; then
    # For simple navigation commands, show directory after completion
    if [[ "$cmd" =~ ^(cd|pushd|popd) ]]; then
      printf '\033]0;%s\007' "$(basename "$PWD")"
    else
      printf '\033]0;%s\007' "$cmd"
    fi
  fi
}

# Also update title when prompt is displayed (after command completion)
update_title_on_prompt() {
  printf '\033]0;%s\007' "$(basename "$PWD")"
}

trap 'set_terminal_window_title "$BASH_COMMAND"' DEBUG
PROMPT_COMMAND="update_title_on_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}"

# Load Zoxide - cached for faster startup
_zoxide_cache="$HOME/.cache/bash/zoxide-init.bash"
if [[ ! -f "$_zoxide_cache" ]] || [[ $(command -v zoxide) -nt "$_zoxide_cache" ]]; then
  mkdir -p "${_zoxide_cache%/*}"
  zoxide init bash >"$_zoxide_cache" 2>/dev/null
fi
[[ -f "$_zoxide_cache" ]] && source "$_zoxide_cache"
unset _zoxide_cache

# Emacs eat shell integration (directory tracking, etc.)
[ -n "$EAT_SHELL_INTEGRATION_DIR" ] && source "$EAT_SHELL_INTEGRATION_DIR/bash"

# Load keychain
[ -f "/usr/bin/keychain" ] && eval "$(keychain --eval --agents ssh --quick --quiet)"

# Load SSH agent
SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
export SSH_AUTH_SOCK

# Load any possible local host customisations
[ -f "$HOME/.bashrc_local" ] && source "$HOME/.bashrc_local"
