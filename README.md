# dotfiles

Personal dotfiles for Pop!_OS, built with reference to
[cetanu/dotfiles](https://github.com/cetanu/dotfiles) but adapted for:

- **apt** instead of Homebrew (Pop!_OS/Ubuntu 24.04)
- the **default system terminal** (COSMIC Terminal) instead of Ghostty/Alacritty/WezTerm
- **fish** as the default login shell, **starship** prompt, **zellij** multiplexer, **yazi** file manager
- a from-scratch **Neovim** config (lazy.nvim) instead of the original author's personal modules
- toolchains for **Python, Rust, Go, TypeScript/Node and Java**

## Setup

```sh
git clone <this repo> ~/dotfiles   # or just use it in place
cd ~/dotfiles
./dependencies.sh   # installs everything (apt packages, rustup, pyenv, fnm, go, nvim, zellij, yazi, lazygit, starship, a Nerd Font)
./install.sh        # symlinks configs into ~/.config and sets fish as your login shell
```

After that:
1. Log out/in (or reboot) so the default shell change takes effect.
2. Open your terminal's settings and set the font to **JetBrainsMono Nerd Font** (needed for the icons used by `lsd`, `starship`, and `zellij`).
3. Open `nvim` once — `lazy.nvim` bootstraps itself and Mason installs the LSPs/formatters on first launch.

Both scripts are idempotent — safe to re-run.

## What's in here

| File / dir | Purpose |
| --- | --- |
| `dependencies.sh` | Installs all CLI tools and language toolchains |
| `install.sh` | Symlinks configs into `~/.config`, sets fish as login shell |
| `config.fish` | Aliases, PATH, prompt/tool init (starship, zoxide, fnm, pyenv) |
| `starship.toml` | Minimal prompt: time, dir, git, command duration |
| `gitconfig` | `delta` pager/diff, rebase-on-pull, nvim as editor |
| `zellij/config.kdl` | Srcery theme, borderless compact layout, Yazi + cheatsheet keybinds |
| `zellij/cheatsheet.md` | Keybinding reference, opened with `Ctrl+?` inside zellij |
| `nvim/` | LSP (mason), completion (blink.cmp), treesitter, fzf-lua, gitsigns, yazi.nvim, conform.nvim formatting |

## Notable deviations from the reference repo

- **No terminal-emulator configs** (no `alacritty.yml`/`ghostty.config`/`wezterm.lua`) — you're using the system default terminal, so there's nothing to configure there beyond the font.
- **`z` belongs to zoxide**, not zellij — both tools want that mnemonic; directory-jumping muscle memory wins. Zellij's shortcuts are abbreviations instead: `zj` (run), `zja` (attach), `zjls` (list sessions), plus the `zn` function (attach to/create a session named after the cwd).
- **Dropped macOS/author-specific bits**: Homebrew/OrbStack, `opam`, the `cloudtoken` sourcing, the Wireshark.app alias, and the `dog` alias (DNS lookup tool we didn't install).
- **Trimmed the curated CLI tool list**: kept `bat`, `lsd`, `ripgrep`, `fd`, `fzf`, `zoxide`, `git-delta`, `lazygit`, `dua-cli`, `hyperfine`, `git-cliff`. Skipped the more author-specific niche tools (`jwt-ui`, `jless`, `envio`, `gitlogue`, `ducker`, `flamelens`, `csvlens`, `git-interactive-rebase-tool`).
- **Neovim is downloaded directly from GitHub releases** into `/opt/nvim` rather than installed via apt (Ubuntu's packaged version is too old for current plugins) or built from source (unnecessary on Linux — prebuilt binaries exist).
- **LSPs are split between Mason and system toolchains**: `rust-analyzer` comes from `rustup component add`, `gopls` from `go install`, everything else (`pyright`, `ruff`, `ts_ls`, `jdtls`, `lua_ls`, `bashls`, `jsonls`, `yamlls`) is managed by `mason.nvim` so it stays self-contained inside Neovim's data dir.
- **`gitconfig` is actually symlinked** by `install.sh` — the reference repo's `install.sh` never linked its own `gitconfig`.

## Languages / toolchains installed

- **Python**: `pyenv` (3.12.0 global) + `pipx`, `poetry`, `uv`, `ruff`
- **Rust**: `rustup` stable toolchain + `rust-analyzer` component
- **Go**: `golang-go` (apt) + `gopls`
- **Node/TypeScript**: `fnm` (latest LTS) + `ts_ls` via Mason
- **Java**: `openjdk-21-jdk` (apt) + `jdtls` via Mason
