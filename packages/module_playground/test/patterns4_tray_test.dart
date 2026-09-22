import 'package:module_playground/module_playground.dart';
import 'package:test/test.dart';

void main() {
  test('«Узоры 4x4» is a sixteen-tile tray on a sixteen-slot board', () {
    final game = PatternsGame.patterns4();

    expect(patterns4Tiles, hasLength(16));
    expect(game.tiles, hasLength(16));
    expect(game.size, 4);
    expect(game.slotCount, 16);
    expect(game.cellSide, 8);
  });

  test('every 4x4 tray tile is a distinct one of the twenty-five, turned', () {
    final taken = <int>{};

    for (final tile in patterns4Tiles) {
      final wanted = patternsTileMasks(tile, 0);
      int? found;

      for (var i = 0; i < patterns5Tiles.length && found == null; i++) {
        if (taken.contains(i)) continue;
        for (var rotation = 0; rotation < 4; rotation++) {
          final masks = patternsTileMasks(patterns5Tiles[i], rotation);
          var same = true;
          for (var cell = 0; cell < 4; cell++) {
            if (masks[cell] != wanted[cell]) same = false;
          }
          if (same) {
            found = i;
            break;
          }
        }
      }

      expect(found, isNotNull, reason: 'tray tile $tile is not one of the 25');
      taken.add(found!);
    }

    expect(taken, hasLength(16));
  });

  test('every cell of every tray tile carries exactly two directions', () {
    for (final tile in patterns4Tiles) {
      expect(tile, hasLength(4), reason: '$tile');
      for (final cell in tile) {
        expect(patternsConnectors, contains(cell), reason: '$tile');
        final mask = patternsConnectorMask(cell);
        final bits = [
          patternsNorth,
          patternsEast,
          patternsSouth,
          patternsWest,
        ].where((b) => mask & b != 0).length;
        expect(bits, 2, reason: '$tile / $cell');
      }
    }
  });
}
