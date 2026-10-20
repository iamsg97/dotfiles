#!/usr/bin/env bash
# One-shot setup for Pop!_OS/Ubuntu (apt), Fedora (dnf) and macOS (Homebrew): installs every tool and
# toolchain below, then symlinks this repo's configs into place.
#
#   ./setup.sh
#
# Run it as your normal user — NOT with sudo. On Linux it calls sudo itself, only for the OS
# package-manager step; everything else installs into $HOME so it must run as you, not root. On macOS
# it needs no sudo at all, but Homebrew must already be installed (https://brew.sh).
#
# Must stay bash 3.2-compatible on the macOS path (that's /bin/bash there).
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
    local url="" auth_header=()

    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        auth_header=(-H "Authorization: Bearer $GITHUB_TOKEN")
    elif command -v gh >/dev/null 2>&1; then
        local gh_token
        gh_token="$(gh auth token 2>/dev/null || true)"
        if [[ -n "$gh_token" ]]; then
            auth_header=(-H "Authorization: Bearer $gh_token")
        fi
    fi

    # 1. Try GitHub API
    local api_json
    if api_json=$(curl -fsSL --retry 3 --retry-delay 1 "${auth_header[@]}" "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null); then
        url=$(echo "$api_json" | grep "browser_download_url" | grep -E "$pattern" | head -1 | cut -d '"' -f4 || true)
    fi

    # 2. Fallback: Query release redirect if API was rate-limited or failed
    if [[ -z "$url" ]]; then
        local tag
        tag=$(curl -fsSL --retry 3 --retry-delay 1 -o /dev/null -w "%{url_effective}" "https://github.com/${repo}/releases/latest" 2>/dev/null | awk -F'/' '{print $NF}')
        if [[ -n "$tag" && "$tag" != "releases" && "$tag" != "latest" ]]; then
            local asset_page
            if asset_page=$(curl -fsSL --retry 3 "https://github.com/${repo}/releases/expanded_assets/${tag}" 2>/dev/null); then
                local clean_pat
                clean_pat=$(echo "$pattern" | sed 's/\\"//g; s/"//g')
                local asset_path
                asset_path=$(echo "$asset_page" | grep -oE "/${repo}/releases/download/${tag}/[^\"']+" | grep -E "$clean_pat" | head -1 || true)
                if [[ -n "$asset_path" ]]; then
                    url="https://github.com${asset_path}"
                fi
            fi
        fi
    fi

    if [[ -z "$url" ]]; then
        echo "Could not find a release asset for ${repo} matching ${pattern}" >&2
        return 1
    fi
    curl -fsSL --retry 3 --retry-delay 1 "$url" -o "$out"
}

# --- distro detection -------------------------------------------------------
if [[ "$(uname -s)" == Darwin ]]; then
    DISTRO_FAMILY=macos
elif command -v dnf >/dev/null; then
    DISTRO_FAMILY=fedora
elif command -v apt-get >/dev/null; then
    DISTRO_FAMILY=debian
else
    echo "Unsupported distro: neither dnf nor apt-get found." >&2
    exit 1
fi
echo "==> Detected distro family: $DISTRO_FAMILY"

# --- distro packages (needs sudo on Linux) ----------------------------------
echo "==> Installing distro packages"
if [[ $DISTRO_FAMILY == macos ]]; then
    # macOS notes:
    #   - Xcode Command Line Tools stand in for build-essential (clang, make, git).
    #   - Homebrew also covers what Linux pulls from installers/release assets: pyenv, fnm, pnpm, bun,
    #     starship, lazygit and the Nerd Font. None of their formulae touch shell rc files.
    #   - openjdk@21 is keg-only; the ~/.zshrc block below puts it on PATH.
    #   - xclip/wl-clipboard are skipped — macOS has pbcopy/pbpaste built in.
    if ! xcode-select -p >/dev/null 2>&1; then
        echo "Xcode Command Line Tools missing. Run 'xcode-select --install', then re-run ./setup.sh" >&2
        exit 1
    fi
    if ! command -v brew >/dev/null; then
        for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
            [[ -x "$b" ]] && eval "$("$b" shellenv)" && break
        done
    fi
    if ! command -v brew >/dev/null; then
        echo "Homebrew not found. Install it from https://brew.sh, then re-run ./setup.sh" >&2
        exit 1
    fi
    brew install \
        curl git unzip \
        tmux bat ripgrep fd fzf zoxide lsd git-delta \
        jq ffmpeg sevenzip hyperfine \
        go openjdk@21 gh \
        pyenv fnm pnpm oven-sh/bun/bun starship lazygit
    # pyenv build dependencies (per the pyenv wiki's macOS list). openssl@3, not plain `openssl`:
    # that now resolves to openssl@4, whose API Python 3.12's _ssl module doesn't compile against.
    brew install openssl@3 readline sqlite3 xz zlib tcl-tk
    brew install --cask font-jetbrains-mono-nerd-font
elif [[ $DISTRO_FAMILY == debian ]]; then
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
if ! command -v rustup >/dev/null && [[ ! -x "$HOME/.cargo/bin/rustup" ]]; then
    # --no-modify-path: the rc block below already sources ~/.cargo/env.
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi
# shellcheck source=/dev/null
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Install cargo-binstall for fast pre-compiled binary installs (avoids compiling from scratch)
if ! command -v cargo-binstall >/dev/null && [[ ! -x "$HOME/.cargo/bin/cargo-binstall" ]]; then
    curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash 2>/dev/null || true
fi

for pkg in dua-cli git-cliff; do
    if ! cargo install --list 2>/dev/null | grep -q "^${pkg} "; then
        if command -v cargo-binstall >/dev/null; then
            cargo binstall --no-confirm "$pkg" || cargo install "$pkg"
        else
            cargo install "$pkg"
        fi
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
    # python-build otherwise picks the newest Homebrew openssl (openssl@4), which 3.12 can't build with.
    [[ $DISTRO_FAMILY == macos ]] && export PYTHON_BUILD_HOMEBREW_OPENSSL_FORMULA=openssl@3
    pyenv install "$PY_VERSION"
fi
pyenv global "$PY_VERSION"
python -m pip install --upgrade pip pipx poetry uv
uv tool install ruff --quiet 2>/dev/null || true
echo "==> Python $PY_VERSION toolchain installed"

echo "==> Installing Node via fnm"
if ! command -v fnm >/dev/null && [[ ! -x "$HOME/.local/share/fnm/fnm" ]]; then
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
fi
export PATH="$HOME/.local/share/fnm:$PATH"
if [[ -x "$HOME/.local/share/fnm/fnm" ]]; then
    ln -sf "$HOME/.local/share/fnm/fnm" "$HOME/.local/bin/fnm"
fi
eval "$(fnm env)"
fnm install --lts
fnm default lts-latest
eval "$(fnm env --use-on-cd)"
echo "==> Node $(node --version) + npm $(npm --version) installed"

# pnpm and bun are installed from their GitHub release assets rather than via the official
# `curl | bash` installers: those installers append PATH exports to whatever shell rc file they
# detect, which would step on the block this script manages in ~/.bashrc below.
echo "==> Installing pnpm"
if ! command -v pnpm >/dev/null && [[ ! -x "$HOME/.local/bin/pnpm" ]]; then
    fetch_latest_asset "pnpm/pnpm" 'pnpm-linux-x64\.tar\.gz' /tmp/pnpm.tar.gz
    mkdir -p "$HOME/.local/share/pnpm"
    tar -xzf /tmp/pnpm.tar.gz -C "$HOME/.local/share/pnpm"
    chmod +x "$HOME/.local/share/pnpm/pnpm"
    ln -sf "$HOME/.local/share/pnpm/pnpm" "$HOME/.local/bin/pnpm"
    rm -f /tmp/pnpm.tar.gz
fi
echo "==> pnpm $(pnpm --version 2>/dev/null || "$HOME/.local/bin/pnpm" --version)"

echo "==> Installing bun"
if ! command -v bun >/dev/null && [[ ! -x "$HOME/.local/bin/bun" ]]; then
    # bun-linux-x64 requires AVX2; the -baseline asset is the fallback for older CPUs.
    bun_asset='bun-linux-x64\.zip'
    grep -q avx2 /proc/cpuinfo || bun_asset='bun-linux-x64-baseline\.zip'
    fetch_latest_asset "oven-sh/bun" "$bun_asset" /tmp/bun.zip
    rm -rf /tmp/bun-extract
    unzip -oq /tmp/bun.zip -d /tmp/bun-extract
    install -m 755 /tmp/bun-extract/*/bun "$HOME/.local/bin/bun"
    ln -sf bun "$HOME/.local/bin/bunx"
    rm -rf /tmp/bun.zip /tmp/bun-extract
fi
echo "==> bun $(bun --version 2>/dev/null || "$HOME/.local/bin/bun" --version)"

echo "==> Installing Starship prompt"
if ! command -v starship >/dev/null && [[ ! -x "$HOME/.local/bin/starship" ]]; then
    # -b ~/.local/bin: the installer defaults to /usr/local/bin, which would need sudo.
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
fi
echo "==> Starship prompt installed"

echo "==> Installing Lazygit"
if ! command -v lazygit >/dev/null && [[ ! -x "$HOME/.local/bin/lazygit" ]]; then
    fetch_latest_asset "jesseduffield/lazygit" 'lazygit_.*_linux_x86_64\.tar\.gz' /tmp/lazygit.tar.gz
    tar -xzf /tmp/lazygit.tar.gz -C "$HOME/.local/bin" lazygit
    chmod +x "$HOME/.local/bin/lazygit"
    rm -f /tmp/lazygit.tar.gz
fi
echo "==> Lazygit installed"

echo "==> Installing JetBrainsMono Nerd Font"
# macOS gets it from the Homebrew cask above.
if [[ $DISTRO_FAMILY != macos && ! -f "$HOME/.local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf" ]]; then
    fetch_latest_asset "ryanoasis/nerd-fonts" 'JetBrainsMono\.zip' /tmp/jbm-nerd.zip
    unzip -oq /tmp/jbm-nerd.zip -d "$HOME/.local/share/fonts" "*.ttf"
    fc-cache -f "$HOME/.local/share/fonts" >/dev/null
    rm -f /tmp/jbm-nerd.zip
fi
echo "==> Nerd Font installed"

# --- shell init (bash on Linux, zsh on macOS) --------------------------------
# rustup, pyenv and fnm need to be sourced into an interactive shell to be usable; pnpm/bun/starship/
# lazygit land in ~/.local/bin, which is on PATH by default on Ubuntu/Fedora. Appended once, guarded by
# markers, so re-running this script never duplicates the block.
if [[ $DISTRO_FAMILY == macos ]]; then
    RCFILE="$HOME/.zshrc"
    RCSHELL=zsh
    BREW_PREFIX="$(brew --prefix)"
else
    RCFILE="$HOME/.bashrc"
    RCSHELL=bash
fi
if ! grep -qF "# >>> dotfiles setup >>>" "$RCFILE" 2>/dev/null; then
    echo "==> Adding tool init block to $RCFILE"
    {
        echo
        echo "# >>> dotfiles setup >>>"
        if [[ $DISTRO_FAMILY == macos ]]; then
            echo "eval \"\$($BREW_PREFIX/bin/brew shellenv)\""
            echo "export PATH=\"$BREW_PREFIX/opt/openjdk@21/bin:\$PATH\""
        fi
        cat <<'EOF'
export PATH="$HOME/.local/bin:$PATH"
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv >/dev/null && eval "$(pyenv init -)"
export PATH="$HOME/.local/share/fnm:$PATH"
command -v fnm >/dev/null && eval "$(fnm env --use-on-cd)"
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
export BUN_INSTALL="$HOME/.bun"
[[ -d "$BUN_INSTALL/bin" ]] && export PATH="$BUN_INSTALL/bin:$PATH"
EOF
        echo "command -v starship >/dev/null && eval \"\$(starship init $RCSHELL)\""
        echo "command -v zoxide >/dev/null && eval \"\$(zoxide init $RCSHELL)\""
        echo "# <<< dotfiles setup <<<"
    } >>"$RCFILE"
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

link "$DOTFILES/starship.toml" ~/.config/starship.toml
link "$DOTFILES/tmux.conf" ~/.tmux.conf
link "$DOTFILES/gitconfig" ~/.gitconfig
echo "==> Configs linked"

echo
echo "Setup complete."
echo "  - Open a new terminal (or 'source $RCFILE') to pick up rustup/pyenv/fnm/starship."
echo "  - Set your terminal's font to 'JetBrainsMono Nerd Font' (needed for icons used by lsd/starship)."
