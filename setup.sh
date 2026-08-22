#!/usr/bin/env bash
# One-shot setup for Pop!_OS/Ubuntu (apt) and Fedora (dnf): installs every tool and toolchain below,
# then symlinks this repo's configs into place.
#
#   ./setup.sh
#
# Run it as your normal user — NOT with sudo. It calls sudo itself, only for the OS package-manager
# step; everything else installs into $HOME so it must run as you, not root.
#
# Idempotent: safe to re-run after pulling repo changes.
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user, not with sudo: ./setup.sh" >&2
    echo "It calls sudo itself for the one step that needs it." >&2
    exit 1
fi

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

# --- distro packages (needs sudo) -------------------------------------------
echo "==> Installing distro packages"
if [[ $DISTRO_FAMILY == debian ]]; then
    sudo apt-get update
    sudo apt-get install -y \
        build-essential curl git unzip file fontconfig clang \
        tmux bat ripgrep fd-find fzf zoxide lsd git-delta \
        jq ffmpeg p7zip-full hyperfine xclip wl-clipboard \
        golang-go openjdk-21-jdk
    # pyenv build dependencies
    sudo apt-get install -y libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
        libsqlite3-dev libncursesw5-dev xz-utils tk-dev libxml2-dev \
        libxmlsec1-dev libffi-dev liblzma-dev
    if ! command -v gh >/dev/null; then
        echo "==> Adding GitHub CLI's apt repo (not in default Ubuntu repos)"
        sudo mkdir -p -m 755 /etc/apt/keyrings
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
            | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
        sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signing-key=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
            | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        sudo apt-get update
        sudo apt-get install -y gh
    fi
else
    # Fedora notes:
    #   - bat/fd-find ship with their upstream binary names, so no batcat/fdfind shims are needed.
    #   - p7zip was replaced by the `7zip` package.
    #   - ffmpeg-free is the Fedora-repo build; it avoids pulling in RPM Fusion.
    #   - Fedora 44 has no OpenJDK 21; java-25-openjdk-devel is the current LTS-track package.
    #   - gh is in Fedora's official repos, no extra repo needed.
    sudo dnf install -y \
        gcc gcc-c++ make patch curl git unzip file fontconfig clang \
        tmux bat ripgrep fd-find fzf zoxide lsd git-delta \
        jq ffmpeg-free 7zip hyperfine xclip wl-clipboard gh \
        golang java-25-openjdk-devel
    # pyenv build dependencies (per the pyenv wiki's Fedora list)
    sudo dnf install -y openssl-devel zlib-devel bzip2 bzip2-devel readline-devel \
        sqlite sqlite-devel ncurses-devel tk-devel libffi-devel xz xz-devel \
        libuuid-devel gdbm-devel libnsl2
fi
echo "==> Distro packages installed"

# --- everything below installs into $HOME, no sudo -------------------------
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
# `curl | bash` installers: those installers append PATH exports to whatever shell rc file they
# detect, which would step on the block this script manages in ~/.bashrc below.
echo "==> Installing pnpm"
if ! command -v pnpm >/dev/null; then
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

echo "==> Installing Starship prompt"
if ! command -v starship >/dev/null; then
    # -b ~/.local/bin: the installer defaults to /usr/local/bin, which would need sudo.
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
fi

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

# --- shell init (bash) -------------------------------------------------------
# rustup, pyenv and fnm need to be sourced into an interactive shell to be usable; pnpm/bun/starship/
# lazygit land in ~/.local/bin, which is on PATH by default on Ubuntu/Fedora. Appended once, guarded by
# markers, so re-running this script never duplicates the block.
BASHRC="$HOME/.bashrc"
if ! grep -qF "# >>> dotfiles setup >>>" "$BASHRC" 2>/dev/null; then
    echo "==> Adding tool init block to ~/.bashrc"
    cat >>"$BASHRC" <<'EOF'

# >>> dotfiles setup >>>
export PATH="$HOME/.local/bin:$PATH"
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv >/dev/null && eval "$(pyenv init -)"
export PATH="$HOME/.local/share/fnm:$PATH"
command -v fnm >/dev/null && eval "$(fnm env --use-on-cd)"
command -v starship >/dev/null && eval "$(starship init bash)"
command -v zoxide >/dev/null && eval "$(zoxide init bash)"
# <<< dotfiles setup <<<
EOF
fi

# --- symlink configs ---------------------------------------------------------
echo "==> Symlinking configs"
link() {
    local src="$1" dest="$2"
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        local backup="${dest}.bak.$(date +%s)"
        mv "$dest" "$backup"
        echo "  existing $dest backed up to $backup"
    fi
    mkdir -p "$(dirname "$dest")"
    ln -sfn "$src" "$dest"
}

link "$DOTFILES/starship.toml" ~/.config/starship/starship.toml
link "$DOTFILES/tmux.conf" ~/.tmux.conf
link "$DOTFILES/gitconfig" ~/.gitconfig
link "$DOTFILES/ghostty/config" ~/.config/ghostty/config
echo "==> Configs linked"

echo
echo "Setup complete."
echo "  - Open a new terminal (or 'source ~/.bashrc') to pick up rustup/pyenv/fnm/starship."
echo "  - Set your terminal's font to 'JetBrainsMono Nerd Font' (needed for icons used by lsd/starship)."
