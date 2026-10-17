import 'package:curvefree/app/app.dart';
import 'package:curvefree/features/content/content_pack_session.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ContentPackSession.ensureLoaded();
  } on Object {
    ContentPackSession.invalidate();
  }
  runApp(const CurveFreeApp());
}
