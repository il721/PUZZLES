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
    'BFS par is 32 and the peaceful reachable closure is 2264',
    () {
      final board = CatsDogsGame.board;
      const game = CatsDogsGame();
      final start = game.initialState() as TokenGraphState;

      final result = solveBfs(
        board,
        start,
        game.isSolved,
        isLegal: isPeacefulPosition,
      );
      expect(result.optimalMoves, 32);

      expect(
        reachableStateCount(board, start, isLegal: isPeacefulPosition),
        2264,
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('the stored optimalSolution replays to a solved state in 32 moves',
      () {
    final game = CatsDogsGame(data.forId('cats_dogs'));
    final solution = game.optimalSolution;
    expect(solution, isNotNull);
    expect(solution, hasLength(32));

    var state = game.initialState();
    for (final move in solution!) {
      final legalFromOrigin = game.legalMoves(state, from: move.from);
      expect(legalFromOrigin, contains(move), reason: 'illegal move: $move');
      state = game.applyMove(state, move);
    }

    expect(game.isSolved(state), isTrue);
  });
}
