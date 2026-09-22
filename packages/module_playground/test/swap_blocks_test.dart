import 'package:module_playground/module_playground.dart';
import 'package:test/test.dart';

/// The block's occupied cells (row*8+col) at its start origin, from the
/// game's own tables - used to check the layout invariants independently of
/// the game's flood-fill logic.
List<int> _startCells(int block) {
  final r0 = swapBlocksStartOrigins[block] ~/ swapBlocksCols;
  final c0 = swapBlocksStartOrigins[block] % swapBlocksCols;
  return [
    for (final (dr, dc) in swapBlocksShapeOffsets[swapBlocksShapes[block]]!)
      (r0 + dr) * swapBlocksCols + (c0 + dc),
  ];
}

/// Whether shape [b]'s 8-cell footprint is congruent to shape [a]'s under
/// one of the 8 symmetries of the square (4 rotations, and the same 4 after
/// a horizontal flip) - i.e. same multiset of cells up to that transform,
/// normalized to start at (0,0).
bool _congruent(List<(int, int)> a, List<(int, int)> b, {required bool allowFlip}) {
  // Sorted, offset-normalized cell list - a canonical form so two footprints
  // can be compared by simple list equality (default Set/List == is
  // identity-based in Dart, not structural, so this avoids that trap).
  List<(int, int)> normalize(Iterable<(int, int)> cells) {
    final minR = cells.map((c) => c.$1).reduce((x, y) => x < y ? x : y);
    final minC = cells.map((c) => c.$2).reduce((x, y) => x < y ? x : y);
    final shifted = cells.map((c) => (c.$1 - minR, c.$2 - minC)).toList();
    shifted.sort((p, q) =>
        p.$1 != q.$1 ? p.$1.compareTo(q.$1) : p.$2.compareTo(q.$2));
    return shifted;
  }

  bool sameList(List<(int, int)> x, List<(int, int)> y) {
    if (x.length != y.length) return false;
    for (var i = 0; i < x.length; i++) {
      if (x[i] != y[i]) return false;
    }
    return true;
  }

  final target = normalize(a);
  final variants = allowFlip ? [b, b.map((c) => (c.$1, -c.$2)).toList()] : [b];

  for (final variant in variants) {
    var cur = variant;
    for (var rot = 0; rot < 4; rot++) {
      if (sameList(normalize(cur), target)) return true;
      cur = cur.map((c) => (c.$2, -c.$1)).toList();
    }
  }
  return false;
}

void main() {
  final game = SwapBlocksGame();

  group('layout invariants', () {
    test('the twelve start footprints are pairwise disjoint', () {
      final seen = <int>{};
      for (var b = 0; b < swapBlocksBlockCount; b++) {
        for (final cell in _startCells(b)) {
          expect(seen.add(cell), isTrue, reason: 'cell $cell reused by block $b');
        }
      }
    });

    test('the twelve start footprints cover exactly 96 cells', () {
      final all = <int>{};
      for (var b = 0; b < swapBlocksBlockCount; b++) {
        all.addAll(_startCells(b));
      }
      expect(all, hasLength(96));
    });

    test('the free cells are exactly rows 6..9 (0-based)', () {
      final occupied = <int>{};
      for (var b = 0; b < swapBlocksBlockCount; b++) {
        occupied.addAll(_startCells(b));
      }
      final free = <int>{};
      for (var cell = 0; cell < swapBlocksRows * swapBlocksCols; cell++) {
        if (!occupied.contains(cell)) free.add(cell);
      }
      final expected = <int>{
        for (var r = 6; r <= 9; r++)
          for (var c = 0; c < swapBlocksCols; c++) r * swapBlocksCols + c,
      };
      expect(free, expected);
    });

    test('all twelve footprints are congruent under rotation+reflection, '
        'and exactly two are congruent under rotation alone', () {
      final shapeA = swapBlocksShapeOffsets[SwapBlocksShape.a]!;
      for (final shape in SwapBlocksShape.values) {
        expect(
          _congruent(shapeA, swapBlocksShapeOffsets[shape]!, allowFlip: true),
          isTrue,
          reason: 'shape $shape not congruent to A under rotation+reflection',
        );
      }

      // Across all four shapes, find which pairs are rotation-only congruent.
      var rotationOnlyPairCount = 0;
      for (final s1 in SwapBlocksShape.values) {
        for (final s2 in SwapBlocksShape.values) {
          if (s1.index >= s2.index) continue;
          if (_congruent(
            swapBlocksShapeOffsets[s1]!,
            swapBlocksShapeOffsets[s2]!,
            allowFlip: false,
          )) {
            rotationOnlyPairCount++;
          }
        }
      }
      // The book's four shapes come in two rotation-congruent pairs (two
      // "left-handed", two "right-handed"): A~C and B~D under rotation
      // alone, both handednesses present.
      expect(rotationOnlyPairCount, 2);
    });
  });

  group('play', () {
    test('the start state is not solved', () {
      expect(game.isSolved(game.initialState()), isFalse);
    });

    test('legalMoves from the start state returns exactly 56 moves', () {
      final moves = game.legalMoves(game.initialState());
      expect(moves, hasLength(56));
    });

    test('every legal move applies cleanly to a disjoint, in-bounds state',
        () {
      final start = game.initialState() as SwapBlocksState;
      for (final move in game.legalMoves(start)) {
        final result = game.applyMove(start, move) as SwapBlocksState;
        final seen = <int>{};
        for (var b = 0; b < swapBlocksBlockCount; b++) {
          final r0 = result.originRow(b);
          final c0 = result.originCol(b);
          expect(r0, inInclusiveRange(0, swapBlocksRows - 3));
          expect(c0, inInclusiveRange(0, swapBlocksCols - 4));
          for (final cell in result.occupiedCells(b)) {
            expect(seen.add(cell), isTrue,
                reason: 'move $move produced overlap at cell $cell');
          }
        }
      }
    });

    test('a move followed by its reverse returns to the original state', () {
      final start = game.initialState() as SwapBlocksState;
      final move = game.legalMoves(start).first;
      final afterMove = game.applyMove(start, move);
      final reverse = PlaygroundMove([move.to, move.from]);
      final back = game.applyMove(afterMove, reverse);
      expect(back, equals(start));
    });

    test('applyMove throws ArgumentError for an illegal move', () {
      final start = game.initialState();
      expect(
        () => game.applyMove(
          start,
          const PlaygroundMove(['r1c1', 'r1c1']),
        ),
        throwsArgumentError,
      );
      expect(
        () => game.applyMove(
          start,
          const PlaygroundMove(['r99c99', 'r1c1']),
        ),
        throwsArgumentError,
      );
    });

    test('isSolved is true for the goal layout (red/black pair swap)', () {
      final start = game.initialState() as SwapBlocksState;
      final origins = List<int>.from(start.origins);
      final t2 = origins[2];
      origins[2] = origins[8];
      origins[8] = t2;
      final t3 = origins[3];
      origins[3] = origins[9];
      origins[9] = t3;
      expect(game.isSolved(SwapBlocksState(origins)), isTrue);
    });

    test('isSolved is also true when two same-class plain blocks are '
        'exchanged instead of the identity mapping (class occupancy, not '
        'identity)', () {
      final start = game.initialState() as SwapBlocksState;
      final origins = List<int>.from(start.origins);
      // Swap the red/black pairs (required for the goal)...
      final t2 = origins[2];
      origins[2] = origins[8];
      origins[8] = t2;
      final t3 = origins[3];
      origins[3] = origins[9];
      origins[9] = t3;
      // ...and additionally exchange blocks 0 and 6, both shape A / plain.
      final t0 = origins[0];
      origins[0] = origins[6];
      origins[6] = t0;
      expect(game.isSolved(SwapBlocksState(origins)), isTrue);
    });
  });

  group('json', () {
    test('round-trips the start state', () {
      final start = game.initialState();
      final json = game.stateToJson(start);
      final parsed = game.stateFromJson(json);
      expect(parsed, equals(start));
    });

    test('round-trips a state reached by a legal move', () {
      final start = game.initialState() as SwapBlocksState;
      final move = game.legalMoves(start).last;
      final moved = game.applyMove(start, move);
      final parsed = game.stateFromJson(game.stateToJson(moved));
      expect(parsed, equals(moved));
    });

    test('stateFromJson returns null for malformed input', () {
      expect(game.stateFromJson(null), isNull);
      expect(game.stateFromJson('nope'), isNull);
      expect(game.stateFromJson(<String, dynamic>{}), isNull);
      expect(game.stateFromJson({'origins': 'nope'}), isNull);
      expect(game.stateFromJson({'origins': List<int>.filled(11, 0)}), isNull);
      expect(
        game.stateFromJson({
          'origins': [for (var i = 0; i < 12; i++) 'x'],
        }),
        isNull,
      );
      expect(
        game.stateFromJson({
          'origins': [for (var i = 0; i < 12; i++) -1],
        }),
        isNull,
      );
      expect(
        game.stateFromJson({
          'origins': [for (var i = 0; i < 12; i++) 999],
        }),
        isNull,
      );
      // Every block at the same origin -> massive overlap.
      expect(
        game.stateFromJson({
          'origins': List<int>.filled(12, swapBlocksStartOrigins[0]),
        }),
        isNull,
      );
    });
  });
}
