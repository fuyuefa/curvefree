import 'package:curvefree/core/storage/local_store_snapshot.dart';

/// Persistence port for the whole-app document store.
abstract interface class LocalStore {
  Future<LocalStoreSnapshot> read();

  Future<void> write(LocalStoreSnapshot snapshot);

  /// Replace store contents from an exported JSON document.
  Future<LocalStoreSnapshot> importJson(String rawJson);

  Future<String> exportJson();
}
