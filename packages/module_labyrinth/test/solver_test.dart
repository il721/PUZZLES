import 'dart:io';

import 'package:module_labyrinth/module_labyrinth.dart';
import 'package:test/test.dart';

/// The book's `example` grid, used wherever a real, non-trivial puzzle is
/// needed.
const _exampleGrid = [
  'АОДТЧЗУА',
  'РИЩШЙПКЮ',
  'ЮЙНЫЖЕЩТ',
  'ПГЛЦЬЪЭБ',
  'ЧИБШГЪФЛ',
  'ДМЬЖНЭСЕ',
  'ХЁЦОЫФРС',
  'ВКЗВЁМХЯ',
];

/// A hand-built grid, guaranteed by construction (not by running the
/// solver) to have at least two distinct solutions.
///
/// It lays a single 33-cell corridor from `(0,0)` to `(7,7)` across rows
/// 0-2 and down the right side of rows 3-7, assigning the corridor cells
/// the 33 alphabet letters in order (so the corridor itself is trivially a
/// valid solution). Near the end, the corridor's step from `(5,7)` to
/// `(6,6)` goes via `(6,7)`; the grid also places a *second* copy of that
/// step's letter (`Ъ`) at `(5,6)` - the other corner of the same 2x2
/// block, which is adjacent to both `(5,7)` and `(6,6)` exactly like
/// `(6,7)` is. So the path can detour through `(5,6)` instead of `(6,7)`,
/// giving a second, geometrically distinct 33-cell solution using the
/// same 33 letters. All 30 cells outside the corridor and this duplicate
/// are filled with `А` (the start letter), which is claimed on the very
/// first move of any solution, so those cells can never be entered and
/// cannot create additional, unaccounted-for solutions.
const _twinSolutionGrid = [
  'АБВГДЕЁЖ',
  'ОНМЛКЙИЗ',
  'ПРСТУФХЦ',
  'АААААААЧ',
  'АААААААШ',
  'ААААААЪЩ',
  'АААААЬЫЪ',
  'АААААЭЮЯ',
];

LabyrinthPuzzle _puzzleFrom(List<String> grid, {String id = 'p'}) =>
    LabyrinthPuzzle.fromJson({
      'id': id,
      'tutorial': false,
      'grid': grid,
      'solution': null,
      'note': null,
    });

/// Asserts that [path] is a structurally valid solution for [puzzle]: the
/// right length, correct endpoints, self-avoiding, orthogonally connected,
/// and covering the whole alphabet with no repeats.
void _expectValidSolution(LabyrinthPuzzle puzzle, List<Cell> path) {
  expect(path, hasLength(LabyrinthPuzzle.pathLength));
  expect(path.first, const Cell(0, 0));
  expect(path.last, const Cell(7, 7));
  expect(path.toSet(), hasLength(path.length), reason: 'cells must be distinct');

  for (var i = 1; i < path.length; i++) {
    final a = path[i - 1];
    final b = path[i];
    final manhattan = (a.row - b.row).abs() + (a.col - b.col).abs();
    expect(manhattan, 1, reason: '$a -> $b is not orthogonally adjacent');
  }

  final letters = path.map(puzzle.letterAt).toList();
  expect(letters.toSet(), hasLength(russianAlphabet.length),
      reason: 'letters must all be distinct');
  expect(letters.toSet(), russianAlphabet.toSet(),
      reason: 'letters must cover the whole alphabet');
}

void main() {
  test('a grid missing a letter entirely has no valid path (status zero)', () {
    // Take the example grid and remove its only 'У' (at row 0, col 6) by
    // overwriting it with a duplicate of a neighbouring letter. With only
    // 32 distinct letters left in the grid, a 33-cell distinct-letter path
    // is impossible, so the search must exhaust to zero.
    final grid = List<String>.from(_exampleGrid);
    grid[0] = 'АОДТЧЗОА'; // 'У' -> 'О'
    final puzzle = _puzzleFrom(grid, id: 'corrupted');

    final result = solveLabyrinth(puzzle);
    expect(result.status, LabyrinthSolveStatus.zero);
    expect(result.count, 0);
    expect(result.path, isNull);
  });

  test('the example puzzle has a full, structurally valid solution path', () {
    final puzzle = _puzzleFrom(_exampleGrid, id: 'example');
    final result = solveLabyrinth(puzzle);

    expect(result.status, isNot(LabyrinthSolveStatus.timeout));
    expect(result.path, isNotNull);
    _expectValidSolution(puzzle, result.path!);
  });

  test('every solution the solver returns is structurally valid (prune soundness)', () {
    final puzzle = _puzzleFrom(_twinSolutionGrid, id: 'twin');
    final result = solveLabyrinth(puzzle, cap: 2);

    expect(result.path, isNotNull);
    _expectValidSolution(puzzle, result.path!);
  });

  test('cap:1 stops at one solution; cap:2 can report multiple', () {
    final puzzle = _puzzleFrom(_twinSolutionGrid, id: 'twin');

    final capped1 = solveLabyrinth(puzzle, cap: 1);
    expect(capped1.status, LabyrinthSolveStatus.unique);
    expect(capped1.count, 1);

    final capped2 = solveLabyrinth(puzzle, cap: 2);
    expect(capped2.status, LabyrinthSolveStatus.multiple);
    expect(capped2.count, 2);
  });

  test('a 1-millisecond timeout on a real puzzle yields status timeout', () {
    final jsonString =
        File('assets/puzzles/module04.json').readAsStringSync();
    final puzzles = LabyrinthPuzzle.listFromJsonString(jsonString);
    final example = puzzles.singleWhere((p) => p.id == 'example');

    final result = solveLabyrinth(
      example,
      timeout: const Duration(milliseconds: 1),
    );
    expect(result.status, LabyrinthSolveStatus.timeout);
  });
}
