/// User-chosen backup file. The app never uploads the document itself.
abstract interface class BackupFileGateway {
  Future<BackupExportResult> exportFile({
    required String fileName,
    required String contents,
  });

  /// Returns the picked file text, or null when the user cancels.
  Future<String?> pickTextFile();
}

final class BackupExportResult {
  const BackupExportResult({this.savedPath});

  /// On-device path or save-dialog URI. Null when the user cancelled
  /// before any file was written.
  final String? savedPath;

  bool get saved => savedPath != null && savedPath!.isNotEmpty;
}

abstract final class BackupFiles {
  static const String directoryName = 'backups';
  static const String prefix = 'curvefree-backup';
  static const String extension = '.json';
  static const String mimeType = 'application/json';
  static const List<String> extensions = <String>['json'];

  static String stamped(DateTime time) {
    final local = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '$prefix-'
        '${local.year}${two(local.month)}${two(local.day)}-'
        '${two(local.hour)}${two(local.minute)}$extension';
  }
}
