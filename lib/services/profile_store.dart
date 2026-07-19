import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/aether_profile.dart';

class ProfileStore {
  static const String _prefsKey = 'aether_prism_profile';

  Future<File> _file() async {
    final Directory dir = await getApplicationSupportDirectory();
    return File('${dir.path}/aether_prism_profile.json');
  }

  Future<AetherProfile?> load() async {
    try {
      final File file = await _file();
      if (await file.exists()) {
        final Map<String, Object?> jsonMap =
            jsonDecode(await file.readAsString()) as Map<String, Object?>;
        return AetherProfile.fromJson(jsonMap);
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
