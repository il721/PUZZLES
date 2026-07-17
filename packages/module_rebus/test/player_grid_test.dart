import 'dart:convert';
import 'dart:io';

import 'package:module_rebus/module_rebus.dart';
import 'package:test/test.dart';

List<RebusPuzzle> _loadPuzzles() {
  // Tests run from the package directory (`dart test` in packages/module_rebus).
  final file = File('assets/puzzles/module01.json');
  return RebusPuzzle.listFromJsonString(file.readAsStringSync());
}

RebusPuzzle _byId(List<RebusPuzzle> puzzles, String id) =>
    puzzles.firstWhere((p) => p.id == id);

/// Fills every editable cell of [number] (padded/truncated to its actual
/// box width by the caller) into `(row, slot)` of [grid].
void _fillNumber(PlayerGrid grid, int row, int slot, String number) {
  for (var pos = 0; pos < number.length; pos++) {
    final ref = CellRef(row, slot, pos);
    if (grid.isGiven(ref)) continue;
    grid.setDigit(ref, int.parse(number[pos]));
  }
}

/// Fills an entire grid from four row-operand lists, four row results, and
/// a total — leaving givens untouched. Column-sum boxes are filled from
/// [rowResults] (a valid grid always has column sum == row result).
void _fillGrid(
  PlayerGrid grid, {
  required List<List<String>> rowOperands,
  required List<String> rowResults,
  required String total,
}) {
  for (var r = 0; r < 4; r++) {
    for (var slot = 0; slot < 4; slot++) {
      _fillNumber(grid, r, slot, rowOperands[r][slot]);
    }
    _fillNumber(grid, r, 4, rowResults[r]);
  }
  for (var j = 0; j < 4; j++) {
    _fillNumber(grid, 4, j, rowResults[j]);
  }
  _fillNumber(grid, 4, 4, total);
}

void _fillCanonical(PlayerGrid grid, RebusPuzzle p) {
  _fillGrid(
    grid,
    rowOperands: p.rows.map((r) => r.nums).toList(),
    rowResults: p.rows.map((r) => r.result).toList(),
    total: p.total,
  );
}

void main() {
  late List<RebusPuzzle> puzzles;

  setUpAll(() {
    puzzles = _loadPuzzles();
  });

  test('canonical fill of the tutorial example wins', () {
    final example = _byId(puzzles, 'example');
    final grid = PlayerGrid.fromPuzzle(example);
    _fillCanonical(grid, example);

    expect(grid.isComplete, isTrue);
    expect(grid.violations().isEmpty, isTrue);
    expect(grid.wins, isTrue);
  });

  test('one wrong digit produces a violation and the grid does not win', () {
    final example = _byId(puzzles, 'example');
    final grid = PlayerGrid.fromPuzzle(example);
    _fillCanonical(grid, example);
    expect(grid.wins, isTrue);

    // Row 1 result is "16"; find an editable digit within it to corrupt.
    // Givens for "example" include (1,4,1,6) (the result's second digit),
    // so corrupt the first digit of the result instead.
    final ref = const CellRef(1, 4, 0);
    expect(grid.isGiven(ref), isFalse);
    final original = grid.digitAt(ref)!;
    grid.setDigit(ref, (original + 1) % 10 == original ? (original + 2) % 10 : (original + 1) % 10);

    final violations = grid.violations();
    expect(violations.isNotEmpty, isTrue);
    expect(grid.wins, isFalse);
    expect(violations.involves(ref), isTrue);
  });

  test('an alternate valid solution of p01 also wins (constraint satisfaction, not canonical-match)', () {
    final p01 = _byId(puzzles, 'p01');
    final grid = PlayerGrid.fromPuzzle(p01);

    // Alternate grid, consistent with p01's givens and box widths:
    //   36:9+2*9=54
    //   6+1:7*21=21
    //   4-7+6*7=21
    //   8+4:6*37=74
    // summary: 54, 21, 21, 74; total 170.
    _fillGrid(
      grid,
      rowOperands: const [
        ['36', '9', '2', '9'],
        ['6', '1', '7', '21'],
        ['4', '7', '6', '7'],
        ['8', '4', '6', '37'],
      ],
      rowResults: const ['54', '21', '21', '74'],
      total: '170',
    );

    expect(grid.isComplete, isTrue);
    expect(grid.violations().isEmpty, isTrue);
    expect(grid.wins, isTrue);
  });

  test('a leading zero is flagged as a badNumber violation', () {
    final p01 = _byId(puzzles, 'p01');
    final grid = PlayerGrid.fromPuzzle(p01);

    // Row 0 slot 0 is a 2-digit editable box ("27" canonically, no given
    // there). Fill it with a leading zero.
    grid.setDigit(const CellRef(0, 0, 0), 0);
    grid.setDigit(const CellRef(0, 0, 1), 5);

    final violations = grid.violations();
    final badNumberViolations =
        violations.items.where((v) => v.type == ViolationType.badNumber).toList();
    expect(badNumberViolations, isNotEmpty);
    expect(
      badNumberViolations.single.cells,
      containsAll([const CellRef(0, 0, 0), const CellRef(0, 0, 1)]),
    );
  });

  test('given cells are immutable', () {
    final example = _byId(puzzles, 'example');
    final grid = PlayerGrid.fromPuzzle(example);

    // (0,1,0,2) is a given: row 0, slot 1, pos 0, digit 2.
    final ref = const CellRef(0, 1, 0);
    expect(grid.isGiven(ref), isTrue);
    expect(grid.digitAt(ref), 2);

    grid.setDigit(ref, 9);
    expect(grid.digitAt(ref), 2, reason: 'setDigit on a given must be a no-op');

    grid.clearDigit(ref);
    expect(grid.digitAt(ref), 2, reason: 'clearDigit on a given must be a no-op');

    expect(grid.orderedEditableCells.contains(ref), isFalse);
  });

  test('JSON round-trip preserves editable digits and tolerates stale keys', () {
    final p01 = _byId(puzzles, 'p01');
    final grid = PlayerGrid.fromPuzzle(p01);

    grid.setDigit(const CellRef(0, 0, 0), 2);
    grid.setDigit(const CellRef(0, 0, 1), 7);
    grid.setDigit(const CellRef(1, 3, 0), 1);

    final json = grid.toJson();
    // Given cells must never be serialized.
    expect(json.containsKey('0:1:0'), isFalse);

    // Simulate a stale key from an older puzzle revision plus an
    // out-of-range value; both must be tolerated (ignored), not thrown.
    final tolerant = Map<String, dynamic>.from(json)
      ..['9:9:9'] = 5
      ..['0:0:0'] = 42;

    final restored = PlayerGrid.fromJson(p01, tolerant);
    expect(restored.digitAt(const CellRef(0, 0, 1)), 7);
    expect(restored.digitAt(const CellRef(1, 3, 0)), 1);
    // The out-of-range overwrite for 0:0:0 must have been ignored, leaving
    // the valid value from the original json untouched... but since we
    // overwrote it with an invalid value (42) before restoring, and 42 is
    // out of the 0-9 range, it must be ignored, falling back to unset.
    expect(restored.digitAt(const CellRef(0, 0, 0)), isNull);

    // A clean round-trip reproduces the same JSON.
    final restoredClean = PlayerGrid.fromJson(p01, json);
    expect(restoredClean.toJson(), equals(json));
    expect(jsonEncode(restoredClean.toJson()), jsonEncode(json));
  });
}
