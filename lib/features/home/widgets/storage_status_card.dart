import 'dart:async';

import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/app/theme/curve_surfaces.dart';
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
    this.onImport,
  });

  final bool ready;
  final bool hasUserData;
  final int schemaVersion;
  final String? errorMessage;
  final Future<void> Function()? onExport;
  final Future<void> Function()? onImport;

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

    final CurveColors colors = CurveColors.of(context);
    return Container(
      key: const Key('storage_status_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: curveSurfaceDecoration(colors),
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
            Text(errorMessage!, style: TextStyle(color: colors.error)),
          ],
          if (ready &&
              errorMessage == null &&
              (onExport != null || onImport != null)) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (onExport != null)
                  OutlinedButton(
                    key: const Key('btn_export_backup'),
                    onPressed: () {
                      final export = onExport;
                      if (export != null) {
                        unawaited(export());
                      }
                    },
                    child: const Text(AppStrings.exportBackup),
                  ),
                if (onImport != null)
                  OutlinedButton(
                    key: const Key('btn_import_backup'),
                    onPressed: () {
                      final restore = onImport;
                      if (restore != null) {
                        unawaited(restore());
                      }
                    },
                    child: const Text(AppStrings.importBackup),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
