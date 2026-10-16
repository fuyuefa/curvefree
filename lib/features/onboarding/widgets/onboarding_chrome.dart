import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/features/onboarding/onboarding_constants.dart';
import 'package:flutter/material.dart';

class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.body,
    this.progressIndex,
    this.onBack,
    required this.primaryLabel,
    required this.onPrimary,
    required this.primaryEnabled,
    this.secondary,
  });

  final Widget body;
  final int? progressIndex;
  final VoidCallback? onBack;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryEnabled;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    final int? index = progressIndex;
    return Scaffold(
      key: const Key('onb_root'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _TopBar(onBack: onBack, progressIndex: index),
              if (index != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                _CollectProgress(index: index, colors: colors),
              ],
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: SingleChildScrollView(child: body)),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                key: const Key('onb_primary'),
                onPressed: primaryEnabled ? onPrimary : null,
                child: Text(primaryLabel),
              ),
              if (secondary != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                secondary!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.progressIndex});

  final VoidCallback? onBack;
  final int? progressIndex;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return SizedBox(
      height: 40,
      child: Row(
        children: <Widget>[
          if (onBack != null)
            IconButton(
              key: const Key('onb_back'),
              tooltip: OnboardingCopy.back,
              onPressed: onBack,
              icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          if (progressIndex != null)
            Text(
              OnboardingCopy.progressLabel(progressIndex!),
              key: const Key('onb_progress'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}

class _CollectProgress extends StatelessWidget {
  const _CollectProgress({required this.index, required this.colors});

  final int index;
  final CurveColors colors;

  @override
  Widget build(BuildContext context) {
    final double fraction = index / OnboardingLimits.collectCount;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.chip),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: AppLayout.progressBarHeight,
        backgroundColor: colors.muted,
        color: colors.primary,
      ),
    );
  }
}

class OnboardingSelectCard extends StatelessWidget {
  const OnboardingSelectCard({
    super.key,
    required this.cardKey,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
  });

  final Key cardKey;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected ? colors.primarySoft : colors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: InkWell(
          key: cardKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(
                color: selected ? colors.primary : colors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  leading!,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingStepHeader extends StatelessWidget {
  const OnboardingStepHeader({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
