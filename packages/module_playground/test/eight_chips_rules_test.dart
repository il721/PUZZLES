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
  final board = EightChipsGame.board;
  const game = EightChipsGame();

  test('initial state has exactly 4 legal moves, all landing on C', () {
    final initial = game.initialState();
    final moves = game.legalMoves(initial);
    expect(moves, hasLength(4));
    expect(moves.map((m) => m.to).toSet(), {'C'});
    expect(moves.map((m) => m.from).toSet(), {'P1', 'P3', 'P5', 'P7'});
  });

  test('P1 -> P5 slide is legal only when C is free', () {
    final cFree = _stateFrom(board, {
      'P1': 'a',
      'P2': 'b',
      'P3': 'c',
      'P4': 'd',
      'P6': 'e',
      'P7': 'f',
      'P8': 'g',
      // P5 and C are both free.
    });
    final movesWhenFree = slideMoves(board, cFree, from: 'P1');
    expect(movesWhenFree, contains(const PlaygroundMove(['P1', 'C', 'P5'])));

    final cOccupied = _stateFrom(board, {
      'P1': 'a',
      'P2': 'b',
      'P3': 'c',
      'P4': 'd',
      'C': 'x',
      'P6': 'e',
      'P7': 'f',
      'P8': 'g',
      // P5 is free, but C blocks the path to it.
    });
    final movesWhenBlocked = slideMoves(board, cOccupied, from: 'P1');
    expect(movesWhenBlocked, isEmpty);
  });

  test('applyMove throws ArgumentError for an illegal move', () {
    final initial = game.initialState();
    expect(
      () => game.applyMove(initial, const PlaygroundMove(['P2', 'C'])),
      throwsArgumentError,
    );
  });

  test('a move followed by its reverse returns the identical state', () {
    final initial = game.initialState();
    final forward = const PlaygroundMove(['P1', 'C']);
    final afterForward = game.applyMove(initial, forward);
    final reverse = const PlaygroundMove(['C', 'P1']);
    final afterReverse = game.applyMove(afterForward, reverse);

    expect(afterReverse, equals(initial));
    expect(afterReverse.hashCode, equals(initial.hashCode));
  });

  test('legalMoves(from: P2) is empty on the initial state', () {
    final initial = game.initialState();
    expect(game.legalMoves(initial, from: 'P2'), isEmpty);
  });
}
