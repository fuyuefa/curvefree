import 'package:curvefree/core/backup/backup_file_gateway.dart';
import 'package:curvefree/core/backup/backup_file_gateway_stub.dart'
    if (dart.library.html) 'package:curvefree/core/backup/backup_file_gateway_web.dart'
    if (dart.library.io) 'package:curvefree/core/backup/backup_file_gateway_io.dart'
    as impl;
import 'package:flutter_riverpod/flutter_riverpod.dart';

BackupFileGateway createBackupFileGateway() => impl.createBackupFileGateway();

final backupFileGatewayProvider = Provider<BackupFileGateway>((Ref ref) {
  return createBackupFileGateway();
});
