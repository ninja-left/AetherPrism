import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/aether_profile.dart';

class ProfileStore {
  static const String _prefsKey = 'aetherprism_profile';
  static const String _legacyPrefsKey = 'aether_prism_profile';
  static const String _fileName = 'aetherprism_profile.json';
  static const String _legacyFileName = 'aether_prism_profile.json';

  Future<File> _file() async {
    final Directory dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<File> _legacyFile() async {
    final Directory dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_legacyFileName');
  }

  Future<AetherProfile?> _readProfileFile(File file) async {
    if (!await file.exists()) {
      return null;
    }

    final Map<String, Object?> jsonMap =
        jsonDecode(await file.readAsString()) as Map<String, Object?>;
    return AetherProfile.fromJson(jsonMap);
  }

  Future<AetherProfile?> load() async {
    try {
      final AetherProfile? profile = await _readProfileFile(await _file());
      if (profile != null) {
        return profile;
      }
    } catch (_) {}

    try {
      final AetherProfile? profile =
          await _readProfileFile(await _legacyFile());
      if (profile != null) {
        return profile;
      }
    } catch (_) {}

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, Object?> jsonMap =
            jsonDecode(raw) as Map<String, Object?>;
        return AetherProfile.fromJson(jsonMap);
      }
    } catch (_) {}

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_legacyPrefsKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, Object?> jsonMap =
            jsonDecode(raw) as Map<String, Object?>;
        return AetherProfile.fromJson(jsonMap);
      }
    } catch (_) {}

    return null;
  }

  Future<void> save(AetherProfile profile) async {
    final String raw = jsonEncode(profile.toJson());
    try {
      final File file = await _file();
      await file.create(recursive: true);
      await file.writeAsString(raw);
      return;
    } catch (_) {}

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, raw);
  }

  Future<String> exportJson(AetherProfile profile) async {
    return jsonEncode(profile.toJson());
  }

  AetherProfile importJson(String raw) {
    final Map<String, Object?> jsonMap = jsonDecode(raw) as Map<String, Object?>;
    return AetherProfile.fromJson(jsonMap);
  }
}
