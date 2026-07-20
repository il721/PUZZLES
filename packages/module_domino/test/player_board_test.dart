import 'dart:convert';
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

  test('fresh board is empty, not covered, no pending', () {
    final board = PlayerBoard.fromPuzzle(example);
    expect(board.placed, isEmpty);
    expect(board.pending, isNull);
    expect(board.isCovered(const Cell(0, 0)), isFalse);
    expect(board.dominoAt(const Cell(0, 0)), isNull);
    expect(board.wins, isFalse);
  });

  test('tap two adjacent uncovered cells places one domino', () {
    final board = PlayerBoard.fromPuzzle(example);
    board.tap(const Cell(0, 0));
    expect(board.pending, const Cell(0, 0));
    board.tap(const Cell(0, 1));
    expect(board.placed, hasLength(1));
    expect(board.placed.single, Domino(const Cell(0, 0), const Cell(0, 1)));
    expect(board.pending, isNull);
    expect(board.isCovered(const Cell(0, 0)), isTrue);
    expect(board.isCovered(const Cell(0, 1)), isTrue);
  });

  test('tap a covered cell splits the domino and clears pending', () {
    final board = PlayerBoard.fromPuzzle(example);
    board.tap(const Cell(0, 0));
    board.tap(const Cell(0, 1));
    expect(board.placed, hasLength(1));

    board.tap(const Cell(0, 1)); // split via the other half of the domino
    expect(board.placed, isEmpty);
    expect(board.pending, isNull);
    expect(board.isCovered(const Cell(0, 0)), isFalse);
    expect(board.isCovered(const Cell(0, 1)), isFalse);
  });

  test('split takes priority even with an unrelated pending selection', () {
    final board = PlayerBoard.fromPuzzle(example);
    board.tap(const Cell(0, 0));
    board.tap(const Cell(0, 1)); // places domino (0,0)-(0,1)
    board.tap(const Cell(5, 5)); // new pending, elsewhere
    expect(board.pending, const Cell(5, 5));

    board.tap(const Cell(0, 0)); // tap a covered cell -> split
    expect(board.placed, isEmpty);
    expect(board.pending, isNull);
  });

  test('tap the same uncovered cell twice deselects, places nothing', () {
    final board = PlayerBoard.fromPuzzle(example);
    board.tap(const Cell(2, 2));
    expect(board.pending, const Cell(2, 2));
    board.tap(const Cell(2, 2));
    expect(board.pending, isNull);
    expect(board.placed, isEmpty);
  });

  test('tap a non-adjacent uncovered cell moves pending, places nothing',
      () {
    final board = PlayerBoard.fromPuzzle(example);
    board.tap(const Cell(0, 0));
    board.tap(const Cell(4, 4)); // not adjacent to (0,0)
    expect(board.pending, const Cell(4, 4));
    expect(board.placed, isEmpty);
  });

  test('reset clears placed dominoes and pending selection', () {
    final board = PlayerBoard.fromPuzzle(example);
    board.tap(const Cell(0, 0));
    board.tap(const Cell(0, 1));
    board.tap(const Cell(2, 2));
    board.reset();
    expect(board.placed, isEmpty);
    expect(board.pending, isNull);
  });

  test('tap throws ArgumentError for out-of-range cells', () {
    final board = PlayerBoard.fromPuzzle(example);
    expect(() => board.tap(const Cell(8, 0)), throwsArgumentError);
    expect(() => board.tap(const Cell(0, 7)), throwsArgumentError);
    expect(() => board.tap(const Cell(-1, 0)), throwsArgumentError);
  });

  test('fromJson restores only valid, in-range, non-overlapping dominoes',
      () {
    final placedJson = [
      [
        [0, 0],
        [0, 1],
      ], // valid
      [
        [3, 3],
        [5, 5],
      ], // not adjacent -> skipped
      [
        [8, 0],
        [8, 1],
      ], // out of range (row 8) -> skipped
      [
        [0, 1],
        [0, 2],
      ], // overlaps (0,1), already covered by the valid entry -> skipped
    ];
    final board = PlayerBoard.fromJson(example, placedJson);
    expect(board.placed, hasLength(1));
    expect(board.placed.single, Domino(const Cell(0, 0), const Cell(0, 1)));
    expect(board.pending, isNull);
  });

  test('toJson -> fromJson round-trips the placed set', () {
    final board = PlayerBoard.fromPuzzle(example);
    board.tap(const Cell(0, 0));
    board.tap(const Cell(0, 1));
    board.tap(const Cell(3, 3));
    board.tap(const Cell(4, 3));

    final json = board.toJson();
    final restored = PlayerBoard.fromJson(example, json);
    expect(restored.placed.toSet(), board.placed.toSet());
  });

  test('toJsonString round-trips through jsonDecode', () {
    final board = PlayerBoard.fromPuzzle(example);
    board.tap(const Cell(1, 1));
    board.tap(const Cell(1, 2));

    final decoded = jsonDecode(board.toJsonString()) as List<dynamic>;
    final restored = PlayerBoard.fromJson(example, decoded);
    expect(restored.placed.toSet(), board.placed.toSet());
  });

  test('playing the example full solution via taps wins', () {
    final board = PlayerBoard.fromPuzzle(example);
    for (final d in example.solution!) {
      board.tap(d.a);
      board.tap(d.b);
    }
    expect(board.placed, hasLength(28));
    expect(board.pending, isNull);
    expect(board.wins, isTrue);
  });
}
