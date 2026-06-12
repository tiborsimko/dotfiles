;;; early-init.el -- Tibor's early Emacs configuration.

;; Copyright (C) 2020 Tibor Simko.

;;; Commentary:

;; This is Tibor's early Emacs configuration.

;;; Code:

;; Delay garbage collection during start-up processes
(setq gc-cons-threshold most-positive-fixnum)

;; Disable file-name-handler-alist during init (speeds up require/load)
(defvar default-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

;; Disable frame resizing
(setq frame-inhibit-implied-resize t)

;; Disable adaptive read buffering for faster subprocess I/O
;; Note: may increase input latency in terminal emulators like EAT
(setq process-adaptive-read-buffering nil)

;;; early-init.el ends here
