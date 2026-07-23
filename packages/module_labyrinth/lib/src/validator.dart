import 'model.dart';

/// Manhattan distance between two cells.
int _manhattan(Cell a, Cell b) =>
    (a.row - b.row).abs() + (a.col - b.col).abs();

/// Whether [c] lies within the puzzle's fixed 8x8 grid.
bool _inBounds(Cell c) =>
    c.row >= 0 &&
    c.row < LabyrinthPuzzle.rows &&
    c.col >= 0 &&
    c.col < LabyrinthPuzzle.cols;

/// A snapshot of a [LabyrinthBoard]'s current state, computed purely from
/// whichever cells are placed right now - safe to recompute after every
/// player action, with no dependency on placement order or history
/// (mirrors module_domino's `BoardStatus`).
///
/// The win condition ([isSolved]) is constraint satisfaction, not a match
/// against the puzzle's stored `solution`: any joined, full-length,
/// duplicate-free, alphabet-complete path wins, even if it differs from
/// the book's recorded geometry. There is no "Check" button - [isSolved]
/// is meant to be re-evaluated (and thus auto-detected) after every call
/// to [LabyrinthBoard.tap] or [LabyrinthBoard.longPress], becoming true
/// the moment the player's final valid move satisfies it.
class LabyrinthStatus {
  /// The current path cells in order: [LabyrinthBoard.chainA] followed by
  /// [LabyrinthBoard.chainZ] reversed. This is the whole `А`-to-`Я` path
  /// when the two chains are joined, and simply the two partial chains
  /// concatenated (anchor-to-head, then head-to-anchor) when they are not.
  final List<Cell> pathCells;

  /// Whether the two chains' heads are currently orthogonally adjacent.
  final bool isJoined;

  /// The number of cells currently placed (`= pathCells.length`).
  final int placedCount;

  /// The distinct letters currently present among [pathCells]. A letter
  /// used twice still appears only once here; see [duplicateLetters] for
  /// which ones.
  final Set<String> usedLetters;

  /// Letters occurring more than once among [pathCells].
  final Set<String> duplicateLetters;

  /// Alphabet letters not yet used by [pathCells].
  final Set<String> missingLetters;

  /// The win condition: joined, full-length (33 cells), no duplicate
  /// letters, and no missing letters.
  final bool isSolved;

  /// Creates a status snapshot.
  const LabyrinthStatus({
    required this.pathCells,
    required this.isJoined,
    required this.placedCount,
    required this.usedLetters,
    required this.duplicateLetters,
    required this.missingLetters,
    required this.isSolved,
  });
}

/// Mutable player-facing state for one [LabyrinthPuzzle]: two partial
/// chains growing inward from the fixed endpoints - [chainA] anchored at
/// `Cell(0,0)` (`А`) and [chainZ] anchored at `Cell(7,7)` (`Я`) - plus two
/// kinds of off-path player annotation: cells manually marked as
/// "non-conducting" ([manualCrosses]) and cells manually marked as "must
/// be conducting" ([marks]). Every off-path cell is in at most one of
/// these two sets; see [toggleMark] and [longPress].
///
/// The two chains meet in the middle rather than the player drawing one
/// continuous line from `А`, mirroring how the book's solving technique
/// actually works: forced moves are often discoverable from both ends at
/// once. [isJoined] and [autoCrosses] are derived from [chainA]/[chainZ]
/// on every access rather than stored, so retracting a chain cell clears
/// any auto-cross or join state that depended on it for free - there is
/// no separate invalidation step.
class LabyrinthBoard {
  /// The puzzle this board plays.
  final LabyrinthPuzzle puzzle;

  /// The chain growing inward from `Cell(0,0)`. Always non-empty; index 0
  /// is always `Cell(0,0)` and is never removed.
  final List<Cell> _chainA;

  /// The chain growing inward from `Cell(7,7)`. Always non-empty; index 0
  /// is always `Cell(7,7)` and is never removed.
  final List<Cell> _chainZ;

  /// Cells the player has manually marked as crossed via [longPress].
  final Set<Cell> _manualCrosses;

  /// Cells the player has manually marked as "must be on path" via
  /// [toggleMark] - the book's deduction that a letter occurring only
  /// once in the grid is necessarily conducting. Purely a player
  /// annotation: nothing in this board ever derives or auto-populates it.
  final Set<Cell> _marks;

  LabyrinthBoard._(
    this.puzzle,
    this._chainA,
    this._chainZ,
    this._manualCrosses,
    this._marks,
  );

  /// Builds a fresh board for [puzzle]: `chainA = [Cell(0,0)]`,
  /// `chainZ = [Cell(7,7)]`, no manual crosses, no marks.
  factory LabyrinthBoard.fromPuzzle(LabyrinthPuzzle puzzle) => LabyrinthBoard._(
        puzzle,
        [const Cell(0, 0)],
        [const Cell(7, 7)],
        <Cell>{},
        <Cell>{},
      );

  /// The chain growing inward from `Cell(0,0)`, as an unmodifiable view.
  List<Cell> get chainA => List.unmodifiable(_chainA);

  /// The chain growing inward from `Cell(7,7)`, as an unmodifiable view.
  List<Cell> get chainZ => List.unmodifiable(_chainZ);

  /// Cells manually marked as crossed, as an unmodifiable view.
  Set<Cell> get manualCrosses => Set.unmodifiable(_manualCrosses);

  /// Cells manually marked as "must be on path", as an unmodifiable view.
  /// See [toggleMark].
  Set<Cell> get marks => Set.unmodifiable(_marks);

  /// The growing end of [chainA]: the cell a tap extends from.
  Cell get headA => _chainA.last;

  /// The growing end of [chainZ]: the cell a tap extends from.
  Cell get headZ => _chainZ.last;

  /// Whether the path is joined: derived (never stored) as `true` exactly
  /// when [headA] and [headZ] are orthogonally adjacent. Once true, [tap]
  /// treats extension as terminal (see [tap]).
  bool get isJoined => _manhattan(headA, headZ) == 1;

  /// Every cell auto-crossed by the book's rule 4 ("if one of several
  /// identical letters becomes conducting, the rest immediately become
  /// non-conducting"): for every letter currently on [chainA] or
  /// [chainZ], every *other* grid cell bearing that same letter, except
  /// cells that are themselves on a chain.
  ///
  /// This is a derived, uncached getter, recomputed on every access - it
  /// is never stored and never persisted (see [toJson]). Because it is
  /// derived, retracting a chain cell clears its auto-crosses for free:
  /// there is nothing to invalidate.
  Set<Cell> get autoCrosses {
    final pathLetters = <String>{
      for (final c in _chainA) puzzle.letterAt(c),
      for (final c in _chainZ) puzzle.letterAt(c),
    };
    final result = <Cell>{};
    for (var r = 0; r < LabyrinthPuzzle.rows; r++) {
      for (var c = 0; c < LabyrinthPuzzle.cols; c++) {
        final cell = Cell(r, c);
        if (isOnPath(cell)) continue;
        if (pathLetters.contains(puzzle.letterAt(cell))) {
          result.add(cell);
        }
      }
    }
    return result;
  }

  /// Whether [c] is currently part of [chainA] (including its anchor).
  bool isOnChainA(Cell c) => _chainA.contains(c);

  /// Whether [c] is currently part of [chainZ] (including its anchor).
  bool isOnChainZ(Cell c) => _chainZ.contains(c);

  /// Whether [c] is on either chain.
  bool isOnPath(Cell c) => isOnChainA(c) || isOnChainZ(c);

  /// The current path cells in order: [chainA] followed by [chainZ]
  /// reversed. See [LabyrinthStatus.pathCells].
  List<Cell> get pathCells => [..._chainA, ..._chainZ.reversed];

  /// Applies one tap at [c] to the board's state machine:
  ///
  ///  1. Tapping the current [headA] or [headZ] retracts that chain by
  ///     one cell - this is checked first and applies even when the path
  ///     is [isJoined] (a join only blocks *extension*, not retraction).
  ///     The anchor is never removed: [chainA] can never shrink below
  ///     `[Cell(0,0)]`, [chainZ] below `[Cell(7,7)]`, so tapping an
  ///     anchor whose chain has length 1 is a no-op.
  ///  2. Otherwise, if [isJoined], extension is impossible (join is
  ///     terminal) and the tap is a no-op.
  ///  3. Otherwise, if [c] is in bounds and on neither chain: it is
  ///     appended to [chainA] when orthogonally adjacent to [headA], else
  ///     to [chainZ] when orthogonally adjacent to [headZ]. If [c] is
  ///     adjacent to *both* heads, [chainA] wins the tie-break. Appending
  ///     also clears any manual cross or mark on [c] (the player has just
  ///     settled - or contradicted - their own annotation; retracting
  ///     afterwards does not restore it). Neither chain may exceed
  ///     [LabyrinthPuzzle.pathLength] cells, and the two together may
  ///     never exceed it either.
  ///  4. Otherwise: toggles [c] in [marks], same as [toggleMark] (this
  ///     covers a cell that is in bounds, off both chains, but not
  ///     adjacent to either head - or the chains are already at
  ///     [LabyrinthPuzzle.pathLength]).
  void tap(Cell c) {
    if (c == headA) {
      if (_chainA.length > 1) {
        _chainA.removeLast();
      }
      return;
    }
    if (c == headZ) {
      if (_chainZ.length > 1) {
        _chainZ.removeLast();
      }
      return;
    }

    if (isJoined) {
      return;
    }
    if (!_inBounds(c) || isOnPath(c)) {
      return;
    }
    final canExtend = _chainA.length + _chainZ.length < LabyrinthPuzzle.pathLength;

    if (canExtend && _manhattan(c, headA) == 1) {
      _chainA.add(c);
      _manualCrosses.remove(c);
      _marks.remove(c);
    } else if (canExtend && _manhattan(c, headZ) == 1) {
      _chainZ.add(c);
      _manualCrosses.remove(c);
      _marks.remove(c);
    } else {
      if (!_marks.remove(c)) {
        _marks.add(c);
        _manualCrosses.remove(c);
      }
    }
  }

  /// Toggles [c] in [marks], the player's "must be on path" annotation:
  ///
  ///  * If [c] is on either chain (including an anchor): no-op. A path
  ///    cell needs no assertion that it is on the path, and anchors are
  ///    never annotatable - this mirrors how [longPress] treats anchors.
  ///  * If [c] is out of bounds: no-op.
  ///  * Otherwise: toggles [c] in [marks]. Adding a mark also clears any
  ///    manual cross on [c] - a cell cannot simultaneously assert "not on
  ///    path" and "must be on path".
  void toggleMark(Cell c) {
    if (isOnPath(c) || !_inBounds(c)) {
      return;
    }
    if (!_marks.remove(c)) {
      _marks.add(c);
      _manualCrosses.remove(c);
    }
  }

  /// Applies one long-press at [c]:
  ///
  ///  * If [c] is on [chainA] at index `i > 0`: truncates [chainA] to
  ///    length `i`, retracting that chain back to just before [c]. Same
  ///    for [chainZ]. The anchor (index 0) is never removed this way and
  ///    is never a legal place for a manual cross.
  ///  * If [c] is an anchor (index 0 on either chain): no-op.
  ///  * Otherwise: toggles [c] in [manualCrosses]. Adding a cross also
  ///    clears any mark on [c] - a cell cannot simultaneously assert
  ///    "not on path" and "must be on path".
  void longPress(Cell c) {
    final ia = _chainA.indexOf(c);
    if (ia > 0) {
      _chainA.removeRange(ia, _chainA.length);
      return;
    }
    if (ia == 0) {
      // c is an anchor on chainA; no-op
      return;
    }
    final iz = _chainZ.indexOf(c);
    if (iz > 0) {
      _chainZ.removeRange(iz, _chainZ.length);
      return;
    }
    if (iz == 0) {
      // c is an anchor on chainZ; no-op
      return;
    }
    if (!_manualCrosses.remove(c)) {
      _manualCrosses.add(c);
      _marks.remove(c);
    }
  }

  /// Resets the board to the initial two-anchor state, clearing manual
  /// crosses and marks.
  void reset() {
    _chainA
      ..clear()
      ..add(const Cell(0, 0));
    _chainZ
      ..clear()
      ..add(const Cell(7, 7));
    _manualCrosses.clear();
    _marks.clear();
  }

  /// Computes the current [LabyrinthStatus] for this board.
  LabyrinthStatus status() {
    final cells = pathCells;
    final letters = cells.map(puzzle.letterAt).toList(growable: false);

    final used = <String>{};
    final duplicates = <String>{};
    for (final l in letters) {
      if (!used.add(l)) {
        duplicates.add(l);
      }
    }
    final missing = russianAlphabet.toSet().difference(used);
    final joined = isJoined;

    return LabyrinthStatus(
      pathCells: cells,
      isJoined: joined,
      placedCount: cells.length,
      usedLetters: used,
      duplicateLetters: duplicates,
      missingLetters: missing,
      isSolved: joined &&
          cells.length == LabyrinthPuzzle.pathLength &&
          duplicates.isEmpty &&
          missing.isEmpty,
    );
  }

  /// Serializes this board's persistent state: `chainA`, `chainZ`,
  /// `crosses` and `marks`, each a list of `[row, col]` pairs. [isJoined]
  /// and [autoCrosses] are deliberately NOT included - both are derived
  /// from `chainA`/`chainZ` and are recomputed by [fromJson] (and every
  /// other accessor) rather than persisted.
  Map<String, dynamic> toJson() => {
        'chainA': [for (final c in _chainA) [c.row, c.col]],
        'chainZ': [for (final c in _chainZ) [c.row, c.col]],
        'crosses': [for (final c in _manualCrosses) [c.row, c.col]],
        'marks': [for (final c in _marks) [c.row, c.col]],
      };

  /// Restores a board for [puzzle] from previously-persisted [json] (as
  /// produced by [toJson]).
  ///
  /// TOLERANT of stale or corrupt saves: [json] is validated as a whole,
  /// and on any structural problem - wrong anchors, non-adjacent
  /// consecutive cells within a chain, out-of-bounds cells, a cell
  /// shared by both chains, or a combined length over
  /// [LabyrinthPuzzle.pathLength] - the bad data is dropped in its
  /// entirety and this falls back to the same fresh state as
  /// [LabyrinthBoard.fromPuzzle], rather than throwing or restoring a
  /// partially-broken board. A bad save must never brick a puzzle.
  ///
  /// `marks` is OPTIONAL: it did not exist before marks were introduced,
  /// so a missing or `null` value yields an empty set rather than failing
  /// the whole payload (a save written before this feature must still
  /// load). A *present but malformed* `marks` value still fails the whole
  /// payload, same as every other field.
  factory LabyrinthBoard.fromJson(
    LabyrinthPuzzle puzzle,
    Map<String, dynamic> json,
  ) {
    final parsed = _tryParse(puzzle, json);
    return parsed ?? LabyrinthBoard.fromPuzzle(puzzle);
  }

  static LabyrinthBoard? _tryParse(
    LabyrinthPuzzle puzzle,
    Map<String, dynamic> json,
  ) {
    final chainA = _parseCells(json['chainA']);
    final chainZ = _parseCells(json['chainZ']);
    final crosses = _parseCells(json['crosses']);
    if (chainA == null || chainZ == null || crosses == null) {
      return null;
    }
    final rawMarks = json['marks'];
    final marks = rawMarks == null ? <Cell>[] : _parseCells(rawMarks);
    if (marks == null) {
      return null; // present but malformed
    }

    if (chainA.isEmpty || chainA.first != const Cell(0, 0)) {
      return null;
    }
    if (chainZ.isEmpty || chainZ.first != const Cell(7, 7)) {
      return null;
    }
    if (!_isValidChain(chainA) || !_isValidChain(chainZ)) {
      return null;
    }
    if (chainA.length + chainZ.length > LabyrinthPuzzle.pathLength) {
      return null;
    }
    if (<Cell>{...chainA, ...chainZ}.length != chainA.length + chainZ.length) {
      return null; // a cell is shared between the two chains.
    }
    for (final c in crosses) {
      if (!_inBounds(c)) {
        return null;
      }
    }
    for (final c in marks) {
      if (!_inBounds(c)) {
        return null;
      }
    }

    return LabyrinthBoard._(
      puzzle,
      chainA,
      chainZ,
      crosses.toSet(),
      marks.toSet(),
    );
  }

  /// Whether [chain] is in bounds, self-avoiding, and orthogonally
  /// connected step-to-step.
  static bool _isValidChain(List<Cell> chain) {
    for (final c in chain) {
      if (!_inBounds(c)) return false;
    }
    for (var i = 1; i < chain.length; i++) {
      if (_manhattan(chain[i - 1], chain[i]) != 1) return false;
    }
    return chain.toSet().length == chain.length;
  }

  /// Parses a `[[r,c], ...]` JSON value into cells, or `null` if it is
  /// not a list of well-formed `[row, col]` integer pairs.
  static List<Cell>? _parseCells(dynamic json) {
    if (json is! List) return null;
    final cells = <Cell>[];
    for (final entry in json) {
      if (entry is! List || entry.length != 2) return null;
      final r = entry[0];
      final c = entry[1];
      if (r is! int || c is! int) return null;
      cells.add(Cell(r, c));
    }
    return cells;
  }
}
