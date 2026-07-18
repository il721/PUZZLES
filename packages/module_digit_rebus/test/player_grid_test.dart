import 'dart:convert';
import 'dart:io';

import 'package:module_digit_rebus/module_digit_rebus.dart';
import 'package:test/test.dart';

void main() {
  late DigitRebusPuzzle example;

  setUpAll(() {
    final jsonString =
        File('assets/puzzles/module02.json').readAsStringSync();
    example = DigitRebusPuzzle.listFromJsonString(jsonString)
        .singleWhere((p) => p.id == 'example');
  });

  test('fresh grid is empty, not complete, no violations', () {
    final grid = PlayerGrid.fromPuzzle(example);
    expect(grid.isComplete, isFalse);
    expect(grid.wins, isFalse);
    expect(grid.violations().isEmpty, isTrue);
    for (final ref in grid.orderedEditableCells) {
      expect(grid.digitAt(ref), isNull);
    }
    expect(grid.orderedEditableCells, hasLength(16));
  });

  test('setDigit / clearDigit round-trip', () {
    final grid = PlayerGrid.fromPuzzle(example);
    grid.setDigit(const CellRef(1, 2), 3);
    expect(grid.digitAt(const CellRef(1, 2)), 3);
    grid.clearDigit(const CellRef(1, 2));
    expect(grid.digitAt(const CellRef(1, 2)), isNull);
  });

  test('setDigit rejects out-of-range digits', () {
    final grid = PlayerGrid.fromPuzzle(example);
    expect(() => grid.setDigit(const CellRef(0, 0), 10), throwsArgumentError);
    expect(() => grid.setDigit(const CellRef(0, 0), -1), throwsArgumentError);
  });

  test('out-of-grid refs throw', () {
    final grid = PlayerGrid.fromPuzzle(example);
    expect(() => grid.digitAt(const CellRef(4, 0)), throwsArgumentError);
    expect(() => grid.setDigit(const CellRef(0, 4), 1), throwsArgumentError);
    expect(() => grid.clearDigit(const CellRef(-1, 0)), throwsArgumentError);
  });

  test('setDigit does NOT enforce glyph sets — the verifier does', () {
    final grid = PlayerGrid.fromPuzzle(example);
    // (0,0) is G3 {1,4,7}; 5 is outside the set but settable.
    grid.setDigit(const CellRef(0, 0), 5);
    expect(grid.digitAt(const CellRef(0, 0)), 5);
    expect(
      grid.violations().items.single.type,
      ViolationType.glyphSet,
    );
  });

  test('filling the canonical answer wins', () {
    final grid = PlayerGrid.fromPuzzle(example);
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        grid.setDigit(CellRef(r, c), example.answer[r][c]);
      }
    }
    expect(grid.isComplete, isTrue);
    expect(grid.violations().isEmpty, isTrue);
    expect(grid.wins, isTrue);
  });

  test('toJson serializes only filled cells; fromJson restores them', () {
    final grid = PlayerGrid.fromPuzzle(example);
    grid.setDigit(const CellRef(0, 0), 4);
    grid.setDigit(const CellRef(3, 3), 3);
    final json = grid.toJson();
    expect(json, {'0:0': 4, '3:3': 3});

    final restored = PlayerGrid.fromJson(example, json);
    expect(restored.digitAt(const CellRef(0, 0)), 4);
    expect(restored.digitAt(const CellRef(3, 3)), 3);
    expect(restored.digitAt(const CellRef(1, 1)), isNull);
  });

  test('toJsonString round-trips through jsonDecode', () {
    final grid = PlayerGrid.fromPuzzle(example);
    grid.setDigit(const CellRef(2, 1), 2);
    final decoded =
        jsonDecode(grid.toJsonString()) as Map<String, dynamic>;
    final restored = PlayerGrid.fromJson(example, decoded);
    expect(restored.digitAt(const CellRef(2, 1)), 2);
  });

  test('fromJson ignores stale keys and bad values', () {
    final restored = PlayerGrid.fromJson(example, {
      '9:9': 5, // out of grid
      'garbage': 1, // malformed key
      '0:0': 42, // out-of-range digit
      '1:1': 'x', // non-int
      '2:2': 1, // valid
    });
    expect(restored.digitAt(const CellRef(0, 0)), isNull);
    expect(restored.digitAt(const CellRef(1, 1)), isNull);
    expect(restored.digitAt(const CellRef(2, 2)), 1);
  });
}
