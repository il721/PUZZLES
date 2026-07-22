import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_labyrinth/module_labyrinth.dart';
import 'package:module_labyrinth_ui/module_labyrinth_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

List<LabyrinthPuzzle> _loadPuzzles() {
  final file = File('../module_labyrinth/assets/puzzles/module04.json');
  return LabyrinthPuzzle.listFromJsonString(file.readAsStringSync());
}

/// Taps every interior cell of [solution] (the `example` puzzle's
/// book-solution path) in forward order, growing chainA the entire way
/// from the `А` anchor up to (but not including) the `Я` anchor. Each
/// tapped cell is adjacent to chainA's current head (the solution is a
/// contiguous path), so every tap is accepted by [LabyrinthBoard.tap]; the
/// final tap lands chainA's head adjacent to the untouched `Я` anchor,
/// joining the path and winning — an honest simulation of real play
/// rather than reaching into the board's internals.
///
/// (Splitting the walk so both chains grow from their own end was tried
/// first, but the board's documented head-adjacency tie-break — a cell
/// adjacent to both heads is always routed to chainA — can steer a
/// chainZ-intended cell into chainA and falsely trigger [isJoined] one
/// step early, silently orphaning cells that were never tapped. A single
/// forward walk has no such ambiguity: chainZ's head never moves off its
/// anchor, so only a cell adjacent to `Я` itself could tie, and the
/// solution only passes adjacent to `Я` at its very last interior step.)
void _tapSolution(LabyrinthSessionNotifier notifier, List<Cell> solution) {
  for (var i = 1; i < solution.length - 1; i++) {
    notifier.tapCell(solution[i]);
  }
}

void main() {
  late List<LabyrinthPuzzle> puzzles;
  late Directory tempDir;
  late SaveService saveService;

  setUpAll(() {
    puzzles = _loadPuzzles();
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('module_labyrinth_ui_session_test_');
    saveService = SaveService(() => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(overrides: [
      labyrinthPuzzlesProvider.overrideWith((ref) async => puzzles),
      labyrinthSaveServiceProvider.overrideWithValue(saveService),
    ]);
  }

  test('threading the example solution from both ends wins and persists solved', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(labyrinthPuzzlesProvider.future);

    // A live subscription mirrors a widget's ref.watch and keeps the
    // autoDispose session alive for the duration of the test.
    final sub = container.listen(labyrinthSessionProvider('example'), (prev, next) {});
    addTearDown(sub.close);

    final example = puzzles.firstWhere((p) => p.id == 'example');
    final notifier = container.read(labyrinthSessionProvider('example').notifier);
    container.read(labyrinthSessionProvider('example'));

    _tapSolution(notifier, example.solution!);

    final state = container.read(labyrinthSessionProvider('example'));
    expect(state.solved, isTrue);
    expect(state.winSeq, 1);
    expect(state.board.status().isSolved, isTrue);

    Map? entry;
    for (var i = 0; i < 50 && entry == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final saved = await saveService.load('module_labyrinth');
      final pz = saved['puzzles'];
      if (pz is Map && pz['example'] is Map && (pz['example'] as Map)['solved'] == true) {
        entry = pz['example'] as Map;
      }
    }
    expect(entry, isNotNull, reason: 'solved state never landed on disk');
  });

  test('persisted entry carries updatedAt, solvedAt and firstSolveElapsedMs after a solve', () async {
    final before = DateTime.now().millisecondsSinceEpoch;
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(labyrinthPuzzlesProvider.future);

    final sub = container.listen(labyrinthSessionProvider('example'), (prev, next) {});
    addTearDown(sub.close);

    final example = puzzles.firstWhere((p) => p.id == 'example');
    final notifier = container.read(labyrinthSessionProvider('example').notifier);
    container.read(labyrinthSessionProvider('example'));

    _tapSolution(notifier, example.solution!);

    Map? entry;
    for (var i = 0; i < 50 && entry == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final saved = await saveService.load('module_labyrinth');
      final pz = saved['puzzles'];
      if (pz is Map && pz['example'] is Map && (pz['example'] as Map)['solved'] == true) {
        entry = pz['example'] as Map;
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

  test('a save merges into the namespace instead of clobbering a sibling puzzle entry', () async {
    // Pre-populate the namespace with an unrelated puzzle's entry, as if
    // "p01" was solved in a previous session.
    await saveService.save('module_labyrinth', <String, dynamic>{
      'puzzles': <String, dynamic>{
        'p01': <String, dynamic>{'chainA': [], 'chainZ': [], 'crosses': [], 'solved': true},
      },
    });

    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(labyrinthPuzzlesProvider.future);

    final sub = container.listen(labyrinthSessionProvider('example'), (prev, next) {});
    addTearDown(sub.close);

    final example = puzzles.firstWhere((p) => p.id == 'example');
    final notifier = container.read(labyrinthSessionProvider('example').notifier);
    container.read(labyrinthSessionProvider('example'));

    notifier.tapCell(example.solution![1]);

    Map? exampleEntry;
    for (var i = 0; i < 50 && exampleEntry == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final saved = await saveService.load('module_labyrinth');
      final pz = saved['puzzles'];
      if (pz is Map && pz['example'] is Map) exampleEntry = pz['example'] as Map;
    }
    expect(exampleEntry, isNotNull, reason: 'example entry never landed on disk');

    final saved = await saveService.load('module_labyrinth');
    final puzzlesMap = saved['puzzles'] as Map;
    expect(puzzlesMap['p01'], isNotNull, reason: 'sibling puzzle entry was clobbered');
    expect((puzzlesMap['p01'] as Map)['solved'], isTrue);
  });

  test('markCell toggles a mark and it survives a save/load round trip', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(labyrinthPuzzlesProvider.future);

    final sub = container.listen(labyrinthSessionProvider('example'), (prev, next) {});
    addTearDown(sub.close);

    final notifier = container.read(labyrinthSessionProvider('example').notifier);
    container.read(labyrinthSessionProvider('example'));

    const markedCell = Cell(0, 7);
    notifier.markCell(markedCell);

    final afterMark = container.read(labyrinthSessionProvider('example'));
    expect(afterMark.board.marks, contains(markedCell));

    Map? entry;
    for (var i = 0; i < 50 && entry == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final saved = await saveService.load('module_labyrinth');
      final pz = saved['puzzles'];
      if (pz is Map && pz['example'] is Map) {
        final candidate = pz['example'] as Map;
        if (candidate['marks'] is List && (candidate['marks'] as List).isNotEmpty) {
          entry = candidate;
        }
      }
    }
    expect(entry, isNotNull, reason: 'marked cell never landed on disk');
    expect(entry!['marks'], contains(equals([markedCell.row, markedCell.col])));

    // Dispose the session (flushes final state) and rebuild a fresh
    // container to force a load from the persisted payload above, proving
    // the mark round-trips through save/load rather than just surviving
    // in memory.
    container.dispose();

    final container2 = makeContainer();
    addTearDown(container2.dispose);
    await container2.read(labyrinthPuzzlesProvider.future);
    final sub2 = container2.listen(labyrinthSessionProvider('example'), (prev, next) {});
    addTearDown(sub2.close);

    LabyrinthSessionState loaded = container2.read(labyrinthSessionProvider('example'));
    for (var i = 0; i < 50 && !loaded.board.marks.contains(markedCell); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      loaded = container2.read(labyrinthSessionProvider('example'));
    }
    expect(loaded.board.marks, contains(markedCell), reason: 'mark did not survive reload');
  });

  test('markCell is a no-op in reviewMode', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(labyrinthPuzzlesProvider.future);

    final sub = container.listen(labyrinthSessionProvider('example'), (prev, next) {});
    addTearDown(sub.close);

    final example = puzzles.firstWhere((p) => p.id == 'example');
    final notifier = container.read(labyrinthSessionProvider('example').notifier);
    container.read(labyrinthSessionProvider('example'));

    _tapSolution(notifier, example.solution!);

    final solvedState = container.read(labyrinthSessionProvider('example'));
    expect(solvedState.reviewMode, isTrue);
    final revBefore = solvedState.rev;
    final marksBefore = solvedState.board.marks.length;

    final untouchedCell = const Cell(0, 7);
    notifier.markCell(untouchedCell);

    final afterState = container.read(labyrinthSessionProvider('example'));
    expect(afterState.rev, revBefore);
    expect(afterState.board.marks.length, marksBefore);
    expect(afterState.board.marks.contains(untouchedCell), isFalse);
  });

  test('reviewMode blocks tapCell and longPressCell once solved', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(labyrinthPuzzlesProvider.future);

    final sub = container.listen(labyrinthSessionProvider('example'), (prev, next) {});
    addTearDown(sub.close);

    final example = puzzles.firstWhere((p) => p.id == 'example');
    final notifier = container.read(labyrinthSessionProvider('example').notifier);
    container.read(labyrinthSessionProvider('example'));

    _tapSolution(notifier, example.solution!);

    final solvedState = container.read(labyrinthSessionProvider('example'));
    expect(solvedState.reviewMode, isTrue);
    final revBefore = solvedState.rev;
    final chainALenBefore = solvedState.board.chainA.length;
    final crossesBefore = solvedState.board.manualCrosses.length;

    // Every cell not on the path is untouched by the solution walk above;
    // a tap/long-press there must be a no-op while reviewMode is true.
    final untouchedCell = const Cell(0, 7);
    notifier.tapCell(untouchedCell);
    notifier.longPressCell(untouchedCell);

    final afterState = container.read(labyrinthSessionProvider('example'));
    expect(afterState.rev, revBefore);
    expect(afterState.board.chainA.length, chainALenBefore);
    expect(afterState.board.manualCrosses.length, crossesBefore);
    expect(afterState.board.isOnPath(untouchedCell), isFalse);
  });
}
