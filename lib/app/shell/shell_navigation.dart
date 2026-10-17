import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page stack the shell uses to show or hide the in-progress bubble.
final class ShellNavigation {
  const ShellNavigation({
    required this.topPageRouteName,
    required this.pageRouteNames,
    required this.coveredByPopup,
  });

  static const ShellNavigation initial = ShellNavigation(
    topPageRouteName: Navigator.defaultRouteName,
    pageRouteNames: <String?>[Navigator.defaultRouteName],
    coveredByPopup: false,
  );

  final String? topPageRouteName;
  final List<String?> pageRouteNames;
  final bool coveredByPopup;

  bool containsPage(String routeName) {
    return pageRouteNames.contains(routeName);
  }

  @override
  bool operator ==(Object other) {
    if (other is! ShellNavigation) {
      return false;
    }
    if (other.topPageRouteName != topPageRouteName ||
        other.coveredByPopup != coveredByPopup ||
        other.pageRouteNames.length != pageRouteNames.length) {
      return false;
    }
    for (int i = 0; i < pageRouteNames.length; i++) {
      if (other.pageRouteNames[i] != pageRouteNames[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    topPageRouteName,
    coveredByPopup,
    Object.hashAll(pageRouteNames),
  );
}

final shellNavigationProvider =
    NotifierProvider<ShellNavigationController, ShellNavigation>(
      ShellNavigationController.new,
    );

final class ShellNavigationController extends Notifier<ShellNavigation> {
  @override
  ShellNavigation build() => ShellNavigation.initial;

  void publish(ShellNavigation navigation) {
    if (state == navigation) {
      return;
    }
    state = navigation;
  }
}
