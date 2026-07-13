# Tibor's dotfiles

## About

Personal configuration for my development environment, managed with
[GNU Stow](https://www.gnu.org/software/stow/).

- **Editor:** Neovim
- **Multiplexer:** Tmux
- **Prompt:** Starship
- **Runtime manager:** Mise
- **Shell:** Zsh
- **Terminal:** Alacritty
- **Theme:** Gruvbox
- **Window manager:** i3 (Linux); Aerospace (macOS)

## Installation

### 1. Clone the repository

```console
mkdir -p ~/Code/github.com/tiborsimko
git clone git@github.com:tiborsimko/dotfiles ~/Code/github.com/tiborsimko/dotfiles
cd ~/Code/github.com/tiborsimko/dotfiles
```

### 2. Install software

On Debian 13, you can use the `install.sh` helper script to provision software:

```console
./install.sh            # see help
./install.sh base-cli   # CLI packages
./install.sh base-gui   # GUI packages (optional)
./install.sh mise       # Runtime version manager
...                     # etc
```

On other Linux distributions or on macOS, install equivalent packages via the
native package manager.

### 3. Configure software

Run `./stow.sh all` to link the enabled dotfiles:

```console
./stow.sh all
```

Alternatively, to activate a single package by hand:

```console
./stow.sh tmux
```

### 4. Install mise-managed toolchain

Once the dotfiles are linked, install the development tools managed by Mise,
i.e. helm, kubectl, lazygit, nvim, several Python versions, etc:

```console
./install.sh mise-tools
```

## Testing

A disposable container provides a sandbox for verifying changes without
touching the host:

```console
make docker-build    # Build the test image
make docker-test     # Run dotfiles verification inside the container
make docker-run      # Open an interactive shell in the container
```

The repo is bind-mounted into the container, so host edits are visible
without rebuilds.

The same verification can be run directly on the host:

```console
./test.sh
```

## License

See [LICENSE](LICENSE).
