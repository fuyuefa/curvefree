/// Local-only identifiers. Prefix keeps collections distinguishable in backups.
abstract final class EntityIds {
  static int _sequence = 0;

  static String next(String prefix) {
    _sequence += 1;
    final micros = DateTime.now().toUtc().microsecondsSinceEpoch;
    return '${prefix}_${micros}_$_sequence';
  }
}
