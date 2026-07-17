import 'dart:convert';

import 'evaluator.dart';
import 'model.dart';

/// Addresses a single digit box in a [PlayerGrid].
///
/// [row] 0..3 identify one of the four arithmetic rows; [row] 4 identifies
/// the summary row. For an arithmetic row, [slot] 0..3 select an operand
/// box and [slot] 4 selects the row's result box. For the summary row,
/// [slot] 0..3 select a column-sum box and [slot] 4 selects the grand-total
/// box. [pos] indexes the target number's decimal string, 0 being the most
/// significant digit.
///
/// [key] is a stable string form (`"row:slot:pos"`) suitable for use as a
/// JSON object key or map key.
class CellRef {
  /// 0..3 selects an arithmetic row; 4 selects the summary row.
  final int row;

  /// 0..3 selects an operand (or, on the summary row, a column-sum box);
  /// 4 selects the result (or, on the summary row, the grand total).
  final int slot;

  /// Zero-based index into the target number's decimal string.
  final int pos;

  /// Creates a cell reference.
  const CellRef(this.row, this.slot, this.pos);

  /// Stable string form of this reference, `"row:slot:pos"`.
  String get key => '$row:$slot:$pos';

  /// Parses a [CellRef] from its [key] form. Returns `null` if [key] is not
  /// a well-formed `"row:slot:pos"` triple.
  static CellRef? tryParse(String key) {
    final parts = key.split(':');
    if (parts.length != 3) return null;
    final row = int.tryParse(parts[0]);
    final slot = int.tryParse(parts[1]);
    final pos = int.tryParse(parts[2]);
    if (row == null || slot == null || pos == null) return null;
    return CellRef(row, slot, pos);
  }

  @override
  bool operator ==(Object other) =>
      other is CellRef && other.row == row && other.slot == slot && other.pos == pos;

  @override
  int get hashCode => Object.hash(row, slot, pos);

  @override
  String toString() => 'CellRef($key)';
}

/// The kind of rule a [GridViolation] reports as broken.
enum ViolationType {
  /// A row's five numbers, all filled, do not satisfy its left-to-right
  /// equation.
  rowEquation,

  /// A column's four operands, plus that row's result, are all filled, and
  /// their sum does not equal the result.
  columnSum,

  /// A summary-row column-sum box and the corresponding row's result are
  /// both filled, but disagree.
  summaryMismatch,

  /// The summary row's four column-sum boxes and the grand-total box are
  /// all filled, but the boxes do not sum to the total.
  totalMismatch,

  /// A fully-filled number is `0`, or has a leading zero.
  badNumber,
}

/// A single detected rule violation, together with enough context to
/// highlight it in the UI.
class GridViolation {
  /// The kind of violation.
  final ViolationType type;

  /// The arithmetic-row index (0..3) this violation concerns, if
  /// applicable (set for [ViolationType.rowEquation] and, for a single
  /// number, [ViolationType.badNumber] on an operand/result cell).
  final int? row;

  /// The column index (0..3) this violation concerns, if applicable (set
  /// for [ViolationType.columnSum] and [ViolationType.summaryMismatch]).
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

/// The full set of violations found by [PlayerGrid.violations].
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

/// Mutable player-facing state for one [RebusPuzzle]: every digit box in
/// the grid (the four arithmetic rows plus the summary row), tracking
/// which cells are immutable givens and which are player-editable.
///
/// Box widths are derived from the puzzle's canonical solution strings
/// (`RebusRow.nums`/`result`, `RebusPuzzle.total`) — the player always sees
/// the correct number of boxes even though only [RebusPuzzle.givens] start
/// pre-filled.
///
/// The win condition implemented by [wins] is constraint satisfaction, not
/// canonical-match: any complete grid that satisfies every printed
/// constraint (row equations, column sums, summary boxes, the grand total,
/// and the no-zero/no-leading-zero number rule) wins, even if it differs
/// from the puzzle's canonical solution.
class PlayerGrid {
  /// The puzzle this grid plays.
  final RebusPuzzle puzzle;

  /// `"row:slot"` -> box width (number of digit positions) for every
  /// number in the grid.
  final Map<String, int> _widths;

  /// `"row:slot:pos"` -> current digit (`null` if empty).
  final Map<String, int?> _digits;

  /// `"row:slot:pos"` keys that are immutable givens.
  final Set<String> _givenKeys;

  PlayerGrid._(this.puzzle, this._widths, this._digits, this._givenKeys);

  /// Builds a fresh grid for [puzzle]: every cell enumerated from the
  /// puzzle's canonical strings, with only the cells listed in
  /// [RebusPuzzle.givens] pre-filled (and locked).
  factory PlayerGrid.fromPuzzle(RebusPuzzle puzzle) {
    final widths = <String, int>{};
    final digits = <String, int?>{};
    final givenKeys = <String>{};

    void declareNumber(int row, int slot, int width) {
      widths['$row:$slot'] = width;
      for (var pos = 0; pos < width; pos++) {
        digits['$row:$slot:$pos'] = null;
      }
    }

    for (var r = 0; r < 4; r++) {
      final row = puzzle.rows[r];
      for (var slot = 0; slot < 4; slot++) {
        declareNumber(r, slot, row.nums[slot].length);
      }
      declareNumber(r, 4, row.result.length);
    }
    for (var j = 0; j < 4; j++) {
      declareNumber(4, j, puzzle.rows[j].result.length);
    }
    declareNumber(4, 4, puzzle.total.length);

    for (final g in puzzle.givens) {
      final key = '${g.row}:${g.slot}:${g.pos}';
      digits[key] = g.digit;
      givenKeys.add(key);
    }

    return PlayerGrid._(puzzle, widths, digits, givenKeys);
  }

  /// Restores a grid for [puzzle] from a previously-persisted [json] (as
  /// produced by [toJson]). Only editable (non-given) cells are ever
  /// restored from [json]; unknown/stale keys (referring to cells that
  /// don't exist in this puzzle, or to given cells) are ignored rather
  /// than throwing, so old saves survive puzzle-data revisions.
  factory PlayerGrid.fromJson(RebusPuzzle puzzle, Map<String, dynamic> json) {
    final grid = PlayerGrid.fromPuzzle(puzzle);
    json.forEach((key, value) {
      if (grid._givenKeys.contains(key)) return;
      if (!grid._digits.containsKey(key)) return;
      if (value is int && value >= 0 && value <= 9) {
        grid._digits[key] = value;
      }
    });
    return grid;
  }

  /// The digit-box width of the number at `(row, slot)`.
  int widthOf(int row, int slot) {
    final width = _widths['$row:$slot'];
    if (width == null) {
      throw ArgumentError('No such number at row=$row slot=$slot');
    }
    return width;
  }

  /// Every [CellRef] belonging to the number at `(row, slot)`, in
  /// most-significant-first order.
  List<CellRef> cellsOf(int row, int slot) {
    final width = widthOf(row, slot);
    return List.generate(width, (pos) => CellRef(row, slot, pos), growable: false);
  }

  /// The digit currently in [ref], or `null` if empty. Throws
  /// [ArgumentError] if [ref] does not address a cell in this grid.
  int? digitAt(CellRef ref) {
    if (!_digits.containsKey(ref.key)) {
      throw ArgumentError('No such cell: $ref');
    }
    return _digits[ref.key];
  }

  /// Whether [ref] is an immutable given.
  bool isGiven(CellRef ref) => _givenKeys.contains(ref.key);

  /// Sets [ref] to [digit] (0-9). A no-op if [ref] is a given.
  void setDigit(CellRef ref, int digit) {
    if (digit < 0 || digit > 9) {
      throw ArgumentError.value(digit, 'digit', 'Must be 0-9');
    }
    if (!_digits.containsKey(ref.key)) {
      throw ArgumentError('No such cell: $ref');
    }
    if (isGiven(ref)) return;
    _digits[ref.key] = digit;
  }

  /// Clears [ref]. A no-op if [ref] is a given or already empty.
  void clearDigit(CellRef ref) {
    if (!_digits.containsKey(ref.key)) {
      throw ArgumentError('No such cell: $ref');
    }
    if (isGiven(ref)) return;
    _digits[ref.key] = null;
  }

  /// Whether every cell in the grid holds a digit.
  bool get isComplete => _digits.values.every((d) => d != null);

  /// Every editable (non-given) cell, in reading order: row 0 through row
  /// 4 (the summary row last), and within a row, slot 0 through slot 4
  /// (operands/column-sum boxes before the result/total), and within a
  /// number, its digit positions most-significant-first.
  List<CellRef> get orderedEditableCells {
    final result = <CellRef>[];
    for (var row = 0; row <= 4; row++) {
      for (var slot = 0; slot <= 4; slot++) {
        final width = _widths['$row:$slot'];
        if (width == null) continue;
        for (var pos = 0; pos < width; pos++) {
          final key = '$row:$slot:$pos';
          if (_givenKeys.contains(key)) continue;
          result.add(CellRef(row, slot, pos));
        }
      }
    }
    return result;
  }

  /// The decimal string at `(row, slot)` if every one of its digit
  /// positions is filled, else `null`.
  String? _numberIfFilled(int row, int slot) {
    final width = _widths['$row:$slot']!;
    final buffer = StringBuffer();
    for (var pos = 0; pos < width; pos++) {
      final d = _digits['$row:$slot:$pos'];
      if (d == null) return null;
      buffer.write(d);
    }
    return buffer.toString();
  }

  /// Computes every rule violation detectable from the cells currently
  /// filled in.
  ///
  /// Each check only fires once every cell in its scope is filled — a
  /// half-entered row or column is never reported as a violation. Checks
  /// performed:
  ///  * [ViolationType.rowEquation]: for each arithmetic row whose five
  ///    numbers (four operands + result) are all filled, its left-to-right
  ///    evaluation must equal its result.
  ///  * [ViolationType.columnSum]: for each column whose four operands
  ///    (one per row) and the corresponding row's result are all filled,
  ///    the operands must sum to that result.
  ///  * [ViolationType.summaryMismatch]: for each column whose summary-row
  ///    column-sum box and corresponding row result are both filled, they
  ///    must agree.
  ///  * [ViolationType.totalMismatch]: once the summary row's four
  ///    column-sum boxes and grand-total box are all filled, the boxes
  ///    must sum to the total.
  ///  * [ViolationType.badNumber]: any fully-filled number (anywhere in
  ///    the grid) that is zero, or has a leading zero.
  GridViolations violations() {
    final items = <GridViolation>[];

    for (final widthKey in _widths.keys) {
      final parts = widthKey.split(':');
      final row = int.parse(parts[0]);
      final slot = int.parse(parts[1]);
      final s = _numberIfFilled(row, slot);
      if (s == null) continue;
      final isZero = int.parse(s) == 0;
      final hasLeadingZero = s.length > 1 && s.startsWith('0');
      if (isZero || hasLeadingZero) {
        items.add(GridViolation(
          type: ViolationType.badNumber,
          row: row,
          column: slot,
          cells: cellsOf(row, slot),
        ));
      }
    }

    for (var r = 0; r < 4; r++) {
      final cells = <CellRef>[];
      final nums = <int>[];
      var allFilled = true;
      for (var slot = 0; slot < 4; slot++) {
        final s = _numberIfFilled(r, slot);
        if (s == null) {
          allFilled = false;
          break;
        }
        nums.add(int.parse(s));
        cells.addAll(cellsOf(r, slot));
      }
      String? resultStr;
      if (allFilled) {
        resultStr = _numberIfFilled(r, 4);
        if (resultStr == null) allFilled = false;
      }
      if (!allFilled) continue;
      cells.addAll(cellsOf(r, 4));
      final result = int.parse(resultStr!);
      final evaluated = evalLeftToRight(nums, puzzle.rows[r].ops);
      if (evaluated != result) {
        items.add(GridViolation(type: ViolationType.rowEquation, row: r, cells: cells));
      }
    }

    for (var j = 0; j < 4; j++) {
      final cells = <CellRef>[];
      var allFilled = true;
      var sum = 0;
      for (var r = 0; r < 4; r++) {
        final s = _numberIfFilled(r, j);
        if (s == null) {
          allFilled = false;
          break;
        }
        sum += int.parse(s);
        cells.addAll(cellsOf(r, j));
      }
      String? targetStr;
      if (allFilled) {
        targetStr = _numberIfFilled(j, 4);
        if (targetStr == null) allFilled = false;
      }
      if (!allFilled) continue;
      cells.addAll(cellsOf(j, 4));
      final target = int.parse(targetStr!);
      if (sum != target) {
        items.add(GridViolation(type: ViolationType.columnSum, column: j, cells: cells));
      }
    }

    for (var j = 0; j < 4; j++) {
      final summaryStr = _numberIfFilled(4, j);
      final resultStr = _numberIfFilled(j, 4);
      if (summaryStr == null || resultStr == null) continue;
      if (summaryStr != resultStr) {
        items.add(GridViolation(
          type: ViolationType.summaryMismatch,
          column: j,
          cells: [...cellsOf(4, j), ...cellsOf(j, 4)],
        ));
      }
    }

    final boxes = List.generate(4, (j) => _numberIfFilled(4, j));
    final totalStr = _numberIfFilled(4, 4);
    if (boxes.every((s) => s != null) && totalStr != null) {
      final sum = boxes.fold<int>(0, (acc, s) => acc + int.parse(s!));
      final total = int.parse(totalStr);
      if (sum != total) {
        items.add(GridViolation(
          type: ViolationType.totalMismatch,
          cells: [
            for (var j = 0; j < 4; j++) ...cellsOf(4, j),
            ...cellsOf(4, 4),
          ],
        ));
      }
    }

    return GridViolations(items);
  }

  /// Whether this grid is complete and satisfies every rule — the win
  /// condition. This is constraint satisfaction, not canonical-match: an
  /// alternate valid grid (differing from [puzzle]'s canonical solution)
  /// also wins.
  bool get wins => isComplete && violations().isEmpty;

  /// Serializes the editable (non-given) cells currently filled in, as a
  /// `"row:slot:pos" -> digit` map suitable for persistence.
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};
    for (final entry in _digits.entries) {
      if (_givenKeys.contains(entry.key)) continue;
      if (entry.value != null) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  /// Convenience for encoding [toJson] directly to a JSON string.
  String toJsonString() => jsonEncode(toJson());
}
