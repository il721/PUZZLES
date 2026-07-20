import 'dart:convert';

import 'model.dart';
import 'validator.dart';

/// Mutable player-facing state for one [DominoPuzzle]: which of its 56
/// cells are currently covered by a placed domino, plus a transient
/// "pending" single-cell selection mid-placement.
///
/// The win condition implemented by [wins] is constraint satisfaction, not
/// canonical-match: any full 28-domino tiling of the grid whose
/// value-pairs are exactly the double-six set wins, even if it differs
/// from the puzzle's stored `solution` geometry.
///
/// Overlaps are impossible by construction: [tap] only ever binds a
/// pending selection with another currently-*uncovered* cell (see [tap]'s
/// state machine below), so [_placed] never contains two dominoes sharing
/// a cell.
class PlayerBoard {
  /// The puzzle this board plays.
  final DominoPuzzle puzzle;

  /// Dominoes placed so far. Never contains two dominoes sharing a cell
  /// (see class doc).
  final List<Domino> _placed;

  /// The single cell mid-selection (tapped once, awaiting a second tap to
  /// bind, deselect, or move), or `null` if none.
  Cell? _pending;

  PlayerBoard._(this.puzzle, this._placed, this._pending);

  /// Builds a fresh, fully-empty board for [puzzle]: no dominoes placed,
  /// no pending selection.
  factory PlayerBoard.fromPuzzle(DominoPuzzle puzzle) =>
      PlayerBoard._(puzzle, <Domino>[], null);

  /// Restores a board for [puzzle] from previously-persisted [placedJson]
  /// (as produced by [toJson]): a list of `[[r1,c1],[r2,c2]]` entries.
  /// Tolerant of stale/malformed data (mirrors `PlayerGrid.fromJson`):
  /// entries that are malformed, out of range (row 0..7, col 0..6),
  /// non-adjacent, or would overlap a cell already covered by an earlier
  /// restored domino are silently skipped rather than throwing. No
  /// pending selection is restored.
  factory PlayerBoard.fromJson(
    DominoPuzzle puzzle,
    List<dynamic> placedJson,
  ) {
    final board = PlayerBoard.fromPuzzle(puzzle);
    for (final entry in placedJson) {
      final domino = _tryParseDomino(entry);
      if (domino == null) continue;
      if (board.isCovered(domino.a) || board.isCovered(domino.b)) continue;
      board._placed.add(domino);
    }
    return board;
  }

  /// Parses one `[[r1,c1],[r2,c2]]` entry into a [Domino], or `null` if
  /// it is malformed, out of range, or its two cells are not orthogonally
  /// adjacent.
  static Domino? _tryParseDomino(dynamic entry) {
    if (entry is! List || entry.length != 2) return null;
    final c1 = entry[0];
    final c2 = entry[1];
    if (c1 is! List || c1.length != 2) return null;
    if (c2 is! List || c2.length != 2) return null;
    final r1 = c1[0];
    final col1 = c1[1];
    final r2 = c2[0];
    final col2 = c2[1];
    if (r1 is! int || col1 is! int || r2 is! int || col2 is! int) {
      return null;
    }
    final a = Cell(r1, col1);
    final b = Cell(r2, col2);
    if (!_inRange(a) || !_inRange(b)) return null;
    if (!_adjacent(a, b)) return null;
    return Domino(a, b);
  }

  static bool _inRange(Cell c) =>
      c.row >= 0 && c.row < 8 && c.col >= 0 && c.col < 7;

  static bool _adjacent(Cell a, Cell b) =>
      (a.row - b.row).abs() + (a.col - b.col).abs() == 1;

  void _checkRange(Cell c) {
    if (!_inRange(c)) {
      throw ArgumentError.value(c, 'c', 'No such cell');
    }
  }

  /// Every placed domino, as an unmodifiable view.
  List<Domino> get placed => List.unmodifiable(_placed);

  /// The single cell mid-selection, or `null` if none.
  Cell? get pending => _pending;

  /// The placed domino covering [cell], or `null` if [cell] is
  /// uncovered.
  Domino? dominoAt(Cell cell) {
    for (final d in _placed) {
      if (d.a == cell || d.b == cell) return d;
    }
    return null;
  }

  /// Whether [cell] is covered by a placed domino.
  bool isCovered(Cell cell) => dominoAt(cell) != null;

  /// Applies one tap at [cell] to the board's state machine. Throws
  /// [ArgumentError] if [cell] is out of range (row 0..7, col 0..6).
  ///
  ///  1. If [cell] is covered by a placed domino, that domino is removed
  ///     (split) and any pending selection is cleared — this takes
  ///     priority even if a pending selection exists.
  ///  2. Otherwise ([cell] is uncovered):
  ///     * no pending selection -> [cell] becomes pending.
  ///     * pending selection is [cell] itself -> pending is cleared
  ///       (deselect).
  ///     * pending selection is orthogonally adjacent to [cell] -> a new
  ///       domino binding them is placed and pending is cleared.
  ///     * otherwise -> pending moves to [cell] (reselect).
  void tap(Cell cell) {
    _checkRange(cell);

    final covering = dominoAt(cell);
    if (covering != null) {
      _placed.remove(covering);
      _pending = null;
      return;
    }

    final p = _pending;
    if (p == null) {
      _pending = cell;
    } else if (p == cell) {
      _pending = null;
    } else if (_adjacent(p, cell)) {
      _placed.add(Domino(p, cell));
      _pending = null;
    } else {
      _pending = cell;
    }
  }

  /// Clears all placed dominoes and any pending selection.
  void reset() {
    _placed.clear();
    _pending = null;
  }

  /// The current [BoardStatus] for this board's placed dominoes.
  BoardStatus status() => verifyBoard(puzzle, _placed);

  /// Whether this board is currently in the win state. See
  /// [BoardStatus.isSolved].
  bool get wins => status().isSolved;

  /// Serializes the placed dominoes as `[[[r,c],[r,c]], ...]`, suitable
  /// for persistence and for [PlayerBoard.fromJson]. Cell order within a
  /// domino is not significant.
  List<List<List<int>>> toJson() => [
        for (final d in _placed)
          [
            [d.a.row, d.a.col],
            [d.b.row, d.b.col],
          ],
      ];

  /// Convenience for encoding [toJson] directly to a JSON string.
  String toJsonString() => jsonEncode(toJson());
}
