import 'package:module_playground/module_playground.dart';
import 'package:test/test.dart';

void main() {
  final game = PatternsGame.patterns5();

  test('twenty-five tiles of four known connectors each', () {
    expect(patterns5Tiles, hasLength(25));
    for (final tile in patterns5Tiles) {
      expect(tile, hasLength(4), reason: 'tile $tile');
      for (final cell in tile) {
        expect(patternsConnectors, contains(cell), reason: 'cell $cell');
      }
    }
  });

  test('every tile is internally continuous across its own two seams', () {
    for (var t = 0; t < patterns5Tiles.length; t++) {
      final masks = patternsTileMasks(patterns5Tiles[t], 0);
      expect(
        masks[0] & patternsEast != 0,
        masks[1] & patternsWest != 0,
        reason: 'tile ${t + 1}: top seam',
      );
      expect(
        masks[2] & patternsEast != 0,
        masks[3] & patternsWest != 0,
        reason: 'tile ${t + 1}: bottom seam',
      );
      expect(
        masks[0] & patternsSouth != 0,
        masks[2] & patternsNorth != 0,
        reason: 'tile ${t + 1}: left seam',
      );
      expect(
        masks[1] & patternsSouth != 0,
        masks[3] & patternsNorth != 0,
        reason: 'tile ${t + 1}: right seam',
      );
    }
  });

  test('every cell joins exactly two of its four sides', () {
    for (final tile in patterns5Tiles) {
      for (final mask in patternsTileMasks(tile, 0)) {
        final sides = [
          patternsNorth,
          patternsEast,
          patternsSouth,
          patternsWest,
        ].where((d) => mask & d != 0);
        expect(sides, hasLength(2), reason: 'connector mask $mask');
      }
    }
  });

  test('four quarter turns are the identity for every tile', () {
    for (final tile in patterns5Tiles) {
      expect(patternsTileMasks(tile, 4), patternsTileMasks(tile, 0),
          reason: 'tile $tile');
    }
  });

  test('one clockwise turn of T1 matches the hand-worked rotation', () {
    // T1 is [NE, SW, SW, NE]; turning it clockwise moves the bottom-left
    // cell into the top-left corner and turns each connector with it, so
    // SW -> NW, NE -> SE.
    expect(
      patternsTileMasks(patterns5Tiles[0], 1),
      [
        patternsConnectorMask('NW'),
        patternsConnectorMask('SE'),
        patternsConnectorMask('SE'),
        patternsConnectorMask('NW'),
      ],
    );
  });

  test('an empty board offers every tile into every slot at every rotation',
      () {
    final moves = game.legalMoves(game.initialState());
    expect(moves, hasLength(25 * 25 * 4));
    expect(moves, contains(const PlaygroundMove(['T1', 'S1r0'])));
    expect(moves, contains(const PlaygroundMove(['T25', 'S25r3'])));
  });

  test('a laid tile can be turned or taken back, and is gone from the tray',
      () {
    var state = game.initialState();
    state = game.applyMove(state, const PlaygroundMove(['T3', 'S7r2']));

    final fromSlot = game.legalMoves(state, from: 'S7');
    expect(fromSlot, hasLength(4));
    expect(fromSlot, contains(const PlaygroundMove(['S7', 'S7r0'])));
    expect(fromSlot, contains(const PlaygroundMove(['S7', 'T3'])));
    expect(fromSlot, isNot(contains(const PlaygroundMove(['S7', 'S7r2']))));

    expect(game.legalMoves(state, from: 'T3'), isEmpty);
    expect(
      game.legalMoves(state, from: 'T4'),
      hasLength(24 * 4),
      reason: 'S7 is taken, so 24 slots remain',
    );

    state = game.applyMove(state, const PlaygroundMove(['S7', 'S7r1']));
    expect((state as PatternsState).slots[6], const PatternsPlacement(2, 1));

    state = game.applyMove(state, const PlaygroundMove(['S7', 'T3']));
    expect((state as PatternsState).slots[6], isNull);
    expect(game.legalMoves(state, from: 'T3'), hasLength(25 * 4));
  });

  test('applying an illegal move throws', () {
    final state = game.initialState();
    expect(
      () => game.applyMove(state, const PlaygroundMove(['S1', 'T1'])),
      throwsArgumentError,
    );
    expect(
      () => game.applyMove(state, const PlaygroundMove(['T1', 'S26r0'])),
      throwsArgumentError,
    );
    expect(
      () => game.applyMove(state, const PlaygroundMove(['T1', 'S1r4'])),
      throwsArgumentError,
    );
  });

  test('par is null: the puzzle has no move economy', () {
    expect(game.par, isNull);
    expect(game.parSource, isNull);
    expect(game.parProven, isFalse);
    expect(game.family, PlaygroundFamily.tilePlacement);
    expect(game.enabled, isTrue);
  });
}
