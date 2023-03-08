;;; ruff-flymake.el --- A flymake backend for the python linter ruff -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Colin J. Fuller

;; Author: Colin Fuller <colin@cjf.io>
;; URL: https://github.com/cjfuller/ruff-flymake
;; Keywords: tools
;; Version: 0.1.0
;; Package-Requires: ((emacs "26.1"))

;;; Commentary:

;; This is a flymake backend that runs the `ruff` python linter
;; (https://github.com/charliermarsh/ruff).
;; You must install ruff on your system in order to use this package.  By
;; default, it will run ruff from your path (as found by `executable-find`).
;; If ruff is not on your path or you want to run a specific version you can
;; set the variable `ruff-flymake-ruff-executable` to the path for ruff that
;; you want to use.
;;
;; Loading this package does not automatically install the backend into
;; flymake; add it to the backends for python-mode in your init.el via:
;; `(add-hook 'python-mode-hook 'ruff-flymake-setup-backend)`
;;
;; Note that if you're using this package alongside eglot, eglot will by
;; default disable other flymake backends.  To avoid this but still get eglot
;; output in your flymake diagnostics, put this in your init.el:
;; ```
;; (add-to-list 'eglot-stay-out-of 'flymake)
;; (add-hook 'flymake-diagnostic-functions 'eglot-flymake-backend nil t)
;; ```

;;; Code:

(defvar ruff-flymake-ruff-executable nil
  "`ruff-flymake-rust-executable` is the path to the ruff binary.

  If `nil` (the default) we attempt to locate it via `executable-find`.")

(defun ruff-flymake-get-ruff-executable ()
  "Get the path to `ruff` using the provided path, or `executable-find` if nil."
  (or ruff-flymake-ruff-executable (executable-find "ruff")))

(defvar-local ruff-flymake--proc nil)

(defun ruff-flymake-backend (report-fn &rest _args)
  "Run ruff and report diagnostics to the flymake callback REPORT-FN."

  (unless (ruff-flymake-get-ruff-executable)
    (error "Unable to locate ruff; is it installed?"))
  (when (process-live-p ruff-flymake--proc)
    (kill-process ruff-flymake--proc))
  (let ((source-buffer (current-buffer))
        (source-code (buffer-string))
        (process-environment (cons "NO_COLOR=1" process-environment)))
    (setq ruff-flymake--proc
          (make-process
           :name "ruff-flymake" :noquery t :connect-type 'pipe
           :buffer (generate-new-buffer "*ruff-flymake*")
           :command `(,(ruff-flymake-get-ruff-executable)
                      "--stdin-filename" ,(or (buffer-file-name source-buffer) "unsaved.py")
                      "--quiet"
                      "-")
           :sentinel
           (lambda (proc _event)
             (when (memq (process-status proc) '(exit signal))
               (unwind-protect
                   (if (with-current-buffer source-buffer (eq proc ruff-flymake--proc))
                       (with-current-buffer (process-buffer proc)
                         (goto-char (point-min))
                         (cl-loop
                          while (search-forward-regexp
                                 "^\\(?:.*\\.py\\):\\([0-9]+\\):\\([0-9]+\\): \\(.*\\)$"
                                 nil t)
                          for msg = (match-string 3)
                          for line = (string-to-number (match-string 1))
                          for col = (string-to-number (match-string 2))
                          for (beg . end) = (flymake-diag-region source-buffer line col)
                          collect (flymake-make-diagnostic source-buffer beg end :warning msg)
                          into diags
                          finally (funcall report-fn diags)))
                     (flymake-log :warning "Cancelling obsolete check %s" proc))
                 (kill-buffer (process-buffer proc)))))))
    (process-send-string ruff-flymake--proc source-code)
    (process-send-eof ruff-flymake--proc)))

(defun ruff-flymake-setup-backend ()
  "Activate ruff-flymake as a backend for flymake.

  This is intended to be added to `python-mode-hook`."
  (add-hook 'flymake-diagnostic-functions #'ruff-flymake-backend nil t))

(provide 'ruff-flymake)
;;; ruff-flymake.el ends here
