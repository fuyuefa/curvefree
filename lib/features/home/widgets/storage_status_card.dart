import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:flutter/material.dart';

class StorageStatusCard extends StatelessWidget {
  const StorageStatusCard({
    super.key,
    required this.ready,
    required this.hasUserData,
    required this.schemaVersion,
    this.errorMessage,
    this.onExport,
  });

  final bool ready;
  final bool hasUserData;
  final int schemaVersion;
  final String? errorMessage;
  final Future<void> Function()? onExport;

  @override
  Widget build(BuildContext context) {
    final String statusLabel;
    if (errorMessage != null) {
      statusLabel = '本地库异常';
    } else if (!ready) {
      statusLabel = '正在初始化本地库…';
    } else if (hasUserData) {
      statusLabel = AppStrings.storageReady;
    } else {
      statusLabel = AppStrings.storageEmpty;
    }

    return Container(
      key: const Key('storage_status_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(AppColors.surface),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.localData,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(statusLabel, style: Theme.of(context).textTheme.bodyMedium),
          if (ready && errorMessage == null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'schema v$schemaVersion · 无云同步',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              errorMessage!,
              style: const TextStyle(color: Color(AppColors.danger)),
            ),
          ],
          if (onExport != null && ready && errorMessage == null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              key: const Key('btn_export_backup'),
              onPressed: () {
                onExport?.call();
              },
              child: const Text(AppStrings.exportBackup),
            ),
          ],
        ],
      ),
    );
  }
}
