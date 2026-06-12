;;; init.el -- Tibor's Emacs configuration.

;; Copyright (C) 2020, 2021, 2022, 2025, 2026 Tibor Simko.

;;; Commentary:

;; This is Tibor's Emacs configuration.

;;; Code:

;; Restore startup performance overrides from early-init.el
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024))  ; 16MB
            (setq file-name-handler-alist default-file-name-handler-alist)))

;; Add Homebrew Emacs site-lisp packages to load-path (for mu4e, notmuch, etc.)
(let ((homebrew-site-lisp "/opt/homebrew/share/emacs/site-lisp"))
  (when (file-directory-p homebrew-site-lisp)
    (let ((default-directory homebrew-site-lisp))
      (normal-top-level-add-subdirs-to-load-path))))

;; Configure package manager

(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))
(package-initialize)
;(package-refresh-contents)

;; Native compilation settings
(when (and (fboundp 'native-comp-available-p)
           (native-comp-available-p))
  ;; Compile packages natively
  (setq native-comp-async-report-warnings-errors nil)  ; Don't show warnings
  (setq native-comp-deferred-compilation t)            ; Compile in background

  ;; Helper function to force recompile all packages
  (defun tibor/native-compile-all-packages ()
    "Native-compile all installed packages."
    (interactive)
    (native-compile-async "~/.config/emacs/elpa" 'recursively)))

;; Configure basic start-up things

(use-package emacs
  :ensure nil
  :config
  ;; macOS: Make both Cmd and Option act as Meta
  (when (eq system-type 'darwin)
    (setq mac-command-modifier 'super)      ; Cmd is Super (s-)
    (setq mac-option-modifier 'meta)        ; Option is Meta (M-)
    ;; Clear default macOS super key bindings (s-t=font, s-n=frame, etc.)
    (dolist (key '("s-a" "s-c" "s-d" "s-e" "s-f" "s-g" "s-h" "s-j" "s-k" "s-l"
                   "s-m" "s-n" "s-o" "s-p" "s-q" "s-s" "s-t" "s-u" "s-v" "s-w"
                   "s-x" "s-y" "s-z"))
      (global-unset-key (kbd key)))
    ;; Bind Cmd-specific keys for macOS convenience (copy/paste/etc)
    (global-set-key (kbd "s-c") 'kill-ring-save)  ; Cmd-c = copy
    (global-set-key (kbd "s-v") 'yank)            ; Cmd-v = paste
    (global-set-key (kbd "s-z") 'toggle-window-zoom)  ; Cmd-z = toggle window zoom (like tmux)
    (global-set-key (kbd "s-n") 'tibor/new-frame-with-eat)  ; Cmd-n = new frame with eat
    (global-set-key (kbd "s-k") 'tibor/switch-to-eat-buffer)  ; Cmd-k = switch to eat buffer
    (global-set-key (kbd "s-s") 'evil-buffer)  ; Cmd-s = switch to former buffer (like C-^)
    (global-set-key (kbd "s-b") 'consult-buffer)    ; Cmd-b = switch buffer
    (global-set-key (kbd "s-f") 'project-find-file) ; Cmd-f = find file in project
    (global-set-key (kbd "s-r") 'consult-recent-file) ; Cmd-r = recent files
    (global-set-key (kbd "s-/") 'consult-ripgrep)   ; Cmd-/ = ripgrep search in project
    (global-set-key (kbd "s-l") 'consult-line)      ; Cmd-l = search lines in buffer
    (global-set-key (kbd "s-o") 'other-window)      ; Cmd-o = other window
    (global-set-key (kbd "s-e") 'tibor/toggle-terminal-tabs) ; Cmd-e = expand/collapse eat buffers to tabs
    (global-set-key (kbd "s-g") 'magit-status)      ; Cmd-g = git status
    (global-set-key (kbd "s-d") 'dired-jump) ; Cmd-d = dired
    (global-set-key (kbd "s-p") 'project-switch-project) ; Cmd-p = switch project
    ;; Global font size adjustment
    (global-set-key (kbd "s-=") (lambda () (interactive) (global-text-scale-adjust 1)))   ; Cmd-+ = increase font size
    (global-set-key (kbd "s--") (lambda () (interactive) (global-text-scale-adjust -1)))  ; Cmd-- = decrease font size
    (global-set-key (kbd "s-0") (lambda () (interactive) (global-text-scale-adjust 0)))   ; Cmd-0 = reset font size
    ;; Tab switching with Cmd-1 through Cmd-9
    (global-set-key (kbd "s-1") (lambda () (interactive) (tab-bar-select-tab 1)))
    (global-set-key (kbd "s-2") (lambda () (interactive) (tab-bar-select-tab 2)))
    (global-set-key (kbd "s-3") (lambda () (interactive) (tab-bar-select-tab 3)))
    (global-set-key (kbd "s-4") (lambda () (interactive) (tab-bar-select-tab 4)))
    (global-set-key (kbd "s-5") (lambda () (interactive) (tab-bar-select-tab 5)))
    (global-set-key (kbd "s-6") (lambda () (interactive) (tab-bar-select-tab 6)))
    (global-set-key (kbd "s-7") (lambda () (interactive) (tab-bar-select-tab 7)))
    (global-set-key (kbd "s-8") (lambda () (interactive) (tab-bar-select-tab 8)))
    (global-set-key (kbd "s-9") (lambda () (interactive) (tab-bar-select-tab 9)))
    (global-set-key (kbd "s-w") (lambda () (interactive)
                                  (if (> (length (tab-bar-tabs)) 1)
                                      (tab-bar-close-tab)
                                    (if (> (length (frame-list)) 1)
                                        (delete-frame)
                                      (tab-bar-close-tab)))))
    (global-set-key (kbd "s-t") 'tibor/new-tab-with-eat)
    (global-set-key (kbd "s-<return>") 'tibor/new-split-with-eat))
  (setq inhibit-startup-screen t)
  (setq initial-scratch-message "")
  (fset 'yes-or-no-p 'y-or-n-p)
  (setq-default indent-tabs-mode nil)
  (setq ring-bell-function 'ignore)

  ;; macOS: Use GNU ls from coreutils (gls) instead of BSD ls
  (when (eq system-type 'darwin)
    (setq insert-directory-program "/opt/homebrew/bin/gls"))
  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (scroll-bar-mode -1)
  (tooltip-mode -1)
  (blink-cursor-mode -1)
  (column-number-mode +1)
  (global-auto-revert-mode 1)
  (savehist-mode 1)
  (save-place-mode 1)
  (show-paren-mode 1)  ; Highlight matching parentheses
  (electric-pair-mode 1)  ; Auto-close brackets, quotes, etc.

  ;; Protect against minified/long-line files killing performance
  (global-so-long-mode 1)

  ;; Pixel-perfect smooth scrolling (Emacs 29+)
  (when (fboundp 'pixel-scroll-precision-mode)
    (pixel-scroll-precision-mode 1))

  ;; macOS: Allow frame to use full screen height
  (when (eq system-type 'darwin)
    (setq frame-resize-pixelwise t))

  (setq read-process-output-max (* 1024 1024))
  (setq custom-file (concat user-emacs-directory "custom.el"))
  (setq calendar-week-start-day 1)
  (when (file-readable-p custom-file)
    (load custom-file))

  ;; Set font
  (set-face-attribute 'default nil :family "Aporetic Sans Mono" :weight 'regular :slant 'normal :width 'normal :height 150)
  (set-face-attribute 'fixed-pitch nil :family "Aporetic Sans Mono" :weight 'regular :height 1.0)
  (set-face-attribute 'variable-pitch nil :family "Aporetic Serif" :weight 'regular :height 1.0)

  ;; (set-face-attribute 'default nil :family "Iosevka Term SS06" :weight 'regular :slant 'normal :width 'normal :height 150)
  ;; (set-face-attribute 'fixed-pitch nil :family "Iosevka Term SS06" :weight 'regular :height 1.0)
  ;; (set-face-attribute 'variable-pitch nil :family "Iosevka SS06" :weight 'regular :height 1.0)

  ;; (set-face-attribute 'default nil :family "Iosevka Term SS14" :weight 'regular :slant 'normal :width 'normal :height 150)
  ;; (set-face-attribute 'fixed-pitch nil :family "Iosevka Term SS14" :weight 'regular :height 1.0)
  ;; (set-face-attribute 'variable-pitch nil :family "Iosevka SS14" :weight 'regular :height 1.0)

  ;; (set-face-attribute 'default nil :family "Iosevka Term" :weight 'regular :slant 'normal :width 'normal :height 150)
  ;; (set-face-attribute 'fixed-pitch nil :family "Iosevka Term" :weight 'regular :height 1.0)
  ;; (set-face-attribute 'variable-pitch nil :family "Iosevka" :weight 'regular :height 1.0)

  ;; Set frame title to [projectname] filename
  (setq frame-title-format
        '(:eval
          (let ((project (project-current)))
            (if project
                (format "[%s] %s"
                        (file-name-nondirectory
                         (directory-file-name
                          (project-root project)))
                        (buffer-name))
              (buffer-name)))))
  (setq icon-title-format nil)

  ;; Disable file icon (proxy icon) in title bar on macOS
  (when (eq system-type 'darwin)
    (setq ns-use-proxy-icon nil)
    ;; Make title bar match the theme
    (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
    ;; Apply to existing frame
    (set-frame-parameter nil 'ns-transparent-titlebar t))
  ;; Delete trailing whitespace before saving
  (add-hook 'before-save-hook 'whitespace-cleanup)
  ;; Backup and autosave settings
  (let ((backup-dir (expand-file-name "backups" user-emacs-directory))
        (autosave-dir (expand-file-name "auto-save" user-emacs-directory)))
    ;; Create backup directory if it doesn't exist
    (unless (file-exists-p backup-dir)
      (make-directory backup-dir t))
    ;; Create auto-save directory if it doesn't exist
    (unless (file-exists-p autosave-dir)
      (make-directory autosave-dir t))
    (setq backup-directory-alist `(("." . ,backup-dir)))
    (setq auto-save-file-name-transforms `((".*" ,autosave-dir t))))
  (setq create-lockfiles nil)  ; Disable lock files (.#filename)
  (setq backup-by-copying t)   ; Don't clobber symlinks
  (setq delete-old-versions t) ; Delete old backups
  (setq kept-new-versions 6)   ; Keep 6 newest versions
  (setq kept-old-versions 2)   ; Keep 2 oldest versions
  (setq version-control t)     ; Use versioned backups
  :hook
  (prog-mode . display-line-numbers-mode))

;; Ediff - keep control panel in same frame
(use-package ediff
  :ensure nil
  :config
  (setq ediff-window-setup-function 'ediff-setup-windows-plain)
  (setq ediff-split-window-function 'split-window-horizontally))

;; Recentf - recent files
(use-package recentf
  :ensure nil
  :config
  (setq recentf-max-saved-items 200)  ; Limit number of recent files
  (setq recentf-exclude '("/tmp/" "/ssh:" "COMMIT_EDITMSG"))  ; Exclude temp files
  (recentf-mode 1))

;; Expand region - smart text selection
;; Sync kill ring with system clipboard in TTY mode
(use-package xclip
  :ensure t
  :config
  (xclip-mode 1))

(use-package expand-region
  :ensure t
  :bind ("C-=" . er/expand-region))

;; Multiple cursors
(use-package multiple-cursors
  :ensure t
  :bind (("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-c C-<" . mc/mark-all-like-this)
         ("C-S-c C-S-c" . mc/edit-lines)))

;; Avy-based link hinting for URLs and commit hashes
(use-package avy
  :ensure t
  :demand t
  :config
  ;; URL regex (simplified version of ffap-url-regexp)
  (defvar tibor/url-regexp
    "https?://[^ \t\n\r<>\"'`]+"
    "Regexp to match HTTP/HTTPS URLs.")

  ;; Commit hash regex
  (defvar tibor/commit-hash-regexp
    "\\<[0-9a-f]\\{7,40\\}\\>"
    "Regexp to match git commit hashes.")

  ;; URL functions
  (defun tibor/avy-open-url ()
    "Use avy to select a URL and open it in browser."
    (interactive)
    (let ((original-pos (point)))
      (avy-with tibor/avy-open-url
        (avy-jump tibor/url-regexp))
      ;; avy-jump moves point on success
      (when (/= (point) original-pos)
        (let ((url (thing-at-point 'url t)))
          (when url
            (browse-url url)))
        (goto-char original-pos))))

  (defun tibor/avy-copy-url ()
    "Use avy to select a URL and copy it."
    (interactive)
    (let ((original-pos (point)))
      (avy-with tibor/avy-copy-url
        (avy-jump tibor/url-regexp))
      (when (/= (point) original-pos)
        (let ((url (thing-at-point 'url t)))
          (when url
            (kill-new url)
            (message "Copied: %s" url)))
        (goto-char original-pos))))

  ;; Commit hash functions
  (defun tibor/avy-open-commit-hash ()
    "Use avy to select a commit hash and open it in magit."
    (interactive)
    (let ((original-pos (point)))
      (avy-with tibor/avy-open-commit-hash
        (avy-jump tibor/commit-hash-regexp))
      (when (/= (point) original-pos)
        (let ((hash (thing-at-point 'word t)))
          (goto-char original-pos)
          (when (and hash (string-match-p "\\`[0-9a-f]\\{7,40\\}\\'" hash))
            (magit-show-commit hash))))))

  (defun tibor/avy-copy-commit-hash ()
    "Use avy to select a commit hash and copy it."
    (interactive)
    (let ((original-pos (point)))
      (avy-with tibor/avy-copy-commit-hash
        (avy-jump tibor/commit-hash-regexp))
      (when (/= (point) original-pos)
        (let ((hash (thing-at-point 'word t)))
          (when (and hash (string-match-p "\\`[0-9a-f]\\{7,40\\}\\'" hash))
            (kill-new hash)
            (message "Copied: %s" hash)))
        (goto-char original-pos))))

  ;; Word selection functions (for kubernetes pod names, etc.)
  (defvar tibor/word-regexp
    "[a-zA-Z0-9_-]\\{4,\\}"
    "Regexp to match words/identifiers (kubernetes pods, etc.).")

  (defun tibor/avy-insert-word ()
    "Use avy to select a word and insert it at point."
    (interactive)
    (let ((original-pos (point)))
      (avy-with tibor/avy-insert-word
        (avy-jump tibor/word-regexp))
      (when (/= (point) original-pos)
        (let ((word (when (looking-at tibor/word-regexp)
                      (match-string-no-properties 0))))
          (goto-char original-pos)
          (when word
            (insert word))))))

  (defun tibor/avy-copy-word ()
    "Use avy to select a word and copy it."
    (interactive)
    (let ((original-pos (point)))
      (avy-with tibor/avy-copy-word
        (avy-jump tibor/word-regexp))
      (when (/= (point) original-pos)
        (let ((word (when (looking-at tibor/word-regexp)
                      (match-string-no-properties 0))))
          (when word
            (kill-new word)
            (message "Copied: %s" word)))
        (goto-char original-pos))))

  ;; Global keybindings (lowercase = open/insert, uppercase = copy)
  :bind (("C-' o" . tibor/avy-open-url)
         ("C-' O" . tibor/avy-copy-url)
         ("C-' h" . tibor/avy-open-commit-hash)
         ("C-' H" . tibor/avy-copy-commit-hash)
         ("C-' w" . tibor/avy-insert-word)
         ("C-' W" . tibor/avy-copy-word)))

;; Color themes

;; Store current theme for new frames
(defvar tibor/current-theme nil
  "Currently active theme for applying customizations to new frames.")

(defun tibor/apply-theme-customizations (&optional frame)
  "Apply theme-specific customizations to FRAME (or all frames if nil)."
  (when tibor/current-theme
    (cond
     ;; Gruvbox dark theme customizations
     ((eq tibor/current-theme 'gruvbox-dark-hard)
      (set-face-attribute 'mode-line frame :background "#3c3836" :box nil)
      (set-face-attribute 'mode-line-inactive frame :foreground "#928374" :background "#32302f" :box nil)
      (set-face-attribute 'tab-bar frame :foreground "#928374" :background nil)
      (set-face-attribute 'tab-bar-tab frame :foreground "#ebdbb2" :background "#3c3836")
      (set-face-attribute 'tab-bar-tab-inactive frame :foreground "#928374" :background nil)
      (set-face-attribute 'fringe frame :background nil)
      (set-face-attribute 'internal-border frame :background nil)
      (set-face-attribute 'line-number frame :background nil)
      (set-face-attribute 'line-number-current-line frame :foreground "#fabd2f" :background nil)
      (set-face-attribute 'font-lock-comment-face frame :slant 'italic)
      (set-face-attribute 'font-lock-string-face frame :slant 'italic)
      ;; Set dark title bar appearance on macOS
      (when (eq system-type 'darwin)
        (set-frame-parameter frame 'ns-appearance 'dark)))
     ;; Gruvbox light theme customizations
     ((eq tibor/current-theme 'gruvbox-light-hard)
      (set-face-attribute 'mode-line frame :background "#d5c4a1" :box nil)
      (set-face-attribute 'mode-line-inactive frame :foreground "#928374" :background "#ebdbb2" :box nil)
      (set-face-attribute 'tab-bar frame :foreground "#928374" :background nil)
      (set-face-attribute 'tab-bar-tab frame :foreground "#282828" :background "#d5c4a1")
      (set-face-attribute 'tab-bar-tab-inactive frame :foreground "#928374" :background nil)
      (set-face-attribute 'fringe frame :background nil)
      (set-face-attribute 'internal-border frame :background nil)
      (set-face-attribute 'line-number frame :background nil)
      (set-face-attribute 'line-number-current-line frame :foreground "#b57614" :background nil)
      (set-face-attribute 'font-lock-comment-face frame :slant 'italic)
      (set-face-attribute 'font-lock-string-face frame :slant 'italic)
      ;; Set light title bar appearance on macOS
      (when (eq system-type 'darwin)
        (set-frame-parameter frame 'ns-appearance 'light)))
     ;; Add more theme customizations here as needed
     ;; Example: ((eq tibor/current-theme 'modus-vivendi) ...)
     )))

(defun tibor/load-theme (theme)
  "Disable all themes and load given THEME with optional customizations.
Supports special customizations for gruvbox-dark-hard and gruvbox-light-hard."
  (interactive
   (list
    (intern (completing-read "Load custom theme: "
                             (mapcar #'symbol-name
                                     (custom-available-themes))))))
  ;; Disable all currently active themes
  (mapc #'disable-theme custom-enabled-themes)
  ;; Load the selected theme
  (load-theme theme t)
  ;; Store the current theme
  (setq tibor/current-theme theme)
  ;; Apply theme-specific customizations to all frames
  (tibor/apply-theme-customizations nil))

;; Apply theme customizations to new frames and initial frame
(add-hook 'after-make-frame-functions #'tibor/apply-theme-customizations)
(add-hook 'window-setup-hook (lambda () (tibor/apply-theme-customizations nil)))

(use-package gruvbox-theme
  :ensure t
  :config
  (if t
      (tibor/load-theme 'gruvbox-light-hard)))

(use-package modus-themes
  :ensure t
  :config
  (if nil
      (tibor/load-theme 'modus-operandi)))

(use-package ef-themes
  :ensure t
  :config
  (if nil
      (tibor/load-theme 'ef-summer)))

(use-package doric-themes
  :ensure t
  :config
  (if nil
      (tibor/load-theme 'doric-earth)))

;; General - leader key setup

(use-package general
  :ensure t
  :config
  (general-create-definer tibor/leader-keys
    :states '(normal visual emacs)
    :keymaps 'override
    :prefix "SPC"
    :global-prefix "C-SPC"))

;; Evil

(use-package evil
  :ensure t
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-undo-system 'undo-redo)
  :config
  ;; Commenting functionality for single line
  (evil-define-key 'normal 'global (kbd "gcc")
                   (lambda ()
                     (interactive)
                     (if (not (use-region-p))
                         (comment-or-uncomment-region (line-beginning-position) (line-end-position)))))

  ;; Commenting functionality for multiple lines
  (evil-define-key 'visual 'global (kbd "gc")
                   (lambda ()
                     (interactive)
                     (if (use-region-p)
                         (comment-or-uncomment-region (region-beginning) (region-end)))))

  ;; Window navigation with Ctrl-hjkl
  ;; (evil-global-set-key 'normal (kbd "C-h") 'evil-window-left)
  ;; (evil-global-set-key 'normal (kbd "C-j") 'evil-window-down)
  ;; (evil-global-set-key 'normal (kbd "C-k") 'evil-window-up)
  ;; (evil-global-set-key 'normal (kbd "C-l") 'evil-window-right)

  ;; (evil-global-set-key 'insert (kbd "C-h") 'evil-window-left)
  ;; (evil-global-set-key 'insert (kbd "C-j") 'evil-window-down)
  ;; (evil-global-set-key 'insert (kbd "C-k") 'evil-window-up)
  ;; (evil-global-set-key 'insert (kbd "C-l") 'evil-window-right)

  ;; (evil-global-set-key 'visual (kbd "C-h") 'evil-window-left)
  ;; (evil-global-set-key 'visual (kbd "C-j") 'evil-window-down)
  ;; (evil-global-set-key 'visual (kbd "C-k") 'evil-window-up)
  ;; (evil-global-set-key 'visual (kbd "C-l") 'evil-window-right)

  ;; Activate evil mode
  (evil-mode 1))

(use-package evil-terminal-cursor-changer
  :ensure t
  :unless (display-graphic-p)
  :config
  (evil-terminal-cursor-changer-activate)
  ;; Restore beam cursor on exit
  (add-hook 'kill-emacs-hook (lambda () (send-string-to-terminal "\033[6 q"))))

(use-package evil-collection
  :after evil
  :ensure t
  :config
  (evil-collection-init)

  ;; Override mu4e bindings: use C-n/C-p instead of C-j/C-k for
  ;; message navigation. This allows C-j/C-k to be used for window
  ;; navigation.
  (with-eval-after-load 'mu4e
    (evil-define-key 'normal mu4e-headers-mode-map
      (kbd "C-n") 'mu4e-headers-next
      (kbd "C-p") 'mu4e-headers-prev
      (kbd "C-j") 'evil-window-down
      (kbd "C-k") 'evil-window-up
      (kbd "R") 'mu4e-compose-wide-reply)
    (evil-define-key 'normal mu4e-view-mode-map
      (kbd "C-n") 'mu4e-view-headers-next
      (kbd "C-p") 'mu4e-view-headers-prev
      (kbd "C-j") 'evil-window-down
      (kbd "C-k") 'evil-window-up
      (kbd "R") 'mu4e-compose-wide-reply)))

;; Windows

(use-package windmove
  :ensure nil
  :custom
  (windmove-wrap-around t))

;; Winner mode - window configuration history

(use-package winner
  :ensure nil
  :config
  (winner-mode 1)

  ;; Track zoom state for mode-line indicator
  (defvar window-zoomed-p nil
    "Non-nil when window is zoomed (like tmux zoom).")

  ;; Toggle window zoom (like tmux zoom)
  (defun toggle-window-zoom ()
    "Toggle between zoomed (single window) and unzoomed (previous layout).
Like tmux's zoom feature."
    (interactive)
    (if window-zoomed-p
        (progn
          (winner-undo)
          (setq window-zoomed-p nil))
      (delete-other-windows)
      (setq window-zoomed-p t))
    (force-mode-line-update t))

  ;; Add zoom indicator to mode-line (after buffer name)
  (setq-default mode-line-buffer-identification
                '((:eval (propertize "%12b" 'face 'mode-line-buffer-id))
                  (:eval (when window-zoomed-p " [Z]"))))

  ;; Bind C-w z to toggle-window-zoom (like tmux prefix-z)
  (with-eval-after-load 'evil
    (define-key evil-window-map (kbd "z") 'toggle-window-zoom)))

;; Tab bar with override mode to ensure M-1 through M-9 always work

;; Helper functions for M-t (needs to be defined before the mode)
(defun tibor/new-split-with-eat ()
  "Split window sensibly and open a new eat terminal in the same directory.
Uses a vertical split if the window is wide enough, horizontal otherwise."
  (interactive)
  (let ((dir default-directory))
    (if (> (window-width) (* 2 80))
        (split-window-right)
      (split-window-below))
    (other-window 1)
    (let ((default-directory dir))
      (eat nil '(4)))))

(defun tibor/new-tab-with-eat ()
  "Create a new tab and open a new eat terminal."
  (interactive)
  (let ((dir default-directory))
    (tab-bar-new-tab)
    (let ((default-directory dir))
      (eat nil '(4)))))

(defun tibor/new-frame-with-eat ()
  "Create a new frame and open a new eat terminal."
  (interactive)
  (let ((dir default-directory))
    (select-frame (make-frame))
    (let ((default-directory dir))
      (eat nil '(4)))))

(defun tibor/switch-to-eat-buffer ()
  "Switch to an eat buffer.
Buffers are shown in MRU order with the current buffer last, so pressing
s-k RET quickly toggles to the most recent other eat terminal."
  (interactive)
  (let* ((eat-buffers (cl-remove-if-not
                       (lambda (buf)
                         (with-current-buffer buf
                           (derived-mode-p 'eat-mode)))
                       (buffer-list)))
         (sorted (remove (current-buffer) eat-buffers)))
    (if sorted
        (switch-to-buffer
         (completing-read "Switch to eat: "
                          (mapcar #'buffer-name sorted)
                          nil t))
      (message "No eat buffers found"))))

(defun tibor/ws-first-buffer-name (ws)
  "Extract the first buffer name from window state WS."
  (when (and (consp ws) (listp (cdr ws)))
    (if (eq (car ws) 'buffer)
        (cadr ws)
      (cl-some #'tibor/ws-first-buffer-name
               (cl-remove-if-not #'consp ws)))))

(defun tibor/tab-displays-terminal-p (tab)
  "Return non-nil if TAB is displaying a terminal buffer."
  (let* ((ws (alist-get 'ws tab))
         (bufname (tibor/ws-first-buffer-name ws))
         (buf (and bufname (get-buffer bufname))))
    (and buf (with-current-buffer buf (derived-mode-p 'eat-mode)))))

(defun tibor/toggle-terminal-tabs ()
  "Toggle terminal buffers between tabs.
When other tabs display terminal buffers, close those tabs.
Otherwise, open each terminal buffer (except the current one) in a new tab.
Focus remains on the current tab."
  (interactive)
  (let* ((all-tabs (funcall tab-bar-tabs-function))
         (current-tab-index (tab-bar--current-tab-index all-tabs))
         (other-tabs (cl-remove-if
                      (lambda (tab) (eq (car tab) 'current-tab))
                      all-tabs))
         (terminal-tabs (cl-remove-if-not #'tibor/tab-displays-terminal-p other-tabs)))
    (if terminal-tabs
        ;; Collapse: close tabs displaying terminal buffers
        (let ((count (length terminal-tabs)))
          (dolist (tab (reverse terminal-tabs))
            (tab-bar-close-tab-by-name (alist-get 'name tab)))
          (message "Closed %d terminal tab(s)" count))
      ;; Expand: open each terminal buffer in a new tab, then return
      (let* ((current (current-buffer))
             (terminal-buffers (cl-remove-if-not
                                (lambda (buf)
                                  (and (not (eq buf current))
                                       (with-current-buffer buf
                                         (derived-mode-p 'eat-mode))))
                                (buffer-list))))
        (if (null terminal-buffers)
            (message "No other terminal buffers found")
          (dolist (buf terminal-buffers)
            (tab-bar-new-tab)
            (switch-to-buffer buf))
          (tab-bar-select-tab (1+ current-tab-index))
          (message "Opened %d terminal tab(s)"
                   (length terminal-buffers)))))))

(defun tibor/quick-switch-to-eat-buffer ()
  "Switch to the most recently used eat buffer without prompting.
If already in an eat buffer, switch to the next most recent one."
  (interactive)
  (let* ((eat-buffers (cl-remove-if-not
                       (lambda (buf)
                         (with-current-buffer buf
                           (derived-mode-p 'eat-mode)))
                       (buffer-list)))
         (sorted (remove (current-buffer) eat-buffers)))
    (if sorted
        (switch-to-buffer (car sorted))
      (message "No other eat buffers found"))))

(use-package tab-bar
  :ensure nil
  :config
  ;; Configure new tab to open scratch buffer instead of cloning current buffer
  (setq tab-bar-new-tab-choice "*scratch*"))

;; Workspaces

;; (use-package beframe
;;   :ensure t
;;   :hook (after-init . beframe-mode))

;; Which key

(use-package which-key
  :ensure t
  :hook
  (after-init . which-key-mode)
  :config
  (setq which-key-idle-delay 0.3))

;; Vertico

(use-package vertico
  :ensure t
  :hook
  (after-init . vertico-mode)
  :custom
  (vertico-count 10)
  (vertico-resize nil)
  (vertico-cycle nil))

;; Vertico directory - enhanced directory navigation
(use-package vertico-directory
  :ensure nil  ;; vertico-directory comes with vertico
  :after vertico
  :bind (:map vertico-map
              ("RET" . vertico-directory-enter)
              ("DEL" . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

;; Orderless

(use-package orderless
  :ensure t
  :defer t
  :after vertico
  :init
  (setq completion-styles '(orderless basic)))

;; Marginalia

(use-package marginalia
  :ensure t
  :hook
  (after-init . marginalia-mode))

;; Consult

(use-package consult
  :ensure t
  :defer t
  :init
  ;; Enhance register preview with thin lines and no mode line
  (advice-add #'register-preview :override #'consult-register-window)
  ;; Use Consult for xref locations with a preview feature
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  :config
  ;; Speed up file preview by using fundamental-mode (no syntax highlighting)
  (setq consult-preview-raw-size 0)  ; Always use simple preview
  (advice-add 'consult--find-file-temporarily-1 :around
              (lambda (orig-fun &rest args)
                (let ((treesit-auto-mode nil)  ; Disable tree-sitter during preview
                      (global-font-lock-mode nil)) ; Disable syntax highlighting
                  (apply orig-fun args)))))

;; Embark

(use-package embark
  :ensure t
  :defer t)

(use-package embark-consult
  :ensure t
  :after embark
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

;; Project management (built-in project.el)
(use-package project
  :ensure nil
  :config
  ;; Helper function to start eat in project root
  (defun tibor/project-eat ()
    "Start eat in the project root, or switch to existing eat session."
    (interactive)
    (let* ((pr (project-current t))
           (default-directory (project-root pr))
           (project-root (project-root pr))
           (eat-buffer-name (format "*term %s*"
                                    (file-name-nondirectory
                                     (directory-file-name project-root)))))
      ;; Check if an eat buffer for this project already exists
      (if-let ((existing-eat
                (seq-find (lambda (buf)
                           (and (with-current-buffer buf
                                  (and (derived-mode-p 'eat-mode)
                                       (equal (expand-file-name default-directory)
                                              (expand-file-name project-root))))))
                         (buffer-list))))
          (switch-to-buffer existing-eat)
        ;; Create new eat with project-specific name
        (eat nil eat-buffer-name))))

  ;; Add custom eat command to project switch menu
  (add-to-list 'project-switch-commands '(tibor/project-eat "Eat" "t") t)

  ;; Add keybindings for direct access to project commands
  (define-key project-prefix-map (kbd "t") 'tibor/project-eat))

;; Ibuffer - buffer list grouped by project
(use-package ibuffer-project
  :ensure t
  :after ibuffer
  :config
  (setq ibuffer-show-empty-filter-groups nil)

  ;; Auto-update ibuffer and group by project
  (add-hook 'ibuffer-hook
            (lambda ()
              (setq ibuffer-filter-groups (ibuffer-project-generate-filter-groups))
              (unless (eq ibuffer-sorting-mode 'project-file-relative)
                (ibuffer-do-sort-by-project-file-relative)))))

;; Helper functions for LazyVim-style bindings
(defun consult-ripgrep-word-at-point ()
  "Search for word at point in project using consult-ripgrep."
  (interactive)
  (let ((word (thing-at-point 'symbol t)))
    (if word
        (consult-ripgrep nil word)
      (consult-ripgrep))))

(defun kill-other-buffers ()
  "Kill all buffers except current one."
  (interactive)
  (mapc 'kill-buffer (delq (current-buffer) (buffer-list))))


;; Leader key bindings (SPC prefix) - LazyVim style
(tibor/leader-keys
  ;; Files (LazyVim style)
  "SPC" '(project-find-file :which-key "find files")
  "/" '(consult-ripgrep :which-key "grep (root dir)")
  "," '(consult-buffer :which-key "switch buffer")
  "." '(embark-act :which-key "embark act")
  "P" '(consult-yank-from-kill-ring :which-key "paste from kill ring")

  ;; Window operations (C-x muscle memory)
  "0" '(delete-window :which-key "delete window")
  "1" '(delete-other-windows :which-key "delete other windows")
  "2" '(split-window-below :which-key "split below")
  "3" '(split-window-right :which-key "split right")

  "f" '(:ignore t :which-key "file")
  "f f" '(project-find-file :which-key "find files (root)")
  "f F" '(find-file :which-key "find files (cwd)")
  "f r" '(consult-recent-file :which-key "recent")
  "f n" '(find-file :which-key "new file")

  ;; Buffers (LazyVim style)
  "b" '(:ignore t :which-key "buffer")
  "b b" '(consult-buffer :which-key "switch buffer")
  "b i" '(ibuffer :which-key "ibuffer (grouped by project)")
  "b d" '(kill-current-buffer :which-key "delete buffer")
  "b o" '(kill-other-buffers :which-key "delete other buffers")
  "b D" '(kill-buffer-and-window :which-key "delete buffer and window")

  ;; Search (LazyVim style)
  "s" '(:ignore t :which-key "search")
  "s l" '(consult-line :which-key "search lines")
  "s o" '(consult-outline :which-key "search outline")
  "s s" '(consult-imenu :which-key "search symbols")
  "s w" '(consult-ripgrep-word-at-point :which-key "search word (root dir)")
  "s g" '(consult-ripgrep :which-key "grep (root dir)")
  "s G" '(consult-grep :which-key "grep (cwd)")

  ;; Git (LazyVim style)
  "g" '(:ignore t :which-key "git")
  "g g" '(magit-status :which-key "status")
  "g s" '(magit-status :which-key "status")
  "g b" '(magit-blame-addition :which-key "blame line")
  "g f" '(magit-log-buffer-file :which-key "file history")
  "g l" '(magit-log-all :which-key "log")
  "g d" '(diff-hl-show-hunk :which-key "diff hunk")

  ;; Code (LazyVim style)
  "c" '(:ignore t :which-key "code")
  "c a" '(lsp-execute-code-action :which-key "code action")
  "c f" '(format-all-buffer :which-key "format")
  "c r" '(lsp-rename :which-key "rename")
  "c d" '(flymake-show-diagnostics-buffer :which-key "line diagnostics")

  ;; Diagnostics/Errors (LazyVim style)
  "x" '(:ignore t :which-key "diagnostics")
  "x x" '(consult-flymake :which-key "diagnostics")
  "x X" '(flymake-show-buffer-diagnostics :which-key "buffer diagnostics")

  ;; Project (project.el)
  "p" '(:ignore t :which-key "project")
  "p SPC" '(project-find-file :which-key "find file")
  "p p" '(project-switch-project :which-key "switch project")
  "p f" '(project-find-file :which-key "find file")
  "p b" '(project-switch-to-buffer :which-key "switch buffer")
  "p d" '(project-find-dir :which-key "find directory")
  "p k" '(project-kill-buffers :which-key "kill project buffers")
  "p s" '(consult-ripgrep :which-key "search project")
  "p t" '(tibor/project-eat :which-key "eat")

  ;; Mail
  "m" '(:ignore t :which-key "mail")
  "m m" '(tibor/mu4e-buffer-selector :which-key "mu4e selector")
  "m M" '(mu4e :which-key "mu4e")

  ;; UI toggles (LazyVim style)
  "u" '(:ignore t :which-key "ui")
  "u f" '(format-all-mode :which-key "toggle format")
  "u l" '(display-line-numbers-mode :which-key "toggle line numbers")

  ;; Help (emacs-kick style)
  "h" '(:ignore t :which-key "help")
  "h f" '(describe-function :which-key "describe function")
  "h v" '(describe-variable :which-key "describe variable")
  "h k" '(describe-key :which-key "describe key")
  "h m" '(describe-mode :which-key "describe mode")
  "h r" '(view-echo-area-messages :which-key "recent messages")

  ;; Avy select (lowercase=open/insert, uppercase=copy)
  "'" '(:ignore t :which-key "avy select")
  "' o" '(tibor/avy-open-url :which-key "open url")
  "' O" '(tibor/avy-copy-url :which-key "copy url")
  "' h" '(tibor/avy-open-commit-hash :which-key "open commit hash")
  "' H" '(tibor/avy-copy-commit-hash :which-key "copy commit hash")
  "' w" '(tibor/avy-insert-word :which-key "insert word")
  "' W" '(tibor/avy-copy-word :which-key "copy word")

  ;; Windows (LazyVim style)
  "w" '(:ignore t :which-key "windows")
  "w d" '(delete-window :which-key "delete window")
  "w w" '(other-window :which-key "other window")
  "w m" '(delete-other-windows :which-key "maximize")
  "w z" '(toggle-window-zoom :which-key "zoom")
  "-" '(split-window-below :which-key "split below")
  "|" '(split-window-right :which-key "split right")

  ;; Notes (custom)
  "n" '(:ignore t :which-key "notes")
  "n n" '(tibor/notes-goto-today :which-key "today's notes")
  "n c" '(tibor/notes-create-entry :which-key "create note entry")

  ;; Quit (LazyVim style)
  "q" '(:ignore t :which-key "quit")
  "q q" '(save-buffers-kill-terminal :which-key "quit all")

  ;; Test (LazyVim style)
  "t" '(:ignore t :which-key "test")
  "t t" '(:ignore t :which-key "run test at point")
  "t f" '(:ignore t :which-key "run file tests")
  "t p" '(:ignore t :which-key "run project tests")
  "t r" '(:ignore t :which-key "repeat last test")
  "t l" '(:ignore t :which-key "run last failed"))

;; Mode-specific test bindings
(defun tibor/setup-python-test-bindings ()
  "Set up test keybindings for Python modes."
  ;; SPC t bindings
  (tibor/leader-keys
    :keymaps '(python-mode-map python-ts-mode-map)
    "t t" '(python-pytest-run-def-or-class-at-point-dwim :which-key "run test at point")
    "t f" '(python-pytest-file-dwim :which-key "run file tests")
    "t p" '(python-pytest :which-key "run project tests")
    "t r" '(python-pytest-repeat :which-key "repeat last test")
    "t l" '(python-pytest-last-failed :which-key "run last failed"))
  ;; C-c t bindings
  (define-key python-mode-map (kbd "C-c t t") 'python-pytest-run-def-or-class-at-point-dwim)
  (define-key python-mode-map (kbd "C-c t f") 'python-pytest-file-dwim)
  (define-key python-mode-map (kbd "C-c t p") 'python-pytest)
  (define-key python-mode-map (kbd "C-c t r") 'python-pytest-repeat)
  (define-key python-mode-map (kbd "C-c t l") 'python-pytest-last-failed)
  (define-key python-ts-mode-map (kbd "C-c t t") 'python-pytest-run-def-or-class-at-point-dwim)
  (define-key python-ts-mode-map (kbd "C-c t f") 'python-pytest-file-dwim)
  (define-key python-ts-mode-map (kbd "C-c t p") 'python-pytest)
  (define-key python-ts-mode-map (kbd "C-c t r") 'python-pytest-repeat)
  (define-key python-ts-mode-map (kbd "C-c t l") 'python-pytest-last-failed))

(with-eval-after-load 'python
  (tibor/setup-python-test-bindings))

;; Go test bindings (works for both go-mode and go-ts-mode)
(defun tibor/setup-go-test-bindings ()
  "Set up test keybindings for Go modes."
  ;; SPC t bindings for both go-mode-map and go-ts-mode-map
  (tibor/leader-keys
    :keymaps '(go-mode-map go-ts-mode-map)
    "t t" '(go-test-current-test :which-key "run test at point")
    "t f" '(go-test-current-file :which-key "run file tests")
    "t p" '(go-test-current-project :which-key "run project tests")
    "t b" '(go-test-current-benchmark :which-key "run benchmark at point")
    "t c" '(go-test-current-coverage :which-key "run with coverage"))

  ;; C-c t bindings for go-mode-map
  (when (boundp 'go-mode-map)
    (define-key go-mode-map (kbd "C-c t t") 'go-test-current-test)
    (define-key go-mode-map (kbd "C-c t f") 'go-test-current-file)
    (define-key go-mode-map (kbd "C-c t p") 'go-test-current-project)
    (define-key go-mode-map (kbd "C-c t b") 'go-test-current-benchmark)
    (define-key go-mode-map (kbd "C-c t c") 'go-test-current-coverage))

  ;; C-c t bindings for go-ts-mode-map
  (when (boundp 'go-ts-mode-map)
    (define-key go-ts-mode-map (kbd "C-c t t") 'go-test-current-test)
    (define-key go-ts-mode-map (kbd "C-c t f") 'go-test-current-file)
    (define-key go-ts-mode-map (kbd "C-c t p") 'go-test-current-project)
    (define-key go-ts-mode-map (kbd "C-c t b") 'go-test-current-benchmark)
    (define-key go-ts-mode-map (kbd "C-c t c") 'go-test-current-coverage)))

(with-eval-after-load 'go-mode
  (tibor/setup-go-test-bindings))

(with-eval-after-load 'go-ts-mode
  (tibor/setup-go-test-bindings))

;; Org mode

(use-package org
  :ensure nil
  :config
  (bind-key "C-c a" #'org-agenda)
  (setq org-directory "~/private/org/")
  (setq org-agenda-files (list org-directory))
  (setq org-agenda-file-regexp "\\`todo.*\\.org\\'")
  (setq org-todo-keywords
        '((sequence "TODO(t)" "STARTED(s!)" "WAITING(w!)" "|" "CANCELLED(c!)" "DONE(d!)")))
  (setq org-tag-alist '(("reana" . ?r) ("opendata" . ?o) ("ntupling" . ?n) ("eosc" . ?e) ("cern" . ?c) ("it" . ?i) ("personal" . ?p) ("team" . ?t)))
  (setq org-auto-align-tags nil)
  (setq org-tags-column 0)
  (setq org-M-RET-may-split-line '((default . nil)))
  (setq org-insert-heading-respect-content t)
  (setq org-log-done nil)
  (setq org-log-into-drawer t)
  (add-hook 'org-mode-hook 'visual-line-mode)
  ;; Disable auto-fill-mode to keep long lines (soft-wrap only, no hard breaks)
  ;; (add-hook 'org-mode-hook 'auto-fill-mode)
  (add-hook 'org-mode-hook 'org-indent-mode)
  (with-eval-after-load 'evil
    (evil-set-initial-state 'org-mode 'insert))

  ;; Enable markdown export backend
  (require 'ox-md)

  ;; Disable table of contents in markdown export by default
  (setq org-md-toplevel-hlevel 1)

  ;; Quick export current subtree to markdown
  (defun tibor/org-export-subtree-to-markdown ()
    "Export the current org subtree to markdown buffer without table of contents."
    (interactive)
    (let ((org-export-with-toc nil))  ; Disable table of contents
      (org-md-export-as-markdown nil t)))

  ;; Keybinding for quick markdown export of subtree
  (define-key org-mode-map (kbd "C-c m") 'tibor/org-export-subtree-to-markdown))

(use-package org-capture
  :ensure nil
  :config
  (bind-key "C-c c" #'org-capture)
  (setq org-capture-templates
        '(("j" "journal" entry (file "journal.org")
           "* %U %?\n")
          ("t" "todo" entry (file "todo.org")
           "* TODO %?\nSCHEDULED: %(org-insert-time-stamp (org-read-date nil t \"+0d\"))\n%a\n")
          ("m" "mail" entry (file "todo.org")
           "* TODO Reply to %:fromname on %a %?\nDEADLINE: %(org-insert-time-stamp (org-read-date nil t \"+2d\"))"))))

;; Custom agenda command for untagged TODOs
(use-package org-agenda
  :ensure nil
  :after org
  :config
  (add-to-list 'org-agenda-custom-commands
               '("u" "Uncategorised todo items" alltodo ""
                 ((org-agenda-skip-function
                   (lambda ()
                     (let ((tags (org-get-tags)))
                       (if tags
                           (progn (outline-next-heading) (point))
                         nil))))
                  (org-agenda-overriding-header "Uncategorised todo items:")))))

;; ;; Org mode bullets
;; (use-package org-bullets
;;   :config
;;   (add-hook 'org-mode-hook 'org-bullets-mode))

;; Mail

;; Mu4e buffer selector (similar to helm-selector-mu4e)
(defun tibor/mu4e-buffer-selector ()
  "Jump to mu4e-headers, mu4e-main, or open mu4e if none exist.
Similar to helm-selector-mu4e, this provides quick access to mu4e."
  (interactive)
  (let ((headers-buf (get-buffer "*mu4e-headers*"))
        (main-buf (get-buffer "*mu4e-main*")))
    (cond
     (headers-buf (switch-to-buffer headers-buf))
     (main-buf (switch-to-buffer main-buf))
     (t (mu4e)))))

(use-package mu4e
  :ensure nil
  :init
  ;; Set mu binary path explicitly for GUI-launched Emacs
  (setq mu4e-mu-binary "/opt/homebrew/bin/mu")
  :config
  ;; Disable notifications in terminal mode to prevent "Window system is not in use" errors
  (unless (display-graphic-p)
    (setq mu4e-notification-support nil))

  ;; Message mode mail sending basic configuration
  (setq user-full-name "Tibor Simko"
        user-mail-address "tibor.simko@cern.ch"
        mail-host-address "tiborsimko.org"
        message-user-fqdn "tiborsimko.org"
        mu4e-personal-addresses '("tibor.simko@cern.ch"))

  ;; Folder setup
  (setq mu4e-sent-folder   "/Archive"    ;; sent messages
        mu4e-drafts-folder "/Drafts"     ;; unfinished messages
        mu4e-trash-folder  "/Trash"      ;; trashed messages
        mu4e-refile-folder "/Archive")   ;; saved messages

  ;; Fetching mail
  (setq mu4e-get-mail-command "x1-mbsync inbox archive"
        mu4e-update-interval nil)
  (setq mu4e-change-filenames-when-moving t) ; since I am using mbsync rather than offlineimap

  ;; Prefer plain text messages
  (setq mm-discouraged-alternatives '("text/html" "text/richtext"))

  ;; Render HTML emails with shr (built-in) for TTY
  (setq mm-text-html-renderer 'shr)
  (setq shr-use-colors nil)
  (setq shr-use-fonts nil)

  ;; Open PDF attachments with macOS default viewer
  (with-eval-after-load 'mailcap
    (mailcap-add "application/pdf" "open '%s'"))

  ;; Composing mail
  (remove-hook 'mu4e-compose-mode-hook #'org-mu4e-compose-org-mode)

  ;; Don't ask for context when composing - use the default/current context
  (setq mu4e-compose-context-policy 'pick-first)

  ;; Don't prompt for "from" address since we only have one
  (remove-hook 'mu4e-compose-pre-hook #'+mu4e-set-from-address-h)

  ;; Customize reply citation line format
  (setq message-citation-line-function 'message-insert-formatted-citation-line
        message-citation-line-format "On %a, %d %b %Y at %R, %N wrote:")

  ;; Disable automatic signature insertion
  (setq message-signature nil
        mu4e-compose-signature nil)

  ;; Extract names from To/Cc headers for greeting (used by yasnippet)
  (defun tibor/mu4e-get-recipient-names ()
    "Return comma-separated string of recipient names for greeting."
    (let ((email-name "") str email-string email-list tmpname name-list)
      (save-excursion
        (goto-char (point-min))
        (setq str (buffer-substring-no-properties (point-min) (point-max))))
      ;; Get To: recipients
      (when (string-match "^To: \"?\\(.+\\)" str)
        (setq email-string (match-string 1 str)))
      ;; Add Cc: recipients
      (when (string-match "^Cc: \"?\\(.+\\)" str)
        (setq email-string (concat email-string ", " (match-string 1 str))))
      ;; Parse email list and extract names
      (when email-string
        (setq email-list (split-string email-string " *, *"))
        (setq name-list '())
        (dolist (tmpstr email-list)
          (setq tmpname (car (split-string tmpstr " ")))
          (setq tmpname (replace-regexp-in-string "[ \"]" "" tmpname))
          ;; If tmpname is just an email (contains @), extract first name before . or @
          (when (and (string-match "@" tmpname)
                     (string-match "^<?\\([^.@]+\\)[.@]" tmpname))
            (setq tmpname (match-string 1 tmpname)))
          ;; Capitalize first letter of the name
          (setq tmpname (capitalize tmpname))
          (push tmpname name-list))
        ;; Sort names alphabetically and join with commas
        (setq email-name (mapconcat 'identity (sort name-list #'string-lessp) ", "))
        ;; For single recipient, try to extract from citation line if name looks like email
        (when (< (length email-list) 2)
          (when (string-match "^\\([^ ,\n]+\\).+wrote:$" str)
            (let ((email-name2 (match-string 1 str)))
              (when (string-match "@" email-name)
                (setq email-name email-name2))))))
      email-name))

  ;; Add custom signature manually via hook
  (defun tibor/insert-email-signature ()
    "Insert email signature without the standard '-- ' separator."
    (save-excursion
      (goto-char (point-max))
      (insert "\n\nBest regards,\n\nTibor")))

  (add-hook 'mu4e-compose-mode-hook #'tibor/insert-email-signature)

  (setq org-mu4e-convert-to-html nil)

  ;; MSMTP - Outging mail
  (setq sendmail-program "/opt/homebrew/bin/msmtp"
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
          (:name "GitHub (purge)" :query "maildir:/Github and flag:unread and (subject:puppet or subject:inveniosoftware or subject:inspire or subject:cds-videos)" :key ?p)
          (:name "GitHub (unread)" :query "maildir:/Github and flag:unread" :key ?g)
          (:name "GitHub (all)" :query "maildir:/Github" :key ?G)
          (:name "Spam" :query "maildir:/Spam" :key ?s)
          (:name "Archive" :query "maildir:/Archive" :key ?a)
          (:name "Today (unread)" :query "date:today..now and flag:unread" :key ?t)
          (:name "Today (all)" :query "date:today..now" :key ?T)
          (:name "Week (unread)" :query "date:7d..now and flag:unread" :key ?w)
          (:name "Week (all)" :query "date:7d..now" :key ?W)))

  ;; UI viewing headers
  (setq mu4e-headers-date-format "%d-%b-%Y")
  (setq mu4e-headers-fields
        '((:human-date . 12)
          (:flags . 6)
          (:maildir . 12)
          (:mailing-list . 20)
          (:from . 22)
          (:subject . nil)))

  ;; UI not to show dupes
  (setq mu4e-search-skip-duplicates t)

  ;; UI not to use any fancy Unicode glyphs that are only taking space unnecessarily
  (setq mu4e-use-fancy-chars nil)

  ;; Keep cursor away from window edges in headers view
  (add-hook 'mu4e-headers-mode-hook
            (lambda ()
              (setq-local scroll-margin 8)))

  ;; Sort messages in descending order (newest first, oldest at bottom)
  (setq mu4e-headers-sort-direction 'descending)

  ;; Clean up the *mu4e-update* window after mail fetch + indexing finishes.
  ;; Sometimes the window lingers with a stale/renamed buffer.
  (defun tibor/mu4e-kill-update-window ()
    "Delete any window still showing a mu4e-update buffer."
    (dolist (win (window-list))
      (when (and (> (count-windows) 1)
                 (string-match-p "\\*mu4e-update\\*"
                                 (buffer-name (window-buffer win))))
        (delete-window win))))
  (add-hook 'mu4e-index-updated-hook #'tibor/mu4e-kill-update-window))

;; Notmuch

(use-package notmuch
  :ensure nil) ;; notmuch is coming with system package

;; Environment: ensure proper PATH

(use-package exec-path-from-shell
  :ensure t
  :config
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize)))

;; Set Docker BuildKit progress to plain for clean output in async shell commands
(setenv "BUILDKIT_PROGRESS" "auto") ;; plain

;; Eat - terminal emulator

(use-package eat
  :ensure t
  :config
  ;; Compile terminfo if not already installed (fixes progress bars, etc.)
  (let ((term-name (if (functionp eat-term-name)
                       (funcall eat-term-name)
                     eat-term-name)))
    (unless (= 0 (call-process "infocmp" nil nil nil term-name))
      (eat-compile-terminfo)))

  ;; Enable shell integration (directory tracking, etc.)
  (setq eat-enable-shell-integration t)
  (setq eat-buffer-name "*term*")

  ;; Limit output processing to prevent Emacs from hanging on large output
  (add-hook 'eat-mode-hook
            (lambda () (setq-local read-process-output-max (* 4 1024))))
  (setq eat-term-scrollback-size 500)

  ;; Use evil-collection for Evil integration (insert state for typing,
  ;; ESC to normal state for scrollback/copy with hjkl, v, y, etc.)

  ;; Dynamic buffer naming: rename eat buffers to show current directory
  (defun tibor/eat-rename-buffer-after-cwd (_ _host _cwd)
    "Rename eat buffer to reflect the current working directory."
    (when (derived-mode-p 'eat-mode)
      (rename-buffer
       (format "*term %s*"
               (file-name-nondirectory
                (directory-file-name default-directory)))
       t)))
  (advice-add 'eat--set-cwd :after #'tibor/eat-rename-buffer-after-cwd)

  ;; Avy link hinting in eat: enter emacs mode, run avy, then exit
  (defun tibor/eat-avy-open-url ()
    "Open a URL in eat using avy (enters emacs mode temporarily)."
    (interactive)
    (eat-emacs-mode)
    (unwind-protect
        (tibor/avy-open-url)
      (eat-semi-char-mode)))

  (defun tibor/eat-avy-copy-url ()
    "Copy a URL in eat using avy (enters emacs mode temporarily)."
    (interactive)
    (eat-emacs-mode)
    (unwind-protect
        (tibor/avy-copy-url)
      (eat-semi-char-mode)))

  (defun tibor/eat-avy-open-commit ()
    "Open a commit hash in eat using avy (enters emacs mode temporarily)."
    (interactive)
    (let ((eat-buf (current-buffer)))
      (eat-emacs-mode)
      (unwind-protect
          (tibor/avy-open-commit-hash)
        (with-current-buffer eat-buf
          (eat-semi-char-mode)))))

  (defun tibor/eat-avy-copy-commit ()
    "Copy a commit hash in eat using avy (enters emacs mode temporarily)."
    (interactive)
    (eat-emacs-mode)
    (unwind-protect
        (tibor/avy-copy-commit-hash)
      (eat-semi-char-mode)))

  (defun tibor/eat-avy-insert-word ()
    "Use avy to select a word in eat and insert it (enters emacs mode temporarily)."
    (interactive)
    (let ((original-pos (point))
          (selected-word nil))
      (eat-emacs-mode)
      (unwind-protect
          (progn
            (avy-with tibor/eat-avy-insert-word
              (avy-jump tibor/word-regexp))
            (when (/= (point) original-pos)
              (when (looking-at tibor/word-regexp)
                (setq selected-word (match-string-no-properties 0)))))
        (eat-semi-char-mode))
      (when selected-word
        (eat-term-send-string eat-terminal selected-word))))

  (defun tibor/eat-avy-copy-word ()
    "Use avy to select a word in eat and copy it (enters emacs mode temporarily)."
    (interactive)
    (eat-emacs-mode)
    (unwind-protect
        (let ((original-pos (point)))
          (avy-with tibor/eat-avy-copy-word
            (avy-jump tibor/word-regexp))
          (when (/= (point) original-pos)
            (when (looking-at tibor/word-regexp)
              (let ((word (match-string-no-properties 0)))
                (kill-new word)
                (message "Copied: %s" word)))))
      (eat-semi-char-mode)))

  ;; Bind avy link commands in eat-semi-char-mode-map (lowercase=open/insert, uppercase=copy)
  (define-key eat-semi-char-mode-map (kbd "C-' o") 'tibor/eat-avy-open-url)
  (define-key eat-semi-char-mode-map (kbd "C-' O") 'tibor/eat-avy-copy-url)
  (define-key eat-semi-char-mode-map (kbd "C-' h") 'tibor/eat-avy-open-commit)
  (define-key eat-semi-char-mode-map (kbd "C-' H") 'tibor/eat-avy-copy-commit)
  (define-key eat-semi-char-mode-map (kbd "C-' w") 'tibor/eat-avy-insert-word)
  (define-key eat-semi-char-mode-map (kbd "C-' W") 'tibor/eat-avy-copy-word)

  ;; Evil C-^ (switch to last buffer) in eat
  (define-key eat-semi-char-mode-map (kbd "C-^") #'evil-buffer)
  ;; Cmd shortcuts in eat (eat semi-char mode swallows most keys, so we must re-bind)
  (define-key eat-semi-char-mode-map (kbd "s-v") #'eat-yank)
  (define-key eat-semi-char-mode-map (kbd "s-n") #'tibor/new-frame-with-eat)
  (define-key eat-semi-char-mode-map (kbd "s-k") #'tibor/switch-to-eat-buffer)
  (define-key eat-semi-char-mode-map (kbd "s-s") #'evil-buffer)
  (define-key eat-semi-char-mode-map (kbd "s-b") #'consult-buffer)
  (define-key eat-semi-char-mode-map (kbd "s-f") #'project-find-file)
  (define-key eat-semi-char-mode-map (kbd "s-r") #'consult-recent-file)
  (define-key eat-semi-char-mode-map (kbd "s-/") #'consult-ripgrep)
  (define-key eat-semi-char-mode-map (kbd "s-o") #'other-window)
  (define-key eat-semi-char-mode-map (kbd "s-d") #'dired-jump)
  (define-key eat-semi-char-mode-map (kbd "s-t") #'tibor/new-tab-with-eat)
  (define-key eat-semi-char-mode-map (kbd "s-<return>") #'tibor/new-split-with-eat)
  (define-key eat-semi-char-mode-map (kbd "s-e") #'tibor/toggle-terminal-tabs)
  (define-key eat-semi-char-mode-map (kbd "s-g") #'magit-status)

  ;; Sync eat mode with evil state: ESC switches to emacs mode for
  ;; scrollback/copy with hjkl/v/y, `i' switches back to semi-char mode
  (add-hook 'evil-normal-state-entry-hook
            (lambda ()
              (when (and (derived-mode-p 'eat-mode) eat-terminal)
                (eat-emacs-mode))))

  ;; Jump to prompt and restore semi-char mode when entering insert state
  (add-hook 'evil-insert-state-entry-hook
            (lambda ()
              (when (and (derived-mode-p 'eat-mode) eat-terminal)
                (eat-semi-char-mode)
                (goto-char (point-max)))))

  ;; In char mode, send ESC to the terminal instead of letting Evil
  ;; intercept it (Evil's input-decode-map translates ESC to [escape]
  ;; before keymap lookup, so eat-self-input can't recover the raw key)
  (evil-define-key 'insert eat-char-mode-map (kbd "<escape>")
    (lambda () (interactive) (eat-term-send-string eat-terminal "\e")))

  ;; Send literal ESC to terminal in semi-char mode (Evil swallows ESC)
  (define-key eat-semi-char-mode-map (kbd "C-c [")
    (lambda () (interactive) (eat-term-send-string eat-terminal "\e")))

  ;; Kill the correct buffer when eat exits; close the tab if it was eat-only
  (setq eat-kill-buffer-on-exit nil)
  (add-hook 'eat-exit-hook
            (lambda (process)
              (let ((buf (process-buffer process)))
                (when (buffer-live-p buf)
                  (let* ((in-selected (eq buf (window-buffer (selected-window))))
                         (close-tab (and in-selected
                                         (one-window-p t)
                                         (> (length (funcall tab-bar-tabs-function)) 1)))
                         (close-window (and in-selected
                                            (not (one-window-p t)))))
                    (cond (close-tab (tab-bar-close-tab))
                          (close-window (delete-window)))
                    (kill-buffer buf)))))))

;; Dired

(use-package dired
  :ensure nil
  :config
  (setq delete-by-moving-to-trash t)
  (bind-key "C-x d" #'dired-jump)
  (bind-key "C-x 4 d" #'dired-jump-other-window))

;; Icons support using nerd-icons
(use-package nerd-icons
  :ensure t)

;; Icons for dired
(use-package nerd-icons-dired
  :ensure t
  :hook (dired-mode . nerd-icons-dired-mode))

;; Icons for completion frameworks (vertico, consult, etc.)
(use-package nerd-icons-completion
  :ensure t
  :after marginalia
  :config
  (nerd-icons-completion-mode 1)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

;; Writeable grep

(use-package wgrep
  :ensure t
  :after grep)

;; Git

(use-package magit
  :ensure t
  :defer t
  :commands (magit-status magit-blame-addition magit-log-buffer-file magit-log-all))

;; Git commit message settings
(use-package git-commit
  :ensure nil  ;; git-commit comes with magit
  :after magit
  :custom
  ;; Set commit message summary line length to 72 characters
  (git-commit-summary-max-length 72)
  ;; Also set fill column for commit message body
  (git-commit-fill-column 72))

;; Git diff highlighting in fringe
(use-package diff-hl
  :ensure t
  :hook ((prog-mode . diff-hl-mode)
         (text-mode . diff-hl-mode)
         (dired-mode . diff-hl-dired-mode)
         (magit-pre-refresh . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :config
  ;; Evil keybindings for navigating git hunks (vim-style)
  (with-eval-after-load 'evil
    (evil-global-set-key 'normal (kbd "] c") 'diff-hl-next-hunk)
    (evil-global-set-key 'normal (kbd "[ c") 'diff-hl-previous-hunk)
    ;; Show diff popup at current hunk
    (evil-global-set-key 'normal (kbd "C-c g d") 'diff-hl-show-hunk)
    ;; Revert current hunk
    (evil-global-set-key 'normal (kbd "C-c g r") 'diff-hl-revert-hunk)))

;; Writing: Notes

(defun tibor/notes-goto-today ()
  "Open today's daily notes file. If the file doesn't exist, create it with a heading."
  (interactive)
  (let* ((filename (expand-file-name
                    (format-time-string "%Y-%m-%d.md")
                    "~/private/notes/"))
         (file-exists (file-exists-p filename)))
    (find-file filename)
    (unless file-exists
      (insert (format-time-string "# %Y-%m-%d\n"))
      (save-buffer))))

(defun tibor/notes-create-entry ()
  "Create new daily note entry at the end of the file."
  (interactive)
  (goto-char (point-max))
  (insert (format-time-string "\n## %Y-%m-%d %H:%M:%S #"))
  (evil-append 1))

;; Reading: PDF

(use-package pdf-tools
  :ensure t
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :config
  (pdf-tools-install :no-query))

;; Writing: TeX

(use-package auctex
  :ensure t
  :config
  ;; Enable SyncTeX correlation (forward/inverse search between source and PDF)
  (setq TeX-source-correlate-mode t
        TeX-source-correlate-method 'synctex
        TeX-source-correlate-start-server t)
  ;; Configure PDF Tools as the viewer
  (setq TeX-view-program-selection '((output-pdf "PDF Tools"))
        TeX-view-program-list '(("PDF Tools" TeX-pdf-tools-sync-view)))
  ;; Auto-refresh PDF after compilation
  (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer))

;; Writing: Snippets

(use-package yasnippet
  :ensure t
  :config
  (yas-global-mode 1))

(use-package yasnippet-snippets
  :ensure t
  :after yasnippet)

;; Programming: LSP

(use-package lsp-mode
  :ensure t
  :defer t
  :hook (;; Replace XXX-mode with concrete major mode (e.g. python-mode)
         (lsp-mode . lsp-enable-which-key-integration)  ;; Integrate with Which Key
         ((js-mode                                      ;; Enable LSP for JavaScript
           tsx-ts-mode                                  ;; Enable LSP for TSX
           typescript-ts-base-mode                      ;; Enable LSP for TypeScript
           css-mode                                     ;; Enable LSP for CSS
           go-ts-mode                                   ;; Enable LSP for Go
           js-ts-mode                                   ;; Enable LSP for JavaScript (TS mode)
           prisma-mode                                  ;; Enable LSP for Prisma
           python-mode                                  ;; Enable LSP for Python
           python-ts-mode                               ;; Enable LSP for Python (tree-sitter)
           ruby-base-mode                               ;; Enable LSP for Ruby
           rust-ts-mode                                 ;; Enable LSP for Rust
           web-mode) . lsp-deferred))                   ;; Enable LSP for Web (HTML)
  :commands lsp
  :init
  ;; Add Mason bin directory to exec-path for language servers
  (add-to-list 'exec-path (expand-file-name "~/.local/share/nvim/mason/bin"))
  :custom
  (lsp-keymap-prefix "C-c l")                           ;; Set the prefix for LSP commands.
  (lsp-inlay-hint-enable nil)                           ;; Usage of inlay hints.
  (lsp-completion-provider :none)                       ;; Disable the default completion provider.
  (lsp-session-file (locate-user-emacs-file ".lsp-session")) ;; Specify session file location.
  (lsp-log-io nil)                                      ;; Disable IO logging for speed.
  (lsp-idle-delay 0.5)                                  ;; Set the delay for LSP to 0 (debouncing).
  (lsp-keep-workspace-alive nil)                        ;; Disable keeping the workspace alive.
  ;; Core settings
  (lsp-enable-xref t)                                   ;; Enable cross-references.
  (lsp-auto-configure t)                                ;; Automatically configure LSP.
  (lsp-enable-links nil)                                ;; Disable links.
  (lsp-eldoc-enable-hover t)                            ;; Enable ElDoc hover.
  (lsp-enable-file-watchers nil)                        ;; Disable file watchers.
  (lsp-enable-folding nil)                              ;; Disable folding.
  (lsp-enable-imenu t)                                  ;; Enable Imenu support.
  (lsp-enable-indentation nil)                          ;; Disable indentation.
  (lsp-enable-on-type-formatting nil)                   ;; Disable on-type formatting.
  (lsp-enable-suggest-server-download nil)              ;; Disable automatic server download.
  (lsp-enable-symbol-highlighting t)                    ;; Enable symbol highlighting.
  (lsp-enable-text-document-color t)                    ;; Enable text document color.
  ;; Modeline settings
  (lsp-modeline-code-actions-enable nil)                ;; Keep modeline clean.
  (lsp-modeline-diagnostics-enable nil)                 ;; Use `flymake' instead.
  (lsp-modeline-workspace-status-enable t)              ;; Display "LSP" in the modeline when enabled.
  (lsp-signature-doc-lines 1)                           ;; Limit echo area to one line.
  (lsp-eldoc-render-all t)                              ;; Render all ElDoc messages.
  ;; Completion settings
  (lsp-completion-enable t)                             ;; Enable completion.
  (lsp-completion-enable-additional-text-edit t)        ;; Enable additional text edits for completions.
  (lsp-enable-snippet nil)                              ;; Disable snippets
  (lsp-completion-show-kind t)                          ;; Show kind in completions.
  ;; Lens settings
  (lsp-lens-enable t)                                   ;; Enable lens support.
  ;; Headerline settings
  (lsp-headerline-breadcrumb-enable-symbol-numbers t)   ;; Enable symbol numbers in the headerline.
  (lsp-headerline-arrow "▶")                            ;; Set arrow for headerline.
  (lsp-headerline-breadcrumb-enable-diagnostics nil)    ;; Disable diagnostics in headerline.
  (lsp-headerline-breadcrumb-icons-enable nil)          ;; Disable icons in breadcrumb.
  ;; Semantic settings
  (lsp-semantic-tokens-enable nil)                      ;; Disable semantic tokens.
  :config
  ;; Evil keybindings for LSP navigation (use evil-local-set-key for higher priority)
  (add-hook 'lsp-mode-hook
            (lambda ()
              (evil-local-set-key 'normal (kbd "g d") 'lsp-find-definition)
              (evil-local-set-key 'normal (kbd "g r") 'lsp-find-references)
              (evil-local-set-key 'normal (kbd "K") 'lsp-describe-thing-at-point))))

;; LSP Python: configure pyright from Mason
(use-package lsp-pyright
  :ensure t
  :demand t
  :after lsp-mode
  :init
  ;; Disable ruff completely before lsp-pyright loads
  (with-eval-after-load 'lsp-mode
    (delete 'ruff-lsp lsp-client-packages)
    (add-to-list 'lsp-disabled-clients 'ruff-lsp))
  :config
  ;; Configure pyright to use Mason installation
  (setq lsp-pyright-langserver-command "pyright-langserver")
  (setq lsp-pyright-langserver-command-args '("--stdio"))
  (setq lsp-pyright-multi-root nil)
  (setq lsp-pyright-auto-import-completions t)
  (setq lsp-pyright-auto-search-paths t)

  ;; Register pyright for Python modes
  (add-hook 'python-mode-hook #'lsp-deferred)
  (add-hook 'python-ts-mode-hook #'lsp-deferred))

;; Programming: EditorConfig support

(use-package editorconfig
  :ensure t
  :config
  (editorconfig-mode 1))

;; Programming: Code formatting

(use-package format-all
  :ensure t
  :commands format-all-mode
  :hook ((python-mode . format-all-mode)
         (python-ts-mode . format-all-mode)
         (go-mode . format-all-mode)
         (go-ts-mode . format-all-mode)
         (js-mode . format-all-mode)
         (js-ts-mode . format-all-mode)
         (typescript-mode . format-all-mode)
         (typescript-ts-mode . format-all-mode)
         (json-mode . format-all-mode)
         (yaml-mode . format-all-mode)
         (markdown-mode . format-all-mode)
         (sh-mode . format-all-mode)
         (bash-ts-mode . format-all-mode))
  :config
  ;; Specify formatters for each language
  (setq-default format-all-formatters
                '(("Python" (black))
                  ("Go" (gofmt))
                  ("JavaScript" (prettier))
                  ("TypeScript" (prettier))
                  ("JSON" (prettier))
                  ("YAML" (prettier))
                  ("Markdown" (prettier))
                  ("Shell" (shfmt)))))

;; Programming: Syntax checking with Flymake

(use-package flymake
  :ensure nil
  :hook (prog-mode . flymake-mode)
  :config
  ;; Keybindings for navigating errors
  ;; Simple next/prev navigation with ] d and [ d
  (define-key flymake-mode-map (kbd "] d") 'flymake-goto-next-error)
  (define-key flymake-mode-map (kbd "[ d") 'flymake-goto-prev-error)
  ;; Use consult-flymake for interactive list with live preview
  (with-eval-after-load 'consult
    (define-key flymake-mode-map (kbd "C-c ! l") 'consult-flymake))
  (define-key flymake-mode-map (kbd "C-c ! L") 'flymake-show-project-diagnostics))

;; Flymake collection - comprehensive language checkers
(use-package flymake-collection
  :ensure t
  :hook (after-init . flymake-collection-hook-setup))

;; Programming: Dockerfile

(use-package dockerfile-ts-mode
  :ensure t
  :mode (("Dockerfile\\'" . dockerfile-ts-mode)
         ("\\.dockerfile\\'" . dockerfile-ts-mode)))

;; Hadolint for Dockerfile linting
(use-package flymake-hadolint
  :ensure t
  :hook (dockerfile-ts-mode . flymake-hadolint-setup)
  :config
  (setq flymake-hadolint-program "hadolint"))

;; Programming: Go mode (fallback if tree-sitter grammar not available)

(use-package go-mode
  :ensure t
  :mode "\\.go\\'"
  :config
  ;; go-ts-mode will override this if tree-sitter grammar is available
  ;; This ensures syntax highlighting even without tree-sitter
  (add-hook 'go-mode-hook #'lsp-deferred))

;; Programming: Go testing

(use-package gotest
  :ensure t
  :config
  ;; Set verbose output
  (setq go-test-verbose t)

  ;; Use compilation mode for clickable errors
  (setq go-test-compilation-function 'compile)

  ;; Add Go test error patterns for compilation mode
  (with-eval-after-load 'compile
    (add-to-list 'compilation-error-regexp-alist 'go-test)
    (add-to-list 'compilation-error-regexp-alist-alist
                 '(go-test . ("^[[:space:]]*\\([_a-zA-Z0-9/-]+\\.go\\):\\([0-9]+\\):.*$" 1 2)))))

;; Programming: update copyright automatically

(use-package copyright
  :ensure nil
  :config
  (setq copyright-names-regexp "CERN\\|Tibor .imko")
  (setq copyright-query nil)  ; Update without asking
  (add-hook 'before-save-hook #'copyright-update))

;; Programming: indent guides

(use-package indent-guide
  :defer t
  :ensure t
  :hook
  (prog-mode . tibor/indent-guide-maybe)
  :config
  (setq indent-guide-char "│")
  (defun tibor/indent-guide-maybe ()
    "Enable indent-guide-mode only in files smaller than 100KB."
    (when (< (buffer-size) (* 100 1024))
      (indent-guide-mode 1))))

;; Programming: Treesitter

(use-package treesit-auto
  :ensure t
  :after emacs
  :custom
  (treesit-auto-install 'prompt)
  :config
  ;; Cache the language availability checks to speed up file opening
  (setq treesit-auto-langs (treesit-auto--build-major-mode-remap-alist))
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode t))

;; Programming: Mise
;; Manages per-directory environment variables from .mise.toml files

(use-package mise
  :ensure t
  :hook (after-init . global-mise-mode))

;; Programming: Python

(use-package pyvenv
  :ensure t
  :config
  (setq pyvenv-mode-line-indicator '(pyvenv-virtual-env-name ("[venv:" pyvenv-virtual-env-name "] ")))
  (pyvenv-mode +1))

(use-package python-pytest
  :ensure t
  :after pyvenv
  :config
  ;; Ensure compilation buffers inherit buffer-local environment variables
  (defun tibor/python-pytest-with-buffer-env (orig-fun &rest args)
    "Advice to make pytest compilation inherit buffer-local environment variables.
This ensures the compilation buffer uses the correct Python virtual environment
from pyvenv, which sets buffer-local process-environment and exec-path."
    (let ((process-environment (default-value 'process-environment))
          (exec-path (default-value 'exec-path)))
      ;; If we have buffer-local overrides (from pyvenv), use them
      (when (local-variable-p 'process-environment)
        (setq process-environment (buffer-local-value 'process-environment (current-buffer))))
      (when (local-variable-p 'exec-path)
        (setq exec-path (buffer-local-value 'exec-path (current-buffer))))
      ;; Now run the original function with the correct environment
      (apply orig-fun args)))

  ;; Apply the advice to python-pytest functions
  (advice-add 'python-pytest :around #'tibor/python-pytest-with-buffer-env)
  (advice-add 'python-pytest-file-dwim :around #'tibor/python-pytest-with-buffer-env)
  (advice-add 'python-pytest-run-def-or-class-at-point-dwim :around #'tibor/python-pytest-with-buffer-env))

;; Writing: Spell checking

(use-package flyspell
  :ensure nil
  :config
  ;; Use aspell if available (faster and better than ispell)
  (when (executable-find "aspell")
    (setq ispell-program-name "aspell")
    (setq ispell-extra-args '("--sug-mode=ultra"))
    ;; Set the dictionary to British English
    (setq ispell-dictionary "en_GB"))

  ;; Automatically enable flyspell for text modes
  (add-hook 'text-mode-hook #'flyspell-mode)
  (add-hook 'org-mode-hook #'flyspell-mode)
  (add-hook 'markdown-mode-hook #'flyspell-mode)
  (add-hook 'mu4e-compose-mode-hook #'flyspell-mode)
  (add-hook 'message-mode-hook #'flyspell-mode)

  ;; For programming modes, only check comments and strings
  (add-hook 'prog-mode-hook #'flyspell-prog-mode)

  ;; Don't print messages for every word checked (reduces noise)
  (setq flyspell-issue-message-flag nil)

  ;; Evil-friendly keybindings for spell checking
  (with-eval-after-load 'evil
    ;; Navigate to next/previous spelling error with ] s and [ s
    (evil-global-set-key 'normal (kbd "] s") 'flyspell-goto-next-error)
    (evil-global-set-key 'normal (kbd "[ s")
                         (lambda () (interactive) (flyspell-goto-next-error t)))
    ;; Correct word at point with z =
    (evil-global-set-key 'normal (kbd "z =") 'flyspell-correct-wrapper)))

;; Flyspell correct - better correction interface
(use-package flyspell-correct
  :ensure t
  :after flyspell
  :bind (:map flyspell-mode-map
              ("C-;" . flyspell-correct-wrapper))
  :config
  ;; Use completing-read interface (works with vertico)
  (setq flyspell-correct-interface #'flyspell-correct-completing-read))

;; Dictionary lookup
(use-package dictionary
  :ensure nil
  :bind ("C-c d" . dictionary-lookup-definition))

;; Consult integration for viewing all spelling errors in buffer
(defun consult-flyspell ()
  "Jump to spelling errors in current buffer using consult."
  (interactive)
  (unless flyspell-mode
    (user-error "Flyspell mode is not enabled"))
  (let ((errors '()))
    ;; Collect all flyspell overlays
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (let ((overlays (overlays-at (point))))
          (dolist (ov overlays)
            (when (overlay-get ov 'flyspell-overlay)
              (let* ((word (buffer-substring-no-properties
                           (overlay-start ov)
                           (overlay-end ov)))
                     (line (line-number-at-pos (overlay-start ov)))
                     (col (save-excursion
                           (goto-char (overlay-start ov))
                           (current-column))))
                (push (list (format "%4d:%3d: %s" line col word)
                           (overlay-start ov))
                      errors)))))
        (goto-char (next-overlay-change (point)))))
    (if (null errors)
        (message "No spelling errors found")
      (let* ((selected (consult--read
                       (nreverse errors)
                       :prompt "Spelling error: "
                       :category 'flyspell-error
                       :sort nil
                       :require-match t
                       :lookup #'consult--lookup-cdr)))
        (when selected
          (goto-char selected)
          (recenter))))))

;; Add spell checking to leader key bindings
(with-eval-after-load 'general
  (tibor/leader-keys
    "s" '(:ignore t :which-key "search/spell")
    "s s" '(consult-imenu :which-key "search symbols")
    "s p" '(flyspell-correct-wrapper :which-key "correct spelling at point")
    "s n" '(flyspell-goto-next-error :which-key "next spelling error")
    "s e" '(consult-flyspell :which-key "list all spelling errors")))

;; Programming: YAML

(use-package yaml-mode
  :ensure t
  :mode ("\\.ya?ml\\'" . yaml-mode))

;; Programming: JSON

(use-package json-mode
  :ensure t
  :mode ("\\.json\\'" . json-mode))

;; Programming: Markdown

(use-package markdown-mode
  :ensure t
  :defer t
  :mode (("\\.md\\'" . markdown-mode)
         ("README\\.md\\'" . gfm-mode))
  :init (setq markdown-command "multimarkdown"))

;; Flymake backend for markdownlint-cli2
(use-package flymake-markdownlint-cli2
  :vc (:url "https://github.com/ewilderj/flymake-markdownlint-cli2"
            :rev :newest
            :branch "main")
  :demand t
  :config
  (add-hook 'markdown-mode-hook 'flymake-mode)
  (add-hook 'markdown-mode-hook 'flymake-markdownlint-cli2-setup))

;; Programming: Snakemake

(use-package snakemake-mode
  :ensure t)

;; AI: Claude Code IDE integration

(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el"
            :rev :newest
            :branch "main")
  :after eat
  :bind ("C-c C-'" . claude-code-ide-menu)
  :config
  (setq claude-code-ide-terminal-backend 'eat)
  (claude-code-ide-emacs-tools-setup))

;; Start Emacs daemon

(use-package server
  :ensure nil
  :config
  (setq server-client-instructions nil)
  (unless (or (server-running-p) (daemonp))
    (server-start)))

;;; init.el ends here
