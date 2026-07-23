import 'dart:io';

import 'package:module_squareword/module_squareword.dart';
import 'package:test/test.dart';

/// The book's own printed solution for puzzle p01 (СЛЮДА, 5x5,
/// `05-solve.pdf`), independently transcribed and verified against the
/// scan - used to check a real full-solve reaches [SquarewordStatus.isSolved].
const _p01BookSolution = [
  'СЛЮДА',
  'АЮСЛД',
  'ЛАДЮС',
  'ДСЛАЮ',
  'ЮДАСЛ',
];

void main() {
  late List<SquarewordPuzzle> puzzles;
  late SquarewordPuzzle tutorial;
  late SquarewordPuzzle p01;

  setUpAll(() {
    final jsonString =
        File('assets/puzzles/module05.json').readAsStringSync();
    puzzles = SquarewordPuzzle.listFromJsonString(jsonString);
    tutorial = puzzles.singleWhere((p) => p.id == 'tutorial');
    p01 = puzzles.singleWhere((p) => p.id == 'p01');
  });

  group('given-cell immutability', () {
    test('place is a no-op on a given cell', () {
      final board = SquarewordBoard.fromPuzzle(tutorial);
      const given = Cell(0, 0); // "С"
      expect(board.isGiven(given), isTrue);
      board.place(given, 'Л');
      expect(board.letterAt(given), 'С');
    });

    test('clear is a no-op on a given cell', () {
      final board = SquarewordBoard.fromPuzzle(tutorial);
      const given = Cell(2, 2); // "Л"
      board.clear(given);
      expect(board.letterAt(given), 'Л');
    });
  });

  test('place succeeds on an editable cell even when it creates a duplicate '
      '(allow + live highlight, not block-on-entry, per decision #3)', () {
    final board = SquarewordBoard.fromPuzzle(tutorial);
    const a = Cell(1, 0);
    const b = Cell(1, 1);
    board.place(a, 'С');
    // No exception, no rejection - even though (0,0) is already "С" in the
    // same column, and (1,1) below will duplicate within the row.
    expect(board.letterAt(a), 'С');
    board.place(b, 'С');
    expect(board.letterAt(b), 'С');
    // Both placements are visible - the write was never blocked.
    expect(board.status().violatingCells, containsAll([a, b]));
  });

  group('violation detection', () {
    test('a non-violating fill reports an empty violation set', () {
      final board = SquarewordBoard.fromPuzzle(tutorial);
      // (1,0) and (1,3) don't clash with each other or with any given on
      // their shared rows/columns/diagonals.
      board.place(const Cell(1, 0), 'А');
      board.place(const Cell(1, 3), 'С');
      expect(board.status().violatingCells, isEmpty);
    });

    test('a row duplicate is detected symmetrically (both cells flagged)',
        () {
      final board = SquarewordBoard.fromPuzzle(tutorial);
      const a = Cell(1, 0);
      const b = Cell(1, 1);
      // "Е" (not "С"/"Л") keeps this isolated to just the row duplicate:
      // column 0's given (0,0)="С" and the main diagonal's givens
      // (0,0)="С", (2,2)="Л" (since (1,1) sits on the main diagonal) would
      // otherwise also fire.
      board.place(a, 'Е');
      board.place(b, 'Е');
      expect(board.status().violatingCells, {a, b});
    });

    test('a column duplicate is detected symmetrically (both cells flagged)',
        () {
      final board = SquarewordBoard.fromPuzzle(tutorial);
      const a = Cell(1, 0);
      const b = Cell(3, 0);
      board.place(a, 'Л');
      board.place(b, 'Л');
      expect(board.status().violatingCells, {a, b});
    });

    test(
        'a main-diagonal duplicate is detected symmetrically (both cells '
        'flagged)', () {
      final board = SquarewordBoard.fromPuzzle(tutorial);
      // (1,1) and (3,3): both on the main diagonal (row == col), neither a
      // given cell.
      const a = Cell(1, 1);
      const b = Cell(3, 3);
      board.place(a, 'А');
      board.place(b, 'А');
      expect(board.status().violatingCells, {a, b});
    });

    test(
        'an anti-diagonal duplicate is detected symmetrically (both cells '
        'flagged)', () {
      final board = SquarewordBoard.fromPuzzle(tutorial);
      // (1,3) and (3,1): both on the anti-diagonal (row + col == n - 1 ==
      // 4), neither a given cell. "С" keeps this isolated: the
      // anti-diagonal's own givens are (0,4)="А" and (2,2)="Л", and column
      // 3's given (0,3)="З"/(2,3)="Е" - "С" clashes with none of them.
      const a = Cell(1, 3);
      const b = Cell(3, 1);
      board.place(a, 'С');
      board.place(b, 'С');
      expect(board.status().violatingCells, {a, b});
    });
  });

  group('isSolved', () {
    test('fully filled but violating is not solved', () {
      final board = SquarewordBoard.fromPuzzle(tutorial);
      for (var r = 0; r < tutorial.n; r++) {
        for (var c = 0; c < tutorial.n; c++) {
          final cell = Cell(r, c);
          if (board.isGiven(cell)) continue;
          // Fill every editable cell with the same letter - guarantees
          // duplicates everywhere while leaving nothing empty.
          board.place(cell, tutorial.letters.first);
        }
      }
      final status = board.status();
      expect(status.filledCount, tutorial.n * tutorial.n);
      expect(status.violatingCells, isNotEmpty);
      expect(status.isSolved, isFalse);
    });

    test(
        'the real solution (from the book, p01) fully fills the board with '
        'zero violations and isSolved == true', () {
      final board = SquarewordBoard.fromPuzzle(p01);
      for (var r = 0; r < p01.n; r++) {
        for (var c = 0; c < p01.n; c++) {
          final cell = Cell(r, c);
          if (board.isGiven(cell)) continue;
          board.place(cell, _p01BookSolution[r][c]);
        }
      }
      final status = board.status();
      expect(status.filledCount, p01.n * p01.n);
      expect(status.violatingCells, isEmpty);
      expect(status.isSolved, isTrue);
    });
  });

  group('toJson / fromJson', () {
    test('round-trip preserves state exactly for a partially-filled board',
        () {
      final board = SquarewordBoard.fromPuzzle(tutorial);
      board.place(const Cell(1, 0), 'А');
      board.place(const Cell(3, 3), 'А');
      board.place(const Cell(4, 4), 'З');

      final json = board.toJson();
      final restored = SquarewordBoard.fromJson(tutorial, json);

      for (var r = 0; r < tutorial.n; r++) {
        for (var c = 0; c < tutorial.n; c++) {
          final cell = Cell(r, c);
          expect(restored.letterAt(cell), board.letterAt(cell),
              reason: 'cell $cell');
        }
      }
      expect(restored.toJson(), json);
    });

    test('a totally malformed payload falls back to the fresh initial state',
        () {
      final restored = SquarewordBoard.fromJson(tutorial, {'garbage': 42});
      final fresh = SquarewordBoard.fromPuzzle(tutorial);
      for (var r = 0; r < tutorial.n; r++) {
        for (var c = 0; c < tutorial.n; c++) {
          final cell = Cell(r, c);
          expect(restored.letterAt(cell), fresh.letterAt(cell));
        }
      }
    });

    test('a corrupt/stale cell key is dropped, not thrown, and does not '
        'discard the rest of the save', () {
      final board = SquarewordBoard.fromJson(tutorial, {
        'filled': {
          '1,0': 'А', // valid editable cell
          '99,99': 'А', // out of bounds
          '0,0': 'Л', // a given cell - refuses to override "С"
          '1,1': 'Ъ', // not one of СЛЕЗА's letters
          'garbage': 'А', // not a well-formed "r,c" key
        },
      });

      expect(board.letterAt(const Cell(1, 0)), 'А');
      expect(board.letterAt(const Cell(0, 0)), 'С'); // given, untouched
      expect(board.letterAt(const Cell(1, 1)), isNull); // dropped
      // Only the one valid entry survives.
      expect(board.toJson(), {
        'filled': {'1,0': 'А'},
      });
    });
  });
}
