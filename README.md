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

### 1. Clone into `$HOME`

```console
git clone git@github.com:tiborsimko/dotfiles ~/.dotfiles
cd ~/.dotfiles
```

### 2. Install software

On Debian 12, you can use the `install.sh` helper script to provision software:

```console
./install.sh            # see help
./install.sh base-cli   # CLI packages
./install.sh base-gui   # GUI packages (optional)
./install.sh mise       # Runtime version manager
./install.sh rustup     # Rust toolchain
./install.sh starship   # Shell prompt
...                     # etc
```

On other Linux distributions or on macOS, install equivalent packages via the
native package manager.

### 3. Configure software

Run `./stow.sh` to link the dotfiles:

```console
./stow.sh
```

Alternatively, to activate a single package by hand:

```console
stow --no-folding tmux
```

## Testing

A disposable container provides a sandbox for verifying changes without
touching the host:

```console
make docker-build    # Build the test image
make docker-test     # Smoke test: stowed configs load cleanly
make docker-run      # Open an interactive shell in the container
```

The repo is bind-mounted into the container, so host edits are visible
without rebuilds.

## License

See [LICENSE](LICENSE).
