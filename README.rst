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
using operating system's package manager.

Usage
-----

First, clone this repository to new home:

.. code-block:: console

    $ cd $HOME
    $ git clone git@github.com:tiborsimko/dotfiles .dotfiles

Second, install any wanted software (such as ``tmux``) using your operating
system's package manager such as ``apt``, ``brew``, ``pacman`` or ``yum``:

.. code-block:: console

    $ pacman -S tmux vim zsh

Third, install Prezto (used for zsh), vim-plug and space-vim (used for vim):

.. code-block:: console

    $ # install Prezto (used for zsh):
    $ git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
    $ # install vim-plug (used for vim):
    $ curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    $ # install space-vim (used for vim):
    $ git clone https://github.com/liuchengxu/space-vim.git ~/.space-vim
    $ ln -s ~/.space-vim/init.vim ~/.vimrc

Finally, activate all wanted configurations (such as ``tmux``) via ``stow``:

.. code-block:: console

    $ stow tmux vim zsh
