import 'dart:io';

import 'package:module_rebus/module_rebus.dart';
import 'package:test/test.dart';

void main() {
  // Tests run from the package directory (`dart test` in packages/module_rebus),
  // so the asset path is relative to the package root.
  late List<RebusPuzzle> puzzles;

  setUpAll(() {
    final file = File('assets/puzzles/module01.json');
    puzzles = RebusPuzzle.listFromJsonString(file.readAsStringSync());
  });

  test('loads all 16 puzzles', () {
    expect(puzzles, hasLength(16));
  });

  test('every puzzle canonical solution is internally consistent', () {
    for (final p in puzzles) {
      final violations = verifyCanonical(p);
      expect(violations, isEmpty, reason: 'Puzzle "${p.id}": $violations');
    }
  });

  test('exactly one tutorial puzzle', () {
    final tutorials = puzzles.where((p) => p.tutorial).toList();
    expect(tutorials, hasLength(1));
    expect(tutorials.single.id, 'example');
  });
}
