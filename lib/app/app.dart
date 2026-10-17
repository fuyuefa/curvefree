import 'package:curvefree/app/shell/shell_route_observer.dart';
import 'package:curvefree/app/theme/theme_mode.dart';
import 'package:curvefree/features/onboarding/onboarding_gate.dart';
import 'package:curvefree/features/training/widgets/workout_float_bubble.dart';
import 'package:curvefree/core/backup/backup_file_gateway.dart';
import 'package:curvefree/core/backup/backup_file_gateway_factory.dart';
import 'package:curvefree/core/constants/app_tokens.dart';
import 'package:curvefree/core/storage/local_store.dart';
import 'package:curvefree/core/storage/local_store_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';

class CurveFreeApp extends StatelessWidget {
  const CurveFreeApp({
    super.key,
    this.localStore,
    this.backupGateway,
    this.skipOnboarding = false,
  });

  /// When set, used instead of the platform default store (tests).
  final LocalStore? localStore;

  /// When set, used instead of the platform share/save sheet (tests).
  final BackupFileGateway? backupGateway;

  /// Shell tests pass true. A normal launch leaves this false.
  final bool skipOnboarding;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        if (localStore != null)
          localStoreProvider.overrideWithValue(localStore!),
        if (backupGateway != null)
          backupFileGatewayProvider.overrideWithValue(backupGateway!),
      ],
      child: _CurveFreeRoot(skipOnboarding: skipOnboarding),
    );
  }
}

class _CurveFreeRoot extends ConsumerStatefulWidget {
  const _CurveFreeRoot({required this.skipOnboarding});

  final bool skipOnboarding;

  @override
  ConsumerState<_CurveFreeRoot> createState() => _CurveFreeRootState();
}

class _CurveFreeRootState extends ConsumerState<_CurveFreeRoot> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    return MaterialApp(
      navigatorKey: _navigatorKey,
      navigatorObservers: <NavigatorObserver>[
        ref.watch(shellRouteObserverProvider),
      ],
      title: AppStrings.appNameZh,
      debugShowCheckedModeBanner: false,
      theme: buildCurveFreeTheme(Brightness.light),
      darkTheme: buildCurveFreeTheme(Brightness.dark),
      themeMode: mode,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (BuildContext context, Widget? child) {
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ?child,
            WorkoutFloatBubble(navigatorKey: _navigatorKey),
          ],
        );
      },
      home: OnboardingGate(skipOnboarding: widget.skipOnboarding),
    );
  }
}
