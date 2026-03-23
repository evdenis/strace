#!/bin/bash
# build-strace.sh — Cross-compile strace for ARM64 with static linking
#
# Usage: bash build-strace.sh [STRACE_VERSION]
#
# This script runs inside the Docker build container.
# It expects aarch64-linux-gnu cross-compiler packages to be installed
# and the strace source tarball already extracted in /build/.

set -eo pipefail

STRACE_VERSION="${1:-5.9}"
CROSS_PREFIX="aarch64-linux-gnu"
CC="${CROSS_PREFIX}-gcc"
STRIP="${CROSS_PREFIX}-strip"
# -Wno-error=array-bounds: GCC >=11 raises false positives in mmsghdr.c
# that older GCC versions did not flag; strace enables -Werror by default
CFLAGS="-O2 -flto -Wno-error=array-bounds"
LDFLAGS="-static -flto"
SRCDIR="/build/strace-${STRACE_VERSION}"

echo "=== Building strace ${STRACE_VERSION} for aarch64 ==="
echo "  Compiler: $($CC --version | head -1)"

cd "$SRCDIR"

./configure \
    --host="${CROSS_PREFIX}" \
    --enable-mpers=no \
    CC="$CC" \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS"

make -j"$(nproc)"

# strace v5.9 places the binary at the build root; v6+ uses src/strace
if [ -f src/strace ]; then
    STRACE_BIN=src/strace
else
    STRACE_BIN=strace
fi

"$STRIP" "$STRACE_BIN"

mkdir -p /build/out
cp "$STRACE_BIN" /build/out/strace

echo "=== Build complete ==="
ls -la /build/out/strace
file /build/out/strace
