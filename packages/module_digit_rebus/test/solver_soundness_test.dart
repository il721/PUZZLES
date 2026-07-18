import 'dart:io';

import 'package:module_digit_rebus/module_digit_rebus.dart';
import 'package:test/test.dart';

void main() {
  late List<DigitRebusPuzzle> puzzles;

  setUpAll(() {
    final jsonString =
        File('assets/puzzles/module02.json').readAsStringSync();
    puzzles = DigitRebusPuzzle.listFromJsonString(jsonString);
  });

  test('every puzzle has at least one solution (the printed answer)', () {
    for (final p in puzzles) {
      expect(countSolutions(p, cap: 2), greaterThan(0), reason: p.id);
    }
  });

  test('the tutorial example is uniquely solvable', () {
    final example = puzzles.singleWhere((p) => p.id == 'example');
    expect(countSolutions(example), 1);
  });

  test('cap bounds the reported count', () {
    final p = puzzles.first;
    expect(countSolutions(p, cap: 1), 1);
  });
}
