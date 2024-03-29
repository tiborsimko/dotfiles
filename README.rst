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
- Terminal: XTerm
- Theme: Gruvbox
- Window manager: AwesomeWM

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

Third, install tpm (used for tmux), vim-plug (used for vim), and prepare
directories for zsh plugins (used for zsh) and mutt cache:

.. code-block:: console

    $ # zsh: prepare directories
    $ mkdir -p ~/.zsh/plugged ~/.cache/zsh
    $ # vim: install vim-plug
    $ mkdir -p ~/.vim/undo
    $ curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    $ # tmux: install tpm
    $ git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    $ # mutt: prepare cache directory
    $ mkdir -p ~/.cache/mutt

Fourth, activate all wanted configurations (such as ``tmux``, ``vim``,
``zsh``) via ``stow``:

.. code-block:: console

    $ stow --no-folding tmux vim zsh

Fifth, build and install Nix and Unclutter tools; the configuration is done
during compile-time so don't use ``stow`` for these:

.. code-block:: console

    $ for app in nix unclutter; do \
        cd $app && make download clean build install && cd ..; \
      done

Sixth, if necessary, copy system-wide files such as
``optimus-manager/foo`` into ``/foo`` on your laptop.
