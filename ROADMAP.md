# Roadmap
#### GH Actions
- [X] Make release changes dynamic; read from CHANGELOG.md
- [ ] Sort uploaded artifacts by platform and arch name
- [ ] Build and release packages for each arch (same way aether is)
- [ ] Ship each package with it's platform specific aether binary[^1]

#### UI/UX
- [X] Use the icons under `asset/icon`
- [ ] Use AetherPrism instead of aether_prism as the app and package name
  - Don't use com.example.aether_prism as the package name (E.x apk package name); use com.njl.aetherprism instead
- [ ] Use the shipped aether binary instead of entering aether binary path[^1]
- [ ] Make the control panel (Start, Stop, etc) bolder and above the config options (treat the options as an advanced options/section)

[^1]: This specific upgrade requires aether-shipping to be implemented first
