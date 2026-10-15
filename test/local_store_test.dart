import 'dart:convert';
import 'dart:io';

import 'package:curvefree/core/backup/backup_file_gateway.dart';
import 'package:curvefree/core/storage/file_local_store.dart';
import 'package:curvefree/core/storage/local_store_providers.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/core/storage/prefs_local_store.dart';
import 'package:curvefree/core/storage/storage_keys.dart';
import 'package:curvefree/features/training/data/workout_repository.dart';
import 'package:curvefree/features/training/models/workout_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalStoreSnapshot', () {
    test('round-trips JSON', () {
      final original = LocalStoreSnapshot.empty().copyWith(
        settings: <String, Object?>{'locale': 'zh_CN'},
        workouts: <Map<String, Object?>>[
          <String, Object?>{'id': 'w1', 'name': '推日'},
        ],
      );
      final encoded = original.encodePretty();
      final decodedMap = jsonDecode(encoded) as Map<String, dynamic>;
      final restored = LocalStoreSnapshot.fromJson(
        decodedMap.map((String key, dynamic value) => MapEntry(key, value)),
      );
      expect(restored.schemaVersion, StorageSchema.currentVersion);
      expect(restored.settings['locale'], 'zh_CN');
      expect(restored.workouts.single['id'], 'w1');
      expect(restored.hasUserData, isTrue);
    });
  });

  group('FileLocalStore', () {
    test('persists and exports', () async {
      final directory = await Directory.systemTemp.createTemp(
        'curvefree_store_',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      final store = FileLocalStore(overrideDirectory: directory);
      final first = await store.read();
      expect(first.schemaVersion, StorageSchema.currentVersion);

      final updated = first.copyWith(settings: <String, Object?>{'unit': 'kg'});
      await store.write(updated);

      final again = await store.read();
      expect(again.settings['unit'], 'kg');

      final exported = await store.exportJson();
      expect(exported.contains('"unit": "kg"'), isTrue);

      final imported = await store.importJson(
        LocalStoreSnapshot.empty()
            .copyWith(settings: <String, Object?>{'unit': 'lb'})
            .encodePretty(),
      );
      expect(imported.settings['unit'], 'lb');
    });

    test('serializes parallel mutations and replaces via temp file', () async {
      final directory = await Directory.systemTemp.createTemp(
        'curvefree_queue_',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      final store = FileLocalStore(overrideDirectory: directory);
      await store.read();

      const mutationCount = 24;
      await Future.wait(<Future<void>>[
        for (var i = 0; i < mutationCount; i++)
          store.mutate((LocalStoreSnapshot current) {
            return current.copyWith(
              workouts: <Map<String, Object?>>[
                ...current.workouts,
                <String, Object?>{'id': 'w$i'},
              ],
              settings: <String, Object?>{...current.settings, 'k$i': i},
            );
          }),
      ]);

      final snapshot = await store.read();
      expect(snapshot.workouts, hasLength(mutationCount));
      expect(snapshot.settings, hasLength(mutationCount));

      final stored = File('${directory.path}/${StorageKeys.rootFileName}');
      final raw = await stored.readAsString();
      expect(jsonDecode(raw), isA<Map<dynamic, dynamic>>());
      final leftovers = directory.listSync().where(
        (FileSystemEntity entity) =>
            entity.path.endsWith(StorageKeys.tempFileSuffix) ||
            entity.path.endsWith(StorageKeys.replacingFileSuffix),
      );
      expect(leftovers, isEmpty);

      final older = store.write(
        LocalStoreSnapshot.empty().copyWith(
          settings: <String, Object?>{'n': 1},
        ),
      );
      final newer = store.write(
        LocalStoreSnapshot.empty().copyWith(
          settings: <String, Object?>{'n': 2},
        ),
      );
      await Future.wait(<Future<void>>[older, newer]);
      expect((await store.read()).settings['n'], 2);
    });

    test('refuses a backup newer than this app', () async {
      final directory = await Directory.systemTemp.createTemp(
        'curvefree_schema_',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final store = FileLocalStore(overrideDirectory: directory);
      final raw = LocalStoreSnapshot.empty()
          .copyWith(schemaVersion: StorageSchema.currentVersion + 1)
          .encodePretty();
      expect(store.importJson(raw), throwsFormatException);
    });

    test('putSetting keeps workouts written in the same burst', () async {
      final directory = await Directory.systemTemp.createTemp(
        'curvefree_setting_',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final store = FileLocalStore(overrideDirectory: directory);
      final container = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container.read(localStoreSnapshotProvider.future);

      final repo = WorkoutRepository(store);
      await Future.wait(<Future<void>>[
        container
            .read(localStoreSnapshotProvider.notifier)
            .putSetting('unit', 'kg'),
        repo.upsert(WorkoutSession.create()),
      ]);

      final snapshot = await store.read();
      expect(snapshot.settings['unit'], 'kg');
      expect(snapshot.workouts, isNotEmpty);
    });
  });

  test('backup file name is a local timestamped json name', () {
    final name = BackupFiles.stamped(DateTime(2026, 10, 15, 16, 5));
    expect(name, 'curvefree-backup-20261015-1605.json');
  });

  group('PrefsLocalStore', () {
    test('persists on web-like prefs', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final store = PrefsLocalStore(preferences: prefs);

      final snapshot = await store.read();
      await store.write(
        snapshot.copyWith(
          foodLogs: <Map<String, Object?>>[
            <String, Object?>{'id': 'f1', 'name': '鸡胸'},
          ],
        ),
      );

      final reloaded = await store.read();
      expect(reloaded.foodLogs.single['name'], '鸡胸');
    });
  });
}
