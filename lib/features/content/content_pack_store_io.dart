import 'dart:convert';
import 'dart:io';

import 'package:curvefree/core/storage/atomic_file_write.dart';
import 'package:curvefree/features/content/content_constants.dart';
import 'package:curvefree/features/content/content_hash.dart';
import 'package:curvefree/features/content/content_manifest.dart';
import 'package:curvefree/features/content/content_pack_store.dart';
import 'package:curvefree/features/content/content_release.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

ContentPackStore createContentPackStore() => FileContentPackStore();

final class FileContentPackStore implements ContentPackStore {
  @override
  Future<String?> applicationRootPath() async {
    // Widget tests do not answer this channel, so the future never completes
    // and the nutrition page stays on its loading state. Tests have no
    // installed pack unless they pass a store rooted at a temp directory.
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return null;
    }
    try {
      final Directory base = await getApplicationSupportDirectory();
      return p.join(base.path, ContentPackPaths.folderName);
    } on Object {
      return null;
    }
  }

  @override
  Future<VerifiedPack?> readInstalled(String rootPath) async {
    final String? pointer = await _readPointer(rootPath);
    if (pointer == null) {
      return null;
    }
    final VerifiedPack? active = await _readSlot(rootPath, pointer);
    if (active != null) {
      return active;
    }
    final String other = pointer == ContentPackPaths.slotA
        ? ContentPackPaths.slotB
        : ContentPackPaths.slotA;
    return _readSlot(rootPath, other);
  }

  @override
  Future<void> publish({
    required String rootPath,
    required List<int> manifestBytes,
    required Map<String, List<int>> files,
  }) async {
    final String? pointer = await _readPointer(rootPath);
    final String next = pointer == ContentPackPaths.slotA
        ? ContentPackPaths.slotB
        : ContentPackPaths.slotA;
    final Directory slot = Directory(p.join(rootPath, next));
    if (await slot.exists()) {
      await slot.delete(recursive: true);
    }
    await slot.create(recursive: true);
    await writeBytesAtomically(
      File(p.join(slot.path, ContentFileNames.manifest)),
      manifestBytes,
    );
    for (final MapEntry<String, List<int>> entry in files.entries) {
      if (!isSafeContentFileName(entry.key)) {
        await slot.delete(recursive: true);
        throw const ContentPackFormatException(ContentJsonKeys.file);
      }
      await writeBytesAtomically(
        File(p.join(slot.path, entry.key)),
        entry.value,
      );
    }
    final VerifiedPack? verified = await _readSlot(rootPath, next);
    if (verified == null) {
      await slot.delete(recursive: true);
      throw const ContentPackFormatException(ContentJsonKeys.sha256);
    }
    await writeFileAtomically(
      File(p.join(rootPath, ContentPackPaths.pointerName)),
      next,
    );
  }

  Future<String?> _readPointer(String rootPath) async {
    final File pointer = File(p.join(rootPath, ContentPackPaths.pointerName));
    if (!await pointer.exists()) {
      return null;
    }
    final String name = (await pointer.readAsString()).trim();
    if (name == ContentPackPaths.slotA || name == ContentPackPaths.slotB) {
      return name;
    }
    return null;
  }

  Future<VerifiedPack?> _readSlot(String rootPath, String slot) async {
    final Directory dir = Directory(p.join(rootPath, slot));
    final File manifestFile = File(p.join(dir.path, ContentFileNames.manifest));
    if (!await manifestFile.exists()) {
      return null;
    }
    final ContentManifest manifest;
    try {
      manifest = ContentManifest.parse(
        utf8.decode(await manifestFile.readAsBytes()),
      );
    } on ContentPackFormatException {
      return null;
    } on FormatException {
      return null;
    }
    if (manifest.format != ContentFormat.version) {
      return null;
    }
    final Map<String, String> raw = <String, String>{};
    for (final ContentFileSpec spec in manifest.packs) {
      if (!isSafeContentFileName(spec.file)) {
        return null;
      }
      final File file = File(p.join(dir.path, spec.file));
      if (!await file.exists()) {
        return null;
      }
      final List<int> bytes = await file.readAsBytes();
      if (sha256Hex(bytes) != spec.sha256) {
        return null;
      }
      raw[spec.file] = utf8.decode(bytes);
    }
    final String? exercisesRaw = raw[manifest.exercises.file];
    final String? foodsRaw = raw[manifest.foods.file];
    if (exercisesRaw == null || foodsRaw == null) {
      return null;
    }
    return VerifiedPack(
      manifest: manifest,
      exercisesRaw: exercisesRaw,
      foodsRaw: foodsRaw,
    );
  }
}
