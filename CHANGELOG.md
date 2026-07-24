## v1.0.8
- Moved the primary Start/Stop controls to the top of the launcher panel so they are easier to reach.
- Mirrored status updates and launcher errors into the log box so the full messages stay visible.
- Upgraded GitHub Actions references to newer major versions to avoid Node.js deprecation warnings.
- Changed the 403 retry delay to 6 seconds with two retries before giving up.

## v1.0.7
- Switched the launcher to a shipped-binary model instead of asking for a binary path.
- Added a CI helper that downloads the latest upstream Aether release asset for each supported build target and stages it into Flutter assets.
- Added runtime extraction of the bundled binary so the app can launch the shipped core directly.

## v1.0.6
- Renamed the package identity from `aether_prism` to `aetherprism`.
- Kept the visible app name as Aether Prism and cleaned up the remaining identity references.

## v1.0.5
- Added changelog-driven release notes so GitHub Actions no longer needs manual body edits.
- Added automated launcher icon generation for Android, macOS, and Windows from `assets/icons/app_icon.png`.
- Added Linux launcher icon handling in CI so the desktop build uses the same app icon.
- Added Android release packaging for one universal APK and split-per-ABI APKs.
- Bumped the app version to v1.0.5+5.
