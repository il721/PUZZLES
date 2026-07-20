import 'dart:io';

import 'package:module_domino/module_domino.dart';
import 'package:test/test.dart';

void main() {
  late List<DominoPuzzle> puzzles;

  setUpAll(() {
    final jsonString = File('assets/puzzles/module03.json').readAsStringSync();
    puzzles = DominoPuzzle.listFromJsonString(jsonString);
  });

  test('every one of the 19 grids satisfies the digit-count invariant', () {
    for (final p in puzzles) {
      final counts = digitCounts(p.grid);
      for (var digit = 0; digit <= 6; digit++) {
        expect(counts[digit], 8,
            reason: '${p.id} digit $digit count should be 8');
      }
    }
  });

  test('every one of the 19 grids has at least one valid tiling', () {
    for (final p in puzzles) {
      final count = countSolutions(p.grid, cap: 2);
      expect(count, greaterThan(0),
          reason: '${p.id} has no valid double-six tiling');
    }
  });

  test('the example stored solution matches a solver-found tiling', () {
    final example = puzzles.singleWhere((p) => p.id == 'example');
    final solved = firstSolution(example.grid);
    expect(solved, isNotNull);

    (int, int) canon(Domino d) {
      final va = example.grid[d.a.row][d.a.col];
      final vb = example.grid[d.b.row][d.b.col];
      return va <= vb ? (va, vb) : (vb, va);
    }

    final storedPairs = example.solution!.map(canon).toSet();
    final solvedPairs = solved!.map(canon).toSet();
    expect(storedPairs, hasLength(28));
    expect(solvedPairs, hasLength(28));
    // Both partitions must realize the full double-six set, whether or
    // not they are the exact same geometric tiling (non-uniqueness is
    // allowed by the constraint-satisfaction win rule).
    expect(storedPairs, solvedPairs);
  });
}
