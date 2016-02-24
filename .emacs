;;; myinit --- My custom init file
;;; Commentary:
;;;   See accompanying GitHub repository for more specifics
;;;   Depends upon a assisting python environment being in the %PATH%.
;;;      One with introspection tools such as `pylint` and `jedi`.
;;; Code:

;; Raise the GC threshold while running this init script
;;   Having one large pause at the end is better than 40+ medium pauses during launch
;;   Restored at the end to interactive levels, but shaves 0.5 seconds off of load
(setq gc-cons-threshold 42000000)

;; Ensure an actual Emacs server process is running.
;; If it is not, go ahead and start one up.
;; Do this so subsequent calls to emacsclientw.exe can hook into it.
(require 'server)
(or (server-running-p)
    (server-start))

;; Start the initial frame maximized
(add-to-list 'initial-frame-alist '(fullscreen . maximized))

;; Raise GC thresholds to modern levels (to ~32MB from ~1MB) while in minibuffer
;;   Borrowed from here: http://bling.github.io/blog/2016/01/18/why-are-you-changing-gc-cons-threshold/
(defun my-minibuffer-setup-hook ()
  (setq gc-cons-threshold 42000000))

(defun my-minibuffer-exit-hook ()
  (setq gc-cons-threshold 800000))

(add-hook 'minibuffer-setup-hook #'my-minibuffer-setup-hook)
(add-hook 'minibuffer-exit-hook #'my-minibuffer-exit-hook)

;; Remove tempations to utilize the GUI
(menu-bar-mode -1)
(tool-bar-mode -1)

;; Do not show the welcome screen (drops straight into god-mode now, see below)
(setq inhibit-startup-message t)

;; Use a more sane cursor type (adjusted by god-mode below)
(setq-default cursor-type 'bar)

;; React normally when typing with a region active
(delete-selection-mode 1)

;; Stop beeping when I hit the end of the file
(setq ring-bell-function 'ignore)

;; Don't jump by half a screen when scrolling on the boundaries
(setq scroll-step 1) ;; Scroll one line a time
(setq scroll-margin 4) ;; Scroll before you hit the actual edge

;; Place a nice code-navigation menu under a right-click menu
(global-set-key [mouse-3] 'imenu)

;; Use the improved buffer menu by default
;;   TODO: Come back through and add categories
(global-set-key (kbd "C-x C-b") 'ibuffer)

;; Make it a bit easier to move around windows
(global-set-key (kbd "M-o") 'other-window)

;; Consider dashes and underscores part of a word in prog-mode
(add-hook 'prog-mode-hook #'superword-mode)

;; Insert matching parens like a real editor
(add-hook 'prog-mode-hook #'electric-pair-mode)
;; And highlight the matching parens
(add-hook 'prog-mode-hook #'show-paren-mode)
;; Actually, highlight the whole expression
(setq show-paren-style 'expression)

;; Activate the bundled `ido` mode
;;   Haven't gone to the external `flx-ido` implementation yet
(require 'ido)
(setq ido-enable-flex-matching t)
(setq ido-separator "\n")
(ido-mode t)

;; Activate visible whitespace for code files
(add-hook 'prog-mode-hook #'whitespace-mode)
;; Be refined in what we flag.  Just the bad stuff and then tabs/spaces via marks
(setq whitespace-style (quote
   (face trailing lines space-mark tab-mark)))
;; Kill trailing whitespace on save
(add-hook 'before-save-hook 'delete-trailing-whitespace)
;; Adjust when to flag a line as too-long via font
(setq whitespace-line-column 100)
;; Show empty lines at the end of the file while we're at it
(setq-default indicate-empty-lines t)
;; And ensure there is a newline at the end (even though the above does not show it)
(setq require-final-newline t)

;; Custom function to search Python 3 docs
(defun python-docs (search_string)
  "Search the official Python 3 documentation"
  (interactive "sSearch Python 3 Docs for: ")
  (browse-url (concat "https://docs.python.org/3/search.html?q=" search_string)))
(add-hook 'python-mode-hook (lambda ()(local-set-key (kbd "C-c d") 'python-docs)))

;; Configure spell checking
;;   Needs `hunspell` in %PATH%
;;   Snag `hunspell` from ezwinports (should come with en_US dictionary files)
;; Below was somewhat configuration by coincidence.  Borrowed heavily from:
;;   http://www.nextpoint.se/?p=656
;;   http://www.mygooglest.com/fni/.emacs
(setq flyspell-auto-correct-binding (kbd "C-:"))  ;; Move aside default keybinding for iedit
(require 'flyspell)
(setq-default ispell-program-name "hunspell")
(setq ispell-really-hunspell t)
(setq ispell-dictionary "en_US")
(setq ispell-dictionary-alist '(("en_US"
                                 "[[:alpha:]]"
                                 "[^[:alpha:]]"
                                 "[']"
                                  t
                                  ("-d" "en_US")
                                  nil
                                  utf-8)))
(setq ispell-local-dictionary-alist ispell-dictionary-alist)
(setq ispell-hunspell-dictionary-alist ispell-dictionary-alist)
(add-hook 'text-mode-hook (lambda () (flyspell-mode 1)))
(add-hook 'prog-mode-hook (lambda () (flyspell-prog-mode)))

;; Setup where to pull third party packages from
(require 'package)
(add-to-list 'package-archives '("melpa-stable" . "http://stable.melpa.org/packages/") t)
;; Only enable the bleeding-edge MELPA when a package doesn't utilize tags (e.g. god-mode)
;; (add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)
(package-initialize)


;; M-x package-install RET zenburn RET
(load-theme 'zenburn t)


;; M-x package-install RET flycheck RET
;; Flycheck uses the fringe
;; Needs `pylint` on your %PATH%
(require 'flycheck)
(add-hook 'after-init-hook #'global-flycheck-mode)


;; M-x package-install RET git-gutter RET
;; Git-gutter uses the margin by default
;; Needs `git` and `diff` on your %PATH%
;; `diff` is often provided in the `/usr/bin` folder of a git-for-windows MinGW system
(require 'git-gutter)
(global-git-gutter-mode +1)
;; Needs to be told to do live diffs
(setq git-gutter:update-interval 2)
;; Give a keybinding to force refresh (it gets confused)
(global-set-key (kbd "C-c g") 'git-gutter)


;; Possible alternative to git-gutter, it's a mixed bag
;; M-x package-install RET diff-hl RET
;; (require 'diff-hl)
;; TODO: Confirm if diff-hl needs `diff` in the %PATH%
;; (global-diff-hl-mode)
;; diff-hl uses the fring by default, but conflicts with flycheck
;; (diff-hl-margin-mode)
;; Enable on-the-fly indicators
;; (diff-hl-flydiff-mode)


;; M-x package-install RET magit RET
(require 'magit)
;; Try and let magit handle setting up minor modes and shortcuts for git-backed files
;;   I'm not convinced this gets auto-revert correct, but I do think it's the way of the future
(global-magit-file-mode t)
;; While using magit, it's most convenient to use Windows credential storage
;;   GitHub Desktop doesn't like that setting and will continuously remove it
;;   The function and hook below continuously applies it when using magit
(defun force-git-wincred ()
  "Force Git to use wincred again"
  (start-process
     "force-git-wincred"
     nil
     "git"
     "config"
     "--global"
     "credential.helper"
     "wincred"))
(defun force-git-emacsclient ()
  "Force Git to use emacsclient again"
  (start-process
     "force-git-emacsclient"
     nil
     "git"
     "config"
     "--global"
     "core.editor"
     "emacsclient"))
(add-hook 'magit-pre-display-buffer-hook 'force-git-wincred)
(add-hook 'magit-pre-display-buffer-hook 'force-git-emacsclient)
;; Also swap it so the password prompt is a popup when it's needed
(setenv "GIT_ASKPASS" "git-gui--askpass")
;; Integrate git-gutter into magit (Not confirmed working)
(add-hook 'git-gutter:update-hooks 'magit-after-revert-hook)
(add-hook 'git-gutter:update-hooks 'magit-not-reverted-hook)


;; M-x package-install RET multiple-cursors RET
(require 'multiple-cursors)
(global-set-key (kbd "C->") 'mc/mark-next-like-this)
(global-set-key (kbd "C-<") 'mc/mark-previous-like-this)


;; M-x package-install RET rainbow-delimiters RET
(require 'rainbow-delimiters)
;; Enable for most programming modes
(add-hook 'prog-mode-hook #'rainbow-delimiters-mode)


;; M-x package-install RET jedi RET
;; Jedi drags along the maligned `auto-complete` package
;;   Could install an additional package to integrate with `company`, but didn't seem to be worth it
;; When `jedi:setup` is called, it must execute the bundled `jediepcserver.py`
;;   in a python environment that has `jedi` and `epc` python packages.
;; Jedi offers to setup such an environment, but that then depends upon `virtualenv` as opposed to `conda`.
;; To bypass this mess, ensure the first `python` on %PATH% can import `jedi` and `epc`.
;;  Alternatively, adjust jedi:server-command to target a python that does.
(require 'jedi)
(add-hook 'python-mode-hook 'jedi:setup)
(setq jedi:complete-on-dot t)
(define-key jedi-mode-map (kbd "<C-tab>") 'jedi:complete)


;; M-x package-install RET markdown-mode RET
(require 'markdown-mode)
(setq markdown-command "pandoc")


;; M-x package-install RET fill-column-indicator RET
(require 'fill-column-indicator)
(add-hook 'prog-mode-hook (lambda () (set-fill-column 100)))
;; Enable for most programming modes
(add-hook 'prog-mode-hook #'fci-mode)


;; M-x package-install RET yaml-mode RET
(require 'yaml-mode)
;; Not part of `prog-mode`, so need to re-hook some minor modes
(add-hook 'yaml-mode-hook #'whitespace-mode)
(add-hook 'yaml-mode-hook #'show-paren-mode)
(add-hook 'yaml-mode-hook #'electric-pair-mode)
(add-hook 'yaml-mode-hook #'superword-mode)


;; M-x package-install RET god-mode RET
;; Only available on MELPA unstable for now
(require 'god-mode)
;; Turn it on by default
(god-mode)
(global-set-key (kbd "<escape>") 'god-local-mode)
;; I hate the minimize keybinding anyway
(global-set-key (kbd "C-z") 'god-local-mode)
;; Get used to VIM style entry into insert mode
(define-key god-local-mode-map (kbd "i") 'god-local-mode)
;; Make it easier to work with windows
(global-set-key (kbd "C-x C-1") 'delete-other-windows)
(global-set-key (kbd "C-x C-2") 'split-window-below)
(global-set-key (kbd "C-x C-3") 'split-window-right)
(global-set-key (kbd "C-x C-0") 'delete-window)
(global-set-key (kbd "C-x C-4 C-f") 'ido-find-file-other-window)
(global-set-key (kbd "C-x C-4 C-b") 'ido-switch-buffer-other-window)
(global-set-key (kbd "C-x C-4 C-d") 'dired-other-window)
(global-set-key (kbd "C-x C-4 C-0") 'kill-buffer-and-window)
(global-set-key (kbd "C-x C-k") 'ido-kill-buffer)
;; And some other convenience mappings
;; (global-set-key (kbd "C-x C-g") 'magit-status) ;; C-g is quit
;; (global-set-key (kbd "C-c C-g") 'git-gutter) ;; C-g is quit
(add-hook 'python-mode-hook (lambda ()(local-set-key (kbd "C-c C-d") 'python-docs)))
;; Toggle cursor to give strong visual clues
;; Borrowed from god-mode readme
(defun my-update-cursor ()
  (setq cursor-type (if (or god-local-mode buffer-read-only)
                        'box
                      'bar)))
(add-hook 'god-mode-enabled-hook 'my-update-cursor)
(add-hook 'god-mode-disabled-hook 'my-update-cursor)


;; M-x package-install RET drag-stuff RET
(require 'drag-stuff)
(drag-stuff-global-mode)


;; M-x package-install RET iedit RET
(require 'iedit)
;; Allow RET to exit iedit-mode (like other search/multiple edit modes)
;;   * http://stackoverflow.com/questions/25238760/how-do-i-exit-iedit-mode-with-enter
(defun quit-iedit-mode ()
  "Turn off iedit-mode."
  (interactive)
  (iedit-mode -1))
(define-key iedit-mode-keymap (kbd "RET") 'quit-iedit-mode)


;; M-x package-install RET expand-region RET
(require 'expand-region)
(global-set-key (kbd "C-=") 'er/expand-region)


;; M-x package-install RET ess RET
(require 'ess-site)


;; Restore the GC threshold to more appropriate levels for interactive use
(setq gc-cons-threshold 800000)
