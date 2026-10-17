/// Content-pack format, asset paths, and download limits.
abstract final class ContentFormat {
  static const int version = 1;
}

abstract final class ContentAssets {
  static const String manifest = 'assets/content/manifest.json';
  static const String exercises = 'assets/content/exercises.json';
  static const String foods = 'assets/content/foods.json';
  static const String attribution = 'assets/content/ATTRIBUTION.md';
}

abstract final class ContentPackPaths {
  static const String folderName = 'content-pack';
  static const String pointerName = 'active-slot.txt';
  static const String slotA = 'a';
  static const String slotB = 'b';
}

abstract final class ContentFileNames {
  /// Installed copy of the release manifest. Distinct from the asset name.
  static const String manifest = 'manifest.json';
}

abstract final class ContentPackLimits {
  static const int releasePageSize = 10;
  static const int bytesPerKibibyte = 1024;
  static const int maxAssetMebibytes = 5;
  static const int maxAssetBytes =
      maxAssetMebibytes * bytesPerKibibyte * bytesPerKibibyte;
  static const int maxFileNameLength = 128;
  static const int sha256HexLength = 64;
  static const Duration networkTimeout = Duration(seconds: 20);
  static const String userAgent = 'curvefree';
  static const String githubAccept = 'application/vnd.github+json';
  static const String githubApiHost = 'api.github.com';
}

abstract final class ContentUpdateService {
  static const String githubReleases = 'github-releases';
}

abstract final class ContentDownloadHosts {
  static const Set<String> allowed = <String>{
    'github.com',
    'objects.githubusercontent.com',
    'release-assets.githubusercontent.com',
    'githubusercontent.com',
  };
}

abstract final class ContentJsonKeys {
  static const String format = 'format';
  static const String id = 'id';
  static const String version = 'version';
  static const String exercises = 'exercises';
  static const String foods = 'foods';
  static const String update = 'update';
  static const String file = 'file';
  static const String license = 'license';
  static const String licenseUrl = 'licenseUrl';
  static const String sourceUrl = 'sourceUrl';
  static const String sha256 = 'sha256';
  static const String service = 'service';
  static const String owner = 'owner';
  static const String repo = 'repo';
  static const String manifestAsset = 'manifestAsset';
  static const String nameZh = 'nameZh';
  static const String nameEn = 'nameEn';
  static const String pattern = 'pattern';
  static const String equipment = 'equipment';
  static const String bodyParts = 'bodyParts';
  static const String sourceId = 'sourceId';
  static const String note = 'note';
  static const String assets = 'assets';
  static const String tagName = 'tag_name';
  static const String name = 'name';
  static const String browserDownloadUrl = 'browser_download_url';
}

abstract final class BodyPartIds {
  static const String chest = 'chest';
  static const String back = 'back';
  static const String shoulders = 'shoulders';
  static const String legs = 'legs';
  static const String glutes = 'glutes';
  static const String arms = 'arms';
  static const String core = 'core';

  static const Set<String> known = <String>{
    chest,
    back,
    shoulders,
    legs,
    glutes,
    arms,
    core,
  };
}
