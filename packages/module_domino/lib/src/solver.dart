import 'model.dart';

/// Canonicalizes a domino's printed values to a sorted `(min, max)` key so
/// e.g. a 3:5 and a 5:3 domino are never treated as distinct.
(int, int) _canonicalPair(int a, int b) => a <= b ? (a, b) : (b, a);

/// The four orthogonal step directions.
const _deltas = [(-1, 0), (1, 0), (0, -1), (0, 1)];

/// Counts occurrences of each digit 0..6 in [grid]. A valid double-six
/// grid must have every digit appear exactly 8 times (56 cells / 7
/// digits).
Map<int, int> digitCounts(List<List<int>> grid) {
  final counts = {for (var d = 0; d <= 6; d++) d: 0};
  for (final row in grid) {
    for (final value in row) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
  }
  return counts;
}

/// Counts value-constrained domino tilings of [grid]: full partitions of
/// every cell into 28 orthogonally-adjacent dominoes whose canonicalized
/// value-pairs are exactly the double-six set (each of the 28 pairs
/// `(i, j)` with `0 <= i <= j <= 6` used once). Search stops early once
/// [cap] tilings have been found, so a returned count equal to [cap]
/// means "at least [cap]" (the default cap of 2 signals non-uniqueness
/// without exhaustively enumerating every tiling).
int countSolutions(List<List<int>> grid, {int cap = 2}) {
  var count = 0;
  _search(grid, onSolution: (_) {
    count++;
    return count < cap;
  });
  return count;
}

/// Returns one valid value-constrained tiling of [grid] (28 dominoes), or
/// `null` if no such tiling exists.
List<Domino>? firstSolution(List<List<int>> grid) {
  List<Domino>? found;
  _search(grid, onSolution: (solution) {
    found = List<Domino>.from(solution);
    return false; // stop after the first hit
  });
  return found;
}

/// Backtracking search shared by [countSolutions] and [firstSolution].
///
/// Repeatedly locates the first uncovered cell in row-major order and
/// tries pairing it with each uncovered orthogonal neighbor whose
/// canonical value-pair has not been used yet, recursing and backtracking.
/// Because a grid of digits 0..6 has exactly 28 possible canonical value
/// pairs (matching the 28 dominoes needed to cover 56 cells), forbidding
/// pair reuse is sufficient to guarantee that any full tiling found uses
/// every double-six pair exactly once.
///
/// [onSolution] is invoked with each full tiling found, in placement
/// order; its return value controls whether the search continues looking
/// for further tilings.
void _search(
  List<List<int>> grid, {
  required bool Function(List<Domino> solution) onSolution,
}) {
  final rows = grid.length;
  final cols = rows == 0 ? 0 : grid[0].length;
  final covered = List.generate(rows, (_) => List.filled(cols, false));
  final usedPairs = <(int, int)>{};
  final placed = <Domino>[];
  var keepGoing = true;

  void search(int fromRow, int fromCol) {
    if (!keepGoing) {
      return;
    }

    // Find the first uncovered cell scanning row-major from (fromRow,
    // fromCol) onward.
    var r = fromRow;
    var c = fromCol;
    while (r < rows && covered[r][c]) {
      c++;
      if (c == cols) {
        c = 0;
        r++;
      }
    }

    if (r == rows) {
      // Every cell is covered: a full valid tiling.
      keepGoing = onSolution(placed);
      return;
    }

    for (final (dr, dc) in _deltas) {
      final nr = r + dr;
      final nc = c + dc;
      if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) {
        continue;
      }
      if (covered[nr][nc]) {
        continue;
      }

      final pair = _canonicalPair(grid[r][c], grid[nr][nc]);
      if (usedPairs.contains(pair)) {
        continue;
      }

      covered[r][c] = true;
      covered[nr][nc] = true;
      usedPairs.add(pair);
      placed.add(Domino(Cell(r, c), Cell(nr, nc)));

      search(r, c);

      placed.removeLast();
      usedPairs.remove(pair);
      covered[r][c] = false;
      covered[nr][nc] = false;

      if (!keepGoing) {
        return;
      }
    }
  }

  search(0, 0);
}
