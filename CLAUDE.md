# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles for **Pop!_OS / Ubuntu 24.04** with **fish** as the login shell. Adapted from
[cetanu/dotfiles](https://github.com/cetanu/dotfiles) for apt (not Homebrew), the system terminal, and a
from-scratch Neovim config. `README.md` is the authoritative, detailed reference — especially for the
tmux and Neovim/Neogit keybindings. Update it when behavior changes.

## The scripts (the core workflow)

- `./setup.sh` — the single entry point that replicates the whole setup: runs `dependencies.sh` then
  `install.sh`. `--deps` / `--link` run just one phase. Prefer editing the two underlying scripts; keep
  `setup.sh` a thin orchestrator.
- `./dependencies.sh` — installs everything: apt packages (incl. **tmux**), rustup, pyenv, fnm, go, Neovim
  (downloaded from GitHub releases into `/opt/nvim`, **not** apt), yazi, lazygit, starship, a Nerd Font, and
  language toolchains. Idempotent.
- `./install.sh` — **symlinks** configs from this repo into `~/.config` (plus `~/.gitconfig` and
  `~/.tmux.conf`), then sets fish as the login shell. Idempotent; backs up any pre-existing non-symlink file
  to `<file>.bak.<timestamp>`.

Both are `set -euo pipefail` bash. Because `install.sh` symlinks (not copies), editing files in this repo
takes effect immediately — no reinstall needed after config edits. The exceptions are `dependencies.sh`
changes (must re-run) and the login-shell change (needs a re-login).

## Symlink map (defined in `install.sh`)

`nvim/` → `~/.config/nvim` · `config.fish` → `~/.config/fish/config.fish` ·
`starship.toml` → `~/.config/starship/starship.toml` · `tmux.conf` → `~/.tmux.conf` ·
`gitconfig` → `~/.gitconfig`. If you add a new config file, wire up its symlink here or it won't be installed.

## Neovim config architecture

Entry point `nvim/init.lua` loads `core.options` + `core.keymaps`, bootstraps **lazy.nvim**, then imports the
whole `nvim/lua/plugins/` directory. Each file in `plugins/` is one self-contained lazy.nvim spec (returns a
table). To add/change a plugin, add or edit a single file there — no central registry to update.

- **Plugin versions are pinned** in `nvim/lazy-lock.json` (tracked in git). Changing plugins means this
  lockfile changes too; commit it.
- **LSPs are split across two sources** (see `plugins/lsp.lua`, `plugins/mason-tools.lua`): `rust-analyzer`
  comes from `rustup`, `gopls` from `go install`; everything else is managed by **mason.nvim**. LSP setup
  uses `vim.lsp.enable` (not `mason-lspconfig` auto-setup).
- **Formatting** is `conform.nvim` (`plugins/conform.lua`), format-on-save with `lsp_fallback`. Formatters:
  stylua (lua), ruff_format (python), gofumpt+goimports (go), prettier (js/ts/json/yaml/markdown),
  fish_indent (fish).
- Other pieces: blink.cmp (completion), nvim-treesitter (main branch), fzf-lua, gitsigns, neogit + diffview,
  yazi.nvim, which-key, lualine.

## Lua formatting

Lua files use **stylua** with `nvim/stylua.toml`: 4-space indent, 120 col width, double quotes, always call
parens. Match this style when editing Lua. `stylua nvim/` formats the tree if the binary is installed.

## Notes

- There is no build or test suite — this is a config repo. "Verifying" a change means running the relevant
  tool (e.g. open `nvim` to check a plugin loads, or `fish -c 'source config.fish'`).
- `config.fish` header documents intentional deviations from the reference repo (dropped macOS-only bits,
  `z` reserved for zoxide, etc.); README's "Notable deviations" section is the fuller list.
