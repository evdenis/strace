#!/bin/bash
# build-strace.sh — Cross-compile strace with static linking
#
# Usage: bash build-strace.sh [STRACE_VERSION] [ARCH]
#
# This script runs inside the Docker build container.
# It expects the appropriate cross-compiler packages to be installed
# and the strace source tarball already extracted in /build/.
#
# Supported architectures: arm64, arm, x86_64, x86

set -eo pipefail

STRACE_VERSION="${1:-7.0}"
ARCH="${2:-arm64}"

case "$ARCH" in
    arm64)
        CROSS_PREFIX="aarch64-linux-gnu"
        ;;
    arm)
        CROSS_PREFIX="arm-linux-gnueabihf"
        ;;
    x86_64)
        CROSS_PREFIX=""
        ;;
    x86)
        CROSS_PREFIX="i686-linux-gnu"
        ;;
    *)
        echo "ERROR: unsupported arch: $ARCH (expected: arm64, arm, x86_64, x86)"
        exit 1
        ;;
esac

if [ -n "$CROSS_PREFIX" ]; then
    CC="${CROSS_PREFIX}-gcc"
    STRIP="${CROSS_PREFIX}-strip"
    HOST_FLAG="--host=${CROSS_PREFIX}"
else
    CC="gcc"
    STRIP="strip"
    HOST_FLAG=""
fi

# -Wno-error=array-bounds: GCC >=11 raises false positives in mmsghdr.c
# that older GCC versions did not flag; strace enables -Werror by default
CFLAGS="-O2 -flto -Wno-error=array-bounds"
LDFLAGS="-static -flto"
SRCDIR="/build/strace-${STRACE_VERSION}"

echo "=== Building strace ${STRACE_VERSION} for ${ARCH} ==="
echo "  Compiler: $($CC --version | head -1)"

cd "$SRCDIR"

# shellcheck disable=SC2086
./configure \
    $HOST_FLAG \
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
