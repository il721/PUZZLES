import 'dart:io';

import 'package:module_squareword/module_squareword.dart';
import 'package:test/test.dart';

/// The book's own worked tutorial example (СЛЕЗА, 5x5, `05--d_t.pdf`
/// pp.80-82), transcribed and cross-verified independently of
/// `module05.json`. Its printed solved grid is the independent oracle for
/// the "tutorial example has a unique solution matching the book" test
/// below.
const _tutorialBookSolution = [
  'СЛЕЗА',
  'АЕЗСЛ',
  'ЗАЛЕС',
  'ЛЗСАЕ',
  'ЕСАЛЗ',
];

SquarewordPuzzle _puzzleFrom({
  required String id,
  required int n,
  required String keyword,
  required List<List<dynamic>> givens,
}) =>
    SquarewordPuzzle.fromJson({
      'id': id,
      'tutorial': false,
      'n': n,
      'keyword': keyword,
      'givens': givens,
    });

/// Asserts that [solution] is a structurally valid diagonal Latin square
/// over [puzzle]'s keyword alphabet, consistent with every given.
void _expectValidSolution(SquarewordPuzzle puzzle, List<String> solution) {
  final n = puzzle.n;
  final alphabet = puzzle.keyword.split('').toSet();
  expect(solution, hasLength(n));

  for (final row in solution) {
    expect(row.split(''), hasLength(n));
    expect(row.split('').toSet(), alphabet, reason: 'row "$row"');
  }
  for (var c = 0; c < n; c++) {
    final col = [for (var r = 0; r < n; r++) solution[r][c]];
    expect(col.toSet(), alphabet, reason: 'column $c');
  }
  final mainDiag = [for (var i = 0; i < n; i++) solution[i][i]];
  expect(mainDiag.toSet(), alphabet, reason: 'main diagonal');
  final antiDiag = [for (var i = 0; i < n; i++) solution[i][n - 1 - i]];
  expect(antiDiag.toSet(), alphabet, reason: 'anti-diagonal');

  for (final g in puzzle.givens) {
    expect(solution[g.row][g.col], g.letter,
        reason: 'given $g not honoured');
  }
}

void main() {
  // (a) A hand-built multi-solution given-set: puzzle p01's (СЛЮДА) row-0
  // givens only, with its secondary given word dropped. With only the
  // keyword row fixed, the rest of the diagonal Latin square is
  // under-constrained and admits more than one completion.
  test('row-0-only givens (secondary word dropped) yields multiple solutions',
      () {
    final puzzle = _puzzleFrom(
      id: 'top-row-only',
      n: 5,
      keyword: 'СЛЮДА',
      givens: [
        [0, 0, 'С'],
        [0, 1, 'Л'],
        [0, 2, 'Ю'],
        [0, 3, 'Д'],
        [0, 4, 'А'],
      ],
    );

    final result = solveSquareword(puzzle, cap: 2);
    expect(result.status, SquarewordSolveStatus.multiple);
    expect(result.count, 2);
    expect(result.solution, isNotNull);
    _expectValidSolution(puzzle, result.solution!);
  });

  // (b) The tutorial example (СЛЕЗА) has a unique solution, and it matches
  // the book's printed answer exactly.
  test('the tutorial example (СЛЕЗА) has a unique solution matching the book',
      () {
    final jsonString =
        File('assets/puzzles/module05.json').readAsStringSync();
    final puzzles = SquarewordPuzzle.listFromJsonString(jsonString);
    final tutorial = puzzles.singleWhere((p) => p.id == 'tutorial');

    final result = solveSquareword(tutorial);
    expect(result.status, SquarewordSolveStatus.unique);
    expect(result.count, 1);
    expect(result.solution, _tutorialBookSolution);
    _expectValidSolution(tutorial, result.solution!);
  });

  // (c) Four-state discipline: cap:1 stops at one solution and reports
  // unique (even though more exist); cap:2 reports multiple; and a
  // deliberately tiny timeout on a real puzzle reports timeout, distinctly
  // from zero - a slow search must never be misread as "unsolvable".
  test('cap:1 stops at one solution; cap:2 reports multiple', () {
    final puzzle = _puzzleFrom(
      id: 'top-row-only',
      n: 5,
      keyword: 'СЛЮДА',
      givens: [
        [0, 0, 'С'],
        [0, 1, 'Л'],
        [0, 2, 'Ю'],
        [0, 3, 'Д'],
        [0, 4, 'А'],
      ],
    );

    final capped1 = solveSquareword(puzzle, cap: 1);
    expect(capped1.status, SquarewordSolveStatus.unique);
    expect(capped1.count, 1);

    final capped2 = solveSquareword(puzzle, cap: 2);
    expect(capped2.status, SquarewordSolveStatus.multiple);
    expect(capped2.count, 2);
  });

  test('a 1-microsecond timeout on a real puzzle yields status timeout, '
      'never confused with zero', () {
    final jsonString =
        File('assets/puzzles/module05.json').readAsStringSync();
    final puzzles = SquarewordPuzzle.listFromJsonString(jsonString);
    // The largest (7x7) puzzles have the biggest search space, making a
    // near-instant timeout land mid-search rather than completing anyway.
    final puzzle = puzzles.singleWhere((p) => p.id == 'p15');

    final result = solveSquareword(
      puzzle,
      timeout: const Duration(microseconds: 1),
    );
    expect(result.status, SquarewordSolveStatus.timeout);
    expect(result.status, isNot(SquarewordSolveStatus.zero));
  });

  test('contradictory givens (same letter twice in a row) short-circuit '
      'to zero, not a false unique/multiple', () {
    final puzzle = _puzzleFrom(
      id: 'contradictory',
      n: 5,
      keyword: 'СЛЮДА',
      givens: [
        [0, 0, 'С'],
        [0, 1, 'С'], // duplicate letter in row 0
      ],
    );

    final result = solveSquareword(puzzle);
    expect(result.status, SquarewordSolveStatus.zero);
    expect(result.count, 0);
    expect(result.solution, isNull);
  });

  test('every one of the 17 numbered puzzles is solvable and honours its '
      'own givens', () {
    final jsonString =
        File('assets/puzzles/module05.json').readAsStringSync();
    final puzzles = SquarewordPuzzle.listFromJsonString(jsonString);

    for (final puzzle in puzzles.where((p) => !p.tutorial)) {
      final result = solveSquareword(
        puzzle,
        cap: 2,
        timeout: const Duration(seconds: 30),
      );
      expect(result.status, isNot(SquarewordSolveStatus.timeout),
          reason: puzzle.id);
      expect(result.status, isNot(SquarewordSolveStatus.zero),
          reason: puzzle.id);
      expect(result.solution, isNotNull, reason: puzzle.id);
      _expectValidSolution(puzzle, result.solution!);
    }
  });
}
