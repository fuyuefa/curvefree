import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory appearance. Defaults to the system setting and is not uploaded.
final themeModeProvider = StateProvider<ThemeMode>(
  (Ref ref) => ThemeMode.system,
);
