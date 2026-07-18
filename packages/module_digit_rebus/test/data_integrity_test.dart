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

  test('has 18 numbered puzzles plus the tutorial example', () {
    expect(puzzles, hasLength(19));
    expect(puzzles.where((p) => p.tutorial).map((p) => p.id), ['example']);
    expect(
      puzzles.where((p) => !p.tutorial).map((p) => p.id),
      List.generate(18, (i) => 'p${(i + 1).toString().padLeft(2, '0')}'),
    );
  });

  test('ids are unique', () {
    expect(puzzles.map((p) => p.id).toSet(), hasLength(puzzles.length));
  });

  test('every puzzle has full 4x4 shape', () {
    for (final p in puzzles) {
      expect(p.glyphs, hasLength(4), reason: p.id);
      expect(p.answer, hasLength(4), reason: p.id);
      expect(p.rowOps, hasLength(4), reason: p.id);
      expect(p.colOps, hasLength(4), reason: p.id);
      for (var i = 0; i < 4; i++) {
        expect(p.glyphs[i], hasLength(4), reason: p.id);
        expect(p.answer[i], hasLength(4), reason: p.id);
        expect(p.rowOps[i], hasLength(2), reason: p.id);
        expect(p.colOps[i], hasLength(2), reason: p.id);
      }
    }
  });

  test('operators are ASCII + - * : only', () {
    const allowed = {'+', '-', '*', ':'};
    for (final p in puzzles) {
      for (final ops in [...p.rowOps, ...p.colOps]) {
        for (final op in ops) {
          expect(allowed, contains(op), reason: '${p.id} op "$op"');
        }
      }
    }
  });

  test('every printed answer digit is admitted by its cell glyph', () {
    for (final p in puzzles) {
      expect(verifyCanonical(p), isEmpty, reason: p.id);
    }
  });
}
