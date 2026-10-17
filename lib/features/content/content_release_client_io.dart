import 'dart:io';
import 'dart:typed_data';

import 'package:curvefree/features/content/content_constants.dart';
import 'package:curvefree/features/content/content_manifest.dart';
import 'package:curvefree/features/content/content_release.dart';

ContentReleaseClient createContentReleaseClient() =>
    const _GitHubReleaseClient();

final class _GitHubReleaseClient implements ContentReleaseClient {
  const _GitHubReleaseClient();

  @override
  Future<List<int>> get(Uri uri) async {
    final HttpClient client = HttpClient();
    try {
      final HttpClientRequest request = await client
          .getUrl(uri)
          .timeout(ContentPackLimits.networkTimeout);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        ContentPackLimits.userAgent,
      );
      request.headers.set(
        HttpHeaders.acceptHeader,
        ContentPackLimits.githubAccept,
      );
      final HttpClientResponse response = await request.close().timeout(
        ContentPackLimits.networkTimeout,
      );
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw ContentNetworkException('status ${response.statusCode}');
      }
      if (response.contentLength > ContentPackLimits.maxAssetBytes) {
        await response.drain<void>();
        throw const ContentPackFormatException('asset size');
      }
      final BytesBuilder builder = BytesBuilder(copy: false);
      await for (final List<int> chunk in response.timeout(
        ContentPackLimits.networkTimeout,
      )) {
        builder.add(chunk);
        if (builder.length > ContentPackLimits.maxAssetBytes) {
          throw const ContentPackFormatException('asset size');
        }
      }
      return builder.takeBytes();
    } on ContentNetworkException {
      rethrow;
    } on ContentPackFormatException {
      rethrow;
    } on Object catch (error) {
      throw ContentNetworkException(error.toString());
    } finally {
      client.close(force: true);
    }
  }
}
