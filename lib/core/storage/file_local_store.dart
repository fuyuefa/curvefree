import 'dart:convert';
import 'dart:io';

import 'package:curvefree/core/storage/local_store.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/core/storage/storage_keys.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// File-backed store for Android/desktop. Not used on Flutter Web.
final class FileLocalStore implements LocalStore {
  FileLocalStore({this._overrideDirectory});

  final Directory? _overrideDirectory;
  File? _file;

  Future<File> _resolveFile() async {
    final cached = _file;
    if (cached != null) {
      return cached;
    }
    final directory =
        _overrideDirectory ?? await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, StorageKeys.rootFileName));
    _file = file;
    return file;
  }

  @override
  Future<LocalStoreSnapshot> read() async {
    final file = await _resolveFile();
    if (!await file.exists()) {
      final empty = LocalStoreSnapshot.empty();
      await write(empty);
      return empty;
    }
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return LocalStoreSnapshot.empty();
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
    final file = await _resolveFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(snapshot.encodePretty());
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
