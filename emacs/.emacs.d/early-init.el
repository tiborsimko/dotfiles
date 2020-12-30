;;; early-init.el -- Tibor's early Emacs configuration.

;; Copyright (C) 2020 Tibor Simko.

;;; Commentary:

;; This is Tibor's early Emacs configuration.

;;; Code:

;; Delay garbage collection during start-up processes
(setq gc-cons-threshold most-positive-fixnum)

;; Disable package.el as we are using straight.el for package management
(setq package-enable-at-startup nil)

;; Disable frame resizing
(setq frame-inhibit-implied-resize t)

;;; early-init.el ends here
