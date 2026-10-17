import 'package:curvefree/core/storage/local_store_snapshot.dart';
import 'package:curvefree/features/onboarding/models/user_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `--dart-define=FORCE_ONBOARDING=true` opens the flow even in release.
const bool forceOnboardingFromEnvironment = bool.fromEnvironment(
  'FORCE_ONBOARDING',
);

/// Set when this process finishes or skips the questionnaire.
///
/// Debug and profile builds reopen the flow on the next process start.
/// The flag only lasts for the current run so completing it still reaches 今日.
final onboardingDismissedProvider = StateProvider<bool>((Ref ref) => false);

/// Whether a cold start should open the questionnaire.
///
/// Release skips when onboarding is already done or the device already has
/// workouts, food logs, or a saved plan ([UserProfile.shouldEnterShell]).
/// Debug, profile, and [forceOnboarding] still open the flow so it can be
/// retested. Widget tests pass `skipOnboarding: true` to enter the shell.
bool shouldPresentOnboarding(
  LocalStoreSnapshot snapshot, {
  bool debugMode = kDebugMode,
  bool profileMode = kProfileMode,
  bool forceOnboarding = forceOnboardingFromEnvironment,
}) {
  if (forceOnboarding || debugMode || profileMode) {
    return true;
  }
  return !UserProfile.shouldEnterShell(snapshot);
}
