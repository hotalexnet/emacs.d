# Alex's Emacs Configuration

这是我的个人 Emacs 配置，主要面向 Arch Linux / GNU Linux 桌面环境。配置集中在 `init.el`，启动优化在 `early-init.el`，本机私有信息放在不会提交的 `local.el`。

## 目录结构

```text
~/.emacs.d/
├── init.el              # 主配置
├── early-init.el        # 启动阶段优化
├── lisp/                # 本地扩展，例如 emms-spectrum.el
├── dict/                # 本地词典文件
├── emacs-chess-cn/      # 中国象棋扩展
├── .gitignore           # 忽略缓存、数据库、私有配置和编译产物
└── local.el             # 本机私有配置，不提交
```

## Emacs 版本

建议使用 Emacs 30 或更新版本。

原因是配置里优先使用了 Emacs 30 内置的 tree-sitter major modes，例如：

- `rust-ts-mode`
- `go-ts-mode`
- `typescript-ts-mode`
- `tsx-ts-mode`
- `lua-ts-mode`
- `yaml-ts-mode`
- `dockerfile-ts-mode`

如果使用较老版本 Emacs，需要自己调整这些 mode 映射。

## 首次安装

克隆到 Emacs 配置目录：

```sh
git clone <your-repo-url> ~/.emacs.d
```

首次启动 Emacs 时，配置会自动：

1. 初始化 `package.el`
2. 使用清华 ELPA 镜像
3. 自动安装 `use-package`
4. 通过 `use-package-always-ensure` 自动安装缺失的 Emacs 包

如果第一次启动时包安装失败，通常是网络或 ELPA 镜像访问问题。可以重新启动 Emacs，或手动执行：

```elisp
M-x package-refresh-contents
```

## Emacs 包依赖

这些包由 `use-package` 自动安装：

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

`org` 和 `mu4e` 不通过 ELPA 自动安装：

- `org` 使用 Emacs 自带版本
- `mu4e` 来自系统里的 `mu` 邮件工具

## 系统依赖

下面这些不是 Emacs 包，需要系统安装。不同发行版包名可能略有区别。

### 基础工具

```sh
sudo pacman -S ripgrep fd git aspell aspell-en w3m
```

用途：

- `ripgrep`：`consult-ripgrep` 搜索项目
- `aspell` / `aspell-en`：Org 和 Markdown 拼写检查
- `w3m`：mu4e HTML 邮件转文本

### LSP 和编程语言支持

```sh
sudo pacman -S clang lua-language-server typescript-language-server yaml-language-server dockerfile-language-server
```

配置中显式使用：

```text
/usr/bin/clangd
/usr/lib/lua-language-server/
```

SQL LSP 使用 Go 安装的 `sqls`：

```sh
go install github.com/sqls-server/sqls@latest
```

安装后需要确保 `~/go/bin/sqls` 存在。

常用语言服务器建议按需安装：

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

### Tree-sitter grammars

配置会优先使用 Emacs 内置的 `*-ts-mode`，但 grammar 仍需要存在。当前本机使用的是：

```text
~/.emacs.d/tree-sitter/libtree-sitter-typescript.so
~/.emacs.d/tree-sitter/libtree-sitter-tsx.so
~/.emacs.d/tree-sitter/libtree-sitter-go.so
~/.emacs.d/tree-sitter/libtree-sitter-rust.so
~/.emacs.d/tree-sitter/libtree-sitter-yaml.so
~/.emacs.d/tree-sitter/libtree-sitter-dockerfile.so
```

这些 `.so` 文件是本机编译产物，不提交到 Git。新机器上需要重新安装或编译 grammar。

### Org / PlantUML

Org Babel 启用了这些语言：

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

PlantUML 需要系统命令：

```sh
sudo pacman -S plantuml graphviz
```

配置里使用：

```text
/usr/bin/plantuml
```

### Markdown 预览

如果安装了 `marked`，`markdown-mode` 会用它渲染 Markdown：

```sh
npm install -g marked
```

### PDF

`pdf-tools` 首次安装可能需要编译依赖。Arch Linux 通常需要：

```sh
sudo pacman -S poppler-glib base-devel
```

### 视频和音乐

`yeetube` 和 `emms` 需要外部播放器/下载器：

```sh
sudo pacman -S mpv yt-dlp
```

EMMS 默认音乐目录是：

```text
~/songs/
```

可以在 `init.el` 里修改 `emms-source-directory-tree-root`。

### 邮件 mu4e

邮件功能依赖：

```sh
sudo pacman -S mu isync msmtp w3m
```

配置默认：

```text
mu4e-maildir: ~/Mail/qq
mbsync account: qq
sendmail: /usr/bin/msmtp
```

还需要你自己配置：

```text
~/.mbsyncrc
~/.msmtprc
```

这些文件通常包含账号或认证信息，不应提交到 Git。

### vterm

`vterm` 需要编译模块：

```sh
sudo pacman -S cmake libvterm
```

### Aider / Aidermacs

配置中使用：

```text
~/.local/bin/aider
```

可以用 pipx 安装：

```sh
pipx install aider-chat
```

或按你的 Python 环境自行安装，只要保证 `~/.local/bin/aider` 可执行。

## 私有配置 local.el

`local.el` 用来存放不适合公开提交的信息，例如邮箱、姓名、API key。它已被 `.gitignore` 忽略。

创建文件：

```sh
nano ~/.emacs.d/local.el
```

示例：

```elisp
;;; local.el --- Private local Emacs settings -*- lexical-binding: t; -*-

(setq user-mail-address "you@example.com"
      user-full-name "Your Name")

(setenv "DEEPSEEK_API_KEY" "your-api-key")
```

不要把真实的 `local.el` 上传到公开仓库。

## 常用快捷键

```text
F2      neotree 文件树
C-x g   Magit
C-c o a Org Agenda
C-c l   org-store-link
C-c n f org-roam-node-find
C-c n i org-roam-node-insert
C-c n l org-roam-buffer-toggle
C-c n c org-roam-capture
C-c n d org-roam-dailies-capture-today
C-c w   elfeed
C-c y   yeetube-search
C-c a   aidermacs
C-c t   vterm
C-c e   打开 init.el
C-c r   保存并重新加载 init.el
F11     writeroom-mode
F6      EMMS 暂停/继续
C-F6    EMMS 停止
C-`     EMMS 下一首
C-'     EMMS 上一首
```

## Org 配置说明

Org 相关增强包括：

- `org-bullets`：替换标题星号
- `org-modern`：美化 TODO、标签、优先级和部分 Org 元素
- `org-roam`：双链笔记
- `org-journal`：日记
- `org-hide-emphasis-markers`：隐藏粗体、斜体、代码等标记符号
- `org-startup-indented`：视觉缩进
- `org-ellipsis`：折叠提示符显示为 `⤵`
- `org-src-fontify-natively`：代码块原生高亮

默认 Org 目录：

```text
~/org/
```

Agenda 文件：

```text
~/org/tasks.org
~/org/notes.org
~/org/journal.org
```

Org-roam 目录：

```text
~/org/roam/
```

## 不提交的文件

`.gitignore` 会忽略：

```text
local.el
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

这些都是本机缓存、数据库、历史记录、私有配置或编译产物，不适合提交。

## 新机器恢复 checklist

1. 安装 Emacs 30+
2. 克隆仓库到 `~/.emacs.d`
3. 安装基础系统依赖
4. 创建 `~/.emacs.d/local.el`
5. 如需邮件，配置 `~/.mbsyncrc` 和 `~/.msmtprc`
6. 如需 LSP，安装对应语言服务器
7. 如需 tree-sitter，安装或编译 grammar
8. 启动 Emacs，让 `use-package` 自动安装 Emacs 包
9. 如果 `pdf-tools` 或 `vterm` 编译失败，补齐系统编译依赖后重启 Emacs

## 备注

这份配置偏个人工作流，不是通用发行版。公开仓库里保留了可复现的核心配置，机器相关的缓存、数据库、账号和密钥都应留在本机。
