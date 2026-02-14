;;; init-state.el --- Persist and restore editor state -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; Restore open buffers/windows between restarts.
(setq desktop-path (list user-emacs-directory)
      desktop-auto-save-timeout 600
      desktop-load-locked-desktop t
      desktop-globals-to-save
      '((extended-command-history . 50)
        (file-name-history . 200)
        (search-ring . 20)
        (regexp-search-ring . 20)
        register-alist))
(desktop-save-mode 1)

;; Persist minibuffer/search history.
(setq history-length 1000
      savehist-save-minibuffer-history t
      savehist-additional-variables
      '(kill-ring search-ring regexp-search-ring file-name-history))
(savehist-mode 1)

;; Restore cursor position in files.
(save-place-mode 1)

(provide 'init-state)
;;; init-state.el ends here
