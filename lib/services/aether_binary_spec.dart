import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Describes the upstream Aether binary to ship for the current runtime.
enum AetherBinaryTarget {
  linuxX64,
  linuxArm64,
  macosX64,
  macosArm64,
  windowsX64,
  androidArm64,
  androidArmv7,
  androidX64,
}

extension AetherBinaryTargetSpec on AetherBinaryTarget {
  String get label => switch (this) {
        AetherBinaryTarget.linuxX64 => 'Linux x86_64',
        AetherBinaryTarget.linuxArm64 => 'Linux arm64',
        AetherBinaryTarget.macosX64 => 'macOS x86_64',
        AetherBinaryTarget.macosArm64 => 'macOS arm64',
        AetherBinaryTarget.windowsX64 => 'Windows x86_64',
        AetherBinaryTarget.androidArm64 => 'Android arm64-v8a',
        AetherBinaryTarget.androidArmv7 => 'Android armeabi-v7a',
        AetherBinaryTarget.androidX64 => 'Android x86_64',
      };

  String get assetPath => switch (this) {
        AetherBinaryTarget.linuxX64 => 'assets/runtime/linux/x86_64/aether',
        AetherBinaryTarget.linuxArm64 => 'assets/runtime/linux/arm64/aether',
        AetherBinaryTarget.macosX64 => 'assets/runtime/macos/x86_64/aether',
        AetherBinaryTarget.macosArm64 => 'assets/runtime/macos/arm64/aether',
        AetherBinaryTarget.windowsX64 => 'assets/runtime/windows/x86_64/aether.exe',
        AetherBinaryTarget.androidArm64 => 'assets/runtime/android/arm64-v8a/aether',
        AetherBinaryTarget.androidArmv7 => 'assets/runtime/android/armeabi-v7a/aether',
        AetherBinaryTarget.androidX64 => 'assets/runtime/android/x86_64/aether',
      };

  String get executableName => switch (this) {
        AetherBinaryTarget.windowsX64 => 'aether.exe',
        _ => 'aether',
      };

  String get releaseAssetName => switch (this) {
        AetherBinaryTarget.linuxX64 => 'aether-linux-x86_64.tar.gz',
        AetherBinaryTarget.linuxArm64 => 'aether-linux-arm64.tar.gz',
        AetherBinaryTarget.macosX64 => 'aether-macos-x86_64.tar.gz',
        AetherBinaryTarget.macosArm64 => 'aether-macos-arm64.tar.gz',
        AetherBinaryTarget.windowsX64 => 'aether-windows-x86_64.zip',
        AetherBinaryTarget.androidArm64 => 'aether-android-arm64.tar.gz',
        AetherBinaryTarget.androidArmv7 => 'aether-android-armv7.tar.gz',
        AetherBinaryTarget.androidX64 => 'aether-android-x86_64.tar.gz',
      };

  String get supportDirName => name;
}

final class AetherBinaryPlatform {
  const AetherBinaryPlatform._();

  static AetherBinaryTarget current() {
    if (Platform.isLinux) {
      return switch (Abi.current()) {
        Abi.linuxArm64 => AetherBinaryTarget.linuxArm64,
        Abi.linuxX64 => AetherBinaryTarget.linuxX64,
        _ => AetherBinaryTarget.linuxX64,
      };
    }

    if (Platform.isMacOS) {
      return switch (Abi.current()) {
        Abi.macosArm64 => AetherBinaryTarget.macosArm64,
        Abi.macosX64 => AetherBinaryTarget.macosX64,
        _ => AetherBinaryTarget.macosArm64,
      };
    }

    if (Platform.isWindows) {
      return AetherBinaryTarget.windowsX64;
    }

    if (Platform.isAndroid) {
      return switch (Abi.current()) {
        Abi.androidArm64 => AetherBinaryTarget.androidArm64,
        Abi.androidArm => AetherBinaryTarget.androidArmv7,
        Abi.androidX64 => AetherBinaryTarget.androidX64,
        _ => AetherBinaryTarget.androidArm64,
      };
    }

    throw UnsupportedError('Unsupported platform for bundled Aether binary.');
  }
}
