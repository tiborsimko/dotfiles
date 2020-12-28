;;; init.el -- Tibor's Emacs configuration.

;; Copyright (C) 2020 Tibor Simko.

;;; Commentary:

;; This is Tibor's Emacs configuration.

;;; Code:

;; Define where to get Emacs packages from
(require 'package)
(add-to-list 'package-archives '("gnu"   . "https://elpa.gnu.org/packages/"))
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives '("org"   . "https://orgmode.org/elpa/"))

;; Load packages and activate them after reading init file
(setq package-enable-at-startup nil)
(package-initialize)

;; Get use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-and-compile
  (setq use-package-always-ensure t
        use-package-expand-minimally t))

;; Use y/n instead of yes/no
(use-package emacs
  :config
  (fset 'yes-or-no-p 'y-or-n-p)
  (setq visible-bell t))

;; Do not show startup screen
(use-package "startup"
  :ensure nil
  :config
  (setq inhibit-startup-screen t))

;; Do not show tool bar
(use-package tool-bar
  :ensure nil
  :config
  (tool-bar-mode -1))

;; Do not show menu bar
(use-package menu-bar
  :ensure nil
  :config
  (menu-bar-mode -1))

;; Do not show scroll bars
(use-package scroll-bar
  :ensure nil
  :config
  (scroll-bar-mode -1))

;; Display column numbers in mode line
(use-package simple
  :ensure nil
  :config
  (column-number-mode +1))

;; Support mouse
(use-package mwheel
  :ensure nil
  :config
  (setq mouse-wheel-scroll-amount '(1 ((shift) . 1)))
  (setq mouse-wheel-progressive-speed nil))

;; Set font and cursor
(use-package frame
  :preface
  (defun tibor/set-default-font ()
    (interactive)
    (when (member "Liberation Mono" (font-family-list))
      (set-face-attribute 'default nil :family "Liberation Mono"))
    (set-face-attribute 'default nil
                        :height 100
                        :weight 'normal))
  :ensure nil
  :config
  (blink-cursor-mode -1)
  (setq frame-resize-pixelwise t)
  (tibor/set-default-font))

;; Gruvbox color scheme
(use-package gruvbox-theme
  :custom-face
  (mode-line ((t (:background "#32302f"))))
  (mode-line-inactive ((t (:foreground "#928374" :background "#32302f"))))
  (fringe ((t (:background "#282828"))))
  (internal-border ((t (:background "#282828"))))
  (line-number ((t (:background "#282828"))))
  (line-number-current-line ((t (:background "#282828"))))
  :config
  (load-theme 'gruvbox t))

;; Prettier modeline
(use-package all-the-icons)
(use-package battery
  :config
  (display-battery-mode 1))
(use-package time
  :config
  (setq display-time-format " %H:%M")
  (display-time-mode))
(use-package doom-modeline
  :init (doom-modeline-mode 1))

;; Configure file behaviour
(use-package files
  :ensure nil
  :config
  ;; Set global backup directory
  (setq backup-directory-alist `(("." . ,(expand-file-name "backups" user-emacs-directory))))
  ;; Update copyright statements in files
  (add-hook 'before-save-hook 'copyright-update))

;; Prefer spaces over tabs
(setq-default indent-tabs-mode nil)

;; Balance parentheses
(use-package paren
  :ensure nil
  :config
  (show-paren-mode +1))

;; Spell checking
(use-package flyspell
  :ensure nil
  :config
  (add-hook 'text-mode-hook 'flyspell-mode))

;; Electric pair mode
(use-package elec-pair
  :ensure nil
  :hook (prog-mode . electric-pair-mode))

;; Delete trailing whitespace before saving
(use-package whitespace
  :ensure nil
  :hook (before-save . whitespace-cleanup))

;; Show key shortcut help
(use-package which-key
  :config
  (which-key-mode 1))

;; Remember file positions
(use-package saveplace
  :ensure nil
  :config
  (save-place-mode +1))

;; Display relative line numbers
(use-package display-line-numbers
  :ensure nil
  :hook (prog-mode . display-line-numbers-mode)
  :config
  (setq display-line-numbers-type 'relative))

;; Ensure environment variables in Emacs are the same as in shell
(use-package exec-path-from-shell
  :config
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize)))

;; Vim mode
(use-package evil
  :init
  (setq evil-want-keybinding nil)
  :hook (after-init . evil-mode))

;; Vim mode collections
(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;; Vim mode commenting
(use-package evil-commentary
  :after evil
  :config
  (evil-commentary-mode +1))

;; Dired jump
(use-package dired-x
  :ensure nil
  :bind (("C-x d" . dired-jump)
         ("C-x 4 d" . dired-jump-other-window))
  :config
  (setq delete-by-moving-to-trash t))

;; Git integration
(use-package magit
  :bind ("C-x g" . magit-status))

;; Show git status in the gutter
(use-package git-gutter
  :hook (prog-mode . git-gutter-mode))

;; Configure git fringe
(use-package git-gutter-fringe)

;; Ibuffer switching using more comfortable, longer buffer names. Good
;; for ibuffer in EXWM.
(use-package ibuffer
  :config
  (setq ibuffer-formats
        '((mark modified read-only " "
                (name 60 60 :left :elide)
                " "
                (size 9 -1 :right)
                " "
                (mode 16 16 :left :elide)
                " " filename-and-process)
          (mark " "
                (name 16 -1)
                " " filename))))

;; Helm completion framework
(use-package helm
  :bind
  ("C-c h" . helm-command-prefix)
  ;("C-c h g" . helm-google-suggest)
  ;("C-c h o" . helm-occur)
  ;("C-c h x" . helm-register)
  ;("C-c h M-:" . helm-eval-expression-with-eldoc)
  ("C-h SPC" . helm-all-mark-rings)
  ("C-x C-f" . helm-find-files)
  ("C-x b" . helm-mini)
  ("M-y" . helm-show-kill-ring)
  ("M-x" . helm-M-x)
  (:map shell-mode-map
        ("C-c C-l" . helm-comint-input-ring))
  (:map minibuffer-local-map
        ("C-c C-l" . helm-minibuffer-history))
  :config
  ;; Use current window for Helm sessions; useful for wide 27" external monitors
  (setq helm-split-window-inside-p t
        helm-echo-input-in-header-line t)
  ;; Use Helm for Eshell history
  (add-hook 'eshell-mode-hook
            #'(lambda ()
                (define-key eshell-mode-map (kbd "C-c C-l")  'helm-eshell-history)))
  ;; Activate Helm
  (helm-mode 1))

;; Helm for key bindings
(use-package helm-descbinds
  :config
  (helm-descbinds-mode))

;; Helm longer buffer names; good for EXWM buffers with long names such as Firefox
(use-package helm-buffers
  :after helm
  :ensure nil
  :config
  (setq helm-buffer-max-length 50))

;; Helm for Projectile
(use-package helm-projectile)

;; Helm password manager
(use-package helm-pass)

;; Project management
(use-package projectile
  :config
  (setq projectile-completion-system 'helm)
  (projectile-mode +1)
  (define-key projectile-mode-map (kbd "C-c p") #'projectile-command-map))

;; Richer documentation
(use-package helpful
  :bind
  ([remap describe-command] . helpful-command)
  ([remap describe-function] . helpful-callable)
  ([remap describe-key] . helpful-key)
  ([remap describe-variable] . helpful-variable))

;; Expand region
(use-package expand-region
  :bind ("C-=" . er/expand-region))

;; Edit grep results
(use-package wgrep)

;; Company completions
(use-package company
  :config
  (global-company-mode))

;; Org mode
(use-package org
  :hook ((org-mode . visual-line-mode)
         (org-mode . auto-fill-mode)
         (org-mode . org-indent-mode)
         (org-mode . (lambda () (setq-local evil-auto-indent nil))))
  :bind (("C-c a" . org-agenda))
  :config
  (setq org-directory "~/private/org/")
  (setq org-agenda-files '("~/private/org/")))

(use-package org-capture
  :ensure nil
  :bind (("C-c c" . org-capture))
  :config
  (setq org-capture-templates
        '(("j" "journal" entry (file+olp+datetree "journal.org")
           "** %U %?\n")
          ("t" "todo" entry (file+headline "todo.org" "Inbox")
           "* TODO %?\nSCHEDULED: %(org-insert-time-stamp (org-read-date nil t \"+0d\"))\n%a\n")
          ("e" "email" entry (file+headline "todo.org" "Email")
           "* TODO Reply on %a %?\nDEADLINE: %(org-insert-time-stamp (org-read-date nil t \"+2d\"))"))))

;; Org mode bullets
(use-package org-bullets
  :hook (org-mode . org-bullets-mode))

;; Mu4e mail system
(require 'mu4e) ;; mu4e comes with maildir-utils system package
(use-package mu4e
  :ensure nil
  :preface

  ;; Buffer switcher
  (defun tibor/switch-to-previous-buffer ()
    "Switch to previously open buffer.
    Repeated invocations toggle between the two most recently open buffers."
    (interactive)
    (switch-to-buffer (other-buffer (current-buffer) 1)))
  (global-set-key (kbd "C-c s") 'tibor/switch-to-previous-buffer)

  ;; Mu4e buffer switcher
  (defun tibor/switch-to-mu4e ()
    "Switch to mu4e headers buffer if it exists, otherwise start m4e."
    (interactive)
    (if (get-buffer "*mu4e-view*")
        (switch-to-buffer "*mu4e-view*")
      (if (get-buffer "*mu4e-headers*")
          (switch-to-buffer "*mu4e-headers*")
        (mu4e))))
  :bind (("C-c m" . tibor/switch-to-mu4e)
         ("C-x m" . tibor/switch-to-mu4e))
  :config

  ;; Message mode mail sending basic configuration
  (setq user-full-name "Tibor Simko"
        user-mail-address "tibor.simko@cern.ch"
        mail-host-address "tiborsimko.org"
        message-from-style 'angles)

  ;; Folder setup
  (setq mu4e-sent-folder   "/Archive"    ;; folder for sent messages
        mu4e-drafts-folder "/Drafts"     ;; unfinished messages
        mu4e-trash-folder  "/Trash"      ;; trashed messages
        mu4e-refile-folder "/Archive")   ;; saved messages

  ;; Fetching mail
  (setq mu4e-get-mail-command "x1-mbsync inbox archive"
        mu4e-update-interval nil)
  (setq mu4e-change-filenames-when-moving t) ; since I am using mbsync rather than offlineimap

  ;; Composing mail
  (remove-hook 'mu4e-compose-mode-hook #'org-mu4e-compose-org-mode)
  (setq mu4e-compose-signature "Best regards,\n\nTibor")
  (setq org-mu4e-convert-to-html nil)

  ;; MSMTP - Outging mail
  (setq sendmail-program "/usr/bin/msmtp"
        send-mail-function 'sendmail-send-it
        message-send-mail-function 'message-send-mail-with-sendmail
        message-sendmail-f-is-evil t
        message-sendmail-extra-arguments '("--read-envelope-from")
        message-send-mail-function 'message-send-mail-with-sendmail)

  ;; Reading email
  (setq mu4e-bookmarks
        '((:name "Unread" :query "flag:unread" :key ?u)
          (:name "Inbox (unread)" :query "maildir:/INBOX and flag:unread" :key ?i)
          (:name "Inbox (all)" :query "maildir:/INBOX" :key ?I)
          (:name "GitHub (unread)" :query "(maildir:/Github or from:notifications@github.com) and flag:unread" :key ?g)
          (:name "GitHub (all)" :query "(maildir:/Github or from:notifications@github.com)" :key ?G)
          (:name "Junk (unread)" :query "maildir:/Junk and flag:unread" :key ?j)
          (:name "Junk (all)" :query "maildir:/Junk" :key ?J)
          (:name "Archive (unread)" :query "maildir:/Archive and flag:unread" :key ?a)
          (:name "Archive (all)" :query "maildir:/Archive" :key ?A)
          (:name "Today (unread)" :query "date:today..now and flag:unread not maildir:/Github not from:notifications@github.com" :key ?t)
          (:name "Today (all)" :query "date:today..now not maildir:/Github not from:notifications@github.com" :key ?T)
          (:name "Week (unread)" :query "date:7d..now and flag:unread not maildir:/Github not from:notifications@github.com" :key ?w)
          (:name "Week (all)" :query "date:7d..now not maildir:/Github not from:notifications@github.com" :key ?W)))

  ;; UI viewing headers
  (setq mu4e-headers-fields
        '((:human-date . 9)
          (:flags . 4)
          (:maildir . 12)
          (:mailing-list . 20)
          (:from . 22)
          (:subject . nil)))

  ;; UI not to show dupes
  (setq mu4e-headers-skip-duplicates t)

  ;; UI not to use any fancy Unicode glyphs that are only taking space unnecessarily
  (setq mu4e-use-fancy-chars nil))

;; Python mode
(use-package python)

;; Python vrtual environment support
(use-package pyvenv
  :config
  (setq pyvenv-mode-line-indicator '(pyvenv-virtual-env-name ("[venv:" pyvenv-virtual-env-name "] ")))
  (pyvenv-mode +1))

;; Python black code formatter
(use-package blacken)

;; Flycheck syntax checks
(use-package flycheck
  :hook ((prog-mode   . flycheck-mode))
  :config
  (setq flycheck-flake8rc "~/.config/flake8"))

;; Docker
(use-package docker)
(use-package dockerfile-mode)
(use-package docker-compose-mode)

;; Kubernetes
(use-package kubernetes
  :commands (kubernetes-overview))
(use-package kubernetes-evil
  :after kubernetes)

;; PDF
(use-package pdf-tools)

;; TeX
(use-package tex
  :ensure auctex
  :config
  (add-to-list 'TeX-view-program-selection '(output-pdf "Zathura")))

;; Markdown mode
(use-package markdown-mode)

;; Web mode
(use-package web-mode
  :mode (("\\.html\\'" . web-mode)
         ("\\.css\\'"   . web-mode)
         ("\\.json\\'"  . web-mode)))

;; Rainbow mode for colour selection
(use-package rainbow-mode
  :hook (web-mode . rainbow-mode))

;; Dumb jump to definition working with many programming modes
(use-package dumb-jump
  :custom
  (dumb-jump-selector 'helm)
  :config
  (add-hook 'xref-backend-functions #'dumb-jump-xref-activate))

;; Dictionary
(use-package dictionary
  :bind ("C-c d" . dictionary-lookup-definition))

;; Eshell
(use-package eshell
  :config
  (defalias 'v 'eshell-exec-visual)
  (setq eshell-visual-subcommands
               '("git" "log" "diff" "show")))

;; Eshell richer prompt
(use-package virtualenvwrapper)
(use-package eshell-prompt-extras
  :after virtualenvwrapper
  :config
  (with-eval-after-load "esh-opt"
    (require 'virtualenvwrapper)
    (venv-initialize-eshell)
    (autoload 'epe-theme-lambda "eshell-prompt-extras")
    (setq eshell-highlight-prompt nil
          eshell-prompt-function 'epe-theme-lambda)))

;; Eshell z
(use-package eshell-z
  :config
  (add-hook 'eshell-mode-hook
            (defun my-eshell-mode-hook ()
              (require 'eshell-z))))

;; Eshell completion
(use-package fish-completion
  :config
  (when (and (executable-find "fish")
             (require 'fish-completion nil t))
    (global-fish-completion-mode)))

;; Vterm terminal
(use-package vterm
  :hook (vterm-mode . (lambda ()
                        (setq-local global-hl-line-mode nil)
                        (setq-local line-spacing nil))))

;; Vterm terminal popup
(use-package vterm-toggle
  :after evil
  :config
  (setq vterm-toggle-fullscreen-p nil)
  (with-eval-after-load 'evil
    (evil-set-initial-state 'vterm-mode 'emacs))
  (global-set-key (kbd "C-x t") #'vterm-toggle)
  (add-to-list 'display-buffer-alist
               '("^v?term.*"
                 (display-buffer-reuse-window display-buffer-at-bottom)
                 (reusable-frames . visible)
                 (window-height . 0.25))))

;; Start server
(use-package server
   :ensure nil
   :config
   (server-start))

;; Password cache
(use-package password-cache
  :config
  (setq password-cache t)
  (setq password-cache-expiry 3600))

;; Window movement
(use-package windmove
  :config
  (setq windmove-wrap-around t))

;; Window movement: more
(use-package windower)

;; Window layout
(use-package winner
  :bind (("<s-right>" . winner-redo)
         ("<s-left>" . winner-undo))
  :config
  (winner-mode 1))

;; Window movement: fast switching
(use-package switch-window)

;; Window automatic resizing: golden ratio
(use-package golden-ratio)

;; Windows transposer
(use-package transpose-frame)

;; Window helper buffer placement
(use-package popwin
  :config
  (popwin-mode 1))


(use-package desktop-environment
  :after exwm
  :config
  (setq desktop-environment-brightness-get-command "light")
  (setq desktop-environment-brightness-set-command "light %s")
  (setq desktop-environment-brightness-get-regexp "^\\([0-9]+\\)")
  (setq desktop-environment-brightness-normal-increment "-A 8")
  (setq desktop-environment-brightness-normal-decrement "-U 8")
  (setq desktop-environment-brightness-small-increment "-A 4")
  (setq desktop-environment-brightness-small-decrement "-U 4")
  (setf
   (alist-get (elt (kbd "s-l") 0) desktop-environment-mode-map nil t)
   nil)
  (desktop-environment-mode))

;; EXWM
(use-package exwm
  :config
  (require 'exwm)

  ;; Better X11 window titles for quick EXWM ibuffer switching
  (add-hook 'exwm-update-title-hook
            (lambda ()
                (exwm-workspace-rename-buffer (format "X11: %s: %s" exwm-class-name exwm-title))))

  ;; Don't isolate workspaces
  (setq exwm-workspace-show-all-buffers t
        exwm-layout-show-all-buffers t)

  ;; Multi-monitor support
  (require 'exwm-randr)
  (exwm-randr-enable)

  ;; Set keys to always pass through to Emacs
  (setq exwm-input-prefix-keys
        '(?\C-\
          ?\C-\M-j
          ?\C-h
          ?\C-u
          ?\C-w
          ?\C-x
          ?\M-&
          ?\M-:
          ?\M-`
          ?\M-x
          ?\M-y))

  ;; Set focus to follow mouse
  (setq mouse-autoselect-window t
        focus-follows-mouse t)

  ;; Set C-q so that the next key is sent to X11 applications directly
  (define-key exwm-mode-map [?\C-q] 'exwm-input-send-next-key)

  ;; Set up global key bindings regardless of input state
  (setq exwm-input-global-keys
        `(
          ;; s-R reset
          ([?\s-R] . exwm-reset)
          ;; s-W switch workspaces
          ([?\s-W] . exwm-workspace-switch)
          ;; s-r run X11 applications
          ([?\s-r] . (lambda (command)
                       (interactive (list (read-shell-command "$ ")))
                       (start-process-shell-command command nil command)))
          ;; s-N workspace switching
          ,@(mapcar (lambda (i)
                      `(,(kbd (format "s-%d" i)) .
                        (lambda ()
                          (interactive)
                          (exwm-workspace-switch-create ,i))))
                    (number-sequence 0 9))))

  ;; s-w switch to last workspace https://github.com/ch11ng/exwm/issues/784
  (defvar exwm-workspace--switch-history-hack (cons exwm-workspace-current-index '()))
  (add-hook 'exwm-workspace-switch-hook
            (lambda ()
              (setq exwm-workspace--switch-history-hack
                    (cons exwm-workspace-current-index
                          (car exwm-workspace--switch-history-hack)))))
  (defun exwm-workspace-switch-to-last ()
    (interactive)
    "Switch to the workspace that was used before current workspace"
    (exwm-workspace-switch (cdr exwm-workspace--switch-history-hack)))
  (exwm-input-set-key (kbd "s-w") #'exwm-workspace-switch-to-last)

  ;; s-hjkl Focus between windows
  (exwm-input-set-key (kbd "s-h") #'evil-window-left)
  (exwm-input-set-key (kbd "s-l") #'evil-window-right)
  (exwm-input-set-key (kbd "s-k") #'evil-window-up)
  (exwm-input-set-key (kbd "s-j") #'evil-window-down)

  ;; s-HJKL Move windows around
  (exwm-input-set-key (kbd "s-H") #'windower-swap-left)
  (exwm-input-set-key (kbd "s-L") #'windower-swap-right)
  (exwm-input-set-key (kbd "s-K") #'windower-swap-above)
  (exwm-input-set-key (kbd "s-J") #'windower-swap-below)

  ;; s-M-hjkl Resize windows
  (exwm-input-set-key (kbd "s-M-h") #'evil-window-decrease-width)
  (exwm-input-set-key (kbd "s-M-l") #'evil-window-increase-width)
  (exwm-input-set-key (kbd "s-M-k") #'evil-window-decrease-height)
  (exwm-input-set-key (kbd "s-M-j") #'evil-window-increase-height)

  ;; s-np Focus next/previous windows
  (exwm-input-set-key (kbd "s-n") #'evil-window-next)
  (exwm-input-set-key (kbd "s-p") #'evil-window-prev)

  ;; s-t Transpose window layout
  (exwm-input-set-key (kbd "s-t") #'transpose-frame)

  ;; s-m Maximise window
  (exwm-input-set-key (kbd "s-m") #'windower-toggle-single)

  ;; s-cC Delete window
  (exwm-input-set-key (kbd "s-c") #'delete-window)
  (exwm-input-set-key (kbd "s-C") #'kill-current-buffer)

  ;; s-s Switch to last buffer in the window
  (exwm-input-set-key (kbd "s-s") #'evil-switch-to-windows-last-buffer)

  ;; s-bB Switch buffers
  (exwm-input-set-key (kbd "s-b") #'helm-buffers-list)

  ; s-g Go to a buffer open in another frame
  (exwm-input-set-key (kbd "s-g") #'ido-switch-buffer-other-frame)

  ;; s-arrows Switch window layout
  (exwm-input-set-key (kbd "s-<right>") #'winner-redo)
  (exwm-input-set-key (kbd "s-<left>") #'winner-undo)

  ;; Enable EXWM
  (exwm-enable))

;; EXWM edit X11 input boxes in Emacs
(use-package exwm-edit
  :after exwm
  :config
  (defun tibor/exwm-edit-compose-hook ()
    "Switch to Markdown mode for EXWM edits."
    (funcall 'markdown-mode))
  (add-hook 'exwm-edit-compose-hook 'tibor/exwm-edit-compose-hook))

;;; init.el ends here
