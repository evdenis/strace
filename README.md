# Strace for Android

Magisk module packaging a pre-compiled [strace](https://github.com/strace/strace) v5.9 binary for Android.
Built with GCC10, LTO, stripped. ARM64 only.

The module installs `strace` to `/system/bin/` via Magisk's systemless overlay and supports auto-update through Magisk's built-in update mechanism.

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

## Support

- [Telegram](https://t.me/joinchat/GsJfBBaxozXvVkSJhm0IOQ)
- [XDA Thread](https://forum.xda-developers.com/apps/magisk/module-debugging-modules-adb-root-t4050041)
