# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles for **Pop!_OS / Ubuntu (apt)** and **Fedora (dnf)**. Adapted from
[cetanu/dotfiles](https://github.com/cetanu/dotfiles) for Linux package managers (not Homebrew) and the
system terminal. Deliberately does **not** manage a shell, editor, or file manager (no fish, no Neovim, no
yazi) — it installs CLI tools/toolchains and symlinks a handful of app configs. `README.md` is the
authoritative, detailed reference — especially for the tmux keybindings and the Fedora/Ubuntu package-name
table. Update it when behavior changes.

## The script (the core workflow)

- `./setup.sh` — the single entry point. Installs every CLI tool/toolchain, then symlinks configs into
  place. `set -euo pipefail` bash, idempotent (safe to re-run after pulling repo changes).
  - **Run as the normal user, never with sudo.** It refuses to run if `$EUID -eq 0`. It calls `sudo`
    itself, only inside the one function that needs it (apt/dnf packages) — everything else installs
    into `$HOME`, and running the whole script as root would put rustup/pyenv/fnm/cargo tools under
    `/root` instead of the real user's home.
  - **Distro family is detected at runtime** (`dnf` → `fedora`, `apt-get` → `debian`). All package-name
    divergence lives in the `if [[ $DISTRO_FAMILY == debian ]]` block right after detection. When adding
    a package, add it to **both** branches or explain why not.
  - **Never use a vendor's `curl | bash` installer without checking whether it edits shell rc files.**
    This script itself appends one guarded block to `~/.bashrc` (rustup/pyenv/fnm/starship/zoxide init) —
    don't let a vendor installer append a second, conflicting one. pnpm and bun are installed from GitHub
    release assets via `fetch_latest_asset` for exactly this reason; starship is passed `-b ~/.local/bin`
    so it doesn't reach for `/usr/local/bin` (and thus sudo).
  - The `~/.bashrc` block is appended once, guarded by `# >>> dotfiles setup >>>` / `# <<< ... <<<`
    markers — re-running the script must not duplicate it.
  - Symlinking backs up any pre-existing non-symlink file to `<file>.bak.<timestamp>` before linking.

Because it symlinks (not copies), editing a tracked config file takes effect immediately — no reinstall
needed. Re-run `./setup.sh` after pulling changes that touch the tool-install steps; a shell restart (or
`source ~/.bashrc`) picks up PATH/init changes.

## Symlink map (defined at the bottom of `setup.sh`)

`starship.toml` → `~/.config/starship/starship.toml` · `tmux.conf` → `~/.tmux.conf` ·
`gitconfig` → `~/.gitconfig` · `ghostty/config` → `~/.config/ghostty/config`. If you add a new config
file, wire up its symlink there or it won't be installed.

## Notes

- There is no build or test suite — this is a config repo. "Verifying" a change means running the
  relevant tool, or `bash -n setup.sh` for script edits.
- Don't reintroduce fish/Neovim/yazi management here — that's an intentional simplification, not an
  oversight. If the user wants one of them back, treat it as a new feature, not a revert.
