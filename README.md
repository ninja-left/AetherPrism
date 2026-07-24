# Aether Prism

Aether Prism is an unofficial GUI wrapper for the [Aether core](https://github.com/CluvexStudio/Aether).

This project does not reimplement the tunnel logic. The GUI collects settings, turns them into environment variables, starts the Aether process, watches stdout/stderr, and retries when the core exits with a reset/error rather than a clean shutdown.

## Versioning

This repository is currently on semantic version **v1.0.8**.

## What this first build does

- cross-platform Flutter UI
- profile editor for the common Aether runtime flags
- process launcher abstraction
- bundled upstream Aether binary resolution
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

Android is now handled the same way: the release workflow downloads the matching upstream Aether binary into bundled assets, and the app extracts the correct one for the current ABI at runtime.

## Build

```bash
flutter pub get
flutter run
```

For release builds, use GitHub Actions. The workflow fetches the latest upstream Aether release asset for each platform and stages it into `assets/runtime/` before packaging.

## Android release signing in GitHub Actions

The Android package id is fixed in CI as `io.github.aetherprism`, so it does not fall back to the `com.example` default anymore.

For release APKs, set these GitHub repository secrets once:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Create the keystore locally, then base64-encode it and store the encoded text in `ANDROID_KEYSTORE_BASE64`. The same keystore must be reused for every future release, or Android will see the app as signed by a different key.

Example keystore command:

```bash
keytool -genkeypair -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

On Linux:

```bash
base64 -w 0 upload-keystore.jks
```

On macOS:

```bash
base64 upload-keystore.jks | tr -d '\n'
```

The workflow will build an unsigned debug APK on pull requests if those secrets are not available, and it will build signed release APKs on `main` once the secrets are present. It also downloads the matching upstream Aether binary so the packaged app ships with the core binary instead of asking for a path.

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
