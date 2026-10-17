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
          children: <Widget>[
            const TodayHeader(),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              AppStrings.localOnlyNotice,
              key: const Key('home_local_only'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            const TodayTrainingSection(),
          ],
        ),
      ),
    );
  }
}
