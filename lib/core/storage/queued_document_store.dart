import 'package:curvefree/core/storage/local_store.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/core/storage/storage_keys.dart';
import 'package:curvefree/core/storage/store_mutation_queue.dart';

/// [LocalStore] that serializes every read and write on one queue.
abstract base class QueuedDocumentStore implements LocalStore {
  final StoreMutationQueue _queue = StoreMutationQueue();

  Future<LocalStoreSnapshot> readUnlocked();

  Future<void> writeUnlocked(LocalStoreSnapshot snapshot);

  @override
  Future<LocalStoreSnapshot> read() {
    return _queue.run(readUnlocked);
  }

  @override
  Future<void> write(LocalStoreSnapshot snapshot) {
    return _queue.run(() => writeUnlocked(snapshot));
  }

  @override
  Future<LocalStoreSnapshot> mutate(
    LocalStoreSnapshot Function(LocalStoreSnapshot current) transform,
  ) {
    return _queue.run(() async {
      final current = await readUnlocked();
      final next = transform(current);
      await writeUnlocked(next);
      return next;
    });
  }

  @override
  Future<String> exportJson() {
    return _queue.run(() async {
      final snapshot = await readUnlocked();
      return snapshot.encodePretty();
    });
  }

  @override
  Future<LocalStoreSnapshot> importJson(String rawJson) {
    return _queue.run(() async {
      final snapshot = LocalStoreSnapshot.decode(rawJson);
      if (snapshot.schemaVersion > StorageSchema.currentVersion) {
        throw FormatException(
          '备份版本 v${snapshot.schemaVersion} 高于当前 v${StorageSchema.currentVersion}',
        );
      }
      await writeUnlocked(snapshot);
      return snapshot;
    });
  }
}
