import 'dart:io';

import 'package:module_squareword/module_squareword.dart';
import 'package:test/test.dart';

void main() {
  late SquarewordPuzzle tutorial;

  setUpAll(() {
    final jsonString =
        File('assets/puzzles/module05.json').readAsStringSync();
    tutorial = SquarewordPuzzle.listFromJsonString(jsonString)
        .singleWhere((p) => p.id == 'tutorial');
  });

  test('has exactly 12 steps with the expected textKeys in order', () {
    expect(squarewordTutorialSteps, hasLength(12));
    for (var i = 0; i < 12; i++) {
      expect(
        squarewordTutorialSteps[i].textKey,
        'squarewordTutorialStep${i + 1}',
      );
    }
  });

  test('steps 1, 2, and 12 (framing/closing) reveal nothing', () {
    for (final i in [0, 1, 11]) {
      expect(squarewordTutorialSteps[i].reveal, isEmpty,
          reason: 'step ${i + 1} should reveal nothing');
    }
  });

  test(
      'cumulative reveal union across all steps equals exactly the '
      'tutorial puzzle\'s 17 non-given cells - no gaps, no cell revealed '
      'twice', () {
    final givenCells = {
      for (final g in tutorial.givens) Cell(g.row, g.col),
    };
    final expectedCells = <Cell>{
      for (var r = 0; r < tutorial.n; r++)
        for (var c = 0; c < tutorial.n; c++)
          if (!givenCells.contains(Cell(r, c))) Cell(r, c),
    };
    expect(expectedCells, hasLength(17));

    final seen = <Cell>{};
    for (final step in squarewordTutorialSteps) {
      for (final g in step.reveal) {
        final cell = Cell(g.row, g.col);
        expect(seen.add(cell), isTrue,
            reason: 'cell $cell revealed by more than one step');
      }
    }
    expect(seen, expectedCells);
  });

  test(
      'every revealed cell is not a given cell (a tutorial reveal never '
      'touches a pre-filled cell)', () {
    final givenCells = {
      for (final g in tutorial.givens) Cell(g.row, g.col),
    };
    for (final step in squarewordTutorialSteps) {
      for (final g in step.reveal) {
        expect(givenCells.contains(Cell(g.row, g.col)), isFalse,
            reason: 'step "${step.textKey}" reveals given cell '
                '(${g.row}, ${g.col})');
      }
    }
  });

  test(
      'every revealed (row, col, letter) matches the tutorial puzzle\'s '
      'actual solution letter at that cell', () {
    // The book's own printed solution for the tutorial example (СЛЕЗА,
    // `05--d_t.pdf` pp.80-82), independently transcribed and verified -
    // the same oracle `solver_test.dart` checks `solveSquareword` against.
    const solution = [
      'СЛЕЗА',
      'АЕЗСЛ',
      'ЗАЛЕС',
      'ЛЗСАЕ',
      'ЕСАЛЗ',
    ];
    for (final step in squarewordTutorialSteps) {
      for (final g in step.reveal) {
        expect(g.letter, solution[g.row][g.col],
            reason: 'step "${step.textKey}" reveals (${g.row}, ${g.col}) '
                'as "${g.letter}" but the solution has '
                '"${solution[g.row][g.col]}"');
      }
    }
  });
}
