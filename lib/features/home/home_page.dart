import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/home/widgets/today_header.dart';
import 'package:curvefree/features/home/widgets/today_training_section.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          children: const <Widget>[
            TodayHeader(),
            SizedBox(height: AppSpacing.sm),
            TodayTrainingSection(),
          ],
        ),
      ),
    );
  }
}
