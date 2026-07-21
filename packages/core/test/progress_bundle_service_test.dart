import 'dart:io';

import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late SaveService saveService;
  late ProgressBundleService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('progress_bundle_service_test_');
    saveService = SaveService(() => tempDir);
    service = ProgressBundleService(saveService, const ['module_rebus', 'module_domino']);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('export includes every listed namespace and excludes settings', () async {
    await saveService.save('module_rebus', {
      'puzzles': {
        'p01': {'solved': true, 'elapsedMs': 500, 'updatedAt': 10},
      },
    });
    await saveService.save('settings', {'language': 'ru', 'soundOn': false});

    final bundle = ProgressBundle.decode(await service.exportJson());

    expect(bundle.bundleVersion, ProgressBundle.currentBundleVersion);
    expect(bundle.namespaces.keys.toSet(), {'module_rebus', 'module_domino'});
    expect(bundle.namespaces.containsKey('settings'), isFalse);
    expect((bundle.namespaces['module_rebus']!['puzzles'] as Map)['p01'], isNotNull);
    expect(bundle.namespaces['module_domino'], <String, dynamic>{});
  });

  test('export then import on the same install is a no-op', () async {
    await saveService.save('module_rebus', {
      'puzzles': {
        'p01': {'solved': true, 'elapsedMs': 500, 'updatedAt': 10},
      },
    });
    final json = await service.exportJson();
    final before = await saveService.load('module_rebus');

    final report = await service.importJson(json);

    expect(report.ok, isTrue);
    expect(report.counts.added, 0);
    expect(report.counts.updated, 0);
    expect(await saveService.load('module_rebus'), before);
  });

  test('import unions a foreign bundle into local progress', () async {
    await saveService.save('module_rebus', {
      'puzzles': {
        'p01': {'solved': true, 'elapsedMs': 500, 'firstSolveElapsedMs': 500, 'updatedAt': 10},
      },
    });

    const foreign = '''
{"bundleVersion":1,"exportedAt":"2026-07-21T00:00:00.000","namespaces":{
  "module_rebus":{"puzzles":{
    "p01":{"solved":true,"elapsedMs":900,"firstSolveElapsedMs":900,"updatedAt":99},
    "p02":{"solved":false,"elapsedMs":40,"updatedAt":99}}}}}
''';

    final report = await service.importJson(foreign);
    expect(report.ok, isTrue);
    expect(report.counts.added, 1);
    expect(report.counts.updated, 0);

    final data = await saveService.load('module_rebus');
    final puzzles = data['puzzles'] as Map;
    expect(puzzles.keys.toSet(), {'p01', 'p02'});
    // Local p01 had the better first-solve time and must survive.
    expect((puzzles['p01'] as Map)['firstSolveElapsedMs'], 500);
  });

  test('import writes namespaces this build does not know about', () async {
    const foreign = '''
{"bundleVersion":1,"exportedAt":"x","namespaces":{
  "module_99_future":{"puzzles":{"z1":{"solved":true,"updatedAt":5}}}}}
''';
    final report = await service.importJson(foreign);
    expect(report.ok, isTrue);

    final data = await saveService.load('module_99_future');
    expect((data['puzzles'] as Map).containsKey('z1'), isTrue);
  });

  test('a malformed bundle is rejected and leaves saves untouched', () async {
    await saveService.save('module_rebus', {
      'puzzles': {
        'p01': {'solved': true, 'updatedAt': 10},
      },
    });
    final before = await saveService.load('module_rebus');

    final report = await service.importJson('this is not a bundle');

    expect(report.ok, isFalse);
    expect(report.error, ImportError.badFormat);
    expect(await saveService.load('module_rebus'), before);
  });

  test('a bundle from a newer app reports versionTooNew and writes nothing', () async {
    final report = await service.importJson(
      '{"bundleVersion":99,"exportedAt":"x","namespaces":{"module_rebus":{"puzzles":{"p9":{}}}}}',
    );

    expect(report.ok, isFalse);
    expect(report.error, ImportError.versionTooNew);
    expect(await saveService.load('module_rebus'), <String, dynamic>{});
  });

  test('import surfaces the bundle exportedAt for the UI', () async {
    final report = await service.importJson(
      '{"bundleVersion":1,"exportedAt":"2026-07-21T14:03:11.482","namespaces":{}}',
    );
    expect(report.ok, isTrue);
    expect(report.exportedAt, '2026-07-21T14:03:11.482');
  });
}
