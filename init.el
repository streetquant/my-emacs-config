;;; init.el --- Minimal Org+LaTeX configuration -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; Produce backtraces when errors occur: can be helpful to diagnose startup issues
;; (setq debug-on-error t)

(let ((minver "27.1"))
  (when (version< emacs-version minver)
    (error "Your Emacs is too old -- this config requires v%s or higher" minver)))
(when (version< emacs-version "28.1")
  (message "Your Emacs is old, and some functionality in this config will be disabled. Please upgrade if possible."))

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(require 'init-benchmarking)

(defconst *is-a-mac* (eq system-type 'darwin))

;; Adjust garbage collection threshold for startup
(setq gc-cons-threshold (* 128 1024 1024))

;; Process performance tuning
(setq read-process-output-max (* 4 1024 1024))
(setq process-adaptive-read-buffering nil)

;; Bootstrap config
(setq custom-file (locate-user-emacs-file "custom.el"))
(require 'init-utils)
(require 'init-site-lisp)
(require 'init-elpa)
(require 'init-exec-path)

;; General performance tuning
(when (require-package 'gcmh)
  (setq gcmh-high-cons-threshold (* 128 1024 1024))
  (add-hook 'after-init-hook #'gcmh-mode))

(setq jit-lock-defer-time 0)

;; Allow users to provide an optional "init-preload-local.el"
(require 'init-preload-local nil t)

;; Navigation and UI behavior
(require 'init-frame-hooks)
(require 'init-xterm)
(require 'init-themes)
(require 'init-gui-frames)
(require 'init-dired)
(require 'init-isearch)
(require 'init-grep)
(require 'init-uniquify)
(require 'init-ibuffer)
(require 'init-recentf)
(require 'init-state)
(require 'init-windows)

;; Completion UX
(require 'init-minibuffer)
(require 'init-hippie-expand)
(require 'init-corfu)

;; Minimal authoring stack
(require 'init-org-latex-minimal)

;; Allow access from emacsclient
(add-hook 'after-init-hook
          (lambda ()
            (require 'server)
            (unless (server-running-p)
              (server-start))))

;; Variables configured via the interactive 'customize' interface
(when (file-exists-p custom-file)
  (load custom-file))

;; Locales (setting them earlier in this file doesn't work in X)
(require 'init-locales)

;; Allow users to provide an optional "init-local" containing personal settings
(require 'init-local nil t)

(provide 'init)

;; Local Variables:
;; coding: utf-8
;; no-byte-compile: t
;; End:
;;; init.el ends here

;; personal configuration
(global-set-key (kbd "C-x b") 'switch-to-buffer)
(global-set-key (kbd "C-x c") 'save-buffers-kill-terminal)
(global-set-key (kbd "C-x <left>") 'previous-buffer)
(global-set-key (kbd "C-x <right>") 'next-buffer)
(global-set-key (kbd "C-x C-<left>") 'previous-buffer)
(global-set-key (kbd "C-x C-<right>") 'next-buffer)

;; Allow repeating buffer navigation with bare arrow keys for a short time.
(setq repeat-exit-timeout 2)
(repeat-mode 1)

;; personal customization
(global-set-key (kbd "C-h") 'delete-backward-char)

(setq org-odt-preferred-output-format "docx")

;; Automatically copy active region to system clipboard.
(setq select-enable-clipboard t
      select-enable-primary t
      select-active-regions t
      mouse-drag-copy-region t)

(defvar sanityinc/last-region-for-clipboard nil
  "Track the last copied region to avoid redundant clipboard updates.")

(defun sanityinc/sync-region-to-clipboard ()
  "Copy the active region to the system clipboard."
  (if (use-region-p)
      (let ((beg (region-beginning))
            (end (region-end)))
        (unless (equal sanityinc/last-region-for-clipboard
                       (list (current-buffer) beg end))
          (setq sanityinc/last-region-for-clipboard
                (list (current-buffer) beg end))
          (condition-case nil
              (gui-set-selection 'CLIPBOARD
                                 (buffer-substring-no-properties beg end))
            (error nil))))
    (setq sanityinc/last-region-for-clipboard nil)))

(add-hook 'post-command-hook #'sanityinc/sync-region-to-clipboard)

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(require 'ai-cleaner)
