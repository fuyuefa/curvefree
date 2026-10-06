import 'dart:convert';

import 'package:curvefree/core/storage/storage_keys.dart';

/// Immutable snapshot of the on-device document database.
final class LocalStoreSnapshot {
  const LocalStoreSnapshot({
    required this.schemaVersion,
    required this.meta,
    required this.settings,
    required this.workouts,
    required this.foodLogs,
  });

  final int schemaVersion;
  final Map<String, Object?> meta;
  final Map<String, Object?> settings;
  final List<Map<String, Object?>> workouts;
  final List<Map<String, Object?>> foodLogs;

  bool get hasUserData =>
      workouts.isNotEmpty || foodLogs.isNotEmpty || settings.isNotEmpty;

  factory LocalStoreSnapshot.empty() {
    return LocalStoreSnapshot(
      schemaVersion: StorageSchema.currentVersion,
      meta: <String, Object?>{
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      },
      settings: const <String, Object?>{},
      workouts: const <Map<String, Object?>>[],
      foodLogs: const <Map<String, Object?>>[],
    );
  }

  factory LocalStoreSnapshot.fromJson(Map<String, Object?> json) {
    final version = json[StorageKeys.schemaVersion];
    return LocalStoreSnapshot(
      schemaVersion: version is int ? version : StorageSchema.currentVersion,
      meta: _asStringKeyedMap(json[StorageKeys.meta]),
      settings: _asStringKeyedMap(json[StorageKeys.settings]),
      workouts: _asMapList(json[StorageKeys.workouts]),
      foodLogs: _asMapList(json[StorageKeys.foodLogs]),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      StorageKeys.schemaVersion: schemaVersion,
      StorageKeys.meta: meta,
      StorageKeys.settings: settings,
      StorageKeys.workouts: workouts,
      StorageKeys.foodLogs: foodLogs,
    };
  }

  String encodePretty() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  LocalStoreSnapshot copyWith({
    int? schemaVersion,
    Map<String, Object?>? meta,
    Map<String, Object?>? settings,
    List<Map<String, Object?>>? workouts,
    List<Map<String, Object?>>? foodLogs,
  }) {
    return LocalStoreSnapshot(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      meta: meta ?? this.meta,
      settings: settings ?? this.settings,
      workouts: workouts ?? this.workouts,
      foodLogs: foodLogs ?? this.foodLogs,
    );
  }

  static Map<String, Object?> _asStringKeyedMap(Object? value) {
    if (value is Map) {
      return value.map(
        (Object? key, Object? item) => MapEntry(key.toString(), item),
      );
    }
    return <String, Object?>{};
  }

  static List<Map<String, Object?>> _asMapList(Object? value) {
    if (value is! List) {
      return <Map<String, Object?>>[];
    }
    return value
        .whereType<Map<Object?, Object?>>()
        .map(
          (Map<Object?, Object?> item) => item.map(
            (Object? key, Object? nested) => MapEntry(key.toString(), nested),
          ),
        )
        .toList(growable: false);
  }
}
