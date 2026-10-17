import 'package:curvefree/features/content/content_manifest.dart';
import 'package:curvefree/features/content/content_pack_store.dart';

ContentPackStore createContentPackStore() =>
    const UnavailableContentPackStore();

final class UnavailableContentPackStore implements ContentPackStore {
  const UnavailableContentPackStore();

  @override
  Future<String?> applicationRootPath() async => null;

  @override
  Future<VerifiedPack?> readInstalled(String rootPath) async => null;

  @override
  Future<void> publish({
    required String rootPath,
    required List<int> manifestBytes,
    required Map<String, List<int>> files,
  }) async {
    throw const ContentUpdateUnavailable();
  }
}
