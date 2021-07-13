(setq episteme/root (expand-file-name default-directory))
(setq episteme/org (concat episteme/root "org"))
(setq episteme/home (concat (getenv "HOME") "/.config/" "episteme/"))
(setq episteme/autosaves (concat episteme/home "autosaves"))
(setq episteme/backups (concat episteme/home "backups"))

(setq org-directory episteme/org)
(setq user-emacs-directory episteme/home)
(unless (file-exists-p episteme/home)
  (make-directory episteme/home))

(defun episteme/setup ()
  (setq episteme/zoom 4)
  (:bind "C-x g" magit-status)
  (:bind "<f12>" (hera-start 'episteme-hydra-default/body))
  (:bind "<f13>" episteme:hydra-dwim)
  ;; probably leave these alone though
  )
(setq byte-complile-warnings '(not cl-functions))

;;; -*- lexical-binding: t; -*-

(let ((bootstrap-file (concat user-emacs-directory "straight/repos/straight.el/bootstrap.el"))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(setq straight-use-package-by-default t)
(straight-use-package 'use-package)
(use-package git) ;; ensure we can install from git sources

(require 'cl-lib)
(use-package f :demand t)          ;; files
(use-package dash :demand t)       ;; lists
(use-package ht :demand t)         ;; hash-tables
(use-package s :demand t)          ;; strings
(use-package a :demand t)          ;; association lists
(use-package anaphora :demand t)   ;; anaphora

(defmacro :function (&rest body)
  (if (->> body length (< 1))
      `(lambda () ,@body)
    (pcase (car body)
      ;; command symbol
      ((and v (pred commandp))
       `(lambda () (call-interactively (quote ,v))))
      ;; function symbol
      ((and v (pred symbolp))
       `(lambda () (,v)))
      ;; quoted command symbol
      ((and v (pred consp) (guard (eq 'quote (car v))) (pred commandp (cadr v)))
       `(lambda () (call-interactively ,v)))
      ;; quoted function symbol
      ((and v (pred consp) (guard (eq 'quote (car v))))
       `(lambda () (,(cadr v))))
      ;; body forms
      (_ `(lambda () ,@body) ))))

(defmacro :command (&rest body)
  (if (->> body length (< 1))
      `(lambda () (interactive) ,@body)
    (pcase (car body)
      ;; command symbol
      ((and v (pred commandp))
       `(lambda () (interactive) (call-interactively (quote ,v))))
      ;; function symbol
      ((and v (pred symbolp))
       `(lambda () (interactive) (,v)))
      ;; quoted command symbol
      ((and v (pred consp) (guard (eq 'quote (car v))) (pred commandp (cadr v)))
       `(lambda () (interactive) (call-interactively ,v)))
      ;; quoted function symbol
      ((and v (pred consp) (guard (eq 'quote (car v))))
       `(lambda () (interactive) (,(cadr v))))
      ;; body forms
      (_ `(lambda () (interactive) ,@body) ))))

(defmacro :after (package &rest body)
  "A simple wrapper around `with-eval-after-load'."
  (declare (indent defun))
  `(with-eval-after-load ',package ,@body))

(defmacro :hook (hook-name &rest body)
  "A simple wrapper around `add-hook'"
  (declare (indent defun))
  (let* ((hook-name (format "%s-hook" (symbol-name hook-name)))
         (hook-sym (intern hook-name))
         (first (car body))
         (local (eq :local first))
         (body (if local (cdr body) body))
         (first (car body))
         (body (if (consp first)
                   (if (eq (car first) 'quote)
                       first
                     `(lambda () ,@body))
                 `',first)))
    `(add-hook ',hook-sym ,body nil ,local)))

(defmacro :push (sym &rest body)
  (declare (indent defun))
  (if (consp body)
      `(setq ,sym (-snoc ,sym ,@body))
    `(add-to-list ,sym ,body)))

(defmacro :bind (key &rest body)
  (declare (indent defun))
  (pcase key
    ;; kbd string resolving symbol
    ((and k (pred symbolp) (pred boundp) (guard (stringp (eval key))))
     `(global-set-key (kbd ,(eval key)) ,(eval `(:command ,@body))))
    ;; partial mode symbol
    ((pred symbolp)
     (let ((mode (intern (format "%s-map" key)))
           (key (eval (car body)))
           (body (eval `(:command ,@(cdr body)))))
       `(define-key ,mode (kbd ,key) ,body)))
    ;; global binding
    (_ `(global-set-key (kbd ,key) ,(eval `(:command ,@body))))))

(episteme/setup)

(set-face-foreground 'vertical-border "gray")

(set-face-attribute 'fringe nil :background nil)

(column-number-mode 1)

(use-package doom-modeline
  :ensure t
  :config
  (doom-modeline-def-modeline
   'my-modeline

   '(bar workspace-name window-number modals matches buffer-info remote-host selection-info)
   '(objed-state misc-info buffer-position major-mode process vcs checker))

  (doom-modeline-mode 1)
  (setq doom-modeline-height 35)
  (setq doom-modeline-bar-width 5)
  :init
  (defun setup-custom-doom-modeline ()
    (doom-modeline-set-modeline 'my-modeline 'default))
  (:hook doom-modeline-mode 'setup-custom-doom-modeline))

(use-package doom-themes
  :ensure t
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t     ; if nil, bold is universally disabled
        doom-themes-enable-italic t)  ; if nil, italics is universally disabled
  (load-theme (intern (format "doom-%s" (or (getenv "theme") "laserwave"))) t)

  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

(setq auto-save-default t)

(setq auto-save-timeout 20
      auto-save-interval 20)

(unless (file-exists-p episteme/autosaves)
    (make-directory episteme/autosaves))

(setq auto-save-file-name-transforms
      `((".*" ,episteme/autosaves t)))

(use-package backup-each-save
  :config (:hook after-save backup-each-save))

(setq kept-new-versions 10)

(setq delete-old-versions t)

(setq backup-by-copying t)

(setq vc-make-backup-files t)

(unless (file-exists-p episteme/backups)
  (make-directory episteme/backups))

(setq backup-directory-alist
      `((".*" . ,episteme/backups)))

(setq make-backup-files t)

(setq-default cursor-type 'box)

(blink-cursor-mode 1)

(menu-bar-mode -1)

(tool-bar-mode -1)

(scroll-bar-mode -1)

(setq inhibit-startup-message t
      initial-scratch-message nil)

(setq custom-file (make-temp-file ""))

(setq-default indent-tabs-mode nil)

(use-package visual-fill-column
  :config
  (global-visual-fill-column-mode))

(setq-default fill-column 79)

(:hook text-mode 'turn-on-auto-fill)

(setq tramp-default-method "ssh")

(use-package whitespace
  :custom
  (whitespace-style
   '(face tabs newline trailing tab-mark space-before-tab space-after-tab))
  :config
  (global-whitespace-mode 1))

(global-prettify-symbols-mode 1)

(electric-pair-mode 1)

(require 'color)
(defun gen-col-list (length s v &optional hval)
  (cl-flet ( (random-float () (/ (random 10000000000) 10000000000.0))
          (mod-float (f) (- f (ffloor f))) )
    (unless hval
      (setq hval (random-float)))
    (let ((golden-ratio-conjugate (/ (- (sqrt 5) 1) 2))
          (h hval)
          (current length)
          (ret-list '()))
      (while (> current 0)
        (setq ret-list
              (append ret-list
                      (list (apply 'color-rgb-to-hex (color-hsl-to-rgb h s v)))))
        (setq h (mod-float (+ h golden-ratio-conjugate)))
        (setq current (- current 1)))
      ret-list)))

(defun set-random-rainbow-colors (s l &optional h)
  ;; Output into message buffer in case you get a scheme you REALLY like.
  ;; (message "set-random-rainbow-colors %s" (list s l h))
  (interactive)
  (rainbow-delimiters-mode t)

  ;; Show mismatched braces in bright red.
  (set-face-background 'rainbow-delimiters-unmatched-face "red")

  ;; Rainbow delimiters based on golden ratio
  (let ( (colors (gen-col-list 9 s l h))
         (i 1) )
    (let ( (length (length colors)) )
      ;;(message (concat "i " (number-to-string i) " length " (number-to-string length)))
      (while (<= i length)
        (let ( (rainbow-var-name (concat "rainbow-delimiters-depth-" (number-to-string i) "-face"))
               (col (nth i colors)) )
          ;; (message (concat rainbow-var-name " => " col))
          (set-face-foreground (intern rainbow-var-name) col))
        (setq i (+ i 1))))))

(use-package rainbow-delimiters :commands rainbow-delimiters-mode :hook ...
  :init
  (setq rainbow-delimiters-max-face-count 16)
  (set-random-rainbow-colors 0.6 0.7 0.5)
  (:hook prog-mode 'rainbow-delimiters-mode))

(require 'paren)
(show-paren-mode 1)
(setq show-paren-delay 0)
(:after xresources
  (set-face-foreground 'show-paren-match (theme-color 'green))
  (set-face-foreground 'show-paren-mismatch "#f00")
  (set-face-attribute 'show-paren-match nil :weight 'extra-bold)
  (set-face-attribute 'show-paren-mismatch nil :weight 'extra-bold))

(use-package which-key
  :custom
  ;; sort single chars alphabetically P p Q q
  (which-key-sort-order 'which-key-key-order-alpha)
  (which-key-idle-delay 0.4)
  :config
  (which-key-mode))

(use-package company
  :config
  (global-company-mode))

(fset 'yes-or-no-p 'y-or-n-p)

(use-package zoom-frm
  :straight (zoom-frm :type git
                      :host github
                      :repo "emacsmirror/zoom-frm")
  :config
  (dotimes (i episteme/zoom) (zoom-frm-in)))

(use-package persistent-soft)

(setq print-level 100
      print-length 9999
      eval-expression-print-level 100
      eval-expression-print-length 9999)

(setq debug-on-error t)

(use-package helpful
    :straight (helpful :type git :host github :repo "Wilfred/helpful")
    :bind (("C-h s" . #'helpful-symbol)
           ("C-h c" . #'helpful-command)
           ("C-h f" . #'helpful-function)
           ("C-h v" . #'helpful-variable)
           ("C-h k" . #'helpful-key)
           ("C-h m" . #'helpful-mode)
           ("C-h C-h" . #'helpful-at-point)))

(defun toggle-context-help ()
  "Turn on or off the context help.
Note that if ON and you hide the help buffer then you need to
manually reshow it. A double toggle will make it reappear"
  (interactive)
  (with-current-buffer (help-buffer)
    (unless (local-variable-p 'context-help)
      (set (make-local-variable 'context-help) t))
    (if (setq context-help (not context-help))
        (progn
           (if (not (get-buffer-window (help-buffer)))
               (display-buffer (help-buffer)))))
    (message "Context help %s" (if context-help "ON" "OFF"))))

(defun context-help ()
  "Display function or variable at point in *Help* buffer if visible.
Default behaviour can be turned off by setting the buffer local
context-help to false"
  (interactive)
  (let ((rgr-symbol (symbol-at-point))) ; symbol-at-point http://www.emacswiki.org/cgi-bin/wiki/thingatpt%2B.el
    (with-current-buffer (help-buffer)
     (unless (local-variable-p 'context-help)
       (set (make-local-variable 'context-help) t))
     (if (and context-help (get-buffer-window (help-buffer))
         rgr-symbol)
       (if (fboundp  rgr-symbol)
           (describe-function rgr-symbol)
         (if (boundp  rgr-symbol) (describe-variable rgr-symbol)))))))

(defadvice eldoc-print-current-symbol-info
  (around eldoc-show-c-tag activate)
  (cond
        ((eq major-mode 'emacs-lisp-mode) (context-help) ad-do-it)
        ((eq major-mode 'lisp-interaction-mode) (context-help) ad-do-it)
        ((eq major-mode 'apropos-mode) (context-help) ad-do-it)
        (t ad-do-it)))

(use-package json-mode
  :straight (json-mode :type git
                       :host github
                       :repo "kiennq/json-mode"
                       :branch "feat/jsonc-mode")
  :config
  (setf auto-mode-alist (assoc-delete-all "\\(?:\\(?:\\.\\(?:b\\(?:\\(?:abel\\|ower\\)rc\\)\\|json\\(?:ld\\)?\\)\\|composer\\.lock\\)\\'\\)"
                                          auto-mode-alist))
  (setf auto-mode-alist (assoc-delete-all "\\.json\\'" auto-mode-alist))
  (add-to-list 'auto-mode-alist '("\\.json\\'" . jsonc-mode)))

(use-package helm
  :config
  (helm-mode 1)
  (require 'helm-config)
  (:bind "M-x" helm-M-x)
  (:bind "C-x C-f" helm-find-files)
  (:bind "C-x b" helm-mini)
  (:bind "C-c y" helm-show-kill-ring)
  (:bind "C-x C-r" helm-recentf))

(use-package ace-jump-helm-line
  :config
  (:bind helm "C-;" ace-jump-helm-line))

(use-package helm-ag)

(use-package helm-descbinds
  :commands helm-descbinds
  :config
  (:bind "C-h b" helm-descbinds))

(defvar helm-full-frame-threshold 0.75)

(when window-system
  (defun helm-full-frame-hook ()
  (let ((threshold (* helm-full-frame-threshold (x-display-pixel-height))))
    (setq helm-full-frame (< (frame-height) threshold))))

  (:hook helm-before-initialize 'helm-full-frame-hook))

(use-package magit)

(defun fix-org-git-version ()
  "The Git version of org-mode.
  Inserted by installing org-mode or when a release is made."
  (require 'git)
  (let ((git-repo (expand-file-name
                   "straight/repos/org/" user-emacs-directory)))
    (string-trim
     (git-run "describe"
              "--match=release\*"
              "--abbrev=6"
              "HEAD"))))

(defun fix-org-release ()
  "The release version of org-mode.
  Inserted by installing org-mode or when a release is made."
  (require 'git)
  (let ((git-repo (expand-file-name
                   "straight/repos/org/" user-emacs-directory)))
    (string-trim
     (string-remove-prefix
      "release_"
      (git-run "describe"
               "--match=release\*"
               "--abbrev=0"
               "HEAD")))))

(use-package org
  :config
  ;; these depend on the 'straight.el fixes' above
  (defalias #'org-git-version #'fix-org-git-version)
  (defalias #'org-release #'fix-org-release)
  (require 'org-habit)
  (require 'org-indent)
  (require 'org-capture)
  (require 'org-tempo)
  (add-to-list 'org-modules 'org-habit t))

(when window-system
  (use-package org-beautify-theme
    :after (org)
    :config
    (setq org-fontify-whole-heading-line t)
    (setq org-fontify-quote-and-verse-blocks t)
    (setq org-hide-emphasis-markers t)))

(setq episteme/pretty-symbols nil)
(:hook org-mode
  (setq-local prettify-symbols-alist episteme/pretty-symbols))

(:hook org-mode 'org-indent-mode)

(use-package org-bullets
  :init
  (:hook org-mode 'org-bullets-mode)
  :config
  (setq org-bullets-bullet-list '("◉" "○" "✸" "•")))

(:push episteme/pretty-symbols
  '("[#A]" . "⇑")
  '("[#C]" . "⇓"))

;; only show priority cookie symbols on headings.
(defun nougat/org-pretty-compose-p (start end match)
  (if (or (string= match "[#A]") (string= match "[#C]"))
      ;; prettify asterisks in headings
      (org-match-line org-outline-regexp-bol)
    ;; else rely on the default function
    (funcall #'prettify-symbols-default-compose-p start end match)))


(:hook org-mode (setq-local prettify-symbols-compose-predicate
                            #'nougat/org-pretty-compose-p))

(:after org
  (setq org-ellipsis " ▿"))

(:push episteme/pretty-symbols
  '("#+begin_src" . ">>")
  '("#+end_src" . "·"))

(defun org-realign-tags ()
  (interactive)
  (setq org-tags-column (- 0 (window-width)))
  (org-align-tags t))

;; (:hook window-configuration-change 'org-realign-tags)

(setq org-startup-folded 'content)

(setq org-hide-block-startup nil)

(:hook org-mode 'turn-on-auto-fill)

(setq org-insert-heading-respect-content nil)

(advice-add 'org-link--open-help :override
            (lambda (path) (helpful-symbol (intern path))))

(defun todo-make-state-model (name key props)
  (append (list :name name :key key) props))

(defun todo-parse-state-data (state-data)
  (-let* (((name second &rest) state-data)
          ((key props) (if (stringp second)
                           (list second (cddr state-data))
                         (list nil (cdr state-data)))))
    (todo-make-state-model name key props)))

(defun todo-make-sequence-model (states)
  (mapcar 'todo-parse-state-data states))

(defun todo-parse-sequences-data (sequences-data)
  (mapcar 'todo-make-sequence-model sequences-data))

(defun todo-keyword-name (name key)
  (if key (format "%s(%s)" name key) name))

(defun todo-keyword-name-for-state (state)
  (todo-keyword-name (plist-get state :name)
                     (plist-get state :key)))

(defun todo-is-done-state (state)
  (equal t (plist-get state :done-state)))

(defun todo-is-not-done-state (state)
  (equal nil (plist-get state :done-state)))

(defun todo-org-sequence (states)
  (let ((active (seq-filter 'todo-is-not-done-state states))
        (inactive (seq-filter 'todo-is-done-state states)))
    (append '(sequence)
            (mapcar 'todo-keyword-name-for-state active)
            '("|")
            (mapcar 'todo-keyword-name-for-state inactive))))

(defun todo-org-todo-keywords (sequences)
  (mapcar 'todo-org-sequence (todo-parse-sequences-data sequences)))
;; (todo-org-todo-keywords todo-keywords)

(defun todo-org-todo-keyword-faces (sequences)
  (cl-loop for sequence in (todo-parse-sequences-data sequences)
           append (cl-loop for state in sequence
                           for name = (plist-get state :name)
                           for face = (plist-get state :face)
                           collect (cons name face))))
;; (todo-org-todo-keyword-faces todo-keywords)

(defun todo-prettify-symbols-alist (sequences)
  (cl-loop for sequence in (todo-parse-sequences-data sequences)
           append (cl-loop for state in sequence
                           for name = (plist-get state :name)
                           for icon = (plist-get state :icon)
                           collect (cons name icon))))
;; (todo-prettify-symbols-alist todo-keywords)

(defun todo-finalize-agenda-for-state (state)
  (-let (((&plist :name :icon :face) state))
    (beginning-of-buffer)
    (while (search-forward name nil 1)
      (let* ((line-props (text-properties-at (point)))
             (line-props (org-plist-delete line-props 'face)))
        (call-interactively 'set-mark-command)
        (search-backward name)
        (call-interactively 'kill-region)
        (let ((symbol-pos (point)))
          (insert icon)
          (beginning-of-line)
          (let ((start (point))
                (end (progn (end-of-line) (point))))
            (add-text-properties start end line-props)
            (add-face-text-property symbol-pos (+ 1 symbol-pos) face))))))
  (beginning-of-buffer)
  (replace-regexp "[[:space:]]+[=]+" ""))

(setq todo-keywords
      ;; normal workflow
      '((("DOING" "d" :icon "🏃" :face org-doing-face)
         ("TODO" "t" :icon "□ " :face org-todo-face)
         ("DONE" "D" :icon "✓ " :face org-done-face :done-state t))
        ;; auxillary states
        (("SOON" "s" :icon "❗ " :face org-soon-face)
         ("SOMEDAY" "S" :icon "🛌" :face org-doing-face)))
      org-todo-keywords (todo-org-todo-keywords todo-keywords)
      org-todo-keyword-faces (todo-org-todo-keyword-faces todo-keywords))

(--map (:push episteme/pretty-symbols it)
       (todo-prettify-symbols-alist todo-keywords))

(setq episteme/todo-sequences-data (todo-parse-sequences-data todo-keywords))
(:hook org-agenda-finalize
  (--each episteme/todo-sequences-data
    (-each it 'todo-finalize-agenda-for-state)))

(defun episteme:todo-sort (a b)
  (let* ((a-state (get-text-property 0 'todo-state a))
         (b-state (get-text-property 0 'todo-state b))
         (a-index (-elem-index a-state todo-keyword-order))
         (b-index (-elem-index b-state todo-keyword-order)))
    (pcase (- b-index a-index)
      ((and v (guard (< 0 v))) 1)
      ((and v (guard (> 0 v))) -1)
      (default nil))))

(setq org-agenda-cmp-user-defined 'episteme:todo-sort
      todo-keyword-order '("DOING" "SOON" "TODO" "SOMEDAY" "DONE"))

(use-package ob-csharp
  :straight (ob-csharp :type git
                       :host github
                       :repo "thomas-villagers/ob-csharp"
                       :files ("src/ob-csharp.el"))
  :config
  (:push org-babel-load-languages '(csharp . t)))

(use-package ob-fsharp
  :straight (ob-fsharp :type git
                       :host github
                       :repo "zweifisch/ob-fsharp"
                       :files ("ob-fsharp.el"))
  :config
  (:push org-babel-load-languages '(fsharp . t)))

(setq org-babel-load-languages
      '((shell . t)
        (emacs-lisp . t)
        (python . t)
        (js . t)
        (csharp . t)
        (fsharp . t)))

(:after org
  (setq org-babel-default-header-args
        '((:session . "none")
          (:results . "replace")
          (:exports . "code")
          (:cache . "no")
          (:noweb . "no")
          (:hlines . "no")
          (:tangle . "no"))))

(progn
  (setq org-confirm-babel-evaluate nil)
  (setq org-confirm-elisp-link-function nil)
  (setq org-confirm-shell-link-function nil)
  (setq safe-local-variable-values '((org-confirm-elisp-link-function . nil))))

(:hook after-init
  (org-babel-do-load-languages 'org-babel-load-languages
                               org-babel-load-languages))

(use-package org-fragtog
  :config
  (:hook org-mode 'org-fragtog-mode))

(use-package helm-org)

(use-package helm-org-rifle)

(use-package helm-org-walk
  :straight (helm-org-walk :type git :host github :repo "dustinlacewell/helm-org-walk"))

(use-package org-ql)

(use-package org-ls
  :straight (org-ls :type git :host github :repo "dustinlacewell/org-ls"))

(use-package embrace
  :config
  (embrace-add-pair (kbd "\;") "`" "`"))

(use-package htmlize)

(use-package pretty-hydra
  :demand t
  :straight (pretty-hydra :type git :host github
                          :repo "jerrypnz/major-mode-hydra.el"
                          :files ("pretty-hydra.el")))

(use-package major-mode-hydra
  :straight (major-mode-hydra :type git :host github
                              :repo "jerrypnz/major-mode-hydra.el"
                              :files ("major-mode-hydra.el")))

(use-package hera
  :demand t
  :straight (hera :type git :host github :repo "dustinlacewell/hera"))

(defun :hydra/inject-hint (symbol hint)
  (-let* ((name (symbol-name symbol))
          (hint-symbol (intern (format "%s/hint" name)))
          (format-form (eval hint-symbol))
          (string-cdr (nthcdr 1 format-form))
          (format-string (string-trim (car string-cdr)))
          (amended-string (format "%s\n\n%s" format-string hint)))
    (setcar string-cdr amended-string)))

(defun :hydra/make-head-hint (head default-color)
  (-let (((key _ hint . rest) head))
    (when key
      (-let* (((&plist :color color) rest)
              (color (or color default-color))
              (face (intern (format "hydra-face-%s" color)))
              (propertized-key (propertize key 'face face)))
        (format " [%s]: %s" propertized-key hint)))))

(defun :hydra/make-hint (heads default-color)
  (string-join
   (cl-loop for head in heads
            for hint = (:hydra/make-head-hint head default-color)
            collect hint) "\n"))

(defun :hydra/clear-hint (head)
  (-let* (((key form _ . rest) head))
    `(,key ,form nil ,@rest)))

(defun :hydra/add-exit-head (heads)
  (let ((exit-head '("SPC" (hera-pop) "to exit" :color blue)))
    (append heads `(,exit-head))))

(defun :hydra/add-heads (columns extra-heads)
  (let* ((cell (nthcdr 1 columns))
         (heads (car cell))
         (extra-heads (mapcar ':hydra/clear-hint extra-heads)))
    (setcar cell (append heads extra-heads))))

(defmacro :hydra (name body columns &optional extra-heads)
  (declare (indent defun))
  (-let* (((&plist :color default-color :major-mode mode) body)
          (extra-heads (:hydra/add-exit-head extra-heads))
          (extra-hint (:hydra/make-hint extra-heads default-color))
          (body (plist-put body :hint nil))
          (body-name (format "%s/body" (symbol-name name)))
          (body-symbol (intern body-name))
          (mode-body-name (major-mode-hydra--body-name-for mode))
          (mode-support
           `(when ',mode
              (defun ,mode-body-name () (interactive) (,body-symbol)))))
    (:hydra/add-heads columns extra-heads)
    (when mode
      (cl-remf body :major-mode))
    `(progn
       (pretty-hydra-define ,name ,body ,columns)
       (:hydra/inject-hint ',name ,extra-hint)
       ,mode-support
       )))

;; (macroexpand-all `(:hydra hydra-test (:color red :major-mode fundamental-mode)
;;    ("First"
;;     (("a" (message "first - a") "msg a" :color blue)
;;      ("b" (message "first - b") "msg b"))
;;     "Second"
;;     (("c" (message "second - c") "msg c" :color blue)
;;      ("d" (message "second - d") "msg d")))))

;; (:hydra hydra-test (:color red :major-mode fundamental-mode)
;;    ("First"
;;     (("a" (message "first - a") "msg a" :color blue)
;;      ("b" (message "first - b") "msg b"))
;;     "Second"
;;     (("c" (message "second - c") "msg c" :color blue)
;;      ("d" (message "second - d") "msg d"))))

(:hydra episteme-hydra-help (:color blue)
  ("Describe"
   (("c" describe-function "function")
    ("p" describe-package "package")
    ("m" describe-mode "mode")
    ("v" describe-variable "variable"))
   "Keys"
   (("k" describe-key "key")
    ("K" describe-key-briefly "brief key")
    ("w" where-is "where-is")
    ("b" helm-descbinds "bindings"))
   "Search"
   (("a" helm-apropos "apropos")
    ("d" apropos-documentation "documentation")
    ("s" info-lookup-symbol "symbol info"))
   "Docs"
   (("i" info "info")
    ("n" helm-man-woman "man")
    ("h" helm-dash "dash"))
   "View"
   (("e" view-echo-area-messages "echo area")
    ("l" view-lossage "lossage")
    ("c" describe-coding-system "encoding")
    ("I" describe-input-method "input method")
    ("C" describe-char "char at point"))))

(defun unpop-to-mark-command ()
  "Unpop off mark ring. Does nothing if mark ring is empty."
  (when mark-ring
    (setq mark-ring (cons (copy-marker (mark-marker)) mark-ring))
    (set-marker (mark-marker) (car (last mark-ring)) (current-buffer))
    (when (null (mark t)) (ding))
    (setq mark-ring (nbutlast mark-ring))
    (goto-char (marker-position (car (last mark-ring))))))

(defun push-mark ()
  (interactive)
  (set-mark-command nil)
  (set-mark-command nil))

(:hydra episteme-hydra-mark (:color pink)
  ("Mark"
   (("m" push-mark "mark here")
    ("p" (lambda () (interactive) (set-mark-command '(4))) "previous")
    ("n" (lambda () (interactive) (unpop-to-mark-command)) "next")
    ("c" (lambda () (interactive) (setq mark-ring nil)) "clear"))))

(:hydra episteme-hydra-registers (:color pink)
  ("Point"
   (("r" point-to-register "save point")
    ("j" jump-to-register "jump")
    ("v" view-register "view all"))
   "Text"
   (("c" copy-to-register "copy region")
    ("C" copy-rectangle-to-register "copy rect")
    ("i" insert-register "insert")
    ("p" prepend-to-register "prepend")
    ("a" append-to-register "append"))
   "Macros"
   (("m" kmacro-to-register "store")
    ("e" jump-to-register "execute"))))

(use-package ace-window)
(winner-mode 1)

(:hydra episteme-hydra-window (:color red)
  ("Jump"
   (("h" windmove-left "left")
    ("l" windmove-right "right")
    ("k" windmove-up "up")
    ("j" windmove-down "down")
    ("a" ace-select-window "ace"))
   "Split"
   (("q" split-window-right "left")
    ("r" (progn (split-window-right) (call-interactively 'other-window)) "right")
    ("e" split-window-below "up")
    ("w" (progn (split-window-below) (call-interactively 'other-window)) "down"))
   "Do"
   (("d" delete-window "delete")
    ("o" delete-other-windows "delete others")
    ("u" winner-undo "undo")
    ("R" winner-redo "redo")
    ("t" nougat-hydra-toggle-window "toggle"))))

(:hydra episteme-hydra-zoom (:color red)
  ("Buffer"
   (("i" text-scale-increase "in")
    ("o" text-scale-decrease "out"))
   "Frame"
   (("I" zoom-frm-in "in")
    ("O" zoom-frm-out "out")
    ("r" toggle-zoom-frame "reset" :color blue))))

(:hydra episteme-hydra-default (:color blue)
  ("Open"
   (("o" (helm-org-walk '(4)) "open")
    ("g" (magit-status) "git"))
   "Emacs"
   (("h" (hera-push 'episteme-hydra-help/body) "help")
    ("m" (hera-push 'episteme-hydra-mark/body) "mark")
    ("w" (hera-push 'episteme-hydra-window/body) "windows")
    ("z" (hera-push 'episteme-hydra-zoom/body) "zoom")
    ("r" (hera-push 'episteme-hydra-registers/body) "registers"))
   "Misc"
   ((";" embrace-commander "embrace"))))

(defun episteme:hydra-dwim ()
  (interactive)
  (let* ((mode major-mode)
        (orig-mode mode))
    (catch 'done
      (while mode
        (let ((hydra (major-mode-hydra--body-name-for mode)))
          (when (fboundp hydra)
            (hera-start hydra)
            (throw 'done t)))
        (setq mode (get mode 'derived-mode-parent)))
      (hera-start 'hydra-default/body))))

(:hydra episteme-hydra-elisp (:color blue :major-mode emacs-lisp-mode)
  ("Execute"
   (("d" eval-defun "defun")
    ("b" eval-current-buffer "buffer")
    ("r" eval-region "region"))
   "Debug"
   (("D" edebug-defun "defun")
    ("a" edebug-all-defs "all definitions" :color red)
    ("A" edebug-all-forms "all forms" :color red)
    ("x" macrostep-expand "expand macro"))))

(defun hydra-org-goto-first-sibling () (interactive)
       (org-backward-heading-same-level 99999999))

(defun hydra-org-goto-last-sibling () (interactive)
       (org-forward-heading-same-level 99999999))

(defun hydra-org-parent-level ()
  (interactive)
  (let ((o-point (point)))
    (if (save-excursion
          (beginning-of-line)
          (looking-at org-heading-regexp))
        (progn
          (call-interactively 'outline-up-heading)
          (org-cycle-internal-local))
      (progn
        (call-interactively 'org-previous-visible-heading)
        (org-cycle-internal-local)))
    (when (and (/= o-point (point))
               org-tidy-p)
      (call-interactively 'hydra-org-tidy))))

(defun hydra-org-child-level ()
  (interactive)
  (org-show-entry)
  (org-show-children)
  (when (not (org-goto-first-child))
    (when (save-excursion
            (beginning-of-line)
            (looking-at org-heading-regexp))
      (next-line))))

(:hydra episteme-hydra-org (:color red :major-mode org-mode)
  ("Shift"
   (("K" org-move-subtree-up "up")
    ("J" org-move-subtree-down "down")
    ("h" org-promote-subtree "promote")
    ("l" org-demote-subtree "demote"))
   "Travel"
   (("p" org-backward-heading-same-level "backward")
    ("n" org-forward-heading-same-level "forward")
    ("j" hydra-org-child-level "to child")
    ("k" hydra-org-parent-level "to parent")
    ("a" hydra-org-goto-first-sibling "first sibling")
    ("e" hydra-org-goto-last-sibling "last sibling"))
   "Perform"
   (("t" (org-babel-tangle) "tangle" :color blue)
    ("e" (org-html-export-to-html) "export" :color blue)
    ("b" helm-org-in-buffer-headings "browse")
    ("r" (lambda () (interactive)
           (helm-org-rifle-current-buffer)
           (org-cycle)
           (org-cycle)) "rifle")
    ("w" helm-org-walk "walk")
    ("v" avy-org-goto-heading-timer "avy")
    ("L" org-toggle-link-display "toggle links"))))
