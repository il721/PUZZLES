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

/// Every `(row, slot)` number-box declaration in the `example` grid, mirroring
/// `PlayerGrid.fromPuzzle`'s enumeration: rows 0..3 have slots 0..4 (four
/// operands plus the result), and row 4 (summary) has slots 0..4 (four
/// column sums plus the grand total).
Iterable<CellRef> _allCells(RebusPuzzle puzzle) sync* {
  for (var r = 0; r < 4; r++) {
    final row = puzzle.rows[r];
    for (var slot = 0; slot < 4; slot++) {
      for (var pos = 0; pos < row.nums[slot].length; pos++) {
        yield CellRef(r, slot, pos);
      }
    }
    for (var pos = 0; pos < row.result.length; pos++) {
      yield CellRef(r, 4, pos);
    }
  }
  for (var j = 0; j < 4; j++) {
    for (var pos = 0; pos < puzzle.rows[j].result.length; pos++) {
      yield CellRef(4, j, pos);
    }
  }
  for (var pos = 0; pos < puzzle.total.length; pos++) {
    yield CellRef(4, 4, pos);
  }
}

void main() {
  late RebusPuzzle example;
  late PlayerGrid grid;

  setUpAll(() {
    final puzzles = _loadPuzzles();
    example = _byId(puzzles, 'example');
    grid = PlayerGrid.fromPuzzle(example);
  });

  test('there are exactly 15 tutorial steps', () {
    expect(tutorialSteps, hasLength(15));
  });

  test('no reveal cell repeats across steps', () {
    final seen = <CellRef>{};
    for (final step in tutorialSteps) {
      for (final cell in step.reveal) {
        expect(seen.contains(cell), isFalse, reason: '$cell revealed more than once');
        seen.add(cell);
      }
    }
  });

  test('no reveal cell is a given of the example puzzle', () {
    final givenRefs = example.givens.map((g) => CellRef(g.row, g.slot, g.pos)).toSet();
    for (final step in tutorialSteps) {
      for (final cell in step.reveal) {
        expect(givenRefs.contains(cell), isFalse, reason: '$cell is already a given');
      }
    }
  });

  test('givens + all reveals cover every cell of the example grid exactly', () {
    final allCells = _allCells(example).toSet();
    expect(allCells, hasLength(38));

    final givenRefs = example.givens.map((g) => CellRef(g.row, g.slot, g.pos)).toSet();
    final revealed = <CellRef>{};
    for (final step in tutorialSteps) {
      revealed.addAll(step.reveal);
    }

    final covered = <CellRef>{...givenRefs, ...revealed};
    expect(covered, equals(allCells));
    // Exactness (no duplicates) already checked by the two tests above,
    // together with disjointness of givens and reveals; this confirms the
    // counts line up too.
    expect(givenRefs.length + revealed.length, equals(allCells.length));
  });

  test('every reveal/highlight cell is within the grid\'s box widths', () {
    void checkCell(CellRef ref) {
      expect(ref.row, inInclusiveRange(0, 4));
      expect(ref.slot, inInclusiveRange(0, 4));
      final width = grid.widthOf(ref.row, ref.slot);
      expect(ref.pos, inInclusiveRange(0, width - 1),
          reason: '$ref out of bounds for width $width');
    }

    for (final step in tutorialSteps) {
      for (final cell in step.reveal) {
        checkCell(cell);
      }
      for (final cell in step.highlightCells) {
        checkCell(cell);
      }
      if (step.highlightRow != null) {
        expect(step.highlightRow, inInclusiveRange(0, 4));
      }
      if (step.highlightColumn != null) {
        expect(step.highlightColumn, inInclusiveRange(0, 3));
      }
    }
  });

  test('canonicalDigitAt returns a valid digit (0-9) for every cell', () {
    for (final cell in _allCells(example)) {
      final digit = canonicalDigitAt(example, cell);
      expect(digit, inInclusiveRange(0, 9), reason: 'bad digit for $cell');
    }
  });
}
