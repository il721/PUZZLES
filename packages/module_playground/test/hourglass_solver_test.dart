import 'dart:io';

import 'package:module_playground/module_playground.dart';
import 'package:test/test.dart';

/// «Песочные часы» is the first playground game whose par this suite does
/// NOT re-derive: C(29,15) = 77558760 positions put an exhaustive search far
/// outside a unit test's budget. The proof that 26 is optimal is the
/// bidirectional bitmask search in `tools/solver/bin/verify_module06.dart`,
/// run at milestone time. What these tests pin is that the shipped data says
/// 26 and that those 26 moves really do replay, move by move, under the
/// rules the app itself plays by.
void main() {
  late PlaygroundData data;

  setUpAll(() {
    final jsonString = File('assets/puzzles/module06.json').readAsStringSync();
    data = PlaygroundData.fromJsonString(jsonString);
  });

  test('the stored optimalSolution replays to a solved state in 26 moves', () {
    final game = HourglassGame(data.forId('hourglass'));
    expect(game.par, 26);
    final solution = game.optimalSolution;
    expect(solution, isNotNull);
    expect(solution, hasLength(26));

    var state = game.initialState();
    for (final move in solution!) {
      final legalFromOrigin = game.legalMoves(state, from: move.from);
      expect(legalFromOrigin, contains(move), reason: 'illegal move: $move');
      state = game.applyMove(state, move);
    }

    expect(game.isSolved(state), isTrue);
  });

  test('the replayed solution empties the upper triangle entirely', () {
    final game = HourglassGame(data.forId('hourglass'));
    var state = game.initialState();
    for (final move in game.optimalSolution!) {
      state = game.applyMove(state, move);
    }

    final board = HourglassGame.board;
    final tokenState = state as TokenGraphState;
    for (final id in hourglassBottomNodes) {
      expect(
        tokenState.tokenAt(board.indexOf(id)),
        hourglassToken,
        reason: 'node $id',
      );
    }
    for (final id in hourglassTopNodes) {
      if (id == 'E1') continue;
      expect(tokenState.tokenAt(board.indexOf(id)), isNull, reason: 'node $id');
    }
  });
}
