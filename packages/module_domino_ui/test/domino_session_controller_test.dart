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

    // With the session provider now autoDispose, a bare container.read
    // does not keep it alive across the awaited delays below — the
    // notifier would be disposed and silently rebuilt mid-test, just like
    // a real widget's ref.watch keeps the session alive for as long as the
    // puzzle screen is visible.
    final sub = container.listen(dominoSessionProvider('example'), (prev, next) {});
    addTearDown(sub.close);

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

    // See the comment in the first test in this file: a live subscription
    // mirrors a widget's ref.watch and keeps the autoDispose session alive
    // for the duration of the test.
    final sub = container.listen(dominoSessionProvider('example'), (prev, next) {});
    addTearDown(sub.close);

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

  test('persisted entry carries an updatedAt epoch-ms stamp', () async {
    final before = DateTime.now().millisecondsSinceEpoch;
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(dominoPuzzlesProvider.future);

    // See the comment in the first test in this file: a live subscription
    // mirrors a widget's ref.watch and keeps the autoDispose session alive
    // for the duration of the test.
    final sub = container.listen(dominoSessionProvider('example'), (prev, next) {});
    addTearDown(sub.close);

    final notifier = container.read(dominoSessionProvider('example').notifier);
    container.read(dominoSessionProvider('example'));
    notifier.tapCell(const Cell(0, 0));
    notifier.tapCell(const Cell(0, 1));

    Map? entry;
    for (var i = 0; i < 50 && entry == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final saved = await saveService.load('module_domino');
      final pz = saved['puzzles'];
      if (pz is Map && pz['example'] is Map) entry = pz['example'] as Map;
    }
    expect(entry, isNotNull, reason: 'entry never landed on disk');
    expect(entry!['updatedAt'], isA<int>());
    expect(entry['updatedAt'] as int, greaterThanOrEqualTo(before));
  });

  test('session is disposed (autoDispose) once its last listener goes away', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(dominoPuzzlesProvider.future);

    // A live subscription is what keeps an autoDispose family provider
    // alive — mirroring a widget's ref.watch while the puzzle screen is
    // visible.
    final sub = container.listen(dominoSessionProvider('example'), (prev, next) {});

    final notifier = container.read(dominoSessionProvider('example').notifier);
    notifier.tapCell(const Cell(0, 0));
    notifier.tapCell(const Cell(0, 1));

    final mutated = container.read(dominoSessionProvider('example'));
    expect(mutated.rev, greaterThan(0));
    expect(mutated.board.isCovered(const Cell(0, 0)), isTrue);

    // Drop the last listener, then give autoDispose a chance to actually
    // run: disposal is scheduled asynchronously after the last listener is
    // removed, not synchronously on close().
    sub.close();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final example = puzzles.firstWhere((p) => p.id == 'example');
    final fresh = container.read(dominoSessionProvider('example'));
    final expectedInitial = DominoSessionState.initial(example);

    expect(fresh.rev, expectedInitial.rev);
    expect(fresh.board.isCovered(const Cell(0, 0)), isFalse);
    expect(fresh.rev, isNot(mutated.rev));
    expect(fresh.board.isCovered(const Cell(0, 0)), isNot(mutated.board.isCovered(const Cell(0, 0))));
  });
}
