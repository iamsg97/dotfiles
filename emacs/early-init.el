;;; early-init.el --- runs before the UI is drawn  -*- lexical-binding: t; -*-

;; Faster startup: don't garbage-collect while loading the config.
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook (lambda () (setq gc-cons-threshold (* 64 1024 1024))))

;; Tsoding-style minimal UI: no menu bar, tool bar or scroll bars.
(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode)   (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;; Emacs 31 nags about older packages lacking a `lexical-binding' header line.
;; Harmless; hide it so it doesn't pop up a *Warnings* window.
(setq warning-suppress-types     '((files missing-lexbind-cookie))
      warning-suppress-log-types '((files missing-lexbind-cookie)))

(setq inhibit-startup-screen t
      initial-scratch-message nil
      package-enable-at-startup t)
