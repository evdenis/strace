#!/usr/bin/env bash
#
# Binary sanity tests for the strace binary.
# Usage: ./tests/test-strace-binary.sh [path/to/strace] [arch]
#   arch: arm64 (default)
#

set -euo pipefail

BINARY="${1:-system/bin/strace}"
ARCH="${2:-arm64}"

if [[ ! -f "$BINARY" ]]; then
    echo "ERROR: binary not found: $BINARY"
    exit 1
fi

case "$ARCH" in
    arm64)
        ELF_PATTERN="ELF 64-bit LSB executable, ARM aarch64"
        MACHINE_PATTERN="Machine:.*AArch64"
        QEMU_BIN="qemu-aarch64-static"
        ;;
    *)
        echo "ERROR: unsupported arch: $ARCH (expected: arm64)"
        exit 1
        ;;
esac

echo "Testing $BINARY (expected arch: $ARCH)"
echo ""

PASS=0
FAIL=0

pass() {
    echo "PASS: $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "FAIL: $1"
    FAIL=$((FAIL + 1))
}

FILE_OUT="$(file "$BINARY")"

# 1. ELF format + correct architecture
if echo "$FILE_OUT" | grep -q "$ELF_PATTERN"; then
    pass "$ELF_PATTERN"
else
    fail "$ELF_PATTERN — got: $FILE_OUT"
fi

# 2. Statically linked
if echo "$FILE_OUT" | grep -q "statically linked"; then
    pass "statically linked"
else
    fail "statically linked — got: $FILE_OUT"
fi

# 3. Stripped
if echo "$FILE_OUT" | grep -q "stripped" && ! echo "$FILE_OUT" | grep -q "not stripped"; then
    pass "stripped"
else
    fail "stripped — got: $FILE_OUT"
fi

# 4. No dynamic section (no NEEDED libs)
READELF_D="$(readelf -d "$BINARY" 2>&1 || true)"
if echo "$READELF_D" | grep -qi "no dynamic section\|there is no dynamic section"; then
    pass "no dynamic section"
else
    fail "no dynamic section — got: $READELF_D"
fi

# 5. ELF type is EXEC (not DYN/shared)
READELF_H="$(readelf -h "$BINARY")"
if echo "$READELF_H" | grep -q "Type:.*EXEC"; then
    pass "ELF type is EXEC"
else
    fail "ELF type is EXEC — got: $(echo "$READELF_H" | grep 'Type:')"
fi

# 6. Machine matches expected architecture
if echo "$READELF_H" | grep -q "$MACHINE_PATTERN"; then
    pass "machine matches $ARCH"
else
    fail "machine matches $ARCH — got: $(echo "$READELF_H" | grep 'Machine:')"
fi

# 7. Reasonable file size (500KB–5MB)
SIZE="$(stat --format='%s' "$BINARY" 2>/dev/null || stat -f '%z' "$BINARY")"
MIN=$((500 * 1024))
MAX=$((5 * 1024 * 1024))
if [[ "$SIZE" -ge "$MIN" && "$SIZE" -le "$MAX" ]]; then
    pass "file size is reasonable ($(( SIZE / 1024 ))KB)"
else
    fail "file size out of range: $SIZE bytes (expected ${MIN}–${MAX})"
fi

# 8. Contains expected strings
# Pipe to grep -c (not -q) to avoid SIGPIPE killing strings under pipefail
if [ "$(strings "$BINARY" | grep -c "strace")" -gt 0 ]; then
    pass "contains 'strace' string"
else
    fail "binary does not contain 'strace' string"
fi

# 9–10. QEMU smoke tests
QEMU_TIMEOUT=5
if command -v "$QEMU_BIN" >/dev/null 2>&1; then
    QEMU="$QEMU_BIN"

    # 9. -V prints version string
    QEMU_VER="$(timeout -k 3 "$QEMU_TIMEOUT" "$QEMU" "$BINARY" -V 2>&1 || true)"
    if echo "$QEMU_VER" | grep -qE "strace -- version [0-9]+\.[0-9]+"; then
        pass "QEMU -V: $QEMU_VER"
    else
        fail "QEMU -V — output: $QEMU_VER"
    fi

    # 10. -h prints help/usage text
    QEMU_HELP="$(timeout -k 3 "$QEMU_TIMEOUT" "$QEMU" "$BINARY" -h 2>&1 || true)"
    if echo "$QEMU_HELP" | grep -q "Usage: strace"; then
        pass "QEMU -h shows usage text"
    else
        fail "QEMU -h — output: $(echo "$QEMU_HELP" | head -3)"
    fi

    # 11. Error on nonexistent program
    QEMU_ERR="$(timeout -k 3 "$QEMU_TIMEOUT" "$QEMU" "$BINARY" /nonexistent/program 2>&1 || true)"
    if echo "$QEMU_ERR" | grep -q "No such file or directory"; then
        pass "QEMU reports error for nonexistent program"
    else
        fail "QEMU nonexistent program — output: $(echo "$QEMU_ERR" | head -3)"
    fi
else
    echo "SKIP: QEMU smoke tests ($QEMU_BIN not installed)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
