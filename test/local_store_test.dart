import 'dart:convert';
import 'dart:io';

import 'package:curvefree/core/storage/file_local_store.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/core/storage/prefs_local_store.dart';
import 'package:curvefree/core/storage/storage_keys.dart';
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
        decodedMap.map(
          (String key, dynamic value) => MapEntry(key, value),
        ),
      );
      expect(restored.schemaVersion, StorageSchema.currentVersion);
      expect(restored.settings['locale'], 'zh_CN');
      expect(restored.workouts.single['id'], 'w1');
      expect(restored.hasUserData, isTrue);
    });
  });

  group('FileLocalStore', () {
    test('persists and exports', () async {
      final directory = await Directory.systemTemp.createTemp('curvefree_store_');
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      final store = FileLocalStore(overrideDirectory: directory);
      final first = await store.read();
      expect(first.schemaVersion, StorageSchema.currentVersion);

      final updated = first.copyWith(
        settings: <String, Object?>{'unit': 'kg'},
      );
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
  });

  group('PrefsLocalStore', () {
    test('persists on web-like prefs', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final store = PrefsLocalStore(preferences: prefs);

      final snapshot = await store.read();
      await store.write(
        snapshot.copyWith(foodLogs: <Map<String, Object?>>[
          <String, Object?>{'id': 'f1', 'name': '鸡胸'},
        ]),
      );

      final reloaded = await store.read();
      expect(reloaded.foodLogs.single['name'], '鸡胸');
    });
  });
}
