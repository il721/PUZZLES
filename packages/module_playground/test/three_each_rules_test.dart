import 'package:module_playground/module_playground.dart';
import 'package:test/test.dart';

void main() {
  const game = ThreeEachGame();

  test('the tile data holds nine tiles of nine circles each, evenly split',
      () {
    expect(threeEachTiles, hasLength(9));

    var total = 0;
    final counts = {threeEachRed: 0, threeEachWhite: 0, threeEachBlack: 0};
    for (final tile in threeEachTiles) {
      expect(tile, hasLength(3), reason: 'tile $tile');
      for (final row in tile) {
        expect(row.length, 3, reason: 'row $row');
        for (final cell in row.split('')) {
          if (cell == threeEachEmpty) continue;
          expect(threeEachColors, contains(cell), reason: 'cell $cell');
          counts[cell] = counts[cell]! + 1;
          total++;
        }
      }
    }

    expect(total, 27);
    expect(counts, {threeEachRed: 9, threeEachWhite: 9, threeEachBlack: 9});
  });

  test('four quarter turns are the identity for every tile and cell', () {
    for (var t = 0; t < threeEachTiles.length; t++) {
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          expect(
            threeEachCell(t, 4, r, c),
            threeEachCell(t, 0, r, c),
            reason: 'tile $t at ($r, $c)',
          );
        }
      }
    }
  });

  test('one clockwise turn of tile 0 matches the hand-worked rotation', () {
    const expected = ['.R.', '.B.', 'W.R'];
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        expect(
          threeEachCell(0, 1, r, c),
          expected[r][c],
          reason: 'cell ($r, $c)',
        );
      }
    }
  });

  test('initialState is nine empty slots with all nine tiles in the tray',
      () {
    final state = game.initialState() as ThreeEachState;
    expect(state.slots, List<ThreeEachPlacement?>.filled(9, null));
    expect(state.trayTiles, [0, 1, 2, 3, 4, 5, 6, 7, 8]);

    for (final row in state.grid()) {
      for (final cell in row) {
        expect(cell, threeEachEmpty);
      }
    }
  });

  test('legalMoves on the empty state offers all tile/slot/rotation combos',
      () {
    final state = game.initialState();
    expect(game.legalMoves(state), hasLength(324));
    expect(game.legalMoves(state, from: 'T1'), hasLength(36));
  });

  test('after placing one tile, legalMoves reflects the smaller tray and '
      'the new slot', () {
    final state = game.initialState();
    final afterPlace = game.applyMove(
      state,
      const PlaygroundMove(['T1', 'S1r0']),
    );

    expect(game.legalMoves(afterPlace), hasLength(260));
    expect(game.legalMoves(afterPlace, from: 'S1'), hasLength(4));
  });

  test('placing T1 -> S1r0 lays tile 0 unrotated into the top-left square',
      () {
    final state = game.initialState();
    final afterPlace = game.applyMove(
      state,
      const PlaygroundMove(['T1', 'S1r0']),
    ) as ThreeEachState;

    final grid = afterPlace.grid();
    expect(grid[0][2], threeEachRed);
    expect(grid[1][0], threeEachRed);
    expect(grid[1][1], threeEachBlack);
    expect(grid[2][2], threeEachWhite);

    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        if (r == 0 && c == 2) continue;
        if (r == 1 && c == 0) continue;
        if (r == 1 && c == 1) continue;
        if (r == 2 && c == 2) continue;
        expect(grid[r][c], threeEachEmpty, reason: 'cell ($r, $c)');
      }
    }
  });

  test('rotating in place keeps the tile and changes only the rotation', () {
    final placed = game.applyMove(
      game.initialState(),
      const PlaygroundMove(['T1', 'S1r0']),
    );
    final rotated = game.applyMove(
      placed,
      const PlaygroundMove(['S1', 'S1r1']),
    ) as ThreeEachState;

    expect(rotated.slots[0], const ThreeEachPlacement(0, 1));
    for (var i = 1; i < rotated.slots.length; i++) {
      expect(rotated.slots[i], isNull);
    }
  });

  test('picking a tile up empties the slot and returns it to the tray', () {
    final placed = game.applyMove(
      game.initialState(),
      const PlaygroundMove(['T1', 'S1r0']),
    );
    final pickedUp = game.applyMove(
      placed,
      const PlaygroundMove(['S1', 'T1']),
    ) as ThreeEachState;

    expect(pickedUp, game.initialState());
    expect(pickedUp.trayTiles, contains(0));
  });

  test('applyMove rejects an illegal move rather than mutating silently', () {
    final placed = game.applyMove(
      game.initialState(),
      const PlaygroundMove(['T1', 'S1r0']),
    );

    // Placing into an occupied slot.
    expect(
      () => game.applyMove(placed, const PlaygroundMove(['T2', 'S1r0'])),
      throwsArgumentError,
    );

    // Placing a tile already on the board.
    expect(
      () => game.applyMove(placed, const PlaygroundMove(['T1', 'S2r0'])),
      throwsArgumentError,
    );

    // Rotating an empty slot.
    expect(
      () => game.applyMove(placed, const PlaygroundMove(['S2', 'S2r1'])),
      throwsArgumentError,
    );
  });
}
