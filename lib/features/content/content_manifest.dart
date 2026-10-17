import 'dart:convert';

import 'package:curvefree/features/content/content_constants.dart';

final class ContentPackFormatException implements Exception {
  const ContentPackFormatException(this.message);

  final String message;

  @override
  String toString() => 'ContentPackFormatException: $message';
}

final class ContentNetworkException implements Exception {
  const ContentNetworkException(this.message);

  final String message;

  @override
  String toString() => 'ContentNetworkException: $message';
}

/// Web and other hosts that cannot swap a local pack directory.
final class ContentUpdateUnavailable implements Exception {
  const ContentUpdateUnavailable();
}

final class ContentFileSpec {
  const ContentFileSpec({
    required this.id,
    required this.version,
    required this.file,
    required this.license,
    required this.sourceUrl,
    required this.sha256,
    this.licenseUrl = '',
  });

  final String id;
  final String version;
  final String file;
  final String license;
  final String licenseUrl;
  final String sourceUrl;
  final String sha256;

  static ContentFileSpec parse(Object? raw, String field) {
    final Map<String, Object?> json = _asMap(raw, field);
    return ContentFileSpec(
      id: _requiredString(json, ContentJsonKeys.id),
      version: _requiredString(json, ContentJsonKeys.version),
      file: _requiredString(json, ContentJsonKeys.file),
      license: _requiredString(json, ContentJsonKeys.license),
      sourceUrl: _requiredString(json, ContentJsonKeys.sourceUrl),
      sha256: _sha256(json),
      licenseUrl: _optionalString(json, ContentJsonKeys.licenseUrl),
    );
  }
}

final class ContentUpdateSource {
  const ContentUpdateSource({
    required this.service,
    required this.owner,
    required this.repo,
    required this.manifestAsset,
  });

  final String service;
  final String owner;
  final String repo;
  final String manifestAsset;

  static ContentUpdateSource parse(Object? raw) {
    final Map<String, Object?> json = _asMap(raw, ContentJsonKeys.update);
    return ContentUpdateSource(
      service: _requiredString(json, ContentJsonKeys.service),
      owner: _requiredString(json, ContentJsonKeys.owner),
      repo: _requiredString(json, ContentJsonKeys.repo),
      manifestAsset: _requiredString(json, ContentJsonKeys.manifestAsset),
    );
  }
}

final class ContentManifest {
  const ContentManifest({
    required this.format,
    required this.id,
    required this.version,
    required this.exercises,
    required this.foods,
    required this.update,
  });

  final int format;
  final String id;
  final String version;
  final ContentFileSpec exercises;
  final ContentFileSpec foods;
  final ContentUpdateSource update;

  List<ContentFileSpec> get packs => <ContentFileSpec>[exercises, foods];

  static ContentManifest parse(String raw) {
    final Object? decoded = jsonDecode(raw);
    final Map<String, Object?> json = _asMap(decoded, 'manifest');
    final Object? format = json[ContentJsonKeys.format];
    if (format is! int) {
      throw const ContentPackFormatException(ContentJsonKeys.format);
    }
    return ContentManifest(
      format: format,
      id: _requiredString(json, ContentJsonKeys.id),
      version: _requiredString(json, ContentJsonKeys.version),
      exercises: ContentFileSpec.parse(
        json[ContentJsonKeys.exercises],
        ContentJsonKeys.exercises,
      ),
      foods: ContentFileSpec.parse(
        json[ContentJsonKeys.foods],
        ContentJsonKeys.foods,
      ),
      update: ContentUpdateSource.parse(json[ContentJsonKeys.update]),
    );
  }
}

Map<String, Object?> _asMap(Object? raw, String field) {
  if (raw is! Map) {
    throw ContentPackFormatException(field);
  }
  return raw.map(
    (Object? key, Object? value) => MapEntry(key.toString(), value),
  );
}

String _requiredString(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw ContentPackFormatException(key);
  }
  return value.trim();
}

String _optionalString(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value == null) {
    return '';
  }
  if (value is! String) {
    throw ContentPackFormatException(key);
  }
  return value.trim();
}

String _sha256(Map<String, Object?> json) {
  final String value = _requiredString(json, ContentJsonKeys.sha256);
  if (value.length != ContentPackLimits.sha256HexLength ||
      !RegExp(r'^[0-9a-f]+$').hasMatch(value)) {
    throw const ContentPackFormatException(ContentJsonKeys.sha256);
  }
  return value;
}
