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
| `nvim/` | LSP (mason), completion (blink.cmp), treesitter, fzf-lua, gitsigns, neogit + diffview, yazi.nvim, conform.nvim formatting |

## Zellij quick reference

> The full, always-up-to-date keybinding cheatsheet lives in [`zellij/cheatsheet.md`](zellij/cheatsheet.md)
> and opens in a floating pane with **`Ctrl + ?`** from inside zellij.

### CLI / help commands

`zellij --help` lists everything; the ones used day to day (fish abbreviations from `config.fish` in **bold**):

| Command | Abbrev | Purpose |
| --- | --- | --- |
| `zellij` | **`zj`** | Start a new session |
| `zellij attach` | **`zja`** | Attach to an existing session (`-c <name>` creates if missing) |
| `zellij list-sessions` | **`zjls`** | List active sessions (alias `zellij ls`) |
| `zn` | — | fish function: attach to / create a session named after the current dir |
| `zellij --session <name>` | — | Start a new **named** session |
| `zellij --layout <name>` | — | Start with a predefined layout |
| `zellij kill-session <name>` / `kill-all-sessions` | — | Kill one / all sessions (`k` / `ka`) |
| `zellij delete-session <name>` / `delete-all-sessions` | — | Delete exited sessions (`d` / `da`) |
| `zellij setup --check` | — | Verify config and print paths/dirs |
| `zellij run -- <cmd>` | — | Run a command in a new pane (`r`) |
| `zellij edit <file>` | — | Open a file in `$EDITOR` in a new pane (`e`) |

### Keybindings

This config starts in **`locked`** mode (keys pass straight through to your shell/editor), so the first
thing to know is the unlock key. Enter a mode (e.g. `Ctrl + p`), press the action key, then `Esc`/`Enter` to return.

**Global / modes**

| Keybinding | Action |
| --- | --- |
| `Ctrl + g` | Lock / unlock (toggle whether zellij intercepts keys) |
| `Ctrl + q` | Quit zellij |
| `Ctrl + ?` | Open this cheatsheet in a floating pane *(custom binding)* |
| `Alt + y` | Open Yazi file manager in a floating pane *(custom binding)* |
| `Ctrl + p` / `t` / `s` / `n` / `h` / `o` | Enter Pane / Tab / Scroll / Resize / Move / Session mode |

**Panes** (`Ctrl + p`)

| Keybinding | Action |
| --- | --- |
| `n` / `Alt + n` | New pane |
| `d` / `r` | Split down / right |
| `x` | Close pane |
| `f` | Toggle fullscreen zoom |
| `w` | Toggle floating |
| `z` | Toggle pane frames |
| `Tab` / `Shift + Tab` | Next / previous pane |
| `Alt + h/j/k/l` | Move focus left/down/up/right |

**Tabs** (`Ctrl + t`)

| Keybinding | Action |
| --- | --- |
| `n` / `x` / `r` | New / close / rename tab |
| `1` – `9` | Jump to tab by index |
| `h` `l` or `[` `]` | Previous / next tab |
| `Shift + [` / `]` | Move tab left / right |

**Scroll & search** (`Ctrl + s`)

| Keybinding | Action |
| --- | --- |
| `u` / `d`, `PgUp` / `PgDn` | Page up / down through scrollback |
| `/` | Search the scrollback buffer |
| `e` | Open the full scrollback in Neovim |

**Resize** (`Ctrl + n`) **& move** (`Ctrl + h`)

| Keybinding | Action |
| --- | --- |
| `h/j/k/l` | Resize toward / swap pane in that direction |
| `-` / `+` | Shrink / grow pane |

**Sessions** (`Ctrl + o`)

| Keybinding | Action |
| --- | --- |
| `d` | Detach from the session (leaves it running) |
| `w` | Open the interactive session manager |

## Git in Neovim (Neogit)

Three complementary tools, plus `lazygit` as a standalone TUI:

- **gitsigns** — inline hunk signs, stage/reset/preview a single hunk (`<leader>h*`, see `gitsigns.lua`).
- **Neogit** — a Magit-style full Git UI (status, stage, commit, branch, push/pull, log).
- **diffview** — side-by-side diffs, file history, and the 3-way view for resolving merge conflicts.

### Keybindings (leader = `Space`)

| Keybinding | Action |
| --- | --- |
| `<leader>gg` | Open Neogit status (the main hub) |
| `<leader>gc` | Commit popup |
| `<leader>gl` | Commit log |
| `<leader>gp` / `<leader>gP` | Pull / push |
| `<leader>gd` | Diff view of the working tree |
| `<leader>gm` | Open the merge-conflict resolution view |
| `<leader>gh` | File history of the current file |
| `<leader>gx` | Close the diff view |

### Inside the Neogit status buffer

| Key | Action |
| --- | --- |
| `s` / `u` | Stage / unstage the item under the cursor |
| `S` / `U` | Stage / unstage everything |
| `<Tab>` | Toggle the inline diff for an item |
| `c c` | Commit (opens message buffer; save+close with `:wq` to confirm) |
| `p` / `P` | Pull / push popup |
| `b` | Branch popup (checkout / create) |
| `l l` | Log popup |
| `<CR>` | Jump to the file under the cursor |
| `?` | Built-in help (lists every key) · `q` closes the buffer |

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
4. Save the file (`:w`). Once a file has no remaining conflict markers, stage it — press `s` on it in the
   diffview file panel (or in Neogit's status buffer).
5. Repeat for every file in the panel, then close the view with **`<leader>gx`**.
6. Finish the operation back in Neogit (`<leader>gg`): for a merge, commit with `c c`; for a rebase,
   open the rebase popup with `r` and choose **continue**. Need to bail out entirely? `r` → **abort**
   (or `:Neogit` → the relevant abort action) runs `git merge/rebase --abort`.

> Prefer the terminal? `lazygit` resolves conflicts too, and `git mergetool` will launch your
> `$EDITOR` (Neovim). The Neogit/diffview flow above is the in-editor path and is usually fastest.

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
