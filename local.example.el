;;; local.example.el --- Example private local Emacs settings -*- lexical-binding: t; -*-

;; Copy this file to local.el and edit the values for your machine.
;; local.el is ignored by Git.

(setq user-mail-address "you@example.com"
      user-full-name "Your Name")

;; Optional: used by aidermacs/aider when selecting a DeepSeek model.
(setenv "DEEPSEEK_API_KEY" "your-api-key")
