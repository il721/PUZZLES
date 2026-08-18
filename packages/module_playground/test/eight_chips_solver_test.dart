import 'dart:io';

import 'package:module_playground/module_playground.dart';
import 'package:test/test.dart';

void main() {
  late PlaygroundData data;

  setUpAll(() {
    final jsonString =
        File('assets/puzzles/module06.json').readAsStringSync();
    data = PlaygroundData.fromJsonString(jsonString);
  });

  test(
    'BFS par is 28 and the reachable closure is 181440 (9!/2 even '
    'permutations)',
    () {
      final board = EightChipsGame.board;
      const game = EightChipsGame();
      final start = game.initialState() as TokenGraphState;

      final result = solveBfs(board, start, game.isSolved);
      expect(result.optimalMoves, 28);

      expect(reachableStateCount(board, start), 181440);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('the stored optimalSolution replays to a solved state in 28 moves',
      () {
    final game = EightChipsGame(data.forId('eight_chips'));
    final solution = game.optimalSolution;
    expect(solution, isNotNull);
    expect(solution, hasLength(28));

    var state = game.initialState();
    for (final move in solution!) {
      final legalFromOrigin = game.legalMoves(state, from: move.from);
      expect(legalFromOrigin, contains(move), reason: 'illegal move: $move');
      state = game.applyMove(state, move);
    }

    expect(game.isSolved(state), isTrue);
  });
}
