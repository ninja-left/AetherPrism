import 'package:aetherprism/services/aether_binary_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled binary target metadata stays aligned with upstream assets', () {
    expect(AetherBinaryTarget.linuxX64.assetPath, 'assets/runtime/linux/x86_64/aether');
    expect(AetherBinaryTarget.linuxX64.releaseAssetName, 'aether-linux-x86_64.tar.gz');

    expect(AetherBinaryTarget.macosArm64.assetPath, 'assets/runtime/macos/arm64/aether');
    expect(AetherBinaryTarget.macosArm64.releaseAssetName, 'aether-macos-arm64.tar.gz');

    expect(AetherBinaryTarget.windowsX64.assetPath, 'assets/runtime/windows/x86_64/aether.exe');
    expect(AetherBinaryTarget.windowsX64.releaseAssetName, 'aether-windows-x86_64.zip');

    expect(AetherBinaryTarget.androidArm64.assetPath, 'assets/runtime/android/arm64-v8a/aether');
    expect(AetherBinaryTarget.androidArmv7.releaseAssetName, 'aether-android-armv7.tar.gz');
  });
}
