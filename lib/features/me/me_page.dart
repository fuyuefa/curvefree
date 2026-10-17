import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/app/theme/curve_surfaces.dart';
import 'package:curvefree/app/theme/theme_mode.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/storage/local_store_providers.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/features/cycle/cycle_constants.dart';
import 'package:curvefree/features/cycle/cycle_providers.dart';
import 'package:curvefree/features/cycle/models/cycle_profile.dart';
import 'package:curvefree/features/cycle/pages/cycle_page.dart';
import 'package:curvefree/features/home/home_backup.dart';
import 'package:curvefree/features/home/widgets/storage_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MePage extends ConsumerWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    final CycleProfile cycle = ref.watch(cycleProfileProvider);
    final AsyncValue<LocalStoreSnapshot> asyncStore = ref.watch(
      localStoreSnapshotProvider,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          children: <Widget>[
            Text(
              AppStrings.navMe,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xxs),
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
            Text(
              AppStrings.themeAppearance,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                _ThemeChip(
                  chipKey: const Key('theme_system'),
                  label: AppStrings.themeSystem,
                  selected: mode == ThemeMode.system,
                  onSelected: () => _setMode(ref, ThemeMode.system),
                ),
                _ThemeChip(
                  chipKey: const Key('theme_light'),
                  label: AppStrings.themeLight,
                  selected: mode == ThemeMode.light,
                  onSelected: () => _setMode(ref, ThemeMode.light),
                ),
                _ThemeChip(
                  chipKey: const Key('theme_dark'),
                  label: AppStrings.themeDark,
                  selected: mode == ThemeMode.dark,
                  onSelected: () => _setMode(ref, ThemeMode.dark),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _CycleEntry(
              subtitle: cycle.meSubtitle,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CyclePage()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            asyncStore.when(
              data: (LocalStoreSnapshot snapshot) => StorageStatusCard(
                ready: true,
                hasUserData: snapshot.hasUserData,
                schemaVersion: snapshot.schemaVersion,
                onExport: () => exportLocalBackup(context, ref),
                onImport: () => restoreLocalBackup(context, ref),
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

  void _setMode(WidgetRef ref, ThemeMode mode) {
    ref.read(themeModeProvider.notifier).state = mode;
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.chipKey,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final Key chipKey;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return ChoiceChip(
      key: chipKey,
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      backgroundColor: colors.muted,
      selectedColor: colors.primarySoft,
      labelStyle: TextStyle(
        color: selected ? colors.primary : colors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        fontFamily: AppFonts.ui,
        fontFamilyFallback: AppFonts.cjkFallback,
      ),
      side: BorderSide(color: selected ? colors.primary : colors.border),
      shape: const StadiumBorder(),
      onSelected: (bool _) => onSelected(),
    );
  }
}

class _CycleEntry extends StatelessWidget {
  const _CycleEntry({required this.subtitle, required this.onTap});

  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        key: const Key('me_cycle_entry'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: curveSurfaceDecoration(colors),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      CycleCopy.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      key: const Key('me_cycle_subtitle'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
