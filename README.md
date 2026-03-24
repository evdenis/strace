# Strace for Android

Magisk module packaging a pre-compiled [strace](https://github.com/strace/strace) v6.19 binary for Android.
Supports **ARM64**, **ARM**, **x86_64**, and **x86** architectures. Built with GCC, LTO, statically linked, stripped.

The module installs `strace` to `/system/bin/` via Magisk's systemless overlay, automatically selecting the correct binary for your device architecture at install time. Supports auto-update through Magisk's built-in update mechanism.

## How to install

### From release (recommended)

1. Download the latest zip from the [releases page](https://github.com/evdenis/strace/releases)
2. Open Magisk → Modules → Install from storage → select the zip → Reboot

### From source

Requires `make`, `adb`, and a rooted device connected via USB.

```bash
git clone https://github.com/evdenis/strace
cd strace
make install
```

## Building from source

Requires Docker.

```bash
# Build strace for a single architecture (default: arm64)
make build-strace ARCH=arm64

# Build for all architectures
make build-strace-all

# Run binary verification tests
make test-strace-all

# Package into installable zip
make zip
```

Supported `ARCH` values: `arm64`, `arm`, `x86_64`, `x86`.

## Support

- [Telegram](https://t.me/joinchat/GsJfBBaxozXvVkSJhm0IOQ)
- [XDA Thread](https://forum.xda-developers.com/apps/magisk/module-debugging-modules-adb-root-t4050041)
