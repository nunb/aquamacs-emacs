;;; menu-bar.el --- define a default menu bar

;; Copyright (C) 1993-1995, 2000-2014 Free Software Foundation, Inc.

;; Author: Richard M. Stallman
;; Maintainer: emacs-devel@gnu.org
;; Keywords: internal, mouse
;; Package: emacs

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;; Avishai Yacobi suggested some menu rearrangements.

;;; Commentary:

;;; Code:

;; useful functions (stump)

(defun aq-binding (any)
  nil)

;; This is referenced by some code below; it is defined in uniquify.el
(defvar uniquify-buffer-name-style)

;; From emulation/cua-base.el; used below
(defvar cua-enable-cua-keys)


;; Don't clobber an existing menu-bar keymap, to preserve any menu-bar key
;; definitions made in loaddefs.el.
(or (lookup-key global-map [menu-bar])
    (bindings--define-key global-map [menu-bar] (make-sparse-keymap "menu-bar")))

;; Force Help item to come last, after the major mode's own items.
;; The symbol used to be called `help', but that gets confused with the
;; help key.
(setq menu-bar-final-items '(buffer services help-menu))

;; This definition is just to show what this looks like.
;; It gets modified in place when menu-bar-update-buffers is called.
(defvar global-buffers-menu-map (make-sparse-keymap "Buffers"))

;; Only declared obsolete (and only made a proper alias) in 23.3.
(define-obsolete-variable-alias
  'menu-bar-files-menu 'menu-bar-file-menu "22.1")

(defvar menu-bar-file-menu
  (let ((menu (make-sparse-keymap "File")))

    ;; This is referenced by some code below; it is defined in uniquify.el
    (defvar uniquify-buffer-name-style)

    ;; From emulation/cua-base.el; used below
    (defvar cua-enable-cua-keys)



    ;; The "File" menu items
    (bindings--define-key menu [exit-emacs]
      '(menu-item "Quit" save-buffers-kill-terminal
                  :help "Save unsaved buffers, then exit"))

    (bindings--define-key menu [separator-exit]
      menu-bar-separator)

    ;; Don't use delete-frame as event name because that is a special
    ;; event.

    (bindings--define-key menu [separator-print]
      menu-bar-separator)

    (bindings--define-key menu [recover-session]
      '(menu-item "Recover Crashed Session" recover-session
                  :enable
                  (and auto-save-list-file-prefix
                       (file-directory-p
                        (file-name-directory auto-save-list-file-prefix))
                       (directory-files
                        (file-name-directory auto-save-list-file-prefix)
                        nil
                        (concat "\\`"
                                (regexp-quote
                                 (file-name-nondirectory
                                  auto-save-list-file-prefix)))
                        t))
                  :help "Recover edits from a crashed session"))
    (bindings--define-key menu [revert-buffer]
      '(menu-item "Revert Buffer" revert-buffer
                  :enable (or (not (eq revert-buffer-function
                                       'revert-buffer--default))
                              (not (eq
                                    revert-buffer-insert-file-contents-function
                                    'revert-buffer-insert-file-contents--default-function))
                              (and buffer-file-number
			       (or (and buffer-file-name
					(file-remote-p buffer-file-name))
				   (buffer-modified-p)
                                       (not (verify-visited-file-modtime
                                             (current-buffer))))))
                  :help "Re-read current buffer from its file"))
    (bindings--define-key menu [write-file]
      '(menu-item "Save As..." write-file
                  :enable (and (menu-bar-menu-frame-live-and-visible-p)
                               (menu-bar-non-minibuffer-window-p))
                  :help "Write current buffer to another file"))
    (bindings--define-key menu [save-buffer]
      '(menu-item "Save" save-buffer
                  :enable (and (buffer-modified-p)
                               (buffer-file-name)
			   (menu-bar-menu-frame-live-and-visible-p)
                               (menu-bar-non-minibuffer-window-p))
                  :help "Save current buffer to its file"))

    (bindings--define-key menu [separator-save]
      menu-bar-separator)


    (bindings--define-key menu [kill-buffer]
      '(menu-item "Close" kill-this-buffer
                  :enable (kill-this-buffer-enabled-p)
                  :help ,(purecopy "Discard (kill) current buffer")))
    (bindings--define-key menu [insert-file]
      `(menu-item ,(purecopy "Insert File...") insert-file
	      :enable (and (menu-bar-non-minibuffer-window-p)
			   (menu-bar-menu-frame-live-and-visible-p))
                  :help ,(purecopy "Insert another file into current buffer")))
    (bindings--define-key menu [dired]
      `(menu-item ,(purecopy "Open Directory...") dired
	      :enable (and (menu-bar-non-minibuffer-window-p)
			   (menu-bar-menu-frame-live-and-visible-p))
	      :help ,(purecopy "Read a directory, to operate on its files")))
    (bindings--define-key menu [open-file]
      `(menu-item ,(purecopy "Open File...") menu-find-file-existing
                  :enable (menu-bar-non-minibuffer-window-p)
                  :help "Read an existing file into an Emacs buffer"))
    (bindings--define-key menu [new-file]
      '(menu-item "Visit New File..." find-file
                  :enable (menu-bar-non-minibuffer-window-p)
                  :help "Specify a new file's name, to edit the file"))

    menu))

(defun menu-find-file-existing ()
  "Edit the existing file FILENAME."
  (interactive)
  (let* ((mustmatch (not (and (fboundp 'x-uses-old-gtk-dialog)
			      (x-uses-old-gtk-dialog))))
	 (filename (car (find-file-read-args "Find file: " mustmatch))))
    (if mustmatch
	(find-file-existing filename)
      (find-file filename))))

;; The "Edit->Search" submenu
(defvar menu-bar-last-search-type nil
  "Type of last non-incremental search command called from the menu.")

(defun nonincremental-repeat-search-forward ()
  "Search forward for the previous search string or regexp."
  (interactive)
  (cond
   ((and (eq menu-bar-last-search-type 'string)
	 search-ring)
    (search-forward (car search-ring)))
   ((and (eq menu-bar-last-search-type 'regexp)
	 regexp-search-ring)
    (re-search-forward (car regexp-search-ring)))
   (t
    (error "No previous search"))))

(defun nonincremental-repeat-search-backward ()
  "Search backward for the previous search string or regexp."
  (interactive)
  (cond
   ((and (eq menu-bar-last-search-type 'string)
	 search-ring)
    (search-backward (car search-ring)))
   ((and (eq menu-bar-last-search-type 'regexp)
	 regexp-search-ring)
    (re-search-backward (car regexp-search-ring)))
   (t
    (error "No previous search"))))

(defun nonincremental-search-forward (string)
  "Read a string and search for it nonincrementally."
  (interactive "sSearch for string: ")
  (setq menu-bar-last-search-type 'string)
  (if (equal string "")
      (search-forward (car search-ring))
    (isearch-update-ring string nil)
    (search-forward string)))

(defun nonincremental-search-backward (string)
  "Read a string and search backward for it nonincrementally."
  (interactive "sSearch for string: ")
  (setq menu-bar-last-search-type 'string)
  (if (equal string "")
      (search-backward (car search-ring))
    (isearch-update-ring string nil)
    (search-backward string)))

(defun nonincremental-re-search-forward (string)
  "Read a regular expression and search for it nonincrementally."
  (interactive "sSearch for regexp: ")
  (setq menu-bar-last-search-type 'regexp)
  (if (equal string "")
      (re-search-forward (car regexp-search-ring))
    (isearch-update-ring string t)
    (re-search-forward string)))

(defun nonincremental-re-search-backward (string)
  "Read a regular expression and search backward for it nonincrementally."
  (interactive "sSearch for regexp: ")
  (setq menu-bar-last-search-type 'regexp)
  (if (equal string "")
      (re-search-backward (car regexp-search-ring))
    (isearch-update-ring string t)
    (re-search-backward string)))

;; The Edit->Search->Incremental Search menu
(defvar menu-bar-i-search-menu
  (let ((menu (make-sparse-keymap "Incremental Search")))
    (bindings--define-key menu [isearch-backward-regexp]
      '(menu-item "Backward Regexp..." isearch-backward-regexp
        :help "Search backwards for a regular expression as you type it"))
    (bindings--define-key menu [isearch-forward-regexp]
      '(menu-item "Forward Regexp..." isearch-forward-regexp
        :help "Search forward for a regular expression as you type it"))
    (bindings--define-key menu [isearch-backward]
      '(menu-item "Backward String..." isearch-backward
        :help "Search backwards for a string as you type it"))
    (bindings--define-key menu [isearch-forward]
      '(menu-item "Forward String..." isearch-forward
        :help "Search forward for a string as you type it"))
    menu))

(defvar menu-bar-search-menu
  (let ((menu (make-sparse-keymap "Search")))

    (bindings--define-key menu [i-search]
      `(menu-item "Incremental Search" ,menu-bar-i-search-menu))
    (bindings--define-key menu [separator-tag-isearch]
      menu-bar-separator)

    (bindings--define-key menu [tags-continue]
      `(menu-item ,(purecopy "Continue Tags Search") tags-loop-continue
                  :help ,(purecopy "Continue last tags search operation")))
    (bindings--define-key menu [tags-srch]
      `(menu-item ,(purecopy "Search Tagged Files...") tags-search
                  :help ,(purecopy "Search for a regexp in all tagged files")))
    (bindings--define-key menu [separator-tag-search]
      `(menu-item ,(purecopy "--")))
    (bindings--define-key menu [grep]
      `(menu-item ,(purecopy "Search Files (Grep)...") grep
		  :help ,(purecopy "Search files for strings or regexps (with Grep)")))
    (bindings--define-key menu [separator-grep-search]
      `(menu-item ,(purecopy "--")))

    (bindings--define-key menu [repeat-search-back]
      '(menu-item "Repeat Backwards"
                  nonincremental-repeat-search-backward
                  :enable (or (and (eq menu-bar-last-search-type 'string)
                                   search-ring)
                              (and (eq menu-bar-last-search-type 'regexp)
                                   regexp-search-ring))
                  :help "Repeat last search backwards"))
    (bindings--define-key menu [repeat-search-fwd]
      '(menu-item "Repeat Forward"
                  nonincremental-repeat-search-forward
                  :enable (or (and (eq menu-bar-last-search-type 'string)
                                   search-ring)
                              (and (eq menu-bar-last-search-type 'regexp)
                                   regexp-search-ring))
                  :help "Repeat last search forward"))
    (bindings--define-key menu [separator-repeat-search]
      menu-bar-separator)

    (bindings--define-key menu [re-search-backward]
      '(menu-item "Regexp Backwards..."
                  nonincremental-re-search-backward
                  :help "Search backwards for a regular expression"))
    (bindings--define-key menu [re-search-forward]
      '(menu-item "Regexp Forward..."
                  nonincremental-re-search-forward
                  :help "Search forward for a regular expression"))

    (bindings--define-key menu [search-backward]
      '(menu-item "String Backwards..."
                  nonincremental-search-backward
                  :help "Search backwards for a string"))
    (bindings--define-key menu [search-forward]
      '(menu-item "String Forward..." nonincremental-search-forward
                  :help "Search forward for a string"))
    menu))

;; The Edit->Replace submenu

(defvar menu-bar-replace-menu
  (let ((menu (make-sparse-keymap "Replace")))
    (bindings--define-key menu [tags-repl-continue]
      '(menu-item "Continue Replace" tags-loop-continue
                  :help "Continue last tags replace operation"))
    (bindings--define-key menu [tags-repl]
      '(menu-item "Replace in Tagged Files..." tags-query-replace
        :help "Interactively replace a regexp in all tagged files"))
    (bindings--define-key menu [separator-replace-tags]
      menu-bar-separator)

    (bindings--define-key menu [query-replace-regexp]
      '(menu-item "Replace Regexp..." query-replace-regexp
                  :enable (not buffer-read-only)
                  :help "Replace regular expression interactively, ask about each occurrence"))
    (bindings--define-key menu [query-replace]
      '(menu-item "Replace String..." query-replace
        :enable (not buffer-read-only)
        :help "Replace string interactively, ask about each occurrence"))
    menu))

(defvar yank-menu (cons (purecopy "Select Yank") nil))
(fset 'yank-menu (cons 'keymap yank-menu))

;;; Assemble the top-level Edit menu items.
(defvar menu-bar-edit-menu
  (let ((menu (make-sparse-keymap "Edit")))
   
    (bindings--define-key menu [props]
      `(menu-item ,(purecopy "Text Properties") facemenu-menu
		  :enable (menu-bar-menu-frame-live-and-visible-p)))

(defvar menu-bar-goto-menu
  (let ((menu (make-sparse-keymap "Go To")))


    (bindings--define-key menu [set-tags-name]
      `(menu-item ,(purecopy "Set Tags File Name...") visit-tags-table
                  :help ,(purecopy "Tell Tags commands which tag table file to use")))

    (bindings--define-key menu [separator-tag-file]
      menu-bar-separator)

    (bindings--define-key menu [apropos-tags]
      '(menu-item "Tags Apropos..." tags-apropos
                  :help "Find function/variables whose names match regexp"))
    (bindings--define-key menu [next-tag-otherw]
      '(menu-item "Next Tag in Other Window"
                  menu-bar-next-tag-other-window
                  :enable (and (boundp 'tags-location-ring)
                               (not (ring-empty-p tags-location-ring)))
                  :help "Find next function/variable matching last tag name in another window"))

    (bindings--define-key menu [next-tag]
      '(menu-item "Find Next Tag"
                  menu-bar-next-tag
                  :enable (and (boundp 'tags-location-ring)
                               (not (ring-empty-p tags-location-ring)))
                  :help "Find next function/variable matching last tag name"))
    (bindings--define-key menu [find-tag-otherw]
      '(menu-item "Find Tag in Other Window..." find-tag-other-window
                  :help "Find function/variable definition in another window"))
    (bindings--define-key menu [find-tag]
      '(menu-item "Find Tag..." find-tag
                  :help "Find definition of function or variable"))

    (bindings--define-key menu [separator-tags]
      menu-bar-separator)

    (bindings--define-key menu [end-of-buf]
      '(menu-item "Goto End of Buffer" end-of-buffer))
    (bindings--define-key menu [beg-of-buf]
      '(menu-item "Goto Beginning of Buffer" beginning-of-buffer))
    (bindings--define-key menu [go-to-pos]
      '(menu-item "Goto Buffer Position..." goto-char
                  :help "Read a number N and go to buffer position N"))
    (bindings--define-key menu [go-to-line]
      '(menu-item "Goto Line..." goto-line
                  :help "Read a line number and go to that line"))
    menu))


(defvar yank-menu (cons (purecopy "Select Yank") nil))
(fset 'yank-menu (cons 'keymap yank-menu))

    (bindings--define-key menu [props]
      `(menu-item ,(purecopy "Text Properties") facemenu-menu))

    ;; ns-win.el said: Add spell for platform consistency.
    (if (featurep 'ns)
        (bindings--define-key menu [spell]
          `(menu-item "Spell" ispell-menu-map)))

    (bindings--define-key menu [fill]
      `(menu-item "Fill" fill-region
                  :enable (and mark-active (not buffer-read-only))
                  :help
                  "Fill text in region to fit between left and right margin"))

    (bindings--define-key menu [separator-bookmark]
      menu-bar-separator)

    (bindings--define-key menu [bookmark]
      `(menu-item "Bookmarks" menu-bar-bookmark-map))

    (bindings--define-key menu [goto]
      `(menu-item ,(purecopy "Go To") ,menu-bar-goto-menu
		  :enable (menu-bar-menu-frame-live-and-visible-p)))

    (bindings--define-key menu [replace]
      `(menu-item ,(purecopy "Replace") ,menu-bar-replace-menu
		  :enable (menu-bar-menu-frame-live-and-visible-p)))

    (bindings--define-key menu [search]
      `(menu-item ,(purecopy "Search") ,menu-bar-search-menu
		  :enable (menu-bar-menu-frame-live-and-visible-p)))

    (bindings--define-key menu [separator-search]
      menu-bar-separator)

    (bindings--define-key menu [mark-whole-buffer]
      `(menu-item ,(purecopy "Select All") mark-whole-buffer
	      :enable (menu-bar-menu-frame-live-and-visible-p)
                  :help ,(purecopy "Mark the whole buffer for a subsequent cut/copy")))

    (bindings--define-key menu [clear]
      `(menu-item ,(purecopy "Clear") delete-region
                  :enable (and mark-active
                               (not buffer-read-only))
                  :help
                  "Delete the text in region between mark and current position"))


    (bindings--define-key menu (if (featurep 'ns) [select-paste]
                       [paste-from-menu])
      ;; ns-win.el said: Change text to be more consistent with
      ;; surrounding menu items `paste', etc."
      `(menu-item ,(if (featurep 'ns) "Select and Paste"
                     "Paste from Kill Menu") yank-menu
                  :enable (and (cdr yank-menu) (not buffer-read-only))
                  :help "Choose a string from the kill ring and paste it"))
    (bindings--define-key menu [paste]
      '(menu-item "Paste" yank
                  :enable (and (or
                                ;; Emacs compiled --without-x (or --with-ns)
                                ;; doesn't have x-selection-exists-p.
                                (and (fboundp 'x-selection-exists-p)
                                     (x-selection-exists-p 'CLIPBOARD))
                                (if (featurep 'ns) ; like paste-from-menu
                                    (cdr yank-menu)
                                  kill-ring))
                               (not buffer-read-only))
                  :help "Paste (yank) text most recently cut/copied"))
    (bindings--define-key menu [copy]
      ;; ns-win.el said: Substitute a Copy function that works better
      ;; under X (for GNUstep).
      `(menu-item "Copy" ,(if (featurep 'ns)
                              'ns-copy-including-secondary
                            'kill-ring-save)
                  :enable mark-active
                  :help "Copy text in region between mark and current position"
                  :keys ,(if (featurep 'ns)
                             "\\[ns-copy-including-secondary]"
                           "\\[kill-ring-save]")))
    (bindings--define-key menu [cut]
      `(menu-item ,(purecopy "Cut") kill-region
	      :enable (and mark-active (not buffer-read-only)
			   (menu-bar-menu-frame-live-and-visible-p))
                  :help
                  "Cut (kill) text in region between mark and current position"))
    ;; ns-win.el said: Separate undo from cut/paste section.
    (if (featurep 'ns)
        (bindings--define-key menu [separator-undo] menu-bar-separator))

    (bindings--define-key menu [undo]
      '(menu-item "Undo" undo
                  :enable (and (not buffer-read-only)
			   (menu-bar-menu-frame-live-and-visible-p)
                               (not (eq t buffer-undo-list))
                               (if (eq last-command 'undo)
                                   (listp pending-undo-list)
                                 (consp buffer-undo-list)))
                  :help "Undo last operation"))

    menu))


(defun menu-bar-next-tag-other-window ()
  "Find the next definition of the tag already specified."
  (interactive)
  (find-tag-other-window nil t))

(defun menu-bar-next-tag ()
  "Find the next definition of the tag already specified."
  (interactive)
  (find-tag nil t))

(define-obsolete-function-alias
  'menu-bar-kill-ring-save 'kill-ring-save "24.1")

;; These are alternative definitions for the cut, paste and copy
;; menu items.  Use them if your system expects these to use the clipboard.

(put 'clipboard-kill-region 'menu-enable
     '(and mark-active (not buffer-read-only)))
(put 'clipboard-kill-ring-save 'menu-enable 'mark-active)
(put 'clipboard-yank 'menu-enable
     '(and (or (not (fboundp 'x-selection-exists-p))
	       (x-selection-exists-p)
	       (x-selection-exists-p 'CLIPBOARD))
 	   (not buffer-read-only)))

(defun clipboard-yank ()
  "Insert the clipboard contents, or the last stretch of killed text."
  (interactive "*")
  (let ((x-select-enable-clipboard t))
    (yank)))

(defun clipboard-kill-ring-save (beg end &optional region)
  "Copy region to kill ring, and save in the X clipboard."
  (interactive "r\np")
  (let ((x-select-enable-clipboard t))
    (kill-ring-save beg end region)))

(defun clipboard-kill-region (beg end &optional region)
  "Kill the region, and save it in the X clipboard."
  (interactive "r\np")
  (let ((x-select-enable-clipboard t))
    (kill-region beg end region)))

(defun menu-bar-enable-clipboard ()
  "Make CUT, PASTE and COPY (keys and menu bar items) use the clipboard.
Do the same for the keys of the same name."
  (interactive)
  ;; These are Sun server keysyms for the Cut, Copy and Paste keys
  ;; (also for XFree86 on Sun keyboard):
  (bindings--define-key global-map [f20] 'clipboard-kill-region)
  (bindings--define-key global-map [f16] 'clipboard-kill-ring-save)
  (bindings--define-key global-map [f18] 'clipboard-yank)
  ;; X11R6 versions:
  (bindings--define-key global-map [cut] 'clipboard-kill-region)
  (bindings--define-key global-map [copy] 'clipboard-kill-ring-save)
  (bindings--define-key global-map [paste] 'clipboard-yank))

;; The "Options" menu items

(defvar menu-bar-custom-menu
  (let ((menu (make-sparse-keymap "Customize")))

    (bindings--define-key menu [customize-apropos-faces]
      '(menu-item "Faces Matching..." customize-apropos-faces
                  :help "Browse faces matching a regexp or word list"))
    (bindings--define-key menu [customize-apropos-options]
      '(menu-item "Options Matching..." customize-apropos-options
                  :help "Browse options matching a regexp or word list"))
    (bindings--define-key menu [customize-apropos]
      '(menu-item "All Settings Matching..." customize-apropos
                  :help "Browse customizable settings matching a regexp or word list"))
    (bindings--define-key menu [separator-1]
      menu-bar-separator)
    (bindings--define-key menu [customize-group]
      '(menu-item "Specific Group..." customize-group
                  :help "Customize settings of specific group"))
    (bindings--define-key menu [customize-face]
      '(menu-item "Specific Face..." customize-face
                  :help "Customize attributes of specific face"))
    (bindings--define-key menu [customize-option]
      '(menu-item "Specific Option..." customize-option
                  :help "Customize value of specific option"))
    (bindings--define-key menu [separator-2]
      menu-bar-separator)
    (bindings--define-key menu [customize-changed-options]
      '(menu-item "New Options..." customize-changed-options
                  :help "Options added or changed in recent Emacs versions"))
    (bindings--define-key menu [customize-saved]
      '(menu-item "Saved Options" customize-saved
                  :help "Customize previously saved options"))
    (bindings--define-key menu [separator-3]
      menu-bar-separator)
    (bindings--define-key menu [customize-browse]
      '(menu-item "Browse Customization Groups" customize-browse
                  :help "Browse all customization groups"))
    (bindings--define-key menu [customize]
      '(menu-item "Top-level Customization Group" customize
                  :help "The master group called `Emacs'"))
    (bindings--define-key menu [customize-themes]
      '(menu-item "Custom Themes" customize-themes
                  :help "Choose a pre-defined customization theme"))
    menu))
;(defvar menu-bar-preferences-menu (make-sparse-keymap "Preferences"))

(defmacro menu-bar-make-mm-toggle (fname doc help &optional props)
  "Make a menu-item for a global minor mode toggle.
FNAME is the minor mode's name (variable and function).
DOC is the text to use for the menu entry.
HELP is the text to use for the tooltip.
PROPS are additional properties."
  `'(menu-item ,doc ,fname
	       ,@props
	       :help ,help
	       :button (:toggle . (and (default-boundp ',fname)
				       (default-value ',fname)))))

(defmacro menu-bar-make-toggle (name variable doc message help &rest body)
  `(progn
     (defun ,name (&optional interactively)
       ,(concat "Toggle whether to " (downcase (substring help 0 1))
		(substring help 1) ".
In an interactive call, record this option as a candidate for saving
by \"Save Options\" in Custom buffers.")
       (interactive "p")
       (if ,(if body `(progn . ,body)
	      `(progn
		 (custom-load-symbol ',variable)
		 (let ((set (or (get ',variable 'custom-set) 'set-default))
		       (get (or (get ',variable 'custom-get) 'default-value)))
		   (funcall set ',variable (not (funcall get ',variable))))))
	   (message ,message "enabled globally")
  	 (message ,message "disabled globally"))
       ;; The function `customize-mark-as-set' must only be called when
       ;; a variable is set interactively, as the purpose is to mark it as
       ;; a candidate for "Save Options", and we do not want to save options
       ;; the user have already set explicitly in his init file.
       (if interactively (customize-mark-as-set ',variable)))
     '(menu-item ,doc ,name
		 :help ,help
		 :button (:toggle . (and (default-boundp ',variable)
					 (default-value ',variable))))))

;; Function for setting/saving default font.

(defun menu-set-font ()
  "Interactively select a font and make it the default on all existing frames."
  (interactive)
  (set-frame-font (if (fboundp 'x-select-font)
		      (x-select-font)
		    (mouse-select-font))
		  nil t))

(defun menu-bar-options-save ()
  "Save current values of Options menu items using Custom."
  (interactive)
  (let ((need-save nil))
    ;; These are set with menu-bar-make-mm-toggle, which does not
    ;; put on a customized-value property.
    (dolist (elt '(global-show-newlines-mode global-linum-mode
		   column-number-mode size-indication-mode
		   cua-mode show-paren-mode transient-mark-mode
		   display-time-mode display-battery-mode
		   visual-line-mode))
      (and (customize-mark-to-save elt)
	   (setq need-save t)))
    ;; These are set with `customize-set-variable'.
    (dolist (elt '(scroll-bar-mode
		   debug-on-quit debug-on-error
		   ;; Somehow this works, when tool-bar and menu-bar don't.
		   tooltip-mode
		   save-place uniquify-buffer-name-style fringe-mode
		   indicate-empty-lines indicate-buffer-boundaries
		   case-fold-search font-use-system-font
		   current-language-environment default-input-method
		   ;; Saving `text-mode-hook' is somewhat questionable,
		   ;; as we might get more than we bargain for, if
		   ;; other code may has added hooks as well.
		   ;; Nonetheless, not saving it would like be confuse
		   ;; more often.
		   ;; -- Per Abrahamsen <abraham@dina.kvl.dk> 2002-02-11.
		   text-mode-hook tool-bar-position
		   word-wrap truncate-lines global-visual-line-mode global-auto-fill-mode))
      (and (get elt 'customized-value)
	   (customize-mark-to-save elt)
	   (setq need-save t)))
    (when (get 'default 'customized-face)
      (put 'default 'saved-face (get 'default 'customized-face))
      (put 'default 'customized-face nil)
      (setq need-save t))
    ;; Save if we changed anything.
    (when need-save
      (custom-save-all))))


;;; Assemble all the top-level items of the "Options" menu



(defun menu-bar-showhide-fringe-ind-customize ()
  "Show customization buffer for `indicate-buffer-boundaries'."
  (interactive)
  (customize-variable 'indicate-buffer-boundaries))

(defun menu-bar-showhide-fringe-ind-mixed ()
  "Display top and bottom indicators in opposite fringes, arrows in right."
  (interactive)
  (customize-set-variable 'indicate-buffer-boundaries
			  '((t . right) (top . left))))

(defun menu-bar-showhide-fringe-ind-box ()
  "Display top and bottom indicators in opposite fringes."
  (interactive)
  (customize-set-variable 'indicate-buffer-boundaries
			  '((top . left) (bottom . right))))
(defun menu-bar-showhide-fringe-ind-right ()
  "Display buffer boundaries and arrows in the right fringe."
  (interactive)
  (customize-set-variable 'indicate-buffer-boundaries 'right))

(defun menu-bar-showhide-fringe-ind-left ()
  "Display buffer boundaries and arrows in the left fringe."
  (interactive)
  (customize-set-variable 'indicate-buffer-boundaries 'left))

(defun menu-bar-showhide-fringe-ind-none ()
  "Do not display any buffer boundary indicators."
  (interactive)
  (customize-set-variable 'indicate-buffer-boundaries nil))

(defun customize-tool-bar ()
  "Show tool bar customization.
Only available in Aquamacs."
  (interactive)
  (tool-bar-mode 1)  ; must be visible
  (sit-for 0)
  (ns-tool-bar-customize))


(defvar menu-bar-showhide-fringe-ind-menu
  (let ((menu (make-sparse-keymap "Buffer boundaries")))

    (bindings--define-key menu [customize]
      '(menu-item "Other (Customize)"
                  menu-bar-showhide-fringe-ind-customize
                  :help "Additional choices available through Custom buffer"
                  :visible (display-graphic-p)
                  :button (:radio . (not (member indicate-buffer-boundaries
                                                 '(nil left right
                                                   ((top . left) (bottom . right))
                                                   ((t . right) (top . left))))))))

    (bindings--define-key menu [mixed]
      '(menu-item "Opposite, Arrows Right" menu-bar-showhide-fringe-ind-mixed
                  :help
                  "Show top/bottom indicators in opposite fringes, arrows in right"
                  :visible (display-graphic-p)
                  :button (:radio . (equal indicate-buffer-boundaries
                                           '((t . right) (top . left))))))

    (bindings--define-key menu [box]
      '(menu-item "Opposite, No Arrows" menu-bar-showhide-fringe-ind-box
                  :help "Show top/bottom indicators in opposite fringes, no arrows"
                  :visible (display-graphic-p)
                  :button (:radio . (equal indicate-buffer-boundaries
                                           '((top . left) (bottom . right))))))

    (bindings--define-key menu [right]
      '(menu-item "In Right Fringe" menu-bar-showhide-fringe-ind-right
                  :help "Show buffer boundaries and arrows in right fringe"
                  :visible (display-graphic-p)
                  :button (:radio . (eq indicate-buffer-boundaries 'right))))

    (bindings--define-key menu [left]
      '(menu-item "In Left Fringe" menu-bar-showhide-fringe-ind-left
                  :help "Show buffer boundaries and arrows in left fringe"
                  :visible (display-graphic-p)
                  :button (:radio . (eq indicate-buffer-boundaries 'left))))

    (bindings--define-key menu [none]
      '(menu-item "No Indicators" menu-bar-showhide-fringe-ind-none
                  :help "Hide all buffer boundary indicators and arrows"
                  :visible (display-graphic-p)
                  :button (:radio . (eq indicate-buffer-boundaries nil))))
    menu))

(defun menu-bar-showhide-fringe-menu-customize ()
  "Show customization buffer for `fringe-mode'."
  (interactive)
  (customize-variable 'fringe-mode))

(defun menu-bar-showhide-fringe-menu-customize-reset ()
  "Reset the fringe mode: display fringes on both sides of a window."
  (interactive)
  (customize-set-variable 'fringe-mode nil))

(defun menu-bar-showhide-fringe-menu-customize-right ()
  "Display fringes only on the right of each window."
  (interactive)
  (require 'fringe)
  (customize-set-variable 'fringe-mode '(0 . nil)))

(defun menu-bar-showhide-fringe-menu-customize-left ()
  "Display fringes only on the left of each window."
  (interactive)
  (require 'fringe)
  (customize-set-variable 'fringe-mode '(nil . 0)))

(defun menu-bar-showhide-fringe-menu-customize-disable ()
  "Do not display window fringes."
  (interactive)
  (require 'fringe)
  (customize-set-variable 'fringe-mode 0))

(defvar menu-bar-showhide-fringe-menu
  (let ((menu (make-sparse-keymap "Fringe")))

    (bindings--define-key menu [showhide-fringe-ind]
      `(menu-item "Buffer Boundaries" ,menu-bar-showhide-fringe-ind-menu
                  :visible (display-graphic-p)
                  :help "Indicate buffer boundaries in fringe"))

    (bindings--define-key menu [indicate-empty-lines]
      (menu-bar-make-toggle toggle-indicate-empty-lines indicate-empty-lines
                            "Empty Line Indicators"
                            "Indicating of empty lines %s"
                            "Indicate trailing empty lines in fringe, globally"))

    (bindings--define-key menu [customize]
      '(menu-item "Customize Fringe" menu-bar-showhide-fringe-menu-customize
                  :help "Detailed customization of fringe"
                  :visible (display-graphic-p)))

    (bindings--define-key menu [default]
      '(menu-item "Default" menu-bar-showhide-fringe-menu-customize-reset
                  :help "Default width fringe on both left and right side"
                  :visible (display-graphic-p)
                  :button (:radio . (eq fringe-mode nil))))

    (bindings--define-key menu [right]
      '(menu-item "On the Right" menu-bar-showhide-fringe-menu-customize-right
                  :help "Fringe only on the right side"
                  :visible (display-graphic-p)
                  :button (:radio . (equal fringe-mode '(0 . nil)))))

    (bindings--define-key menu [left]
      '(menu-item "On the Left" menu-bar-showhide-fringe-menu-customize-left
                  :help "Fringe only on the left side"
                  :visible (display-graphic-p)
                  :button (:radio . (equal fringe-mode '(nil . 0)))))

    (bindings--define-key menu [none]
      '(menu-item "None" menu-bar-showhide-fringe-menu-customize-disable
                  :help "Turn off fringe"
                  :visible (display-graphic-p)
                  :button (:radio . (eq fringe-mode 0))))
    menu))

(defun menu-bar-right-scroll-bar ()
  "Display scroll bars on the right of each window."
  (interactive)
  (customize-set-variable 'scroll-bar-mode 'right))

(defun menu-bar-left-scroll-bar ()
  "Display scroll bars on the left of each window."
  (interactive)
  (customize-set-variable 'scroll-bar-mode 'left))

(defun menu-bar-no-scroll-bar ()
  "Turn off scroll bars."
  (interactive)
  (customize-set-variable 'scroll-bar-mode nil))

(defvar menu-bar-showhide-scroll-bar-menu
  (let ((menu (make-sparse-keymap "Scroll-bar")))

    (bindings--define-key menu [right]
      '(menu-item "On the Right"
                  menu-bar-right-scroll-bar
                  :help "Scroll-bar on the right side"
                  :visible (display-graphic-p)
                  :button (:radio . (eq (cdr (assq 'vertical-scroll-bars
                                                   (frame-parameters))) 'right))))

    (bindings--define-key menu [left]
      '(menu-item "On the Left"
                  menu-bar-left-scroll-bar
                  :help "Scroll-bar on the left side"
                  :visible (display-graphic-p)
                  :button (:radio . (eq (cdr (assq 'vertical-scroll-bars
                                                   (frame-parameters))) 'left))))

    (bindings--define-key menu [none]
      '(menu-item "None"
                  menu-bar-no-scroll-bar
                  :help "Turn off scroll-bar"
                  :visible (display-graphic-p)
                  :button (:radio . (eq (cdr (assq 'vertical-scroll-bars
                                                   (frame-parameters))) nil))))
    menu))

(defun menu-bar-frame-for-menubar ()
  "Return the frame suitable for updating the menu bar."
  (or (and (framep menu-updating-frame)
	   menu-updating-frame)
      (selected-frame)))

(defun menu-bar-positive-p (val)
  "Return non-nil if VAL is a positive number."
  (and (numberp val)
       (> val 0)))

(defun menu-bar-set-tool-bar-position (position)
  (customize-set-variable 'tool-bar-mode t)
  (customize-set-variable 'tool-bar-position position))
(defun menu-bar-showhide-tool-bar-menu-customize-disable ()
  "Do not display tool bars."
  (interactive)
  (customize-set-variable 'tool-bar-mode nil))
(defun menu-bar-showhide-tool-bar-menu-customize-enable-left ()
  "Display tool bars on the left side."
  (interactive)
  (menu-bar-set-tool-bar-position 'left))
(defun menu-bar-showhide-tool-bar-menu-customize-enable-right ()
  "Display tool bars on the right side."
  (interactive)
  (menu-bar-set-tool-bar-position 'right))
(defun menu-bar-showhide-tool-bar-menu-customize-enable-top ()
  "Display tool bars on the top side."
  (interactive)
  (menu-bar-set-tool-bar-position 'top))
(defun menu-bar-showhide-tool-bar-menu-customize-enable-bottom ()
  "Display tool bars on the bottom side."
  (interactive)
  (menu-bar-set-tool-bar-position 'bottom))

(when (featurep 'move-toolbar)
  (defvar menu-bar-showhide-tool-bar-menu
    (let ((menu (make-sparse-keymap "Tool-bar")))

      (bindings--define-key menu [showhide-tool-bar-left]
        '(menu-item "On the Left"
                    menu-bar-showhide-tool-bar-menu-customize-enable-left
                    :help "Tool-bar at the left side"
                    :visible (display-graphic-p)
                    :button
                    (:radio . (and tool-bar-mode
                                   (eq (frame-parameter
                                        (menu-bar-frame-for-menubar)
                                        'tool-bar-position)
                                       'left)))))

      (bindings--define-key menu [showhide-tool-bar-right]
        '(menu-item "On the Right"
                    menu-bar-showhide-tool-bar-menu-customize-enable-right
                    :help "Tool-bar at the right side"
                    :visible (display-graphic-p)
                    :button
                    (:radio . (and tool-bar-mode
                                   (eq (frame-parameter
                                        (menu-bar-frame-for-menubar)
                                        'tool-bar-position)
                                       'right)))))

      (bindings--define-key menu [showhide-tool-bar-bottom]
        '(menu-item "On the Bottom"
                    menu-bar-showhide-tool-bar-menu-customize-enable-bottom
                    :help "Tool-bar at the bottom"
                    :visible (display-graphic-p)
                    :button
                    (:radio . (and tool-bar-mode
                                   (eq (frame-parameter
                                        (menu-bar-frame-for-menubar)
                                        'tool-bar-position)
                                       'bottom)))))

      (bindings--define-key menu [showhide-tool-bar-top]
        '(menu-item "On the Top"
                    menu-bar-showhide-tool-bar-menu-customize-enable-top
                    :help "Tool-bar at the top"
                    :visible (display-graphic-p)
                    :button
                    (:radio . (and tool-bar-mode
                                   (eq (frame-parameter
                                        (menu-bar-frame-for-menubar)
                                        'tool-bar-position)
                                       'top)))))

      (bindings--define-key menu [showhide-tool-bar-none]
        '(menu-item "None"
                    menu-bar-showhide-tool-bar-menu-customize-disable
                    :help "Turn tool-bar off"
                    :visible (display-graphic-p)
                    :button (:radio . (eq tool-bar-mode nil))))
      menu)))

(defvar menu-bar-showhide-menu
  (let ((menu (make-sparse-keymap "Show/Hide")))


    (bindings--define-key menu [showhide-battery]
      (menu-bar-make-mm-toggle display-battery-mode
			       "Battery Status"
			       "Display battery status information in mode line"
			       (:visible (not (eq window-system 'ns)))))
    
    (bindings--define-key menu [showhide-date-time]
      (menu-bar-make-mm-toggle display-time-mode
			       "Time, Load and Mail"
			       "Display time, system load averages and \
mail status in mode line"
			       (:visible (not (eq window-system 'ns)))))

    (bindings--define-key menu [datetime-separator] `(menu-item "" nil
			  :visible (not (eq window-system ns))))

    (bindings--define-key menu [column-number-mode]
      (menu-bar-make-mm-toggle column-number-mode
                               "Column Numbers"
                               "Show the current column number in the mode line"))

    (bindings--define-key menu [line-number-mode]
      (menu-bar-make-mm-toggle line-number-mode
                               "Line Numbers"
                               "Show the current line number in the mode line"))

    (bindings--define-key menu [size-indication-mode]
      (menu-bar-make-mm-toggle size-indication-mode
                               "Size Indication"
                               "Show the size of the buffer in the mode line"))

    (bindings--define-key menu [size-separator] menu-bar-separator)


    ;; let's not show tooltips in Aquamacs
    ;; (bindings--define-key menu [showhide-tooltip-mode]
    ;;   '(menu-item "Tooltips" tooltip-mode
    ;; 		  :help "Turn tooltips on/off"
    ;; 		  :visible (and (display-graphic-p) (fboundp 'x-show-tip))
    ;; 		  :button (:toggle . tooltip-mode)))


    ;; (bindings--define-key menu [tooltip-separator] menu-bar-separator)
    (bindings--define-key menu [showhide-speedbar]
      '(menu-item "Speedbar" speedbar-frame-mode
                  :help "Display a Speedbar quick-navigation frame"
                  :button (:toggle
                           . (and (boundp 'speedbar-frame)
                                  (frame-live-p (symbol-value 'speedbar-frame))
                                  (frame-visible-p
                                   (symbol-value 'speedbar-frame))))))
    (bindings--define-key menu [speedbar-separator] menu-bar-separator)
    (bindings--define-key menu [showhide-fringe]
      `(menu-item "Fringe" ,menu-bar-showhide-fringe-menu
    	    :help "Settings for Fringe display in the margins of windows."
                  :visible (display-graphic-p)))

    ;; No scroll bar options shown in Aquamacs
    ;; (bindings--define-key menu [showhide-scroll-bar]
    ;;   `(menu-item "Scroll-bar" ,menu-bar-showhide-scroll-bar-menu
    ;; 		  :visible (display-graphic-p)))

    ;; No Toolbar customization button shown in Aquamacs
    ;; available via right-click on toolbar
    ;; (if (and (boundp 'menu-bar-showhide-tool-bar-menu)
    ;; 	     (keymapp menu-bar-showhide-tool-bar-menu))
    ;; 	(bindings--define-key menu [showhide-tool-bar]
    ;; 	  `(menu-item "Tool-bar" ,menu-bar-showhide-tool-bar-menu
    ;; 		      :visible (display-graphic-p)))
    ;;   ;; else not tool bar that can move.
    ;;   (bindings--define-key menu [showhide-tool-bar]
    ;; 	'(menu-item "Tool-bar" toggle-tool-bar-mode-from-frame
    ;; 		    :help "Turn tool-bar on/off"
    ;; 		    :visible (display-graphic-p)
    ;; 		    :button
    ;; 		    (:toggle . (menu-bar-positive-p
    ;; 				(frame-parameter (menu-bar-frame-for-menubar)
    ;; 						 'tool-bar-lines))))))

    ;; (bindings--define-key menu [ns-tool-bar]
    ;;   `(menu-item "Toolbar..."
    ;; 	      customize-tool-bar
    ;; 	      :help ,(purecopy "Display the Toolbar customization panel")
    ;; 	      :visible (and ,(fboundp 'ns-tool-bar-customize) (display-graphic-p))))

    (bindings--define-key menu [newlines-separator] menu-bar-separator)
    (bindings--define-key menu [hl-line-mode]
      (menu-bar-make-mm-toggle global-hl-line-mode
			       "Line Highlighting"
			       "Highlight current line (hl-line-mode)"))
    (bindings--define-key menu [show-newlines-mode]
      (menu-bar-make-mm-toggle global-show-newlines-mode
			       "Show Newlines"
			       "Show hard newlines"))
    (bindings--define-key menu [linum-mode]
      (menu-bar-make-mm-toggle global-linum-mode
			       "Line Numbering"
			       "Show the current line number next to each line"))
    (bindings--define-key menu [highlight-paren-mode]
      (menu-bar-make-mm-toggle show-paren-mode
			       "Paren Match Highlighting"
			       "Highlight matching/mismatched parentheses at cursor (Show Paren mode)"))

    menu))

(defvar menu-bar-line-wrapping-menu
  (let ((menu (make-sparse-keymap "Line Wrapping")))

    (bindings--define-key menu [auto-wrap]
      '(menu-item "Auto-Detect Line Wrap in Text Files"
		  toggle-text-mode-auto-detect-wrap
		  :help "Automatically use hard or soft word wrap (Auto Fill / Longlines) in text modes."
		  :button (:toggle . (if (listp text-mode-hook)
					 (or (member 'auto-detect-wrap text-mode-hook)
					     (member 'auto-detect-longlines text-mode-hook))
				       (or (eq 'auto-detect-wrap text-mode-hook)
					   (eq 'auto-detect-longlines text-mode-hook))))))

    (bindings--define-key menu [wrapping-set-default]
      `(menu-item (if (menu-bar-local-wrapping-p)
		      "Adopt as Default"
		    "Adopted as Default")
		  menu-bar-set-wrapping-default
		  :help "Set current wrapping style as default for other buffers."
		  :enable (and (menu-bar-menu-frame-live-and-visible-p)
			       (menu-bar-local-wrapping-p))
		  :button (:toggle . (not (menu-bar-local-wrapping-p)))))

    (bindings--define-key menu [default-separator]
      '("--"))

    (bindings--define-key menu [auto-fill-mode]
      `(menu-item (format "Break Lines (Auto Fill) at %s" fill-column)
		  set-auto-fill
		  :help "Automatically fill text between left and right margins (Auto Fill) in this buffer and in new buffers."
		  :enable (menu-bar-menu-frame-live-and-visible-p)
		  :button (:radio . auto-fill-function)))

    (bindings--define-key menu [word-wrap]
      `(menu-item "Word Wrap"
		  set-word-wrap
		  :help "Wrap long lines at word boundaries in this buffer and in new buffers."
		  :button (:radio . (and (null truncate-lines)
					 (not (truncated-partial-width-window-p))
					 word-wrap))
		  :enable (menu-bar-menu-frame-live-and-visible-p)))


    (bindings--define-key menu [window-wrap]
      `(menu-item "Wrap"
		  set-line-wrap
		  :help "Wrap long lines at window edge in this buffer and in new buffers."
		  :button (:radio . (and (null truncate-lines)
					 (not (truncated-partial-width-window-p))
					 (not word-wrap)
					 (null auto-fill-function)))
		  :visible (menu-bar-menu-frame-live-and-visible-p)
		  :enable (not (truncated-partial-width-window-p))))

    (bindings--define-key menu [truncate]
      `(menu-item "Truncate"
		  set-truncate-lines
		  :help "Truncate long lines at window edge in this buffer and in new buffers."
		  :button (:radio . (or (truncated-partial-width-window-p)
					truncate-lines)) ; truncate takes precedence over word-wrap
		  :visible (menu-bar-menu-frame-live-and-visible-p)
		  :enable (not (truncated-partial-width-window-p))))
    menu))

(defvar menu-bar-options-menu
  (let ((menu (make-sparse-keymap "Options")))
    (bindings--define-key menu [customize]
      `(menu-item ,(purecopy "Customize Aquamacs") ,menu-bar-custom-menu))

    (bindings--define-key menu [package]
      '(menu-item "Manage Emacs Packages" package-list-packages
        :help "Install or uninstall additional Emacs packages"))

    (bindings--define-key menu [custom-separator]
      menu-bar-separator)

    (bindings--define-key menu [save]
      `(menu-item ,(purecopy "Save Options") menu-bar-options-save
                  :help ,(purecopy "Save options set from the menu above")))

    (bindings--define-key menu [custom-separator]
      menu-bar-separator)

    (if (featurep 'system-font-setting)
        (bindings--define-key menu [menu-system-font]
          (menu-bar-make-toggle
           toggle-use-system-font font-use-system-font
           "Use System Font"
           "Use system font: %s"
           "Use the monospaced font defined by the system")))

    (bindings--define-key menu [showhide]
      `(menu-item "Show/Hide" ,menu-bar-showhide-menu))

    (bindings--define-key menu [showhide-separator]
      menu-bar-separator)

    (bindings--define-key menu [mule]
      ;; It is better not to use backquote here,
      ;; because that makes a bootstrapping problem
      ;; if you need to recompile all the Lisp files using interpreted code.
  `(menu-item ,(purecopy "Language") ,mule-menu-keymap
;; Most of the MULE menu actually does make sense in unibyte mode,
;; e.g. language selection.
;;;	:visible '(default-value 'enable-multibyte-characters)
                  ))
    ;;(setq menu-bar-final-items (cons 'mule menu-bar-final-items))
    ;;(bindings--define-key menu [preferences]
    ;;  `(menu-item "Preferences" ,menu-bar-preferences-menu
    ;;	      :help "Toggle important global options"))

    (bindings--define-key menu [mule-separator]
      menu-bar-separator)

    (bindings--define-key menu [debug-on-quit]
      (menu-bar-make-toggle toggle-debug-on-quit debug-on-quit
                            "Enter Debugger on Quit/C-g" "Debug on Quit %s"
                            "Enter Lisp debugger when C-g is pressed"))
    (bindings--define-key menu [debug-on-error]
      (menu-bar-make-toggle toggle-debug-on-error debug-on-error
                            "Enter Debugger on Error" "Debug on Error %s"
                            "Enter Lisp debugger when an error is signaled"))
    (bindings--define-key menu [debugger-separator]
      menu-bar-separator)

    (bindings--define-key menu [edit-options-separator]
      '("--"))
    menu))

(bindings--define-key menu-bar-search-menu [case-fold-search]
      (menu-bar-make-toggle toggle-case-fold-search case-fold-search
                            "Case-Insensitive Search"
       "Case-Insensitive Search %s"
       "Ignore letter-case in search commands"))


(defun set-global-mode-here-and-default (global-mode &optional enable)
  "Sets global minor mode GLOBAL-MODE in this buffer, and as default
for future buffers."
  (let ((sgmh-this-buffer (current-buffer))
	(saved (symbol-function 'buffer-list)))
    (unwind-protect
	(progn
	  (fset 'buffer-list (lambda (&optional frame) (list sgmh-this-buffer)))
	  (funcall global-mode enable))
      (fset 'buffer-list saved))))

;; (defvar line-wrapping--saved-state nil)

;; (defvar line-wrapping--state nil "Line wrapping mode in effect.
;; One of `truncate', `wrap', `word-wrap' and `fill'.")
;; (make-variable-buffer-local 'line-wrapping--state)

; could add something to minor-mode-alist as a lighter for the
; mode-line
(setq minor-mode-alist (cons (list 'truncate-lines " Trunc")
			   minor-mode-alist))

(defun menu-bar-set-wrapping-default ()
  "Set current buffer's line wrapping style as default."
  (interactive)

  (let ((variables '(word-wrap truncate-lines line-move-visual
			       visual-line-mode auto-fill-function
			       fringe-indicator-alist)))

    (let ((vlf (member (cons 'continuation visual-line-fringe-indicators)
		       fringe-indicator-alist)))

      (unless (eq (if vlf t nil)
		  (if (member (cons 'continuation visual-line-fringe-indicators)
			      (default-value 'fringe-indicator-alist)) t nil))
	(if vlf
	    (set-default 'fringe-indicator-alist
			 (cons (cons 'continuation visual-line-fringe-indicators)
			       (default-value 'fringe-indicator-alist)))
	  (set-default 'fringe-indicator-alist
		       (remove (cons 'continuation visual-line-fringe-indicators)
			       (default-value 'fringe-indicator-alist))))))

    ;; create local bindings in all buffers
    ;; in order to just set the default for future buffers
    ;; WE DON'T NEED THIS IF USERS CALL THIS FUNCTION EXPLICITLY
    ;; (dolist (buf (buffer-list))
    ;;   (when (buffer-live-p buf)
    ;; 	(with-current-buffer buf
    ;; 	  (unless (eq major-mode 'fundamental-mode)
    ;; 	    (dolist (v variables)
    ;; 	      ;; create local binding
    ;; 	      (set v (symbol-value v)))))))
    
    ;; set default values and remove local bindings in current buffer
    (dolist (v variables)
      (set-default v (symbol-value v))
      (kill-local-variable v))

    (customize-mark-as-set 'word-wrap)
    (customize-mark-as-set 'truncate-lines)
    (customize-mark-as-set 'fringe-indicator-alist)
    (customize-mark-as-set 'auto-fill-function)

    (message "Line wrapping set as default for other buffers.")))


;; We just offer the auto-wrap option in Aquamacs
;; (bindings--define-key menu-bar-line-wrapping-menu [auto-fill-text-mode]
;;   `(menu-item ,(purecopy "Hard Word Wrap as Default in Text Modes")
;;               menu-bar-text-mode-auto-fill
;; 	      :help ,(purecopy "Automatically fill text while typing (Auto Fill mode)")
;;               :button (:toggle . (if (listp text-mode-hook)
;; 				     (member 'turn-on-auto-fill text-mode-hook)
;; 				   (eq 'turn-on-auto-fill text-mode-hook)))))
(defun menu-bar-local-wrapping-p ()
  (or (local-variable-p 'word-wrap)
      (local-variable-p 'truncate-lines)
      (local-variable-p 'auto-fill-function)))



(bindings--define-key menu-bar-options-menu [line-wrapping]
  `(menu-item "Line Wrapping" ,menu-bar-line-wrapping-menu))

;; The "Tools" menu items

(defvar menu-bar-games-menu
  (let ((menu (make-sparse-keymap "Games")))

    (bindings--define-key menu [zone]
      '(menu-item "Zone Out" zone
                  :help "Play tricks with Emacs display when Emacs is idle"))
    (bindings--define-key menu [tetris]
      '(menu-item "Tetris" tetris
                  :help "Falling blocks game"))
    (bindings--define-key menu [solitaire]
      '(menu-item "Solitaire" solitaire
                  :help "Get rid of all the stones"))
    (bindings--define-key menu [snake]
      '(menu-item "Snake" snake
                  :help "Move snake around avoiding collisions"))
    (bindings--define-key menu [pong]
      '(menu-item "Pong" pong
                  :help "Bounce the ball to your opponent"))
    (bindings--define-key menu [mult]
      '(menu-item "Multiplication Puzzle"  mpuz
                  :help "Exercise brain with multiplication"))
    (bindings--define-key menu [life]
      '(menu-item "Life"  life
                  :help "Watch how John Conway's cellular automaton evolves"))
    (bindings--define-key menu [land]
      '(menu-item "Landmark" landmark
                  :help "Watch a neural-network robot learn landmarks"))
    (bindings--define-key menu [hanoi]
      '(menu-item "Towers of Hanoi" hanoi
                  :help "Watch Towers-of-Hanoi puzzle solved by Emacs"))
    (bindings--define-key menu [gomoku]
      '(menu-item "Gomoku"  gomoku
                  :help "Mark 5 contiguous squares (like tic-tac-toe)"))
    (bindings--define-key menu [bubbles]
      '(menu-item "Bubbles" bubbles
                  :help "Remove all bubbles using the fewest moves"))
    (bindings--define-key menu [black-box]
      '(menu-item "Blackbox"  blackbox
                  :help "Find balls in a black box by shooting rays"))
    (bindings--define-key menu [adventure]
      '(menu-item "Adventure"  dunnet
                  :help "Dunnet, a text Adventure game for Emacs"))
    (bindings--define-key menu [5x5]
      '(menu-item "5x5" 5x5
                  :help "Fill in all the squares on a 5x5 board"))
    menu))

(defvar menu-bar-encryption-decryption-menu
  (let ((menu (make-sparse-keymap "Encryption/Decryption")))
    (bindings--define-key menu [insert-keys]
      '(menu-item "Insert Keys" epa-insert-keys
                  :help "Insert public keys after the current point"))

    (bindings--define-key menu [export-keys]
      '(menu-item "Export Keys" epa-export-keys
                  :help "Export public keys to a file"))

    (bindings--define-key menu [import-keys-region]
      '(menu-item "Import Keys from Region" epa-import-keys-region
                  :help "Import public keys from the current region"))

    (bindings--define-key menu [import-keys]
      '(menu-item "Import Keys from File..." epa-import-keys
                  :help "Import public keys from a file"))

    (bindings--define-key menu [list-keys]
      '(menu-item "List Keys" epa-list-keys
                  :help "Browse your public keyring"))

    (bindings--define-key menu [separator-keys]
      menu-bar-separator)

    (bindings--define-key menu [sign-region]
      '(menu-item "Sign Region" epa-sign-region
                  :help "Create digital signature of the current region"))

    (bindings--define-key menu [verify-region]
      '(menu-item "Verify Region" epa-verify-region
                  :help "Verify digital signature of the current region"))

    (bindings--define-key menu [encrypt-region]
      '(menu-item "Encrypt Region" epa-encrypt-region
                  :help "Encrypt the current region"))

    (bindings--define-key menu [decrypt-region]
      '(menu-item "Decrypt Region" epa-decrypt-region
                  :help "Decrypt the current region"))

    (bindings--define-key menu [separator-file]
      menu-bar-separator)

    (bindings--define-key menu [sign-file]
      '(menu-item "Sign File..." epa-sign-file
                  :help "Create digital signature of a file"))

    (bindings--define-key menu [verify-file]
      '(menu-item "Verify File..." epa-verify-file
                  :help "Verify digital signature of a file"))

    (bindings--define-key menu [encrypt-file]
      '(menu-item "Encrypt File..." epa-encrypt-file
                  :help "Encrypt a file"))

    (bindings--define-key menu [decrypt-file]
      '(menu-item "Decrypt File..." epa-decrypt-file
                  :help "Decrypt a file"))

    menu))

(defun menu-bar-read-mail ()
  "Read mail using `read-mail-command'."
  (interactive)
  (call-interactively read-mail-command))

(defvar menu-bar-tools-menu
  (let ((menu (make-sparse-keymap "Tools")))

    (bindings--define-key menu [games]
      `(menu-item "Games" ,menu-bar-games-menu))

    (bindings--define-key menu [separator-games]
      menu-bar-separator)

    (bindings--define-key menu [encryption-decryption]
      `(menu-item "Encryption/Decryption"
                  ,menu-bar-encryption-decryption-menu))

    (bindings--define-key menu [separator-encryption-decryption]
      menu-bar-separator)

    (bindings--define-key menu [simple-calculator]
      '(menu-item "Simple Calculator" calculator
                  :help "Invoke the Emacs built-in quick calculator"))
    (bindings--define-key menu [calc]
      '(menu-item "Programmable Calculator" calc
                  :help "Invoke the Emacs built-in full scientific calculator"))
    (bindings--define-key menu [calendar]
      '(menu-item "Calendar" calendar
                  :help "Invoke the Emacs built-in calendar"))

    (bindings--define-key menu [separator-net]
      menu-bar-separator)

    (bindings--define-key menu [browse-web]
      '(menu-item "Browse the Web..." browse-web))
    (bindings--define-key menu [directory-search]
      '(menu-item "Directory Search" eudc-tools-menu))
    (bindings--define-key menu [compose-mail]
      '(menu-item "Compose New Mail" compose-mail
                  :visible (and mail-user-agent (not (eq mail-user-agent 'ignore)))
                  :help "Start writing a new mail message"))
    (bindings--define-key menu [rmail]
      '(menu-item "Read Mail" menu-bar-read-mail
                  :visible (and read-mail-command
                                (not (eq read-mail-command 'ignore)))
                  :help "Read your mail"))

    (bindings--define-key menu [gnus]
      '(menu-item "Read Net News" gnus
                  :help "Read network news groups"))

    (bindings--define-key menu [separator-vc]
      menu-bar-separator)

    (bindings--define-key menu [pcl-cvs]
      `(menu-item ,(purecopy "CVS Repositories") cvs-global-menu))
    (bindings--define-key menu [vc] nil) ;Create the place for the VC menu.
    (bindings--define-key menu [separator-compare]
      menu-bar-separator)

    (bindings--define-key menu [epatch]
      '(menu-item "Apply Patch" menu-bar-epatch-menu))
    (bindings--define-key menu [ediff-merge]
      '(menu-item "Merge" menu-bar-ediff-merge-menu))
    (bindings--define-key menu [compare]
      '(menu-item "Compare (Ediff)" menu-bar-ediff-menu))

    (bindings--define-key menu [separator-spell]
      menu-bar-separator)

    (bindings--define-key menu [spell]
      '(menu-item "Spell Checking" ispell-menu-map))

    (bindings--define-key menu [separator-prog]
      menu-bar-separator)

    (bindings--define-key menu [semantic]
      '(menu-item "Source Code Parsers (Semantic)"
                  semantic-mode
                  :help "Toggle automatic parsing in source code buffers (Semantic mode)"
                  :button (:toggle . (bound-and-true-p semantic-mode))))

    (bindings--define-key menu [ede]
      '(menu-item "Project Support (EDE)"
                  global-ede-mode
                  :help "Toggle the Emacs Development Environment (Global EDE mode)"
                  :button (:toggle . (bound-and-true-p global-ede-mode))))

    (bindings--define-key menu [gdb]
      '(menu-item "Debugger (GDB)..." gdb
                  :help "Debug a program from within Emacs with GDB"))
    (bindings--define-key menu [shell-on-region]
      '(menu-item "Shell Command on Region..." shell-command-on-region
                  :enable mark-active
                  :help "Pass marked region to a shell command"))
    (bindings--define-key menu [shell]
      '(menu-item "Shell Command..." shell-command
                  :help "Invoke a shell command and catch its output"))
    (bindings--define-key menu [compile]
      '(menu-item "Compile..." compile
                  :help "Invoke compiler or Make, view compilation errors"))
    (bindings--define-key menu [grep]
      '(menu-item "Search Files (Grep)..." grep
                  :help "Search files for strings or regexps (with Grep)"))
    menu))

;; The "Help" menu items

(defvar menu-bar-describe-menu
  (let ((menu (make-sparse-keymap "Describe")))

    (bindings--define-key menu [mule-diag]
      '(menu-item "Show All of Mule Status" mule-diag
                  :visible (default-value 'enable-multibyte-characters)
                  :help "Display multilingual environment settings"))
    (bindings--define-key menu [describe-coding-system-briefly]
      '(menu-item "Describe Coding System (Briefly)"
                  describe-current-coding-system-briefly
                  :visible (default-value 'enable-multibyte-characters)))
    (bindings--define-key menu [describe-coding-system]
      '(menu-item "Describe Coding System..." describe-coding-system
                  :visible (default-value 'enable-multibyte-characters)))
    (bindings--define-key menu [describe-input-method]
      '(menu-item "Describe Input Method..." describe-input-method
                  :visible (default-value 'enable-multibyte-characters)
                  :help "Keyboard layout for specific input method"))
    (bindings--define-key menu [describe-language-environment]
      `(menu-item "Describe Language Environment"
                  ,describe-language-environment-map))

    (bindings--define-key menu [separator-desc-mule]
      menu-bar-separator)

    (bindings--define-key menu [list-keybindings]
      '(menu-item "List Key Bindings" describe-bindings
                  :help "Display all current key bindings (keyboard shortcuts)"))
    (bindings--define-key menu [describe-current-display-table]
      '(menu-item "Describe Display Table" describe-current-display-table
                  :help "Describe the current display table"))
    (bindings--define-key menu [describe-package]
      '(menu-item "Describe Package..." describe-package
                  :help "Display documentation of a Lisp package"))
    (bindings--define-key menu [describe-face]
      '(menu-item "Describe Face..." describe-face
                  :help "Display the properties of a face"))
    (bindings--define-key menu [describe-variable]
      '(menu-item "Describe Variable..." describe-variable
                  :help "Display documentation of variable/option"))
    (bindings--define-key menu [describe-function]
      '(menu-item "Describe Function..." describe-function
                  :help "Display documentation of function/command"))
    (bindings--define-key menu [describe-key-1]
      '(menu-item "Describe Key or Mouse Operation..." describe-key
                  ;; Users typically don't identify keys and menu items...
                  :help "Display documentation of command bound to a \
key, a click, or a menu-item"))
    (bindings--define-key menu [describe-mode]
      '(menu-item "Describe Buffer Modes" describe-mode
                  :help "Describe this buffer's major and minor mode"))
    menu))

(defun menu-bar-read-lispref ()
  "Display the Emacs Lisp Reference manual in Info mode."
  (interactive)
  (info "elisp"))

(defun menu-bar-read-lispintro ()
  "Display the Introduction to Emacs Lisp Programming in Info mode."
  (interactive)
  (info "eintr"))

(defun search-emacs-glossary ()
  "Display the Glossary node of the Emacs manual in Info mode."
  (interactive)
  (info "(emacs)Glossary"))

(defun emacs-index-search (topic)
  "Look up TOPIC in the indices of the Emacs User Manual."
  (interactive "sSubject to look up: ")
  (info "emacs")
  (Info-index topic))

(defun elisp-index-search (topic)
  "Look up TOPIC in the indices of the Emacs Lisp Reference Manual."
  (interactive "sSubject to look up: ")
  (info "elisp")
  (Info-index topic))

(defvar menu-bar-search-documentation-menu
  (let ((menu (make-sparse-keymap "Search Documentation")))

    (bindings--define-key menu [search-documentation-strings]
      '(menu-item "Search Documentation Strings..." apropos-documentation
                  :help
                  "Find functions and variables whose doc strings match a regexp"))
    (bindings--define-key menu [find-any-object-by-name]
      '(menu-item "Find Any Object by Name..." apropos
                  :help "Find symbols of any kind whose names match a regexp"))
    (bindings--define-key menu [find-option-by-value]
      '(menu-item "Find Options by Value..." apropos-value
                  :help "Find variables whose values match a regexp"))
    (bindings--define-key menu [find-options-by-name]
      '(menu-item "Find Options by Name..." apropos-user-option
                  :help "Find user options whose names match a regexp"))
    (bindings--define-key menu [find-commands-by-name]
      '(menu-item "Find Commands by Name..." apropos-command
                  :help "Find commands whose names match a regexp"))
    (bindings--define-key menu [sep1]
      menu-bar-separator)
    (bindings--define-key menu [lookup-command-in-manual]
      '(menu-item "Look Up Command in User Manual..." Info-goto-emacs-command-node
                  :help "Display manual section that describes a command"))
    (bindings--define-key menu [lookup-key-in-manual]
      '(menu-item "Look Up Key in User Manual..." Info-goto-emacs-key-command-node
                  :help "Display manual section that describes a key"))
    (bindings--define-key menu [lookup-subject-in-elisp-manual]
      '(menu-item "Look Up Subject in ELisp Manual..." elisp-index-search
                  :help "Find description of a subject in Emacs Lisp manual"))
    (bindings--define-key menu [lookup-subject-in-emacs-manual]
      '(menu-item "Look Up Subject in User Manual..." emacs-index-search
                  :help "Find description of a subject in Emacs User manual"))
    (bindings--define-key menu [emacs-terminology]
      '(menu-item "Emacs Terminology" search-emacs-glossary
                  :help "Display the Glossary section of the Emacs manual"))
    menu))

(defvar menu-bar-manuals-menu
  (let ((menu (make-sparse-keymap "More Manuals")))

    (bindings--define-key menu [man]
      '(menu-item "Read Man Page..." manual-entry
                  :help "Man-page docs for external commands and libraries"))
    (bindings--define-key menu [sep2]
      menu-bar-separator)
    (bindings--define-key menu [order-emacs-manuals]
      `(menu-item ,(purecopy "Ordering Manuals") view-order-manuals
                  :help ,(purecopy "How to order manuals from the Free Software Foundation")))
    (bindings--define-key menu [lookup-subject-in-all-manuals]
      `(menu-item ,(purecopy "Lookup Subject in all Manuals...") info-apropos
                  :help ,(purecopy "Find description of a subject in all installed manuals")))
    (bindings--define-key menu [other-manuals]
      `(menu-item ,(purecopy "All Other Manuals (Info)") Info-directory
                  :help ,(purecopy "Read any of the installed manuals")))
    (bindings--define-key menu [emacs-lisp-reference]
      `(menu-item ,(purecopy "Emacs Lisp Reference") menu-bar-read-lispref
                  :help ,(purecopy "Read the Emacs Lisp Reference manual")))
    (bindings--define-key menu [emacs-lisp-intro]
      `(menu-item ,(purecopy "Introduction to Emacs Lisp") menu-bar-read-lispintro
                  :help ,(purecopy "Read the Introduction to Emacs Lisp Programming")))
    (bindings--define-key menu [emacs-psychotherapist]
      `(menu-item ,(purecopy "Emacs Psychotherapist") doctor
		  :help ,(purecopy "Our doctor will help you feel better")))
    menu))

(defun help-with-tutorial-spec-language ()
  "Use the Emacs tutorial, specifying which language you want."
  (interactive)
  (help-with-tutorial t))

(defvar menu-bar-help-menu
  (let ((menu (make-sparse-keymap "Help")))
    (bindings--define-key menu [about-gnu-project]
      '(menu-item "About GNU" describe-gnu-project
                  :help "About the GNU System, GNU Project, and GNU/Linux"))
    (bindings--define-key menu [about-emacs]
      '(menu-item "About Emacs" about-emacs
                  :help "Display version number, copyright info, and basic help"))
    (bindings--define-key menu [sep4]
      menu-bar-separator)
    (bindings--define-key menu [describe-no-warranty]
      '(menu-item "(Non)Warranty" describe-no-warranty
                  :help "Explain that Emacs has NO WARRANTY"))
    (bindings--define-key menu [describe-copying]
      '(menu-item "Copying Conditions" describe-copying
                  :help "Show the Emacs license (GPL)"))
    (bindings--define-key menu [getting-new-versions]
      '(menu-item "Getting New Versions" describe-distribution
                  :help "How to get the latest version of Emacs"))
    (bindings--define-key menu [sep2]
      menu-bar-separator)
    (bindings--define-key menu [external-packages]
      '(menu-item "Finding Extra Packages" view-external-packages
                  :help "How to get more Lisp packages for use in Emacs"))
    (bindings--define-key menu [find-emacs-packages]
      `(menu-item ,(purecopy "Search Built-in Packages") finder-by-keyword
                  :help ,(purecopy "Find built-in packages and features by keyword")))
    (bindings--define-key menu [more-manuals]
      `(menu-item ,(purecopy "More Manuals") ,menu-bar-manuals-menu))
    (bindings--define-key menu [emacs-manual]
      `(menu-item ,(purecopy "Read the Emacs Manual") info-emacs-manual
                  :help ,(purecopy "Full documentation of Emacs features")))
    (bindings--define-key menu [describe]
      `(menu-item ,(purecopy "Describe") ,menu-bar-describe-menu))
    (bindings--define-key menu [search-documentation]
      `(menu-item ,(purecopy "Search Documentation") ,menu-bar-search-documentation-menu))
    (bindings--define-key menu [sep1]
      '("--"))
    (bindings--define-key menu [send-emacs-bug-report]
      `(menu-item ,(purecopy "Send Bug Report...") report-emacs-bug
                  :help ,(purecopy "Send e-mail to Emacs maintainers")))
    (bindings--define-key menu [emacs-news]
      `(menu-item ,(purecopy "Emacs News") view-emacs-news
                  :help ,(purecopy "New features of this version")))
    (bindings--define-key menu [emacs-tutorial-language-specific]
      `(menu-item ,(purecopy "Emacs Tutorial (choose language)...")
                  help-with-tutorial-spec-language
                  :help "Learn how to use Emacs (choose a language)"))
    (bindings--define-key menu [emacs-tutorial]
      '(menu-item "Emacs Tutorial" help-with-tutorial
                  :help "Learn how to use Emacs"))

    ;; In OS X it's in the app menu already.
    ;; FIXME? There already is an "About Emacs" (sans ...) entry in the Help menu.
    (and (featurep 'ns)
         (not (eq system-type 'darwin))
         (bindings--define-key menu [info-panel]
           '(menu-item "About Emacs..." ns-do-emacs-info-panel)))
    menu))

(bindings--define-key global-map [menu-bar tools]
  (cons (purecopy "Tools") menu-bar-tools-menu))
(bindings--define-key global-map [menu-bar buffer]
  (cons (purecopy "Window") global-buffers-menu-map))
(bindings--define-key global-map [menu-bar options]
  (cons (purecopy "Options") menu-bar-options-menu))
(bindings--define-key global-map [menu-bar edit]
  (cons (purecopy "Edit") menu-bar-edit-menu))
(bindings--define-key global-map [menu-bar file]
  (cons (purecopy "File") menu-bar-file-menu))
(bindings--define-key global-map [menu-bar help-menu]
  (cons (purecopy "Help") menu-bar-help-menu))

(defun menu-bar-menu-frame-live-and-visible-p ()
  "Return non-nil if the menu frame is alive and visible.
The menu frame is the frame for which we are updating the menu."
  (let ((menu-frame (or menu-updating-frame (selected-frame))))
    (and (frame-live-p menu-frame)
	 (frame-visible-p menu-frame))))

(defun menu-bar-non-minibuffer-window-p ()
  "Return non-nil if selected window of the menu frame is not a minibuf window.

See the documentation of `menu-bar-menu-frame-live-and-visible-p'
for the definition of the menu frame."
  (let ((menu-frame (or menu-updating-frame (selected-frame))))
    (not (window-minibuffer-p (frame-selected-window menu-frame)))))

(defun kill-this-buffer ()	; for the menu bar
  "Kill the current buffer.
When called in the minibuffer, get out of the minibuffer
using `abort-recursive-edit'."
  (interactive)
  (cond
   ;; Don't do anything when `menu-frame' is not alive or visible
   ;; (Bug#8184).
   ((not (menu-bar-menu-frame-live-and-visible-p)))
   ((menu-bar-non-minibuffer-window-p)
    (kill-buffer (current-buffer)))
   (t
    (abort-recursive-edit))))

(defun kill-this-buffer-enabled-p ()
  "Return non-nil if the `kill-this-buffer' menu item should be enabled."
  (and (menu-bar-menu-frame-live-and-visible-p)
  (or (not (menu-bar-non-minibuffer-window-p))
      (let (found-1)
	;; Instead of looping over entire buffer list, stop once we've
	;; found two "killable" buffers (Bug#8184).
	(catch 'found-2
	  (dolist (buffer (buffer-list))
	    (unless (string-match-p "^ " (buffer-name buffer))
	      (if (not found-1)
		  (setq found-1 t)
		(throw 'found-2 t))))))))
  )

(put 'dired 'menu-enable '(menu-bar-non-minibuffer-window-p))

;; Permit deleting frame if it would leave a visible or iconified frame.
(defun delete-frame-enabled-p ()
  "Return non-nil if `delete-frame' should be enabled in the menu bar."
  (let ((frames (frame-list))
	(count 0))
    (while frames
      (if (frame-visible-p (car frames))
	  (setq count (1+ count)))
      (setq frames (cdr frames)))
    (> count 1)))

(defcustom yank-menu-length 20
  "Maximum length to display in the yank-menu."
  :type 'integer
  :group 'menu)

(defun menu-bar-update-yank-menu (string old)
  (let ((front (car (cdr yank-menu)))
	(menu-string (if (<= (length string) yank-menu-length)
			 string
		       (concat
			(substring string 0 (/ yank-menu-length 2))
			"..."
			(substring string (- (/ yank-menu-length 2)))))))
    ;; Don't let the menu string start with two dashes, or be empty
    ;; string or single dash; those have special meaning (separators) in a menu.
    (if (or (string-match "\\`--" menu-string)
	    (string-match "\\`-?\\'" menu-string))
	;; append a soft hyphen, which isn't displayed, at beginning
	(setq menu-string (concat "\u00ad" menu-string)))
    ;; If we're supposed to be extending an existing string, and that
    ;; string really is at the front of the menu, then update it in place.
    (if (and old (or (eq old (car front))
		     (string= old (car front))))
	(progn
	  (setcar front string)
	  (setcar (cdr front) menu-string))
      (setcdr yank-menu
	      (cons
	       (cons string (cons menu-string 'menu-bar-select-yank))
	       (cdr yank-menu)))))
  (if (> (length (cdr yank-menu)) kill-ring-max)
      (setcdr (nthcdr kill-ring-max yank-menu) nil)))

(put 'menu-bar-select-yank 'apropos-inhibit t)
(defun menu-bar-select-yank ()
  "Insert the stretch of previously-killed text selected from menu.
The menu shows all the killed text sequences stored in `kill-ring'."
  (interactive "*")
  (push-mark (point))
  (insert last-command-event))


;;; Buffers Menu

(defcustom buffers-menu-max-size 10
  "Maximum number of entries which may appear on the Buffers menu.
If this is 10, then only the ten most-recently-selected buffers are shown.
If this is nil, then all buffers are shown.
A large number or nil slows down menu responsiveness."
  :type '(choice integer
		 (const :tag "All" nil))
  :group 'menu)

(defcustom buffers-menu-buffer-name-length 30
  "Maximum length of the buffer name on the Buffers menu.
If this is a number, then buffer names are truncated to this length.
If this is nil, then buffer names are shown in full.
A large number or nil makes the menu too wide."
  :type '(choice integer
		 (const :tag "Full length" nil))
  :group 'menu)

(defcustom buffers-menu-show-directories 'unless-uniquify
  "If non-nil, show directories in the Buffers menu for buffers that have them.
The special value `unless-uniquify' means that directories will be shown
unless `uniquify-buffer-name-style' is non-nil (in which case, buffer
names should include enough of a buffer's directory to distinguish it
from other buffers).

Setting this variable directly does not take effect until next time the
Buffers menu is regenerated."
  :set (lambda (symbol value)
	 (set symbol value)
	 (menu-bar-update-buffers t))
  :initialize 'custom-initialize-default
  :type '(choice (const :tag "Never" nil)
		 (const :tag "Unless uniquify is enabled" unless-uniquify)
		 (const :tag "Always" t))
  :group 'menu)

(defcustom buffers-menu-show-status t
  "If non-nil, show modified/read-only status of buffers in the Buffers menu.
Setting this variable directly does not take effect until next time the
Buffers menu is regenerated."
  :set (lambda (symbol value)
	 (set symbol value)
	 (menu-bar-update-buffers t))
  :initialize 'custom-initialize-default
  :type 'boolean
  :group 'menu)

(defvar list-buffers-directory nil
  "String to display in buffer listings for buffers not visiting a file.")
(make-variable-buffer-local 'list-buffers-directory)

(defun menu-bar-select-buffer (&optional buffer)
  (interactive)
  (switch-to-buffer (or buffer last-command-event)))

(defun menu-bar-select-frame (frame)
  (make-frame-visible frame)
  (raise-frame frame)
  (select-frame frame))


;; FIXME: move these in common place 
;; (shared with mouse.el)
(defvar buffer-menu-modified-string "*")
(defvar buffer-menu-read-only-string "%")

(defun menu-bar-update-buffers-1 (elt)
  (let* ((buf (car elt))
	 (file
	  (and (if (eq buffers-menu-show-directories 'unless-uniquify)
		   (or (not (boundp 'uniquify-buffer-name-style))
		       (null uniquify-buffer-name-style))
		 buffers-menu-show-directories)
	       (or (buffer-file-name buf)
		   (buffer-local-value 'list-buffers-directory buf)))))
    (when file
      (setq file (file-name-directory file)))
    (when (and file (> (length file) 20))
      (setq file (concat "..." (substring file -17))))
    (cons (if buffers-menu-show-status
	      (let ((mod (if (buffer-modified-p buf) buffer-menu-modified-string ""))  ; on NS this indicates modification. To Do: show on the left
		    ;; (icon (if (buffer-modified-p buf) "\u2666 " ""))
		    (ro (if (buffer-local-value 'buffer-read-only buf) buffer-menu-read-only-string ""))
		    )
		(if file
		    (format "%s  %s%s    \t%s" (cdr elt) mod ro file)
		  (format "%s  %s%s" (cdr elt) mod ro)))
	    (if file
		(format "%s    \t%s"  (cdr elt) file)
	      (cdr elt)))
	  buf)))

;; Used to cache the menu entries for commands in the Buffers menu
(defvar menu-bar-buffers-menu-command-entries nil)

(defvar menu-bar-select-buffer-function 'switch-to-buffer
  "Function to select the buffer chosen from the `Buffers' menu-bar menu.
It must accept a buffer as its only required argument.")

(defun menu-bar-update-buffers (&optional force)
  ;; If user discards the Buffers item, play along.
  (and (lookup-key (current-global-map) [menu-bar buffer])
       (or force (frame-or-buffer-changed-p))
       ;; buffers list in menu should be stable (rather than reflecting Emacs buffer ordering)
       (let ((buffers (sort (buffer-list) (lambda (a b) (string< (buffer-name a) (buffer-name b)))))
	     (frames (frame-list))
	     buffers-menu)
	 ;; If requested, list only the N most recently selected buffers.
	 (if (and (integerp buffers-menu-max-size)
		  (> buffers-menu-max-size 1))
	     (if (> (length buffers) buffers-menu-max-size)
		 (setcdr (nthcdr buffers-menu-max-size buffers) nil)))

	 ;; Make the menu of buffers proper.
	 (setq buffers-menu
	       (let (alist)
		 ;; Put into each element of buffer-list
		 ;; the name for actual display,
		 ;; perhaps truncated in the middle.
		 (dolist (buf buffers)
		   (let ((name (buffer-name buf)))
                     (unless (eq ?\s (aref name 0))
                       (push (menu-bar-update-buffers-1
                              (cons buf
				    (if (and (integerp buffers-menu-buffer-name-length)
					     (> (length name) buffers-menu-buffer-name-length))
					(concat
					 (substring
					  name 0 (/ buffers-menu-buffer-name-length 2))
					 "..."
					 (substring
					  name (- (/ buffers-menu-buffer-name-length 2))))
				      name)
                                    ))
                             alist))))
		 ;; Now make the actual list of items.
                 (let ((buffers-vec (make-vector (length alist) nil))
                       (i (length alist)))
                   (dolist (pair alist)
                     (setq i (1- i))
                     (aset buffers-vec i
			   (cons 'menu-item
				 (nconc (list
					 (car pair)
				  `(lambda ()
                                     (interactive)
                                     (funcall menu-bar-select-buffer-function ,(cdr pair))))))
			   ))
                   (list buffers-vec))))

	 ;; Make a Frames menu if we have more than one frame.
	   (let* ((frames-vec (make-vector (length frames) nil))
                  (frames-menu
                   (cons 'keymap
                         (list "Select Frame" frames-vec)))
                  (i 0))
             (dolist (frame frames)
	     (let ((name (frame-parameter frame 'name)))
	       (when (or (frame-visible-p frame)
			 (not (and (> (length name) 0)
				   (string= (substring name 0 1) " "))))
               (aset frames-vec i
                     (nconc
                      (list
                       (frame-parameter frame 'name)
                       (cons nil nil))
                      `(lambda ()
                         (interactive) (menu-bar-select-frame ,frame))))
		 (setq i (1+ i)))))
	     ;; Put it after the normal buffers
	     (setq buffers-menu
		   (nconc buffers-menu
			  `((frames-separator "--")
			  (frames menu-item "Frames" ,frames-menu :enable ,(> i 1) )))))

	 ;; Add in some normal commands at the end of the menu.  We use
	 ;; the copy cached in `menu-bar-buffers-menu-command-entries'
	 ;; if it's been set already.  Note that we can't use constant
	 ;; lists for the menu-entries, because the low-level menu-code
	 ;; modifies them.
	 (unless menu-bar-buffers-menu-command-entries
	   (setq menu-bar-buffers-menu-command-entries
		 (list '(command-separator "--")
		       (list 'next-buffer
			     'menu-item
			     "Next Buffer"
			     'next-buffer
			     :help "Switch to the \"next\" buffer in a cyclic order")
		       (list 'previous-buffer
			     'menu-item
			     "Previous Buffer"
			     'previous-buffer
			     :help "Switch to the \"previous\" buffer in a cyclic order")
		       (list 'select-named-buffer
			     'menu-item
			     "Select Named Buffer..."
			     'switch-to-buffer
			     :help "Prompt for a buffer name, and select that buffer in the current window")
		       (list 'list-all-buffers
			     'menu-item
			     "List All Buffers"
			     'list-buffers
			     :help "Pop up a window listing all Emacs buffers"
			     ))))
	 (setq buffers-menu
	       (nconc buffers-menu menu-bar-buffers-menu-command-entries))

         ;; We used to "(bindings--define-key (current-global-map) [menu-bar buffer]"
         ;; but that did not do the right thing when the [menu-bar buffer]
         ;; entry above had been moved (e.g. to a parent keymap).
	 (setcdr global-buffers-menu-map (cons "Buffers" buffers-menu)))))

(add-hook 'menu-bar-update-hook 'menu-bar-update-buffers)

(menu-bar-update-buffers)

;; this version is too slow
;;(defun format-buffers-menu-line (buffer)
;;  "Returns a string to represent the given buffer in the Buffer menu.
;;nil means the buffer shouldn't be listed.  You can redefine this."
;;  (if (string-match "\\` " (buffer-name buffer))
;;      nil
;;    (with-current-buffer buffer
;;     (let ((size (buffer-size)))
;;       (format "%s%s %-19s %6s %-15s %s"
;;	       (if (buffer-modified-p) "*" " ")
;;	       (if buffer-read-only "%" " ")
;;	       (buffer-name)
;;	       size
;;	       mode-name
;;	       (or (buffer-file-name) ""))))))

;;; Set up a menu bar menu for the minibuffer.

(dolist (map (list minibuffer-local-map
		   ;; This shouldn't be necessary, but there's a funny
		   ;; bug in keymap.c that I don't understand yet.  -stef
		   minibuffer-local-completion-map))
  (bindings--define-key map [menu-bar minibuf]
    (cons "Minibuf" (make-sparse-keymap "Minibuf"))))

(let ((map minibuffer-local-completion-map))
  (bindings--define-key map [menu-bar minibuf ?\?]
    '(menu-item "List Completions" minibuffer-completion-help
		:help "Display all possible completions"))
  (bindings--define-key map [menu-bar minibuf space]
    '(menu-item "Complete Word" minibuffer-complete-word
		:help "Complete at most one word"))
  (bindings--define-key map [menu-bar minibuf tab]
    '(menu-item "Complete" minibuffer-complete
		:help "Complete as far as possible")))

(let ((map minibuffer-local-map))
  (bindings--define-key map [menu-bar minibuf quit]
    '(menu-item "Quit" abort-recursive-edit
		:help "Abort input and exit minibuffer"))
  (bindings--define-key map [menu-bar minibuf return]
    '(menu-item "Enter" exit-minibuffer
		:key-sequence "\r"
		:help "Terminate input and exit minibuffer"))
  (bindings--define-key map [menu-bar minibuf isearch-forward]
    '(menu-item "Isearch History Forward" isearch-forward
		:help "Incrementally search minibuffer history forward"))
  (bindings--define-key map [menu-bar minibuf isearch-backward]
    '(menu-item "Isearch History Backward" isearch-backward
		:help "Incrementally search minibuffer history backward"))
  (bindings--define-key map [menu-bar minibuf next]
    '(menu-item "Next History Item" next-history-element
		:help "Put next minibuffer history element in the minibuffer"))
  (bindings--define-key map [menu-bar minibuf previous]
    '(menu-item "Previous History Item" previous-history-element
		:help "Put previous minibuffer history element in the minibuffer")))

(define-minor-mode menu-bar-mode
  "Toggle display of a menu bar on each frame (Menu Bar mode).
With a prefix argument ARG, enable Menu Bar mode if ARG is
positive, and disable it otherwise.  If called from Lisp, enable
Menu Bar mode if ARG is omitted or nil.

This command applies to all frames that exist and frames to be
created in the future."
  :init-value t
  :global t
  ;; It's defined in C/cus-start, this stops the d-m-m macro defining it again.
  :variable menu-bar-mode

  ;; Turn the menu-bars on all frames on or off.
  (let ((val (if menu-bar-mode 1 0)))
    (dolist (frame (frame-list))
      (set-frame-parameter frame 'menu-bar-lines val))
    ;; If the user has given `default-frame-alist' a `menu-bar-lines'
    ;; parameter, replace it.
    (if (assq 'menu-bar-lines default-frame-alist)
	(setq default-frame-alist
	      (cons (cons 'menu-bar-lines val)
		    (assq-delete-all 'menu-bar-lines
				     default-frame-alist)))))
  ;; Make the message appear when Emacs is idle.  We can not call message
  ;; directly.  The minor-mode message "Menu-bar mode disabled" comes
  ;; after this function returns, overwriting any message we do here.
  (when (and (called-interactively-p 'interactive) (not menu-bar-mode))
    (run-with-idle-timer 0 nil 'message
			 "Menu-bar mode disabled.  Use M-x menu-bar-mode to make the menu bar appear.")))

;;;###autoload
;; (This does not work right unless it comes after the above definition.)
;; This comment is taken from tool-bar.el near
;; (put 'tool-bar-mode ...)
;; We want to pretend the menu bar by standard is on, as this will make
;; customize consider disabling the menu bar a customization, and save
;; that.  We could do this for real by setting :init-value above, but
;; that would overwrite disabling the menu bar from X resources.
(put 'menu-bar-mode 'standard-value '(t))

(defun toggle-menu-bar-mode-from-frame (&optional arg)
  "Toggle menu bar on or off, based on the status of the current frame.
See `menu-bar-mode' for more information."
  (interactive (list (or current-prefix-arg 'toggle)))
  (if (eq arg 'toggle)
      (menu-bar-mode
       (if (menu-bar-positive-p
	    (frame-parameter (menu-bar-frame-for-menubar) 'menu-bar-lines))
	    0 1))
    (menu-bar-mode arg)))

(declare-function x-menu-bar-open "term/x-win" (&optional frame))
(declare-function w32-menu-bar-open "term/w32-win" (&optional frame))

(defun popup-menu (menu &optional position prefix from-menu-bar)
  "Popup the given menu and call the selected option.
MENU can be a keymap, an easymenu-style menu or a list of keymaps as for
`x-popup-menu'.
The menu is shown at the place where POSITION specifies. About
the form of POSITION, see `popup-menu-normalize-position'.
PREFIX is the prefix argument (if any) to pass to the command.
FROM-MENU-BAR, if non-nil, means we are dropping one of menu-bar's menus."
  (let* ((map (cond
	       ((keymapp menu) menu)
	       ((and (listp menu) (keymapp (car menu))) menu)
	       (t (let* ((map (easy-menu-create-menu (car menu) (cdr menu)))
			 (filter (when (symbolp map)
				   (plist-get (get map 'menu-prop) :filter))))
		    (if filter (funcall filter (symbol-function map)) map)))))
	 (frame (selected-frame))
	 event cmd)
    (if from-menu-bar
	(let* ((xy (posn-x-y position))
	       (menu-symbol (menu-bar-menu-at-x-y (car xy) (cdr xy))))
	  (setq position (list menu-symbol (list frame '(menu-bar)
						 xy 0))))
      (setq position (popup-menu-normalize-position position)))
    ;; The looping behavior was taken from lmenu's popup-menu-popup
    (while (and map (setq event
			  ;; map could be a prefix key, in which case
			  ;; we need to get its function cell
			  ;; definition.
			  (x-popup-menu position (indirect-function map))))
      ;; Strangely x-popup-menu returns a list.
      ;; mouse-major-mode-menu was using a weird:
      ;; (key-binding (apply 'vector (append '(menu-bar) menu-prefix events)))
      (setq cmd
	    (cond
	     ((and from-menu-bar
		   (consp event)
		   (numberp (car event))
		   (numberp (cdr event)))
	      (let ((x (car event))
		    (y (cdr event))
		    menu-symbol)
		(setq menu-symbol (menu-bar-menu-at-x-y x y))
		(setq position (list menu-symbol (list frame '(menu-bar)
						 event 0)))
		(setq map
		      (key-binding (vector 'menu-bar menu-symbol)))))
	     ((and (not (keymapp map)) (listp map))
	      ;; We were given a list of keymaps.  Search them all
	      ;; in sequence until a first binding is found.
	      (let ((mouse-click (apply 'vector event))
		    binding)
		(while (and map (null binding))
		  (setq binding (lookup-key (car map) mouse-click))
		  (if (numberp binding)	; `too long'
		      (setq binding nil))
		  (setq map (cdr map)))
		  binding))
	     (t
	      ;; We were given a single keymap.
	      (lookup-key map (apply 'vector event)))))
      ;; Clear out echoing, which perhaps shows a prefix arg.
      (message "")
      ;; Maybe try again but with the submap.
      (setq map (if (keymapp cmd) cmd)))
    ;; If the user did not cancel by refusing to select,
    ;; and if the result is a command, run it.
    (when (and (null map) (commandp cmd))
      (setq prefix-arg prefix)
      ;; `setup-specified-language-environment', for instance,
      ;; expects this to be set from a menu keymap.
      (setq last-command-event (car (last event)))
      ;; mouse-major-mode-menu was using `command-execute' instead.
      (call-interactively cmd))))

(defun popup-menu-normalize-position (position)
  "Convert the POSITION to the form which `popup-menu' expects internally.
POSITION can an event, a posn- value, a value having
form ((XOFFSET YOFFSET) WINDOW), or nil.
If nil, the current mouse position is used."
  (pcase position
    ;; nil -> mouse cursor position
    (`nil
     (let ((mp (mouse-pixel-position)))
       (list (list (cadr mp) (cddr mp)) (car mp))))
    ;; Value returned from `event-end' or `posn-at-point'.
    ((pred posnp)
     (let ((xy (posn-x-y position)))
       (list (list (car xy) (cdr xy))
	     (posn-window position))))
    ;; Event.
    ((pred eventp)
     (popup-menu-normalize-position (event-end position)))
    (t position)))

(defcustom tty-menu-open-use-tmm nil
  "If non-nil, \\[menu-bar-open] on a TTY will invoke `tmm-menubar'.

If nil, \\[menu-bar-open] will drop down the menu corresponding to the
first (leftmost) menu-bar item; you can select other items by typing
\\[forward-char], \\[backward-char], \\[right-char] and \\[left-char]."
  :type '(choice (const :tag "F10 drops down TTY menus" nil)
		 (const :tag "F10 invokes tmm-menubar" t))
  :group 'display
  :version "24.4")

(defvar tty-menu--initial-menu-x 1
  "X coordinate of the first menu-bar menu dropped by F10.

This is meant to be used only for debugging TTY menus.")

(defun menu-bar-open (&optional frame)
  "Start key navigation of the menu bar in FRAME.

This function decides which method to use to access the menu
depending on FRAME's terminal device.  On X displays, it calls
`x-menu-bar-open'; on Windows, `w32-menu-bar-open'; otherwise it
calls either `popup-menu' or `tmm-menubar' depending on whether
\`tty-menu-open-use-tmm' is nil or not.

If FRAME is nil or not given, use the selected frame."
  (interactive)
  (let ((type (framep (or frame (selected-frame)))))
    (cond
     ((eq type 'x) (x-menu-bar-open frame))
     ((eq type 'w32) (w32-menu-bar-open frame))
     ((and (null tty-menu-open-use-tmm)
	   (not (zerop (or (frame-parameter nil 'menu-bar-lines) 0))))
      ;; Make sure the menu bar is up to date.  One situation where
      ;; this is important is when this function is invoked by name
      ;; via M-x, in which case the menu bar includes the "Minibuf"
      ;; menu item that should be removed when we exit the minibuffer.
      (force-mode-line-update)
      (redisplay)
      (let* ((x tty-menu--initial-menu-x)
	     (menu (menu-bar-menu-at-x-y x 0 frame)))
	(popup-menu (or
		     (lookup-key global-map (vector 'menu-bar menu))
		     (lookup-key (current-local-map) (vector 'menu-bar menu))
		     (cdar (minor-mode-key-binding (vector 'menu-bar menu))))
		    (posn-at-x-y x 0 nil t) nil t)))
     (t (with-selected-frame (or frame (selected-frame))
          (tmm-menubar))))))

(global-set-key [f10] 'menu-bar-open)

(defvar tty-menu-navigation-map
  (let ((map (make-sparse-keymap)))
    ;; The next line is disabled because it breaks interpretation of
    ;; escape sequences, produced by TTY arrow keys, as tty-menu-*
    ;; commands.  Instead, we explicitly bind some keys to
    ;; tty-menu-exit.
    ;;(bindings--define-key map [t] 'tty-menu-exit)

    ;; The tty-menu-* are just symbols interpreted by term.c, they are
    ;; not real commands.
    (dolist (bind '((keyboard-quit . tty-menu-exit)
                    (keyboard-escape-quit . tty-menu-exit)
                    ;; The following two will need to be revised if we ever
                    ;; support a right-to-left menu bar.
                    (forward-char . tty-menu-next-menu)
                    (backward-char . tty-menu-prev-menu)
                    (right-char . tty-menu-next-menu)
                    (left-char . tty-menu-prev-menu)
                    (next-line . tty-menu-next-item)
                    (previous-line . tty-menu-prev-item)
                    (newline . tty-menu-select)
                    (newline-and-indent . tty-menu-select)
		    (menu-bar-open . tty-menu-exit)))
      (substitute-key-definition (car bind) (cdr bind)
                                 map (current-global-map)))

    ;; The bindings of menu-bar items are so that clicking on the menu
    ;; bar when a menu is already shown pops down that menu.
    (bindings--define-key map [menu-bar t] 'tty-menu-exit)

    (bindings--define-key map [?\C-r] 'tty-menu-select)
    (bindings--define-key map [?\C-j] 'tty-menu-select)
    (bindings--define-key map [return] 'tty-menu-select)
    (bindings--define-key map [linefeed] 'tty-menu-select)
    (bindings--define-key map [mouse-1] 'tty-menu-select)
    (bindings--define-key map [drag-mouse-1] 'tty-menu-select)
    (bindings--define-key map [mouse-2] 'tty-menu-select)
    (bindings--define-key map [drag-mouse-2] 'tty-menu-select)
    (bindings--define-key map [mouse-3] 'tty-menu-select)
    (bindings--define-key map [drag-mouse-3] 'tty-menu-select)
    (bindings--define-key map [wheel-down] 'tty-menu-next-item)
    (bindings--define-key map [wheel-up] 'tty-menu-prev-item)
    (bindings--define-key map [wheel-left] 'tty-menu-prev-menu)
    (bindings--define-key map [wheel-right] 'tty-menu-next-menu)
    ;; The following 4 bindings are for those whose text-mode mouse
    ;; lack the wheel.
    (bindings--define-key map [S-mouse-1] 'tty-menu-next-item)
    (bindings--define-key map [S-drag-mouse-1] 'tty-menu-next-item)
    (bindings--define-key map [S-mouse-2] 'tty-menu-prev-item)
    (bindings--define-key map [S-drag-mouse-2] 'tty-menu-prev-item)
    (bindings--define-key map [S-mouse-3] 'tty-menu-prev-item)
    (bindings--define-key map [S-drag-mouse-3] 'tty-menu-prev-item)
    (bindings--define-key map [header-line mouse-1] 'tty-menu-select)
    (bindings--define-key map [header-line drag-mouse-1] 'tty-menu-select)
    ;; The down-mouse events must be bound to tty-menu-ignore, so that
    ;; only releasing the mouse button pops up the menu.
    (bindings--define-key map [mode-line down-mouse-1] 'tty-menu-ignore)
    (bindings--define-key map [mode-line down-mouse-2] 'tty-menu-ignore)
    (bindings--define-key map [mode-line down-mouse-3] 'tty-menu-ignore)
    (bindings--define-key map [mode-line C-down-mouse-1] 'tty-menu-ignore)
    (bindings--define-key map [mode-line C-down-mouse-2] 'tty-menu-ignore)
    (bindings--define-key map [mode-line C-down-mouse-3] 'tty-menu-ignore)
    (bindings--define-key map [down-mouse-1] 'tty-menu-ignore)
    (bindings--define-key map [C-down-mouse-1] 'tty-menu-ignore)
    (bindings--define-key map [C-down-mouse-2] 'tty-menu-ignore)
    (bindings--define-key map [C-down-mouse-3] 'tty-menu-ignore)
    (bindings--define-key map [mouse-movement] 'tty-menu-mouse-movement)
    map)
  "Keymap used while processing TTY menus.")

(provide 'menu-bar)

;;; menu-bar.el ends here
