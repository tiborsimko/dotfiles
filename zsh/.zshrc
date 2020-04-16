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
bindkey '^B' vi-backward-word
bindkey -M viins '^B' vi-backward-word
bindkey -M vicmd '^B' vi-backward-word
bindkey '^W' vi-backward-kill-word
bindkey -M viins '^W' vi-backward-kill-word
bindkey -M vicmd '^W' vi-backward-kill-word

# python venv: using lazy wrapper for much faster shell startup times
[ -e /usr/bin/virtualenvwrapper_lazy.sh ] && source /usr/bin/virtualenvwrapper_lazy.sh

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
alias e="$EDITOR"
alias g="git"
alias k="kubectl"
alias open="$OPENER"
alias t="task"
alias to="taskopen"

# fix gruvbox colours
[ -f $HOME/.vim/plugged/gruvbox/gruvbox_256palette.sh ] && \
    source $HOME/.vim/plugged/gruvbox/gruvbox_256palette.sh

# do not share history between terminals with my tmux workflow
setopt no_share_history
unsetopt share_history

# allow '>' redirection to overwrite existing files
setopt clobber

# single-line pure prompt
prompt_newline='%666v'
PURE_PROMPT_SYMBOL='$'
PURE_PROMPT_VICMD_SYMBOL='#'
PROMPT=" $PROMPT"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
if [ -e /usr/share/fzf/completion.zsh ]; then
    source /usr/share/fzf/key-bindings.zsh
    source /usr/share/fzf/completion.zsh
fi

# fzf: ff = fuzzy file (and edit)
ff() (
  IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
  [[ -n "$files" ]] && ${EDITOR} "${files[@]}"
)

# fzf: fs = fuzzy search (string and edit matching files)
fs() {
  local file
  local line
  read -r file line <<<"$(ag --nobreak --noheading $@ | fzf -0 -1 | awk -F: '{print $1, $2}')"
  if [[ -n $file ]]
  then
    # note: uses nvim due to <https://github.com/liuchengxu/space-vim/issues/407>
    nvim $file +$line
  fi
}

# fzf: fv = fuzzy view (of a string in files)
fv() {
    if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
    local file
    file="$(rg --max-count=1 --ignore-case --files-with-matches --no-messages "$@" | fzf-tmux +m --preview="rg --ignore-case --pretty --context 10 '"$@"' {}")" && ${OPENER} "$file"
}

# fzf: o (open argument or most used files; using fasd)
unalias o 2> /dev/null
o() {
    [ $# -eq 1 ] && test -e "$1" && ${OPENER} "$1" && return
    local file
    file="$(fasd -Rfl "$@" | fzf -1 -0 --no-sort +m)" && ${OPENER} "${file}" || return 1
}

# fzf: v (edit argument or most used files in vim; using viminfo)
v() {
    [ $# -eq 1 ] && test -e "$1" && ${EDITOR} "$1" && return
    local files
    files=$(grep '^>' ~/.viminfo | cut -c3- |
        while read line; do
            [ -f "${line/\~/$HOME}" ] && echo "$line"
        done | fzf-tmux -d -m -q "$*" -1) && ${EDITOR} ${files//\~/$HOME}
}

# fzf: z (jump around most used directories; using fasd)
z() {
    [ $# -eq 1 ] && test -d "$1" && cd "$1" && return
    local dir
    dir="$(fasd -Rdl "$@" | fzf -1 -0 --no-sort +m)" && cd "${dir}" || return 1
}
