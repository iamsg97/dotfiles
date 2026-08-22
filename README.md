# dotfiles

Personal dotfiles for **Pop!_OS / Ubuntu (apt)** and **Fedora (dnf)**, built with reference to
[cetanu/dotfiles](https://github.com/cetanu/dotfiles) but adapted for:

- **apt or dnf** instead of Homebrew — `setup.sh` detects the distro family at runtime
- **Ghostty** as the tracked terminal config, **starship** prompt, **tmux** multiplexer
- your normal login shell (bash) — nothing here manages or replaces it
- toolchains for **Python, Rust, Go, TypeScript/Node and Java**

## Setup

```sh
git clone <this repo> ~/dotfiles   # or just use it in place
cd ~/dotfiles
./setup.sh
```

`setup.sh` is the single entry point: it installs every CLI tool and toolchain below, then symlinks the
configs into place. Run it as your **normal user, not with sudo** — it calls `sudo` itself, only for the
one step that needs it (apt/dnf packages); everything else installs into `$HOME`.

After that:
1. Open a new terminal (or `source ~/.bashrc`) to pick up the rustup/pyenv/fnm/starship PATH changes
   `setup.sh` appends to `~/.bashrc` (in a guarded, idempotent block).
2. Open your terminal's settings and set the font to **JetBrainsMono Nerd Font** (needed for the icons
   used by `lsd` and `starship`).

Everything is idempotent — safe to re-run.

## What's in here

| File / dir | Purpose |
| --- | --- |
| `setup.sh` | Installs every CLI tool/toolchain, then symlinks configs into place |
| `starship.toml` | Minimal prompt: time, dir, git, command duration |
| `gitconfig` | `delta` pager/diff, rebase-on-pull, vim as editor |
| `tmux.conf` | Fast escape-time + true color, vi copy mode, `\|`/`-` splits (current path), Ctrl+arrow/vi-style pane nav, Alt+arrow window switching |
| `ghostty/config` | Ghostty terminal config: `Everforest Dark Hard` theme |

## tmux quick reference

The config ([`tmux.conf`](tmux.conf), symlinked to `~/.tmux.conf`) keeps the default **prefix `Ctrl + b`**
and is tuned for responsiveness and quick keyboard navigation: a 10ms escape-time (tmux's 500ms default
makes `<Esc>` feel laggy in terminal apps like vim), `tmux-256color` + RGB `terminal-overrides` for true
color, `focus-events` and `aggressive-resize` on, and vi-style copy mode. Mouse mode is also on, so
pane/window selection and resizing can be done by click and drag too.

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

The `lazygit` binary is installed and on `PATH`; run it directly inside any git repo for the status/stage/
commit/branch/push-pull/log TUI (`?` for help, `q` to quit).

## Notable deviations from the reference repo

- **Ghostty is the only terminal-emulator config tracked** (`ghostty/config`, symlinked to
  `~/.config/ghostty/config`) — theme is `Everforest Dark Hard`. No `alacritty.yml`/`wezterm.lua`.
- **No managed shell, editor, or file manager config.** This repo deliberately stays out of fish/nvim/yazi
  — it installs CLI tools and toolchains and gets out of the way. `setup.sh` appends a small guarded block
  to `~/.bashrc` (rustup/pyenv/fnm/starship/zoxide init) since those tools need to be sourced into an
  interactive shell to work; everything else that installs into `~/.local/bin` relies on that directory
  already being on `PATH` by default on Ubuntu/Fedora.
- **tmux instead of zellij** — the multiplexer config comes from
  [iamsg97/dotfiles](https://github.com/iamsg97/dotfiles) (`.tmux.conf`/`.tmux.config`) and installs from
  apt/dnf.
- **Dropped macOS/author-specific bits**: Homebrew/OrbStack, `opam`, the `cloudtoken` sourcing, the
  Wireshark.app alias, and the `dog` alias (DNS lookup tool we didn't install).
- **Trimmed the curated CLI tool list**: kept `bat`, `lsd`, `ripgrep`, `fd`, `fzf`, `zoxide`, `git-delta`,
  `lazygit`, `dua-cli`, `hyperfine`, `git-cliff`, `gh`. Skipped the more author-specific niche tools
  (`jwt-ui`, `jless`, `envio`, `gitlogue`, `ducker`, `flamelens`, `csvlens`,
  `git-interactive-rebase-tool`).
- **`gitconfig` is actually symlinked** by `setup.sh` — the reference repo's install script never linked
  its own `gitconfig`.

## Fedora vs. Ubuntu package differences

`setup.sh` handles these automatically; they're listed here because they're the non-obvious part of the
dnf branch.

| Ubuntu (apt) | Fedora (dnf) | Note |
| --- | --- | --- |
| `build-essential` | `gcc gcc-c++ make patch` | no metapackage equivalent |
| `bat`, `fd-find` | `bat`, `fd-find` | Fedora keeps the upstream binary names, so the `batcat`/`fdfind` shims into `~/.local/bin` are **apt-only** |
| `p7zip-full` | `7zip` | p7zip was retired from Fedora |
| `ffmpeg` | `ffmpeg-free` | the Fedora-repo build; avoids pulling in RPM Fusion |
| `openjdk-21-jdk` | `java-25-openjdk-devel` | Fedora 44 has no JDK 21 |
| `libssl-dev`, `zlib1g-dev`, … | `openssl-devel`, `zlib-devel`, … | pyenv build deps, per the pyenv wiki's Fedora list |
| apt: add GitHub's apt repo for `gh` | `gh` from Fedora's own repos | `gh` isn't in default Ubuntu repos |

## Languages / toolchains installed

- **Python**: `pyenv` (latest 3.12.x as global) + `pipx`, `poetry`, `uv`, `ruff`. The version is resolved
  at install time rather than hard-pinned — old patch releases stop building against current gcc/openssl.
  Override with `PY_VERSION=3.12.4 ./setup.sh`.
- **Rust**: `rustup` stable toolchain + curated cargo tools (`dua-cli`, `git-cliff`).
- **Go**: `golang-go` (apt) / `golang` (dnf).
- **Node/TypeScript**: `fnm` (latest LTS), plus **pnpm** and **bun** (with `bunx`). Both are installed
  from their GitHub release assets into `~/.local/bin` rather than via their official `curl | bash`
  installers, since those installers append PATH exports to whatever shell rc file they detect.
- **Java**: `openjdk-21-jdk` on apt, `java-25-openjdk-devel` on dnf (Fedora 44 no longer ships JDK 21).
- **C/C++**: `build-essential`/`gcc gcc-c++` plus `clang`.
