import 'package:curvefree/features/content/content_manifest.dart';

/// A verified installed pack. File bytes already matched the manifest hashes.
final class VerifiedPack {
  const VerifiedPack({
    required this.manifest,
    required this.exercisesRaw,
    required this.foodsRaw,
  });

  final ContentManifest manifest;
  final String exercisesRaw;
  final String foodsRaw;
}

abstract class ContentPackStore {
  Future<String?> applicationRootPath();

  Future<VerifiedPack?> readInstalled(String rootPath);

  Future<void> publish({
    required String rootPath,
    required List<int> manifestBytes,
    required Map<String, List<int>> files,
  });
}
