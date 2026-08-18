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

  test('the board has 13 nodes and 16 two-node lines', () {
    expect(board.nodeIds, hasLength(13));
    expect(board.lines, hasLength(16));
    for (final line in board.lines) {
      expect(line, hasLength(2), reason: 'line $line');
    }
  });

  test('initial position is peaceful and has exactly 8 legal moves', () {
    final initial = game.initialState() as TokenGraphState;
    expect(isPeacefulPosition(initial), isTrue);

    final moves = game.legalMoves(initial);
    expect(moves, hasLength(8));
    expect(moves.toSet(), {
      const PlaygroundMove(['L1', 'U1']),
      const PlaygroundMove(['L2', 'U1']),
      const PlaygroundMove(['L2', 'D1']),
      const PlaygroundMove(['L3', 'D1']),
      const PlaygroundMove(['R1', 'U2']),
      const PlaygroundMove(['R2', 'U2']),
      const PlaygroundMove(['R2', 'D2']),
      const PlaygroundMove(['R3', 'D2']),
    });
  });

  test(
    'a cat on U1 next to a dog on U2 may not slide adjacent to the dog',
    () {
      final state = _stateFrom(board, {'U1': catToken, 'U2': dogToken});
      final moves = game.legalMoves(state, from: 'U1');

      expect(moves, isNot(contains(const PlaygroundMove(['U1', 'M']))));
      expect(moves, isNot(contains(const PlaygroundMove(['U1', 'TM']))));
      expect(moves, contains(const PlaygroundMove(['U1', 'L1'])));
      expect(moves, contains(const PlaygroundMove(['U1', 'L2'])));
      expect(moves, hasLength(2));
    },
  );

  test('applyMove throws for a banned move, applies an allowed one', () {
    final state = _stateFrom(board, {'U1': catToken, 'U2': dogToken});

    expect(
      () => game.applyMove(state, const PlaygroundMove(['U1', 'M'])),
      throwsArgumentError,
    );

    final moved = game.applyMove(state, const PlaygroundMove(['U1', 'L1']));
    expect(
      moved,
      equals(_stateFrom(board, {'L1': catToken, 'U2': dogToken})),
    );
  });

  test('isPeacefulPosition detects adjacent cat/dog pairs', () {
    final adjacent = _stateFrom(board, {'M': catToken, 'U2': dogToken});
    expect(isPeacefulPosition(adjacent), isFalse);

    final initial = game.initialState() as TokenGraphState;
    expect(isPeacefulPosition(initial), isTrue);
  });
}
