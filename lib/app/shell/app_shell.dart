import 'package:curvefree/app/shell/app_tab.dart';
import 'package:curvefree/app/shell/curve_bottom_nav.dart';
import 'package:curvefree/features/home/home_page.dart';
import 'package:curvefree/features/me/me_page.dart';
import 'package:curvefree/features/nutrition/pages/nutrition_page.dart';
import 'package:curvefree/features/training/pages/training_log_page.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _tab = AppTab.today;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('app_shell'),
      body: switch (_tab) {
        AppTab.today => const HomePage(),
        AppTab.training => const TrainingLogPage(),
        AppTab.nutrition => const NutritionPage(),
        AppTab.me => const MePage(),
      },
      bottomNavigationBar: CurveBottomNav(
        current: _tab,
        onSelect: (AppTab tab) => setState(() => _tab = tab),
      ),
    );
  }
}
