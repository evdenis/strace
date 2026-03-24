#!/system/bin/sh

# Magisk sets $ARCH to one of: arm64, arm, x86_64, x86
STRACE_SRC="$MODPATH/strace-bin/$ARCH/strace"

if [ ! -f "$STRACE_SRC" ]; then
    abort "Unsupported architecture: $ARCH"
fi

ui_print "- Installing strace for $ARCH"
mkdir -p "$MODPATH/system/bin"
cp "$STRACE_SRC" "$MODPATH/system/bin/strace"
set_perm "$MODPATH/system/bin/strace" 0 0 0755

# Remove arch binaries not needed at runtime
rm -rf "$MODPATH/strace-bin"
