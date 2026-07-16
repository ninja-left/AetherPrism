# Aether Prism

Aether Prism is a GUI wrapper for the Aether core binary.

It does not reimplement the tunnel logic. It starts the `aether` executable, passes settings through environment variables, and shows logs and connection state in a GUI.

## What this repo does

- Cross-platform GUI in Flutter for Android, Linux, Windows, and macOS
- Profile editor for Aether env vars
- Binary path selection
- Start / stop control
- Live stdout/stderr log capture
- JSON profile save/load

## How it works

Aether already supports non-interactive startup through environment variables. The wrapper uses that contract instead of prompting in a terminal.

For example, the upstream docs list variables such as:

- `AETHER_PROTOCOL`
- `AETHER_SOCKS`
- `AETHER_NOIZE`
- `AETHER_SCAN`
- `AETHER_IP`
- `AETHER_MASQUE_HTTP2`
- `AETHER_WG_KEEPALIVE`
- `AETHER_WG_STALL`
- `AETHER_NO_WATCHDOG`
- `AETHER_PEER`
- `AETHER_CONFIG`

## Build plan

1. Run `flutter pub get`
2. Let GitHub Actions or local Flutter tooling generate missing platform folders with:
   `flutter create --platforms=android,linux,macos,windows .`
3. Build per target:
   - Android: `flutter build apk --release`
   - Linux: `flutter build linux --release`
   - Windows: `flutter build windows --release`
   - macOS: `flutter build macos --release`

## Android note

Android is treated as a binary-launch wrapper too. The user points the app at the Aether binary or imports it into app storage, and the wrapper launches it with the chosen environment. That keeps the UI separate from the networking core.

## Repo layout

```text
lib/
  main.dart
.github/workflows/
  build.yml
pubspec.yaml
README.md
analysis_options.yaml
```
