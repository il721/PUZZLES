import 'dart:io';

import 'package:module_domino/module_domino.dart';
import 'package:test/test.dart';

void main() {
  late DominoPuzzle example;

  setUpAll(() {
    final jsonString =
        File('assets/puzzles/module03.json').readAsStringSync();
    example = DominoPuzzle.listFromJsonString(jsonString)
        .singleWhere((p) => p.id == 'example');
  });

  test('has 10 steps', () {
    expect(dominoTutorialSteps, hasLength(10));
  });

  test('reveal union is exactly 0..27, no duplicates, no gaps', () {
    final seen = <int>{};
    for (final step in dominoTutorialSteps) {
      for (final i in step.revealSolutionIndices) {
        expect(seen.add(i), isTrue, reason: 'duplicate reveal index $i');
      }
    }
    expect(seen, hasLength(28));
    expect(seen, unorderedEquals(List.generate(28, (i) => i)));
  });

  test('every revealed index is also highlighted for its step', () {
    for (final step in dominoTutorialSteps) {
      expect(
        step.highlightSolutionIndices.toSet(),
        step.revealSolutionIndices.toSet(),
      );
    }
  });

  test('every referenced solution index is in range', () {
    for (final step in dominoTutorialSteps) {
      for (final i in [
        ...step.revealSolutionIndices,
        ...step.highlightSolutionIndices,
      ]) {
        expect(i, inInclusiveRange(0, 27));
      }
    }
  });

  test('cumulative reveals against example.solution build a solved board',
      () {
    final placed = <Domino>[];
    for (final step in dominoTutorialSteps) {
      for (final i in step.revealSolutionIndices) {
        placed.add(example.solution![i]);
      }
      final status = verifyBoard(example, placed);
      expect(status.conflicts, isEmpty,
          reason: 'conflict after partial tutorial reveal');
    }
    expect(placed, hasLength(28));
    final finalStatus = verifyBoard(example, placed);
    expect(finalStatus.isSolved, isTrue);
  });
}
