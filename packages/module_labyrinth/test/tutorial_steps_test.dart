import 'dart:io';

import 'package:module_labyrinth/module_labyrinth.dart';
import 'package:test/test.dart';

void main() {
  late LabyrinthPuzzle example;

  setUpAll(() {
    final jsonString =
        File('assets/puzzles/module04.json').readAsStringSync();
    example = LabyrinthPuzzle.listFromJsonString(jsonString)
        .singleWhere((p) => p.id == 'example');
  });

  test('has exactly 12 steps with the expected textKeys in order', () {
    expect(labyrinthTutorialSteps, hasLength(12));
    for (var i = 0; i < 12; i++) {
      expect(labyrinthTutorialSteps[i].textKey, 'labyrinthTutorialStep${i + 1}');
    }
  });

  test('steps 1-3 reveal no path cells', () {
    for (var i = 0; i < 3; i++) {
      expect(labyrinthTutorialSteps[i].revealPathIndices, isEmpty,
          reason: 'step ${i + 1} should reveal nothing');
    }
  });

  test(
      'cumulative reveal union over steps 4-12 is exactly {0..32}, no '
      'duplicates, no gaps', () {
    final seen = <int>{};
    for (final step in labyrinthTutorialSteps.skip(3)) {
      for (final i in step.revealPathIndices) {
        expect(seen.add(i), isTrue, reason: 'duplicate reveal index $i');
      }
    }
    expect(seen, hasLength(LabyrinthPuzzle.pathLength));
    expect(
      seen,
      unorderedEquals(List.generate(LabyrinthPuzzle.pathLength, (i) => i)),
    );
  });

  test('every revealed index is a valid index into the example solution',
      () {
    final solution = example.solution!;
    for (final step in labyrinthTutorialSteps) {
      for (final i in step.revealPathIndices) {
        expect(i, inInclusiveRange(0, solution.length - 1));
      }
    }
  });

  test('every highlighted index is a valid index into the example solution',
      () {
    final solution = example.solution!;
    for (final step in labyrinthTutorialSteps) {
      for (final i in step.highlightPathIndices) {
        expect(i, inInclusiveRange(0, solution.length - 1));
      }
    }
  });

  test('markCells is empty except step 3', () {
    for (var i = 0; i < 12; i++) {
      if (i == 2) continue;
      expect(labyrinthTutorialSteps[i].markCells, isEmpty,
          reason: 'step ${i + 1} should have no markCells');
    }
  });

  test('step 3 markCells is exactly [Cell(0, 6)]', () {
    expect(labyrinthTutorialSteps[2].markCells, [const Cell(0, 6)]);
  });

  test(
      'every markCells letter occurs exactly once in the example puzzle '
      'grid', () {
    final counts = <String, int>{};
    for (final row in example.grid) {
      for (final letter in row) {
        counts[letter] = (counts[letter] ?? 0) + 1;
      }
    }
    for (final step in labyrinthTutorialSteps) {
      for (final cell in step.markCells) {
        final letter = example.letterAt(cell);
        expect(counts[letter], 1,
            reason: 'markCells letter "$letter" at $cell should occur '
                'exactly once in the example grid');
      }
    }
  });
}
