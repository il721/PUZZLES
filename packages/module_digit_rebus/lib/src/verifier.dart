import 'evaluator.dart';
import 'model.dart';

/// Addresses one cell of the 4x4 grid: [row] and [col] are both 0..3.
///
/// [key] is a stable string form (`"row:col"`) suitable for use as a JSON
/// object key or map key.
class CellRef {
  /// Row index, 0..3.
  final int row;

  /// Column index, 0..3.
  final int col;

  /// Creates a cell reference.
  const CellRef(this.row, this.col);

  /// Stable string form of this reference, `"row:col"`.
  String get key => '$row:$col';

  /// Parses a [CellRef] from its [key] form. Returns `null` if [key] is
  /// not a well-formed `"row:col"` pair.
  static CellRef? tryParse(String key) {
    final parts = key.split(':');
    if (parts.length != 2) return null;
    final row = int.tryParse(parts[0]);
    final col = int.tryParse(parts[1]);
    if (row == null || col == null) return null;
    return CellRef(row, col);
  }

  @override
  bool operator ==(Object other) =>
      other is CellRef && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'CellRef($key)';
}

/// The kind of rule a [GridViolation] reports as broken.
enum ViolationType {
  /// A row's four cells, all filled, do not satisfy its left-to-right
  /// equation (including any evaluation to null: negative intermediate,
  /// zero divisor, or inexact division).
  rowEquation,

  /// A column's four cells, all filled, do not satisfy its top-to-bottom
  /// equation (including any evaluation to null).
  columnEquation,

  /// A filled cell holds a digit outside its glyph's digit set. Reported
  /// per cell as soon as the cell is filled, regardless of how the digit
  /// got there (input UI, save-restore, replay).
  glyphSet,
}

/// A single detected rule violation, together with enough context to
/// highlight it in the UI.
class GridViolation {
  /// The kind of violation.
  final ViolationType type;

  /// The row index (0..3) this violation concerns, if applicable (set for
  /// [ViolationType.rowEquation] and [ViolationType.glyphSet]).
  final int? row;

  /// The column index (0..3) this violation concerns, if applicable (set
  /// for [ViolationType.columnEquation] and [ViolationType.glyphSet]).
  final int? column;

  /// Every cell that participates in this violation, for highlighting.
  final List<CellRef> cells;

  /// Creates a violation.
  const GridViolation({
    required this.type,
    this.row,
    this.column,
    required this.cells,
  });
}

/// The full set of violations found by [verifyGrid].
class GridViolations {
  /// Every violation found, in no particular order.
  final List<GridViolation> items;

  /// Creates a violation set.
  const GridViolations(this.items);

  /// Whether no violations were found.
  bool get isEmpty => items.isEmpty;

  /// Whether at least one violation was found.
  bool get isNotEmpty => items.isNotEmpty;

  /// Whether [ref] participates in any reported violation.
  bool involves(CellRef ref) => items.any((v) => v.cells.contains(ref));
}

/// Computes every rule violation detectable from the cells currently
/// filled in `cells[row][col]` (`null` meaning empty) for [puzzle].
///
/// Checks performed:
///  * [ViolationType.glyphSet]: any filled cell whose digit is outside its
///    glyph's digit set — reported per cell, without waiting for the rest
///    of its row or column. `0` is fully legal wherever the glyph permits
///    it (there is no zero/leading-zero rule in this module).
///  * [ViolationType.rowEquation] / [ViolationType.columnEquation]: an
///    equation is checked only once every one of its four cells is filled
///    — a half-entered row or column is never reported as a violation. A
///    line whose evaluation is null (negative intermediate, zero divisor,
///    inexact division) is a violation, never a crash or a false pass.
GridViolations verifyGrid(DigitRebusPuzzle puzzle, List<List<int?>> cells) {
  final items = <GridViolation>[];

  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 4; c++) {
      final d = cells[r][c];
      if (d == null) continue;
      if (!puzzle.glyphs[r][c].digits.contains(d)) {
        items.add(GridViolation(
          type: ViolationType.glyphSet,
          row: r,
          column: c,
          cells: [CellRef(r, c)],
        ));
      }
    }
  }

  for (var r = 0; r < 4; r++) {
    final line = [for (var c = 0; c < 4; c++) cells[r][c]];
    if (line.any((d) => d == null)) continue;
    if (!lineHolds(line.cast<int>(), puzzle.rowOps[r])) {
      items.add(GridViolation(
        type: ViolationType.rowEquation,
        row: r,
        cells: [for (var c = 0; c < 4; c++) CellRef(r, c)],
      ));
    }
  }

  for (var c = 0; c < 4; c++) {
    final line = [for (var r = 0; r < 4; r++) cells[r][c]];
    if (line.any((d) => d == null)) continue;
    if (!lineHolds(line.cast<int>(), puzzle.colOps[c])) {
      items.add(GridViolation(
        type: ViolationType.columnEquation,
        column: c,
        cells: [for (var r = 0; r < 4; r++) CellRef(r, c)],
      ));
    }
  }

  return GridViolations(items);
}
