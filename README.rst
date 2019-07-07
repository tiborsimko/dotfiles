==================
 Tibor's dotfiles
==================

About
-----

This repository contains dotfiles to set up my personal GNU/Linux development
environment and configure several preferred applications.

- Editor: Emacs, Vim
- Multiplexer: Tmux
- Shell: Zsh
- System monitor: XMobar
- Terminal: Termite
- Theme: Gruvbox
- Window manager: XMonad

Tested on the following platforms:

- Arch Linux with Tmux/2.9, Vim/8.1, Zsh/5.7.
- CentOS 7 with Tmux/1.8, Vim/7.4, Zsh/5.0.

Screenshot
----------

FIXME

Prerequisites
-------------

This repository uses `GNU Stow <https://www.gnu.org/software/stow/>`_ to manage
symbolic links to dotfiles. The ``stow`` package should be readily installable
using operating system's package manager.

Usage
-----

First, clone this repository to new home:

```console
$ cd $HOME
$ git clone git@github.com:tiborsimko/dotfiles .dotfiles
```

Second, install any wanted software (such as ``tmux``) using your operating
system's package manager such as ``apt``, ``brew``, ``pacman`` or ``yum``:

```console
$ pacman -S tmux vim zsh
```

Third, install Prezto (used for zsh):

```console
$ # install Prezto (used for zsh):
$ git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
```

Finally, activate all wanted configurations (such as ``tmux``) via ``stow``:

```console
$ stow tmux vim zsh
```
