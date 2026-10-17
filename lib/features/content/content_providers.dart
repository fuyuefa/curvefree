import 'package:curvefree/features/content/content_constants.dart';
import 'package:curvefree/features/content/content_manifest.dart';
import 'package:curvefree/features/content/content_pack_session.dart';
import 'package:curvefree/features/content/content_pack_store_factory.dart';
import 'package:curvefree/features/content/content_pack_updater.dart';
import 'package:curvefree/features/content/content_release.dart';
import 'package:curvefree/features/content/content_release_client_factory.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final contentSnapshotProvider = FutureProvider<ContentSnapshot>((Ref ref) {
  return ContentPackSession.ensureLoaded();
});

final contentReleaseClientProvider = Provider<ContentReleaseClient>((Ref ref) {
  return createContentReleaseClient();
});

final contentPackUpdaterProvider = Provider<ContentPackUpdater>((Ref ref) {
  return ContentPackUpdater(
    client: ref.watch(contentReleaseClientProvider),
    store: createContentPackStore(),
  );
});

Future<ContentUpdateOutcome> checkContentPackUpdate(
  ContentPackUpdater updater,
) async {
  try {
    final ContentManifest bundled = ContentManifest.parse(
      await rootBundle.loadString(ContentAssets.manifest),
    );
    final String? root = await updater.store.applicationRootPath();
    if (root == null) {
      return ContentUpdateOutcome.unavailable;
    }
    return await updater.update(bundled: bundled, rootPath: root);
  } on ContentNetworkException {
    return ContentUpdateOutcome.offline;
  } on ContentUpdateUnavailable {
    return ContentUpdateOutcome.unavailable;
  } on ContentPackFormatException {
    return ContentUpdateOutcome.rejected;
  } on Object {
    return ContentUpdateOutcome.failed;
  }
}
