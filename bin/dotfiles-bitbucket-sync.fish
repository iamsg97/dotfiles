#!/usr/bin/env fish
# Mirror this dotfiles repo's `main` branch to Bitbucket (for machines where GitHub is blocked).
#
# Runs automatically from githooks/ (post-commit, post-merge, post-rewrite) once setup.sh has set
# `core.hooksPath`. Safe to run by hand too:  fish ~/dotfiles/bin/dotfiles-bitbucket-sync.fish
# Output goes to ~/.local/state/dotfiles-sync.log; failures also raise a macOS notification.

set -l remote bitbucket
set -l url git@bitbucket.org:iamsg97/dotfiles.git
set -l branch main
set -l log_file $HOME/.local/state/dotfiles-sync.log

set -l repo (path resolve (status dirname)/..)
cd $repo; or exit 1
mkdir -p (path dirname $log_file)

function _log --inherit-variable log_file
    echo (date '+%Y-%m-%d %H:%M:%S') $argv >>$log_file
end

# Only mirror main; feature branches stay local until merged.
test (git branch --show-current) = $branch; or exit 0

# Add the remote on first run (on the work laptop it may also be `origin` — pushing twice is harmless).
if not git remote get-url $remote >/dev/null 2>&1
    git remote add $remote $url
    _log "added remote $remote -> $url"
end

if set -l out (env GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=15" git push --quiet $remote $branch 2>&1)
    _log "pushed $branch @ "(git rev-parse --short HEAD)" to $remote"
else
    _log "push FAILED: $out"
    if command -q osascript
        osascript -e 'display notification "Push to Bitbucket failed — see ~/.local/state/dotfiles-sync.log" with title "dotfiles sync"' 2>/dev/null
    end
    exit 1
end
