import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_squareword/module_squareword.dart';
import 'package:module_squareword_ui/module_squareword_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

List<SquarewordPuzzle> _loadPuzzles() {
  final file = File('../module_squareword/assets/puzzles/module05.json');
  return SquarewordPuzzle.listFromJsonString(file.readAsStringSync());
}

void main() {
  late List<SquarewordPuzzle> puzzles;
  late Directory tempDir;
  late SaveService saveService;

  setUpAll(() {
    puzzles = _loadPuzzles();
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('module_squareword_ui_session_test_');
    saveService = SaveService(() => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(overrides: [
      squarewordPuzzlesProvider.overrideWith((ref) async => puzzles),
      squarewordSaveServiceProvider.overrideWithValue(saveService),
    ]);
  }

  test('placing then clearing a cell round-trips through toJson/fromJson via persistence', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(squarewordPuzzlesProvider.future);

    final sub = container.listen(squarewordSessionProvider('p01'), (prev, next) {});
    addTearDown(sub.close);

    final puzzle = puzzles.firstWhere((p) => p.id == 'p01');
    final notifier = container.read(squarewordSessionProvider('p01').notifier);
    container.read(squarewordSessionProvider('p01'));

    // Row 0 is always given; row 1 col 0 is editable in every puzzle shape
    // (only row 0 is guaranteed fully given).
    final target = Cell(1, 0);
    expect(container.read(squarewordSessionProvider('p01')).board.isGiven(target), isFalse);

    notifier.place(target, puzzle.keyword[1]);

    Map? entry;
    for (var i = 0; i < 50 && entry == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final saved = await saveService.load('module_squareword');
      final pz = saved['puzzles'];
      if (pz is Map && pz['p01'] is Map) entry = pz['p01'] as Map;
    }
    expect(entry, isNotNull, reason: 'placement never landed on disk');
    final filled = entry!['filled'] as Map;
    expect(filled['1,0'], puzzle.keyword[1]);

    notifier.clear(target);

    Map? clearedEntry;
    for (var i = 0; i < 50; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final saved = await saveService.load('module_squareword');
      final pz = saved['puzzles'];
      if (pz is Map && pz['p01'] is Map) {
        final f = (pz['p01'] as Map)['filled'] as Map;
        if (!f.containsKey('1,0')) {
          clearedEntry = pz['p01'] as Map;
          break;
        }
      }
    }
    expect(clearedEntry, isNotNull, reason: 'clear never landed on disk');
  });

  test('a save merges into the namespace instead of clobbering a sibling puzzle entry', () async {
    // Pre-populate the namespace with an unrelated puzzle's entry, as if
    // "p02" was solved in a previous session.
    await saveService.save('module_squareword', <String, dynamic>{
      'puzzles': <String, dynamic>{
        'p02': <String, dynamic>{'filled': <String, dynamic>{}, 'solved': true},
      },
    });

    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(squarewordPuzzlesProvider.future);

    final sub = container.listen(squarewordSessionProvider('p01'), (prev, next) {});
    addTearDown(sub.close);

    final puzzle = puzzles.firstWhere((p) => p.id == 'p01');
    final notifier = container.read(squarewordSessionProvider('p01').notifier);
    container.read(squarewordSessionProvider('p01'));

    notifier.place(const Cell(1, 0), puzzle.keyword[1]);

    Map? p01Entry;
    for (var i = 0; i < 50 && p01Entry == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final saved = await saveService.load('module_squareword');
      final pz = saved['puzzles'];
      if (pz is Map && pz['p01'] is Map) p01Entry = pz['p01'] as Map;
    }
    expect(p01Entry, isNotNull, reason: 'p01 entry never landed on disk');

    final saved = await saveService.load('module_squareword');
    final puzzlesMap = saved['puzzles'] as Map;
    expect(puzzlesMap['p02'], isNotNull, reason: 'sibling puzzle entry was clobbered');
    expect((puzzlesMap['p02'] as Map)['solved'], isTrue);
  });

  test('onDispose flushes the last captured payload without reading state/ref', () async {
    final container = ProviderContainer(overrides: [
      squarewordPuzzlesProvider.overrideWith((ref) async => puzzles),
      squarewordSaveServiceProvider.overrideWithValue(saveService),
    ]);
    await container.read(squarewordPuzzlesProvider.future);

    final sub = container.listen(squarewordSessionProvider('p01'), (prev, next) {});
    final puzzle = puzzles.firstWhere((p) => p.id == 'p01');
    final notifier = container.read(squarewordSessionProvider('p01').notifier);
    container.read(squarewordSessionProvider('p01'));

    notifier.place(const Cell(1, 0), puzzle.keyword[1]);

    // Dispose immediately — before the debounce timer would have fired —
    // to prove the onDispose flush (not the debounce timer) is what
    // persists the placement.
    sub.close();
    container.dispose();

    Map? entry;
    for (var i = 0; i < 50 && entry == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final saved = await saveService.load('module_squareword');
      final pz = saved['puzzles'];
      if (pz is Map && pz['p01'] is Map) entry = pz['p01'] as Map;
    }
    expect(entry, isNotNull, reason: 'onDispose flush never landed on disk');
    expect((entry!['filled'] as Map)['1,0'], puzzle.keyword[1]);
  });

  test('filling the board via solver-verified letters wins and persists updatedAt/solvedAt/firstSolveElapsedMs',
      () async {
    final before = DateTime.now().millisecondsSinceEpoch;
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(squarewordPuzzlesProvider.future);

    final sub = container.listen(squarewordSessionProvider('p01'), (prev, next) {});
    addTearDown(sub.close);

    final puzzle = puzzles.firstWhere((p) => p.id == 'p01');
    final solveResult = solveSquareword(puzzle);
    expect(solveResult.solution, isNotNull, reason: 'p01 must have a solver-verified solution');
    final solution = solveResult.solution!;

    final notifier = container.read(squarewordSessionProvider('p01').notifier);
    container.read(squarewordSessionProvider('p01'));

    for (var r = 0; r < puzzle.n; r++) {
      for (var c = 0; c < puzzle.n; c++) {
        final cell = Cell(r, c);
        if (container.read(squarewordSessionProvider('p01')).board.isGiven(cell)) continue;
        notifier.place(cell, solution[r][c]);
      }
    }

    final state = container.read(squarewordSessionProvider('p01'));
    expect(state.solved, isTrue);
    expect(state.winSeq, 1);
    expect(state.board.status().isSolved, isTrue);

    Map? entry;
    for (var i = 0; i < 50 && entry == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final saved = await saveService.load('module_squareword');
      final pz = saved['puzzles'];
      if (pz is Map && pz['p01'] is Map && (pz['p01'] as Map)['solved'] == true) {
        entry = pz['p01'] as Map;
      }
    }
    expect(entry, isNotNull, reason: 'solved entry never landed on disk');
    // These three fields are what progress_merge.dart's tie-break ladder
    // climbs (firstSolveElapsedMs -> solvedAt -> updatedAt) to decide which
    // of two devices' copies of a solved puzzle to keep; dropping any of
    // them would silently make a sync keep the SLOWER of two solves.
    expect(entry!['updatedAt'], isA<int>());
    expect(entry['updatedAt'] as int, greaterThanOrEqualTo(before));
    expect(entry['solvedAt'], isA<String>());
    expect(entry['firstSolveElapsedMs'], isA<int>());
  });

  test('reviewMode blocks place and clear once solved', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(squarewordPuzzlesProvider.future);

    final sub = container.listen(squarewordSessionProvider('p01'), (prev, next) {});
    addTearDown(sub.close);

    final puzzle = puzzles.firstWhere((p) => p.id == 'p01');
    final solution = solveSquareword(puzzle).solution!;
    final notifier = container.read(squarewordSessionProvider('p01').notifier);
    container.read(squarewordSessionProvider('p01'));

    for (var r = 0; r < puzzle.n; r++) {
      for (var c = 0; c < puzzle.n; c++) {
        final cell = Cell(r, c);
        if (container.read(squarewordSessionProvider('p01')).board.isGiven(cell)) continue;
        notifier.place(cell, solution[r][c]);
      }
    }

    final solvedState = container.read(squarewordSessionProvider('p01'));
    expect(solvedState.reviewMode, isTrue);
    final revBefore = solvedState.rev;

    // Find an editable cell and try to mutate it post-solve; must be a
    // no-op while reviewMode holds.
    final editable = Cell(1, 0);
    notifier.place(editable, puzzle.keyword[0]);
    notifier.clear(editable);

    final afterState = container.read(squarewordSessionProvider('p01'));
    expect(afterState.rev, revBefore);
  });
}
