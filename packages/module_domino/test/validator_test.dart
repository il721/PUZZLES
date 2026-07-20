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

  group('DominoValue', () {
    test('canonicalization is order-independent (regression)', () {
      expect(DominoValue.of(3, 5), DominoValue.of(5, 3));
      expect(DominoValue.of(3, 5).hashCode, DominoValue.of(5, 3).hashCode);
      expect(DominoValue.of(3, 5).low, 3);
      expect(DominoValue.of(3, 5).high, 5);
      expect(DominoValue.of(5, 3).low, 3);
      expect(DominoValue.of(5, 3).high, 5);
    });

    test('toString is low:high', () {
      expect(DominoValue.of(5, 3).toString(), '3:5');
    });
  });

  test('doubleSixSet has 28 unique values', () {
    expect(doubleSixSet, hasLength(28));
    expect(doubleSixSet.toSet(), hasLength(28));
  });

  group('empty board', () {
    test('is not complete, not solved, and has all 28 values remaining',
        () {
      final status = verifyBoard(example, const <Domino>[]);
      expect(status.placedCount, 0);
      expect(status.coveredCells, isEmpty);
      expect(status.isComplete, isFalse);
      expect(status.isSolved, isFalse);
      expect(status.conflicts, isEmpty);
      expect(status.remaining, hasLength(28));
      expect(status.remaining.toSet(), doubleSixSet);
    });
  });

  group('conflicts', () {
    test('a duplicate value-pair is flagged even on a partial board', () {
      // example.grid[0] = [0, 6, 2, 5, 0, 0, 5]; grid[1][0] = 0;
      // grid[2][0] = 6. Both dominoes below canonicalize to DominoValue
      // (0, 6), and their cells do not overlap.
      final d1 = Domino(const Cell(0, 0), const Cell(0, 1));
      final d2 = Domino(const Cell(1, 0), const Cell(2, 0));
      expect(valueOf(example, d1), DominoValue.of(0, 6));
      expect(valueOf(example, d2), DominoValue.of(0, 6));

      final status = verifyBoard(example, [d1, d2]);
      expect(status.placedCount, 2);
      expect(status.conflicts, {d1, d2});
      expect(status.usedValues, {DominoValue.of(0, 6)});
      expect(status.isComplete, isFalse);
      expect(status.isSolved, isFalse);
    });
  });

  group('the example solution', () {
    test('is complete, solved, no conflicts, nothing remaining', () {
      final status = verifyBoard(example, example.solution!);
      expect(status.placedCount, 28);
      expect(status.coveredCells, hasLength(56));
      expect(status.isComplete, isTrue);
      expect(status.conflicts, isEmpty);
      expect(status.isSolved, isTrue);
      expect(status.remaining, isEmpty);
      expect(status.usedValues, doubleSixSet);
    });
  });
}
