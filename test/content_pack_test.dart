import 'dart:convert';
import 'dart:io';

import 'package:curvefree/features/content/content_constants.dart';
import 'package:curvefree/features/content/content_hash.dart';
import 'package:curvefree/features/content/content_manifest.dart';
import 'package:curvefree/features/content/content_pack_session.dart';
import 'package:curvefree/features/content/content_pack_store.dart';
import 'package:curvefree/features/content/content_pack_store_io.dart';
import 'package:curvefree/features/content/content_pack_updater.dart';
import 'package:curvefree/features/content/content_providers.dart';
import 'package:curvefree/features/content/content_release.dart';
import 'package:curvefree/features/exercises/exercise_catalog.dart';
import 'package:curvefree/features/exercises/models/catalog_exercise.dart';
import 'package:curvefree/features/home/muscle_groups.dart';
import 'package:curvefree/features/nutrition/data/food_catalog.dart';
import 'package:curvefree/features/nutrition/models/food_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    root = Directory.systemTemp.createTempSync('curvefree-content-');
  });

  tearDown(() {
    ExerciseCatalog.clearOverlay();
    ContentPackSession.invalidate();
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('manifest records pack id, version, license, and source', () {
    final ContentManifest manifest = ContentManifest.parse(
      File(ContentAssets.manifest).readAsStringSync(),
    );
    expect(manifest.format, ContentFormat.version);
    expect(manifest.id, 'curvefree-content');
    expect(manifest.version, '0.1.0');
    expect(manifest.exercises.license, 'Unlicense');
    expect(
      manifest.exercises.sourceUrl,
      'https://github.com/yuhonas/free-exercise-db',
    );
    expect(manifest.foods.license, contains('GPL-3.0-only'));
    expect(manifest.foods.sourceUrl, 'https://fdc.nal.usda.gov/');
    expect(manifest.update.service, ContentUpdateService.githubReleases);
    expect(manifest.update.owner, 'fuyuefa');
    expect(manifest.update.repo, 'curvefree');
    expect(manifest.update.manifestAsset, 'content-manifest.json');
    expect(
      sha256Hex(File(ContentAssets.exercises).readAsBytesSync()),
      manifest.exercises.sha256,
    );
    expect(
      sha256Hex(File(ContentAssets.foods).readAsBytesSync()),
      manifest.foods.sha256,
    );
  });

  test('attribution notice is present for users and GPLv3', () {
    final String notice = File(ContentAssets.attribution).readAsStringSync();
    expect(notice, contains('GPL-3.0'));
    expect(notice, contains('Unlicense'));
    expect(notice, contains('USDA'));
    expect(notice, contains('Open Food Facts'));
    expect(notice, contains('ODbL'));
    expect(notice.contains('。'), isFalse);
  });

  test(
    'active pack resolves baseline and bundled exercise and food ids',
    () async {
      expect(ExerciseCatalog.byId('ex_deadlift')?.nameZh, '硬拉');
      final ContentSnapshot snapshot = await ContentPackLoader().load();
      ExerciseCatalog.applyOverlay(
        exercises: snapshot.exerciseOverlay.exercises,
        bodyParts: snapshot.exerciseOverlay.bodyParts,
      );

      final CatalogExercise? curl = ExerciseCatalog.byId('fedb_barbell_curl');
      expect(curl?.nameZh, '杠铃弯举');
      expect(curl?.nameEn, 'Barbell Curl');
      expect(curl?.sourceId, 'Barbell_Curl');
      expect(ExerciseCatalog.byId('ex_deadlift')?.nameZh, '硬拉');
      expect(
        ExerciseCatalog.search('Barbell Curl')
            .map((CatalogExercise item) => item.id),
        contains('fedb_barbell_curl'),
      );
      expect(
        muscleGroupsFor(catalogId: 'fedb_side_lateral_raise', name: '侧平举'),
        contains(MuscleGroup.shoulders),
      );
      expect(
        muscleGroupsFor(
          catalogId: 'fedb_split_squat_with_dumbbells',
          name: '哑铃分腿蹲',
        ),
        containsAll(<MuscleGroup>[MuscleGroup.legs, MuscleGroup.glutes]),
      );

      final FoodItem? chicken = snapshot.foods.byId('chicken_breast');
      final FoodItem? eggWhite = snapshot.foods.byId('egg_white');
      expect(chicken?.nameZh, '鸡胸肉（熟）');
      expect(eggWhite?.nameZh, '鸡蛋白');
      expect(eggWhite?.nameEn, 'Egg white');
      expect(eggWhite?.fdcId, '172183');
      expect(snapshot.foods.search('Egg white').single.id, 'egg_white');
      expect(snapshot.installed, isFalse);
      expect(snapshot.attribution, contains('Unlicense'));
    },
  );

  test('food overlay replaces the same id and keeps the rest', () {
    final FoodCatalog base = FoodCatalog.parse(
      File(ContentAssets.foods).readAsStringSync(),
    );
    final FoodCatalog extra = FoodCatalog.parse(
      jsonEncode(<String, Object?>{
        'foods': <Map<String, Object?>>[
          <String, Object?>{
            'id': 'chicken_breast',
            'nameZh': '鸡胸肉（覆盖）',
            'source': 'usda',
            'kcal': 165,
            'proteinG': 31,
            'carbG': 0,
            'fatG': 3.6,
          },
          <String, Object?>{
            'id': 'new_food',
            'nameZh': '新食物',
            'nameEn': 'New food',
            'source': 'estimate',
            'kcal': 10,
            'proteinG': 1,
            'carbG': 1,
            'fatG': 1,
          },
        ],
      }),
    );
    final FoodCatalog merged = base.overlay(extra);
    expect(merged.byId('chicken_breast')?.nameZh, '鸡胸肉（覆盖）');
    expect(merged.byId('egg_white')?.nameZh, '鸡蛋白');
    expect(merged.byId('new_food')?.nameEn, 'New food');
  });

  test('network failure keeps the last good pack', () async {
    final _PackFixture first = _pack(version: '0.1.1', exerciseName: '第一份');
    await _install(root, first);
    final VerifiedPack? before = await FileContentPackStore().readInstalled(
      root.path,
    );
    expect(before?.manifest.version, '0.1.1');

    final ContentPackUpdater updater = ContentPackUpdater(
      client: _FakeReleaseClient(_bodies(first.bundled, first), offline: true),
      store: FileContentPackStore(),
    );
    expect(
      () => updater.update(bundled: first.bundled, rootPath: root.path),
      throwsA(isA<ContentNetworkException>()),
    );
    final VerifiedPack? after = await FileContentPackStore().readInstalled(
      root.path,
    );
    expect(after?.manifest.version, '0.1.1');
    expect(after?.exercisesRaw, contains('第一份'));
  });

  test('hash mismatch does not swap the installed pack', () async {
    final _PackFixture first = _pack(version: '0.1.1', exerciseName: '第一份');
    await _install(root, first);
    final _PackFixture broken = _pack(
      version: '0.1.2',
      exerciseName: '坏包',
      lieAboutExerciseHash: true,
    );
    final ContentUpdateOutcome outcome = await ContentPackUpdater(
      client: _FakeReleaseClient(_bodies(first.bundled, broken)),
      store: FileContentPackStore(),
    ).update(bundled: first.bundled, rootPath: root.path);
    expect(outcome, ContentUpdateOutcome.rejected);
    final VerifiedPack? still = await FileContentPackStore().readInstalled(
      root.path,
    );
    expect(still?.manifest.version, '0.1.1');
    expect(still?.exercisesRaw, contains('第一份'));
  });

  test(
    'verified release swaps in and a later corrupt slot falls back',
    () async {
      final _PackFixture first = _pack(version: '0.1.1', exerciseName: '第一份');
      final _PackFixture second = _pack(version: '0.1.2', exerciseName: '第二份');
      final FileContentPackStore store = FileContentPackStore();
      expect(
        await ContentPackUpdater(
          client: _FakeReleaseClient(_bodies(first.bundled, first)),
          store: store,
        ).update(bundled: first.bundled, rootPath: root.path),
        ContentUpdateOutcome.updated,
      );
      expect(
        await ContentPackUpdater(
          client: _FakeReleaseClient(_bodies(first.bundled, second)),
          store: store,
        ).update(bundled: first.bundled, rootPath: root.path),
        ContentUpdateOutcome.updated,
      );
      expect((await store.readInstalled(root.path))?.manifest.version, '0.1.2');

      final String pointer = File(
        '${root.path}/${ContentPackPaths.pointerName}',
      ).readAsStringSync().trim();
      final File activeExercises = File('${root.path}/$pointer/exercises.json');
      expect(activeExercises.existsSync(), isTrue);
      activeExercises.writeAsStringSync('not-the-verified-bytes');
      final VerifiedPack? fallback = await store.readInstalled(root.path);
      expect(fallback?.manifest.version, '0.1.1');
      expect(fallback?.exercisesRaw, contains('第一份'));
    },
  );

  test('disallowed download url is rejected before fetch', () async {
    final _PackFixture pack = _pack(version: '0.1.1', exerciseName: '不会装');
    final _FakeReleaseClient client = _FakeReleaseClient(
      _bodies(pack.bundled, pack, manifestUrl: 'http://evil.example/manifest'),
    );
    final ContentUpdateOutcome outcome = await ContentPackUpdater(
      client: client,
      store: FileContentPackStore(),
    ).update(bundled: pack.bundled, rootPath: root.path);
    expect(outcome, ContentUpdateOutcome.rejected);
    expect(client.calls, hasLength(1));
    expect(await FileContentPackStore().readInstalled(root.path), isNull);
  });

  test('check update reports offline without touching the pack', () async {
    final _PackFixture pack = _pack(version: '0.1.1', exerciseName: '不会装');
    final ContentUpdateOutcome outcome = await checkContentPackUpdate(
      ContentPackUpdater(
        client: _FakeReleaseClient(_bodies(pack.bundled, pack), offline: true),
        store: _RootedStore(root.path),
      ),
    );
    expect(outcome, ContentUpdateOutcome.offline);
    expect(
      File('${root.path}/${ContentPackPaths.pointerName}').existsSync(),
      isFalse,
    );
  });
}

final class _RootedStore implements ContentPackStore {
  _RootedStore(this.root) : _inner = FileContentPackStore();

  final String root;
  final FileContentPackStore _inner;

  @override
  Future<String?> applicationRootPath() async => root;

  @override
  Future<void> publish({
    required String rootPath,
    required List<int> manifestBytes,
    required Map<String, List<int>> files,
  }) {
    return _inner.publish(
      rootPath: rootPath,
      manifestBytes: manifestBytes,
      files: files,
    );
  }

  @override
  Future<VerifiedPack?> readInstalled(String rootPath) {
    return _inner.readInstalled(rootPath);
  }
}

final class _FakeReleaseClient implements ContentReleaseClient {
  _FakeReleaseClient(this.bodies, {this.offline = false});

  final Map<String, List<int>> bodies;
  final bool offline;
  final List<Uri> calls = <Uri>[];

  @override
  Future<List<int>> get(Uri uri) async {
    calls.add(uri);
    if (offline) {
      throw const ContentNetworkException('offline');
    }
    final List<int>? body = bodies[uri.toString()];
    if (body == null) {
      throw ContentNetworkException('missing $uri');
    }
    return body;
  }
}

final class _PackFixture {
  const _PackFixture({
    required this.bundled,
    required this.remote,
    required this.manifestBytes,
    required this.exercises,
    required this.foods,
    required this.manifestUrl,
    required this.exerciseUrl,
    required this.foodUrl,
  });

  final ContentManifest bundled;
  final ContentManifest remote;
  final List<int> manifestBytes;
  final List<int> exercises;
  final List<int> foods;
  final String manifestUrl;
  final String exerciseUrl;
  final String foodUrl;
}

_PackFixture _pack({
  required String version,
  required String exerciseName,
  bool lieAboutExerciseHash = false,
}) {
  final List<int> exercises = utf8.encode(
    jsonEncode(<String, Object?>{
      'exercises': <Map<String, Object?>>[
        <String, Object?>{
          'id': 'fedb_barbell_curl',
          'sourceId': 'Barbell_Curl',
          'nameZh': exerciseName,
          'nameEn': 'Barbell Curl',
          'pattern': 'pull',
          'equipment': 'barbell',
          'bodyParts': <String>['arms'],
        },
      ],
    }),
  );
  final List<int> foods = utf8.encode(
    jsonEncode(<String, Object?>{
      'foods': <Map<String, Object?>>[
        <String, Object?>{
          'id': 'egg_white',
          'nameZh': '鸡蛋白',
          'source': 'usda',
          'kcal': 52,
          'proteinG': 10.9,
          'carbG': 0.7,
          'fatG': 0.2,
        },
      ],
    }),
  );
  final String exerciseSha = lieAboutExerciseHash
      ? 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
      : sha256Hex(exercises);
  final String raw = jsonEncode(<String, Object?>{
    'format': ContentFormat.version,
    'id': 'curvefree-content',
    'version': version,
    'exercises': <String, Object?>{
      'id': 'exercises',
      'version': version,
      'file': 'exercises.json',
      'license': 'Unlicense',
      'sourceUrl': 'https://github.com/yuhonas/free-exercise-db',
      'sha256': exerciseSha,
    },
    'foods': <String, Object?>{
      'id': 'foods',
      'version': version,
      'file': 'foods.json',
      'license': 'public-domain AND GPL-3.0-only',
      'sourceUrl': 'https://fdc.nal.usda.gov/',
      'sha256': sha256Hex(foods),
    },
    'update': <String, Object?>{
      'service': ContentUpdateService.githubReleases,
      'owner': 'fuyuefa',
      'repo': 'curvefree',
      'manifestAsset': 'content-manifest.json',
    },
  });
  final ContentManifest remote = ContentManifest.parse(raw);
  final ContentManifest bundled = ContentManifest.parse(
    raw.replaceFirst(version, '0.0.0'),
  );
  return _PackFixture(
    bundled: bundled,
    remote: remote,
    manifestBytes: utf8.encode(raw),
    exercises: exercises,
    foods: foods,
    manifestUrl:
        'https://github.com/fuyuefa/curvefree/releases/download/content-v$version/content-manifest.json',
    exerciseUrl:
        'https://github.com/fuyuefa/curvefree/releases/download/content-v$version/exercises.json',
    foodUrl:
        'https://github.com/fuyuefa/curvefree/releases/download/content-v$version/foods.json',
  );
}

Map<String, List<int>> _bodies(
  ContentManifest bundled,
  _PackFixture pack, {
  String? manifestUrl,
}) {
  final String releaseBody = jsonEncode(<Object?>[
    <String, Object?>{
      'tag_name': 'content-v${pack.remote.version}',
      'assets': <Map<String, String>>[
        <String, String>{
          'name': 'content-manifest.json',
          'browser_download_url': manifestUrl ?? pack.manifestUrl,
        },
        <String, String>{
          'name': 'exercises.json',
          'browser_download_url': pack.exerciseUrl,
        },
        <String, String>{
          'name': 'foods.json',
          'browser_download_url': pack.foodUrl,
        },
      ],
    },
  ]);
  return <String, List<int>>{
    githubReleasesUri(bundled.update).toString(): utf8.encode(releaseBody),
    manifestUrl ?? pack.manifestUrl: pack.manifestBytes,
    pack.exerciseUrl: pack.exercises,
    pack.foodUrl: pack.foods,
  };
}

Future<void> _install(Directory root, _PackFixture pack) {
  return FileContentPackStore().publish(
    rootPath: root.path,
    manifestBytes: pack.manifestBytes,
    files: <String, List<int>>{
      'exercises.json': pack.exercises,
      'foods.json': pack.foods,
    },
  );
}
