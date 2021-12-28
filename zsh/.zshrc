# Tibor's zshrc.

# Measure start-up performance?
ZSHZPROF=0  # 0=no, 1=yes

# Load zprof optionally
[ $ZSHZPROF -gt 0 ] && zmodload zsh/zprof

# Configure where to install zsh plugins
ZSHPLUGGED=$HOME/.zsh/plugged

# Install zsh plugins if necessary
if [ ! -d $ZSHPLUGGED ]; then
    mkdir -p $ZSHPLUGGED && cd $ZSHPLUGGED
    git clone https://github.com/zsh-users/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-history-substring-search
    git clone https://github.com/rupa/z
    git clone https://github.com/changyuheng/zsh-interactive-cd
fi

# Syntax highlighting (zsh-users/zsh-syntax-highlighting)
source $ZSHPLUGGED/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Limit syntax highlighting to shorter inputs for better performance for longer inputs
ZSH_HIGHLIGHT_MAXLENGTH=100

# Autosuggestions (zsh-users/zsh-autosuggestions)
source $ZSHPLUGGED/zsh-autosuggestions/zsh-autosuggestions.zsh

# Completions (zsh-users/zsh-completions)
fpath=($ZSHPLUGGED/zsh-completions/src $fpath)
autoload -Uz compinit && compinit

# History substring searching (zsh-users/zsh-history-substring-search)
source $ZSHPLUGGED/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down

# z (rupa/z)
source $ZSHPLUGGED/z/z.sh

# cd (changyuheng/zsh-interactive-cd)
source $ZSHPLUGGED/zsh-interactive-cd/zsh-interactive-cd.plugin.zsh

# Use vi bindings
bindkey -v

# Enter normal mode from insert mode faster
export KEYTIMEOUT=1

# Add some emacs-like bindings to vi mode
bindkey '^A' vi-beginning-of-line
bindkey -M viins '^A' vi-beginning-of-line
bindkey -M vicmd '^A' vi-beginning-of-line
bindkey '^E' vi-end-of-line
bindkey -M viins '^E' vi-end-of-line
bindkey -M vicmd '^E' vi-end-of-line
bindkey '^[F' vi-forward-word
bindkey -M viins '^[F' vi-forward-word
bindkey -M vicmd '^[F' vi-forward-word
bindkey '^B' vi-backward-word
bindkey -M viins '^B' vi-backward-word
bindkey -M vicmd '^B' vi-backward-word
bindkey '^W' vi-backward-kill-word
bindkey -M viins '^W' vi-backward-kill-word
bindkey -M vicmd '^W' vi-backward-kill-word

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

# Fix terminal gruvbox colours
[ -f $HOME/.vim/plugged/gruvbox/gruvbox_256palette.sh ] && \
    source $HOME/.vim/plugged/gruvbox/gruvbox_256palette.sh

# Fix dmenu gruvbox colours
alias dmenu="dmenu ${DMENU_DEFAULT_OPTS}"
alias dmenu_run="dmenu_run ${DMENU_DEFAULT_OPTS}"

# Allow '>' redirection to overwrite existing files
setopt clobber

# Useful aliases
alias b="$BROWSER"
alias cp='cp -i'
alias e="$EDITOR"
alias ee="emacsclient -c -n"
alias g="git"
alias kgj="kubectl get jobs"
alias kgn="kubectl get nodes"
alias kgp="kubectl get pods"
alias l="ls -la --color"
alias ll="ls -l --color"
alias mv='mv -i'
alias open="$OPENER"
alias rg='rg --hidden --glob !.git'
alias rm='rm -i'
alias t="task"
alias to="taskopen"
alias vim="vimx"
alias zsh_setup_kubectl_autocompletion="source <(kubectl completion zsh)"

# ff = fuzzy file (and edit)
ff() (
    IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
    [[ -n "$files" ]] && $=EDITOR "${files[@]}"
)

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

# o (open argument or most used files; using fasd)
unalias o 2> /dev/null
o() {
    [ $# -eq 1 ] && test -e "$1" && ${OPENER} "$1" && return
    local file
    file="$(fasd -Rfl "$@" | fzf -1 -0 --no-sort +m)" && ${OPENER} "${file}" || return 1
}

# v (edit argument or most used files in vim; using viminfo)
v() {
    [ $# -eq 1 ] && test -e "$1" && $=EDITOR "$1" && return
    local files
    files=$(grep '^>' ~/.viminfo | cut -c3- |
        while read line; do
            [ -f "${line/\~/$HOME}" ] && echo "$line"
        done | fzf-tmux -d -m -q "$*" -1) && $=EDITOR ${files//\~/$HOME}
}

# Emacs vterm helper function
vterm_printf(){
    if [ -n "$TMUX" ] && ([ "${TERM%%-*}" = "tmux" ] || [ "${TERM%%-*}" = "screen" ] ); then
        # Tell tmux to pass the escape sequences through
        printf "\ePtmux;\e\e]%s\007\e\\" "$1"
    elif [ "${TERM%%-*}" = "screen" ]; then
        # GNU screen (screen, screen-256color, screen-256color-bce)
        printf "\eP\e]%s\007\e\\" "$1"
    else
        printf "\e]%s\e\\" "$1"
    fi
}

# Emacs vterm clean scrollback
if [[ "$INSIDE_EMACS" = 'vterm' ]]; then
    alias clear='vterm_printf "51;Evterm-clear-scrollback";tput clear'
fi
if [[ "$INSIDE_EMACS" = 'vterm' ]]; then
    function clear(){
        vterm_printf "51;Evterm-clear-scrollback";
        tput clear;
    }
fi

# Emacs vterm set buffer names after current directory
autoload -U add-zsh-hook
add-zsh-hook -Uz chpwd (){ print -Pn "\e]2;%2~\a" }

# Emacs vterm set directory tracking for M-x commands
vterm_prompt_end() {
    vterm_printf "51;A$(whoami)@$(hostname):$(pwd)";
}
setopt PROMPT_SUBST
PROMPT=$PROMPT'%{$(vterm_prompt_end)%}'

# Emacs vterm pass command
vterm_cmd() {
    local vterm_elisp
    vterm_elisp=""
    while [ $# -gt 0 ]; do
        vterm_elisp="$vterm_elisp""$(printf '"%s" ' "$(printf "%s" "$1" | sed -e 's|\\|\\\\|g' -e 's|"|\\"|g')")"
        shift
    done
    vterm_printf "51;E$vterm_elisp"
}

# SSH agent
# $(ssh-add -l | grep -q 'The agent has no identities') && ssh-add

# Prompt
eval "$(starship init zsh)"

# Fuzzy finder (installed via vim, so not using zinit packs)
[ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh

# Load local host customisations
[ -f $HOME/.zshrc.local ] && source $HOME/.zshrc.local

# Report on performance
[ $ZSHZPROF -gt 0 ] && zprof
