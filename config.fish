# Adapted from https://github.com/cetanu/dotfiles for Pop!_OS/Linux + fish.
# Dropped: macOS-only bits (opam, cloudtoken, Wireshark.app path), niche aliases
# for tools we didn't install (dog), and the zellij "z" alias (zoxide owns "z" here).

# --- Rust CLI replacements ---
alias ls="lsd --long --human-readable --group-dirs first --gitsort --git --blocks permission,size,date,git,name --date relative --size short --permission octal"
alias lst="lsd --long --human-readable --group-dirs first --gitsort --git --blocks permission,size,date,git,name --date relative --size short --permission octal --tree --depth 2"
alias cat="bat"
alias grep="rg"

alias vim="nvim"
alias p="cd ~/Documents"
alias gitcf="git commit --amend; git push -f"
alias gitp="git checkout master; git pull"
alias gitr="git reset --hard HEAD"
alias gits="git status"
alias lg="lazygit"

# --- PATH ---
fish_add_path "$HOME/.cargo/bin"
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/go/bin"
fish_add_path "$HOME/.local/share/fnm"

set -Ux EDITOR "nvim"
set -Ux VISUAL "nvim"
set -Ux JAVA_HOME "/usr/lib/jvm/java-21-openjdk-amd64"

# --- Rust ---
if test -d "$HOME/.cargo"
    set -Ux RUSTUP_HOME "$HOME/.rustup"
end

# --- pyenv ---
set -Ux PYENV_ROOT "$HOME/.pyenv"
fish_add_path "$PYENV_ROOT/bin"
status is-interactive; and pyenv init - | source

# --- fnm (Node) ---
fnm env --use-on-cd --shell fish | source

# --- Starship prompt ---
set -x STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"
starship init fish | source

# --- zoxide ---
zoxide init fish | source

# --- Zellij integration ---
abbr -a zj "zellij"
abbr -a zja "zellij attach"
abbr -a zjls "zellij list-sessions"

function zn --description "Attach to (or create) a zellij session named after the current directory"
    if set -q ZELLIJ
        echo "Already inside a Zellij session!"
    else
        set -l session_name (basename (pwd) | tr '.' '_')
        zellij attach -c $session_name
    end
end

# --- Yazi integration: quitting yazi cd's the shell to the last visited dir ---
function y --description "Open yazi, then cd to wherever you ended up"
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        cd -- "$cwd"
    end
    rm -f -- "$tmp"
end
