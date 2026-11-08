# Carried over from ~/.zshrc

# Homebrew (sets PATH, MANPATH, HOMEBREW_* vars)
eval (/opt/homebrew/bin/brew shellenv fish)

# PATH additions (fish_add_path prepends and de-duplicates)
fish_add_path /opt/homebrew/opt/openjdk@21/bin
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.local/share/fnm

# Cargo
test -f $HOME/.cargo/env.fish; and source $HOME/.cargo/env.fish

# pyenv
set -gx PYENV_ROOT $HOME/.pyenv
test -d $PYENV_ROOT/bin; and fish_add_path $PYENV_ROOT/bin
type -q pyenv; and pyenv init - | source

# fnm
type -q fnm; and fnm env --use-on-cd | source

# pnpm
set -gx PNPM_HOME $HOME/.local/share/pnpm
fish_add_path $PNPM_HOME

# bun
set -gx BUN_INSTALL $HOME/.bun
test -d $BUN_INSTALL/bin; and fish_add_path $BUN_INSTALL/bin

# zoxide
type -q zoxide; and zoxide init fish | source
