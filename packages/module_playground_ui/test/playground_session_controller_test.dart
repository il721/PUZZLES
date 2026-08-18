import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_playground/module_playground.dart';
import 'package:module_playground_ui/module_playground_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

List<PlaygroundGame> _loadGames() {
  final file = File('../module_playground/assets/puzzles/module06.json');
  final data = PlaygroundData.fromJsonString(file.readAsStringSync());
  return buildPlaygroundRegistry(data);
}

void main() {
  late List<PlaygroundGame> games;
  late PlaygroundGame eightChips;
  late Directory tempDir;
  late SaveService saveService;

  setUpAll(() {
    games = _loadGames();
    eightChips = games.firstWhere((g) => g.id == 'eight_chips');
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('module_playground_ui_session_test_');
    saveService = SaveService(() => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(overrides: [
      playgroundPuzzlesProvider.overrideWith((ref) async => games),
      playgroundSaveServiceProvider.overrideWithValue(saveService),
    ]);
  }

  test('apply pushes one move onto the stack (moveCount 1)', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(playgroundPuzzlesProvider.future);

    final sub = container.listen(playgroundSessionProvider('eight_chips'), (prev, next) {});
    addTearDown(sub.close);

    final notifier = container.read(playgroundSessionProvider('eight_chips').notifier);
    final initial = container.read(playgroundSessionProvider('eight_chips'));
    expect(initial.moveCount, 0);

    final legalMove = eightChips.legalMoves(initial.board).first;
    notifier.apply(legalMove);

    expect(container.read(playgroundSessionProvider('eight_chips')).moveCount, 1);
  });

  test('undo pops the last move and the board equals the initial state', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(playgroundPuzzlesProvider.future);

    final sub = container.listen(playgroundSessionProvider('eight_chips'), (prev, next) {});
    addTearDown(sub.close);

    final notifier = container.read(playgroundSessionProvider('eight_chips').notifier);
    final initial = container.read(playgroundSessionProvider('eight_chips'));
    final initialBoard = initial.board;

    final legalMove = eightChips.legalMoves(initialBoard).first;
    notifier.apply(legalMove);
    expect(container.read(playgroundSessionProvider('eight_chips')).moveCount, 1);

    notifier.undo();
    final afterUndo = container.read(playgroundSessionProvider('eight_chips'));
    expect(afterUndo.moveCount, 0);
    expect(afterUndo.board, equals(initialBoard));
  });

  test('restart clears the move stack', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(playgroundPuzzlesProvider.future);

    final sub = container.listen(playgroundSessionProvider('eight_chips'), (prev, next) {});
    addTearDown(sub.close);

    final notifier = container.read(playgroundSessionProvider('eight_chips').notifier);
    final initial = container.read(playgroundSessionProvider('eight_chips'));
    final legalMove = eightChips.legalMoves(initial.board).first;
    notifier.apply(legalMove);
    notifier.apply(eightChips.legalMoves(container.read(playgroundSessionProvider('eight_chips')).board).first);
    expect(container.read(playgroundSessionProvider('eight_chips')).moveCount, greaterThan(0));

    notifier.restart();
    final afterRestart = container.read(playgroundSessionProvider('eight_chips'));
    expect(afterRestart.moveCount, 0);
    expect(afterRestart.board, equals(initial.board));
  });

  test(
      'applying the recorded 28-move optimalSolution marks solved, sets bestMoves 28, '
      'bumps winSeq exactly once', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(playgroundPuzzlesProvider.future);

    final sub = container.listen(playgroundSessionProvider('eight_chips'), (prev, next) {});
    addTearDown(sub.close);

    final notifier = container.read(playgroundSessionProvider('eight_chips').notifier);
    container.read(playgroundSessionProvider('eight_chips'));

    final solution = eightChips.optimalSolution;
    expect(solution, isNotNull, reason: 'eight_chips must have a recorded optimal solution');
    expect(solution!, hasLength(28));

    for (final move in solution) {
      notifier.apply(move);
    }

    final state = container.read(playgroundSessionProvider('eight_chips'));
    expect(state.solved, isTrue);
    expect(state.bestMoves, 28);
    expect(state.winSeq, 1);
    expect(eightChips.isSolved(state.board), isTrue);
  });
}
