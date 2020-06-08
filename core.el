;;; core.el -*- lexical-binding: t; -*-

(setq package-quickstart t)

(defconst *emacs27*
  (> emacs-major-version 26))
(defconst *emacs28*
  (> emacs-major-version 27))
(defconst *is-mac*
  (eq system-type 'darwin))
(defconst *is-linux*
  (eq system-type 'gnu/linux))
(defconst *is-windows*
  (memq system-type '(cygwin windows-nt ms-dos)))
(defconst *is-gui*
    (display-graphic-p))

;; Unix tools look for HOME, but this is normally not defined on Windows.
(when (and *is-windows* (null (getenv "HOME")))
  (setenv "HOME" (getenv "USERPROFILE")))

(defvar emacs--initial-load-path load-path)
(defvar emacs--initial-process-environment process-environment)
(defvar emacs--initial-exec-path exec-path)

(defconst *emacs-dir*
  (eval-when-compile (file-truename user-emacs-directory))
  "Path to the currently loaded .emacs.d directory.")

(defconst *local-dir* (concat *emacs-dir* "local/")
  "Directory for non-volatile local storage.
Use this for files that don't change much, like server binaries, external
dependencies or long-term shared data. Must end with a slash.")

(defconst *var-dir* (concat *emacs-dir* "var/")
  "Directory for volatile local storage.
Use this for files that change often, like cache files. Must end with a slash.")

(defconst *vendor-dir* (concat *emacs-dir* "vendor/")
  "Directory for third-party emacs-lisp packages.")

(unless noninteractive
  (defvar emacs--initial-file-name-handler-alist file-name-handler-alist)

  (setq file-name-handler-alist nil)
  ;; Restore `file-name-handler-alist', because it is needed for handling
  ;; encrypted or compressed files, among other things.
  (defun emacs-reset-file-handler-alist-h ()
    ;; Re-add rather than `setq', because file-name-handler-alist may have
    ;; changed since startup, and we want to preserve those.
    (dolist (handler file-name-handler-alist)
      (add-to-list 'emacs--initial-file-name-handler-alist handler))
    (setq file-name-handler-alist emacs--initial-file-name-handler-alist))
  (add-hook 'emacs-startup-hook #'emacs-reset-file-handler-alist-h))

(add-hook
  'emacs-startup-hook
   (defun emacs-display-startup-time ()
     (message "Emacs ready in %s with %d garbage collections."
      (format "%.2f seconds"
        (float-time
          (time-subtract after-init-time before-init-time)))
      gcs-done)))

(add-hook
  'kill-emacs-hook
   (defun run-package-quickstart-refresh ()
     (package-quickstart-refresh)))

(when *is-mac*
  (setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program "open"
      dnd-open-file-other-window t)

  (if *emacs27*
      (set-fontset-font
       t 'symbol (font-spec :family "Apple Color Emoji") nil 'prepend)
      (set-fontset-font
       "fontset-default" 'unicode "Apple Color Emoji" nil 'prepend)
      )

  (setq ns-alternate-modifier 'super
        ns-command-modifier 'meta)
  )

(setq debug-on-error nil
      jka-compr-verbose nil)
(when (fboundp 'set-charset-priority)
  (set-charset-priority 'unicode))
(prefer-coding-system 'utf-8)
(setq locale-coding-system 'utf-8)

(setq ad-redefinition-action 'accept)
(setq apropos-do-all t)
(setq auto-mode-case-fold nil)
(setq inhibit-startup-message t
      inhibit-startup-echo-area-message user-login-name
      inhibit-default-init t
      ;; Avoid pulling in many packages by starting the scratch buffer in
      ;; `fundamental-mode', rather than, say, `org-mode' or `text-mode'.
      initial-major-mode 'fundamental-mode
      initial-scratch-message nil)

(setq make-backup-files nil)

(unless (daemonp)
  (advice-add #'display-startup-echo-area-message :override #'ignore))

(setq idle-update-delay 1.0)

(setq gnutls-verify-error (not (getenv "INSECURE"))
      gnutls-algorithm-priority
      (when (boundp 'libgnutls-version)
        (concat "SECURE128:+SECURE192:-VERS-ALL"
                (if (and (not (version< emacs-version "26.3"))
                         (>= libgnutls-version 30605))
                    ":+VERS-TLS1.3")
                ":+VERS-TLS1.2"))
      ;; `gnutls-min-prime-bits' is set based on recommendations from
      ;; https://www.keylength.com/en/4/
      gnutls-min-prime-bits 3072
      tls-checktrust gnutls-verify-error
      ;; Emacs is built with `gnutls' by default, so `tls-program' would not be
      ;; used in that case. Otherwise, people have reasons to not go with
      ;; `gnutls', we use `openssl' instead. For more details, see
      ;; https://redd.it/8sykl1
      tls-program '("openssl s_client -connect %h:%p -CAfile %t -nbio -no_ssl3 -no_tls1 -no_tls1_1 -ign_eof"
                    "gnutls-cli -p %p --dh-bits=3072 --ocsp --x509cafile=%t \
--strict-tofu --priority='SECURE192:+SECURE128:-VERS-ALL:+VERS-TLS1.2:+VERS-TLS1.3' %h"
                    ;; compatibility fallbacks
                    "gnutls-cli -p %p %h"))

(setq auth-sources (list (concat *local-dir* "authinfo.gpg")
                         "~/.authinfo.gpg"))

(setq abbrev-file-name             (concat *local-dir* "abbrev.el")
      async-byte-compile-log-file  (concat *var-dir* "async-bytecomp.log")
      bookmark-default-file        (concat *local-dir* "bookmarks")
      custom-file                  (concat *local-dir* "custom.el")
      custom-theme-directory       (concat *local-dir* "themes/")
      desktop-dirname              (concat *local-dir* "desktop")
      desktop-base-file-name       "autosave"
      desktop-base-lock-name       "autosave-lock"
      pcache-directory             (concat *var-dir* "pcache/")
      request-storage-directory    (concat *var-dir* "request")
      server-auth-dir              (concat *var-dir* "server/")
      shared-game-score-directory  (concat *local-dir* "shared-game-score/")
      tramp-auto-save-directory    (concat *var-dir* "tramp-auto-save/")
      tramp-backup-directory-alist backup-directory-alist
      tramp-persistency-file-name  (concat *var-dir* "tramp-persistency.el")
      url-cache-directory          (concat *var-dir* "url/")
      url-configuration-directory  (concat *var-dir* "url/")
      gamegrid-user-score-file-directory (concat *local-dir* "games/"))

(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)

(setq-default cursor-in-non-selected-windows nil)
(setq highlight-nonselected-windows nil)

(setq fast-but-imprecise-scrolling t)

(setq frame-inhibit-implied-resize t)

(setq ffap-machine-p-known 'reject)

(setq inhibit-compacting-font-caches t)

(unless *is-mac*   (setq command-line-ns-option-alist nil))
(unless *is-linux* (setq command-line-x-option-alist nil))

(setq delete-by-moving-to-trash *is-mac*)

(setq gcmh-idle-delay 5
      gcmh-high-cons-threshold (* 16 1024 1024)  ; 16mb
      gcmh-verbose nil)

(setq package-archives
      '(("melpa" .        "https://melpa.org/packages/")
        ("melpa-stable" . "https://stable.melpa.org/packages/")
        ("gnu" .          "https://elpa.gnu.org/packages/")
        ("org" .          "https://orgmode.org/elpa/")))

(require 'package)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

(dolist (r `((?i . (file . ,(expand-file-name "init.el" user-emacs-directory)))
             (?c . (file . ,(expand-file-name "core.el" user-emacs-directory)))
            ))
  (set-register (car r) (cdr r)))

(setq ring-bell-function 'ignore)

(fset 'yes-or-no-p 'y-or-n-p)

(setq-default indent-tabs-mode nil
              tab-width 2)

(defun other-window-backwards ()
    (interactive)
    (other-window -1))

(when *is-gui*

  (scroll-bar-mode -1)
  (blink-cursor-mode -1)
  (global-visual-line-mode +1)
  (delete-selection-mode +1)
  (unless *is-mac* (menu-bar-mode -1))
  (tool-bar-mode -1)
  (transient-mark-mode -1)
  (column-number-mode +1)
  (electric-pair-mode +1)

  (use-package bind-key
    :ensure t
    :config
    (add-to-list 'same-window-buffer-names "*Personal Keybindings*"))

  (unbind-key "C-z")
  (unbind-key "s-p")

  (setq dired-use-ls-dired nil
        custom-safe-themes t)

  (dolist (cmd '(narrow-to-region
                 narrow-to-page
                 narrow-to-defun
                 upcase-region
                 downcase-region
                 erase-buffer
                 eval-expression
                 dired-find-alternate-file
                 set-goal-column))
    (put cmd 'disabled nil))

  (bind-keys*
   ("M-%" . query-replace-regexp)
   ("M-z" . just-one-space)
   ("C-;" . comment-line)
   ("C-M-;" . comment-or-uncomment-region)
   ("M-M" . man)
   ("C-M-k" . kill-sexp)
   ("C-<tab>" . mode-line-other-buffer)
   ("C-c q" . delete-other-windows)
   ("C-x r j" . jump-to-register)
   ("M-o" . other-window)
   ("M-O" . other-window-backwards)
   )

  (use-package fringe
    :config
    (fringe-mode)
    (toggle-indicate-empty-lines))

  (use-package isearch
    :defines (isearch-mode-map)
    :bind (:map isearch-mode-map
                ("C-<return>" . isearch-done-opposite)
                ("M-i" . helm-swoop-from-isearch)
                )
    :init (defun isearch-done-opposite (&optional nopush edit)
            "End current search in the opposite side of the match."
            (interactive)
            (funcall #'isearch-done nopush edit)
            (when isearch-other-end (goto-char isearch-other-end))))

  (use-package whitespace
    :bind (("C-x S" . whitespace-cleanup-save-buffer))
    :init (defun whitespace-cleanup-save-buffer ()
            (interactive)
            (whitespace-cleanup)
            (save-buffer))
    :hook (prog-mode . whitespace-mode)
    :config
    (setq-default whitespace-style '(face trailing tab-mark)))

  (use-package saveplace
    :hook (after-init . save-place-mode)
    :init
    (setq save-place-file (concat *var-dir* "places")))

  (use-package recentf
    :hook (after-init . recentf-mode)
    :init
    (setq recentf-save-file (concat *var-dir* "recentf")))

  (use-package remember-last-theme
    :ensure t
    :config (remember-last-theme-with-file-enable
             (concat *var-dir* "last-theme.el")))

  (use-package discover
    :ensure t
    :config (global-discover-mode))

  (use-package ediff
    :config
    (defvar ctl-period-equals-map)
    (define-prefix-command 'ctl-period-equals-map)
    (bind-key "C-. =" #'ctl-period-equals-map)

    (setq ediff-diff-options "-w")

    :bind (("C-. = b" . ediff-buffers)
           ("C-. = B" . ediff-buffers3)
           ("C-. = c" . compare-windows)
           ("C-. = =" . ediff-files)
           ("C-. = f" . ediff-files)
           ("C-. = F" . ediff-files3)
           ("C-. = r" . ediff-revision)
           ("C-. = p" . ediff-patch-file)
           ("C-. = P" . ediff-patch-buffer)
           ("C-. = l" . ediff-regions-linewise)
           ("C-. = w" . ediff-regions-wordwise)))

  (use-package magit
    :ensure t
    :hook (magit-mode . hl-line-mode)
    :config
    (when (functionp 'ivy-completing-read)
      (setq magit-completing-read-function 'ivy-completing-read)))

  (use-package fullframe
    :ensure t
    :defer 3
    :config
    (fullframe magit-status magit-mode-quit-window nil)
    (fullframe projectile-vc magit-mode-quit-window nil))

  (use-package dumb-jump
    :ensure t
    :hook (prog-mode . dumb-jump-mode)
    :bind (("M-g o" . dumb-jump-go-other-window)
           ("M-g j" . dumb-jump-go)
           ("M-g b" . dumb-jump-back)
           ("M-g i" . dumb-jump-go-prompt)
           ("M-g x" . dumb-jump-go-prefer-external)
           ("M-g z" . dumb-jump-go-prefer-external-other-window))
    :config (setq dumb-jump-selector 'helm))

  (use-package exec-path-from-shell
    :ensure t
    :defer 3
    :config
    (setq exec-path-from-shell-check-startup-files nil
          exec-path-from-shell-variables '("PATH" "ZSH" "MANPATH"
                                           "SSH_AUTH_SOCK"
                                           "SSH_AGENT_PID"
                                           "GPG_AGENT_INFO"
                                           "RUST_SRC_PATH"
                                           "GNOME_KEYRING_CONTROL"
                                           "GNOME_KEYRING_PID"))
    (exec-path-from-shell-initialize))

  (use-package vterm :ensure t :defer t)
  (use-package vterm-toggle :ensure t :bind ("C-M-." . vterm-toggle))
  (use-package eterm-256color :ensure t :hook (vterm-mode . eterm-256color-mode))

  (use-package discover-my-major
    :ensure t
    :bind (("C-h M-m" . discover-my-major)
           ("C-h M-S-m" . discover-my-mode)))

  (use-package avy
    :ensure t
    :bind (("M-g M-g" . avy-goto-line)
           ("M-g w" . avy-goto-word-1)
           ("M-g e" . avy-goto-word-0)
           ("C-'" . avy-goto-char)
           ("C-M-'" . avy-goto-char-2)))

  (use-package switch-window
    :ensure t
    :bind (("M-i" . switch-window))
    :config (setq switch-window-shortcut-style 'qwerty))

  (use-package untitled-new-buffer
    :ensure t
    :bind (("M-N" . untitled-new-buffer-with-select-major-mode)))

  (use-package projectile
    :ensure t
    :hook (after-init . projectile-mode)
    :bind-keymap ("C-c p" . projectile-command-map)
    :init (setq projectile-known-projects-file (concat *local-dir* "projectile-bookmarks.eld")
                projectile-cache-file (concat *var-dir* "projectile.cache")))

  (use-package expand-region
    :ensure t
    :bind ("C-@" . er/expand-region))

  (use-package hungry-delete
    :ensure t
    :defer t)

  (use-package hl-todo
    :ensure t
    :hook (prog-mode . hl-todo-mode)
    :bind (("C-c t n" . hl-todo-next)
           ("C-c t p" . hl-todo-previous)
           ("C-c t o" . hl-todo-occur)))

  (use-package zygospore
    :ensure t
    :bind (("C-x 1" . zygospore-toggle-delete-other-windows)))

  (use-package aggressive-indent
    :ensure t
    :defer t
    :init (setq aggressive-indent-sit-for-time 0.5))

  (use-package neotree
    :ensure t
    :bind (("<f7>" . neotree-toggle))
    :hook (neo-after-create . my/neotree-setup)
    :init
    (defun my/neotree-setup (_)
      (with-current-buffer neo-buffer-name
        (toggle-truncate-lines)
        (toggle-word-wrap)))
    :config
    (setq neo-theme (if *is-gui* 'icons 'arrow)
          neo-window-fixed-size t
          neo-window-width 35
          neo-smart-open t))

  (use-package multiple-cursors
    :ensure t
    :bind (("C->" . mc/mark-next-like-this)
           ("C-<" . mc/mark-previous-like-this)
           ("C-M->" . mc/skip-to-next-like-this)
           ("C-M-<" . mc/skip-to-previous-like-this)
           ("C-S-c C-S-c" . mc/edit-lines)
           ("C-M-0" . mc/mark-all-like-this)
           ("M-<down-mouse-1>" . mc/add-cursor-on-click))
    :init (setq mc/list-file (concat *local-dir* "mc-lists.el")))

  (use-package company
    :ensure t
    :hook (after-init . company-mode))

  (use-package which-key
    :ensure t
    :hook (after-init . which-key-mode))

  (use-package paredit :ensure t :defer t)
  (use-package prettier-js :ensure t :defer t)

  (use-package restclient :ensure t :mode ("\\.http\\'" . restclient-mode))
  (use-package toml-mode :ensure t :mode "\\.toml\\'")
  (use-package yaml-mode :ensure t :mode "\\.ya?ml\\'")
  (use-package dockerfile-mode :ensure t :mode "Dockerfile\\'")
  (use-package groovy-mode :ensure t :mode (("Jenkinsfile\\'" . groovy-mode)))
  (use-package json-mode :ensure t
    :mode "\\.json\\'"
    :config (setq-default json-reformat:indent-width 2
                          js-indent-level 2))
  (use-package markdown-mode :ensure t
    :mode (("\\.md" . gfm-mode)
           ("\\.markdown" . gfm-mode)))

  (use-package wgrep :ensure t :defer t)
  (use-package wgrep-ag :ensure t :defer t)

  (use-package gitignore-mode :ensure t :mode ".gitignore\\'")
  (use-package git-messenger
    :ensure t
    :bind ("C-x g p" . git-messenger:popup-message)
    :config (setq git-messenger:use-magit-popup t))
  (use-package git-timemachine :ensure t :bind ("C-x g t" . git-timemachine-toggle))
  (use-package what-the-commit :ensure t :bind ("C-x g c" . what-the-commit-insert))
  (use-package browse-at-remote
    :ensure t
    :bind (("C-c g g" . browse-at-remote)))

  (use-package helm
    :ensure t
    :bind (("M-x" . helm-M-x)
           ("C-h SPC" . helm-all-mark-rings)
           ("M-Y" . helm-show-kill-ring)
           ("C-x b" . helm-mini)
           ("C-x C-b" . helm-buffers-list)
           ("C-M-l" . helm-buffers-list)
           ("C-x C-S-b" . ibuffer)
           ("C-x C-f" . helm-find-files)
           ("C-x C-r" . helm-recentf)

           ("C-x c !" . helm-calcul-expression)
           ("M-:" . helm-eval-expression-with-eldoc)

           ("C-h a" . helm-apropos)
           ("C-h i" . helm-info-emacs)
           ("C-h C-l" . helm-locate-library)
           ("C-c h i" . helm-semantic-or-imenu)
           )
    :config
    (setq helm-command-prefix-key "C-c h"
          helm-split-window-inside-p t
          helm-buffers-fuzzy-matching t
          helm-buffer-max-length nil
          helm-recentf-fuzzy-match t
          helm-apropos-fuzzy-match t
          helm-move-to-line-cycle-in-source t
          helm-ff-search-library-in-sexp t
          helm-ff-file-name-history-use-recentf t
          helm-ff-auto-update-initial-value t
          helm-full-frame nil)
    (helm-mode))

  (use-package helm-descbinds
    :ensure t
    :bind (("C-h b" . helm-descbinds)))

  (use-package helm-ag :ensure t :defer t)
  (use-package helm-rg :ensure t :defer t)
  (use-package helm-tramp :ensure t :defer t)
  (use-package helm-themes :ensure t :bind ("C-c h t" . helm-themes))

  (use-package helm-swoop
    :ensure t
    :bind (("M-i" . helm-swoop)
           ("M-I" . helm-multi-swoop)))

  (use-package helm-projectile
    :ensure t
    :bind* (("C-c p D" . projectile-dired)
            ("C-c p v" . projectile-vc)
            ("C-c p k" . projectile-kill-buffers)

            ("C-c p p" . helm-projectile-switch-project)
            ("C-c p f" . helm-projectile-find-file)
            ("C-c p F" . helm-projectile-find-file-in-known-projects)
            ("C-c p g" . helm-projectile-find-file-dwin)
            ("C-c p d" . helm-projectile-find-dir)
            ("C-c p C-r" . helm-projectile-recentf)
            ("C-c p b" . helm-projectile-switch-to-buffer)
            ("C-c p s s" . helm-projectile-ag)
            ("C-c p s g" . helm-projectile-grep)
            )
    :init
    (setq
     ;; projectile-keymap-prefix (kbd "C-c p")
          projectile-enable-caching t
          projectile-indexing-method 'alien
          projectile-completion-system 'helm
          projectile-mode-line '(:eval (format " {%s}" (projectile-project-name))))

    :config
    (helm-projectile-on))


  (use-package merlin
    :ensure t
    :bind (:map merlin-mode-map
                ("M-." . merlin-locate)
                ("M-," . merlin-pop-stack)
                ("M-?" . merlin-occurrences)
                ;; ("M-m" . merlin-error-next)
                ;; ("M-n" . merlin-error-prev)
                ("C-c C-o" . merlin-occurrences)
                ("C-c C-j" . merlin-jump)
                ("C-c i" . merlin-locate-ident)
                ("C-c C-e" . merlin-iedit-occurrences)))

  (use-package merlin-eldoc
    :after merlin
    :ensure t
    :custom
    (eldoc-echo-area-use-multiline-p t) ; use multiple lines when necessary
    (merlin-eldoc-max-lines 8)          ; but not more than 8
    (merlin-eldoc-type-verbosity 'min)  ; don't display verbose types
    :bind (:map merlin-mode-map
                ("C-c m p" . merlin-eldoc-jump-to-prev-occurrence)
                ("C-c m n" . merlin-eldoc-jump-to-next-occurrence)))

  (use-package flycheck-ocaml
    :ensure t
    :after merlin)

  (use-package company-lsp
    :ensure t
    :after company
    :config (push 'company-lsp company-backends))

  (use-package lsp-ui :ensure t :defer t)

  (use-package lsp-mode
    :ensure t
    :config
    (lsp-register-client
     (make-lsp-client
      :new-connection
      ;; dependency: reason-language-server needs to be in your path
      ;; https://github.com/jaredly/reason-language-server/
      (lsp-stdio-connection (lambda () "reason-language-server"))
      :major-modes '(reason-mode)
      :priority 0
      :server-id 'reasoml-lsp-server)))

  (use-package reason-mode
    :ensure t
    :mode "\\.rei?\\'"
    :hook (reason-mode . reason-mode-setup)
    :init
    (defun reason-mode-setup ()
      (interactive)
      (lsp)
      (lsp-ui-mode +1)
      (company-mode +1)
      (subword-mode +1)
      (hungry-delete-mode +1)
      (utop-minor-mode +1)
      (add-hook 'before-save-hook 'refmt-before-save nil t)
      ))

  (use-package tuareg
    :ensure t
    :hook (tuareg-mode . ocaml-mode-setup)
    :init
    (defun ocaml-mode-setup ()
      (interactive)
      (ocp-setup-indent)
      (setq merlin-command 'opam
            mode-name "🐫")
      (merlin-mode +1)
      (merlin-eldoc-setup)
      (merlin-use-merlin-imenu)
      (company-mode +1)
      (hungry-delete-mode +1)
      (utop-minor-mode +1)))

  (use-package typescript-mode
    :ensure t
    :mode "\\.ts\\'"
    :config (setq typescript-indent-level 2))

  (use-package tide
    :ensure t
    :pin melpa-stable
    :bind (:map tide-mode-map
                ("<f8>" . tide-references)
                ("<f9>" . tide-find-previous-reference)
                ("<f10>" . tide-find-next-reference))
    :hook (typescript-mode . tide-setup-typescript)
    :init (defun tide-setup-typescript ()
            (interactive)
            (tide-setup)
            (flycheck-mode +1)
            (company-mode +1)
            (eldoc-mode +1)
            (prettier-js-mode +1)
            (subword-mode +1)
            (hungry-delete-mode +1)
            )
    )

  (use-package web-mode
    :ensure t
    :mode (("\\.tsx\\'" . web-mode))
    :hook (web-mode . web-mode-typescript)
    :init (defun web-mode-typescript ()
            (when (string-equal "tsx" (file-name-extension buffer-file-name))
              (tide-setup)
              (flycheck-mode)
              (eldoc-mode)
              (prettier-js-mode)
              (subword-mode)
              (hungry-delete-mode)
              ;; (add-hook 'before-save-hook 'tide-format-before-save)
              ))
    :config (setq web-mode-markup-indent-offset 2
                  web-mode-css-indent-offset 2
                  web-mode-code-indent-offset 2
                  web-mode-block-padding 2
                  web-mode-comment-style 2

                  web-mode-enable-css-colorization t
                  web-mode-enable-auto-pairing t
                  web-mode-enable-comment-keywords t
                  web-mode-enable-current-element-highlight nil))

  (use-package fancy-narrow :ensure t :defer t)

  (use-package minions :ensure t :hook ((prog-mode . minions-mode)))

  

  (add-to-list
   'custom-theme-load-path
   *vendor-dir*)

  (use-package default-black-theme :defer t)

  (use-package ir-black-theme :ensure t :defer t)
  (use-package minsk-theme :ensure t :defer t)
  (use-package eclipse-theme :ensure t :defer t)
  (use-package minimal-theme :ensure t :defer t)
  (use-package chocolate-theme :ensure t :defer t)
  (use-package naysayer-theme :ensure t :defer t)
  (use-package overcast-theme :ensure t :defer t)
  (use-package github-modern-theme :ensure t :defer t)
  (use-package doom-themes :ensure t :defer t)
  (use-package silkworm-theme :ensure t :defer t)
  (use-package oldlace-theme :ensure t :defer t)
  (use-package spacemacs-theme :ensure t :defer t)
  (use-package rebecca-theme :ensure t :defer t)
  (use-package monotropic-theme :ensure t :defer t)
  (use-package white-theme :ensure t :defer t)

  )

(use-package evil
  :ensure t
  :hook (after-init . my/setup-evil)
  :init
  (defun my/setup-evil ()
    (interactive)
    (evil-set-leader 'normal (kbd "<SPC>"))

    ;; general
    (evil-define-key 'normal 'global (kbd "<leader>;") 'comment-line)
    (evil-define-key 'normal 'global (kbd "<leader>SPC") 'helm-M-x)

    ;; files
    (evil-define-key 'normal 'global (kbd "<leader>ft") 'neotree-toggle)
    (evil-define-key 'normal 'global (kbd "<leader>fy") 'gn-copy-file-name)
    (evil-define-key 'normal 'global (kbd "<leader>fR") 'gn-rename-file-and-buffer)
    (evil-define-key 'normal 'global (kbd "<leader>fs") 'save-buffer)
    (evil-define-key 'normal 'global (kbd "<leader>fS") 'whitespace-cleanup-save-buffer)
    (evil-define-key 'normal 'global (kbd "<leader>ff") 'helm-find-files)
    (evil-define-key 'normal 'global (kbd "<leader>fn") 'untitled-new-buffer-with-select-major-mode)
    (evil-define-key 'normal 'global (kbd "<leader>fD") 'gn-delete-file-and-buffer)
    (evil-define-key 'normal 'global (kbd "<leader>fj") 'dired-x-find-file)

    ;; buffers
    (evil-define-key 'normal 'global (kbd "<leader>bb") 'helm-buffers-list)
    (evil-define-key 'normal 'global (kbd "<leader>TAB") 'mode-line-other-buffer)
    (evil-define-key 'normal 'global (kbd "<leader>bn") 'next-buffer)
    (evil-define-key 'normal 'global (kbd "<leader>bp") 'previous-buffer)
    (evil-define-key 'normal 'global (kbd "<leader>bk") 'kill-buffer)
    (evil-define-key 'normal 'global (kbd "<leader>bK") 'gn-kill-all-buffers-but-current-one)
    (evil-define-key 'normal 'global (kbd "<leader>bd") 'kill-current-buffer)

    ;; help
    (evil-define-key 'normal 'global (kbd "<leader>hm") 'discover-my-mode)
    (evil-define-key 'normal 'global (kbd "<leader>hM") 'discover-my-major)
    (evil-define-key 'normal 'global (kbd "<leader>hf") 'describe-function)
    (evil-define-key 'normal 'global (kbd "<leader>hv") 'describe-variable)
    (evil-define-key 'normal 'global (kbd "<leader>hl") 'find-library)
    (evil-define-key 'normal 'global (kbd "<leader>hb") 'helm-descbinds)

    ;; regions
    (evil-define-key 'normal 'global (kbd "<leader>@") 'er/expand-region)
    (evil-define-key 'normal 'global (kbd "<leader>z") 'just-one-space)

    ;; windows
    (evil-define-key 'normal 'global (kbd "gh") 'evil-window-left)
    (evil-define-key 'normal 'global (kbd "gl") 'evil-window-right)
    (evil-define-key 'normal 'global (kbd "gj") 'evil-window-bottom)
    (evil-define-key 'normal 'global (kbd "gk") 'evil-window-top)

    (evil-define-key 'normal 'global (kbd "<leader>ww") 'ace-window)
    (evil-define-key 'normal 'global (kbd "<leader>wo") 'other-window)
    (evil-define-key 'normal 'global (kbd "<leader>wd") 'delete-window)
    (evil-define-key 'normal 'global (kbd "<leader>wD") 'ace-delete-other-windows)
    (evil-define-key 'normal 'global (kbd "<leader>w-") 'split-window-below)
    (evil-define-key 'normal 'global (kbd "<leader>w/") 'split-window-right)

    (evil-define-key 'normal 'global (kbd "<leader>w1") 'zygospore-toggle-delete-other-windows)

    ;; projects
    (evil-define-key 'normal 'global (kbd "<leader>p<SPC>") 'helm-projectile)
    (evil-define-key 'normal 'global (kbd "<leader>pp") 'helm-projectile-switch-project)
    (evil-define-key 'normal 'global (kbd "<leader>p!") 'projectile-run-shell-command-in-root)
    (evil-define-key 'normal 'global (kbd "<leader>p&") 'projectile-run-async-shell-command-in-root)
    (evil-define-key 'normal 'global (kbd "<leader>pb") 'helm-projectile-switch-to-buffer)
    (evil-define-key 'normal 'global (kbd "<leader>pB") 'helm-switch-to-buffer-other-window)
    (evil-define-key 'normal 'global (kbd "<leader>pd") 'helm-projectile-find-dir)
    (evil-define-key 'normal 'global (kbd "<leader>pf") 'helm-projectile-find-file)
    (evil-define-key 'normal 'global (kbd "<leader>pI") 'projectile-invalidate-cache)
    (evil-define-key 'normal 'global (kbd "<leader>pv") 'magit-status)
    (evil-define-key 'normal 'global (kbd "<leader>psg") 'helm-projectile-grep)
    (evil-define-key 'normal 'global (kbd "<leader>psr") 'helm-projectile-rg)
    (evil-define-key 'normal 'global (kbd "<leader>pss") 'helm-projectile-ag)
    (evil-define-key 'normal 'global (kbd "<leader>psi") 'helm-projectile-git-grep)
    (evil-define-key 'normal 'global (kbd "<leader>po") 'projectile-multi-occur)
    (evil-define-key 'normal 'global (kbd "<leader>pr") 'projectile-recentf)
    (evil-define-key 'normal 'global (kbd "<leader>pT") 'projectile-find-test-file)
    (evil-define-key 'normal 'global (kbd "<leader>pR") 'projectile-replace-regexp)
    (evil-define-key 'normal 'global (kbd "<leader>pk") 'projectile-kill-buffers)

    (evil-mode)))

(provide 'core)
