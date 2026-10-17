import 'dart:convert';
import 'dart:io';

import 'package:curvefree/core/storage/storage_keys.dart';

/// Replaces [target] by flushing [contents] to a temp file in the same
/// directory, then renaming it over [target].
///
/// A crash while the temp file is still open leaves the previous document
/// in place. On Android/Linux the rename replaces [target] atomically.
Future<void> writeFileAtomically(File target, String contents) {
  return writeBytesAtomically(target, utf8.encode(contents));
}

/// Same replacement as [writeFileAtomically], for bytes that must stay intact.
Future<void> writeBytesAtomically(File target, List<int> bytes) async {
  await target.parent.create(recursive: true);
  final File temp = File('${target.path}${StorageKeys.tempFileSuffix}');
  try {
    await temp.writeAsBytes(bytes, flush: true);
    try {
      await temp.rename(target.path);
    } on FileSystemException {
      await _replaceWithoutAtomicRename(temp, target);
    }
  } on Object {
    if (await temp.exists()) {
      await temp.delete();
    }
    rethrow;
  }
}

Future<void> _replaceWithoutAtomicRename(File temp, File target) async {
  final displaced = File('${target.path}${StorageKeys.replacingFileSuffix}');
  if (await displaced.exists()) {
    await displaced.delete();
  }
  if (await target.exists()) {
    await target.rename(displaced.path);
  }
  try {
    await temp.rename(target.path);
  } on Object {
    if (!await target.exists() && await displaced.exists()) {
      await displaced.rename(target.path);
    }
    rethrow;
  }
  if (await displaced.exists()) {
    await displaced.delete();
  }
}
