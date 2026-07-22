import 'dart:io';

import 'package:module_labyrinth/module_labyrinth.dart';
import 'package:test/test.dart';

void main() {
  late LabyrinthPuzzle example;

  setUpAll(() {
    final jsonString =
        File('assets/puzzles/module04.json').readAsStringSync();
    example = LabyrinthPuzzle.listFromJsonString(jsonString)
        .singleWhere((p) => p.id == 'example');
  });

  /// Taps every cell of [cells] in order onto [board], for building up a
  /// custom chain via the state machine under test.
  void tapAll(LabyrinthBoard board, Iterable<Cell> cells) {
    for (final c in cells) {
      board.tap(c);
    }
  }

  test('fresh board has two anchors, is not joined, 2 cells placed', () {
    final board = LabyrinthBoard.fromPuzzle(example);
    expect(board.chainA, [const Cell(0, 0)]);
    expect(board.chainZ, [const Cell(7, 7)]);
    expect(board.headA, const Cell(0, 0));
    expect(board.headZ, const Cell(7, 7));
    expect(board.isJoined, isFalse);
    expect(board.manualCrosses, isEmpty);

    final status = board.status();
    expect(status.placedCount, 2);
    expect(status.pathCells, [const Cell(0, 0), const Cell(7, 7)]);
    expect(status.isSolved, isFalse);
  });

  test('tap adjacent cell extends chainA from headA', () {
    final board = LabyrinthBoard.fromPuzzle(example);
    board.tap(const Cell(1, 0));
    expect(board.chainA, [const Cell(0, 0), const Cell(1, 0)]);
    expect(board.headA, const Cell(1, 0));
    expect(board.chainZ, [const Cell(7, 7)]);
  });

  test('tap adjacent cell extends chainZ from headZ', () {
    final board = LabyrinthBoard.fromPuzzle(example);
    board.tap(const Cell(7, 6));
    expect(board.chainZ, [const Cell(7, 7), const Cell(7, 6)]);
    expect(board.headZ, const Cell(7, 6));
    expect(board.chainA, [const Cell(0, 0)]);
  });

  test('tapping the current head retracts that chain by one', () {
    final board = LabyrinthBoard.fromPuzzle(example);
    board.tap(const Cell(1, 0));
    board.tap(const Cell(2, 0));
    expect(board.chainA, hasLength(3));

    board.tap(const Cell(2, 0)); // tap the current head
    expect(board.chainA, [const Cell(0, 0), const Cell(1, 0)]);
    expect(board.headA, const Cell(1, 0));
  });

  test('anchor cells can never be retracted away', () {
    final board = LabyrinthBoard.fromPuzzle(example);
    board.tap(const Cell(0, 0)); // tap the anchor itself, length 1
    expect(board.chainA, [const Cell(0, 0)]);
    board.tap(const Cell(7, 7));
    expect(board.chainZ, [const Cell(7, 7)]);
  });

  test('extension rejected onto a cell already occupied by the same chain',
      () {
    final board = LabyrinthBoard.fromPuzzle(example);
    tapAll(board, [const Cell(1, 0), const Cell(2, 0)]);
    board.tap(const Cell(1, 0)); // occupied, not the head -> no-op
    expect(board.chainA, [
      const Cell(0, 0),
      const Cell(1, 0),
      const Cell(2, 0),
    ]);
  });

  test('extension rejected onto a non-adjacent cell', () {
    final board = LabyrinthBoard.fromPuzzle(example);
    board.tap(const Cell(4, 4)); // not adjacent to headA (0,0)
    expect(board.chainA, [const Cell(0, 0)]);
    expect(board.chainZ, [const Cell(7, 7)]);
  });

  test('extension rejected onto an out-of-bounds cell', () {
    final board = LabyrinthBoard.fromPuzzle(example);
    board.tap(const Cell(-1, 0));
    board.tap(const Cell(0, 8));
    expect(board.chainA, [const Cell(0, 0)]);
  });

  test('a cell adjacent to both heads prefers chainA (tie-break)', () {
    final board = LabyrinthBoard.fromPuzzle(example);
    // Grow chainA to headA = (2,2).
    tapAll(board, [
      const Cell(0, 1),
      const Cell(0, 2),
      const Cell(1, 2),
      const Cell(2, 2),
    ]);
    // Grow chainZ to headZ = (2,4), staying clear of chainA's cells.
    tapAll(board, [
      const Cell(6, 7),
      const Cell(5, 7),
      const Cell(4, 7),
      const Cell(3, 7),
      const Cell(2, 7),
      const Cell(2, 6),
      const Cell(2, 5),
      const Cell(2, 4),
    ]);
    expect(board.headA, const Cell(2, 2));
    expect(board.headZ, const Cell(2, 4));

    board.tap(const Cell(2, 3)); // adjacent to both heads
    expect(board.headA, const Cell(2, 3));
    expect(board.headZ, const Cell(2, 4)); // chainZ untouched
  });

  test('join detection, join is terminal, and retraction un-joins', () {
    final board = LabyrinthBoard.fromPuzzle(example);
    // Grow chainA down column 0 then along row 7 to (7,6), which is
    // adjacent to the untouched headZ (7,7).
    tapAll(board, [
      const Cell(1, 0),
      const Cell(2, 0),
      const Cell(3, 0),
      const Cell(4, 0),
      const Cell(5, 0),
      const Cell(6, 0),
      const Cell(7, 0),
      const Cell(7, 1),
      const Cell(7, 2),
      const Cell(7, 3),
      const Cell(7, 4),
      const Cell(7, 5),
      const Cell(7, 6),
    ]);
    expect(board.headA, const Cell(7, 6));
    expect(board.isJoined, isTrue);

    final chainALengthAtJoin = board.chainA.length;
    board.tap(const Cell(6, 6)); // adjacent to headA, but join is terminal
    expect(board.chainA, hasLength(chainALengthAtJoin));
    expect(board.isJoined, isTrue);

    board.tap(board.headA); // retract; un-joins
    expect(board.isJoined, isFalse);
    expect(board.headA, const Cell(7, 5));
  });

  test('long-press on a path cell truncates that chain to just before it',
      () {
    final board = LabyrinthBoard.fromPuzzle(example);
    tapAll(board, [
      const Cell(1, 0),
      const Cell(2, 0),
      const Cell(3, 0),
    ]);
    board.longPress(const Cell(1, 0)); // index 1
    // Long-press retracts to just BEFORE the pressed cell, so Cell(1, 0)
    // itself is removed along with everything after it.
    expect(board.chainA, [const Cell(0, 0)]);

    // Long-pressing an anchor is a no-op: it is neither retractable nor a
    // legal place for a manual cross.
    board.longPress(const Cell(0, 0));
    expect(board.chainA, [const Cell(0, 0)]);
    expect(board.manualCrosses, isEmpty);
  });

  test('long-press elsewhere toggles a manual cross', () {
    final board = LabyrinthBoard.fromPuzzle(example);
    board.longPress(const Cell(4, 4));
    expect(board.manualCrosses, {const Cell(4, 4)});
    board.longPress(const Cell(4, 4));
    expect(board.manualCrosses, isEmpty);
  });

  test(
      'extending onto a manually crossed cell clears it, and retraction '
      'does not restore it', () {
    final board = LabyrinthBoard.fromPuzzle(example);
    board.longPress(const Cell(1, 0));
    expect(board.manualCrosses, {const Cell(1, 0)});

    board.tap(const Cell(1, 0)); // extends chainA onto the crossed cell
    expect(board.chainA, [const Cell(0, 0), const Cell(1, 0)]);
    expect(board.manualCrosses, isEmpty);

    board.tap(const Cell(1, 0)); // retract
    expect(board.chainA, [const Cell(0, 0)]);
    expect(board.manualCrosses, isEmpty); // not restored
  });

  test('manual crosses survive retraction and auto-cross churn elsewhere',
      () {
    final board = LabyrinthBoard.fromPuzzle(example);
    board.longPress(const Cell(5, 5)); // unrelated cell
    expect(board.manualCrosses, {const Cell(5, 5)});

    tapAll(board, [const Cell(1, 0), const Cell(2, 0)]);
    board.tap(const Cell(2, 0)); // retract
    board.tap(const Cell(1, 0)); // retract to anchor
    expect(board.chainA, [const Cell(0, 0)]);
    expect(board.manualCrosses, {const Cell(5, 5)});
  });

  test('autoCrosses derive correctly and disappear when the letter leaves '
      'the path', () {
    // The example grid places 'Ю' at both (1,7) and (2,0).
    expect(example.letterAt(const Cell(1, 7)), 'Ю');
    expect(example.letterAt(const Cell(2, 0)), 'Ю');

    final board = LabyrinthBoard.fromPuzzle(example);
    expect(board.autoCrosses, isNot(contains(const Cell(1, 7))));

    tapAll(board, [const Cell(1, 0), const Cell(2, 0)]);
    expect(board.headA, const Cell(2, 0));
    expect(board.autoCrosses, contains(const Cell(1, 7)));
    // The letter-bearing cell itself is on the path, so it is excluded.
    expect(board.autoCrosses, isNot(contains(const Cell(2, 0))));

    board.tap(const Cell(2, 0)); // retract, letter leaves the path
    expect(board.autoCrosses, isNot(contains(const Cell(1, 7))));
  });

  test('duplicate and missing letter reporting', () {
    final board = LabyrinthBoard.fromPuzzle(example);
    // Row 0 of the example grid is "АОДТЧЗУА": walking it end to end
    // revisits the letter 'А' at both ends.
    tapAll(board, [
      const Cell(0, 1),
      const Cell(0, 2),
      const Cell(0, 3),
      const Cell(0, 4),
      const Cell(0, 5),
      const Cell(0, 6),
      const Cell(0, 7),
    ]);
    final status = board.status();
    expect(status.duplicateLetters, contains('А'));
    expect(status.usedLetters, contains('А'));
    expect(status.missingLetters, contains('Б')); // never placed
    expect(status.isSolved, isFalse);
  });

  test('isSolved is true for the example solution replayed through tap',
      () {
    final board = LabyrinthBoard.fromPuzzle(example);
    final solution = example.solution!;
    // Indices 0 and 32 are already the chainA/chainZ anchors; tap the
    // interior of the path in order onto chainA.
    tapAll(board, solution.sublist(1, solution.length - 1));

    final status = board.status();
    expect(status.isJoined, isTrue);
    expect(status.placedCount, LabyrinthPuzzle.pathLength);
    expect(status.duplicateLetters, isEmpty);
    expect(status.missingLetters, isEmpty);
    expect(status.isSolved, isTrue);
  });

  test('isSolved is false for a joined-but-short path', () {
    final board = LabyrinthBoard.fromPuzzle(example);
    tapAll(board, [
      const Cell(1, 0),
      const Cell(2, 0),
      const Cell(3, 0),
      const Cell(4, 0),
      const Cell(5, 0),
      const Cell(6, 0),
      const Cell(7, 0),
      const Cell(7, 1),
      const Cell(7, 2),
      const Cell(7, 3),
      const Cell(7, 4),
      const Cell(7, 5),
      const Cell(7, 6),
    ]);
    final status = board.status();
    expect(status.isJoined, isTrue);
    expect(status.placedCount, lessThan(LabyrinthPuzzle.pathLength));
    expect(status.isSolved, isFalse);
  });

  test('toJson -> fromJson round-trips chains and manual crosses', () {
    final board = LabyrinthBoard.fromPuzzle(example);
    tapAll(board, [const Cell(1, 0), const Cell(2, 0)]);
    tapAll(board, [const Cell(7, 6), const Cell(7, 5)]);
    board.longPress(const Cell(4, 4));

    final json = board.toJson();
    final restored = LabyrinthBoard.fromJson(example, json);
    expect(restored.chainA, board.chainA);
    expect(restored.chainZ, board.chainZ);
    expect(restored.manualCrosses, board.manualCrosses);
  });

  group('fromJson falls back to the initial state for malformed saves', () {
    void expectFallback(Map<String, dynamic> json) {
      final board = LabyrinthBoard.fromJson(example, json);
      expect(board.chainA, [const Cell(0, 0)]);
      expect(board.chainZ, [const Cell(7, 7)]);
      expect(board.manualCrosses, isEmpty);
    }

    test('wrong chainA anchor', () {
      expectFallback({
        'chainA': [
          [1, 1],
        ],
        'chainZ': [
          [7, 7],
        ],
        'crosses': [],
      });
    });

    test('wrong chainZ anchor', () {
      expectFallback({
        'chainA': [
          [0, 0],
        ],
        'chainZ': [
          [6, 6],
        ],
        'crosses': [],
      });
    });

    test('non-adjacent consecutive cells within a chain', () {
      expectFallback({
        'chainA': [
          [0, 0],
          [0, 2], // skips (0,1)
        ],
        'chainZ': [
          [7, 7],
        ],
        'crosses': [],
      });
    });

    test('out-of-bounds cell in a chain', () {
      expectFallback({
        'chainA': [
          [0, 0],
          [0, 8], // column 8 is out of bounds
        ],
        'chainZ': [
          [7, 7],
        ],
        'crosses': [],
      });
    });

    test('out-of-bounds cell in crosses', () {
      expectFallback({
        'chainA': [
          [0, 0],
        ],
        'chainZ': [
          [7, 7],
        ],
        'crosses': [
          [8, 8],
        ],
      });
    });

    test('overlapping chains', () {
      expectFallback({
        'chainA': [
          [0, 0],
          [1, 0],
        ],
        'chainZ': [
          [7, 7],
          [6, 7],
          [6, 6],
          [6, 5],
          [6, 4],
          [6, 3],
          [6, 2],
          [6, 1],
          [6, 0],
          [5, 0],
          [4, 0],
          [3, 0],
          [2, 0],
          [1, 0], // shared with chainA
        ],
        'crosses': [],
      });
    });

    test('over-length (combined chains exceed pathLength)', () {
      expectFallback({
        'chainA': [
          [0, 0], [0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7],
          [1, 7], [1, 6], [1, 5], [1, 4], [1, 3], [1, 2], [1, 1], [1, 0],
          [2, 0], [2, 1], [2, 2], [2, 3],
        ], // 20 cells
        'chainZ': [
          [7, 7], [7, 6], [7, 5], [7, 4], [7, 3], [7, 2], [7, 1], [7, 0],
          [6, 0], [6, 1], [6, 2], [6, 3], [6, 4], [6, 5],
        ], // 14 cells; 20 + 14 = 34 > 33
        'crosses': [],
      });
    });

    test('malformed JSON shape (non-int coordinates)', () {
      expectFallback({
        'chainA': [
          [0, 0],
          ['x', 'y'],
        ],
        'chainZ': [
          [7, 7],
        ],
        'crosses': [],
      });
    });

    test('missing field entirely', () {
      expectFallback({
        'chainZ': [
          [7, 7],
        ],
        'crosses': [],
      });
    });
  });
}
