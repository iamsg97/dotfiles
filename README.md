# dotfiles

Personal dotfiles for Pop!_OS, built with reference to
[cetanu/dotfiles](https://github.com/cetanu/dotfiles) but adapted for:

- **apt** instead of Homebrew (Pop!_OS/Ubuntu 24.04)
- the **default system terminal** (COSMIC Terminal) instead of Ghostty/Alacritty/WezTerm
- **fish** as the default login shell, **starship** prompt, **tmux** multiplexer, **yazi** file manager
- a from-scratch **Neovim** config (lazy.nvim) instead of the original author's personal modules
- toolchains for **Python, Rust, Go, TypeScript/Node and Java**

## Setup

```sh
git clone <this repo> ~/dotfiles   # or just use it in place
cd ~/dotfiles
./setup.sh          # one-shot: installs everything, then symlinks the configs
```

`setup.sh` is the single entry point — it runs `dependencies.sh` (apt packages, rustup, pyenv, fnm, go,
nvim, tmux, yazi, lazygit, starship, a Nerd Font) and then `install.sh` (symlinks configs into `~/.config`
and sets fish as your login shell). Run a phase on its own with `./setup.sh --deps` or `./setup.sh --link`.

After that:
1. Log out/in (or reboot) so the default shell change takes effect.
2. Open your terminal's settings and set the font to **JetBrainsMono Nerd Font** (needed for the icons used by `lsd` and `starship`).
3. Open `nvim` once — `lazy.nvim` bootstraps itself and Mason installs the LSPs/formatters on first launch.

Everything is idempotent — safe to re-run.

## What's in here

| File / dir | Purpose |
| --- | --- |
| `setup.sh` | One-shot entry point: runs `dependencies.sh` then `install.sh` |
| `dependencies.sh` | Installs all CLI tools and language toolchains |
| `install.sh` | Symlinks configs into `~/.config` (and `~/.tmux.conf`), sets fish as login shell |
| `config.fish` | Aliases, PATH, prompt/tool init (starship, zoxide, fnm, pyenv) |
| `starship.toml` | Minimal prompt: time, dir, git, command duration |
| `gitconfig` | `delta` pager/diff, rebase-on-pull, nvim as editor |
| `tmux.conf` | Fast escape-time + true color, vi copy mode, `\|`/`-` splits (current path), Ctrl+arrow/vi-style pane nav, Alt+arrow window switching |
| `nvim/` | LSP (mason), completion (blink.cmp), treesitter, fzf-lua, gitsigns, lazygit.nvim + diffview, yazi.nvim, conform.nvim formatting |
| `yazi/yazi.toml` | Yazi file manager config: shows hidden files/dirs by default |
| `ghostty/config` | Ghostty terminal config: `Everforest Dark Hard` theme, fish shell integration |

## tmux quick reference

The config ([`tmux.conf`](tmux.conf), symlinked to `~/.tmux.conf`) keeps the default **prefix `Ctrl + b`**
and is tuned for responsiveness and quick keyboard navigation: a 10ms escape-time (tmux's 500ms default
makes Neovim's `<Esc>` feel laggy), `tmux-256color` + RGB `terminal-overrides` for true color so the `edge`
colorscheme renders correctly, `focus-events` and `aggressive-resize` on, and vi-style copy mode. Mouse mode
is also on, so pane/window selection and resizing can be done by click and drag too.

### CLI / fish abbreviations (from `config.fish`, in **bold**)

| Command | Abbrev | Purpose |
| --- | --- | --- |
| `tmux` | **`tm`** | Start a new session |
| `tmux attach` | **`tma`** | Attach to the last session (`-t <name>` targets one) |
| `tmux list-sessions` | **`tml`** | List active sessions |
| `tn` | — | fish function: attach to / create a session named after the current dir |
| `tmux new -s <name>` | — | Start a new **named** session |
| `tmux kill-session -t <name>` / `kill-server` | — | Kill one / all sessions |

### Keybindings

Prefix is `Ctrl + b` — press it, release, then the key below. Custom bindings from `tmux.conf`:

| Keybinding | Action |
| --- | --- |
| `prefix` then `\|` | Split pane **vertically** — side by side (new pane in the current path) |
| `prefix` then `-` | Split pane **horizontally** — stacked (new pane in the current path) |
| `Ctrl + ←/→/↑/↓` | Switch panes (no prefix needed) |
| `prefix` then `h`/`j`/`k`/`l` | Switch panes, vi-style (repeatable — hold prefix once, tap the letter again) |
| `prefix` then `H`/`J`/`K`/`L` | Resize the active pane in that direction (repeatable, 5 cells per tap) |
| `Alt + ←/→` | Previous / next window (no prefix needed) |
| `prefix` then `r` | Reload `~/.tmux.conf` |
| `prefix` then `c` / `,` / `&` | New window / rename window / kill window *(tmux defaults)* |
| `prefix` then `d` | Detach (session keeps running) |
| `prefix` then `[` | Enter copy mode (vi keys: `v` to select, `y` to copy, `q` to quit) |

Windows and panes are **1-indexed** and windows renumber automatically when one is closed.

## Git in Neovim (lazygit)

Two complementary tools:

- **gitsigns** — inline hunk signs, stage/reset/preview a single hunk (`<leader>h*`, see `gitsigns.lua`).
- **lazygit.nvim** — opens the `lazygit` TUI (status, stage, commit, branch, push/pull, log) in a floating
  terminal inside Neovim, via `plugins/lazygit.lua`. It's the same `lazygit` binary as the shell's `lg`
  alias, so keybindings inside it are the standard lazygit ones (`?` for help, `q` to quit).
- **diffview** — side-by-side diffs, file history, and the 3-way view for resolving merge conflicts.

### Keybindings (leader = `Space`)

| Keybinding | Action |
| --- | --- |
| `<leader>gg` | Open LazyGit (floating terminal) |
| `<leader>gd` | Diff view of the working tree |
| `<leader>gm` | Open the merge-conflict resolution view |
| `<leader>gh` | File history of the current file |
| `<leader>gx` | Close the diff view |

### Resolving a merge conflict

When a `git merge`/`rebase`/`pull` stops with conflicts:

1. Open the resolution view: **`<leader>gm`** (`:DiffviewOpen`). The file panel (top-left) lists every
   conflicted file; selecting one shows a 3-way layout — **OURS** (your branch) on the left,
   **THEIRS** (incoming) on the right, and the working result in the center.
2. Jump between conflict regions with **`]x`** / **`[x`**.
3. For each region, choose a side (these are diffview's defaults, applied to the region under the cursor):

   | Key | Takes |
   | --- | --- |
   | `<leader>co` | **O**urs |
   | `<leader>ct` | **T**heirs |
   | `<leader>cb` | **B**ase (common ancestor) |
   | `<leader>ca` | **A**ll (keep both, in order) |
   | `dx` | Delete the region (keep neither) |

   To take one side for the **whole file** at once, use the uppercase variants in the file panel:
   `<leader>cO` / `<leader>cT` / `<leader>cB` / `<leader>cA`.
4. Save the file (`:w`). Once a file has no remaining conflict markers, stage it from lazygit
   (**`<leader>gg`**, then `a` to stage the file or `space` to toggle staging).
5. Repeat for every file in the panel, then close the view with **`<leader>gx`**.
6. Finish the operation from LazyGit (`<leader>gg`): commit with `c`, or for a rebase, continue/abort from
   its rebase menu (`m`).

> `git mergetool` also launches your `$EDITOR` (Neovim) directly on a conflicted file, if you'd rather
> skip the TUI entirely.

## Notable deviations from the reference repo

- **Ghostty is the only terminal-emulator config tracked** (`ghostty/config`, symlinked to `~/.config/ghostty/config`) — theme is `Everforest Dark Hard` (dark, low-contrast, pairs with nvim's `edge` colorscheme). No `alacritty.yml`/`wezterm.lua`.
- **tmux instead of zellij** — the multiplexer config comes from [iamsg97/dotfiles](https://github.com/iamsg97/dotfiles) (`.tmux.conf`/`.tmux.config`) and installs from apt. Its fish shortcuts are `tm` (run), `tma` (attach), `tml` (list sessions), plus the `tn` function (attach to/create a session named after the cwd).
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
