import 'package:module_labyrinth/module_labyrinth.dart';
import 'package:test/test.dart';

/// A valid 8x8 grid (the book's `example` puzzle) reused across tests that
/// only need a well-formed grid, not a solved one.
const _validGrid = [
  'АОДТЧЗУА',
  'РИЩШЙПКЮ',
  'ЮЙНЫЖЕЩТ',
  'ПГЛЦЬЪЭБ',
  'ЧИБШГЪФЛ',
  'ДМЬЖНЭСЕ',
  'ХЁЦОЫФРС',
  'ВКЗВЁМХЯ',
];

void main() {
  test('Cell value-equality and hashCode', () {
    expect(const Cell(2, 3), const Cell(2, 3));
    expect(const Cell(2, 3), isNot(const Cell(3, 2)));
    expect(const Cell(2, 3).hashCode, const Cell(2, 3).hashCode);

    final seen = <Cell>{}
      ..add(const Cell(1, 1))
      ..add(Cell(1, 1));
    expect(seen, hasLength(1));
  });

  test('letterAt reads grid[row][col]', () {
    final puzzle = LabyrinthPuzzle.fromJson({
      'id': 'p',
      'tutorial': false,
      'grid': _validGrid,
      'solution': null,
      'note': null,
    });
    expect(puzzle.letterAt(const Cell(0, 0)), 'А');
    expect(puzzle.letterAt(const Cell(7, 7)), 'Я');
    expect(puzzle.letterAt(const Cell(1, 2)), 'Щ');
  });

  test('book coordinate convention maps (bookRow, colLetter) to (row, col)', () {
    // The book labels rows 8 (top) down to 1 (bottom) and columns a..h;
    // (bookRow, colLetter) -> (8 - bookRow, colLetter - 'a').
    Cell bookToInternal(int bookRow, String colLetter) => Cell(
          8 - bookRow,
          colLetter.codeUnitAt(0) - 'a'.codeUnitAt(0),
        );

    // Book (8, 'a') is the top-left corner, always 'А'.
    expect(bookToInternal(8, 'a'), const Cell(0, 0));
    // Book (1, 'h') is the bottom-right corner, always 'Я'.
    expect(bookToInternal(1, 'h'), const Cell(7, 7));
    // Book (5, 'd') is an interior cell.
    expect(bookToInternal(5, 'd'), const Cell(3, 3));
  });

  test('fromJson round-trip, including a non-null solution', () {
    final json = {
      'id': 'p01',
      'tutorial': true,
      'grid': _validGrid,
      'solution': [
        [0, 0],
        [1, 0],
        [1, 1],
      ],
      'note': 'sample note',
    };
    final puzzle = LabyrinthPuzzle.fromJson(json);

    expect(puzzle.id, 'p01');
    expect(puzzle.tutorial, isTrue);
    expect(puzzle.grid, hasLength(8));
    for (final row in puzzle.grid) {
      expect(row, hasLength(8));
    }
    expect(puzzle.grid[1][2], 'Щ');
    expect(puzzle.solution, [
      const Cell(0, 0),
      const Cell(1, 0),
      const Cell(1, 1),
    ]);
    expect(puzzle.note, 'sample note');
  });

  test('fromJson throws FormatException naming the puzzle for wrong grid dimensions', () {
    final tooFewRows = {
      'id': 'bad-rows',
      'tutorial': false,
      'grid': _validGrid.sublist(0, 7),
      'solution': null,
      'note': null,
    };
    expect(
      () => LabyrinthPuzzle.fromJson(tooFewRows),
      throwsA(isA<FormatException>().having(
        (e) => e.message,
        'message',
        contains('bad-rows'),
      )),
    );

    final tooFewCols = {
      'id': 'bad-cols',
      'tutorial': false,
      'grid': [
        'АОДТЧЗУ', // 7 chars instead of 8
        ..._validGrid.sublist(1),
      ],
      'solution': null,
      'note': null,
    };
    expect(
      () => LabyrinthPuzzle.fromJson(tooFewCols),
      throwsA(isA<FormatException>().having(
        (e) => e.message,
        'message',
        contains('bad-cols'),
      )),
    );
  });

  test('fromJson throws FormatException when grid[0][0] is not А', () {
    final grid = List<String>.from(_validGrid);
    grid[0] = 'БОДТЧЗУА'; // corrupt top-left corner
    final json = {
      'id': 'bad-start',
      'tutorial': false,
      'grid': grid,
      'solution': null,
      'note': null,
    };
    expect(
      () => LabyrinthPuzzle.fromJson(json),
      throwsA(isA<FormatException>().having(
        (e) => e.message,
        'message',
        contains('bad-start'),
      )),
    );
  });

  test('fromJson throws FormatException when grid[7][7] is not Я', () {
    final grid = List<String>.from(_validGrid);
    grid[7] = 'ВКЗВЁМХБ'; // corrupt bottom-right corner
    final json = {
      'id': 'bad-end',
      'tutorial': false,
      'grid': grid,
      'solution': null,
      'note': null,
    };
    expect(
      () => LabyrinthPuzzle.fromJson(json),
      throwsA(isA<FormatException>().having(
        (e) => e.message,
        'message',
        contains('bad-end'),
      )),
    );
  });
}
