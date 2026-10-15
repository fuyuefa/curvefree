import 'package:curvefree/core/storage/local_store.dart';
import 'package:curvefree/core/storage/local_store_factory.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localStoreProvider = Provider<LocalStore>((Ref ref) {
  return createPlatformLocalStore();
});

final localStoreSnapshotProvider =
    AsyncNotifierProvider<LocalStoreController, LocalStoreSnapshot>(
      LocalStoreController.new,
    );

final class LocalStoreController extends AsyncNotifier<LocalStoreSnapshot> {
  @override
  Future<LocalStoreSnapshot> build() {
    return ref.read(localStoreProvider).read();
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(ref.read(localStoreProvider).read);
  }

  Future<String> exportBackup() {
    return ref.read(localStoreProvider).exportJson();
  }

  Future<void> importBackup(String rawJson) async {
    final snapshot = await ref.read(localStoreProvider).importJson(rawJson);
    state = AsyncData(snapshot);
  }

  Future<void> putSetting(String key, Object? value) async {
    final store = ref.read(localStoreProvider);
    await store.mutate((LocalStoreSnapshot current) {
      final nextSettings = Map<String, Object?>.from(current.settings)
        ..[key] = value;
      return current.copyWith(settings: nextSettings);
    });
    state = AsyncData(await store.read());
  }
}
