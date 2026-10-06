import 'package:curvefree/core/storage/local_store.dart';
import 'package:curvefree/core/storage/local_store_factory_stub.dart'
    if (dart.library.html) 'package:curvefree/core/storage/local_store_factory_web.dart'
    if (dart.library.io) 'package:curvefree/core/storage/local_store_factory_io.dart'
    as impl;

LocalStore createPlatformLocalStore() => impl.createPlatformLocalStore();
