import 'package:curvefree/core/storage/local_store_providers.dart';
import 'package:curvefree/features/cycle/models/cycle_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cycleProfileProvider =
    NotifierProvider<CycleProfileController, CycleProfile>(
      CycleProfileController.new,
    );

final class CycleProfileController extends Notifier<CycleProfile> {
  @override
  CycleProfile build() {
    final Map<String, Object?>? settings = ref
        .watch(localStoreSnapshotProvider)
        .valueOrNull
        ?.settings;
    if (settings == null) {
      return CycleProfile.empty;
    }
    return CycleProfile.fromSettings(settings);
  }

  Future<void> save(CycleProfile profile) async {
    await ref
        .read(localStoreSnapshotProvider.notifier)
        .putSetting(CycleProfile.settingsKey, profile.toJson());
    state = profile;
  }
}
