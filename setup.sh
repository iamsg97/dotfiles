#!/usr/bin/env bash
# One-shot setup: installs all dependencies, then symlinks the configs into place.
# This is the single entry point to replicate the whole environment on a fresh machine.
#
#   ./setup.sh            # full run: dependencies.sh, then install.sh
#   ./setup.sh --deps     # only install dependencies (apt packages, toolchains, binaries)
#   ./setup.sh --link     # only symlink configs into ~/.config etc.
#
# Every step is idempotent, so re-running is safe.
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_deps=true
run_link=true
case "${1:-}" in
    --deps) run_link=false ;;
    --link) run_deps=false ;;
    "") ;;
    -h | --help)
        sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
    *)
        echo "Unknown option: $1 (use --deps, --link, or no argument)" >&2
        exit 1
        ;;
esac

if $run_deps; then
    echo "===> Step 1/2: installing dependencies"
    "$DOTFILES/dependencies.sh"
fi

if $run_link; then
    echo "===> Step 2/2: linking configs"
    "$DOTFILES/install.sh"
fi

echo
echo "Setup complete."
