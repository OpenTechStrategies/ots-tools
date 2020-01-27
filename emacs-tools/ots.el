;;;;       Emacs Lisp code used at Open Tech Strategies, LLC.
;;;;               https://OpenTechStrategies.com/
;;;; 
;;;; Copyright (c) 2014-2019 Open Tech Strategies, LLC
;;;; 
;;;; This program is free software: you can redistribute it and/or modify
;;;; it under the terms of the GNU General Public License as published by
;;;; the Free Software Foundation, either version 3 of the License, or
;;;; (at your option) any later version.
;;;; 
;;;; This program is distributed in the hope that it will be useful, but
;;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;;; General Public License for more details.
;;;; 
;;;; If you did not receive a copy of the GNU General Public License
;;;; along with this program, see <http://www.gnu.org/licenses/>.
;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; Overview
;;;; ========
;;;;
;;;; Most of this stuff is highly OTS-specific and probably not of
;;;; interest outside the company.  However, we publish it as free
;;;; software partly because that's our policy and partly because we
;;;; want to be able to conveniently refer others to this code --
;;;; either to ask them for suggestions on how to do something better
;;;; or to show an example to someone who wants one.  In particular,
;;;; some of the customizations we've made to Org Mode functionality
;;;; might be useful outside OTS.
;;;;
;;;; To use these functions, put something like this in your .emacs,
;;;; or your ~/.emacs.d/init.el, or whatever your Emacs init file is:
;;;;
;;;;   ;; Do 'git clone git@github.com:OpenTechStrategies/ots-tools.git'
;;;;   ;; to get the 'ots-tools' repository.
;;;;   (setq ots-dir (file-name-as-directory
;;;;                   (expand-file-name "~/path/to/ots-tools-dir")))
;;;;
;;;;   (let ((ots-elisp-root (concat ots-dir "emacs-tools")))
;;;;     (when (file-exists-p ots-elisp-root)
;;;;       (add-to-list 'load-path ots-elisp-root)
;;;;       (load "ots")))
;;;;   
;;;; We try to stay compatible with the most recent official releases
;;;; of Org Mode, but... we don't try too hard.  If something related
;;;; to Org Mode seems not to be working, try running the development
;;;; version of Org Mode from git://orgmode.org/org-mode.git.
;;;;
;;;; To find the interactive entry points below, look for functions
;;;; that have an "(interactive ...)" form near the beginning.

(require 'org)
(require 'org-agenda)

(defvar ots-dir (file-name-as-directory
                  (or (getenv "OTSDIR") (expand-file-name "~/OTS")))
  "*Root of the OTS working copy tree.  This always ends with a slash.

This will be derived from the environment variable \"OTSDIR\" if
it exists, otherwise it will be set to a default value that is
unlikely to be correct for you.

You can ensure this variable has the correct value by either
defining \"OTSDIR\" in the environment Emacs runs in, or by
setting this variable directly in your .emacs, like the following
but with the path portion adjusted as appropriate:

(setq ots-dir (file-name-as-directory (expand-file-name \"~/OTS\")))
")

;; If `org-todo-keywords' has the default Org Mode value, that means
;; the user hasn't customized it.  But at OTS, we use the intermediate
;; state "STARTED", and we mark "DONE" as a final state.  So if
;; `org-todo-keywords' isn't defined or if the user hasn't customized
;; `org-todo-keywords' at all, then they couldn't possibly have those
;; necessary customizations, which means we'll have to set it up for
;; them.
(when (or (not (boundp 'org-todo-keywords)) (equal org-todo-keywords '((sequence "TODO" "DONE"))))
  (setq org-todo-keywords '((sequence "TODO" "STARTED" "|" "DONE"))))


;;; Emacs abbrevs for common but hard-to-type OTS phrases.

;; These only have an effect in the `abbrev-mode' minor mode, which
;; you can turn on by running `M-x abbrev-mode'.

;; LaTeX: where *every* character gets to be special.
;; 
;; But seriously: a further improvement to the below would be to make
;; non-LaTeX abbrevs here, but define a OTS-specific LaTeX mode hook
;; that overrides them by using `define-mode-abbrev' (which *should*
;; take the mode as an argument, IMHO, but instead requires to be run
;; while in that mode).  For now, we define LaTeX-specific abbrevs
;; globally, since it's in LaTeX that these are really hard to type.
(define-global-abbrev "ivv" "IV\\&V")
(define-global-abbrev "osivv" "OS~IV\\&V")
(define-global-abbrev "checkbooknyc" "Checkbook~NYC")
(define-global-abbrev "cbnyc" "Checkbook~NYC") ; even easier to type

;; I wish that `define-global-abbrev' took a flag to say "No need to
;; ask about saving this abbrev to ~/.emacs.d/abbrev_defs, since, you
;; know, I'm defining it right here in Elisp in the first place."
;;
;; Since it doesn't, you might want to set this in your .emacs, unless
;; you normally make abbrevs on the fly and want Emacs to save them:
;;
;; (setq save-abbrevs nil)



;;; Random helpers.

(defun ots-svn-authz-edit ()
  "Find the OTS SVN authz file (and start in the \"All Leads\" section)."
  (interactive)
  (find-file
   (concat ots-dir
           "infra/svn-server/srv/svn/repositories/auth/ots-authz-file"))
  (goto-char (point-min))
  (search-forward
   "(Please leave this line here; `ots-svn-authz-helper' looks for it.)")
  (forward-char 1)
  (message (concat "NOTE: When you commit+push your changes, "
                   "they will take effect automagically.")))



;;; Compatibility shims.
;;; 
;;; Most distributions ship Emacs 24.x as of this writing, so that's
;;; the highest major version OTS Elisp requires.  But recent dev
;;; versions of Emacs have some nifty stuff, so we import some of 
;;; that stuff from the future.

(unless (fboundp 'string-trim-right)
  (defun string-trim-right (string)
    ;; Imported from lisp/emacs-lisp/subr-x.el in Emacs 26 dev,
    ;; git revision 8661313efd5fd5b0a27fe82f276a1ff862646424.
    "Remove trailing whitespace from STRING."
    (if (string-match "[ \t\n\r]+\\'" string)
        (replace-match "" t t string)
      string)))


(defmacro ots-with-org-file (file &rest body)
  (declare (indent 1))
  `(save-excursion
     (save-restriction
       (set-buffer (find-file-noselect ,file))
       (widen)
       (goto-char (point-min))
       ,@body)))

(defconst ots-org-file (concat ots-dir "org/ots.org")
  "Path to the ots.org file.")

(defvar ots-org-files nil
  "All the org files in the OTS tree that we consider \"interesting\".
Basically, that's any 'notes.org' file that should be included by default
in `org-agenda-files'.  Don't set this variable directly; instead, run
`ots-load-org-files'.")

(defun ots-load-org-files ()
  "Build or rebuild `ots-org-files' and `org-agenda-files'.
Both variables are affected when this runs, but the effects on
the latter are non-destructive: if you have non-OTS stuff in
`org-agenda-files', that stuff will be preserved."
  (interactive)
  (message "Finding and loading OTS Org Mode files...")
  (setq ots-org-files
        (append (list ots-org-file)
                (split-string
                 (shell-command-to-string
                  (format 
                   (concat "find '%s' -name notes.org -print "
                           "| grep -v '/personnel/' "
                           "| grep -v '/infra/examples/' "
                           "| xargs grep -l '#+CATEGORY:'")
                   ots-dir)))))
  ;; Only grab the psm.org file if it exists
  (let ((psm-org-file (concat ots-dir "clients/hhs/cms/psm/psm.org")))
    (when (and
           (not (member psm-org-file ots-org-files))
           (file-exists-p psm-org-file))
      ;; Keep ots-org-file on the front of the list.
      (nconc ots-org-files (list psm-org-file))))
  ;; Reload any files that have changed on disk (e.g., due to 'svn up').
  (mapcar (lambda (buf)
            (when (and
                   (member (buffer-file-name buf) ots-org-files)
                   (not (verify-visited-file-modtime buf)))
              (save-excursion
                (set-buffer buf)
                ;; We could pass the optional NOCONFIRM flag below to
                ;; avoid prompting the user, but I think maybe it's
                ;; actually better for people to be alerted that an
                ;; OTS Org Mode file is being reloaded from disk.
                (revert-buffer))))
          (buffer-list))
  ;; Incorporate everyone into the Org Agenda.
  (unless (boundp 'org-agenda-files) (setq org-agenda-files ()))
  (mapcar (lambda (org-file) (add-to-list 'org-agenda-files org-file))
          ots-org-files)
  (message "Finding and loading OTS Org Mode files...done"))
(defalias 'ots-reload-org-files 'ots-load-org-files)

;; Now actually do the initialization
(ots-load-org-files)



;;; Deliverables-tracking system.
;; 
;; Note that this system depends on `ots-org-files' having been
;; initialized correctly above.  If deliverables aren't showing up as
;; expected, make sure the corresponding 'notes.org' file is
;; `ots-org-files' and thus in `org-agenda-files'.  Also make sure
;; that the top of the org file has correct "#+SETUPFILE" and
;; "#+CATEGORY" lines, and that the deliverable entries have dates
;; and ":DUE:" tags.
;;
;; Some pages Karl consulted while working on this:
;;
;;   - https://orgmode.org/org.html#Tags
;;   - https://orgmode.org/org.html#Agenda-Views
;;   - https://orgmode.org/org.html#Matching-tags-and-properties
;;   - https://orgmode.org/org.html#Categories
;;   - https://orgmode.org/org.html#Presentation-and-Sorting

;; Make tag-based agenda views sort by date instead of by filename.
(let ((new (mapcar (lambda (sort-spec)
                     (if (and (eq (car sort-spec) 'tags)
                              (not (eq (cadr sort-spec) 'timestamp-up)))
                         (append (list (car sort-spec)) 
                                 (list 'timestamp-up)
                                 (cdr sort-spec))
                       sort-spec))
                   org-agenda-sorting-strategy)))
  (setq org-agenda-sorting-strategy new))

(defvar ots-deliverables-horizon 30
  "Don't show items farther in the future than this number of days,
in `ots-browse-deliverables'.  
This can be nil (in which case there will be no time horizon), but if
non-nil it must be a positive integer; the behavior if negative is
undefined.  Deliverables whose dates are in the past are always shown.")

(defvar ots-deliverables-current-horizon nil
  "Internal variable used to keep an deliverables horizon active in 
the deliverables buffer.  Users should never set this.")

(defun ots-browse-deliverables (&optional days-into-future)
  "Show deliverables, i.e., entries items marked with the 'DUE' tag.
This is the expected entry point for listing upcoming deliverables.

Optional prefix argument DAYS-INTO-FUTURE limits how many days into
the future to consider deliverables.  Set `ots-deliverables-horizon' 
to get a default limit, but an interactive prefix arg will override
that default.  Repeated calls preserve the current limit, so to set
a new limit interactively just invoke with a new prefix argument.

To add a new deliverable, just make an entry in the appropriate
'notes.org' file, with the \"DUE\" tag and an orgmode-formatted
date:

  ** <2019-07-08 Mon> Some deliverable heading goes here.      :DUE:

That's our standard for the date format, by the way.  If you use
it, then everything will line up nicely.  Finer degrees of
resolution, such as \"EOD\" or \"By 10am\" can be included in the
body of the entry.

Note that the 'notes.org' must have a \"#+CATEGORY: Foo\" line near the
top, where \"Foo\" is a short-but-recognizeable name for the client."
  (interactive "P")
  (if days-into-future
      (setq ots-deliverables-current-horizon days-into-future)
    (if ots-deliverables-current-horizon
        (setq days-into-future ots-deliverables-current-horizon)
      (setq days-into-future ots-deliverables-horizon
            ots-deliverables-current-horizon days-into-future)))
  ;; See https://orgmode.org/manual/Tag-inheritance.html.
  ;; You might think that `org-tags-exclude-from-inheritance'
  ;; or maybe `org-agenda-show-inherited-tags' or maybe
  ;; `org-agenda-use-tag-inheritance' would be relevant here, 
  ;; but nope.  Only `org-use-tag-inheritance' matters.
  ;;
  ;; TODO: Some improvements we could use:
  ;; 
  ;;   1) Right now the resultant buffer has header
  ;; 
  ;;        "Headlines with TAGS match: DUE
  ;;         Press ‘C-u r’ to search again"
  ;; 
  ;;      That's just noise for us.  We don't need
  ;;      either line showing, and we also don't need
  ;;      what the second line says to be true (because
  ;;      `g' is the traditional key for reloading, and
  ;;      it does `org-agenda-redo-all').
  ;;      
  ;;   2) When the buffer is regenerated via `g' or `r' 
  ;;      or `C-u r', our custom let-bound settings for
  ;;      `org-agenda-hide-tags-regexp' and
  ;;      `org-use-tag-inheritance' are no longer in
  ;;      effect, so the buffer is regenerated with
  ;;      newly-visible inherited lines and "DUE" tags.
  ;;      (Using `make-local-variable' for them doesn't
  ;;      work either, by the way.)
  ;;
  ;; The solution to both is probably to reimplement this
  ;; w/ `org-add-agenda-custom-command', as documented in
  ;; https://orgmode.org/manual/Special-agenda-views.html,
  ;; and pass an options list to set everything up right,
  ;; including a value for `org-agenda-overriding-header'.
  ;;
  ;; But for now, we solve it by rebinding 'g' :-).
  (let ((org-agenda-buffer-name "*OTS Deliverables*") 
        (org-agenda-overriding-header
         (concat
          (if days-into-future 
              (format "OTS deliverables through %d days from now.\n" 
                      days-into-future)
            "All OTS deliverables.\n")
          "Type `g' to refresh; " 
          "use prefix arg to set time horizon in days."
          "\n"))
        (org-agenda-hide-tags-regexp "^DUE$")
        (org-use-tag-inheritance nil)
        (org-agenda-skip-function
         (lambda ()
           (when days-into-future
             (save-match-data
               (re-search-forward org-ts-regexp-both)
               (let ((timestamp (match-string-no-properties 0)))
                 (when (> (org-time-stamp-to-now timestamp) days-into-future)
                   (outline-next-heading)
                   (point))))))))
    (org-tags-view nil "DUE")
    (when (eq (key-binding "g") 'org-agenda-redo-all)
      (local-set-key "g" 'ots-browse-deliverables))))


;; Display the Org Mode header path (Outline path) from top to point.
;; 
;; This is a variant of functionality already available in Org Mode.
;; 
;; When we wrote this, we didn't know about `org-get-outline-path'
;; (nor about the related fact that org-eldoc displays in the
;; minibuffer the outline path for the current heading).  In
;; https://lists.gnu.org/archive/html/emacs-orgmode/2019-12/threads.html#00033
;; (thread "[PROPOSAL] New function `org-headings-to-point' and
;; displayer.")  Adam Porter helpfully pointed these out, and I (Karl)
;; tried it out.  I found `ots-org-display-headings-to-point'
;; preferable because it's easier on the eye, at least IMHO.
;; 
;; As that thread discusses, the ideal thing to do would be to update
;; our code to use what Org Mode already provides.  As that thread
;; also discusses, that is more easily said than done because the
;; interfaces available right now aren't shaped quite right for the
;; functionality we want, though Adam goes partway there in his post
;; https://lists.gnu.org/archive/html/emacs-orgmode/2019-12/msg00073.html
;; for what it's worth.
;; 
;; Anyway, for now we just have these independently-written functions
;; that sort of, but not quite, duplicate features in Org Mode.

(defun ots-org-headings-to-point ()
  "Return all the Org Mode headings leading to point."
  (when (not (eq major-mode 'org-mode))
    (error "ERROR: this only works in Org Mode"))
  (let ((headings (list (org-heading-components))))
    (save-excursion
      (save-match-data
        (save-restriction
          (widen)
          (while (org-up-heading-safe)
            (setq headings (cons (org-heading-components) headings)))))
      headings)))

(defun ots-org-display-headings-to-point ()
  "Display Org Mode heading titles from level 1 to current subtree.
Display each title on its own line, indented proportionally to its level."
  (interactive)
  (let* ((heading-titles (mapcar (lambda (heading)
                                   (nth 4 heading))
                                 (ots-org-headings-to-point)))
         (level 0)
         (hierarchy (mapcar (lambda (title)
                              (prog1
                                  (if (zerop level)
                                      (concat "• " title)
                                    (concat "\n" 
                                            (make-string (* level 2) ? )
                                            "→ " title))
                                (setq level (1+ level))))
                            heading-titles)))
    (display-message-or-buffer (string-join hierarchy))))



(defvar ots-default-rate nil
  "*Default rate in US dollars for OTS contracts.  This is
  usually set in hours.org or some other place where invoice
  amounts are calculated.  Note that OTS rates can vary among clients
  (for example, non-profit vs for-profit) and you will usually have to
  supply the rate manually.")

(defun ots-tally-client-hours (rate)
  "Tally total hours and amount for client around point, in an OTS ledger.
Calculate amount by multipling total hours found by RATE dollars/hour.
Return a list of the form '(total-hours total-amount).  If called
interactively, prompt for RATE, and display result in minibuffer."
  (interactive (list (read-number "Rate in dollars/hour: " ots-default-rate)))
  (let ((beg         nil)
        (end         nil)
        (total-hours 0)
        (hours-re    "^\*\*\\s-+\\([0-9.]+\\)\\s-+\\(hr\\|hour\\)"))
    (save-excursion
      (save-match-data
        (save-restriction
          (widen)
          ;; Find the boundaries of the current top-level org tree.
          ;; Org Mode should have this built in, but AFAIK doesn't.
          (re-search-backward "^\* ")
          (forward-line 1)
          (setq beg (point))
          (re-search-forward "^\* " nil 'end)
          (beginning-of-line)
          (setq end (point))
          (goto-char beg)
          (re-search-forward hours-re)
          (while (< (point) end)
            (setq total-hours
                  (+ total-hours (string-to-number (match-string 1))))
            ;; Advance now, to avoid the step-too-far problem:
            (re-search-forward hours-re nil 'end)))))
    (message "%.2f hours  =>  $%.2f" total-hours
             (* (float total-hours) (float rate)))
    (list total-hours (* (float total-hours) (float rate)))))

(defun ots-update-invoice-totals (rate)
  "Walk through all entries in an invoice, updating totals at RATE.
Print and return a list of all the totals by type, in this form:

  (('grand-total G_TOTAL)
   ('hours-total H_TOTAL)   ; this one is not money, just a number
   ('time-total T_TOTAL)
   ('flat-total F_TOTAL)
   ('expense-total E_TOTAL)
   ...
  )

G_TOTAL is always the sum of all the other monetary totals.

For hours entries (i.e., \"\\timeentry{...}\" entries), update the dollar
total in place in the buffer, based on the given hours for that entry.

For flat-rate entries and expense entries, make no change in the
buffer (for such entries, we assume the dollar amount is correct,
just as we assume that the hours are correct for time-based
entries), just update the running total for that entry type."
  (interactive (list (read-number "Rate in dollars/hour: " ots-default-rate)))
  ;; Leave any narrowing active, just in case.
  (let* ((entry-re "\\\\\\(time\\|expense\\|flat\\)entry{")
         (buffer-started-pristine (not (buffer-modified-p)))
         (orig-checksum  (when buffer-started-pristine
                           (md5 (buffer-substring (point-min) (point-max)))))
         (hours-total      0)
         (time-dollars     0)
         (expense-dollars  0)
         (flat-dollars     0))
    (save-excursion
      (save-match-data
        (goto-char (point-min))
        (while (re-search-forward entry-re nil t)
          (let ((type (match-string 1)))
            (cond 
             ((string-equal type "time")
              (forward-char -1) (forward-sexp 2) (forward-char 1)
              (let ((hours (string-to-number
                            (buffer-substring-no-properties
                             (point) (progn (search-forward "}")
                                            (forward-char -1)
                                            (point))))))
                (search-forward "{")
                (delete-region (point)
                               (progn (search-forward "}")
                                      (forward-char -1)
                                      (point)))
                (setq hours-total (+ hours-total hours))
                (let ((subtotal (* hours rate)))
                  (insert (format "%.2f" subtotal))
                  (setq time-dollars (+ time-dollars subtotal)))))
             ((or (string-equal type "flat") (string-equal type "expense"))
              (forward-char -1) (forward-sexp 2) (forward-char 1)
              (let ((subtotal (string-to-number
                               (buffer-substring-no-properties
                                (point) (progn (search-forward "}")
                                               (forward-char -1)
                                               (point))))))
                (if (string-equal type "expense")
                    (setq expense-dollars (+ expense-dollars subtotal))
                  (setq flat-dollars (+ flat-dollars subtotal)))))
             (t
              (error "Unrecognized entry type: '%s'" type)))))))
    ;; If the buffer was unmodified when we started, and the invoice
    ;; was already correct, then don't pretend we changed anything.
    (when buffer-started-pristine
      (let ((new-checksum (md5 (buffer-substring (point-min) (point-max)))))
        (when (string-equal new-checksum orig-checksum)
          (set-buffer-modified-p nil))))
    (let ((grand-total (+ time-dollars flat-dollars expense-dollars)))
      (message
       "$%.2f (%.2f hours => $%.2f; $%.2f flat rate; $%.2f expenses)"
       grand-total hours-total time-dollars flat-dollars expense-dollars)
      (sit-for 2)
      (list (list 'grand-total grand-total)
            (list 'hours-total hours-total)
            (list 'time-dollars time-dollars)
            (list 'flat-dollars flat-dollars)
            (list 'expense-dollars expense-dollars)))))


(defun ots-org-headings (level &optional end)
  "Return an alist of heading names at LEVEL and their locations.
LEVEL is the Org Mode subtree depth -- the number of asterisks. 
Start searching from point; optional argument END means don't
search past END.  A heading may have \"|\"-separated alternate names.
The returned list is suitable for `completing-read'.

Here is an example return value:

  ((\"J. Random\" 762) (\"Jane Random\" 762) (\"Jane Q. Random\" 762)...)

That would correspond to the example heading below, where \"*\" is on
position 762 at the beginning of a line in the buffer and LEVEL == 1:

  * J. Random | Jane Random | Jane Q. Random"
  ;; Right now, re-generating the returned list for a given org file
  ;; is not expensive enough to be worth optimizing.  But someday we
  ;; might care, and the answer then is to cache the entries, and then
  ;; check the mod time for the corresponding buffer to invalidate the
  ;; cache and regenerate the list when needed.  There are some
  ;; functions (e.g., `ots-visit-client' and `ots-crm-lookup') that
  ;; indirectly invoke this twice when called interactively, once for
  ;; the `completing-read' in the 'interactive' form, and again in an
  ;; assoc in the body of the function.  If that's ever costing us
  ;; response time, caching is (yes, really) the easy answer.
  (let* ((ret   ())
         (stars (regexp-quote (make-string level ?*)))
         (re    (concat "^" stars "\\s-+\\([^\n]*\\)")))
    (save-excursion
      (save-match-data
        (while (re-search-forward re end "end-of-buffer")
          (let* ((names (match-string-no-properties 1))
                 (opt (point))
                 (bpt (prog2 (beginning-of-line) (point) (goto-char opt))))
            (setq names (string-trim-right names))
            ;; Remove any Org Mode tags (like ":SOME_TAG:" at the end
            ;; of a heading line).
            (setq names (replace-regexp-in-string 
                         "\\s-+:[a-zA-Z0-9@_:]+:$" "" names))
            ;; Now convert names from a messy string to a clean list.
            (setq names (split-string names "\s+|\s+"))
            ;; Add all these names to the list.
            (mapcar
             (lambda (name) (setq ret (cons (list name bpt) ret)))
             names)))))
    ret))


(defun ots-client-entries ()
  "Return a list of client names for use by `completing-read'."
  (let ((boundary nil)
        (ret      ()))
    (ots-with-org-file ots-org-file
      (save-match-data
        ;; First establish the boundary below which clients are not listed.
        (re-search-forward "^\* Bureaucracy")
        (beginning-of-line)
        (setq boundary (point))
        ;; Now find all client entries before the boundary.
        (goto-char (point-min))
        (ots-org-headings 2 boundary)))))

(defun ots-visit-client (client-name)
  "Go to CLIENT-NAME's entry in ots.org and narrow to the entry.
Interactively, prompt completingly for client.

To remove the narrowing effect and see the rest of the buffer,
widen your view, which is by default bound to C-x n w."
  (interactive
   (list (let ((completion-ignore-case t))
           (completing-read "OTS client: " (ots-client-entries)))))
  (find-file ots-org-file)
  (widen)
  (goto-char (point-min))
  (let ((posn (cadr (assoc-if (lambda (x) (equalp client-name x)) (ots-client-entries)))))
    (goto-char posn)
    (org-narrow-to-element)
    (org-show-subtree)))

(defun ots-asciidoc-underline (b e)
  "Surround the region from B to E with Asciidoc formatting for underline.
The formatting will really be implemented with pass-through to HTML.
The region should contain only the text to be underlined; any further
Asciidoc formatting should be outside the region."
  (interactive "r")
  (setq e (copy-marker e))
  (goto-char b)
  (insert "pass:[<span style=\"text-decoration: underline;\" >")
  (goto-char e)
  (insert "</span>]"))

(defun ots-org-filter-buffer-tags ()
  "Prompt for a tag in this org-mode buffer, and show headlines matching it."
  ;; It'd be nice take TAG as a parameter, but the way `org-tags-view'
  ;; works there's no easy way to pass the tag as an argument, even
  ;; if we use `org-get-buffer-tags' interactively to get the tag.
  (interactive)
  (let ((org-agenda-files (list (buffer-file-name)))
        (org-use-tag-inheritance nil))
    (org-tags-view)))


;;; The OTS CRM system.  Coming soon to theaters everywhere.

(defconst ots-crm-file (concat ots-dir "org/crm.org")
  "Path to the OTS crm.org file.")

(defun ots-crm-entries ()
  "Return a list of crm entry names and positions.
This works like `ots-org-headings' called in the crm file, 
and the return value is thus suitable for `completing-read'."
  (ots-with-org-file ots-crm-file (ots-org-headings 1)))

(defun ots-crm-entry-boundaries (start)
  "Return the boundaries of the crm entry that starts at START.
The return value is a list of the form `(beg-marker end-marker)'.
The elements are markers representing the first position of the
entry and and the first position *after* the entry, in `ots-crm-file'."
  (ots-with-org-file ots-crm-file
    (goto-char start)
    (end-of-line)
    (re-search-forward "^\\*\\s-+[^:\n]*" nil "end")
    (beginning-of-line)
    (list (copy-marker start) (copy-marker (point)))))

(defvar-local ots-crm-entry-bounds nil
  "When non-nil, gives the start and end of a crm entry.
The value is a list: `(beg-marker end-marker)'.  This variable is
automatically buffer-local, and is normally only set in buffer used to
display a read-only copy of a crm entry, to enable jumping directly
from that copy to the actual crm entry in `ots-crm-file'.")

(defun ots-crm-display (crm-entry)
  "Display CRM-ENTRY in the \"*OTS CRM*\" buffer.
Bind Return to visiting the corresponding real entry in `ots-crm-file',
and bind 'q' to `bury-buffer'."
  (let ((buf (get-buffer-create "*OTS CRM*")))
    (save-excursion
      (set-buffer buf)
      (read-only-mode -1)
      (erase-buffer)
      (insert (car crm-entry))
      (goto-char (point-min))
      (read-only-mode)
      (setq-local ots-crm-entry-bounds (cdr crm-entry))
      (local-set-key "q" (lambda () (interactive)
                           (delete-windows-on (current-buffer))))
      (local-set-key 
       "\r" 
       (lambda () 
         (interactive)
         ;; If Elisp were a lexically scoped language, the way to do
         ;; this would be obvious.  However, Elisp is dynamically
         ;; scoped, so when we switch to the `ots-crm-file' buffer,
         ;; it's tricky to hold on to the value of the buffer-local
         ;; variable `ots-crm-entry-bounds' we left behind in the
         ;; display buffer.  These otherwise completely unnecessary
         ;; `let' bindings are the solution.  Yay.
         (let ((start          (car  ots-crm-entry-bounds))
               (end            (cadr ots-crm-entry-bounds))
               (highlight-face (if (facep 'highlight) 
                                   'highlight ; Is this a standard or not?
                                 ;; In case not, default to manual highlight.
                                 '(:background "grey20"))))
           (switch-to-buffer
            (let ((crm-buf (find-file ots-crm-file)))
              (widen)
              (goto-char start)
              (delete-all-overlays) ; this is a bit destructive, hmm
              (overlay-put (make-overlay start end) 'face highlight-face)
              ;; If the user asked to go to the CRM file, assume she
              ;; intends to focus on it; make it the main window.
              (delete-other-windows)
              (recenter)
              crm-buf))))))
    ;; Totally not sure I'm doing this right.  The `display-buffer'
    ;; doc string is one of the seven wonders of the ancient world.
    (display-buffer buf
                    '(display-buffer-at-bottom 
                      . ((window-height 
                          . shrink-window-if-larger-than-buffer))))))

(defun ots-crm-lookup (name)
  "Jump to crm entry NAME.  Interactively, prompt completingly for NAME."
  (interactive
   (list (let ((completion-ignore-case t))
           ;; Oddly, the "req-match" value below for the REQUIRE-MATCH
           ;; parameter of `completing-read' still allows successful
           ;; completion of the empty string.  I don't know why there
           ;; is no option to require a true match, and there doesn't
           ;; seem to be any way to use the PREDICATE parameter to
           ;; achieve that effect either.  Improvements welcome.
           (completing-read "OTS CRM lookup: "
                            (ots-crm-entries) nil "req-match"))))
  (let* ((bounds (ots-crm-entry-boundaries (cadr (assoc name (ots-crm-entries)))))
         (start  (car bounds))
         (end    (cadr bounds)))
    (switch-to-buffer (find-file-noselect ots-crm-file))
    (widen)
    (goto-char start)
    (forward-line 1)
    (narrow-to-region start end)))

(defun ots-new-crm-entry ()
  "Insert a template for a new CRM entry."
  ;; This is totally doable with `define-skeleton', but I'm not sure
  ;; when that was introduced into Emacs.  We want this to work for
  ;; everyone, whatever version of Emacs they're running.
  (interactive)
  (insert "* NAME HERE\n"
          "pronouns: \n"
          "title: \n"
          "department: \n"
          "organization: \n"
          "email: \n"
          "  - email1\n"
          "  - email2\n"
          "cell: \n"
          "skype: \n"
          "address: |-\n"
          "  you can have\n"
          "  multi-line addresses\n"
          "gpg: \n"
          "birthday: \n"
          "twitter: \n"
          "website: \n"
          "note: >-\n"
          "   ...and multi-line\n"
          "   notes.  I'm not sure why\n"
          "   the continuation indicator\n"
          "   is different than it was\n"
          "   for email.  Maybe someone\n"
          "   who knows can explain.\n"
          "\n"
          )
  (search-backward "* NAME HERE")
  (beginning-of-line)
  (forward-char 2))

(defun ots-conference-call-info (&optional insert)
  "Echo, make pasteable, and return OTS conf call dial-in info.
With optional prefix arg INSERT, also insert it into the buffer at point."
  (interactive "P")
  (let ((txt (ots-with-org-file ots-crm-file
               (search-forward "OTS Conference Call")
               (search-forward "+1-")
               (forward-char -3)
               (buffer-substring-no-properties 
                (point) (progn (end-of-line) (point))))))
    (when insert (insert txt))
    (let ((select-enable-primary t)) (kill-new txt))
    (message "%s" txt)
    txt))

(defun ots-copy-link ()
  "Put the link around point into the kill-ring (i.e., the clipboard).
The link around point can either be a plain URL, or an Org Mode 
bracketed link as per `org-bracket-link-regexp'.  If there is no link
around point, just return nil."
  (interactive)
  (save-match-data
    (let ((link nil))
      (cond
       ((org-in-regexp org-bracket-link-regexp 1)
        (setq link (org-link-unescape (match-string-no-properties 1))))
       ((thing-at-point 'url)
        (setq link (thing-at-point 'url))))
      (when link
        (kill-new link)
        (message "%s" link)
        link))))


;;; Forwarding pointers for the ref system that used to be here.

(defun ots-ref-forward-to-published ()
  (interactive)
  (display-message-or-buffer
   (concat 
    "The OTS ref system is now published as 'oref.el'.\n"
    "\n"
    "The new recommended entry point is `oref-do-ref',\n"
    "which replaces `ots-do-ref'.  Please update your\n"
    "Emacs configuration accordingly.\n"
    "\n"
    "https://github.com/OpenTechStrategies/ots-tools/blob/master/emacs-tools/oref.el\n"
    "\n"
    )))
(defalias 'ots-set-ref 'ots-ref-forward-to-published)
(defalias 'ots-find-ref 'ots-ref-forward-to-published)
(defalias 'ots-do-ref 'ots-ref-forward-to-published)



(defun ots-shell-command-on-region-capture (&optional command)
	"Execute shell command on region, and put the output into the kill ring."
	(interactive)
	(if command
			(shell-command-on-region (point) (mark) command)
		(call-interactively 'shell-command-on-region))
	(switch-to-buffer "*Shell Command Output*")
	(kill-ring-save (point-min) (point-max))
	(switch-to-buffer nil)
	)
(defun ots-send-region-to-hastebin ()
	"Send region to hastebin and put resulting URL in kill ring.
Requires the 'haste' client program; do 'gem install haste' or see
https://github.com/seejohnrun/haste-client."
	(interactive)
	(ots-shell-command-on-region-capture "haste")
	)

;;; OTS preferences for various modes.

(defun ots-markdown-mode-hook ()
  "Hook for `markdown-mode' (note: *not* for `ots-markdown-mode')."
  (setq indent-tabs-mode nil))

(add-hook 'markdown-mode-hook 'ots-markdown-mode-hook)

(defun ots-markdown-mode ()
  "OTS Markdown Mode is not a real mode, it's just a shim.

http://jblevins.org/projects/markdown-mode/ has a Markdown Mode
for Emacs, but not everyone at OTS has that mode installed (it's
not part of Emacs by default, at least as of Emacs 26.0.5).

Still, we want our Markdown preferences to apply to any Markdown
file we edit, whether its buffer is in Markdown Mode or not.  So
OTS Markdown Mode provides those preferences unconditionally, while
also switching to real `markdown-mode' iff it is available."
  ;; Fake up our own major mode first
  (kill-all-local-variables)
  (setq major-mode 'ots-markdown-mode)
  (setq mode-name "OTS Fake Markdown Mode")
  ;; Note we deliberately do not do this:
  ;; 
  ;;   (run-mode-hooks 'ots-markdown-mode-hook)
  ;; 
  ;; ...because while there is an `ots-markdown-mode-hook', it's
  ;; meant to be run by real `markdown-mode' (if installed).
  ;; Meanwhile, our fake shim mode need not run any mode hook.
  ;;
  ;; If the user has Markdown mode installed, switch to it.
  (when (fboundp 'markdown-mode) (markdown-mode))
  ;; Make absolutely sure about the TABs.
  (setq indent-tabs-mode nil))

(mapcar 
 (lambda (e) (add-to-list 'auto-mode-alist (cons e 'ots-markdown-mode)))
 (list "\\.md\\'" "\\.mdwn\\'" "\\.markdown\\'"))

;;; Local Variables:
;;; indent-tabs-mode: nil
;;; End:
