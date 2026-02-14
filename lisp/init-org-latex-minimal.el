;;; init-org-latex-minimal.el --- Minimal Org+LaTeX config -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(when *is-a-mac*
  (maybe-require-package 'grab-mac-link))

(maybe-require-package 'org-cliplink)
(maybe-require-package 'org-journal)

(define-key global-map (kbd "C-c l") 'org-store-link)
(define-key global-map (kbd "C-c a") 'org-agenda)
(define-key global-map (kbd "C-c j") 'org-journal-new-entry)

;; Keep core editing/export preferences only.
(setq org-log-done t
      org-edit-timestamp-down-means-later t
      org-hide-emphasis-markers t
      org-catch-invisible-edits 'show
      org-export-coding-system 'utf-8
      org-html-validation-link nil
      org-export-kill-product-buffer-when-displayed t
      org-support-shift-select t)

(defun sanityinc/org-select-latex-preview-process ()
  "Pick the best available process for LaTeX fragment previews."
  (setq-local org-preview-latex-default-process
              (cond
               ((executable-find "dvisvgm") 'dvisvgm)
               ((executable-find "dvipng") 'dvipng)
               (t org-preview-latex-default-process))))

(add-hook 'org-mode-hook 'sanityinc/org-select-latex-preview-process)

(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-M-<up>") 'org-up-element)
  (when *is-a-mac*
    (define-key org-mode-map (kbd "M-h") nil)
    (define-key org-mode-map (kbd "C-c g") 'grab-mac-link))

  ;; Keep Babel support intentionally minimal.
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (latex . t)
     (shell . t))))

(provide 'init-org-latex-minimal)
;;; init-org-latex-minimal.el ends here
