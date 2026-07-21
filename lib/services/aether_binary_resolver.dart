import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'aether_binary_spec.dart';

class AetherBinaryResolver {
  const AetherBinaryResolver();

  Future<File> resolveExecutable() async {
    final String? override = Platform.environment['AETHER_PRISM_BINARY_OVERRIDE'];
    if (override != null && override.trim().isNotEmpty) {
      final File overrideFile = File(override.trim());
      if (await overrideFile.exists()) {
        return overrideFile;
      }
    }

    final AetherBinaryTarget target = AetherBinaryPlatform.current();
    final Directory supportDir = await getApplicationSupportDirectory();
    final Directory runtimeDir = Directory(
      '${supportDir.path}${Platform.pathSeparator}aetherprism-runtime${Platform.pathSeparator}${target.supportDirName}',
    );
    final File executable = File(
      '${runtimeDir.path}${Platform.pathSeparator}${target.executableName}',
    );

    if (await executable.exists()) {
      return executable;
    }

    try {
      final ByteData asset = await rootBundle.load(target.assetPath);
      await runtimeDir.create(recursive: true);
      await executable.writeAsBytes(
        asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
        flush: true,
      );
      await _ensureExecutableBit(executable);
      return executable;
    } on FlutterError catch (_) {
      if (!kReleaseMode) {
        return File(target.executableName);
      }
      rethrow;
    }
  }

  Future<void> _ensureExecutableBit(File file) async {
    if (Platform.isWindows) {
      return;
    }

    final ProcessResult result = await Process.run(
      'chmod',
      <String>['755', file.path],
    );
    if (result.exitCode != 0) {
      throw ProcessException(
        'chmod',
        <String>['755', file.path],
        result.stderr.toString(),
        result.exitCode,
      );
    }
  }

  String describeCurrentTarget() => AetherBinaryPlatform.current().label;

  String describeCurrentAsset() => AetherBinaryPlatform.current().assetPath;
}
