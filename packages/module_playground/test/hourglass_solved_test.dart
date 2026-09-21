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

  /// A fresh, mutable copy of the opening position's serialized node map.
  Map<String, dynamic> openingPositions() => Map<String, dynamic>.from(
        game.stateToJson(game.initialState())['positions'] as Map,
      );

  test('the opening position is not solved', () {
    expect(game.isSolved(game.initialState()), isFalse);
  });

  test('the full lower triangle is solved', () {
    expect(game.isSolved(HourglassGame.goalState()), isTrue);
  });

  test('a lower triangle one token short is not solved', () {
    final almost = _stateFrom(board, {
      for (final id in hourglassBottomNodes)
        if (id != 'I3') id: hourglassToken,
      'D1': hourglassToken,
    });
    expect(almost.tokens.where((t) => t != null), hasLength(15));
    expect(game.isSolved(almost), isFalse);
  });

  test('a state survives a JSON round trip', () {
    final initial = game.initialState();
    expect(game.stateFromJson(game.stateToJson(initial)), initial);

    final goal = HourglassGame.goalState();
    expect(game.stateFromJson(game.stateToJson(goal)), goal);
  });

  test('a defective save is rejected rather than half-loaded', () {
    expect(game.stateFromJson(null), isNull);
    expect(game.stateFromJson('nonsense'), isNull);
    expect(game.stateFromJson({'positions': 7}), isNull);

    final missingNode = openingPositions()..remove('I5');
    expect(game.stateFromJson({'positions': missingNode}), isNull);

    final unknownLabel = openingPositions()..['A1'] = 'X';
    expect(game.stateFromJson({'positions': unknownLabel}), isNull);

    final shortCensus = openingPositions()..['A1'] = null;
    expect(game.stateFromJson({'positions': shortCensus}), isNull);
  });
}
