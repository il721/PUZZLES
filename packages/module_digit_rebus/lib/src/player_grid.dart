import 'dart:convert';

import 'model.dart';
import 'verifier.dart';

/// Mutable player-facing state for one [DigitRebusPuzzle]: the 16 digit
/// cells of the 4x4 grid. There are no givens — every cell starts empty
/// and is player-editable.
///
/// The win condition implemented by [wins] is constraint satisfaction, not
/// canonical-match: any complete grid where every cell is in its glyph's
/// digit set and all 8 equations hold wins, even if it differs from the
/// puzzle's printed answer.
///
/// [setDigit] validates only the digit range (0-9); glyph-set membership
/// is enforced by the verifier ([violations]), not by input paths, so a
/// digit restored from a stale save or placed by any future input path is
/// still flagged.
class PlayerGrid {
  /// The puzzle this grid plays.
  final DigitRebusPuzzle puzzle;

  /// `_cells[row][col]` — current digit, `null` if empty.
  final List<List<int?>> _cells;

  PlayerGrid._(this.puzzle, this._cells);

  /// Builds a fresh, fully-empty grid for [puzzle].
  factory PlayerGrid.fromPuzzle(DigitRebusPuzzle puzzle) => PlayerGrid._(
        puzzle,
        List.generate(4, (_) => List<int?>.filled(4, null)),
      );

  /// Restores a grid for [puzzle] from a previously-persisted [json] (as
  /// produced by [toJson]): a `"row:col" -> digit` map. Malformed or stale
  /// keys and out-of-range values are ignored rather than throwing, so old
  /// saves survive puzzle-data revisions.
  factory PlayerGrid.fromJson(DigitRebusPuzzle puzzle, Map<String, dynamic> json) {
    final grid = PlayerGrid.fromPuzzle(puzzle);
    json.forEach((key, value) {
      final ref = CellRef.tryParse(key);
      if (ref == null || !_inRange(ref)) return;
      if (value is int && value >= 0 && value <= 9) {
        grid._cells[ref.row][ref.col] = value;
      }
    });
    return grid;
  }

  static bool _inRange(CellRef ref) =>
      ref.row >= 0 && ref.row < 4 && ref.col >= 0 && ref.col < 4;

  void _checkRef(CellRef ref) {
    if (!_inRange(ref)) {
      throw ArgumentError('No such cell: $ref');
    }
  }

  /// The digit currently in [ref], or `null` if empty. Throws
  /// [ArgumentError] if [ref] does not address a cell in this grid.
  int? digitAt(CellRef ref) {
    _checkRef(ref);
    return _cells[ref.row][ref.col];
  }

  /// Sets [ref] to [digit] (0-9).
  void setDigit(CellRef ref, int digit) {
    if (digit < 0 || digit > 9) {
      throw ArgumentError.value(digit, 'digit', 'Must be 0-9');
    }
    _checkRef(ref);
    _cells[ref.row][ref.col] = digit;
  }

  /// Clears [ref]. A no-op if already empty.
  void clearDigit(CellRef ref) {
    _checkRef(ref);
    _cells[ref.row][ref.col] = null;
  }

  /// Whether every cell in the grid holds a digit.
  bool get isComplete =>
      _cells.every((row) => row.every((d) => d != null));

  /// Every cell, in reading order (row-major). All 16 cells are editable —
  /// this module has no givens.
  List<CellRef> get orderedEditableCells => [
        for (var r = 0; r < 4; r++)
          for (var c = 0; c < 4; c++) CellRef(r, c),
      ];

  /// Computes every rule violation detectable from the cells currently
  /// filled in. See [verifyGrid] for the exact scope rules (partial rows
  /// and columns produce no equation violation; glyph-set membership is
  /// checked per filled cell).
  GridViolations violations() => verifyGrid(puzzle, _cells);

  /// Whether this grid is complete and satisfies every rule — the win
  /// condition. Constraint satisfaction, not canonical-match.
  bool get wins => isComplete && violations().isEmpty;

  /// Serializes the cells currently filled in, as a `"row:col" -> digit`
  /// map suitable for persistence.
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        final d = _cells[r][c];
        if (d != null) result['$r:$c'] = d;
      }
    }
    return result;
  }

  /// Convenience for encoding [toJson] directly to a JSON string.
  String toJsonString() => jsonEncode(toJson());
}
