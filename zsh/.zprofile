# Tibor's zprofile.

# Set prefereed programs
export EDITOR="emacsclient -t"
export VISUAL="emacsclient -t"
export BROWSER="qutebrowser"
export PAGER="less"
export TERMINAL="alacritty"
export OPENER="xdg-open"
export LANG="en_GB.UTF-8"

# Ensure path arrays do not contain duplicates
typeset -gU cdpath fpath mailpath path

# Set the list of directories that Zsh searches for programs
path=(
  /usr/local/{bin,sbin}
  $path
)

# Private PATH additions
[ -d $HOME/private/bin ] && \
    export PATH=$HOME/private/bin:$PATH

# Fix for CERN LXPLUS7 self-compiled software (such as tmux, vim)
[ -d $HOME/public/lxplus7/bin ] && export PATH=$HOME/public/lxplus7/bin:$PATH

# Fix for CERN LXPLUS7 self-compiled libraries (such as libevent needed for tmux)
[ -d $HOME/public/lxplus7/lib ] && \
    export LD_LIBRARY_PATH=$HOME/public/lxplus7/lib:$LD_LIBRARY_PATH

# Fzf with rg
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'

# Fzf layout
export FZF_DEFAULT_OPTS='--layout=reverse --height 50%'

# Fzf gruvbox dark theme
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
  --color=fg:#ebdbb2,bg:#1d2021,hl:#83a598
  --color=fg+:#ebdbb2,bg+:#3c3836,hl+:#83a598,gutter:#1d2021
  --color=info:#8ec07c,prompt:#7c6f64,pointer:#8ec07c
  --color=marker:#8ec07c,spinner:#8ec07c,header:#665c54
    '

# Dmenu gruvbox dark theme
export DMENU_DEFAULT_OPTS='-nb #111313 -nf #bdae93 -sb #111313 -sf #fbf1c7'

# Less
export LESS='-F -g -i -M -R -S -w -X -z-4'
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[00;47;30m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# Nix
if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then
    . $HOME/.nix-profile/etc/profile.d/nix.sh;
fi

# Start SSH agent
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

# Start X11 on tty1 after logging in
[[ -z $DISPLAY  ]] && [ "$(tty)" = "/dev/tty1" ] && exec startx
