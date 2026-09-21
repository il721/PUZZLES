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
  final board = HourglassGame.board;
  const game = HourglassGame();

  test('the board has 29 nodes on 14 straight lines, 40 edges in all', () {
    expect(board.nodeIds, hasLength(29));
    expect(board.lines, hasLength(14));

    final edges = <String>{};
    for (final line in board.lines) {
      expect(line.toSet(), hasLength(line.length), reason: 'line $line');
      for (var i = 0; i + 1 < line.length; i++) {
        final pair = [line[i], line[i + 1]]..sort();
        edges.add(pair.join('-'));
      }
    }
    expect(edges, hasLength(40));
  });

  test('every node has the neighbour count drawn in the scan', () {
    final tables = TokenGraphJumpTables.of(board);
    final degrees = {
      for (var i = 0; i < board.nodeIds.length; i++)
        board.nodeIds[i]: tables.steps[i].length,
    };
    expect(degrees, {
      'A1': 1,
      'A2': 2,
      'A3': 2,
      'A4': 2,
      'A5': 1,
      'B1': 3,
      'B2': 4,
      'B3': 4,
      'B4': 3,
      'C1': 3,
      'C2': 4,
      'C3': 3,
      'D1': 3,
      'D2': 3,
      'E1': 4,
      'F1': 3,
      'F2': 3,
      'G1': 3,
      'G2': 4,
      'G3': 3,
      'H1': 3,
      'H2': 4,
      'H3': 4,
      'H4': 3,
      'I1': 1,
      'I2': 2,
      'I3': 2,
      'I4': 2,
      'I5': 1,
    });
  });

  test('the two triangles share only the waist node', () {
    expect(hourglassTopNodes, hasLength(15));
    expect(hourglassBottomNodes, hasLength(15));
    expect(
      hourglassTopNodes.toSet().intersection(hourglassBottomNodes.toSet()),
      {'E1'},
    );
    expect(
      {...hourglassTopNodes, ...hourglassBottomNodes},
      board.nodeIds.toSet(),
    );
  });

  test('the opening position offers exactly four moves', () {
    final initial = game.initialState() as TokenGraphState;
    expect(initial.tokens.where((t) => t != null), hasLength(15));

    // The upper triangle is packed solid, so nothing in it can step; the
    // only play is through the waist - E1 steps down into either half of
    // the lower triangle's first row, or D1/D2 hop straight over E1.
    expect(game.legalMoves(initial), [
      const PlaygroundMove(['D1', 'F2']),
      const PlaygroundMove(['D2', 'F1']),
      const PlaygroundMove(['E1', 'F1']),
      const PlaygroundMove(['E1', 'F2']),
    ]);
  });

  test('a cascade is one move and may be stopped after any hop', () {
    // D1 hops E1 onto F2, and from F2 may hop G3 onto H4 - both landings
    // are offered, because rule 3 lets the player end a cascade anywhere.
    // C1 and C2 are free in this sparse position, so D1 may also step.
    final state = _stateFrom(board, {
      'D1': hourglassToken,
      'E1': hourglassToken,
      'G3': hourglassToken,
    });

    expect(game.legalMoves(state, from: 'D1'), [
      const PlaygroundMove(['D1', 'C1']),
      const PlaygroundMove(['D1', 'C2']),
      const PlaygroundMove(['D1', 'F2']),
      const PlaygroundMove(['D1', 'F2', 'H4']),
    ]);
  });

  test('a cascade never lands back on the vacated origin', () {
    // E1 hops F2 onto G3; from G3 the only hop back would be over F2 onto
    // E1 itself, which is where the token came from - the move list must
    // not contain it.
    final state = _stateFrom(board, {
      'E1': hourglassToken,
      'F2': hourglassToken,
    });

    final moves = game.legalMoves(state, from: 'E1');
    expect(moves, contains(const PlaygroundMove(['E1', 'G3'])));
    for (final move in moves) {
      expect(move.to, isNot('E1'), reason: '$move');
    }
  });

  test('a move must be replayed by the exact path the rules generate', () {
    final state = _stateFrom(board, {
      'D1': hourglassToken,
      'E1': hourglassToken,
      'G3': hourglassToken,
    });

    const cascade = PlaygroundMove(['D1', 'F2', 'H4']);
    final after = game.applyMove(state, cascade) as TokenGraphState;
    expect(after.tokenAt(board.indexOf('D1')), isNull);
    expect(after.tokenAt(board.indexOf('H4')), hourglassToken);
    expect(after.tokenAt(board.indexOf('E1')), hourglassToken);
    expect(after.tokenAt(board.indexOf('G3')), hourglassToken);

    // Same destination, but not the path the cascade actually takes.
    expect(
      () => game.applyMove(state, const PlaygroundMove(['D1', 'H4'])),
      throwsArgumentError,
    );
  });

  test('a step is never mixed into a cascade', () {
    // D1 hops E1 onto F2 and stops: G3 is empty, so there is no second hop,
    // and "hop onto F2, then step on to G3" is not a move at all.
    final state = _stateFrom(board, {
      'D1': hourglassToken,
      'E1': hourglassToken,
    });

    expect(game.legalMoves(state, from: 'D1'), [
      const PlaygroundMove(['D1', 'C1']),
      const PlaygroundMove(['D1', 'C2']),
      const PlaygroundMove(['D1', 'F2']),
    ]);
  });
}
