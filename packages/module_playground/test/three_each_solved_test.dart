import 'package:module_playground/module_playground.dart';
import 'package:test/test.dart';

/// The book's printed answer (Мочалов, 1980, p. 114), as the nine moves
/// that lay each tile into its slot at its solving rotation.
const List<PlaygroundMove> _bookAnswer = [
  PlaygroundMove(['T2', 'S1r2']),
  PlaygroundMove(['T3', 'S2r0']),
  PlaygroundMove(['T1', 'S3r3']),
  PlaygroundMove(['T4', 'S4r1']),
  PlaygroundMove(['T5', 'S5r3']),
  PlaygroundMove(['T6', 'S6r0']),
  PlaygroundMove(['T9', 'S7r0']),
  PlaygroundMove(['T8', 'S8r3']),
  PlaygroundMove(['T7', 'S9r2']),
];

/// Whether every one of [threeEachLines] on [grid] carries exactly one
/// circle of each colour, computed independently of [ThreeEachGame.isSolved].
bool _everyLineHasThreeEach(List<List<String>> grid) {
  for (final line in threeEachLines()) {
    final counts = {for (final color in threeEachColors) color: 0};
    for (final (r, c) in line) {
      final cell = grid[r][c];
      if (cell == threeEachEmpty) continue;
      counts[cell] = counts[cell]! + 1;
    }
    if (counts.values.any((n) => n != 1)) return false;
  }
  return true;
}

void main() {
  const game = ThreeEachGame();

  test('the book answer solves the puzzle after the last of nine moves, '
      'never before', () {
    var state = game.initialState();
    for (final move in _bookAnswer) {
      expect(game.legalMoves(state), contains(move), reason: '$move');
      state = game.applyMove(state, move);
      final isLastMove = move == _bookAnswer.last;
      expect(game.isSolved(state), isLastMove, reason: '$move');
    }
  });

  test('twenty lines each carry one red, one white and one black circle, '
      'checked independently of isSolved', () {
    var state = game.initialState();
    for (final move in _bookAnswer) {
      state = game.applyMove(state, move);
    }

    expect(_everyLineHasThreeEach((state as ThreeEachState).grid()), isTrue);
  });

  test('a near miss - one tile rotated wrong - fills the board without '
      'solving it', () {
    var state = game.initialState();
    for (final move in _bookAnswer) {
      final swapped = move == const PlaygroundMove(['T6', 'S6r0'])
          ? const PlaygroundMove(['T6', 'S6r1'])
          : move;
      state = game.applyMove(state, swapped);
    }

    expect((state as ThreeEachState).slots.every((p) => p != null), isTrue);
    expect(game.isSolved(state), isFalse);
  });

  test('laying every tile unrotated into its matching slot does not solve '
      'the puzzle', () {
    var state = game.initialState();
    for (var t = 0; t < threeEachTileIds.length; t++) {
      state = game.applyMove(
        state,
        PlaygroundMove([threeEachTileIds[t], '${threeEachSlotIds[t]}r0']),
      );
    }

    expect((state as ThreeEachState).slots.every((p) => p != null), isTrue);
    expect(game.isSolved(state), isFalse);
  });
}
