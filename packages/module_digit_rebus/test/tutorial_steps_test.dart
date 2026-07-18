import 'dart:io';

import 'package:module_digit_rebus/module_digit_rebus.dart';
import 'package:test/test.dart';

void main() {
  late DigitRebusPuzzle example;

  setUpAll(() {
    final jsonString =
        File('assets/puzzles/module02.json').readAsStringSync();
    example = DigitRebusPuzzle.listFromJsonString(jsonString)
        .singleWhere((p) => p.id == 'example');
  });

  test('has 9 steps', () {
    expect(tutorialSteps, hasLength(9));
  });

  test('reveals are disjoint and cover all 16 cells exactly once', () {
    final seen = <CellRef>{};
    for (final step in tutorialSteps) {
      for (final ref in step.reveal) {
        expect(seen.add(ref), isTrue, reason: 'duplicate reveal $ref');
      }
    }
    expect(seen, hasLength(16));
  });

  test('every referenced cell and row/column index is in range', () {
    for (final step in tutorialSteps) {
      for (final ref in [...step.reveal, ...step.highlightCells]) {
        expect(ref.row, inInclusiveRange(0, 3));
        expect(ref.col, inInclusiveRange(0, 3));
      }
      if (step.highlightRow != null) {
        expect(step.highlightRow, inInclusiveRange(0, 3));
      }
      if (step.highlightColumn != null) {
        expect(step.highlightColumn, inInclusiveRange(0, 3));
      }
    }
  });

  test('canonicalDigitAt matches the printed answer', () {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        expect(canonicalDigitAt(example, CellRef(r, c)), example.answer[r][c]);
      }
    }
  });

  test('deduction chain follows the book: row 2, col 1, row 3, col 3', () {
    final lineSteps = tutorialSteps
        .where((s) => s.highlightRow != null || s.highlightColumn != null)
        .map((s) => s.highlightRow != null ? 'r${s.highlightRow}' : 'c${s.highlightColumn}')
        .toList();
    expect(lineSteps, ['r1', 'r1', 'c0', 'r2', 'c2']);
  });

  test('grid built from cumulative reveals never violates, then wins', () {
    final grid = PlayerGrid.fromPuzzle(example);
    for (final step in tutorialSteps) {
      for (final ref in step.reveal) {
        grid.setDigit(ref, canonicalDigitAt(example, ref));
      }
      expect(grid.violations().isEmpty, isTrue,
          reason: 'violation after partial tutorial reveal');
    }
    expect(grid.wins, isTrue);
  });
}
