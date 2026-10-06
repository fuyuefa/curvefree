import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/storage/local_store_providers.dart';
import 'package:curvefree/features/home/widgets/module_tile.dart';
import 'package:curvefree/features/home/widgets/storage_status_card.dart';
import 'package:curvefree/features/nutrition/pages/nutrition_page.dart';
import 'package:curvefree/features/training/pages/training_log_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStore = ref.watch(localStoreSnapshotProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            Text(
              AppStrings.appNameZh,
              key: const Key('home_brand'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.tagline,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            asyncStore.when(
              data: (snapshot) => StorageStatusCard(
                ready: true,
                hasUserData: snapshot.hasUserData,
                schemaVersion: snapshot.schemaVersion,
                onExport: () => _exportBackup(context, ref),
              ),
              loading: () => const StorageStatusCard(
                ready: false,
                hasUserData: false,
                schemaVersion: 0,
              ),
              error: (Object error, StackTrace stack) => StorageStatusCard(
                ready: false,
                hasUserData: false,
                schemaVersion: 0,
                errorMessage: error.toString(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('今日', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ModuleTile(
              key: const Key('tile_training'),
              title: AppStrings.training,
              subtitle: AppStrings.trainingHint,
              icon: Icons.fitness_center,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TrainingLogPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ModuleTile(
              key: const Key('tile_nutrition'),
              title: AppStrings.nutrition,
              subtitle: AppStrings.nutritionHint,
              icon: Icons.restaurant,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NutritionPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              AppStrings.gplNotice,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final json = await ref
          .read(localStoreSnapshotProvider.notifier)
          .exportBackup();
      await Clipboard.setData(ClipboardData(text: json));
      messenger.showSnackBar(const SnackBar(content: Text('备份 JSON 已复制到剪贴板')));
    } on Object catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('导出失败：$error')));
    }
  }
}
