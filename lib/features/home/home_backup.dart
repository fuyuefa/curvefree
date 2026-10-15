import 'package:curvefree/core/backup/backup_file_gateway.dart';
import 'package:curvefree/core/backup/backup_file_gateway_factory.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/storage/local_store_providers.dart';
import 'package:curvefree/features/nutrition/nutrition_providers.dart';
import 'package:curvefree/features/training/training_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> exportLocalBackup(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final json = await ref
        .read(localStoreSnapshotProvider.notifier)
        .exportBackup();
    final result = await ref
        .read(backupFileGatewayProvider)
        .exportFile(
          fileName: BackupFiles.stamped(DateTime.now()),
          contents: json,
        );
    if (!result.saved) {
      return;
    }
    _showMessage(messenger, AppStrings.backupSaved);
  } on Object catch (error) {
    _showMessage(messenger, '${AppStrings.backupExportFailed}：$error');
  }
}

Future<void> restoreLocalBackup(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final raw = await ref.read(backupFileGatewayProvider).pickTextFile();
    if (raw == null || !context.mounted) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(AppStrings.backupRestoreTitle),
          content: const Text(AppStrings.backupRestoreBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              key: const Key('btn_confirm_restore'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(AppStrings.confirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref.read(localStoreSnapshotProvider.notifier).importBackup(raw);
    ref.invalidate(workoutSessionsProvider);
    ref.invalidate(foodLogsProvider);
    _showMessage(messenger, AppStrings.backupRestored);
  } on Object catch (error) {
    _showMessage(messenger, '${AppStrings.backupImportFailed}：$error');
  }
}

void _showMessage(ScaffoldMessengerState messenger, String message) {
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}
