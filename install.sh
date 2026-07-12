#!/usr/bin/env bash
# Symlinks this repo's configs into place. Run dependencies.sh first.
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

rm -rf ~/.config/nvim 2>/dev/null || true
[[ -L ~/.config/nvim ]] || mkdir -p ~/.config
link "$DOTFILES/nvim" ~/.config/nvim
echo "nvim config installed"

link "$DOTFILES/config.fish" ~/.config/fish/config.fish
echo "fish config installed"

link "$DOTFILES/starship.toml" ~/.config/starship/starship.toml
echo "starship config installed"

link "$DOTFILES/tmux.conf" ~/.tmux.conf
echo "tmux config installed"

link "$DOTFILES/gitconfig" ~/.gitconfig
echo "gitconfig installed"

link "$DOTFILES/yazi/yazi.toml" ~/.config/yazi/yazi.toml
echo "yazi config installed"

link "$DOTFILES/ghostty/config" ~/.config/ghostty/config
echo "ghostty config installed"

if command -v fish >/dev/null && [[ "${SHELL:-}" != "$(command -v fish)" ]]; then
    echo "Setting fish as your default login shell (you may be asked for your password)..."
    chsh -s "$(command -v fish)"
fi

echo
echo "Done."
echo "  - Log out and back in (or reboot) for the default login shell change to take effect."
echo "  - Open nvim once: lazy.nvim will bootstrap itself and mason will install LSPs/formatters automatically."
echo "  - Set your terminal's font to 'JetBrainsMono Nerd Font' if you haven't already (Settings > Font)."
