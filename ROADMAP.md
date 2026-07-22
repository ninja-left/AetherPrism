# Roadmap

## Milestones

### v1.0.6 — Naming and identity
- Rename the app/package identity from `aether_prism` to `aetherprism` / `Aether Prism`.
- Replace leftover internal identifiers, file names, and test imports that still reference the old package name.
- Force the Android package id away from the `com.example` default in CI.
- Keep everything else stable so this release is only about identity cleanup.

### v1.0.7 — Shipped binary integration
- [X] Use the shipped Aether binary instead of asking for a binary path.
- [X] Finish the binary delivery flow first, then wire the UI to it.
- [X] Download the latest upstream Aether release asset for each build target in CI.

### v1.0.8 — Control panel cleanup
- Make the control panel (Start, Stop, etc) bolder and place it above the config options.
- Treat the current options area as an advanced section.
#### Minor patches
- The aether fetch script fails fully if it hits a 403 rate limit; Make it wait 6 seconds and retry for 2 times
- Upgrade the used actions versions to avoid Node.js deprecated warnings
- Log all activities in the log box too instead of just using status bar

### v1.0.9 — Release pipeline polish
- Sort uploaded artifacts by platform and arch name.
- Build and release packages for each arch the same way Aether does.
- Ship each package with its platform-specific Aether binary.

## GH Actions
- [X] Make release changes dynamic; read from CHANGELOG.md
- [X] Ship each package with its platform specific aether binary[^1]
- [ ] Sort uploaded artifacts by platform and arch name
- [ ] Build and release packages for each arch (same way aether is)

## UI/UX
- [X] Use the icons under `asset/icon`
- [X] Use `AetherPrism` instead of `aether_prism` as the app and package name
- [X] Use the shipped aether binary instead of entering aether binary path[^1]
- [ ] Make the control panel (Start, Stop, etc) bolder and above the config options (treat the options as an advanced options/section)

[^1]: This specific upgrade requires aether-shipping to be implemented first
