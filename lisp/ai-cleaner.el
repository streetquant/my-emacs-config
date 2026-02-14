;;; ai-cleaner.el --- Remove AI unicode watermarks and footprints from text -*- lexical-binding: t; -*-

;; Author: Your Name <you@example.com>
;; Version: 2.3
;; Keywords: text, tools, convenience, ai, watermark
;; Package-Requires: ((emacs "25.1"))

;;; Commentary:
;;
;; Enhanced AI text cleaner that removes:
;; - Zero-width and invisible Unicode characters
;; - Homoglyphs (lookalike characters; excludes Greek letters)
;; - Directional marks and format characters
;; - Unusual whitespace patterns
;; - Smart quotes (converts both to and from ASCII/typographic)
;; - AI watermarking artifacts
;;
;; Enhancements:
;; - Fixed EOF parenthesis issue
;; - Automatically saves visiting file after cleaning
;; - New smart-quote conversion (‘…’ “…”)

;;; Code:

(require 'cl-lib)

(defgroup ai-cleaner nil
  "Clean AI-injected or nonstandard Unicode artifacts in text."
  :group 'convenience)

(defcustom ai-cleaner-dash-normalization 'hyphen
  "How to normalize dash-like Unicode characters."
  :type '(choice (const keep)
                 (const em)
                 (const en)
                 (const hyphen)
                 (const double-hyphen))
  :group 'ai-cleaner)

(defcustom ai-cleaner-detect-homoglyphs t
  "Whether to detect and replace homoglyph characters (excludes Greek letters)."
  :type 'boolean
  :group 'ai-cleaner)

(defcustom ai-cleaner-normalize-quotes t
  "Whether to normalize smart and ASCII quotes."
  :type 'boolean
  :group 'ai-cleaner)

(defcustom ai-cleaner-report-findings t
  "Whether to show detailed cleaning report."
  :type 'boolean
  :group 'ai-cleaner)

(defconst ai-cleaner-watermark-chars
  '(;; chatgpt watermark + invisible
    (?\u202F . " ")
    (?\u200B . "") (?\u200C . "") (?\u200D . "") (?\u2060 . "") (?\uFEFF . "") (?\u180E . "")
    ;; formatting marks
    (?\u202A . "") (?\u202B . "") (?\u202C . "") (?\u202D . "") (?\u202E . "")
    (?\u2066 . "") (?\u2067 . "") (?\u2068 . "") (?\u2069 . "") (?\u061C . "")
    (?\u200E . "") (?\u200F . "")
    (?\u2028 . "\n") (?\u2029 . "\n\n") (?\u0085 . "\n")
    ;; spaces
    (?\u00A0 . " ") (?\u2000 . " ") (?\u2001 . " ") (?\u2002 . " ")
    (?\u2003 . " ") (?\u2004 . " ") (?\u2005 . " ") (?\u2006 . " ")
    (?\u2007 . " ") (?\u2008 . " ") (?\u2009 . " ") (?\u200A . " ") (?\u205F . " ") (?\u3000 . " ")
    ;; control chars
    (?\u0000 . "") (?\u0001 . "") (?\u0002 . "") (?\u0003 . "") (?\u0004 . "")
    (?\u0005 . "") (?\u0006 . "") (?\u0007 . "") (?\u0008 . "")
    (?\u000B . " ") (?\u000C . "\n")
    (?\u000E . "") (?\u000F . "") (?\u0010 . "") (?\u0011 . "") (?\u0012 . "")
    (?\u0013 . "") (?\u0014 . "") (?\u0015 . "") (?\u0016 . "")
    (?\u0017 . "") (?\u0018 . "") (?\u0019 . "") (?\u001A . "")
    (?\u001B . "") (?\u001C . "") (?\u001D . "") (?\u001E . "") (?\u001F . "") (?\u007F . ""))
  "Known watermark or control characters.")

(defconst ai-cleaner-homoglyphs
  '(;; Cyrillic lookalikes
    (?\u0430 . "a") (?\u0435 . "e") (?\u043E . "o") (?\u0440 . "p")
    (?\u0441 . "c") (?\u0445 . "x") (?\u0443 . "y")
    (?\u0410 . "A") (?\u0415 . "E") (?\u041E . "O") (?\u0420 . "P")
    (?\u0421 . "C") (?\u0422 . "T") (?\u0425 . "X"))
  "Common homoglyph letters excluding Greek.")

(defconst ai-cleaner-quote-chars
  '(;; Double to ASCII "
    (?\u201C . "\"") (?\u201D . "\"") (?\u201E . "\"") (?\u201F . "\"")
    (?\u2033 . "\"") (?\u2036 . "\"") (?\u301D . "\"") (?\u301E . "\"")
    (?\uFF02 . "\"")
    ;; Single to ’
    (?\u2018 . "’") (?\u2019 . "’") (?\u201A . "’") (?\u201B . "’")
    (?\u2032 . "’") (?\u2035 . "’") (?\uFF07 . "’") (?\u02BC . "’")
    (?\u02C8 . "’") (?\u2039 . "’") (?\u203A . "’")
    (?\uFF40 . "`"))
  "Smart quotes and quote-like characters to normalize.")

(defvar ai-cleaner--findings nil
  "Alist of findings from last run.")

(defun ai-cleaner--dash-replacement-target ()
  (pcase ai-cleaner-dash-normalization
    ('keep nil)
    ('em "—")
    ('en "–")
    ('hyphen "-")
    ('double-hyphen "--")
    (_ "-")))

(defun ai-cleaner--dash-replacements ()
  (let ((to (ai-cleaner--dash-replacement-target)))
    (when to
      (list
       (cons ?\u2014 to) (cons ?\u2013 to) (cons ?\u2012 to)
       (cons ?\u2015 to) (cons ?\u2212 to) (cons ?\u2010 to)
       (cons ?\u2011 to) (cons ?\u2043 to)
       (cons ?\uFE58 to) (cons ?\uFE63 to)
       (cons ?\uFF0D to))))) ; fixed missing paren

(defun ai-cleaner--collect-replacements ()
  (let ((pairs ai-cleaner-watermark-chars))
    (when ai-cleaner-detect-homoglyphs
      (setq pairs (append pairs ai-cleaner-homoglyphs)))
    (when ai-cleaner-normalize-quotes
      (setq pairs (append pairs ai-cleaner-quote-chars)))
    (setq pairs (append pairs (ai-cleaner--dash-replacements)))
    pairs))

(defun ai-cleaner--perform-replacements ()
  (let ((count 0)
        (pairs (ai-cleaner--collect-replacements))
        (ht (make-hash-table :test 'equal)))
    (save-excursion
      (dolist (p pairs)
        (let ((char (char-to-string (car p)))
              (r (cdr p))
              (n 0))
          (goto-char (point-min))
          (while (search-forward char nil t)
            (replace-match r t t)
            (cl-incf count)
            (cl-incf n))
          (when (> n 0)
            (puthash (car p) n ht)))))
    (setq ai-cleaner--findings ht)
    count))

(defun ai-cleaner--normalize-whitespace ()
  (let ((c 0))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "[ \t]\\{2,\\}" nil t)
        (replace-match " " t t))
      (goto-char (point-min))
      (while (re-search-forward " +\\([,.!?;:]\\)" nil t)
        (replace-match "\\1" t))
      (goto-char (point-min))
      (while (re-search-forward "\n\\{3,\\}" nil t)
        (replace-match "\n\n" t t)))
    c))

;; Smart quote conversion
(defun ai-cleaner--smartify-straight-quotes ()
  "Convert straight ASCII quotes to typographic curly quotes.
Uses simple context-sensitive toggling."
  (save-excursion
    (goto-char (point-min))
    (let (toggle)
      ;; double quotes
      (setq toggle t)
      (while (search-forward "\"" nil t)
        (replace-match (if toggle "“" "”") t t)
        (setq toggle (not toggle))))
    (goto-char (point-min))
    (let (toggle)
      ;; single quotes
      (setq toggle t)
      (while (search-forward "'" nil t)
        (replace-match (if toggle "‘" "’") t t)
        (setq toggle (not toggle))))))

(defun ai-cleaner--report-findings ()
  (when (and ai-cleaner-report-findings ai-cleaner--findings)
    (with-output-to-temp-buffer "*AI Cleaner Report*"
      (maphash
       (lambda (ch n)
         (princ (format "• %s (U+%04X): %d occurrence(s)\n"
                        (char-to-string ch) ch n)))
       ai-cleaner--findings))))

;;;###autoload
(defun ai-cleaner-clean-current-buffer ()
  "Clean Unicode watermarks, homoglyphs, whitespace, and quote styles.
Automatically saves buffer if visiting a file."
  (interactive)
  (if buffer-read-only
      (error "Buffer is read-only")
    (let ((a (ai-cleaner--perform-replacements))
          (b (ai-cleaner--normalize-whitespace)))
      (ai-cleaner--smartify-straight-quotes)
      (let ((tcount (+ a b)))
        (if (> tcount 0)
            (progn
              (when (and buffer-file-name (buffer-modified-p))
                (save-buffer))
              (message "✓ Cleaned %d issues and smartified quotes." tcount)
              (ai-cleaner--report-findings))
          (message "ℹ No AI watermarks detected."))))))

;;;###autoload
(defun ai-cleaner-check-region (start end)
  "Check region START–END for AI patterns without editing."
  (interactive "r")
  (let ((sample (buffer-substring-no-properties start end))
        (n 0))
    (dolist (pair (ai-cleaner--collect-replacements))
      (let ((str (char-to-string (car pair)))
            (o 0))
        (while (setq o (string-match str sample o))
          (setq n (1+ n))
          (setq o (1+ o)))))
    (if (> n 0)
        (message "⚠️  %d suspicious characters detected." n)
      (message "✅ No AI watermarks detected."))))

(defalias 'clean-ai-text #'ai-cleaner-clean-current-buffer)
(defalias 'check-ai-text #'ai-cleaner-check-region)

(provide 'ai-cleaner)
;;; ai-cleaner.el ends here
