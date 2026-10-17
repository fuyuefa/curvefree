import 'package:curvefree/features/training/pages/session_page.dart';
import 'package:flutter/material.dart';

/// Route names so the shell can tell a session page from other pushes.
abstract final class SessionRoutes {
  static const String prefix = '/session/';

  static String nameFor(String sessionId) => '$prefix$sessionId';
}

MaterialPageRoute<void> sessionPageRoute(String sessionId) {
  return MaterialPageRoute<void>(
    settings: RouteSettings(name: SessionRoutes.nameFor(sessionId)),
    builder: (BuildContext context) => SessionPage(sessionId: sessionId),
  );
}
