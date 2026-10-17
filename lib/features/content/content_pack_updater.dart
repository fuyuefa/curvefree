import 'dart:convert';

import 'package:curvefree/features/content/content_constants.dart';
import 'package:curvefree/features/content/content_hash.dart';
import 'package:curvefree/features/content/content_manifest.dart';
import 'package:curvefree/features/content/content_pack_store.dart';
import 'package:curvefree/features/content/content_release.dart';

enum ContentUpdateOutcome {
  updated,
  alreadyCurrent,
  offline,
  rejected,
  unavailable,
  noRelease,
  failed,
}

final class ContentPackUpdater {
  ContentPackUpdater({required this.client, required this.store});

  final ContentReleaseClient client;
  final ContentPackStore store;

  /// Repo coordinates come from [bundled], never from an installed pack.
  Future<ContentUpdateOutcome> update({
    required ContentManifest bundled,
    required String rootPath,
  }) async {
    if (bundled.update.service != ContentUpdateService.githubReleases) {
      return ContentUpdateOutcome.rejected;
    }
    final List<int> releaseBytes = await client.get(
      githubReleasesUri(bundled.update),
    );
    final List<ContentRelease> releases;
    try {
      releases = parseContentReleases(utf8.decode(releaseBytes));
    } on ContentPackFormatException {
      return ContentUpdateOutcome.rejected;
    } on FormatException {
      return ContentUpdateOutcome.rejected;
    }
    ContentRelease? chosen;
    for (final ContentRelease release in releases) {
      if (release.assetNamed(bundled.update.manifestAsset) != null) {
        chosen = release;
        break;
      }
    }
    if (chosen == null) {
      return ContentUpdateOutcome.noRelease;
    }
    final ContentAsset manifestAsset = chosen.assetNamed(
      bundled.update.manifestAsset,
    )!;
    final List<int>? manifestBytes = await _download(manifestAsset.url);
    if (manifestBytes == null) {
      return ContentUpdateOutcome.rejected;
    }
    final ContentManifest remote;
    try {
      remote = ContentManifest.parse(utf8.decode(manifestBytes));
    } on ContentPackFormatException {
      return ContentUpdateOutcome.rejected;
    } on FormatException {
      return ContentUpdateOutcome.rejected;
    }
    if (remote.format != ContentFormat.version) {
      return ContentUpdateOutcome.rejected;
    }
    final Map<String, List<int>> files = <String, List<int>>{};
    for (final ContentFileSpec spec in remote.packs) {
      if (!isSafeContentFileName(spec.file)) {
        return ContentUpdateOutcome.rejected;
      }
      final ContentAsset? asset = chosen.assetNamed(spec.file);
      if (asset == null) {
        return ContentUpdateOutcome.rejected;
      }
      final List<int>? bytes = await _download(asset.url);
      if (bytes == null) {
        return ContentUpdateOutcome.rejected;
      }
      if (sha256Hex(bytes) != spec.sha256) {
        return ContentUpdateOutcome.rejected;
      }
      files[spec.file] = bytes;
    }
    final VerifiedPack? installed = await store.readInstalled(rootPath);
    final ContentManifest current = installed?.manifest ?? bundled;
    if (_sameBytes(current, remote)) {
      return ContentUpdateOutcome.alreadyCurrent;
    }
    try {
      await store.publish(
        rootPath: rootPath,
        manifestBytes: manifestBytes,
        files: files,
      );
    } on ContentPackFormatException {
      return ContentUpdateOutcome.rejected;
    }
    return ContentUpdateOutcome.updated;
  }

  Future<List<int>?> _download(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !isAllowedContentDownloadUrl(uri)) {
      return null;
    }
    final List<int> bytes = await client.get(uri);
    if (bytes.length > ContentPackLimits.maxAssetBytes) {
      return null;
    }
    return bytes;
  }

  bool _sameBytes(ContentManifest current, ContentManifest remote) {
    return current.version == remote.version &&
        current.exercises.sha256 == remote.exercises.sha256 &&
        current.foods.sha256 == remote.foods.sha256;
  }
}
