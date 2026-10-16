import 'package:curvefree/app/shell/app_shell.dart';
import 'package:curvefree/app/theme/theme_mode.dart';
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
  const CurveFreeApp({super.key, this.localStore, this.backupGateway});

  /// When set, used instead of the platform default store (tests).
  final LocalStore? localStore;

  /// When set, used instead of the platform share/save sheet (tests).
  final BackupFileGateway? backupGateway;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        if (localStore != null)
          localStoreProvider.overrideWithValue(localStore!),
        if (backupGateway != null)
          backupFileGatewayProvider.overrideWithValue(backupGateway!),
      ],
      child: const _CurveFreeRoot(),
    );
  }
}

class _CurveFreeRoot extends ConsumerWidget {
  const _CurveFreeRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    return MaterialApp(
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
      home: const AppShell(),
    );
  }
}
