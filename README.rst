==================
 Tibor's dotfiles
==================

About
-----

This repository contains dotfiles to set up my personal GNU/Linux development
environment and configure several preferred applications.

- Editor: Vim
- Multiplexer: Tmux
- Shell: Zsh
- System monitor: Slstatus
- Terminal: St
- Theme: Gruvbox
- Window manager: Dwm

Tested on the following platforms:

- Android Termux
- Arch Linux
- CentOS

Screenshot
----------

.. figure:: https://raw.githubusercontent.com/tiborsimko/dotfiles/master/screenshot.png
   :alt: screenshot.png
   :align: center

Prerequisites
-------------

This repository uses `GNU Stow <https://www.gnu.org/software/stow/>`_ to manage
symbolic links to dotfiles. The ``stow`` package should be readily installable
using your operating system's package manager.

Usage
-----

First, clone this repository to new home:

.. code-block:: console

    $ cd $HOME
    $ git clone git@github.com:tiborsimko/dotfiles .dotfiles

Second, install any wanted software (such as ``tmux``, ``vim``, ``zsh``) using
your operating system's package manager (such as ``apt``, ``brew``, ``pacman``,
``yum``):

.. code-block:: console

    $ sudo pacman -S tmux vim zsh

Third, install tpm (used for tmux), vim-plug (used for vim), and prezto (used for zsh):

.. code-block:: console

    $ # install tpm (used for tmux):
    $ git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    $ # install vim-plug (used for vim):
    $ curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    $ # prepare some vim directories
    $ mkdir -p ~/.vim/undo
    $ # install prezto (used for zsh):
    $ git clone --recursive https://github.com/sorin-ionescu/prezto "${ZDOTDIR:-$HOME}/.zprezto"

Fourth, activate all wanted configurations (such as ``tmux``, ``vim``,
``zsh``) via ``stow``:

.. code-block:: console

    $ stow tmux vim zsh

Fifth, build and install dwm window manager and associated suckless tools; the
configuration is done during compile-time so don't use ``stow`` for these:

.. code-block:: console

    $ for app in dmenu dwm slock slstatus st; do \
        cd $app && make download clean build install && cd ..; \
      done
