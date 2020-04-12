# Tibor's Prezto configuration.
#
# Executes commands at login pre-zshrc.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

#
# Browser
#

export BROWSER="qutebrowser"

#
# Editors
#

export EDITOR="vim"
export VISUAL="vim"
export PAGER="less"

#
# Terminal
#

export TERMINAL="st"

#
# Opener
#

export OPENER="xdg-open"

#
# Language
#

if [[ -z "$LANG" ]]; then
  export LANG='en_GB.UTF-8'
fi

#
# Paths
#

# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath mailpath path

# Set the list of directories that cd searches.
# cdpath=(
#   $cdpath
# )

# Set the list of directories that Zsh searches for programs.
path=(
  /usr/local/{bin,sbin}
  $path
)

#
# Less
#

# Set the default Less options.
# Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
# Remove -X and -F (exit if the content fits on one screen) to enable it.
export LESS='-F -g -i -M -R -S -w -X -z-4'

# Set the Less input preprocessor.
# Try both `lesspipe` and `lesspipe.sh` as either might exist on a system.
if (( $#commands[(i)lesspipe(|.sh)] )); then
  export LESSOPEN="| /usr/bin/env $commands[(i)lesspipe(|.sh)] %s 2>&-"
fi

# private PATH additions
[ -d $HOME/private/bin ] && \
    export PATH=$HOME/private/bin:$PATH

# fix for CERN LXPLUS7 self-compiled software (such as tmux, vim)
[ -d $HOME/public/lxplus7/bin ] && export PATH=$HOME/public/lxplus7/bin:$PATH

# fix for CERN LXPLUS7 self-compiled libraries (such as libevent needed for tmux)
[ -d $HOME/public/lxplus7/lib ] && \
    export LD_LIBRARY_PATH=$HOME/public/lxplus7/lib:$LD_LIBRARY_PATH

# fzf with rg
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'

# fzf layout
export FZF_DEFAULT_OPTS='--layout=reverse --height 50%'

# fzf gruvbox dark medium theme
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
  --color=fg:#ebdbb2,bg:#282828,hl:#83a598
  --color=fg+:#ebdbb2,bg+:#3c3836,hl+:#83a598,gutter:#282828
  --color=info:#8ec07c,prompt:#7c6f64,pointer:#8ec07c
  --color=marker:#8ec07c,spinner:#8ec07c,header:#665c54
    '

# start X11 on tty1 after logging in
[[ -z $DISPLAY  ]] && [ "$(tty)" = "/dev/tty1" ] && exec startx
