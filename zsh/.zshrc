# Tibor's Prezto configuration.
#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...

# vi mode with some emacs bindings
set -o vi
bindkey '^A' vi-beginning-of-line
bindkey -M viins '^A' vi-beginning-of-line
bindkey -M vicmd '^A' vi-beginning-of-line
bindkey '^E' vi-end-of-line
bindkey -M viins '^E' vi-end-of-line
bindkey -M vicmd '^E' vi-end-of-line
bindkey '^[F' vi-forward-word
bindkey -M viins '^[F' vi-forward-word
bindkey -M vicmd '^[F' vi-forward-word
bindkey '^[B' vi-backward-word
bindkey -M viins '^[B' vi-backward-word
bindkey -M vicmd '^[B' vi-backward-word
bindkey '^W' vi-backward-kill-word
bindkey -M viins '^W' vi-backward-kill-word
bindkey -M vicmd '^W' vi-backward-kill-word

# python venv
if [ -e /usr/bin/virtualenvwrapper.sh ]; then
    source /usr/bin/virtualenvwrapper.sh
fi

# common customisations (PATH, PAGER and friends)
export PATH=$HOME/private/bin:$PATH
export EDITOR="vim"
export VISUAL="vim"
export PAGER="less -insMXRE"
export BROWSER="qutebrowser"
export TERMINAL="termite"
export LANG=C
export LC_ALL=en_GB.utf8

# fix for CERN LXPLUS7 self-compiled software (such as vim8)
if [[ -d $HOME/public/lxplus7/bin ]]; then
    export PATH=$HOME/public/lxplus7/bin:$PATH
fi

# shortcuts for some directories
setopt autonamedirs
r=$HOME/private/project/reana/src
o=$HOME/private/project/opendata/src/opendata.cern.ch
a=$HOME/private/project/analysispreservation/src/analysispreservation.cern.ch
i=$HOME/private/project/invenio/src

# cdr / cd to recent directories
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs

# fish-like search history
bindkey "^R" history-incremental-search-backward
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
bindkey -M vicmd "/" history-incremental-search-backward
bindkey -M vicmd "?" history-incremental-search-forward
bindkey -M vicmd "//" history-beginning-search-backward
bindkey -M vicmd "??" history-beginning-search-forward

# useful aliases
alias b="$BROWSER"
alias e="vim"
alias g="git"
alias t="task"
alias to="taskopen"
alias v="vim"
function v2 {
    tmux split-window -v "vim $@"
}
function v3 {
    tmux split-window -h "vim $@"
}

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# fzf with rg
if [ -e /usr//share/fzf/completion.zsh ]; then
    source /usr/share/fzf/key-bindings.zsh
    source /usr/share/fzf/completion.zsh
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
    export FZF_DEFAULT_OPTS='--extended'
fi

# fzf ibase16 gruvbox dark medium theme
_gen_fzf_default_opts() {
    local color00='#282828'
    local color01='#3c3836'
    local color02='#504945'
    local color03='#665c54'
    local color04='#bdae93'
    local color05='#d5c4a1'
    local color06='#ebdbb2'
    local color07='#fbf1c7'
    local color08='#fb4934'
    local color09='#fe8019'
    local color0A='#fabd2f'
    local color0B='#b8bb26'
    local color0C='#8ec07c'
    local color0D='#83a598'
    local color0E='#d3869b'
    local color0F='#d65d0e'

    export FZF_DEFAULT_OPTS="
      --color=bg+:$color01,bg:$color00,spinner:$color0C,hl:$color0D
      --color=fg:$color04,header:$color0D,info:$color0A,pointer:$color0C
      --color=marker:$color0C,fg+:$color06,prompt:$color0A,hl+:$color0D
    "
}

_gen_fzf_default_opts

# do not share history between terminals with my tmux workflow
setopt no_share_history
unsetopt share_history

# allow '>' redirection to overwrite existing files
setopt clobber

# single-line pure prompt
prompt pure
prompt_newline='%666v'
PURE_PROMPT_SYMBOL='$'
PURE_PROMPT_VICMD_SYMBOL='#'
PROMPT=" $PROMPT"

