import 'package:curvefree/app/shell/app_tab.dart';
import 'package:curvefree/app/shell/curve_bottom_nav.dart';
import 'package:curvefree/app/shell/shell_tab.dart';
import 'package:curvefree/features/home/home_page.dart';
import 'package:curvefree/features/me/me_page.dart';
import 'package:curvefree/features/nutrition/pages/nutrition_page.dart';
import 'package:curvefree/features/training/pages/training_log_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppTab tab = ref.watch(shellTabProvider);
    return Scaffold(
      key: const Key('app_shell'),
      body: switch (tab) {
        AppTab.today => const HomePage(),
        AppTab.training => const TrainingLogPage(),
        AppTab.nutrition => const NutritionPage(),
        AppTab.me => const MePage(),
      },
      bottomNavigationBar: CurveBottomNav(
        current: tab,
        onSelect: (AppTab next) {
          ref.read(shellTabProvider.notifier).select(next);
        },
      ),
    );
  }
}
