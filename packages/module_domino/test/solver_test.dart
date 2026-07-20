import 'dart:io';

import 'package:module_domino/module_domino.dart';
import 'package:test/test.dart';

void main() {
  late List<DominoPuzzle> puzzles;

  setUpAll(() {
    final jsonString = File('assets/puzzles/module03.json').readAsStringSync();
    puzzles = DominoPuzzle.listFromJsonString(jsonString);
  });

  test('the example grid has at least one valid tiling', () {
    final example = puzzles.singleWhere((p) => p.id == 'example');
    expect(countSolutions(example.grid, cap: 2), greaterThan(0));
  });

  test('firstSolution on the example grid is a valid full tiling', () {
    final example = puzzles.singleWhere((p) => p.id == 'example');
    final solution = firstSolution(example.grid);
    expect(solution, isNotNull);
    expect(solution, hasLength(28));

    final covered = <Cell>{};
    final usedPairs = <(int, int)>{};
    for (final domino in solution!) {
      expect(covered.add(domino.a), isTrue,
          reason: '${domino.a} covered twice');
      expect(covered.add(domino.b), isTrue,
          reason: '${domino.b} covered twice');

      final rowDelta = (domino.a.row - domino.b.row).abs();
      final colDelta = (domino.a.col - domino.b.col).abs();
      expect(rowDelta + colDelta, 1, reason: 'not orthogonally adjacent');

      final va = example.grid[domino.a.row][domino.a.col];
      final vb = example.grid[domino.b.row][domino.b.col];
      final pair = va <= vb ? (va, vb) : (vb, va);
      expect(usedPairs.add(pair), isTrue, reason: 'pair $pair reused');
    }
    expect(covered, hasLength(56));

    final expectedPairs = {
      for (var i = 0; i <= 6; i++)
        for (var j = i; j <= 6; j++) (i, j),
    };
    expect(usedPairs, expectedPairs);
  });

  test('cap bounds the reported count', () {
    final example = puzzles.singleWhere((p) => p.id == 'example');
    expect(countSolutions(example.grid, cap: 1), 1);
  });

  test('digit-count invariant holds for a couple of puzzles', () {
    for (final id in ['example', 'p01', 'p18']) {
      final puzzle = puzzles.singleWhere((p) => p.id == id);
      final counts = digitCounts(puzzle.grid);
      for (var digit = 0; digit <= 6; digit++) {
        expect(counts[digit], 8, reason: '$id digit $digit');
      }
    }
  });

  test('a grid with no valid tiling yields 0 solutions and null firstSolution', () {
    // 2x2 grid where both possible dominoes share the same value-pair
    // (1,1) - impossible to cover with distinct pairs even though it is
    // trivially geometrically tileable.
    final grid = [
      [1, 1],
      [1, 1],
    ];
    expect(countSolutions(grid), 0);
    expect(firstSolution(grid), isNull);
  });
}
