import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:curvefree/core/backup/backup_file_gateway.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/storage/atomic_file_write.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

BackupFileGateway createBackupFileGateway() => const IoBackupFileGateway();

final class IoBackupFileGateway implements BackupFileGateway {
  const IoBackupFileGateway();

  @override
  Future<BackupExportResult> exportFile({
    required String fileName,
    required String contents,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(directory.path, BackupFiles.directoryName));
    final file = File(p.join(folder.path, fileName));
    await writeFileAtomically(file, contents);
    await _presentToUser(fileName: fileName, contents: contents, file: file);
    return BackupExportResult(savedPath: file.path);
  }

  Future<void> _presentToUser({
    required String fileName,
    required String contents,
    required File file,
  }) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[
            XFile(file.path, mimeType: BackupFiles.mimeType, name: fileName),
          ],
          subject: AppStrings.backupShareSubject,
          fileNameOverrides: <String>[fileName],
        ),
      );
      return;
    }
    await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(contents)),
      mimeType: BackupFiles.mimeType,
      dialogTitle: AppStrings.backupSaveDialog,
      type: FileType.custom,
      allowedExtensions: BackupFiles.extensions,
    );
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
    return _decodeBackupText(bytes);
  }
}

String _decodeBackupText(List<int> bytes) {
  var text = utf8.decode(bytes);
  if (text.startsWith('\uFEFF')) {
    text = text.substring(1);
  }
  return text;
}
