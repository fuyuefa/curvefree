import 'dart:io';

import 'package:curvefree/core/storage/atomic_file_write.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/core/storage/queued_document_store.dart';
import 'package:curvefree/core/storage/storage_keys.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// File-backed store for Android/desktop. Not used on Flutter Web.
final class FileLocalStore extends QueuedDocumentStore {
  FileLocalStore({this.overrideDirectory});

  final Directory? overrideDirectory;
  File? _file;

  Future<File> _resolveFile() async {
    final cached = _file;
    if (cached != null) {
      return cached;
    }
    final directory =
        overrideDirectory ?? await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, StorageKeys.rootFileName));
    _file = file;
    return file;
  }

  @override
  Future<LocalStoreSnapshot> readUnlocked() async {
    final file = await _resolveFile();
    if (!await file.exists()) {
      final empty = LocalStoreSnapshot.empty();
      await writeUnlocked(empty);
      return empty;
    }
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return LocalStoreSnapshot.empty();
    }
    return LocalStoreSnapshot.decode(
      raw,
      invalidRootMessage: '本地库根节点必须是 JSON 对象',
    );
  }

  @override
  Future<void> writeUnlocked(LocalStoreSnapshot snapshot) async {
    final file = await _resolveFile();
    await writeFileAtomically(file, snapshot.encodePretty());
  }
}
