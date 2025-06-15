# Dotfiles Configuration

A comprehensive collection of configuration files for a modern development environment featuring Bash, Tmux, and Neovim with a focus on productivity and developer experience.

## 🎯 Overview

This repository contains carefully curated configuration files that provide:

-   **Enhanced Terminal Experience**: Customized Bash environment with useful aliases and modern tooling support
-   **Terminal Multiplexing**: Productive Tmux configuration for session management and window splitting
-   **Modern Text Editor**: Feature-rich Neovim setup based on Kickstart.nvim with LSP, autocompletion, and formatting
-   **IDE Configuration**: VS Code settings and keybindings for optimal development workflow

## 📋 Prerequisites

### System Requirements

-   **Operating System**: Linux (tested on Ubuntu/Debian-based systems)
-   **Shell**: Bash (default on most Linux systems)
-   **Git**: Required for cloning and plugin management
-   **Make**: Required for building some Neovim plugins
-   **Unzip**: Required for plugin extraction

### Required Tools

#### Core Dependencies

```bash
# Essential tools
sudo apt update && sudo apt install -y git make unzip curl wget

# Node.js ecosystem (for JavaScript/TypeScript development)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
# Restart terminal, then:
nvm install --lts
nvm use --lts

# Neovim (latest stable)
wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo tar -C /opt -xzf nvim-linux64.tar.gz
sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/
```

#### Package Managers & Tools

```bash
# Bun (JavaScript runtime and package manager)
curl -fsSL https://bun.sh/install | bash

# pnpm (Fast, disk space efficient package manager)
curl -fsSL https://get.pnpm.io/install.sh | sh

# Homebrew on Linux (for additional tools)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Ripgrep (fast text search - required for Telescope)
sudo apt install ripgrep
# OR via Homebrew: brew install ripgrep

# LazyGit (Git TUI - optional but recommended)
brew install lazygit
# OR: sudo apt install lazygit
```

#### Development Tools

```bash
# Tmux
sudo apt install tmux

# Build essentials for compiling tools
sudo apt install build-essential

# For C/C++ development (optional)
sudo apt install clang-format

# For Python development (optional)
sudo apt install python3-pip
pip3 install black isort flake8
```

## 🚀 Installation

### Quick Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Backup existing configurations (recommended)
mkdir -p ~/dotfiles-backup
cp ~/.bashrc ~/dotfiles-backup/ 2>/dev/null || true
cp ~/.tmux.conf ~/dotfiles-backup/ 2>/dev/null || true
cp -r ~/.config/nvim ~/dotfiles-backup/ 2>/dev/null || true
cp -r ~/.config/Code/User ~/dotfiles-backup/vscode-user 2>/dev/null || true

# Create symbolic links
ln -sf ~/dotfiles/.bashrc ~/.bashrc
ln -sf ~/dotfiles/.tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles/nvim ~/.config/nvim

# VS Code settings (choose your installation path)
# For VS Code:
ln -sf ~/dotfiles/vscode/settings.json ~/.config/Code/User/settings.json
ln -sf ~/dotfiles/vscode/keybindings.json ~/.config/Code/User/keybindings.json
# For VS Code Insiders:
# ln -sf ~/dotfiles/vscode/settings.json ~/.config/Code\ -\ Insiders/User/settings.json
# ln -sf ~/dotfiles/vscode/keybindings.json ~/.config/Code\ -\ Insiders/User/keybindings.json

# Source the new bash configuration
source ~/.bashrc
```

### Manual Installation

If you prefer to review and selectively apply configurations:

1. **Bash Configuration**:

    ```bash
    cp .bashrc ~/.bashrc
    source ~/.bashrc
    ```

2. **Tmux Configuration**:

    ```bash
    cp .tmux.conf ~/.tmux.conf
    # Restart tmux or source: tmux source-file ~/.tmux.conf
    ```

3. **Neovim Configuration**:

    ```bash
    mkdir -p ~/.config
    cp -r nvim ~/.config/
    # Neovim will automatically install plugins on first launch
    ```

4. **VS Code Configuration**:

    ```bash
    # Create VS Code User directory if it doesn't exist
    mkdir -p ~/.config/Code/User

    # Copy settings and keybindings
    cp vscode/settings.json ~/.config/Code/User/
    cp vscode/keybindings.json ~/.config/Code/User/

    # For VS Code Insiders, use:
    # mkdir -p ~/.config/Code\ -\ Insiders/User
    # cp vscode/settings.json ~/.config/Code\ -\ Insiders/User/
    # cp vscode/keybindings.json ~/.config/Code\ -\ Insiders/User/
    ```

## 📁 Configuration Details

### Bash Configuration (`.bashrc`)

**Key Features**:

-   **Development Aliases**: Quick shortcuts for common development tasks
    -   `lg` → `lazygit` (Git TUI)
    -   `cl` → `clear` (Clear terminal)
    -   `nvc` → `cd ~/.config/nvim/` (Quick access to Neovim config)
-   **Tool Integration**: Automatic setup for modern development tools
    -   NVM (Node Version Manager)
    -   Bun (JavaScript runtime)
    -   pnpm (Package manager)
    -   Homebrew on Linux
-   **Enhanced Terminal**: Colored output, improved history, and intelligent completion

### Tmux Configuration (`.tmux.conf`)

**Key Features**:

-   **Mouse Support**: Click to switch panes and resize windows
-   **Intuitive Keybindings**:
    -   `|` for horizontal split
    -   `-` for vertical split
    -   `Ctrl + Arrow Keys` for pane navigation
    -   `Prefix + r` to reload configuration
-   **Visual Enhancements**:
    -   Session info in status bar
    -   Date/time display
    -   Window numbering starting from 1
-   **Productivity**:
    -   Large history buffer (10,000 lines)
    -   Automatic window renumbering

### Neovim Configuration (`nvim/`)

**Architecture**: Based on Kickstart.nvim with custom extensions

**Core Features**:

-   **Modern Plugin Management**: Lazy.nvim for fast startup and efficient loading
-   **LSP Integration**: Full Language Server Protocol support with Mason for automatic installation
-   **Smart Autocompletion**: Blink.cmp with snippet support via LuaSnip
-   **Advanced Search**: Telescope.nvim with fuzzy finding and live grep
-   **Git Integration**: Gitsigns for diff visualization and git operations
-   **Syntax Highlighting**: Treesitter for accurate code parsing

**Custom Plugins** (`nvim/lua/custom/plugins/`):

-   **Conform.nvim**: Advanced code formatting with project-aware Prettier configuration
    -   Automatic format-on-save
    -   Support for JavaScript, TypeScript, React, JSON, HTML, CSS, SCSS, Markdown, YAML
    -   Smart config detection (project-level → global fallback)

**Available Kickstart Plugins** (`nvim/lua/kickstart/plugins/`):

-   Debug support (DAP) for debugging workflows
-   Autopairs for bracket/quote completion
-   Enhanced Git signs and operations
-   Indentation guides
-   Linting support
-   Neo-tree file explorer

**Key Mappings**:

-   `<Space>` → Leader key
-   `<Leader>f` → Format current buffer
-   `<Leader>sf` → Search files (Telescope)
-   `<Leader>sg` → Live grep (Telescope)
-   `<Leader>pv` → Open file explorer (Netrw)
-   `<C-h/j/k/l>` → Navigate between splits

### VS Code Configuration (`vscode/`)

**Key Features**:

-   **Editor Settings**: Optimized for development productivity
    -   Tab size: 4 spaces with smart indentation
    -   Format on save with automatic import organization
    -   Prettier as default formatter
    -   Intelligent cursor positioning with surrounding lines
-   **File Management**: Enhanced file handling and exclusions
    -   Smart exclusion of common build/cache directories
    -   Hidden system files (.git, .DS_Store, node_modules, dist, build, .next, .nuxt)
-   **Custom Keybindings**: Productivity-focused shortcuts
    -   `Ctrl+M` → Next editor tab
    -   `Ctrl+N` → Previous editor tab
    -   `Shift+Ctrl+I` → Focus outline
    -   `Ctrl+Shift+]` → Peek definition
-   **Development Tools**: Integrated development experience
    -   Inline suggestions enabled
    -   Code actions on save (fix all, organize imports)
    -   Enhanced word handling and navigation

**Files**:

-   `settings.json` → User settings with development optimizations
-   `keybindings.json` → Custom key bindings for improved workflow

## 🔧 Customization

### Adding New Bash Aliases

Edit `.bashrc` and add your aliases in the custom aliases section:

```bash
#custom aliases
alias your_alias='your_command'
```

### Extending Neovim

1. **Add new plugins**: Create files in `nvim/lua/custom/plugins/`
2. **Modify existing config**: Edit the respective files in the plugin directories
3. **LSP servers**: Modify the `servers` table in `nvim/init.lua`

### Tmux Customization

Modify `.tmux.conf` and reload with `tmux source-file ~/.tmux.conf`

### VS Code Customization

1. **Settings**: Edit `vscode/settings.json` to modify editor behavior, formatting rules, and file exclusions
2. **Keybindings**: Edit `vscode/keybindings.json` to add or modify keyboard shortcuts
3. **Extensions**: The settings include configurations that work well with popular extensions like Prettier, ESLint, and GitLens

## 🎨 Theming

-   **Neovim**: Currently using Tokyo Night theme (can be changed in `nvim/init.lua`)
-   **VS Code**: Inherits from your VS Code theme settings (not included in these configs)
-   **Terminal**: Inherits from your terminal emulator's color scheme
-   **Tmux**: Minimal status bar with green and yellow accents

## 🛠️ Troubleshooting

### Common Issues

1. **Neovim plugins not loading**:

    ```bash
    nvim --headless "+Lazy! sync" +qa
    ```

2. **LSP not working**:

    ```bash
    # In Neovim
    :checkhealth
    :Mason  # Install missing language servers
    ```

3. **Tmux key bindings not working**:

    ```bash
    tmux kill-server  # Restart tmux completely
    ```

4. **Node.js tools not found**:

    ```bash
    # Reinstall NVM and Node.js
    source ~/.bashrc
    nvm install --lts
    ```

### Health Checks

```bash
# Neovim health check
nvim -c ":checkhealth" -c ":qa"

# Check installed tools
which nvim tmux git make unzip rg
node --version
npm --version
```

## 📚 Learning Resources

-   **Neovim**: `:help` within Neovim, [Learn Vimscript the Hard Way](https://learnvimscriptthehardway.stevelosh.com/)
-   **Kick start guide**: [Neovim Kickstart](https://github.com/nvim-lua/kickstart.nvim)
-   **Tmux**: `man tmux`, [Tmux Cheat Sheet](https://tmuxcheatsheet.com/)
-   **Lua**: [Programming in Lua](https://www.lua.org/pil/), [Lua User Wiki](http://lua-users.org/wiki/)
-   **Git**: [Pro Git Book](https://git-scm.com/book)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request with detailed description

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

---

**Note**: These configurations are optimized for development workflows involving JavaScript/TypeScript, web development, and general programming. Adjust the LSP servers and formatters in the Neovim configuration based on your specific development needs.
