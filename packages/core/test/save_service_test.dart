import 'dart:convert';
import 'dart:io';

import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late SaveService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('save_service_test_');
    service = SaveService(() => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('round-trips save and load', () async {
    await service.save('ns', {'a': 1, 'b': 'two'});
    final loaded = await service.load('ns');
    expect(loaded, {'a': 1, 'b': 'two'});
  });

  test('load on a namespace with no save file returns an empty map', () async {
    final loaded = await service.load('missing');
    expect(loaded, <String, dynamic>{});
  });

  test('50 concurrent saves serialize, land on the last payload, and leave no temp files', () async {
    const namespace = 'concurrent';
    final futures = <Future<void>>[];
    for (var i = 0; i < 50; i++) {
      futures.add(service.save(namespace, {'i': i}));
    }
    await Future.wait(futures);

    final loaded = await service.load(namespace);
    expect(loaded, {'i': 49});

    final leftoverTemp = tempDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.tmp'))
        .toList();
    expect(leftoverTemp, isEmpty);
  });

  test('a corrupt (unparseable) file is quarantined and load returns empty', () async {
    final file = File('${tempDir.path}/corrupt.json');
    await file.writeAsString('not valid json {{{');

    final loaded = await service.load('corrupt');
    expect(loaded, <String, dynamic>{});

    final bakFiles = tempDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('corrupt.json.') && f.path.endsWith('.bak'))
        .toList();
    expect(bakFiles, hasLength(1));
  });

  test('a file with a schemaVersion newer than supported is quarantined', () async {
    final file = File('${tempDir.path}/future.json');
    await file.writeAsString(jsonEncode({
      'schemaVersion': 99,
      'data': {'x': 1},
    }));

    final loaded = await service.load('future');
    expect(loaded, <String, dynamic>{});

    final bakFiles = tempDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('future.json.') && f.path.endsWith('.bak'))
        .toList();
    expect(bakFiles, hasLength(1));
  });
}
