;;; init.el --- Arch Emacs 配置  -*- lexical-binding: t; -*-
;; Author: alex
;; Time: 2025-10-22

;; ------------------------------
;; 🔧 基础设置与 UI 精简
;; ------------------------------
;; 禁用启动画面
(setq inhibit-splash-screen t)
(setq inhibit-startup-message t)
(setq initial-scratch-message nil)
(setq ring-bell-function 'ignore) ; 关闭提示音

;; 关闭无关 UI 元素
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

;; 关闭 lsp-mode 对 emacs-lisp-mode 的警告
(setq lsp-warn-no-matched-clients nil)

;; 关闭 checkdoc 提示（比如缺 lexical-binding、commentary）
(setq checkdoc-force-docstrings-flag nil)
(setq checkdoc-arguments-in-order-flag nil)
(setq checkdoc-verb-check-experimental-flag nil)

;; 如果你用了 flycheck/flymake 带 package-lint，也可以关掉
;;(with-eval-after-load 'flycheck
;;  (flycheck-disable-checker 'emacs-lisp-checkdoc))

;; 关闭 minibuffer 鼠标点击警告
(setq minibuffer-prompt-properties
      '(read-only t cursor-intangible t face minibuffer-prompt))

;; 显示行号（相对行号）
(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative)

;; 自动换行
(setq-default truncate-lines nil)
(add-hook 'org-mode-hook 'visual-line-mode)

;; 基本编辑设置
(setq-default tab-width 4)
(setq-default indent-tabs-mode nil)

(setq-default python-indent-offset 4)

(setq python-indent-guess-indent-offset nil)
(setq backup-directory-alist `(("." . ,(expand-file-name "var/backups/" user-emacs-directory))))
(setq auto-save-file-name-transforms `((".*" ,(expand-file-name "var/auto-save/" user-emacs-directory) t)))
(setq auto-save-list-file-prefix (expand-file-name "var/auto-save/sessions/" user-emacs-directory))
(setq create-lockfiles nil)
(make-directory (expand-file-name "var/backups/" user-emacs-directory) t)
(make-directory (expand-file-name "var/auto-save/" user-emacs-directory) t)
(make-directory (expand-file-name "var/auto-save/sessions/" user-emacs-directory) t)

;; ------------------------------
;; 🖋 字体设置（仅图形界面）
;; ------------------------------

(when (display-graphic-p)
  (set-face-attribute 'default nil
                      :font "MesloLGM Nerd Font Mono"
                      :height 140
                      :weight 'normal)
  ;; 中文字体
  (set-fontset-font t 'han (font-spec :name "Sarasa Term SC Nerd" :size 18)))

;; ------------------------------
;; 📦 包管理器与 use-package
;; ------------------------------

(require 'package)
(setq package-archives '(("melpa" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")
                         ("gnu"   . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
                         ("org"   . "https://mirrors.tuna.tsinghua.edu.cn/elpa/org/")))
(package-initialize)

;; Bootstrap use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t) ; 自动安装未安装的包

;; ------------------------------
;; 📁 文件类型关联与高亮
;; ------------------------------

;; 基础配置文件
(add-to-list 'auto-mode-alist '("\\.\\(conf\\|cfg\\|ini\\|properties\\)\\'" . conf-mode))
;; Shell 配置
(add-to-list 'auto-mode-alist '("\\.\\(bashrc\\|zshrc\\|kshrc\\|profile\\|xinitrc\\|xsession\\)\\'" . sh-mode))
(use-package git-modes
  :mode (("\\.gitconfig\\'" . gitconfig-mode)
         ("\\.gitignore\\'" . gitignore-mode)
         ("\\.gitattributes\\'" . gitattributes-mode)))
;; 特定配置文件
(dolist (pair '(("tint2rc\\'" . conf-mode)
                ("\\.cwmrc\\'" . conf-mode)
                ("i3/config" . conf-mode)
                ("bspwmrc" . conf-mode)
                ("sxhkdrc" . sh-mode)))
  (add-to-list 'auto-mode-alist pair))

;; 常用编程语言优先使用 Emacs 30 内置 tree-sitter major mode
(dolist (pair '(("\\.rs\\'" . rust-ts-mode)
                ("\\.go\\'" . go-ts-mode)
                ("\\.ts\\'" . typescript-ts-mode)
                ("\\.tsx\\'" . tsx-ts-mode)
                ("\\.lua\\'" . lua-ts-mode)
                ("\\.ya?ml\\'" . yaml-ts-mode)
                ("Dockerfile\\'" . dockerfile-ts-mode)))
  (add-to-list 'auto-mode-alist pair))

;; 增强 conf-mode 高亮
(add-hook 'conf-mode-hook
          (lambda ()
            (font-lock-add-keywords nil
             '(("^\\[.*\\]$" . font-lock-keyword-face)
               ("^\\(.*\\)\\s-*=\\s-*\\(.*\\)$"
                (1 font-lock-variable-name-face)
                (2 font-lock-string-face))))))

;; Web 开发
(use-package web-mode
  :mode "\\.html?\\'"
  :config
  (setq web-mode-markup-indent-offset 2
        web-mode-css-indent-offset 2
        web-mode-code-indent-offset 2))

(use-package emmet-mode
  :hook ((web-mode . emmet-mode)
         (css-mode . emmet-mode)))

;; PHP
(use-package php-mode
  :mode "\\.php\\'")

;; ------------------------------
;; 🌐 LSP 与智能补全
;; ------------------------------

;; 路径设置（避免启动时同步执行 npm prefix -g）
(dolist (dir '("/usr/local/bin" "~/.local/bin" "~/.npm-global/bin" "~/go/bin"))
  (let ((expanded-dir (expand-file-name dir)))
    (when (file-directory-p expanded-dir)
      (setenv "PATH" (concat expanded-dir ":" (getenv "PATH")))
      (add-to-list 'exec-path expanded-dir))))

(use-package lsp-mode
  :init
  (setq lsp-keymap-prefix "C-c l")
  :commands lsp
  :hook ((php-mode . lsp-deferred)
         (web-mode . lsp-deferred)
         (css-mode . lsp-deferred)
         (sh-mode . lsp-deferred)
         (c-mode    . lsp-deferred)
         (c++-mode  . lsp-deferred)
         (python-mode . lsp-deferred)
         (rust-ts-mode . lsp-deferred)
         (js-mode . lsp-deferred)
         (js-json-mode . lsp-deferred)
         (js-ts-mode . lsp-deferred)
         (typescript-ts-mode . lsp-deferred)
         (tsx-ts-mode . lsp-deferred)
         (go-ts-mode . lsp-deferred)
         (lua-ts-mode . lsp-deferred)
         (yaml-ts-mode . lsp-deferred)
         (dockerfile-ts-mode . lsp-deferred)
         (sql-mode . lsp-deferred)
         (markdown-mode . lsp-deferred)))

(use-package lsp-ui
  :hook (lsp-mode . lsp-ui-mode))

(setq lsp-clangd-binary-path "/usr/bin/clangd")
(setq lsp-clients-lua-language-server-install-dir "/usr/lib/lua-language-server/")
(setq lsp-sqls-server (expand-file-name "go/bin/sqls" (getenv "HOME")))

(use-package yasnippet
  :config
  (yas-global-mode 1))

(use-package company
  :hook (after-init . global-company-mode)
  :custom
  ;; 1. 让 backends 列表“合并”而不是完全覆盖，这样各模式能自动追加
  (company-backends '(company-files company-capf company-yasnippet))
  (company-minimum-prefix-length 1)
  (company-idle-delay 0.2)
  :bind (:map company-active-map
         ("<tab>" . company-complete-common-or-cycle)
         ("C-n" . company-select-next)
         ("C-p" . company-select-previous)))

;; 2. 单独给 c-mode/c++-mode 追加 LSP 后端
(with-eval-after-load 'company
  (add-to-list 'company-backends 'company-capf)   ;; LSP 用 company-capf
  (add-hook 'c-mode-hook
            (lambda ()
              (setq-local company-backends
                          '(company-capf company-files company-yasnippet)))))

;; ------------------------------
;; 🔎 快速补全与导航
;; ------------------------------

(use-package vertico
  :init
  (vertico-mode 1))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides
   '((file (styles partial-completion)))))

(use-package consult
  :bind (("C-s" . consult-line)
         ("C-x b" . consult-buffer)
         ("M-y" . consult-yank-pop)
         ("C-c h" . consult-ripgrep)
         ("C-c i" . consult-imenu)))

(use-package flycheck
  :hook (after-init . global-flycheck-mode))

(use-package lsp-treemacs
  :after lsp-mode)

;; ------------------------------
;; 📂 文件树与导航
;; ------------------------------

(use-package neotree
  :bind ("<f2>" . neotree-toggle)
  :config
  (use-package all-the-icons)) ; 依赖图标

;; ------------------------------
;; 🎨 主题与美化
;; ------------------------------

(use-package doom-themes
  :init (load-theme 'doom-gruvbox t)
  :config
  (doom-themes-visual-bell-config)
  (doom-themes-org-config))

(use-package doom-modeline
  :ensure t
  :defer 0.2
  :config
  (doom-modeline-mode 1))

(use-package highlight-indent-guides
  :hook (prog-mode . my-enable-highlight-indent-guides)
  :config
  (setq highlight-indent-guides-auto-character-face-per-depth t))

;; highlight-indent-guides 在 batch/无图形 frame 下会因为 default face 不完整而报错。
(defun my-enable-highlight-indent-guides ()
  (when (display-graphic-p)
    (highlight-indent-guides-mode 1)))

;; ------------------------------
;; 📄 Org Mode 核心配置
;; ------------------------------

(use-package org
  :ensure nil
  :defer t
  :bind (("C-c o a" . org-agenda)
         ("C-c l" . org-store-link))
  :custom
  (org-adapt-indentation nil)
  (org-list-allow-alphabetical t)
  (org-pretty-entities t)
  (org-hide-emphasis-markers t)
  (org-startup-indented t)
  (org-startup-with-inline-images t)
  (org-src-fontify-natively t)
  (org-src-tab-acts-natively t)
  (org-edit-src-content-indentation 0)
  (org-ellipsis " ⤵")
  ;;(org-ellipsis " ⤷")
  ;;(org-ellipsis " ↴")
  (org-directory "~/org/")
  (org-agenda-files
   (list (concat org-directory "tasks.org")
         (concat org-directory "notes.org")
         (concat org-directory "journal.org")))
  (org-todo-keywords
   '((sequence "TODO(t)" "IN-PROGRESS(p)" "WAITING(w)" "|" "DONE(d)" "CANCELLED(c)")))
  (org-todo-keyword-faces
   '(("TODO"        . (:foreground "red" :weight bold))
     ("IN-PROGRESS" . (:foreground "orange" :weight bold))
     ("WAITING"     . (:foreground "blue" :weight bold))
     ("DONE"        . (:foreground "forest green" :weight bold))
     ("CANCELLED"   . (:foreground "grey" :weight bold))))
  (org-log-done 'time)
  (org-deadline-warning-days 7)
  (org-agenda-span 14)
  (org-agenda-block-separator ?─)
  (org-agenda-time-grid
   '((daily today require-timed)
     (800 1000 1200 1400 1600 1800 2000)
     " ┄┄┄┄┄ " "────────────────"))
  (org-babel-python-command "python3")
  (org-plantuml-exec-mode 'plantuml)
  (org-plantuml-executable-path "/usr/bin/plantuml")
  :config
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((python . t)
     (shell . t)
     (R . t)
     (js . t)
     (sql . t)
     (emacs-lisp . t)
     (org . t)
     (dot . t)
     (plantuml . t))))

;; Org 子模块
(use-package org-bullets
  :hook (org-mode . org-bullets-mode)
  :config
;;  (setq org-bullets-bullet-list '("◉" "○" "✸" "☆")))
  (setq org-bullets-bullet-list '("★" "✮" "☆" "✫" "✪" "✬" "✸" "✿" "▸" "•")))

(use-package org-modern
  :hook (org-mode . org-modern-mode)
  :custom
  ;; Keep the existing org-bullets hierarchy icons.
  (org-modern-star nil)
  (org-modern-todo t)
  (org-modern-tag t)
  (org-modern-priority t)
  (org-modern-hide-stars 'leading))

(use-package org-roam
  :after org
  :custom
  (org-roam-directory (file-truename "~/org/roam/"))
  :bind (("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n l" . org-roam-buffer-toggle)
         ("C-c n c" . org-roam-capture)
         ("C-c n d" . org-roam-dailies-capture-today))
  :config
  (make-directory org-roam-directory t)
  (org-roam-db-autosync-enable))

;; Journal
(use-package org-journal
  :after org
  :custom
  (org-journal-dir (concat org-directory "journal/"))
  (org-journal-date-format "%Y-%m-%d (%A)")
  (org-journal-file-format "%Y-%m-%d.org"))

;; 让 PlantUML 在无图形显示的 Emacs/session 中也能执行
(unless (string-match-p "-Djava\\.awt\\.headless=true" (or (getenv "JAVA_TOOL_OPTIONS") ""))
  (setenv "JAVA_TOOL_OPTIONS"
          (string-trim
           (concat (or (getenv "JAVA_TOOL_OPTIONS") "")
                   " -Djava.awt.headless=true"))))

;; ------------------------------
;; 📝 Markdown 支持
;; ------------------------------

(use-package markdown-mode
  :mode "\\.md\\'"
  :hook (markdown-mode . (lambda ()
                           (setq tab-width 4)
                           (flyspell-mode 1)
                           (local-set-key (kbd "C-c t") 'markdown-table-align)))
  :config
  (when (executable-find "marked")
    (setq markdown-command "marked")))

(use-package markdown-preview-mode
  :defer t)

(use-package elfeed
  :commands elfeed
  :bind ("C-c w" . elfeed)
  :custom
  (elfeed-feeds
   '(("https://planet.emacslife.com/atom.xml" emacs)
     ("https://hnrss.org/frontpage" tech))))

(use-package nov
  :mode ("\\.epub\\'" . nov-mode))

(use-package keycast
  :commands keycast-mode-line-mode
  ;; The current MELPA build requires a newer cond-let API than this Emacs
  ;; package archive provides; load it on demand after that dependency is fixed.
  :defer t)

(use-package yeetube
  :commands yeetube-search
  :bind ("C-c y" . yeetube-search)
  :custom
  (yeetube-ytdlp-program "yt-dlp")
  (yeetube-play-function #'yeetube-mpv-play))

(use-package pdf-tools
  :magic ("%PDF" . pdf-view-mode)
  :config
  (pdf-tools-install :no-query)
  (setq-default pdf-view-display-size 'fit-page)
  (add-hook 'pdf-view-mode-hook #'display-line-numbers-mode -90))

;; 只设置程序和默认词典，不碰 ispell-local-dictionary-alist
(setq ispell-program-name "aspell")
(setq ispell-dictionary "en") ; 默认全局用英文

;; 在需要的 mode 中启用 flyspell
(defun my-enable-flyspell-en ()
  (setq ispell-local-dictionary "en") ; 明确指定 buffer 用 en
  (flyspell-mode 1))

(add-hook 'org-mode-hook 'my-enable-flyspell-en)
(add-hook 'markdown-mode-hook 'my-enable-flyspell-en)

;; ------------------------------
;; 🖼️ 启动页与 Dashboard
;; ------------------------------

(use-package dashboard
  :ensure t
  :config
  (dashboard-setup-startup-hook)
  (setq dashboard-startup-banner (expand-file-name "images/splash.svg"
                                                    data-directory)
        dashboard-banner-logo-title "Welcome back, Alex")
  (setq dashboard-items '((recents  . 10)
                          (projects . 5)
                          (bookmarks . 5))))

;; Load private machine-local settings such as email address and API keys.
;; local.el is intentionally ignored by Git.
(load (expand-file-name "local.el" user-emacs-directory) t)

;; ------------------------------
;; 📬 邮件：mu4e
;; ------------------------------

(use-package mu4e
  :ensure nil
  :commands mu4e
  :init
  (setq mu4e-maildir "~/Mail/qq"
        mu4e-drafts-folder "/Drafts"
        mu4e-sent-folder "/Sent"
        mu4e-trash-folder "/Trash"
        mu4e-refile-folder "/Archive"
        mu4e-mu-binary-location "/usr/bin/mu"
        mu4e-get-mail-command "mbsync qq"
        mu4e-update-interval 300
        message-send-mail-function 'message-send-mail-with-sendmail
        sendmail-program "/usr/bin/msmtp"
        message-kill-buffer-on-exit t
        mu4e-compose-dont-reply-to-self t
        user-mail-address (or user-mail-address "")
        user-full-name (or user-full-name "alex")
        mu4e-user-mail-address-list (if (string-empty-p user-mail-address) nil (list user-mail-address))
        mu4e-attachment-dir "~/Downloads"
        mu4e-view-show-images t
        mm-inline-images t
        mu4e-html2text-command "w3m -T text/html")
  :bind (("C-x m" . mu4e-compose-new)
         ("C-x M" . mu4e))
  :hook (message-mode . (lambda ()
                          (local-set-key (kbd "C-c C-c") 'message-send-and-exit))))

;; ------------------------------
;; 🎵 音乐播放：EMMS
;; ------------------------------

(add-to-list 'load-path "~/.emacs.d/lisp")
(use-package emms
  :commands (emms emms-play-directory emms-pause emms-stop emms-next emms-previous)
  :bind (("<f6>" . emms-pause)
         ("C-<f6>" . emms-stop)
         ("C-`" . emms-next)
         ("C-'" . emms-previous))
  :config
  (require 'emms-setup)
  (emms-all)
  (emms-default-players)
  (setq emms-player-list '(emms-player-mpv))
  (setq emms-source-directory-tree-root "~/songs/")
  (require 'emms-spectrum)
  (setq emms-spectrum-bar-count 32
        emms-spectrum-refresh-rate 0.1
        emms-spectrum-peak-hold t
        emms-spectrum-color-theme 'rainbow
        emms-spectrum-height 10))

;; ------------------------------
;;    中国象棋
;; ------------------------------
(add-to-list 'load-path "/home/alex/.emacs.d/emacs-chess-cn")
(autoload 'chess-cn "chess-cn" nil t)

;; ------------------------------
;; 🖥️ 终端与工具
;; ------------------------------

;; 浮动终端
(use-package vterm
  :bind ("C-c t" . vterm))

;; 快速打开配置文件
(global-set-key (kbd "C-c e") (lambda () (interactive) (find-file "~/.emacs.d/init.el")))
(global-set-key (kbd "C-c r") (lambda () (interactive)
                                (save-buffer)
                                (message "重新加载配置...")
                                (load-file "~/.emacs.d/init.el")))

;; ------------------------------
;; AI
;; ------------------------------
;; DEEPSEEK_API_KEY is read from local.el or the shell environment.

(use-package aidermacs
  :bind ("C-c a" . aidermacs-transient-menu)
  :custom
  (aidermacs-program "/home/alex/.local/bin/aider")
  (aidermacs-default-model "deepseek/deepseek-v4-pro")
  (aidermacs-extra-args '("--no-check-update" "--no-gitignore" "--map-tokens" "0"
                          "--thinking-tokens" "0"))
  (aidermacs-backend 'vterm))

;; ------------------------------
;; ✅ 启动完成提示
;; ------------------------------

(message "🎉 Emacs 配置加载完成！F2 打开文件树，C-x g 打开 Magit，C-c o a 打开 Org Agenda，C-c a 打开 Aider。")

;; ------------------------------
;; 🌿 可选：Git 集成（Magit）
;; ------------------------------

(use-package magit
  :bind ("C-x g" . magit-status))

;; ------------------------------
;; 🧘 专注模式
;; ------------------------------

(use-package writeroom-mode
  :bind ("<f11>" . writeroom-mode))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("21d2bf8d4d1df4859ff94422b5e41f6f2eeff14dd12f01428fa3cb4cb50ea0fb"
     "b7a09eb77a1e9b98cafba8ef1bd58871f91958538f6671b22976ea38c2580755"
     "5c7720c63b729140ed88cf35413f36c728ab7c70f8cd8422d9ee1cedeb618de5"
     "8c7e832be864674c220f9a9361c851917a93f921fedb7717b1b5ece47690c098"
     "e4a702e262c3e3501dfe25091621fe12cd63c7845221687e36a79e17cf3a67e0"
     "d12b1d9b0498280f60e5ec92e5ecec4b5db5370d05e787bc7cc49eae6fb07bc0"
     "aec7b55f2a13307a55517fdf08438863d694550565dee23181d2ebd973ebd6b8"
     "dd4582661a1c6b865a33b89312c97a13a3885dc95992e2e5fc57456b4c545176"
     "56044c5a9cc45b6ec45c0eb28df100d3f0a576f18eef33ff8ff5d32bac2d9700"
     "d481904809c509641a1a1f1b1eb80b94c58c210145effc2631c1a7f2e4a2fdf4"
     "720838034f1dd3b3da66f6bd4d053ee67c93a747b219d1c546c41c4e425daf93"
     "1ad12cda71588cc82e74f1cabeed99705c6a60d23ee1bb355c293ba9c000d4ac"
     "5a4cdc4365122d1a17a7ad93b6e3370ffe95db87ed17a38a94713f6ffe0d8ceb"
     "cee5c56dc8b95b345bfe1c88d82d48f89e0f23008b0c2154ef452b2ce348da37"
     "0325a6b5eea7e5febae709dab35ec8648908af12cf2d2b569bedc8da0a3a81c1"
     default))
 '(package-selected-packages
   '(aidermacs all-the-icons chess company-dict dashboard dired-sidebar
               consult doom-modeline doom-themes dracula-theme
               ef-themes elfeed emmet-mode emms flycheck fold-dwim
               git-modes gruvbox-theme highlight-indent-guides htmlize
               keycast lsp-treemacs lsp-ui magit markdown-preview-mode
               neotree nord-theme nov orderless org-bullets
               org-journal org-modern org-roam org-superstar origami
               pdf-tools php-mode vertico vterm web-mode
               writeroom-mode yeetube)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
