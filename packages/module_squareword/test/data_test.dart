import 'dart:io';

import 'package:module_squareword/module_squareword.dart';
import 'package:test/test.dart';

void main() {
  late List<SquarewordPuzzle> puzzles;

  setUpAll(() {
    final jsonString =
        File('assets/puzzles/module05.json').readAsStringSync();
    puzzles = SquarewordPuzzle.listFromJsonString(jsonString);
  });

  test('has 17 numbered puzzles plus the tutorial example', () {
    expect(puzzles, hasLength(18));
    expect(puzzles.where((p) => p.tutorial).map((p) => p.id), ['tutorial']);
    expect(
      puzzles.where((p) => !p.tutorial).map((p) => p.id),
      List.generate(17, (i) => 'p${(i + 1).toString().padLeft(2, '0')}'),
    );
  });

  test('every keyword has n distinct letters', () {
    for (final p in puzzles) {
      final letters = p.keyword.split('');
      expect(letters, hasLength(p.n), reason: p.id);
      expect(letters.toSet(), hasLength(p.n),
          reason: '${p.id} keyword "${p.keyword}" has a repeated letter');
    }
  });

  // Every puzzle's row-0 givens are the full printed keyword, in column
  // order - the book's fixed starting row for every squareword grid.
  test('row-0 givens equal the keyword in column order', () {
    for (final p in puzzles) {
      final row0 = <int, String>{
        for (final g in p.givens.where((g) => g.row == 0)) g.col: g.letter,
      };
      expect(row0.keys.toSet(), List.generate(p.n, (i) => i).toSet(),
          reason: '${p.id} is missing a row-0 given cell');
      final row0Letters =
          List.generate(p.n, (c) => row0[c]).join();
      expect(row0Letters, p.keyword, reason: p.id);
    }
  });

  test('every given letter is a member of its puzzle\'s keyword set', () {
    for (final p in puzzles) {
      final alphabet = p.keyword.split('').toSet();
      for (final g in p.givens) {
        expect(alphabet.contains(g.letter), isTrue,
            reason: '${p.id} given $g uses a letter outside its keyword '
                '"${p.keyword}"');
      }
    }
  });

  test('every given cell is in bounds and cells are pairwise distinct', () {
    for (final p in puzzles) {
      final seen = <Cell>{};
      for (final g in p.givens) {
        expect(g.row, inInclusiveRange(0, p.n - 1), reason: '${p.id} $g');
        expect(g.col, inInclusiveRange(0, p.n - 1), reason: '${p.id} $g');
        expect(seen.add(Cell(g.row, g.col)), isTrue,
            reason: '${p.id} has a duplicate given cell $g');
      }
    }
  });

  test('every puzzle has a plausible n (5, 6, or 7)', () {
    for (final p in puzzles) {
      expect(p.n, anyOf(5, 6, 7), reason: p.id);
    }
  });
}
