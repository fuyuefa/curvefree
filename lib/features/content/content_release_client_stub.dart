import 'package:curvefree/features/content/content_manifest.dart';
import 'package:curvefree/features/content/content_release.dart';

ContentReleaseClient createContentReleaseClient() =>
    const _UnavailableReleaseClient();

final class _UnavailableReleaseClient implements ContentReleaseClient {
  const _UnavailableReleaseClient();

  @override
  Future<List<int>> get(Uri uri) async {
    throw const ContentUpdateUnavailable();
  }
}
