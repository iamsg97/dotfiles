#!/usr/bin/env bash
# Installs everything config.fish/zellij/nvim configs expect.
# Adapted from https://github.com/cetanu/dotfiles for Pop!_OS/Ubuntu (apt) instead of macOS (brew).
set -euo pipefail

fetch_latest_asset() {
    local repo="$1" pattern="$2" out="$3"
    local url
    url=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
        | grep "browser_download_url" | grep -E "$pattern" | head -1 | cut -d '"' -f4)
    if [[ -z "$url" ]]; then
        echo "Could not find a release asset for ${repo} matching ${pattern}" >&2
        return 1
    fi
    curl -fsSL "$url" -o "$out"
}

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/fonts"

echo "==> Updating apt and installing base packages"
sudo apt-get update
sudo apt-get install -y \
    build-essential curl git unzip file fontconfig \
    fish bat ripgrep fd-find fzf zoxide lsd git-delta \
    jq ffmpeg poppler-utils imagemagick p7zip-full luarocks chafa hyperfine \
    xclip wl-clipboard \
    golang-go openjdk-21-jdk

# Debian/Ubuntu rename these to avoid clashes with other packages
ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
echo "==> Base packages installed"

echo "==> Installing Rust toolchain"
if ! command -v rustup >/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
# shellcheck source=/dev/null
source "$HOME/.cargo/env"
rustup component add rust-analyzer
for pkg in dua-cli git-cliff; do
    if ! cargo install --list | grep -q "^${pkg} "; then
        cargo install "$pkg"
    fi
done
echo "==> Rust toolchain + curated cargo tools installed"

echo "==> Installing pyenv + Python"
if ! command -v pyenv >/dev/null; then
    sudo apt-get install -y libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
        libsqlite3-dev libncursesw5-dev xz-utils tk-dev libxml2-dev \
        libxmlsec1-dev libffi-dev liblzma-dev
    curl -fsSL https://pyenv.run | bash
fi
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
PY_VERSION=3.12.0
if ! pyenv versions --bare | grep -q "^${PY_VERSION}\$"; then
    pyenv install "$PY_VERSION"
fi
pyenv global "$PY_VERSION"
python -m pip install --upgrade pip pipx poetry uv
uv tool install ruff --quiet 2>/dev/null || true
echo "==> Python toolchain installed"

echo "==> Installing Node via fnm"
if ! command -v fnm >/dev/null; then
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
fi
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env)"
fnm install --lts
echo "==> Node installed"

echo "==> Installing gopls"
go install golang.org/x/tools/gopls@latest
echo "==> gopls installed"

echo "==> Installing Starship prompt"
if ! command -v starship >/dev/null; then
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
fi

echo "==> Installing Neovim (latest stable, apt's version is too old for modern plugins)"
if [[ ! -x /opt/nvim/bin/nvim ]]; then
    fetch_latest_asset "neovim/neovim" 'linux-x86_64\.tar\.gz"' /tmp/nvim.tar.gz
    sudo rm -rf /opt/nvim
    sudo mkdir -p /opt/nvim
    sudo tar -xzf /tmp/nvim.tar.gz -C /opt/nvim --strip-components=1
    sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
fi
echo "==> $(nvim --version | head -1)"

echo "==> Installing tree-sitter CLI (nvim-treesitter 'main' branch compiles parsers with it)"
if ! command -v tree-sitter >/dev/null; then
    fetch_latest_asset "tree-sitter/tree-sitter" 'tree-sitter-linux-x64\.gz"' /tmp/tree-sitter.gz
    gunzip -f /tmp/tree-sitter.gz
    install -m 755 /tmp/tree-sitter "$HOME/.local/bin/tree-sitter"
fi
echo "==> tree-sitter $(tree-sitter --version)"

echo "==> Installing Zellij"
if ! command -v zellij >/dev/null; then
    fetch_latest_asset "zellij-org/zellij" 'zellij-x86_64-unknown-linux-musl\.tar\.gz"' /tmp/zellij.tar.gz
    tar -xzf /tmp/zellij.tar.gz -C "$HOME/.local/bin"
    chmod +x "$HOME/.local/bin/zellij"
fi
echo "==> Zellij installed"

echo "==> Installing Yazi"
if ! command -v yazi >/dev/null; then
    fetch_latest_asset "sxyazi/yazi" 'yazi-x86_64-unknown-linux-gnu\.zip"' /tmp/yazi.zip
    rm -rf /tmp/yazi-extract
    unzip -oq /tmp/yazi.zip -d /tmp/yazi-extract
    cp /tmp/yazi-extract/*/yazi "$HOME/.local/bin/"
    cp /tmp/yazi-extract/*/ya "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/yazi" "$HOME/.local/bin/ya"
fi
echo "==> Yazi installed"

echo "==> Installing Lazygit"
if ! command -v lazygit >/dev/null; then
    fetch_latest_asset "jesseduffield/lazygit" 'lazygit_.*_linux_x86_64\.tar\.gz"' /tmp/lazygit.tar.gz
    tar -xzf /tmp/lazygit.tar.gz -C "$HOME/.local/bin" lazygit
    chmod +x "$HOME/.local/bin/lazygit"
fi
echo "==> Lazygit installed"

echo "==> Installing JetBrainsMono Nerd Font"
if [[ ! -f "$HOME/.local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf" ]]; then
    fetch_latest_asset "ryanoasis/nerd-fonts" 'JetBrainsMono\.zip"' /tmp/jbm-nerd.zip
    unzip -oq /tmp/jbm-nerd.zip -d "$HOME/.local/share/fonts" "*.ttf"
    fc-cache -f "$HOME/.local/share/fonts" >/dev/null
fi
echo "==> Nerd Font installed"

echo
echo "All dependencies installed."
echo "Next steps:"
echo "  1. Run ./install.sh to symlink the configs into place."
echo "  2. Open your terminal's settings and set the font to 'JetBrainsMono Nerd Font' (needed for icons in lsd/starship/zellij)."
echo "  3. Restart your terminal so fish, fnm, pyenv, and rustup PATH changes take effect."
