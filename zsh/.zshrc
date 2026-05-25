# Tibor's zshrc.

# Measure start-up performance?
ZSHZPROF=0  # 0=no, 1=yes

# Load zprof optionally
[ $ZSHZPROF -gt 0 ] && zmodload zsh/zprof

# Interactive shell configuration

# Enable bracketed paste (prevents \e[200~ leaking as literal text)
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic

# Set programs used in interactive sessions
export BROWSER="open"
export PAGER="less"
export OPENER="open"

# Set EDITOR and VISUAL based on environment
if [[ -n "$INSIDE_EMACS" ]]; then
    # Use emacsclient without -c to reuse current frame (faster in eat terminal)
    export EDITOR="emacsclient"
    export VISUAL="emacsclient"
else
    export EDITOR="nvim"
    export VISUAL="nvim"
fi

# Fzf with rg
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'

# Fzf layout and minimal customization
export FZF_DEFAULT_OPTS='--layout=reverse --height 50% --gutter=" " --color=pointer:#689d6a,marker:#689d6a'

# Fzf to use fd instead of find to list path candidates
_fzf_compgen_path() {
    fd --hidden --follow --exclude ".git" . "$1"
}

_fzf_compgen_dir() {
    fd --type d --hidden --follow --exclude ".git" . "$1"
}

# GPG terminal for pinentry
GPG_TTY=$(tty)
export GPG_TTY

# Set bat theme (for delta)
export BAT_THEME=ansi

# K9s colours
export K9S_SKIN="gruvbox-dark-hard"

# Claude Code client
export COLORTERM=truecolor

# Less
export LESS='-F -i -M -R -z-4'
export LESSCHARSET=utf-8
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[00;47;30m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# Configure where to install zsh plugins
ZSHPLUGGED=$HOME/.zsh/plugged

# Install zsh plugins if necessary
if [ ! -d $ZSHPLUGGED ]; then
    mkdir -p $ZSHPLUGGED && cd $ZSHPLUGGED
    git clone https://github.com/zsh-users/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-history-substring-search
    git clone https://github.com/changyuheng/zsh-interactive-cd
    git clone https://github.com/zsh-users/zsh-completions
fi

# Autosuggestions (zsh-users/zsh-autosuggestions)
source $ZSHPLUGGED/zsh-autosuggestions/zsh-autosuggestions.zsh

# Completions (zsh-users/zsh-completions)
# Ensure Homebrew completions are available (in case .zprofile wasn't sourced)
[[ -d /opt/homebrew/share/zsh/site-functions ]] && fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
fpath=($ZSHPLUGGED/zsh-completions/src /usr/share/zsh/vendor-completions $fpath)
autoload -Uz compinit
if [[ ! -f ~/.zcompdump ]] || [[ $(date +'%j') != $(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null) ]]; then
  compinit
else
  compinit -C
fi

# Completion matching: exact -> case-insensitive -> partial-word at separators -> substring
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# History substring searching (zsh-users/zsh-history-substring-search)
source $ZSHPLUGGED/zsh-history-substring-search/zsh-history-substring-search.zsh
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=''
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND=''

# cd (changyuheng/zsh-interactive-cd)
source $ZSHPLUGGED/zsh-interactive-cd/zsh-interactive-cd.plugin.zsh

# Snappy Esc → command-mode switch (default 40 = 400ms is laggy)
KEYTIMEOUT=1

# Use vi bindings (must come before custom bindings)
bindkey -v

# Bind arrow keys for history prefix search (like bash's history-search-backward)
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
bindkey '^[OA' history-beginning-search-backward
bindkey '^[OB' history-beginning-search-forward
bindkey '^P' history-beginning-search-backward
bindkey '^N' history-beginning-search-forward
bindkey '^[[5~' history-beginning-search-backward
bindkey '^[[6~' history-beginning-search-forward

# Bind Home/End keys (both escape code variants for tmux compatibility)
bindkey '^[[H' beginning-of-line
bindkey '^[OH' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[OF' end-of-line

# Emacs-inspired comforts in vi insert mode (not exact emacs semantics).
# (Ctrl-W backward-kill-word, Ctrl-U kill-line-backward, Ctrl-R history search work by default)
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^B' backward-word
bindkey -M viins '^F' forward-word
bindkey -M viins '^K' kill-line
bindkey -M viins '^Y' yank
bindkey -M viins '^[d' kill-word
bindkey -M viins '^[f' forward-word
bindkey -M viins '^[b' backward-word

# Edit current command line in $EDITOR (long pipelines benefit from full nvim)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M viins '^X^E' edit-command-line
bindkey -M vicmd 'v'    edit-command-line

# In vi normal mode, k/j walk history with prefix search (matches arrow keys)
bindkey -M vicmd 'k' history-beginning-search-backward
bindkey -M vicmd 'j' history-beginning-search-forward

# Treat Alacritty Shift+Return (ESC CR) as normal Enter at the shell prompt.
bindkey '^[^M' accept-line

# Disable terminal bell/beep
unsetopt BEEP

# Treat ! literally at interactive prompts.  History expansion breaks common
# pasted payloads such as curl data, JSON, URLs, and passwords.
unsetopt BANG_HIST

# Shortcuts for some directories
setopt autonamedirs
r=$HOME/private/project/reana/src
o=$HOME/private/project/opendata/src/opendata.cern.ch
a=$HOME/private/project/analysispreservation/src/analysispreservation.cern.ch
i=$HOME/private/project/invenio/src

# cdr / cd to recent directories
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs

# History
HISTFILE=$HOME/.cache/zsh/history
HISTSIZE=90000
SAVEHIST=90000

# Do not share history between terminals with my tmux workflow
setopt no_share_history
unsetopt share_history

# Allow '>' redirection to overwrite existing files
setopt clobber

# Useful aliases
alias b="$BROWSER"
alias cp='cp -i'
alias e="emacsclient -t"
alias ec="emacsclient -t -e '(org-capture)'"
alias ee="emacsclient -c -n"
alias g="git"
alias gg="lazygit"
alias gl="glab"
alias i3lock="i3lock -c 000000"
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
alias mutt="neomutt"
alias mv='mv -i'
alias o=open
alias p="podman"
alias pc="podman-compose"
alias rcg='reana-client-go'
alias rc='reana-client'
alias rd='reana-dev'
alias rm='rm -i'
alias t="task"
alias to="taskopen"
alias vim="nvim"
alias v="nvim"
alias wr='workon reana && eval "$(reana-dev client-setup-environment)"'

# Kubectl completion - lazy loaded
_kubectl_lazy_load() {
    # Unfunction the command wrappers to avoid interference
    unfunction kubectl k 2>/dev/null
    # Load kubectl completion
    source <(command kubectl completion zsh)
    # Set up completion for k to use kubectl's completion
    compdef k=kubectl
    # Recreate command wrappers without lazy loading (since it's now loaded)
    kubectl() { command kubectl "$@" }
    k() { command kubectl "$@" }
    # Mark as loaded
    export _kubectl_completion_loaded=1
}

# Lazy load kubectl completion when kubectl or k is used for the first time
kubectl() {
    _kubectl_lazy_load
    kubectl "$@"
}

k() {
    _kubectl_lazy_load
    kubectl "$@"
}

# Completion trigger function that loads kubectl on first TAB
_kubectl_lazy_completion() {
    _kubectl_lazy_load
    # Now call the real kubectl completion function
    _kubectl "$@"
}

# Set up completion to trigger lazy load
compdef _kubectl_lazy_completion kubectl
compdef _kubectl_lazy_completion k

# Docker alias
alias d='docker'

# K9s completion - lazy loaded
_k9s_lazy_load() {
    # Unfunction the command wrapper to avoid interference
    unfunction k9s 2>/dev/null
    # Load k9s completion if available
    if command -v k9s &> /dev/null; then
        source <(command k9s completion zsh)
    fi
    # Recreate command wrapper without lazy loading (since it's now loaded)
    k9s() { command k9s "$@" }
    # Mark as loaded
    export _k9s_completion_loaded=1
}

# Lazy load k9s completion when k9s is used for the first time
k9s() {
    _k9s_lazy_load
    k9s "$@"
}

# Completion trigger function that loads k9s on first TAB
_k9s_lazy_completion() {
    _k9s_lazy_load
    # Now call the real k9s completion function
    _k9s "$@"
}

# Set up completion to trigger lazy load
compdef _k9s_lazy_completion k9s

alias rg='command rg --line-number --with-filename --no-heading --hidden --glob "!.git/"'

# Set up completions for aliased commands
compdef _git g

# ff = fuzzy file (and edit)
ff() {
    IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
    [[ -n "$files" ]] && $=EDITOR "${files[@]}"
}

# fs = fuzzy search (string and edit matching files)
fs() {
    local file
    local line
    read -r file line <<<"$(ag --nobreak --noheading $@ | fzf -0 -1 | awk -F: '{print $1, $2}')"
    if [[ -n $file ]]; then
        $=EDITOR $file +$line
    fi
}

# fv = fuzzy view (of a string in files)
fv() {
    if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
    local file
    file="$(rg --max-count=1 --ignore-case --files-with-matches --no-messages "$@" | fzf-tmux +m --preview="rg --ignore-case --pretty --context 10 '"$@"' {}")" && ${OPENER} "$file"
}

# Emacs eat shell integration (directory tracking, etc.)
[ -n "$EAT_SHELL_INTEGRATION_DIR" ] && source "$EAT_SHELL_INTEGRATION_DIR/zsh"

# Virtualenv helpers (replacing virtualenvwrapper)
workon() { source ~/.virtualenvs/${1}/bin/activate }
mkvirtualenv() {
  local python_bin="python3"
  local OPTIND=1 opt
  while getopts "p:" opt; do
    case $opt in
      p) python_bin="$OPTARG" ;;
      *) ;;
    esac
  done
  shift $((OPTIND - 1))
  local name=$1
  ${python_bin} -m venv ~/.virtualenvs/${name} && workon ${name}
}
lsvirtualenvs() { local d; for d in ~/.virtualenvs/*/; do [ -d "$d" ] && basename "$d"; done }
rmvirtualenv() { rm -rf ~/.virtualenvs/${1} }

# SSH agent
# $(ssh-add -l | grep -q 'The agent has no identities') && ssh-add

# Use mise activate for full PATH/env management (hooks, auto-venv, etc.)
eval "$(mise activate zsh)"

# Add krew (kubectl plugin manager) to PATH
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Prompt
eval "$(starship init zsh)"

# Change terminal window titles
set_terminal_window_title() {
    local cmd=$(echo $1 | cut -d' ' -f1)
    if [ "$cmd" != "" ]; then
        echo -ne "\033]0;$cmd\007"
    else
        echo -ne "\033]0;$(basename "$PWD")\007"
    fi
}

typeset -ga precmd_functions
precmd_functions+=(set_terminal_window_title)

# Reset cursor visibility before each prompt (prevents invisible cursor)
_reset_cursor() { echo -ne '\e[?25h\e[6 q' }
precmd_functions+=(_reset_cursor)

# Cursor shape reflects vi keymap: bar in insert, block in normal
_vi_cursor_shape() {
    case $KEYMAP in
        vicmd|visual) echo -ne '\e[2 q' ;;
        main|viins|*) echo -ne '\e[6 q' ;;
    esac
}
zle -N zle-keymap-select _vi_cursor_shape
zle -N zle-line-init _vi_cursor_shape

typeset -ga preexec_functions
preexec_functions+=(set_terminal_window_title)

# Fuzzy finder - cached for faster startup
_fzf_completion_cache="$HOME/.cache/zsh/fzf-completion.zsh"
if [[ ! -f "$_fzf_completion_cache" ]] || [[ $(command -v fzf) -nt "$_fzf_completion_cache" ]]; then
    mkdir -p "${_fzf_completion_cache:h}"
    fzf --zsh > "$_fzf_completion_cache" 2>/dev/null
fi
[[ -f "$_fzf_completion_cache" ]] && source "$_fzf_completion_cache"
unset _fzf_completion_cache

# Load local host customisations
[ -f $HOME/.zshrc.local ] && source $HOME/.zshrc.local

# Load Zoxide
eval "$(zoxide init zsh)"

# Syntax highlighting (zsh-users/zsh-syntax-highlighting)
# Limit syntax highlighting to shorter inputs for better performance for longer inputs
ZSH_HIGHLIGHT_MAXLENGTH=100
source $ZSHPLUGGED/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Load keychain
# eval $(keychain --eval --agents ssh --quick --quiet)

# Report on performance
[ $ZSHZPROF -gt 0 ] && zprof
