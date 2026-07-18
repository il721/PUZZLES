import 'evaluator.dart';
import 'model.dart';

/// Default enumeration cap for [countSolutions]. The ship gate only needs
/// to distinguish 0 / 1 / "more than 1"; the cap bounds worst-case work on
/// a pathologically loose puzzle.
const int solutionCap = 1000;

/// Verifies the puzzle's printed answer against every constraint. Returns
/// human-readable violations; an empty list means the answer is valid.
List<String> verifyCanonical(DigitRebusPuzzle puzzle) {
  final violations = <String>[];
  final a = puzzle.answer;

  for (var row = 0; row < 4; row++) {
    for (var col = 0; col < 4; col++) {
      final glyph = puzzle.glyphs[row][col];
      if (!glyph.digits.contains(a[row][col])) {
        violations.add(
          'cell[$row][$col]: digit ${a[row][col]} not allowed by '
          '${glyph.code} ${glyph.digits}',
        );
      }
    }
  }

  for (var row = 0; row < 4; row++) {
    if (!lineHolds(a[row], puzzle.rowOps[row])) {
      violations.add('row $row equation fails');
    }
  }
  for (var col = 0; col < 4; col++) {
    final cells = [for (var row = 0; row < 4; row++) a[row][col]];
    if (!lineHolds(cells, puzzle.colOps[col])) {
      violations.add('col $col equation fails');
    }
  }

  return violations;
}

/// Counts assignments that satisfy all constraints, enumerating each
/// cell's domain as exactly its glyph's digit set (never 0-9) with
/// row/column pruning, stopping at [cap].
int countSolutions(DigitRebusPuzzle puzzle, {int cap = solutionCap}) {
  final domains = [
    for (var row = 0; row < 4; row++)
      [
        for (var col = 0; col < 4; col++)
          puzzle.glyphs[row][col].digits.toList(growable: false)
      ]
  ];
  final grid = List.generate(4, (_) => List.filled(4, 0));
  var count = 0;

  bool rowHolds(int row) => lineHolds(grid[row], puzzle.rowOps[row]);
  bool colHolds(int col) => lineHolds(
        [for (var row = 0; row < 4; row++) grid[row][col]],
        puzzle.colOps[col],
      );

  void search(int pos) {
    if (count >= cap) {
      return;
    }
    if (pos == 16) {
      count++;
      return;
    }
    final row = pos ~/ 4;
    final col = pos % 4;
    for (final digit in domains[row][col]) {
      grid[row][col] = digit;
      if (col == 3 && !rowHolds(row)) {
        continue;
      }
      if (row == 3 && !colHolds(col)) {
        continue;
      }
      search(pos + 1);
    }
  }

  search(0);
  return count;
}
