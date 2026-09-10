import 'dart:convert';

import 'package:curvefree/core/storage/local_store.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/core/storage/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web-safe store using SharedPreferences (QA preview / browser).
final class PrefsLocalStore implements LocalStore {
  PrefsLocalStore({this._preferences});

  SharedPreferences? _preferences;

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<LocalStoreSnapshot> read() async {
    final prefs = await _prefs();
    final raw = prefs.getString(StorageKeys.webPrefsKey);
    if (raw == null || raw.trim().isEmpty) {
      final empty = LocalStoreSnapshot.empty();
      await write(empty);
      return empty;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('本地库根节点必须是 JSON 对象');
    }
    return LocalStoreSnapshot.fromJson(
      decoded.map(
        (Object? key, Object? value) => MapEntry(key.toString(), value),
      ),
    );
  }

  @override
  Future<void> write(LocalStoreSnapshot snapshot) async {
    final prefs = await _prefs();
    await prefs.setString(StorageKeys.webPrefsKey, snapshot.encodePretty());
  }

  @override
  Future<String> exportJson() async {
    final snapshot = await read();
    return snapshot.encodePretty();
  }

  @override
  Future<LocalStoreSnapshot> importJson(String rawJson) async {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      throw const FormatException('备份根节点必须是 JSON 对象');
    }
    final snapshot = LocalStoreSnapshot.fromJson(
      decoded.map(
        (Object? key, Object? value) => MapEntry(key.toString(), value),
      ),
    );
    await write(snapshot);
    return snapshot;
  }
}
