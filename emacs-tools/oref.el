;;; OREF: A system for marking and citing sources in plaintext documents.
;;
;; The recommended entry point is `oref-do-ref' -- see its doc string
;; for more about what refs are and how to use them.  See the section
;; "Installation" below for how to install this package into Emacs.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; Copyright (c) 2016, 2017, 2018 Open Tech Strategies, LLC
;; 
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;; 
;; If you did not receive a copy of the GNU General Public License
;; along with this program, see <http://www.gnu.org/licenses/>.
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;; Installation ;;;;
;;
;; Put something like this in your .emacs file -- you may need to
;; adjust the path to "oref.el" of course:
;;
;;   (let ((oref-el (expand-file-name "~/OTS/ots-tools/emacs-tools/oref.el")))
;;     ;; Hint: git clone git@github.com:OpenTechStrategies/ots-tools.git
;;     (when (file-exists-p oref-el)
;;       (load oref-el)
;;       ;; Make `C-c o' run `oref-do-ref'.  You can choose any single-letter
;;       ;; key, of course -- it doesn't have to be "o".
;;       (global-set-key "\C-co" 'oref-do-ref)))
;;
;;;;;;;;;;;;;;;;;;;;;;


;; Require `subr-x' because all the good string functions are defined
;; there and it might not be loaded by default.  I found this out when
;; a fairly young Emacs session failed in `oref-find-ref-internal'
;; (which uses `string-join'), and then while I was in investigating
;; this, suddenly `string-join' became defined (I guess I must have
;; typed a key bound to some autoloaded function that brought in a
;; library that required `subr-x').  But I was never able to reproduce
;; `string-join' *not* being defined after that -- even in a brand new
;; 'emacs -q' session, it was defined.  I don't know how to explain
;; that, but anyway there's no reason to take a risk: it costs nothing
;; to require it explicitly, so we do.
(require 'subr-x)

(defun oref-make-uuid (&optional length)
  "Return a uuid of length LENGTH (defaults to 32 and capped at 32).
This function makes no guarantees about uniqueness, but tries its best."
  (substring
   (md5 (concat 
         (format "%d" (point))
         (format "%d" (emacs-pid))
         (system-name)
         (emacs-version)
         (user-full-name)
         (current-time-string)
         (emacs-uptime)
         (format "%d" (random))
         (format "%S" (recent-keys))
         ;; Probably the above is enough and we don't need to
         ;; use the buffer text, but if we wanted to, then:
         ;; (buffer-substring-no-properties
         ;;   (point-min) (min undo-outer-limit (point-max)))
         ))
   0 (if length (min length 32) 32)))


(defun oref-copy-ref-as-kill (ref)
  "Copy REF to the kill ring with a specialized yank handler.
The yank handler causes REF to be yanked in fancy mode-specific ways.
This function modifies the text properties of REF."
  (let ((citation-yank-fn 
         ;; As we handle more special cases, we may want to pull
         ;; this anonymous lambda out into its own named function.
         (lambda (citation-str)
           (cond
            ((eq major-mode 'latex-mode)
             (if current-prefix-arg
                 ;; It's up to the LaTeX author who uses the prefix
                 ;; arg to make sure there's a LaTeX command called
                 ;; \oref{...} that does whatever it should do, e.g.,
                 ;; put the citation into the document in a certain
                 ;; style, or perhaps just omit the citation (the
                 ;; latter is useful when you want to have inline,
                 ;; non-comment citations in the LaTeX source even
                 ;; though they don't show in the output).
                 (insert (format "\\oref{%s}" citation-str))
               ;; If we're on a blank line (and how I wish that
               ;; Emacs had a native function for asking that),
               ;; then the user probably wants to insert the ref
               ;; as a LaTeX comment on its own line.  Do so.
               (if (save-excursion (and
                                    (skip-chars-backward " ")
                                    (bolp)
                                    (skip-chars-forward " ")
                                    (eolp)))
                   (insert "% " citation-str)
                 (insert citation-str))))
            (t
             (insert citation-str))))))
    (set-text-properties 0 (length ref)
                         (list 'yank-handler (list citation-yank-fn)) 
                         ref))
  (kill-new ref))


(defun oref-set-ref ()
  "Insert a new unique reference origin, and put the ref in the kill ring.

When pasting a reference with \\[yank], you may use a prefix argument
to insert a mode-specific alternate form of citation.  For example, in
LaTeX mode, \\[yank] with prefix arg inserts \"\\oref{ref:...}\".

If you're considering binding this to a key, see `oref-do-ref' instead."
  (interactive)
  (let ((ref-str (format "ref:%s" (oref-make-uuid 8))))
    (insert "[" ref-str "]")
    (when (and 
           (looking-at "\\S-")
           (not (looking-at ":")))
      (insert " "))
    (oref-copy-ref-as-kill ref-str)))


(defun oref-get-ref-at-point (&optional pair-if-source)
  "Return the ref (a string starting with \"ref:\") at point, else nil.
If optional argument PAIR-IF-SOURCE is non-nil, then if there is a ref
at point and it is the source ref (i.e., the origin, in square braces),
then return a cons cell: (REF-STR-WITHOUT-SQUARE-BRACES . 'source)."
  (let* ((ref        (thing-at-point 'filename))
         (ref-bounds (bounds-of-thing-at-point 'filename))
         (ref-start  (car ref-bounds))
         (ref-end    (cdr ref-bounds)))
    (when ref
      (let ((ref (substring-no-properties ref)))
        (when (and (> (length ref) 4)
                   (string-equal (substring ref 0 4) "ref:"))
          (save-match-data
            (string-match "^\\(ref:[a-z0-9]+\\)" ref)
            (setq ref (match-string 1 ref)))
          (when (and (> ref-start (point-min))
                     (= (char-after (1- ref-start)) ?\[)
                     (= (char-after     ref-end)    ?\]))
            (setq ref (cons ref 'source)))
          ref)))))

(defvar oref-ref-files-cache nil
  "Cache of files that contain [ref:] tags.
Users should not modify this variable.")

(defun oref-ref-files-rebuild-cache (root)
  "(Re)build cache of files under ROOT whose contents contain \"[ref:]\" tags.
The cache is `oref-ref-files-cache', whose value will be updated."
  (interactive "DRebuild OTS ref cache starting from directory: ")
  (setq root (directory-file-name root))
  (message "Rebuilding ref-file cache (may take a while)...")
  ;; We *could* update the cache non-destructively instead of
  ;; rebuilding it from scratch.  A non-destructive update would mean
  ;; that every existing file in the cache stays there, and we just
  ;; merge in any new ones.  But I'm not sure that would buy us much
  ;; in practice; the user would generally just rebuild the cache from
  ;; a higher-up directory, because they know where the files are.
  (setq oref-ref-files-cache
        (split-string (shell-command-to-string
                       (format (concat "grep "
                                       "--exclude-dir \".svn/\" "
                                       "--exclude-dir \".git/\" "
                                       "-rlI "
                                       "\"\\[ref:.*\\]\" %s")
                               root))
                      "\n"))
  (message "done"))

(defun oref-find-ref-internal (ref)
  "Jump to the origin site of REF. The origin site is the one
where the ref is in square braces.  There can be only one such
place; if there are more than one, then this function may choose
the wrong one.

Returns t if origin site is found, else nil."
  (let* ((cmd (format (concat "grep "
                              "--exclude-dir \".svn/\" "
                              "--exclude-dir \".git/\" "
                              "-rlI -m 1 "
                              "\"\\[%s\\]\" %s")
                      ref
                      (string-join oref-ref-files-cache " ")))
         (output (prog2 (message "Searching (may take a while...)")
                     (shell-command-to-string cmd)
                   (message "")))
         (fname (substring output 0 (string-match "$" output))))
    (if (string-blank-p fname)
        nil
      (let ((orig-buf (current-buffer))
            (other-buf (other-buffer)))
        (find-file fname)
        (when (or (eq orig-buf  (current-buffer))
                  (eq other-buf (current-buffer)))
          (push-mark))
        (widen)
        (goto-char (point-min))
        (search-forward (concat "[" ref "]"))
        (forward-word -2)
        (forward-char -1)
        (when (eq major-mode 'org-mode)
          (org-reveal))
        t))))

(defun oref-find-ref (&optional ref)
  "Jump to the origin site of REF (defaults to the ref point is in).
The origin site is the one where the ref is in square braces.  There
can be only one such place; if there are more than one, then this
function may choose the wrong one.

If REF is in the current buffer or in the \"other buffer\" (i.e., the
result of `(other-buffer)'), then push mark at the current location in
the current buffer before jumping to REF.  The justification for this
is that when working in either one buffer or alternating between two
(an interview notes file and a report-in-progress, for example), one
usually wants to be able to return to where one was in either buffer.

Refs are searched for in the files listed in `oref-ref-files-cache',
which is built as needed by `oref-ref-files-rebuild-cache', which see.

If you're considering binding this to a key, see `oref-do-ref' instead."

  ;; TODO: It might be interesting to sort the search list by
  ;; closeness to the current dir.  The cost of sort might be higher
  ;; than the cost of just grepping through those files, though.  If
  ;; we had a lot of files with refs in them, we might want to move
  ;; recent hit files to the head of oref-ref-files-cache.

  (interactive)
  ;; If called interactively, get the ref around point.
  (when (and (called-interactively-p) (not ref))
    (setq ref (oref-get-ref-at-point)))
  ;; If we were called non-interactively and just the unique ID
  ;; portion was passed, then tack on the "ref:" prefix.
  (unless (string-equal (substring ref 0 4) "ref:")
    (setq ref (concat "ref:" ref)))

  ;; If we do not have a list of files to search, make one.
  (unless oref-ref-files-cache
    (call-interactively 'oref-ref-files-rebuild-cache))
  (while (not (oref-find-ref-internal ref))
    ;; We didn't find a match.  Give the user chances to rebuild
    ;; the ref file index (e.g., perhaps starting from higher up).
    (message (concat "Ref not found.  "
                     "Will offer you a chance to rebuild the index..."))
    (sit-for 2)
    (call-interactively 'oref-ref-files-rebuild-cache)))

(defun oref-do-ref ()
  "If point is in a citation ref, go to its source, else set a new ref
(unless point is in a source ref, in which case put the ref in the kill ring).

This function is the recommended entry point to the oref system.  If
you're going to bind something to a key, it should probably be this,
not `oref-set-ref' nor `oref-find-ref'.

================================
Introduction to the OREF system:
================================

OREF allows you to quickly mark and traverse place-specific
connections between documents.  It is typically used for
connections that are kept in the background, accessible only to
those working with a document's plaintext source (e.g., LaTeX,
DocBook XML, etc).

For example:

Suppose you're writing a report in LaTeX.  The report relies on a
bunch of interviews, and your interview notes are in individual
files, or maybe in one big file, in some kind of plaintext format.

Whenever you write an assertion in the report that is based on a
specific thing an interviewee said, you'd like to note the
connection by citing that thing in a LaTeX comment.

But it would be too time-consuming to write out the name of the
interviewee each time, and to copy-and-paste the exact relevant
excerpt from the interview notes.  Even if you did all that,
jumping from the report to a given source -- which is a thing one
often wants to do -- would involve a laborious manual process of
searching through interview file(s).

Instead, you can just use `oref-do-ref' as described below.  It
allows you to quickly insert a reference marker (known as an
\"origin ref\") in the interview notes file and insert a
corresponding citation (known as a \"citation ref\") in the
report.  It also allows you jump from citation to origin later.

Here's how to use it:

In the interview notes, run `\\[oref-do-ref]' to insert a new
origin ref.  It will be a randomly generated reference identifier
in square braces, like this: \"[ref:34992c31]\".

That reference is now in the clipboard (the Emacs `kill-ring').
You can now go into the interview document and paste a citation
ref with `\\[yank]''.  The pasted version will just the raw ref
without the square braces, like so: \"ref:34992c31\".

(The square braces that surround the origin ref distinguish the
origin location, of which there must be only one, from its
citation locations, of which there may be many.)

When you paste a citation ref, it adjusts to context appropriately.
For example, it may include a mode-specific comment prefix when pasted
on a line by itself in, e.g., LaTeX.  See the documentation for
`oref-set-ref' for details about `\\[yank]' behavior.

To jump from citation to origin, just put point anywhere within
the citation ref and run `\\[oref-do-ref]'.  (On just the first
time, you may be prompted once to tell Emacs the root of the
directory tree under which all reference origins are found.)  See
the documentation for `oref-find-ref' for other details about the
jump behavior.

To grab a reference again so you can paste it as a new citation
somewhere, just put point anywhere inside the origin ref (e.g.,
inside the square braces around \"[ref:34992c31]\") and run
`\\[oref-do-ref]'.  This will add the ref to both the kill ring 
and the search ring."
  (interactive)
  (let ((ref (oref-get-ref-at-point)))
    (if ref
        (if (consp ref)
            (if (eq (cdr ref) 'source)
                (progn
                  (oref-copy-ref-as-kill (car ref))
                  (isearch-update-ring (car ref))
                  (message "Copied \"%s\" to clipboard and to search ring." (car ref)))
              (error (concat
                      (format "Unrecognized ref format: \"%S\".  " ref)
                      "Are you from the future?")))
          (oref-find-ref ref))
      (oref-set-ref))))
