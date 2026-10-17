import 'package:curvefree/features/content/content_release.dart';
import 'package:curvefree/features/content/content_release_client_stub.dart'
    if (dart.library.html) 'package:curvefree/features/content/content_release_client_stub.dart'
    if (dart.library.io) 'package:curvefree/features/content/content_release_client_io.dart'
    as impl;

ContentReleaseClient createContentReleaseClient() =>
    impl.createContentReleaseClient();
