# Tibor's zprofile.

# Use brew (cached for faster startup) - macOS only
if [[ -x /opt/homebrew/bin/brew ]]; then
    _brew_shellenv_cache="$HOME/.cache/zsh/brew-shellenv.zsh"
    if [[ ! -f "$_brew_shellenv_cache" ]] || [[ /opt/homebrew/bin/brew -nt "$_brew_shellenv_cache" ]]; then
        mkdir -p "${_brew_shellenv_cache:h}"
        /opt/homebrew/bin/brew shellenv > "$_brew_shellenv_cache"
    fi
    source "$_brew_shellenv_cache"
    unset _brew_shellenv_cache
fi

# Set system-level programs
export TERMINAL="alacritty"

# Ensure path arrays do not contain duplicates
typeset -gU cdpath fpath mailpath path

# Set the list of directories that Zsh searches for programs
path=(
  /usr/local/{bin,sbin}
  $path
)

# Enrich path to Nvim/Mason for Helix to use the same LSP servers, and Cargo and Go paths
export PATH=$HOME/.local/share/nvim/mason/bin:$HOME/.cargo/bin:$GOPATH/bin:/usr/local/go/bin:$PATH

# User PATH additions
[ -d $HOME/private/bin ] && export PATH=$HOME/private/bin:$PATH
[ -d $HOME/.local/bin ] && export PATH=$HOME/.local/bin:$PATH

# Fix for CERN LXPLUS7 self-compiled software (such as tmux, vim)
[ -d $HOME/public/lxplus7/bin ] && export PATH=$HOME/public/lxplus7/bin:$PATH

# Fix for CERN LXPLUS7 self-compiled libraries (such as libevent needed for tmux)
[ -d $HOME/public/lxplus7/lib ] && \
    export LD_LIBRARY_PATH=$HOME/public/lxplus7/lib:$LD_LIBRARY_PATH

# Start SSH agent
SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
export SSH_AUTH_SOCK

# Start WM on tty1 after logging in
[[ -z $DISPLAY  ]] && [ "$(tty)" = "/dev/tty1" ] && exec startx
