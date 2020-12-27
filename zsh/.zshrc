# Tibor's zshrc.

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit's installer chunk

# Syntax highlighting
zinit ice wait lucid atinit"zicompinit; zicdreplay"
zinit light zdharma/fast-syntax-highlighting

# Autosuggestions
zinit ice wait lucid atload"_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions

# Completions
zinit ice wait lucid blockf atpull'zinit creinstall -q .'
zinit light zsh-users/zsh-completions

# History substring searching
zinit ice wait lucid atload'__bind_history_keys'
zinit light zsh-users/zsh-history-substring-search
function __bind_history_keys() {
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^P' history-substring-search-up
    bindkey '^N' history-substring-search-down
}

# Abbreviations
if is-at-least 5.5; then
    zinit ice wait lucid
    zinit light olets/zsh-abbr
fi

# Fasd
eval "$(fasd --init auto)"

# z
zinit ice wait blockf lucid
zinit light rupa/z

# z tab completion
zinit ice wait lucid
zinit light changyuheng/fz

# z / fzf (ctrl-g)
zinit ice wait lucid
zinit light andrewferrier/fzf-z

# cd
zinit ice wait lucid
zinit light changyuheng/zsh-interactive-cd

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

# Python venv: using lazy wrapper for much faster shell startup times
[ -e /usr/bin/virtualenvwrapper_lazy.sh ] && source /usr/bin/virtualenvwrapper_lazy.sh

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

# Useful aliases
alias b="$BROWSER"
alias cp='cp -i'
alias e="$EDITOR"
alias g="git"
alias k="kubectl"
alias l="ls -la --color"
alias ll="ls -l --color"
alias mv='mv -i'
alias open="$OPENER"
alias rg='rg --hidden --glob !.git'
alias rm='rm -i'
alias t="task"
alias to="taskopen"

# Fix gruvbox colours
[ -f $HOME/.vim/plugged/gruvbox/gruvbox_256palette.sh ] && \
    source $HOME/.vim/plugged/gruvbox/gruvbox_256palette.sh

# Allow '>' redirection to overwrite existing files
setopt clobber

# ff = fuzzy file (and edit)
ff() (
    IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
    [[ -n "$files" ]] && ${EDITOR} "${files[@]}"
)

# fs = fuzzy search (string and edit matching files)
fs() {
    local file
    local line
    read -r file line <<<"$(ag --nobreak --noheading $@ | fzf -0 -1 | awk -F: '{print $1, $2}')"
    if [[ -n $file ]]; then
        ${EDITOR} $file +$line
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
    [ $# -eq 1 ] && test -e "$1" && ${EDITOR} "$1" && return
    local files
    files=$(grep '^>' ~/.viminfo | cut -c3- |
        while read line; do
            [ -f "${line/\~/$HOME}" ] && echo "$line"
        done | fzf-tmux -d -m -q "$*" -1) && ${EDITOR} ${files//\~/$HOME}
}

# Prompt
zinit ice pick"async.zsh" src"pure.zsh"
zinit light sindresorhus/pure
prompt_newline='%666v'
PURE_PROMPT_SYMBOL='$'
PURE_PROMPT_VICMD_SYMBOL='#'
PROMPT=" $PROMPT"

# SSH agent
$(ssh-add -l | grep -q 'The agent has no identities') && ssh-add

# Fuzzy finder (installed via vim, so not using zinit packs)
[ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh

# Load local host customisations
[ -f $HOME/.zshrc.local ] && source $HOME/.zshrc.local
