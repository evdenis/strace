#!/usr/bin/env bash
#
# bump-strace.sh — Check for new upstream strace release and update the module.
#
# If a new strace version is available, this script:
#   1. Updates STRACE_VERSION in Dockerfile and scripts/build-strace.sh
#   2. Rebuilds and tests all architecture binaries
#   3. Bumps module.prop (version, versionCode, description)
#   4. Creates a git commit and tag
#   5. Writes the new tag to .new-tag for the CI workflow to push
#
# Requires: gh (GitHub CLI), docker, make, qemu-user-static (for cross-arch tests)
# Environment: GH_TOKEN must be set for gh api calls
#
# Usage: bash scripts/bump-strace.sh

set -euo pipefail

# --- Detect latest upstream release ---

LATEST=$(gh api repos/strace/strace/releases/latest --jq '.tag_name' | sed 's/^v//')
if [ -z "$LATEST" ]; then
    echo "ERROR: Failed to detect latest strace release"
    exit 1
fi

CURRENT=$(grep '^ARG STRACE_VERSION=' Dockerfile | cut -d= -f2)
if [ -z "$CURRENT" ]; then
    echo "ERROR: Failed to parse STRACE_VERSION from Dockerfile"
    exit 1
fi

if [ "$LATEST" = "$CURRENT" ]; then
    echo "Already on strace $CURRENT — nothing to do"
    exit 0
fi

echo "=== New strace release: $CURRENT → $LATEST ==="

# --- Install QEMU for cross-arch tests (if not already present) ---

if ! command -v qemu-aarch64-static >/dev/null 2>&1; then
    echo "Installing qemu-user-static..."
    sudo apt-get update && sudo apt-get install -y qemu-user-static
fi

# --- Update STRACE_VERSION in build files ---

sed -i "s/^ARG STRACE_VERSION=.*/ARG STRACE_VERSION=${LATEST}/" Dockerfile
sed -i "s/STRACE_VERSION=\"\${1:-[^}]*}\"/STRACE_VERSION=\"\${1:-${LATEST}}\"/" scripts/build-strace.sh

grep -qF "ARG STRACE_VERSION=${LATEST}" Dockerfile
grep -qF "\${1:-${LATEST}}" scripts/build-strace.sh
echo "Updated STRACE_VERSION in Dockerfile and scripts/build-strace.sh"

# --- Build and test ---

make build-strace-all
make test-strace-all

# --- Bump module.prop ---

CUR_VER=$(grep '^version=' module.prop | cut -d= -f2)
CUR_CODE=$(grep '^versionCode=' module.prop | cut -d= -f2)

NEW_CODE=$((CUR_CODE + 1))
MAJOR=$(echo "$CUR_VER" | sed 's/^v//' | cut -d. -f1)
case "$CUR_VER" in
    *.*) MINOR="${CUR_VER#v*.}" ;;
    *)   MINOR="" ;;
esac
if [ -z "$MINOR" ]; then
    NEW_VER="v${MAJOR}.1"
else
    NEW_VER="v${MAJOR}.$((MINOR + 1))"
fi

sed -i "s/^version=.*/version=${NEW_VER}/" module.prop
sed -i "s/^versionCode=.*/versionCode=${NEW_CODE}/" module.prop
sed -i "s/Strace v${CURRENT}/Strace v${LATEST}/" module.prop

echo "Module version: $CUR_VER → $NEW_VER (versionCode: $CUR_CODE → $NEW_CODE)"

# --- Commit and tag ---

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add Dockerfile scripts/build-strace.sh module.prop strace-bin/
git commit -m "build: bump strace from v${CURRENT} to v${LATEST}"
git tag "$NEW_VER"

# Signal to the CI workflow that there's a new tag to push
echo "$NEW_VER" > .new-tag
echo "=== Ready to push: $NEW_VER ==="
