import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_domino/module_domino.dart';
import 'package:module_domino_ui/module_domino_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

List<DominoPuzzle> _loadPuzzles() {
  final file = File('../module_domino/assets/puzzles/module03.json');
  return DominoPuzzle.listFromJsonString(file.readAsStringSync());
}

void main() {
  late List<DominoPuzzle> puzzles;
  late Directory tempDir;
  late SaveService saveService;

  setUpAll(() {
    puzzles = _loadPuzzles();
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('module_domino_ui_session_test_');
    saveService = SaveService(() => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(overrides: [
      dominoPuzzlesProvider.overrideWith((ref) async => puzzles),
      dominoSaveServiceProvider.overrideWithValue(saveService),
    ]);
  }

  test('binding all example-solution dominoes wins and persists solved', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(dominoPuzzlesProvider.future);

    final example = puzzles.firstWhere((p) => p.id == 'example');
    final notifier = container.read(dominoSessionProvider('example').notifier);
    container.read(dominoSessionProvider('example'));

    for (final d in example.solution!) {
      notifier.tapCell(d.a);
      notifier.tapCell(d.b);
    }

    final state = container.read(dominoSessionProvider('example'));
    expect(state.solved, isTrue);
    expect(state.winSeq, 1);
    expect(state.board.wins, isTrue);

    Map? entry;
    for (var i = 0; i < 50 && entry == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final saved = await saveService.load('module_domino');
      final pz = saved['puzzles'];
      if (pz is Map && pz['example'] is Map && (pz['example'] as Map)['solved'] == true) {
        entry = pz['example'] as Map;
      }
    }
    expect(entry, isNotNull, reason: 'solved state never landed on disk');
  });

  test('tap two adjacent cells binds a domino; tapping it again splits', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(dominoPuzzlesProvider.future);

    final notifier = container.read(dominoSessionProvider('example').notifier);
    container.read(dominoSessionProvider('example'));

    notifier.tapCell(const Cell(0, 0));
    notifier.tapCell(const Cell(0, 1));
    var state = container.read(dominoSessionProvider('example'));
    expect(state.board.isCovered(const Cell(0, 0)), isTrue);
    expect(state.status.placedCount, 1);

    notifier.tapCell(const Cell(0, 0));
    state = container.read(dominoSessionProvider('example'));
    expect(state.board.isCovered(const Cell(0, 0)), isFalse);
    expect(state.status.placedCount, 0);
  });
}
