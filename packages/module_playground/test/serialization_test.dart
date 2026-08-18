import 'package:module_playground/module_playground.dart';
import 'package:test/test.dart';

void main() {
  const game = EightChipsGame();
  final board = EightChipsGame.board;

  test('state -> stateToJson -> stateFromJson round-trips to an equal state',
      () {
    final state = game.initialState();
    final json = game.stateToJson(state);
    final restored = game.stateFromJson(json);
    expect(restored, equals(state));
  });

  test('stateFromJson returns null (never throws) on defective input', () {
    // Not a map at all.
    expect(game.stateFromJson('not a map'), isNull);
    expect(game.stateFromJson(42), isNull);
    expect(game.stateFromJson(null), isNull);
    expect(game.stateFromJson(<dynamic>['a', 'list']), isNull);

    // Wrong node count: one node key missing entirely.
    final tooFewPositions = <String, dynamic>{
      for (final id in board.nodeIds.where((id) => id != 'P8')) id: null,
    };
    expect(game.stateFromJson({'positions': tooFewPositions}), isNull);

    Map<String, dynamic> validPositions() => Map<String, dynamic>.from(
          game.stateToJson(game.initialState())['positions'] as Map,
        );

    // Unknown token label.
    final unknownLabel = validPositions()..['P1'] = '9';
    expect(game.stateFromJson({'positions': unknownLabel}), isNull);

    // Duplicate token label.
    final duplicateLabel = validPositions();
    duplicateLabel['P2'] = duplicateLabel['P1'];
    expect(game.stateFromJson({'positions': duplicateLabel}), isNull);

    // No free node at all (every position occupied).
    final noFreeNode = validPositions()..['C'] = '1';
    expect(game.stateFromJson({'positions': noFreeNode}), isNull);
  });

  _catsDogsTests();
}

Map<String, dynamic> _catsDogsPositions(Map<String, String> placements) => {
      for (final id in CatsDogsGame.board.nodeIds) id: placements[id],
    };

void _catsDogsTests() {
  const game = CatsDogsGame();

  test(
    'cats_dogs: state -> stateToJson -> stateFromJson round-trips to an '
    'equal state',
    () {
      final state = game.initialState();
      final json = game.stateToJson(state);
      final restored = game.stateFromJson(json);
      expect(restored, equals(state));
    },
  );

  test('cats_dogs: stateFromJson returns null on defective input', () {
    // Not a map at all.
    expect(game.stateFromJson('not a map'), isNull);
    expect(game.stateFromJson(42), isNull);
    expect(game.stateFromJson(null), isNull);
    expect(game.stateFromJson(<dynamic>['a', 'list']), isNull);

    // Missing node key.
    final missingKey = _catsDogsPositions({
      'L1': catToken,
      'L2': catToken,
      'L3': catToken,
      'R1': dogToken,
      'R2': dogToken,
      'R3': dogToken,
    })
      ..remove('BM');
    expect(game.stateFromJson({'positions': missingKey}), isNull);

    // Unknown token label.
    final unknownLabel = _catsDogsPositions({
      'L1': 'X',
      'L2': catToken,
      'L3': catToken,
      'R1': dogToken,
      'R2': dogToken,
      'R3': dogToken,
    });
    expect(game.stateFromJson({'positions': unknownLabel}), isNull);

    // Wrong census: only two cats.
    final wrongCensus = _catsDogsPositions({
      'L2': catToken,
      'L3': catToken,
      'R1': dogToken,
      'R2': dogToken,
      'R3': dogToken,
    });
    expect(game.stateFromJson({'positions': wrongCensus}), isNull);

    // Non-peaceful: a cat and a dog on adjacent nodes (M and D1).
    final notPeaceful = _catsDogsPositions({
      'M': catToken,
      'L2': catToken,
      'L3': catToken,
      'D1': dogToken,
      'R2': dogToken,
      'R3': dogToken,
    });
    expect(game.stateFromJson({'positions': notPeaceful}), isNull);
  });
}
