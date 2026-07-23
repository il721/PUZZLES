import 'model.dart';

/// A snapshot of a [SquarewordBoard]'s current state, computed purely from
/// whichever cells are currently filled in - safe to recompute after every
/// player action, with no dependency on placement order or history (mirrors
/// `module_labyrinth`'s `LabyrinthStatus` / `module_domino`'s `BoardStatus`).
///
/// The win condition ([isSolved]) is constraint satisfaction, not a match
/// against any particular canonical solution: any fully-filled grid with
/// zero violations wins, even if it differs from the puzzle's `solver.dart`
/// solution or `05-solve.pdf`'s printed answer.
class SquarewordStatus {
  /// The number of cells (given + editable) currently holding a letter.
  final int filledCount;

  /// Every cell that currently participates in a violation: it shares a
  /// row, a column, the main diagonal, or the anti-diagonal with another
  /// cell holding the *same* letter. Violations are symmetric - if two
  /// cells in one row hold the same letter, both are in this set, not just
  /// the one written second. Given cells are checked exactly like editable
  /// cells; a given can violate (or be part of a violation with) another
  /// cell just as easily as a player-filled one.
  final Set<Cell> violatingCells;

  /// The win condition: every cell in the grid is filled, and
  /// [violatingCells] is empty.
  final bool isSolved;

  /// Creates a status snapshot.
  const SquarewordStatus({
    required this.filledCount,
    required this.violatingCells,
    required this.isSolved,
  });
}

/// Mutable player-facing state for one [SquarewordPuzzle]: an `n`x`n` grid
/// of optional letters, tracking which cells are immutable givens
/// ([puzzle]'s [SquarewordPuzzle.givens]) and which are player-editable.
///
/// Modeled like `module_rebus`'s `PlayerGrid`: a fixed set of given-cell
/// keys, with mutation methods ([place], [clear]) that are no-ops on a
/// given cell. Unlike `PlayerGrid`, placement is never validated against
/// the surrounding grid - per the module's decision #3 ("allow + live
/// highlight, not block-on-entry"), [place] always succeeds against an
/// editable cell, even if it creates a row/column/diagonal duplicate. Live
/// violation detection is [status]'s job, mirroring how
/// `module_labyrinth`'s `LabyrinthBoard.status()` reports what's wrong
/// rather than ever rejecting a write.
class SquarewordBoard {
  /// The puzzle this board plays.
  final SquarewordPuzzle puzzle;

  /// `n`x`n` grid of the letter currently in each cell, or `null` if empty.
  /// Given cells start (and, since [place]/[clear] are no-ops on them,
  /// remain) pre-filled with their printed letter.
  final List<List<String?>> _grid;

  /// The set of cells declared as givens by [puzzle], immutable for the
  /// life of this board.
  final Set<Cell> _givenCells;

  SquarewordBoard._(this.puzzle, this._grid, this._givenCells);

  /// Builds a fresh board for [puzzle]: every given cell pre-filled and
  /// locked, every other cell empty.
  factory SquarewordBoard.fromPuzzle(SquarewordPuzzle puzzle) {
    final n = puzzle.n;
    final grid = List.generate(n, (_) => List<String?>.filled(n, null));
    final givenCells = <Cell>{};
    for (final g in puzzle.givens) {
      grid[g.row][g.col] = g.letter;
      givenCells.add(Cell(g.row, g.col));
    }
    return SquarewordBoard._(puzzle, grid, givenCells);
  }

  /// Whether [cell] is an immutable given.
  bool isGiven(Cell cell) => _givenCells.contains(cell);

  /// The letter currently in [cell], or `null` if empty.
  String? letterAt(Cell cell) => _grid[cell.row][cell.col];

  /// Sets [cell] to [letter]. A no-op if [cell] is a given.
  ///
  /// [letter] must be one of [puzzle]'s own keyword letters ([assert]ed,
  /// not thrown) - the popup picker the UI offers only ever shows a
  /// puzzle's own `n` letters (decision #2), so any other value reaching
  /// here is a programming-contract violation in the calling UI code, not a
  /// user-facing "invalid input" the model needs to reject gracefully.
  ///
  /// Always succeeds against an editable cell, even if it creates a
  /// row/column/diagonal duplicate - see [status] for live violation
  /// detection instead of write-time rejection.
  void place(Cell cell, String letter) {
    assert(
      puzzle.letters.contains(letter),
      'letter "$letter" is not one of puzzle "${puzzle.id}"\'s own keyword '
      'letters (${puzzle.keyword})',
    );
    if (isGiven(cell)) return;
    _grid[cell.row][cell.col] = letter;
  }

  /// Empties [cell]. A no-op if [cell] is a given (or already empty).
  void clear(Cell cell) {
    if (isGiven(cell)) return;
    _grid[cell.row][cell.col] = null;
  }

  /// Every line (a row, a column, or a diagonal) whose cells must
  /// collectively hold each keyword letter at most once - mirroring
  /// `solveSquareword`'s own constraint definition exactly: all `n` rows,
  /// all `n` columns, the main diagonal (cells where `row == col`), and the
  /// anti-diagonal (cells where `row + col == n - 1`).
  Iterable<List<Cell>> _lines() sync* {
    final n = puzzle.n;
    for (var r = 0; r < n; r++) {
      yield [for (var c = 0; c < n; c++) Cell(r, c)];
    }
    for (var c = 0; c < n; c++) {
      yield [for (var r = 0; r < n; r++) Cell(r, c)];
    }
    yield [for (var i = 0; i < n; i++) Cell(i, i)];
    yield [for (var i = 0; i < n; i++) Cell(i, n - 1 - i)];
  }

  /// Computes the current [SquarewordStatus] for this board: how many cells
  /// are filled, which cells currently violate a row/column/diagonal
  /// constraint, and whether the board is solved.
  SquarewordStatus status() {
    final n = puzzle.n;
    var filledCount = 0;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (_grid[r][c] != null) filledCount++;
      }
    }

    final violating = <Cell>{};
    for (final line in _lines()) {
      final byLetter = <String, List<Cell>>{};
      for (final cell in line) {
        final letter = _grid[cell.row][cell.col];
        if (letter == null) continue;
        byLetter.putIfAbsent(letter, () => []).add(cell);
      }
      for (final cells in byLetter.values) {
        if (cells.length > 1) {
          violating.addAll(cells);
        }
      }
    }

    return SquarewordStatus(
      filledCount: filledCount,
      violatingCells: violating,
      isSolved: filledCount == n * n && violating.isEmpty,
    );
  }

  /// Serializes this board's persistent state: the editable (non-given)
  /// cells currently filled in, as `{"filled": {"r,c": "letter"}}` - e.g.
  /// `{"filled": {"1,3": "С"}}` for a single filled cell at row 1, col 3.
  /// Given cells and empty cells are never included; [fromJson] restores
  /// them from [puzzle] / leaves them empty respectively.
  Map<String, dynamic> toJson() {
    final filled = <String, dynamic>{};
    for (var r = 0; r < puzzle.n; r++) {
      for (var c = 0; c < puzzle.n; c++) {
        if (_givenCells.contains(Cell(r, c))) continue;
        final letter = _grid[r][c];
        if (letter != null) {
          filled['$r,$c'] = letter;
        }
      }
    }
    return {'filled': filled};
  }

  /// Restores a board for [puzzle] from previously-persisted [json] (as
  /// produced by [toJson]).
  ///
  /// TOLERANT of stale or corrupt saves, per-key: starts from the same
  /// fresh state as [SquarewordBoard.fromPuzzle], then applies each entry
  /// of `json['filled']` independently, dropping (not throwing on) any
  /// entry whose key is not a well-formed `"r,c"` pair, whose cell is out
  /// of bounds for this [puzzle], whose cell is a given cell, or whose
  /// value is not one of [puzzle]'s own keyword letters. A single bad entry
  /// never discards the rest of a save. If `json` itself isn't a map, or
  /// has no usable `filled` map, this falls back to the fresh initial
  /// state, same as [SquarewordBoard.fromPuzzle].
  factory SquarewordBoard.fromJson(
    SquarewordPuzzle puzzle,
    Map<String, dynamic> json,
  ) {
    final board = SquarewordBoard.fromPuzzle(puzzle);
    final rawFilled = json['filled'];
    if (rawFilled is! Map) return board;

    final alphabet = puzzle.letters.toSet();
    rawFilled.forEach((key, value) {
      if (key is! String || value is! String) return;
      final parts = key.split(',');
      if (parts.length != 2) return;
      final r = int.tryParse(parts[0]);
      final c = int.tryParse(parts[1]);
      if (r == null || c == null) return;
      if (r < 0 || r >= puzzle.n || c < 0 || c >= puzzle.n) return;
      final cell = Cell(r, c);
      if (board.isGiven(cell)) return;
      if (!alphabet.contains(value)) return;
      board._grid[r][c] = value;
    });
    return board;
  }
}
