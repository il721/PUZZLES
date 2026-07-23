import 'model.dart';

/// Outcome of a [solveSquareword] search.
///
/// [zero], [unique] and [multiple] all presuppose that the search ran to
/// exhaustion (or reached its solution `cap`) - they report how many
/// distinct completions exist. [timeout] is reported whenever the search
/// was cut short by its time budget before reaching that conclusion, no
/// matter how many solutions had already been found by then; a [timeout]
/// result must never be read as "zero solutions" or "these are all the
/// solutions".
enum SquarewordSolveStatus { zero, unique, multiple, timeout }

/// The result of a [solveSquareword] search.
class SquarewordSolveResult {
  /// The search outcome; see [SquarewordSolveStatus].
  final SquarewordSolveStatus status;

  /// The first completed grid found, as `n` row strings (row 0 is the top
  /// row), or `null` if none was found before the search ended.
  final List<String>? solution;

  /// Number of distinct solutions found, capped at the search's `cap`.
  final int count;

  /// Number of cells visited (recursive calls made) during the search, for
  /// diagnostics and tuning `cap`/`timeout`.
  final int nodesVisited;

  /// Creates a result.
  const SquarewordSolveResult({
    required this.status,
    required this.solution,
    required this.count,
    required this.nodesVisited,
  });
}

/// Searches [puzzle] for completions of its `n`x`n` grid such that every
/// row, every column, and both main diagonals (top-left-to-bottom-right,
/// i.e. cells where `row == col`; top-right-to-bottom-left, i.e. cells
/// where `row + col == n - 1`) contain each of [SquarewordPuzzle.letters]
/// exactly once - a "diagonal Latin square" - consistent with
/// [puzzle.givens].
///
/// Depth-first search over the grid's empty cells (row-major order),
/// tracking a bitmask of used letters per row, per column, and for each of
/// the two main diagonals (`n` <= 7 fits comfortably in an `int`). For each
/// empty cell, a candidate letter is skipped if it already appears in that
/// cell's row, column, or (only for cells actually on that diagonal) main
/// diagonal or anti-diagonal.
///
/// If the givens themselves are already contradictory (e.g. the same
/// letter placed twice in one row), the search short-circuits to
/// [SquarewordSolveStatus.zero] without visiting any cell - a genuinely
/// unsatisfiable given-set has zero completions by construction.
///
/// The search stops early once [cap] solutions have been found - status
/// [SquarewordSolveStatus.multiple] is reported for any `cap >= 2` reached
/// - or once [timeout] elapses, whichever comes first. A
/// [SquarewordSolveStatus.timeout] result means the search did not reach
/// exhaustion, so its [SquarewordSolveResult.count] must not be treated as
/// a final solution count.
SquarewordSolveResult solveSquareword(
  SquarewordPuzzle puzzle, {
  int cap = 2,
  Duration timeout = const Duration(seconds: 60),
}) {
  final n = puzzle.n;
  final letters = puzzle.letters;
  final letterIndex = {
    for (var i = 0; i < letters.length; i++) letters[i]: i,
  };

  final grid = List.generate(n, (_) => List<String?>.filled(n, null));
  final rowMask = List.filled(n, 0);
  final colMask = List.filled(n, 0);
  var mainDiagMask = 0; // cells where row == col
  var antiDiagMask = 0; // cells where row + col == n - 1

  bool contradictoryGivens = false;

  for (final g in puzzle.givens) {
    final li = letterIndex[g.letter];
    if (li == null) {
      // A given letter outside this puzzle's own keyword alphabet can
      // never be placed by a completion built from that alphabet.
      contradictoryGivens = true;
      break;
    }
    final bit = 1 << li;
    final onMain = g.row == g.col;
    final onAnti = g.row + g.col == n - 1;

    if (rowMask[g.row] & bit != 0 ||
        colMask[g.col] & bit != 0 ||
        (onMain && mainDiagMask & bit != 0) ||
        (onAnti && antiDiagMask & bit != 0)) {
      contradictoryGivens = true;
      break;
    }

    grid[g.row][g.col] = g.letter;
    rowMask[g.row] |= bit;
    colMask[g.col] |= bit;
    if (onMain) mainDiagMask |= bit;
    if (onAnti) antiDiagMask |= bit;
  }

  if (contradictoryGivens) {
    return const SquarewordSolveResult(
      status: SquarewordSolveStatus.zero,
      solution: null,
      count: 0,
      nodesVisited: 0,
    );
  }

  final emptyCells = <Cell>[];
  for (var r = 0; r < n; r++) {
    for (var c = 0; c < n; c++) {
      if (grid[r][c] == null) {
        emptyCells.add(Cell(r, c));
      }
    }
  }

  var count = 0;
  var nodesVisited = 0;
  var timedOut = false;
  List<String>? firstFound;

  final stopwatch = Stopwatch()..start();

  bool timedOutNow() {
    if (nodesVisited % 4096 == 0 && stopwatch.elapsed >= timeout) {
      timedOut = true;
    }
    return timedOut;
  }

  List<String> snapshotGrid() =>
      List.generate(n, (r) => grid[r].map((l) => l!).join());

  // Returns `false` once the whole search should stop (cap reached or
  // timed out); `true` to keep exploring sibling branches.
  bool search(int idx) {
    nodesVisited++;
    if (timedOutNow()) {
      return false;
    }

    if (idx == emptyCells.length) {
      count++;
      firstFound ??= snapshotGrid();
      return count < cap;
    }

    final cell = emptyCells[idx];
    final r = cell.row;
    final c = cell.col;
    final onMain = r == c;
    final onAnti = r + c == n - 1;

    for (var li = 0; li < letters.length; li++) {
      final bit = 1 << li;
      if (rowMask[r] & bit != 0) continue;
      if (colMask[c] & bit != 0) continue;
      if (onMain && mainDiagMask & bit != 0) continue;
      if (onAnti && antiDiagMask & bit != 0) continue;

      grid[r][c] = letters[li];
      rowMask[r] |= bit;
      colMask[c] |= bit;
      if (onMain) mainDiagMask |= bit;
      if (onAnti) antiDiagMask |= bit;

      final keepGoing = search(idx + 1);

      grid[r][c] = null;
      rowMask[r] &= ~bit;
      colMask[c] &= ~bit;
      if (onMain) mainDiagMask &= ~bit;
      if (onAnti) antiDiagMask &= ~bit;

      if (!keepGoing) {
        return false;
      }
    }
    return true;
  }

  search(0);

  if (timedOut) {
    return SquarewordSolveResult(
      status: SquarewordSolveStatus.timeout,
      solution: firstFound,
      count: count,
      nodesVisited: nodesVisited,
    );
  }

  final status = count == 0
      ? SquarewordSolveStatus.zero
      : (count == 1
          ? SquarewordSolveStatus.unique
          : SquarewordSolveStatus.multiple);
  return SquarewordSolveResult(
    status: status,
    solution: firstFound,
    count: count,
    nodesVisited: nodesVisited,
  );
}
