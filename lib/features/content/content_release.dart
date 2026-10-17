import 'dart:convert';

import 'package:curvefree/features/content/content_constants.dart';
import 'package:curvefree/features/content/content_manifest.dart';

abstract class ContentReleaseClient {
  Future<List<int>> get(Uri uri);
}

final class ContentAsset {
  const ContentAsset({required this.name, required this.url});

  final String name;
  final String url;
}

final class ContentRelease {
  const ContentRelease({required this.tagName, required this.assets});

  final String tagName;
  final List<ContentAsset> assets;

  ContentAsset? assetNamed(String name) {
    for (final ContentAsset asset in assets) {
      if (asset.name == name) {
        return asset;
      }
    }
    return null;
  }
}

bool isSafeContentFileName(String name) {
  if (name.isEmpty || name.length > ContentPackLimits.maxFileNameLength) {
    return false;
  }
  return RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(name);
}

bool isAllowedContentDownloadUrl(Uri uri) {
  return uri.scheme == 'https' &&
      ContentDownloadHosts.allowed.contains(uri.host);
}

/// Releases index for the repo pinned in the bundled manifest.
Uri githubReleasesUri(ContentUpdateSource source) {
  if (!isSafeContentFileName(source.owner) ||
      !isSafeContentFileName(source.repo)) {
    throw const ContentPackFormatException('repo');
  }
  return Uri.https(
    ContentPackLimits.githubApiHost,
    '/repos/${source.owner}/${source.repo}/releases',
    <String, String>{'per_page': '${ContentPackLimits.releasePageSize}'},
  );
}

List<ContentRelease> parseContentReleases(String raw) {
  final Object? decoded = jsonDecode(raw);
  if (decoded is! List) {
    throw const ContentPackFormatException(ContentJsonKeys.assets);
  }
  final List<ContentRelease> releases = <ContentRelease>[];
  for (final Object? item in decoded) {
    if (item is! Map) {
      throw const ContentPackFormatException(ContentJsonKeys.assets);
    }
    final Map<String, Object?> json = item.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );
    final Object? tag = json[ContentJsonKeys.tagName];
    final String tagName = tag is String ? tag : '';
    final Object? assetsRaw = json[ContentJsonKeys.assets];
    if (assetsRaw is! List) {
      throw const ContentPackFormatException(ContentJsonKeys.assets);
    }
    final List<ContentAsset> assets = <ContentAsset>[];
    for (final Object? assetRaw in assetsRaw) {
      if (assetRaw is! Map) {
        throw const ContentPackFormatException(ContentJsonKeys.assets);
      }
      final Map<String, Object?> asset = assetRaw.map(
        (Object? key, Object? value) => MapEntry(key.toString(), value),
      );
      final Object? name = asset[ContentJsonKeys.name];
      final Object? url = asset[ContentJsonKeys.browserDownloadUrl];
      if (name is! String || url is! String || name.isEmpty || url.isEmpty) {
        throw const ContentPackFormatException(
          ContentJsonKeys.browserDownloadUrl,
        );
      }
      assets.add(ContentAsset(name: name, url: url));
    }
    releases.add(ContentRelease(tagName: tagName, assets: assets));
  }
  return releases;
}
