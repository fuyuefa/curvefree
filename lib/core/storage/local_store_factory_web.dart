import 'package:curvefree/core/storage/local_store.dart';
import 'package:curvefree/core/storage/prefs_local_store.dart';

LocalStore createPlatformLocalStore() => PrefsLocalStore();
