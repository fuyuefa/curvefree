import 'package:curvefree/core/backup/backup_file_gateway.dart';

BackupFileGateway createBackupFileGateway() =>
    const UnsupportedBackupFileGateway();

final class UnsupportedBackupFileGateway implements BackupFileGateway {
  const UnsupportedBackupFileGateway();

  @override
  Future<BackupExportResult> exportFile({
    required String fileName,
    required String contents,
  }) {
    throw UnsupportedError('当前平台不能导出备份文件');
  }

  @override
  Future<String?> pickTextFile() {
    throw UnsupportedError('当前平台不能选择备份文件');
  }
}
