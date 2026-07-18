import 'dart:io';

import 'package:module_digit_rebus/module_digit_rebus.dart';
import 'package:test/test.dart';

void main() {
  late DigitRebusPuzzle example;
  late DigitRebusPuzzle p01;

  setUpAll(() {
    final jsonString =
        File('assets/puzzles/module02.json').readAsStringSync();
    final puzzles = DigitRebusPuzzle.listFromJsonString(jsonString);
    example = puzzles.singleWhere((p) => p.id == 'example');
    p01 = puzzles.singleWhere((p) => p.id == 'p01');
  });

  List<List<int?>> emptyCells() =>
      List.generate(4, (_) => List<int?>.filled(4, null));

  List<List<int?>> answerCells(DigitRebusPuzzle p) => [
        for (var r = 0; r < 4; r++) [for (var c = 0; c < 4; c++) p.answer[r][c]],
      ];

  group('scope rule', () {
    test('empty grid has no violations', () {
      expect(verifyGrid(example, emptyCells()).isEmpty, isTrue);
    });

    test('partial row produces no equation violation even if unsatisfiable',
        () {
      // Example row 0 is 4+8:6=2. Put 3 wrong-leaning digits but leave the
      // result empty: no rowEquation may fire.
      final cells = emptyCells();
      cells[0][0] = 4;
      cells[0][1] = 8;
      cells[0][2] = 8; // wrong, but row incomplete
      final violations = verifyGrid(example, cells);
      expect(
        violations.items.where((v) => v.type == ViolationType.rowEquation),
        isEmpty,
      );
    });

    test('partial column produces no equation violation', () {
      final cells = emptyCells();
      cells[0][0] = 4;
      cells[1][0] = 7; // col 0 incomplete
      final violations = verifyGrid(example, cells);
      expect(
        violations.items.where((v) => v.type == ViolationType.columnEquation),
        isEmpty,
      );
    });

    test('completed wrong row fires rowEquation with all 4 cells', () {
      // Example row 2 is 3+2+1=6; fill 3+2+1=2 (2 is in G2? no — use a
      // glyph-legal wrong digit: G2 {0,6,8} -> 0).
      final cells = emptyCells();
      cells[2][0] = 3;
      cells[2][1] = 2;
      cells[2][2] = 1;
      cells[2][3] = 0; // in G2 set, equation false
      final violations = verifyGrid(example, cells);
      final rowViolations =
          violations.items.where((v) => v.type == ViolationType.rowEquation);
      expect(rowViolations, hasLength(1));
      expect(rowViolations.single.row, 2);
      expect(rowViolations.single.cells, hasLength(4));
      expect(
        violations.items.where((v) => v.type == ViolationType.glyphSet),
        isEmpty,
      );
    });

    test('completed wrong column fires columnEquation', () {
      // Example col 2 is 6-3-1=2; fill 6-3-3=2 (3 in G3? G3 {1,4,7} — use
      // canonical digits but wrong result cell instead: 6-3-1=3, 3 in G4.
      final cells = emptyCells();
      cells[0][2] = 6;
      cells[1][2] = 3;
      cells[2][2] = 1;
      cells[3][2] = 3; // in G4 {2,3}, equation false (should be 2)
      final violations = verifyGrid(example, cells);
      final colViolations = violations.items
          .where((v) => v.type == ViolationType.columnEquation);
      expect(colViolations, hasLength(1));
      expect(colViolations.single.column, 2);
    });
  });

  group('null-tolerant evaluation', () {
    test('division by zero in a filled row is a violation, not a crash', () {
      // Example row 0 ops are + then : — make the divisor 0.
      final cells = emptyCells();
      cells[0][0] = 4;
      cells[0][1] = 8;
      cells[0][2] = 0; // divisor 0 -> eval null
      cells[0][3] = 2;
      final violations = verifyGrid(example, cells);
      expect(
        violations.items.where((v) => v.type == ViolationType.rowEquation),
        hasLength(1),
      );
    });

    test('negative intermediate in a filled column is a violation', () {
      // Example col 0 ops are - then *: 1-4 goes negative.
      final cells = emptyCells();
      cells[0][0] = 1;
      cells[1][0] = 4;
      cells[2][0] = 3;
      cells[3][0] = 9;
      final violations = verifyGrid(example, cells);
      expect(
        violations.items.where((v) => v.type == ViolationType.columnEquation),
        isNotEmpty,
      );
    });
  });

  group('glyph-set membership', () {
    test('flags a single filled cell outside its glyph set immediately', () {
      // Example cell (0,0) is G3 {1,4,7} — put a 5.
      final cells = emptyCells();
      cells[0][0] = 5;
      final violations = verifyGrid(example, cells);
      expect(violations.items, hasLength(1));
      final v = violations.items.single;
      expect(v.type, ViolationType.glyphSet);
      expect(v.row, 0);
      expect(v.column, 0);
      expect(v.cells, [const CellRef(0, 0)]);
      expect(violations.involves(const CellRef(0, 0)), isTrue);
    });

    test('0 is legal where the glyph permits it (no badNumber rule)', () {
      // Find a G1 or G2 cell in the example and fill 0 there.
      var found = false;
      final cells = emptyCells();
      outer:
      for (var r = 0; r < 4; r++) {
        for (var c = 0; c < 4; c++) {
          if (example.glyphs[r][c].digits.contains(0)) {
            cells[r][c] = 0;
            found = true;
            break outer;
          }
        }
      }
      expect(found, isTrue, reason: 'example must contain a 0-capable glyph');
      expect(verifyGrid(example, cells).isEmpty, isTrue);
    });
  });

  group('full-grid verdicts', () {
    test('canonical answer of every puzzle has no violations', () {
      final jsonString =
          File('assets/puzzles/module02.json').readAsStringSync();
      for (final p in DigitRebusPuzzle.listFromJsonString(jsonString)) {
        expect(verifyGrid(p, answerCells(p)).isEmpty, isTrue, reason: p.id);
      }
    });

    test('one wrong digit in a full grid produces violations', () {
      final cells = answerCells(p01);
      // Flip cell (0,0) to another digit in the same glyph set so only
      // equations can complain.
      final glyph = p01.glyphs[0][0];
      final wrong =
          glyph.digits.firstWhere((d) => d != p01.answer[0][0]);
      cells[0][0] = wrong;
      expect(verifyGrid(p01, cells).isNotEmpty, isTrue);
    });
  });
}
