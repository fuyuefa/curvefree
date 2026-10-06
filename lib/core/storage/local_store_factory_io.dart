import 'package:curvefree/core/storage/file_local_store.dart';
import 'package:curvefree/core/storage/local_store.dart';

LocalStore createPlatformLocalStore() => FileLocalStore();
