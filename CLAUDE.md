# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles for **Pop!_OS / Ubuntu (apt)**, **Fedora (dnf)** and **macOS (Homebrew)**. Adapted from
[cetanu/dotfiles](https://github.com/cetanu/dotfiles) for Linux package managers (not Homebrew) and the
system terminal. Deliberately does **not** manage Neovim or a file manager (no yazi); the one managed editor is
terminal Emacs (`emacs/`, added at the user's request); fish is
installed and configured on macOS only — it installs CLI tools/toolchains and symlinks a handful of app configs. `README.md` is the
authoritative, detailed reference — especially for the tmux keybindings and the Fedora/Ubuntu package-name
table. Update it when behavior changes.

## The script (the core workflow)

- `./setup.sh` — the single entry point. Installs every CLI tool/toolchain, then symlinks configs into
  place. `set -euo pipefail` bash, idempotent (safe to re-run after pulling repo changes).
  - **Run as the normal user, never with sudo.** It refuses to run if `$EUID -eq 0`. It calls `sudo`
    itself, only inside the one function that needs it (apt/dnf packages) — everything else installs
    into `$HOME`, and running the whole script as root would put rustup/pyenv/fnm/cargo tools under
    `/root` instead of the real user's home.
  - **Distro family is detected at runtime** (`Darwin` → `macos`, `dnf` → `fedora`, `apt-get` → `debian`).
    All package-name divergence lives in the `macos`/`debian`/else block right after detection. When adding
    a package, add it to **all three** branches or explain why not. The macOS path runs under `/bin/bash`
    3.2 — no bash 4+ features there, and no `fetch_latest_asset` (its empty-array expansion trips `set -u`).
  - The rc block goes to `~/.bashrc` on Linux and `~/.zshrc` on macOS.
  - **Never use a vendor's `curl | bash` installer without checking whether it edits shell rc files.**
    This script itself appends one guarded block to `~/.bashrc` (rustup/pyenv/fnm/zoxide init) —
    don't let a vendor installer append a second, conflicting one. pnpm and bun are installed from GitHub
    release assets via `fetch_latest_asset` for exactly this reason.
  - The `~/.bashrc` block is appended once, guarded by `# >>> dotfiles setup >>>` / `# <<< ... <<<`
    markers — re-running the script must not duplicate it.
  - Symlinking backs up any pre-existing non-symlink file to `<file>.bak.<timestamp>` before linking.

Because it symlinks (not copies), editing a tracked config file takes effect immediately — no reinstall
needed. Re-run `./setup.sh` after pulling changes that touch the tool-install steps; a shell restart (or
`source ~/.bashrc`) picks up PATH/init changes.

## Symlink map (defined at the bottom of `setup.sh`)

`tmux.conf` → `~/.tmux.conf` · `gitconfig` → `~/.gitconfig` ·
`fish/config.fish` → `~/.config/fish/config.fish` · `emacs/init.el` + `emacs/early-init.el` → `~/.emacs.d/`
(only those two files; `elpa/`, `tree-sitter/` stay local). Ghostty is intentionally left on its built-in defaults (no tracked config). If you add a new config
file, wire up its symlink there or it won't be installed.

## Notes

- There is no build or test suite — this is a config repo. "Verifying" a change means running the
  relevant tool, or `bash -n setup.sh` for script edits.
- Don't reintroduce Neovim/yazi management here — that's an intentional simplification, not an
  oversight. fish was re-added (macOS) and Emacs added at the user's request; anything further is a new feature.
- Emacs: the user uses lazygit, not magit — don't add magit. Never suggest `package-autoremove` (no
  `package-selected-packages`, so it would remove everything). Emacs itself and the language servers are
  not installed by `setup.sh` (documented in README's Emacs section).
- Starship was removed on purpose (the user dropped its init line from `~/.zshrc`); zsh uses its default
  prompt. Same rule: re-adding it is a new feature.
