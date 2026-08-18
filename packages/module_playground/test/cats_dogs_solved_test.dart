import 'package:module_playground/module_playground.dart';
import 'package:test/test.dart';

/// Builds a [TokenGraphState] on [board] from a sparse map of node id ->
/// token label; every node not mentioned is free.
TokenGraphState _stateFrom(
  TokenGraphBoard board,
  Map<String, String> placements,
) {
  final tokens = List<String?>.filled(board.nodeIds.length, null);
  placements.forEach((nodeId, token) {
    tokens[board.indexOf(nodeId)] = token;
  });
  return TokenGraphState(tokens);
}

void main() {
  final board = CatsDogsGame.board;
  const game = CatsDogsGame();

  test('initial state is not solved', () {
    final initial = game.initialState();
    expect(game.isSolved(initial), isFalse);
  });

  test('the fully swapped position is solved', () {
    final swapped = _stateFrom(board, {
      'L1': dogToken,
      'L2': dogToken,
      'L3': dogToken,
      'R1': catToken,
      'R2': catToken,
      'R3': catToken,
    });
    expect(game.isSolved(swapped), isTrue);
  });

  test('a near-miss with one seat unfilled is not solved', () {
    final nearMiss = _stateFrom(board, {
      'L1': dogToken,
      'L2': dogToken,
      'M': dogToken,
      'R1': catToken,
      'R2': catToken,
      'R3': catToken,
    });
    expect(game.isSolved(nearMiss), isFalse);
  });

  test('all six seats filled is not solved unless the swap is complete', () {
    final seatsFilledButNotSwapped = _stateFrom(board, {
      'L1': catToken,
      'L2': dogToken,
      'L3': dogToken,
      'R1': dogToken,
      'R2': catToken,
      'R3': catToken,
    });
    expect(game.isSolved(seatsFilledButNotSwapped), isFalse);
  });
}
