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

;; Project management
(use-package projectile
  :config
  (setq projectile-completion-system 'ivy)
  (projectile-mode +1)
  (define-key projectile-mode-map (kbd "C-c p") #'projectile-command-map))

;; Ivy completion framework
(use-package ivy
  :bind (("<s-up>" . ivy-push-view)
         ("<s-down>" . ivy-switch-view))
  :config
  (setq ivy-use-virtual-buffers t)
  (setq ivy-count-format "(%d/%d) ")
  (ivy-mode 1))

;; Ivy richer selections
(use-package ivy-rich
  :init
  (ivy-rich-mode 1))

;; Counsel enhanced command working with Ivy
(use-package counsel
  :bind (("M-x" . counsel-M-x)
         ("C-x b" . counsel-ibuffer)
         ("C-x C-f" . counsel-find-file)
         ("C-M-l" . counsel-imenu)
         :map minibuffer-local-map
         ("C-r" . 'counsel-minibufer-history))
  :config
  (setq counsel-switch-buffer-preview-virtual-buffers nil)
  (counsel-mode 1))

;; Counsel support for Projectile
(use-package counsel-projectile
  :config
  (counsel-projectile-mode +1))

;; Swiper Ivy-enhanced search
(use-package swiper
  :after ivy
  :bind (("C-s" . swiper)))


;; Richer documentation
(use-package helpful
  :after counsel
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-command] . helpful-command)
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-key] . helpful-key)
  ([remap describe-variable] . counsel-describe-variable))

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

;; Dictionary
(use-package dictionary
  :bind ("C-c d" . dictionary-lookup-definition))

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

;;; init.el ends here
