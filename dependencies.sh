#!/usr/bin/env bash
# Installs everything config.fish/tmux/nvim configs expect.
# Adapted from https://github.com/cetanu/dotfiles for Linux package managers instead of macOS (brew).
#
# Supports two distro families, detected at runtime:
#   - debian : Pop!_OS / Ubuntu / Debian  (apt-get)
#   - fedora : Fedora / RHEL derivatives  (dnf)
#
# The privileged (package-manager) part is isolated in install_system_packages(); everything after it
# installs into $HOME and needs no sudo. The two halves can be run separately, which is useful when
# sudo has to be typed in by hand:
#
#   ./dependencies.sh --system-only   # just the distro packages (needs sudo)
#   ./dependencies.sh --user-only     # everything else (rustup, pyenv, fnm, starship, yazi, ...)
#
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

# --- distro detection -------------------------------------------------------
if command -v dnf >/dev/null; then
    DISTRO_FAMILY=fedora
elif command -v apt-get >/dev/null; then
    DISTRO_FAMILY=debian
else
    echo "Unsupported distro: neither dnf nor apt-get found." >&2
    exit 1
fi
echo "==> Detected distro family: $DISTRO_FAMILY"

# Everything that needs root. Split out so it can be run on its own (--system-only) on machines where
# sudo has to be entered interactively.
install_system_packages() {
    if [[ $DISTRO_FAMILY == debian ]]; then
        echo "==> Updating apt and installing base packages"
        sudo apt-get update
        sudo apt-get install -y \
            build-essential curl git unzip file fontconfig \
            fish tmux bat ripgrep fd-find fzf zoxide lsd git-delta \
            jq ffmpeg poppler-utils imagemagick p7zip-full luarocks chafa hyperfine \
            xclip wl-clipboard \
            golang-go openjdk-21-jdk
        # pyenv build dependencies
        sudo apt-get install -y libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
            libsqlite3-dev libncursesw5-dev xz-utils tk-dev libxml2-dev \
            libxmlsec1-dev libffi-dev liblzma-dev
    else
        # Fedora notes:
        #   - bat/fd-find ship with their upstream binary names, so no batcat/fdfind shims are needed.
        #   - p7zip was replaced by the `7zip` package.
        #   - ffmpeg-free is the Fedora-repo build; it avoids pulling in RPM Fusion.
        #   - Fedora 44 has no OpenJDK 21; java-25-openjdk-devel is the current LTS-track package.
        #   - neovim in the Fedora repos is current (unlike Ubuntu's), so it is installed here rather
        #     than being downloaded from GitHub releases.
        echo "==> Installing base packages with dnf"
        sudo dnf install -y \
            gcc gcc-c++ make patch curl git unzip file fontconfig \
            fish tmux neovim bat ripgrep fd-find fzf zoxide lsd git-delta \
            jq ffmpeg-free poppler-utils ImageMagick 7zip luarocks chafa hyperfine \
            xclip wl-clipboard \
            golang java-25-openjdk-devel
        # pyenv build dependencies (per the pyenv wiki's Fedora list)
        sudo dnf install -y openssl-devel zlib-devel bzip2 bzip2-devel readline-devel \
            sqlite sqlite-devel ncurses-devel tk-devel libffi-devel xz xz-devel \
            libuuid-devel gdbm-devel libnsl2
    fi
    echo "==> Base packages installed"
}

run_system=true
case "${1:-}" in
    --system-only) ;;
    --user-only) run_system=false ;;
    "") ;;
    *)
        echo "Unknown option: $1 (use --system-only, --user-only, or no argument)" >&2
        exit 1
        ;;
esac

if $run_system; then
    install_system_packages
    if [[ ${1:-} == --system-only ]]; then
        echo "System packages done. Run ./dependencies.sh --user-only for the rest (no sudo needed)."
        exit 0
    fi
fi

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/fonts"

if [[ $DISTRO_FAMILY == debian ]]; then
    # Debian/Ubuntu rename these to avoid clashes with other packages
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

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
if ! command -v pyenv >/dev/null && [[ ! -x "$HOME/.pyenv/bin/pyenv" ]]; then
    curl -fsSL https://pyenv.run | bash
fi
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
# Track the latest 3.12 patch release rather than a hard-pinned 3.12.0: old patch releases fail to
# build against current gcc/openssl on rolling distros. Override with PY_VERSION=x.y.z if needed.
PY_VERSION="${PY_VERSION:-$(pyenv install --list | tr -d ' ' | grep -E '^3\.12\.[0-9]+$' | tail -1)}"
if ! pyenv versions --bare | grep -q "^${PY_VERSION}\$"; then
    pyenv install "$PY_VERSION"
fi
pyenv global "$PY_VERSION"
python -m pip install --upgrade pip pipx poetry uv
uv tool install ruff --quiet 2>/dev/null || true
echo "==> Python $PY_VERSION toolchain installed"

echo "==> Installing Node via fnm"
if ! command -v fnm >/dev/null; then
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
fi
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env)"
fnm install --lts
echo "==> Node installed"

# pnpm and bun are installed from their GitHub release assets rather than via the official
# `curl | bash` installers on purpose: those installers append PATH exports to the shell rc files they
# detect, and ~/.config/fish/config.fish is a symlink into this repo — they would rewrite a tracked
# file. Installing them independently of the fnm-managed Node also means they survive a `fnm use`.
echo "==> Installing pnpm"
if ! command -v pnpm >/dev/null; then
    # The tarball is a directory (the launcher plus dist/), not a lone binary, so it is extracted into
    # PNPM_HOME and only the launcher is symlinked onto PATH.
    fetch_latest_asset "pnpm/pnpm" 'pnpm-linux-x64\.tar\.gz"' /tmp/pnpm.tar.gz
    mkdir -p "$HOME/.local/share/pnpm"
    tar -xzf /tmp/pnpm.tar.gz -C "$HOME/.local/share/pnpm"
    chmod +x "$HOME/.local/share/pnpm/pnpm"
    ln -sf "$HOME/.local/share/pnpm/pnpm" "$HOME/.local/bin/pnpm"
fi
echo "==> pnpm $(pnpm --version)"

echo "==> Installing bun"
if ! command -v bun >/dev/null; then
    # bun-linux-x64 requires AVX2; the -baseline asset is the fallback for older CPUs.
    bun_asset='bun-linux-x64\.zip"'
    grep -q avx2 /proc/cpuinfo || bun_asset='bun-linux-x64-baseline\.zip"'
    fetch_latest_asset "oven-sh/bun" "$bun_asset" /tmp/bun.zip
    rm -rf /tmp/bun-extract
    unzip -oq /tmp/bun.zip -d /tmp/bun-extract
    install -m 755 /tmp/bun-extract/*/bun "$HOME/.local/bin/bun"
    ln -sf bun "$HOME/.local/bin/bunx"
fi
echo "==> bun $(bun --version)"

echo "==> Installing gopls"
go install golang.org/x/tools/gopls@latest
echo "==> gopls installed"

echo "==> Installing Starship prompt"
if ! command -v starship >/dev/null; then
    # -b ~/.local/bin: the installer defaults to /usr/local/bin, which would need sudo. Everything
    # else in this half of the script installs under $HOME, and ~/.local/bin is on the fish PATH.
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
fi

if [[ $DISTRO_FAMILY == debian ]]; then
    echo "==> Installing Neovim (latest stable, apt's version is too old for modern plugins)"
    if [[ ! -x /opt/nvim/bin/nvim ]]; then
        fetch_latest_asset "neovim/neovim" 'linux-x86_64\.tar\.gz"' /tmp/nvim.tar.gz
        sudo rm -rf /opt/nvim
        sudo mkdir -p /opt/nvim
        sudo tar -xzf /tmp/nvim.tar.gz -C /opt/nvim --strip-components=1
        sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
    fi
fi
echo "==> $(nvim --version | head -1)"

echo "==> Installing tree-sitter CLI (nvim-treesitter 'main' branch compiles parsers with it)"
if ! command -v tree-sitter >/dev/null; then
    fetch_latest_asset "tree-sitter/tree-sitter" 'tree-sitter-linux-x64\.gz"' /tmp/tree-sitter.gz
    gunzip -f /tmp/tree-sitter.gz
    install -m 755 /tmp/tree-sitter "$HOME/.local/bin/tree-sitter"
fi
echo "==> tree-sitter $(tree-sitter --version)"

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
echo "  2. Open your terminal's settings and set the font to 'JetBrainsMono Nerd Font' (needed for icons in lsd/starship)."
echo "  3. Restart your terminal so fish, fnm, pyenv, and rustup PATH changes take effect."
