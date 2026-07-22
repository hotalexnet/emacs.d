# Alex's Emacs Configuration

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Runtime: Emacs 30+](https://img.shields.io/badge/runtime-Emacs%2030%2B-blue.svg)](https://www.gnu.org/software/emacs/)
[![State: Dotfiles](https://img.shields.io/badge/state-dotfiles-2ea44f.svg)](#what-it-does)
**English** | [**中文**](./README.zh-CN.md)

Personal Emacs configuration for GNU/Linux, mainly targeting Arch Linux. The main configuration lives in `init.el`; startup optimizations live in `early-init.el`; private machine settings live in `local.el`, which is ignored by Git.

## What It Does

This repository provides a complete `~/.emacs.d` setup for editing, Org mode,
LSP-based programming, completion, project navigation, email/news reading,
media playback, PDF reading, terminal use, and Aider-assisted coding.

## Directory Layout

```text
~/.emacs.d/
├── init.el              # Main configuration
├── early-init.el        # Startup optimizations
├── lisp/                # Local extensions, such as emms-spectrum.el
├── dict/                # Local dictionary files
├── emacs-chess-cn/      # Chinese chess extension, tracked as a submodule
├── .gitignore           # Ignores caches, databases, private files, and build outputs
├── local.example.el     # Template for private local settings
└── local.el             # Private local settings, not committed
```

## Emacs Version

Emacs 30 or newer is recommended.

This configuration prefers built-in tree-sitter major modes, including:

- `rust-ts-mode`
- `go-ts-mode`
- `typescript-ts-mode`
- `tsx-ts-mode`
- `lua-ts-mode`
- `yaml-ts-mode`
- `dockerfile-ts-mode`

If you use an older Emacs version, adjust these mode mappings yourself.

## First Install

Clone this repository into the Emacs configuration directory:

```sh
git clone --recurse-submodules <your-repo-url> ~/.emacs.d
```

If you already cloned without submodules, initialize them afterwards:

```sh
git submodule update --init --recursive
```

On first startup, Emacs will automatically:

1. Initialize `package.el`
2. Use the Tsinghua ELPA mirrors
3. Install `use-package` if missing
4. Install missing Emacs packages through `use-package-always-ensure`

If package installation fails on first startup, it is usually a network or mirror access issue. Restart Emacs or run:

```elisp
M-x package-refresh-contents
```

## Emacs Package Dependencies

These packages are installed automatically through `use-package`:

```text
git-modes
web-mode
emmet-mode
php-mode
lsp-mode
lsp-ui
yasnippet
company
vertico
orderless
consult
flycheck
lsp-treemacs
neotree
all-the-icons
doom-themes
doom-modeline
highlight-indent-guides
org-bullets
org-modern
org-roam
org-journal
markdown-mode
markdown-preview-mode
elfeed
nov
keycast
yeetube
pdf-tools
dashboard
emms
vterm
aidermacs
magit
writeroom-mode
```

`org` and `mu4e` are not installed from ELPA:

- `org` uses the version bundled with Emacs
- `mu4e` comes from the system `mu` mail package

## System Dependencies

The following are external system programs, not Emacs packages. Package names may vary across distributions.

### Basic Tools

```sh
sudo pacman -S ripgrep fd git aspell aspell-en w3m
```

Usage:

- `ripgrep`: project search via `consult-ripgrep`
- `aspell` / `aspell-en`: spell checking in Org and Markdown
- `w3m`: HTML-to-text conversion for `mu4e`

### LSP And Programming Language Support

```sh
sudo pacman -S clang lua-language-server typescript-language-server yaml-language-server dockerfile-language-server
```

The configuration explicitly uses:

```text
/usr/bin/clangd
/usr/lib/lua-language-server/
```

SQL LSP uses `sqls`, installed through Go:

```sh
go install github.com/sqls-server/sqls@latest
```

After installation, make sure `~/go/bin/sqls` exists.

Common optional language servers:

```sh
# Python
sudo pacman -S pyright

# Rust
rustup component add rust-analyzer

# Go
go install golang.org/x/tools/gopls@latest

# PHP
composer global require phpactor/phpactor
```

### Tree-sitter Grammars

The configuration prefers Emacs built-in `*-ts-mode`, but grammar libraries still need to exist. This machine currently uses:

```text
~/.emacs.d/tree-sitter/libtree-sitter-typescript.so
~/.emacs.d/tree-sitter/libtree-sitter-tsx.so
~/.emacs.d/tree-sitter/libtree-sitter-go.so
~/.emacs.d/tree-sitter/libtree-sitter-rust.so
~/.emacs.d/tree-sitter/libtree-sitter-yaml.so
~/.emacs.d/tree-sitter/libtree-sitter-dockerfile.so
```

These `.so` files are local build outputs and are not committed. Reinstall or rebuild grammars on a new machine.

### Org / PlantUML

Org Babel enables these languages:

```text
python
shell
R
js
sql
emacs-lisp
org
dot
plantuml
```

PlantUML requires external tools:

```sh
sudo pacman -S plantuml graphviz
```

The configuration uses:

```text
/usr/bin/plantuml
```

### Markdown Preview

If `marked` is installed, `markdown-mode` uses it to render Markdown:

```sh
npm install -g marked
```

### PDF

`pdf-tools` may need build dependencies on first install. On Arch Linux:

```sh
sudo pacman -S poppler-glib base-devel
```

### Video And Music

`yeetube` and `emms` need external media tools:

```sh
sudo pacman -S mpv yt-dlp
```

The default EMMS music directory is:

```text
~/songs/
```

Change `emms-source-directory-tree-root` in `init.el` if needed.

### Mail / mu4e

Mail support depends on:

```sh
sudo pacman -S mu isync msmtp w3m
```

Defaults used by this configuration:

```text
mu4e-maildir: ~/Mail/qq
mbsync account: qq
sendmail: /usr/bin/msmtp
```

You still need to configure:

```text
~/.mbsyncrc
~/.msmtprc
```

These files usually contain account or authentication data and should not be committed.

### vterm

`vterm` needs native module build dependencies:

```sh
sudo pacman -S cmake libvterm
```

### Aider / Aidermacs

This configuration expects:

```text
~/.local/bin/aider
```

Install it with pipx:

```sh
pipx install aider-chat
```

Or install it through your preferred Python environment, as long as `~/.local/bin/aider` is executable.

## Private Configuration: local.el

`local.el` stores information that should not be committed, such as email address, full name, and API keys. It is ignored by `.gitignore`.

Copy the template:

```sh
cp ~/.emacs.d/local.example.el ~/.emacs.d/local.el
```

Then edit `local.el`. Template content:

```elisp
;;; local.el --- Private local Emacs settings -*- lexical-binding: t; -*-

(setq user-mail-address "you@example.com"
      user-full-name "Your Name")

(setenv "DEEPSEEK_API_KEY" "your-api-key")
```

Do not upload your real `local.el` to a public repository.

## Key Bindings

```text
F2      Toggle neotree
C-x g   Magit status
C-c o a Org Agenda
C-c l   Store Org link
C-c n f Find Org-roam node
C-c n i Insert Org-roam node
C-c n l Toggle Org-roam buffer
C-c n c Org-roam capture
C-c n d Capture today's Org-roam daily
C-c w   Elfeed
C-c y   Yeetube search
C-c a   Aidermacs
C-c t   vterm
C-c e   Open init.el
C-c r   Save and reload init.el
F11     writeroom-mode
F6      EMMS pause/resume
C-F6    EMMS stop
C-`     EMMS next track
C-'     EMMS previous track
```

## Org Configuration

Org enhancements include:

- `org-bullets`: replaces headline stars
- `org-modern`: improves TODO keywords, tags, priorities, and other Org elements
- `org-roam`: linked notes
- `org-journal`: journal files
- `org-hide-emphasis-markers`: hides markup characters for bold, italic, code, and similar text
- `org-startup-indented`: visual indentation
- `org-ellipsis`: folded headings show `⤵`
- `org-src-fontify-natively`: native syntax highlighting in source blocks

Default Org directory:

```text
~/org/
```

Agenda files:

```text
~/org/tasks.org
~/org/notes.org
~/org/journal.org
```

Org-roam directory:

```text
~/org/roam/
```

## Ignored Files

`.gitignore` ignores:

```text
local.el
custom.el
elpa/
eln-cache/
.cache/
auto-save-list/
var/
recentf
.lsp-session-v1
lsp-cache/
org-roam.db
elfeed/
emms/cache
emms/history
emms/scores
games/*-scores
tree-sitter/*.so
init.el.bak-*
```

These are local caches, databases, histories, private settings, or build outputs and should not be committed.

## New Machine Restore Checklist

1. Install Emacs 30+
2. Clone this repository to `~/.emacs.d`
3. Install basic system dependencies
4. Create `~/.emacs.d/local.el`
5. Configure `~/.mbsyncrc` and `~/.msmtprc` if mail is needed
6. Install language servers if LSP is needed
7. Install or build tree-sitter grammars if needed
8. Start Emacs and let `use-package` install Emacs packages
9. If `pdf-tools` or `vterm` fails to build, install the missing native build dependencies and restart Emacs

## Notes

This is a personal workflow configuration, not a general-purpose Emacs distribution. The repository keeps reproducible configuration files public, while machine-local caches, databases, accounts, and secrets stay local.
