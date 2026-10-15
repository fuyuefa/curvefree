import 'package:curvefree/core/storage/local_store_snapshot.dart';

/// Persistence port for the whole-app document store.
abstract interface class LocalStore {
  Future<LocalStoreSnapshot> read();

  Future<void> write(LocalStoreSnapshot snapshot);

  /// Read the latest snapshot, apply [transform], and write the result
  /// before any other queued mutation can observe the old document.
  Future<LocalStoreSnapshot> mutate(
    LocalStoreSnapshot Function(LocalStoreSnapshot current) transform,
  );

  /// Replace store contents from an exported JSON document.
  Future<LocalStoreSnapshot> importJson(String rawJson);

  Future<String> exportJson();
}
