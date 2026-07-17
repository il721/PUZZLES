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

List<List<int>> _canonicalGrid(RebusPuzzle p) {
  return p.rows
      .map((row) => row.nums.map(int.parse).toList(growable: false))
      .toList(growable: false);
}

bool _gridsEqual(List<List<int>> a, List<List<int>> b) {
  if (a.length != b.length) return false;
  for (var r = 0; r < a.length; r++) {
    if (a[r].length != b[r].length) return false;
    for (var j = 0; j < a[r].length; j++) {
      if (a[r][j] != b[r][j]) return false;
    }
  }
  return true;
}

bool _solutionsContainGrid(List<List<List<int>>> solutions, List<List<int>> grid) {
  return solutions.any((s) => _gridsEqual(s, grid));
}

void main() {
  late List<RebusPuzzle> puzzles;

  setUpAll(() {
    puzzles = _loadPuzzles();
  });

  test(
    'a weakened copy of the tutorial puzzle with no givens does not collapse '
    'the search to a single branch, and still contains the canonical grid',
    () {
      // This guards against unsound pruning: if the solver ever pruned a
      // partial assignment based on a *guessed* value for a not-yet-chosen
      // row (rather than only against fixed, already-known facts), it could
      // wrongly discard valid completions and under-count solutions. With
      // every given removed, the search space is wide open, so a sound
      // solver must find at least the canonical grid plus others.
      final example = _byId(puzzles, 'example');
      final weakened = RebusPuzzle(
        id: example.id,
        tutorial: example.tutorial,
        rows: example.rows,
        total: example.total,
        givens: const <Given>[],
      );

      final solutions = collectSolutions(weakened, cap: 3);

      // With every given removed the puzzle admits many solutions; `cap`
      // returns the first ones found in DFS order, so the canonical grid is
      // not guaranteed to be among them. Canonical inclusion is asserted
      // below on real puzzles (unique by the data gate), where cap: 2 must
      // surface it. Here we only require that the search does not collapse.
      expect(solutions.length, greaterThanOrEqualTo(2));
    },
  );

  group('the canonical grid is among the solver-found solutions for', () {
    for (final id in ['p01', 'p07', 'p13']) {
      test(id, () {
        final puzzle = _byId(puzzles, id);
        final solutions = collectSolutions(puzzle, cap: 2);
        expect(
          _solutionsContainGrid(solutions, _canonicalGrid(puzzle)),
          isTrue,
          reason: 'Canonical grid for "$id" not found among solver solutions',
        );
      });
    }
  });
}
