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
}
