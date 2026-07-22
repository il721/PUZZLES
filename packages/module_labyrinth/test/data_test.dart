import 'dart:io';

import 'package:module_labyrinth/module_labyrinth.dart';
import 'package:test/test.dart';

void main() {
  late List<LabyrinthPuzzle> puzzles;

  setUpAll(() {
    final jsonString =
        File('assets/puzzles/module04.json').readAsStringSync();
    puzzles = LabyrinthPuzzle.listFromJsonString(jsonString);
  });

  test('has 18 numbered puzzles plus the tutorial example', () {
    expect(puzzles, hasLength(19));
    expect(puzzles.where((p) => p.tutorial).map((p) => p.id), ['example']);
    expect(
      puzzles.where((p) => !p.tutorial).map((p) => p.id),
      List.generate(18, (i) => 'p${(i + 1).toString().padLeft(2, '0')}'),
    );
  });

  test('every grid is 8x8 and uses only alphabet letters', () {
    final alphabet = russianAlphabet.toSet();
    for (final p in puzzles) {
      expect(p.grid, hasLength(8), reason: p.id);
      for (final row in p.grid) {
        expect(row, hasLength(8), reason: p.id);
        for (final letter in row) {
          expect(alphabet.contains(letter), isTrue,
              reason: '${p.id} has non-alphabet letter "$letter"');
        }
      }
    }
  });

  test('every grid starts at А and ends at Я', () {
    for (final p in puzzles) {
      expect(p.grid[0][0], 'А', reason: p.id);
      expect(p.grid[7][7], 'Я', reason: p.id);
    }
  });

  // The book constructs every grid by writing the 33-letter solution path
  // and then filling the remaining 31 cells by reusing the path's letters,
  // so each of the 64 cells belongs to a letter used exactly once (the 2
  // cells with no reuse) or exactly twice (the other 31 letters), and all
  // 33 letters appear. This is verified across all 19 transcribed grids;
  // a violation here means a transcription error in module04.json.
  test('every grid satisfies the book\'s letter-count construction rule', () {
    for (final p in puzzles) {
      final counts = <String, int>{};
      for (final row in p.grid) {
        for (final letter in row) {
          counts[letter] = (counts[letter] ?? 0) + 1;
        }
      }

      expect(counts.keys.toSet(), russianAlphabet.toSet(), reason: p.id);

      final onceCount = counts.values.where((c) => c == 1).length;
      final twiceCount = counts.values.where((c) => c == 2).length;
      final otherCount =
          counts.values.where((c) => c != 1 && c != 2).length;

      expect(onceCount, 2, reason: '${p.id} letters occurring once');
      expect(twiceCount, 31, reason: '${p.id} letters occurring twice');
      expect(otherCount, 0, reason: '${p.id} letters with an unexpected count');
      expect(counts.values.reduce((a, b) => a + b), 64, reason: p.id);
    }
  });
}
