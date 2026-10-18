import 'package:curvefree/app/shell/app_tab.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected shell tab.
///
/// Pushed routes sit above the shell, so they cannot reach its state through
/// the widget tree. Finish summary uses this notifier to land on today.
final shellTabProvider = NotifierProvider<ShellTabController, AppTab>(
  ShellTabController.new,
);

final class ShellTabController extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.today;

  void select(AppTab tab) {
    if (state == tab) {
      return;
    }
    state = tab;
  }
}

/// Pops every page above the shell and shows [AppTab.today].
void popToTodayTab(WidgetRef ref, NavigatorState navigator) {
  ref.read(shellTabProvider.notifier).select(AppTab.today);
  navigator.popUntil((Route<dynamic> route) => route.isFirst);
}
