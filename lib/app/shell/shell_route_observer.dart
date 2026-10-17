import 'package:curvefree/app/shell/shell_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final shellRouteObserverProvider = Provider<ShellRouteObserver>((Ref ref) {
  final ShellRouteObserver observer = ShellRouteObserver(
    onNavigation: ref.read(shellNavigationProvider.notifier).publish,
  );
  ref.onDispose(observer.dispose);
  return observer;
});

/// Records page route names, ignoring dialogs and bottom sheets.
final class ShellRouteObserver extends NavigatorObserver {
  ShellRouteObserver({required this.onNavigation});

  final void Function(ShellNavigation navigation) onNavigation;
  final List<Route<dynamic>> _stack = <Route<dynamic>>[];
  NavigatorState? _boundNavigator;

  void dispose() {
    _stack.clear();
    _boundNavigator = null;
  }

  void _bindNavigator() {
    final NavigatorState? current = navigator;
    if (current == null || identical(_boundNavigator, current)) {
      return;
    }
    _boundNavigator = current;
    _stack.clear();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _bindNavigator();
    _stack.add(route);
    _schedulePublish();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _bindNavigator();
    _stack.remove(route);
    _schedulePublish();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _bindNavigator();
    _stack.remove(route);
    _schedulePublish();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _bindNavigator();
    if (oldRoute != null) {
      final int index = _stack.indexOf(oldRoute);
      if (index >= 0 && newRoute != null) {
        _stack[index] = newRoute;
      } else {
        _stack.remove(oldRoute);
        if (newRoute != null) {
          _stack.add(newRoute);
        }
      }
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
    _schedulePublish();
  }

  void _schedulePublish() {
    final NavigatorState? current = navigator;
    if (current == null || _stack.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!current.mounted || !identical(navigator, current)) {
        return;
      }
      if (_stack.isEmpty) {
        return;
      }
      onNavigation(_snapshot());
    });
  }

  ShellNavigation _snapshot() {
    final bool coveredByPopup =
        _stack.isNotEmpty && _stack.last is PopupRoute<dynamic>;
    final List<String?> pageRouteNames = <String?>[];
    String? topPageRouteName;
    for (final Route<dynamic> route in _stack) {
      if (route is PopupRoute<dynamic>) {
        continue;
      }
      pageRouteNames.add(route.settings.name);
      topPageRouteName = route.settings.name;
    }
    return ShellNavigation(
      topPageRouteName: topPageRouteName,
      pageRouteNames: pageRouteNames,
      coveredByPopup: coveredByPopup,
    );
  }
}
