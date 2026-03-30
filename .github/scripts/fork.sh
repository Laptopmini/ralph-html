#!/bin/bash

# ==============================================================================
# FORK REPO: Create a fork of the current repo within your own organization,
# to be branched out as a starting point for further PRD-driven development.
# Usage: ./fork.sh <new-repo-name>
# ==============================================================================

set -euo pipefail

if [[ -z "${1:-}" ]]; then
  echo "Usage: $0 <new-repo-name>" >&2
  exit 1
fi

NAME="$1"
NAMESPACE="Laptopmini"
UPSTREAM=$(git remote get-url origin)
BARE_CLONE="temp-repo-bare-clone"
NEW_REPO="https://github.com/$NAMESPACE/$NAME.git"

echo "Cloning $UPSTREAM as $NAME..."

# Navigate to parent directory
cd ..

# Create a bare clone of the upstream repo
git clone --bare "$UPSTREAM" "$BARE_CLONE"

# Create a new empty repo on GitHub
gh repo create "$NAMESPACE/$NAME" --public

# Mirror-push everything to the new repo
cd "$BARE_CLONE"
git push --mirror "$NEW_REPO"

# Remove the local bare clone
cd ..
rm -rf "$BARE_CLONE"

# Clone the "fork"
git clone "$NEW_REPO"

# Add the original repo as a remote
cd "$NAME"
git remote add upstream "$UPSTREAM"

if command -v code &>/dev/null; then
  code .
fi

echo "✅ Done!."