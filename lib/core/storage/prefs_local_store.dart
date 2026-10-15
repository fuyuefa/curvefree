import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/core/storage/queued_document_store.dart';
import 'package:curvefree/core/storage/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web-safe store using SharedPreferences (QA preview / browser).
final class PrefsLocalStore extends QueuedDocumentStore {
  PrefsLocalStore({this._preferences});

  SharedPreferences? _preferences;

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<LocalStoreSnapshot> readUnlocked() async {
    final prefs = await _prefs();
    final raw = prefs.getString(StorageKeys.webPrefsKey);
    if (raw == null || raw.trim().isEmpty) {
      final empty = LocalStoreSnapshot.empty();
      await writeUnlocked(empty);
      return empty;
    }
    return LocalStoreSnapshot.decode(
      raw,
      invalidRootMessage: '本地库根节点必须是 JSON 对象',
    );
  }

  @override
  Future<void> writeUnlocked(LocalStoreSnapshot snapshot) async {
    final prefs = await _prefs();
    await prefs.setString(StorageKeys.webPrefsKey, snapshot.encodePretty());
  }
}
