/// Schema and collection keys for the local document store.
abstract final class StorageKeys {
  static const String rootFileName = 'curvefree_store.json';
  static const String webPrefsKey = 'curvefree_store_json';
  static const String schemaVersion = 'schemaVersion';
  static const String meta = 'meta';
  static const String settings = 'settings';
  static const String workouts = 'workouts';
  static const String foodLogs = 'foodLogs';
}

abstract final class StorageSchema {
  /// Bump when on-disk shape changes; keep migrations explicit.
  static const int currentVersion = 1;
}
