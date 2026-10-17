import 'package:curvefree/features/content/content_pack_store.dart';
import 'package:curvefree/features/content/content_pack_store_stub.dart'
    if (dart.library.html) 'package:curvefree/features/content/content_pack_store_stub.dart'
    if (dart.library.io) 'package:curvefree/features/content/content_pack_store_io.dart'
    as impl;

ContentPackStore createContentPackStore() => impl.createContentPackStore();
