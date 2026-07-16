# Aether Prism

Aether Prism is an unofficial GUI wrapper for the Aether core.

This project does not reimplement the tunnel logic. The GUI collects settings, turns them into environment variables, starts the Aether process, watches stdout/stderr, and retries when the core exits with a reset/error rather than a clean shutdown.

## Versioning

This repository starts at semantic version **v1.0.0**.

## What this first build does

- cross-platform Flutter UI
- profile editor for the common Aether runtime flags
- process launcher abstraction
- live log view
- start, stop, restart, and automatic retry
- JSON export/import for profiles
- clear separation between UI and backend launcher

## Runtime model

Aether Prism assumes the Aether core can be started as a normal process with environment variables, and that it prints logs to stdout/stderr while running.

If the core exits cleanly, the GUI stops retrying.
If the core logs a connection reset / closed / error / timeout type failure, the GUI retries after a short backoff.

## Platform notes

Desktop is the main path: Linux, Windows, and macOS should be straightforward.

Android is kept in the codebase through the same process abstraction, but the final runtime packaging still depends on how the Aether binary is delivered on-device. The GUI side is ready; the backend binary delivery method is the part that has to be matched to the target environment.

## Build

```bash
flutter pub get
flutter run
```

For release builds, use GitHub Actions.

## Environment mapping

The app maps UI values to the Aether runtime using env vars such as:

- `AETHER_PROTOCOL`
- `AETHER_SOCKS`
- `AETHER_NOIZE`
- `AETHER_SCAN`
- `AETHER_IP`
- `AETHER_MASQUE_HTTP2`
- `AETHER_MASQUE_H2_PEER`
- `AETHER_WG_KEEPALIVE`
- `AETHER_WG_STALL`
- `AETHER_NO_WATCHDOG`
- `AETHER_WG_NO_DATA_CHECK`
- `AETHER_WG_NO_PROFILE_RETRY`
- `AETHER_PEER`
- `AETHER_WG_PEER`
- `AETHER_CONFIG`
- `AETHER_WG_CONFIG`
- `AETHER_MASQUE_CONFIG`
