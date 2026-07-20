import 'dart:io';

import 'package:module_domino/module_domino.dart';
import 'package:test/test.dart';

void main() {
  late List<DominoPuzzle> puzzles;

  setUpAll(() {
    final jsonString = File('assets/puzzles/module03.json').readAsStringSync();
    puzzles = DominoPuzzle.listFromJsonString(jsonString);
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

  test('every puzzle has a full 8x7 grid of digits 0..6', () {
    for (final p in puzzles) {
      expect(p.grid, hasLength(8), reason: p.id);
      for (final row in p.grid) {
        expect(row, hasLength(7), reason: p.id);
        for (final digit in row) {
          expect(digit, inInclusiveRange(0, 6), reason: p.id);
        }
      }
    }
  });

  test('example is a tutorial with a 28-domino solution', () {
    final example = puzzles.singleWhere((p) => p.id == 'example');
    expect(example.tutorial, isTrue);
    expect(example.solution, isNotNull);
    expect(example.solution, hasLength(28));
  });

  test('non-example puzzles have no stored solution', () {
    for (final p in puzzles.where((p) => !p.tutorial)) {
      expect(p.solution, isNull, reason: p.id);
    }
  });

  test('p01 grid first row is correct', () {
    final p01 = puzzles.singleWhere((p) => p.id == 'p01');
    expect(p01.grid.first, [5, 1, 1, 5, 3, 5, 1]);
  });

  test('rows/cols helpers and valueAt', () {
    final p01 = puzzles.singleWhere((p) => p.id == 'p01');
    expect(p01.rows, 8);
    expect(p01.cols, 7);
    expect(p01.valueAt(const Cell(0, 0)), 5);
    expect(p01.valueAt(const Cell(7, 6)), 6);
  });

  test('Cell value-equality and hashCode', () {
    expect(const Cell(2, 3), const Cell(2, 3));
    expect(const Cell(2, 3), isNot(const Cell(3, 2)));
    expect(const Cell(2, 3).hashCode, const Cell(2, 3).hashCode);

    final seen = <Cell>{}
      ..add(const Cell(1, 1))
      ..add(Cell(1, 1));
    expect(seen, hasLength(1));
  });

  test('Domino value-equality is order-independent', () {
    final d1 = Domino(const Cell(0, 0), const Cell(0, 1));
    final d2 = Domino(const Cell(0, 1), const Cell(0, 0));
    expect(d1, d2);
    expect(d1.hashCode, d2.hashCode);

    final different = Domino(const Cell(0, 0), const Cell(1, 0));
    expect(d1, isNot(different));

    final seen = <Domino>{d1, d2};
    expect(seen, hasLength(1));
  });
}
