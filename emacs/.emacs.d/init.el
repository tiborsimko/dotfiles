;;; init.el -- Tibor's Emacs configuration.

;; Copyright (C) 2020, 2021 Tibor Simko.

;;; Commentary:

;; This is Tibor's Emacs configuration.

;;; Code:

;; Bootstrap straight.el package manager
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Install use-package and bind-key
(straight-use-package 'use-package)

;; Configure use-package to install features via packages by default
(setq straight-use-package-by-default t)

;; Prefer eager over lazy loading for now
(setq use-package-always-defer nil)

;; Bind key helper
(use-package bind-key
  :demand t)

;; Configure garbage collection to happen when idle
(use-package gcmh
  :config
  (setq gcmh-verbose t))

;; Configure basic start-up things
(use-package emacs
  :straight nil
  :demand t
  :config
  ;; Do not show startup screen
  (setq inhibit-startup-screen t)
  ;; Use fully empty scratch buffer
  (setq initial-scratch-message "")
  ;; Use y/n instead of yes/no
  (fset 'yes-or-no-p 'y-or-n-p)
  ;; Prefer spaces over tabs
  (setq-default indent-tabs-mode nil)
  ;; Prefer visible rather than audible bell
  (setq visible-bell t)
  ;; Increase process read buffer size
  (setq read-process-output-max (* 1024 1024))
  ;; Reset garbage collection after startup
  (add-hook 'emacs-startup-hook #'gcmh-mode))

;; Keep ~/.emacs.d clean
(use-package no-littering
  :demand t
  :config
  ;; Configure recentf littering
  (require 'recentf)
  (add-to-list 'recentf-exclude no-littering-var-directory)
  (add-to-list 'recentf-exclude no-littering-etc-directory)
  ;; Configure auto-save littering
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))
  ;; Configure saved customisation littering
  (setq custom-file (no-littering-expand-etc-file-name "custom.el")))

;; Display column numbers in mode line
(use-package simple
  :straight nil
  :demand t
  :config
  (column-number-mode +1))

;; Support mouse
(use-package mwheel
  :straight nil
  :config
  (setq mouse-wheel-scroll-amount '(1 ((shift) . 1)))
  (setq mouse-wheel-progressive-speed nil))

;; Gruvbox color scheme
(use-package gruvbox-theme
  :demand t
  :config
  (custom-set-faces
   '(mode-line ((t (:background "#3c3836" :box nil))))
   '(mode-line-inactive ((t (:foreground "#928374" :background "#32302f" :box nil))))
   '(fringe ((t (:background "#1d2021"))))
   '(internal-border ((t (:background "#1d2021"))))
   '(hl-line ((t (:background "#282828"))))
   '(line-number ((t (:background "#1d2021"))))
   '(line-number-current-line ((t (:background "#1d2021")))))
  (load-theme 'gruvbox-dark-hard t))

;; Complete but compact mode line
(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :config
  (setq doom-modeline-icon nil
        doom-modeline-height 1))

;; Do not highlight current line (besides line number)
(use-package hl-line
  :straight nil
  :config
  (global-hl-line-mode -1))

;; Disable cursor blinking when running in terminal console
(setq visible-cursor nil)

;; Disable menu bar when running in terminal console
(menu-bar-mode -1)

;; Global text scaling that operates on all buffers
(use-package default-text-scale
  :config
  (default-text-scale-mode))

;; Update copyright statements in files
(use-package files
  :straight nil
  :demand t
  :config
  (add-hook 'before-save-hook 'copyright-update))

;; Balance parentheses
(use-package paren
  :straight nil
  :config
  (show-paren-mode +1))

;; Spell checking
(use-package flyspell
  :straight nil
  :config
  (add-hook 'text-mode-hook 'flyspell-mode))

;; Delete trailing whitespace before saving
(use-package whitespace
  :straight nil
  :config
  (add-hook 'before-save-hook 'whitespace-cleanup))

;; Remember file positions
(use-package saveplace
  :straight nil
  :demand t
  :config
  (save-place-mode +1))

;; Display relative line numbers
(use-package display-line-numbers
  :straight nil
  :demand t
  :config
  (setq display-line-numbers-type 'relative)
  (add-hook 'prog-mode-hook 'display-line-numbers-mode))

;; Ibuffer switching using more comfortable, longer buffer names. Good
;; for ibuffer.
(use-package ibuffer
  :straight nil
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

;; Dired jump
(use-package dired-x
  :straight nil
  :config
  (setq delete-by-moving-to-trash t)
  (bind-key "C-x d" #'dired-jump)
  (bind-key "C-x 4 d" #'dired-jump-other-window))

;; Set password cache and expiry time, e.g. useful for eshell sudo commands
(use-package password-cache
  :straight nil
  :config
  (setq password-cache t)
  (setq password-cache-expiry 3600))

;; Start server
(use-package server
  :straight nil
  :if window-system
  :config
  (unless (server-running-p)
    (server-start)))

;; Ensure environment variables in Emacs are the same as in shell
(use-package exec-path-from-shell
  :demand t
  :config
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize)))

;; Show key shortcut help
(use-package which-key
  :demand t
  :config
  (which-key-mode 1))

;; Vim mode
(use-package evil
  :init
  (setq evil-want-keybinding nil)
  (add-hook 'after-init-hook 'evil-mode))

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

;; Vim mode undo/redo
(use-package undo-fu
  :after evil
  :custom
  (evil-undo-system 'undo-fu))

;; Persistent undo/redo
(use-package undo-fu-session
  :after undo-fu
  :config
  (setq undo-fu-session-incompatible-files '("/COMMIT_EDITMSG\\'" "/git-rebase-todo\\'"))
  (global-undo-fu-session-mode))

;; Editing snippets
(use-package yasnippet
  :config
  (yas-global-mode 1))

(use-package yasnippet-snippets
  :after yasnippet)

;; Git integration
(use-package magit
  :commands magit-status
  :config
  (bind-key "C-x g" . #'magit-status))

;; Show git status in the gutter
(use-package git-gutter
  :config
  (add-hook 'prog-mode-hook 'git-gutter-mode))

;; Configure git fringe
(use-package git-gutter-fringe)

;; Tab bar mode
(use-package tab-bar
  :straight nil
  :config
  (setq tab-bar-close-button-show nil
        tab-bar-new-button-show nil
        tab-bar-new-tab-choice "*scratch*"
        tab-bar-show nil))

;; Repeat mode for quickly jump to other windows (C-x o o o) or other tabs (C-x t o o o) and more
(use-package repeat
  :straight nil
  :config
  (repeat-mode))

;; Helm completion framework
(use-package helm
  :config
  ;; Bind keys for common commands
  (bind-key "C-c h" #'helm-command-prefix)
  (bind-key "C-c h g" #'helm-google-suggest)
  (bind-key "C-c h o" #'helm-occur)
  (bind-key "C-c h x" #'helm-register)
  (bind-key "C-c h M-:" #'helm-eval-expression-with-eldoc)
  (bind-key "C-h SPC" #'helm-all-mark-rings)
  (bind-key "C-x C-f" #'helm-find-files)
  (bind-key "C-x b" #'helm-mini)
  (bind-key "M-y" #'helm-show-kill-ring)
  (bind-key "M-x" #'helm-M-x)
  ;; Rebind persistent action keys
  (bind-key "<tab>" #'helm-execute-persistent-action helm-map)
  (bind-key "C-i" #'helm-execute-persistent-action helm-map)
  (bind-key "C-z" #'helm-select-action helm-map)
  ;; Use current window for Helm sessions; useful for wide 27" external monitors
  (setq helm-split-window-inside-p t
        helm-echo-input-in-header-line t)
  ;; Use windows rather than frames for Helm completions
  (setq helm-show-completion-display-function 'helm-show-completion-default-display-function)
  ;; Activate Helm
  (helm-mode 1))

;; Helm ripgrep
(use-package helm-rg
  :after helm)

;; Helm for key bindings
(use-package helm-descbinds
  :after helm
  :config
  (helm-descbinds-mode))

;; Helm longer buffer names
(use-package helm-buffers
  :after helm
  :straight nil
  :config
  (setq helm-buffer-max-length 50))

;; Helm for Projectile
(use-package helm-projectile
  :after (helm projectile)
  :config
  (setq projectile-completion-system 'helm)
  (helm-projectile-on))

;; Helm password manager
(use-package helm-pass
  :after helm)

;; Helm selector for often used applications
(use-package helm-selector
  :after helm
  :preface

  ;; Helm selector for VTerm buffers
  (defun tibor/helm-selector-vterm ()
    "Helm for `VTerm' buffers."
    (interactive)
    (helm-selector
     "Vterm"
     :predicate (helm-selector-major-modes-predicate 'vterm-mode)
     :make-buffer-fn (lambda (&optional name)
                       (if name
                           (vterm (format "vterm: %s" name))
                         (vterm)))
     :use-follow-p t))
  (defun tibor/helm-selector-vterm-other-window ()
    "Like `tibor/helm-selector-vterm' but raise buffer in other window."
    (interactive)
    (let ((current-prefix-arg t))
      (call-interactively #'tibor/helm-selector-vterm)))

  :config
  (bind-key "C-c m" #'helm-selector-mu4e)
  (bind-key "C-c M" #'helm-selector-mu4e-other-window)
  (bind-key "C-c o" #'helm-selector-org)
  (bind-key "C-c O" #'helm-selector-org-other-window)
  (bind-key "C-c s" #'helm-selector-shell)
  (bind-key "C-c S" #'helm-selector-shell-other-window)
  (bind-key "C-c v" #'tibor/helm-selector-vterm)
  (bind-key "C-c V" #'tibor/helm-selector-vterm-other-window))

;; Project management
(use-package projectile
  :config
  (projectile-mode +1)
  (define-key projectile-mode-map (kbd "C-c p") #'projectile-command-map))

;; Richer documentation
(use-package helpful
  :config
  (bind-key [remap describe-command] #'helpful-command)
  (bind-key [remap describe-function] #'helpful-callable)
  (bind-key [remap describe-key] #'helpful-key)
  (bind-key [remap describe-variable] #'helpful-variable))

;; Expand region
(use-package expand-region
  :commands er/expand-region
  :config
  (bind-key "C-=" . #'er/expand-region))

;; Edit grep results
(use-package wgrep)

;; Ripgrep integration
(use-package rg
  :config
  (setq rg-keymap-prefix "\C-cr")
  (rg-enable-default-bindings))

;; Company completions
(use-package company
  :config
  (global-company-mode))

;; Org mode
(use-package org
  :straight nil
  :config
  (bind-key "C-c a" #'org-agenda)
  (setq org-directory "~/private/org/")
  (setq org-agenda-files '("~/private/org/"))
  (add-hook 'org-mode-hook 'visual-line-mode)
  (add-hook 'org-mode-hook 'auto-fill-mode)
  (add-hook 'org-mode-hook 'org-indent-mode)
  (add-hook 'org-mode-hook #'(lambda () (setq-local evil-auto-indent nil))))

(use-package org-capture
  :straight nil
  :config
  (bind-key "C-c c" #'org-capture)
  (setq org-capture-templates
        '(("j" "journal" entry (file+olp+datetree "journal.org")
           "** %U %?\n")
          ("t" "todo" entry (file+headline "todo.org" "Inbox")
           "* TODO %?\nSCHEDULED: %(org-insert-time-stamp (org-read-date nil t \"+0d\"))\n%a\n")
          ("e" "email" entry (file+headline "todo.org" "Email")
           "* TODO Reply on %a %?\nDEADLINE: %(org-insert-time-stamp (org-read-date nil t \"+2d\"))"))))

;; Org mode bullets
(use-package org-bullets
  :config
  (add-hook 'org-mode-hook 'org-bullets-mode))

;; Calendar
(use-package calendar
  :straight nil
  :config
  (setq calendar-week-start-day 1))

;; Mu4e mail system
(use-package mu4e
  :straight nil
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
          (:name "GitHub (cernopendata/reanahub)" :query "maildir:/Github and (subject:cernopendata or subject:reanahub)" :key ?g)
          (:name "GitHub (others)" :query "maildir:/Github not subject:cernopendata not subject:reanahub" :key ?G)
          (:name "Spam" :query "maildir:/Spam" :key ?s)
          (:name "Archive" :query "maildir:/Archive" :key ?a)
          (:name "Today (unread)" :query "date:today..now and flag:unread not maildir:/Github not maildir:/Spam" :key ?t)
          (:name "Today (all)" :query "date:today..now not maildir:/Github not maildir:/Spam" :key ?T)
          (:name "Week (unread)" :query "date:7d..now and flag:unread not maildir:/Github not maildir:/Spam" :key ?w)
          (:name "Week (all)" :query "date:7d..now not maildir:/Github not maildir:/Spam" :key ?W)))

  ;; Composing email snippet helper; adapted from
  ;; http://pragmaticemacs.com/emacs/email-templates-in-mu4e-with-yasnippet/
  (defun tibor/mu4e-get-names-for-yasnippet ()
    "Return comma-separated string of names for an email."
    (interactive)
    (let ((email-name "") str email-string email-list email-name2 tmpname)
      (save-excursion
        (goto-char (point-min))
        (setq str (buffer-substring-no-properties (point-min) (point-max))))
      (when (string-match "^To: \"?\\(.+\\)" str)
        (setq email-string (match-string 1 str)))
      (when (string-match "^Cc: \"?\\(.+\\)" str)
        (setq email-string (concat email-string ", " (match-string 1 str))))
      (setq email-list (split-string email-string " *, *"))
      (dolist (tmpstr (sort email-list #'string-lessp))
        (setq tmpname (car (split-string tmpstr " ")))
        (setq tmpname (replace-regexp-in-string "[ \"]" "" tmpname))
        (setq email-name
              (concat email-name ", " tmpname)))
      (setq email-name (replace-regexp-in-string "^, " "" email-name))
      (if (< (length email-list) 2)
          (when (string-match "^\\([^ ,\n]+\\).+writes:$" str)
            (progn (setq email-name2 (match-string 1 str))
                   (when (string-match "@" email-name)
                     (setq email-name email-name2)))))
      email-name))

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
(use-package python
  :config
  (setq python-shell-interpreter "ipython"
        python-shell-interpreter-args "-i --simple-prompt --InteractiveShell.display_page=True"))

;; Python vrtual environment support
(use-package pyvenv
  :config
  (setq pyvenv-mode-line-indicator '(pyvenv-virtual-env-name ("[venv:" pyvenv-virtual-env-name "] ")))
  (pyvenv-mode +1))

;; Python virtualwrapper tools for Eshell
(use-package virtualenvwrapper)

;; Python black code formatter
(use-package blacken)

;; Flycheck syntax checks
(use-package flycheck
  :config
  (setq flycheck-flake8rc "~/.config/flake8")
  (add-hook 'prog-mode-hook 'flycheck-mode))

;; LSP
(use-package lsp-mode
  :config
  (add-hook 'python-mode-hook 'lsp-mode)
  (define-key lsp-mode-map (kbd "C-c l") lsp-command-map))

;; LSP UI
(use-package lsp-ui
  :after lsp-mode
  :custom
  (lsp-ui-doc-position 'top)
  :config
  (add-hook 'lsp-mode-hook 'lsp-ui-mode))

;; LSP pyright
(use-package lsp-pyright
  :after lsp-mode
  :hook (python-mode . (lambda ()
                         (require 'lsp-pyright)
                         (lsp))))

;; Docker
(use-package docker)
(use-package dockerfile-mode)
(use-package docker-compose-mode)

;; Kubernetes
(use-package kubernetes
  :commands (kubernetes-overview))
(use-package kubernetes-evil
  :after kubernetes)

;; REST client
(use-package restclient)

;; PDF
(use-package pdf-tools)

;; TeX
(use-package tex
  :straight auctex
  :config
  (add-to-list 'TeX-view-program-selection '(output-pdf "Zathura")))

;; Markdown mode
(use-package markdown-mode)

;; Web mode
(use-package web-mode
  :config
  (add-to-list 'auto-mode-alist '("\\.html\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.css\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.json\\'" . web-mode)))

;; Rainbow mode for colour selection
(use-package rainbow-mode
  :config
  (add-hook 'web-mode-hook 'rainbow-mode))

;; Dumb jump to definition working with many programming modes
(use-package dumb-jump
  :custom
  (dumb-jump-selector 'helm)
  :config
  (add-hook 'xref-backend-functions #'dumb-jump-xref-activate))

;; Dictionary
(use-package dictionary)

;; Eshell
(use-package eshell
  :straight nil
  :after helm
  :config
  ;; Use Helm for Eshell history completion
  (add-hook 'eshell-mode-hook
            #'(lambda ()
                (bind-key "M-r" #'helm-eshell-history eshell-mode-map))))

;; Eshell terminals
(use-package em-term
  :straight nil
  :after eshell
  :config
  ;; Destroy eshell visual command buffers automatically when done.
  ;; Note: allows to press `q` to exit `git ka` for example; however
  ;; beware of a bug for short-lived processes, see the doctring
  (setq eshell-destroy-buffer-when-process-dies t)
  ;; Use leading v for any visual command such as mutt
  (defalias 'v 'eshell-exec-visual)
  ;; Define some known and frequently used visual commands
  (add-to-list 'eshell-visual-commands "alsamixer")
  (add-to-list 'eshell-visual-commands "watch")
  (add-to-list 'eshell-visual-commands "zsh")
  ;; Define git subcommands to always run in visual mode
  (setq eshell-visual-subcommands
        '(("git" "k" "ka" "log" "diff" "show"))))

;; Eshell sudo integration
(use-package em-tramp
  :straight nil
  :after eshell
  :config
  ;; Use Tramp for local sudo commands
  (add-to-list 'eshell-modules-list 'eshell-tramp))

;; Eshell internal vs external commands
(use-package esh-cmd
  :straight nil
  :after eshell
  :config
  ;; Prefer OS functions over Lisp functions in general
  (setq eshell-prefer-lisp-functions nil))

;; Eshell richer prompt
(use-package eshell-prompt-extras
  :after (eshell virtualenvwrapper)
  :config
  (with-eval-after-load "esh-opt"
    (require 'virtualenvwrapper)
    (venv-initialize-eshell)
    (autoload 'epe-theme-lambda "eshell-prompt-extras")
    (setq eshell-highlight-prompt nil
          eshell-prompt-function 'epe-theme-lambda)))

;; Eshell z
(use-package eshell-z
  :after eshell
  :config
  (add-hook 'eshell-mode-hook
            (defun my-eshell-mode-hook ()
              (require 'eshell-z))))

;; Eshell completion
(use-package fish-completion
  :after eshell
  :config
  (when (and (executable-find "fish")
             (require 'fish-completion nil t))
    (global-fish-completion-mode)))

;; Vterm terminal
(use-package vterm
  :after evil
  :config
  (defun tibor/evil-normal-in-vterm-copy-mode ()
    (if (bound-and-true-p vterm-copy-mode)
        (evil-normal-state)
      (evil-emacs-state)))
  ;; Switch off evil mode bindings in the shell prompt command line,
  ;; as they don't work well. The vi mode bindings in shell prompt
  ;; will be coming via zsh shell configuration
  (evil-set-initial-state 'vterm-mode 'emacs)
  ;; Use evil mode bindings in the output copy mode
  (add-hook 'vterm-copy-mode-hook 'tibor/evil-normal-in-vterm-copy-mode)
  ;; Switch off highlighting of the current line
  (add-hook 'vterm-mode-hook #'(lambda ()
                                 (setq-local global-hl-line-mode nil)
                                 (setq-local line-spacing nil)))
  ;; Set nice terminal name with current working directory
  (setq vterm-buffer-name-string "vterm %s"))

;; Window movement
(use-package windmove
  :straight nil
  :config
  (setq windmove-wrap-around t))

;; Window movements: more functionality
(use-package windower
  :config
  (bind-key "m" #'windower-toggle-single evil-window-map))

;; Window layout
(use-package winner
  :straight nil
  :after evil
  :config
  (bind-key "U" #'winner-redo evil-window-map)
  (bind-key "u" #'winner-undo evil-window-map)
  (winner-mode 1))

;; Window movement: fast switching
(use-package switch-window)

;; Window automatic resizing: golden ratio
(use-package golden-ratio)

;; Window transposer
(use-package transpose-frame
  :after evil
  :config
  (bind-key "t" #'transpose-frame evil-window-map))

;; Window helper buffer placement
(use-package popwin
  :config
  (popwin-mode 1))

;; Helper to set windows dedicated
(defun tibor/toggle-window-dedicated ()
  "Toggle window dedication flag. Useful for vterm buffers."
  (interactive)
  (message
   (if (let (window (get-buffer-window (current-buffer)))
         (set-window-dedicated-p window (not (window-dedicated-p window))))
       "%s is dedicated"
     "%s is not dedicated")
   (current-buffer)))

;; Local Variables:
;; byte-compile-warnings: (not free-vars unresolved)
;; End:

;;; init.el ends here
