import 'dart:convert';
import 'dart:typed_data';

import 'package:curvefree/core/backup/backup_file_gateway.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:file_picker/file_picker.dart';

BackupFileGateway createBackupFileGateway() => const WebBackupFileGateway();

final class WebBackupFileGateway implements BackupFileGateway {
  const WebBackupFileGateway();

  @override
  Future<BackupExportResult> exportFile({
    required String fileName,
    required String contents,
  }) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(contents)),
      mimeType: BackupFiles.mimeType,
      dialogTitle: AppStrings.backupSaveDialog,
      type: FileType.custom,
      allowedExtensions: BackupFiles.extensions,
    );
    return BackupExportResult(savedPath: uri?.toString());
  }

  @override
  Future<String?> pickTextFile() async {
    final file = await FilePicker.pickFile(
      dialogTitle: AppStrings.backupPickDialog,
      type: FileType.custom,
      allowedExtensions: BackupFiles.extensions,
    );
    if (file == null) {
      return null;
    }
    final bytes = await file.readAsBytes();
    var text = utf8.decode(bytes);
    if (text.startsWith('\uFEFF')) {
      text = text.substring(1);
    }
    return text;
  }
}
