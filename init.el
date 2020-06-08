;;; init.el -*- lexical-binding: t; -*-

(setq gc-cons-threshold most-positive-fixnum)
(setq load-prefer-newer noninteractive)

(let
    (file-name-handler-alist)
    (setq user-emacs-directory
        (file-name-directory load-file-name)))

(load
    (concat user-emacs-directory "core")
    nil'nomessage)

;; ## added by OPAM user-setup for emacs / base ## 56ab50dc8996d2bb95e7856a6eddb17b ## you can edit, but keep this line
(require 'opam-user-setup "~/.emacs.d/opam-user-setup.el")
;; ## end of OPAM user-setup addition for emacs / base ## keep this line

(set-face-attribute 'default nil :font "Fira Code" :height 160)
