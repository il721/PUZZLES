import 'model.dart';

/// Precomputed letter -> 0..32 index lookup for [russianAlphabet], shared
/// by every [solveLabyrinth] call.
final Map<String, int> _letterIndex = {
  for (var i = 0; i < russianAlphabet.length; i++) russianAlphabet[i]: i,
};

/// The four orthogonal step directions, tried in this fixed order: up,
/// down, left, right.
const _deltas = [(-1, 0), (1, 0), (0, -1), (0, 1)];

/// Manhattan distance between two cells.
int _manhattan(Cell a, Cell b) =>
    (a.row - b.row).abs() + (a.col - b.col).abs();

/// Outcome of a [solveLabyrinth] search.
///
/// [zero], [unique] and [multiple] all presuppose that the search ran to
/// exhaustion (or reached its solution `cap`) - they report how many
/// distinct solutions exist. [timeout] is reported whenever the search was
/// cut short by its time budget before reaching that conclusion, no matter
/// how many solutions had already been found by then; a [timeout] result
/// must never be read as "zero solutions" or "these are all the
/// solutions".
enum LabyrinthSolveStatus { zero, unique, multiple, timeout }

/// The result of a [solveLabyrinth] search.
class LabyrinthSolveResult {
  /// The search outcome; see [LabyrinthSolveStatus].
  final LabyrinthSolveStatus status;

  /// The first solution path found (`А` to `Я`,
  /// [LabyrinthPuzzle.pathLength] cells), or `null` if none was found
  /// before the search ended.
  final List<Cell>? path;

  /// Number of distinct solutions found, capped at the search's `cap`.
  final int count;

  /// Number of cells visited (recursive calls made) during the search, for
  /// diagnostics and tuning `cap`/`timeout`.
  final int nodesVisited;

  /// Creates a result.
  const LabyrinthSolveResult({
    required this.status,
    required this.path,
    required this.count,
    required this.nodesVisited,
  });
}

/// Searches [puzzle] for self-avoiding orthogonal paths of exactly
/// [LabyrinthPuzzle.pathLength] cells from `А` (`grid[0][0]`) to `Я`
/// (`grid[7][7]`) that visit all 33 Russian letters, each exactly once.
///
/// Depth-first search over cells, tracking a `visited` grid, a bitmask of
/// used letter indices, and the current path. Three prunes cut the search
/// before it recurses into a neighbour: (1) the path is never grown past
/// [LabyrinthPuzzle.pathLength] cells; (2) a Manhattan-distance + parity
/// check discards neighbours from which the target cannot possibly be
/// reached in the steps remaining; (3) the target cell is refused unless
/// it would land exactly on the last (33rd) cell.
///
/// The search stops early once [cap] solutions have been found - status
/// [LabyrinthSolveStatus.multiple] is reported for any `cap >= 2` reached -
/// or once [timeout] elapses, whichever comes first. A [LabyrinthSolveStatus.timeout]
/// result means the search did not reach exhaustion, so its
/// [LabyrinthSolveResult.count] must not be treated as a final solution
/// count.
LabyrinthSolveResult solveLabyrinth(
  LabyrinthPuzzle puzzle, {
  int cap = 2,
  Duration timeout = const Duration(seconds: 60),
}) {
  const target = Cell(7, 7);
  final visited = List.generate(
    LabyrinthPuzzle.rows,
    (_) => List.filled(LabyrinthPuzzle.cols, false),
  );
  final path = <Cell>[];
  var usedMask = 0;
  var count = 0;
  var nodesVisited = 0;
  var timedOut = false;
  List<Cell>? firstFound;

  final stopwatch = Stopwatch()..start();

  bool timedOutNow() {
    if (nodesVisited % 8192 == 0 && stopwatch.elapsed >= timeout) {
      timedOut = true;
    }
    return timedOut;
  }

  // Returns `false` once the whole search should stop (cap reached or
  // timed out); `true` to keep exploring sibling branches.
  bool search(Cell current) {
    nodesVisited++;
    if (timedOutNow()) {
      return false;
    }

    if (path.length == LabyrinthPuzzle.pathLength) {
      if (current == target) {
        // A 33-cell self-avoiding path has 33 distinct letters, and the
        // alphabet has exactly 33 letters, so every letter is necessarily
        // used - no need to re-check usedMask against the full alphabet.
        assert(
          usedMask == (1 << russianAlphabet.length) - 1,
          'a full-length path must use every letter of the alphabet',
        );
        count++;
        firstFound ??= List<Cell>.from(path);
        return count < cap;
      }
      return true;
    }

    for (final (dr, dc) in _deltas) {
      final nr = current.row + dr;
      final nc = current.col + dc;
      if (nr < 0 ||
          nr >= LabyrinthPuzzle.rows ||
          nc < 0 ||
          nc >= LabyrinthPuzzle.cols) {
        continue;
      }
      if (visited[nr][nc]) {
        continue;
      }

      final letterBit = 1 << _letterIndex[puzzle.grid[nr][nc]]!;
      if (usedMask & letterBit != 0) {
        continue;
      }

      final neighbour = Cell(nr, nc);
      final wouldBeLength = path.length + 1;

      // Prune 3: the target may only be entered as the last cell.
      if (neighbour == target &&
          wouldBeLength != LabyrinthPuzzle.pathLength) {
        continue;
      }

      // Prune 2: Manhattan distance + parity feasibility from neighbour.
      final remaining = LabyrinthPuzzle.pathLength - path.length;
      final d = _manhattan(neighbour, target);
      if (d > remaining - 1 || (remaining - 1 - d).isOdd) {
        continue;
      }

      visited[nr][nc] = true;
      usedMask |= letterBit;
      path.add(neighbour);

      final keepGoing = search(neighbour);

      path.removeLast();
      usedMask &= ~letterBit;
      visited[nr][nc] = false;

      if (!keepGoing) {
        return false;
      }
    }
    return true;
  }

  visited[0][0] = true;
  usedMask |= 1 << _letterIndex[puzzle.grid[0][0]]!;
  path.add(const Cell(0, 0));
  search(const Cell(0, 0));

  if (timedOut) {
    return LabyrinthSolveResult(
      status: LabyrinthSolveStatus.timeout,
      path: firstFound,
      count: count,
      nodesVisited: nodesVisited,
    );
  }

  final status = count == 0
      ? LabyrinthSolveStatus.zero
      : (count == 1
          ? LabyrinthSolveStatus.unique
          : LabyrinthSolveStatus.multiple);
  return LabyrinthSolveResult(
    status: status,
    path: firstFound,
    count: count,
    nodesVisited: nodesVisited,
  );
}
