import 'package:curvefree/app/shell/app_shell.dart';
import 'package:curvefree/core/storage/local_store_providers.dart';
import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/features/onboarding/onboarding_entry.dart';
import 'package:curvefree/features/onboarding/pages/onboarding_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Release skips a finished profile or existing local records.
/// Debug, profile, and `FORCE_ONBOARDING` still open the flow; see
/// [shouldPresentOnboarding].
class OnboardingGate extends ConsumerWidget {
  const OnboardingGate({super.key, required this.skipOnboarding});

  /// Widget tests of the shell pass true. Production leaves this false.
  final bool skipOnboarding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (skipOnboarding) {
      return const AppShell();
    }
    final bool dismissed = ref.watch(onboardingDismissedProvider);
    final AsyncValue<LocalStoreSnapshot> snapshot = ref.watch(
      localStoreSnapshotProvider,
    );
    return snapshot.when(
      loading: () => const Scaffold(body: SizedBox.shrink()),
      error: (Object error, StackTrace stack) => const AppShell(),
      data: (LocalStoreSnapshot data) {
        if (dismissed || !shouldPresentOnboarding(data)) {
          return const AppShell();
        }
        return const OnboardingFlow();
      },
    );
  }
}
