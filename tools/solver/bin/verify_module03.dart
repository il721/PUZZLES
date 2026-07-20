import 'dart:io';

import 'package:module_domino/module_domino.dart';

/// Resolves the path to `module03.json`.
///
/// If [args] has a first element, it is used verbatim as the data file
/// path. Otherwise the path is derived from this script's own location
/// (`tools/solver/bin/verify_module03.dart`), so the default works
/// regardless of the working directory the CLI is invoked from.
String _resolveDataPath(List<String> args) {
  if (args.isNotEmpty) {
    return args.first;
  }
  final scriptFile = File.fromUri(Platform.script);
  final binDir = scriptFile.parent;
  return '${binDir.path}/../../../packages/module_domino/assets/puzzles/module03.json';
}

/// Checks the digit-count invariant: each digit 0..6 must appear exactly 8
/// times in a valid 8x7 double-six grid (56 cells / 7 digits). Returns
/// human-readable violations; an empty list means the invariant holds.
List<String> _checkDigitInvariant(List<List<int>> grid) {
  final counts = digitCounts(grid);
  final violations = <String>[];
  for (var digit = 0; digit <= 6; digit++) {
    final count = counts[digit] ?? 0;
    if (count != 8) {
      violations.add('digit $digit appears $count times (expected 8)');
    }
  }
  return violations;
}

/// Validates that [dominoes] forms a complete, valid double-six tiling of
/// [grid]: every cell covered exactly once by an orthogonally-adjacent
/// pair, and the 28 canonicalized value-pairs are exactly the double-six
/// set with no duplicates. Returns human-readable violations; an empty
/// list means the tiling is valid.
List<String> _validateTiling(List<List<int>> grid, List<Domino> dominoes) {
  final violations = <String>[];
  final rows = grid.length;
  final cols = rows == 0 ? 0 : grid[0].length;

  if (dominoes.length != 28) {
    violations.add('expected 28 dominoes, got ${dominoes.length}');
  }

  final covered = <Cell>{};
  final usedPairs = <(int, int)>{};

  for (final domino in dominoes) {
    for (final cell in [domino.a, domino.b]) {
      if (cell.row < 0 ||
          cell.row >= rows ||
          cell.col < 0 ||
          cell.col >= cols) {
        violations.add('cell $cell out of bounds');
        continue;
      }
      if (!covered.add(cell)) {
        violations.add('cell $cell covered more than once');
      }
    }

    final rowDelta = (domino.a.row - domino.b.row).abs();
    final colDelta = (domino.a.col - domino.b.col).abs();
    if (rowDelta + colDelta != 1) {
      violations.add(
        'domino ${domino.a}-${domino.b} is not orthogonally adjacent',
      );
    }

    final va = grid[domino.a.row][domino.a.col];
    final vb = grid[domino.b.row][domino.b.col];
    final pair = va <= vb ? (va, vb) : (vb, va);
    if (!usedPairs.add(pair)) {
      violations.add('value-pair $pair used more than once');
    }
  }

  if (covered.length != rows * cols) {
    violations.add(
      'only ${covered.length} of ${rows * cols} cells covered',
    );
  }

  final expectedPairs = {
    for (var i = 0; i <= 6; i++)
      for (var j = i; j <= 6; j++) (i, j),
  };
  final missing = expectedPairs.difference(usedPairs);
  if (missing.isNotEmpty) {
    violations.add('missing value-pairs: $missing');
  }

  return violations;
}

/// Validates every module-03 puzzle: the grid must satisfy the
/// digit-count invariant, and a value-constrained double-six tiling must
/// exist (ship gate: 0 valid tilings is a hard failure). For `example`,
/// the encoded `solution` is additionally checked as a valid tiling.
Future<void> main(List<String> args) async {
  final dataPath = _resolveDataPath(args);
  final dataFile = File(dataPath);

  if (!dataFile.existsSync()) {
    stderr.writeln('domino_verify: cannot find puzzle data at "$dataPath"');
    exitCode = 1;
    return;
  }

  final puzzles = DominoPuzzle.listFromJsonString(dataFile.readAsStringSync());

  var failures = 0;
  final nonUnique = <String>[];
  final rows = <String>[];

  for (final puzzle in puzzles) {
    final digitViolations = _checkDigitInvariant(puzzle.grid);
    final digitOk = digitViolations.isEmpty;

    final solutionCount = countSolutions(puzzle.grid, cap: 2);
    final solution = firstSolution(puzzle.grid);

    final notes = <String>[];

    if (!digitOk) {
      failures++;
      print('${puzzle.id}: HARD FAIL - digit-count invariant violated');
      for (final v in digitViolations) {
        print('  - $v');
      }
    }

    if (solutionCount == 0) {
      failures++;
      notes.add('HARD FAIL: no valid tiling exists');
    } else if (solutionCount >= 2) {
      nonUnique.add(puzzle.id);
      notes.add('non-unique (>= 2)');
    }

    if (puzzle.id == 'example') {
      final storedSolution = puzzle.solution;
      if (storedSolution == null) {
        failures++;
        notes.add('HARD FAIL: example has no stored solution');
      } else {
        final tilingViolations = _validateTiling(puzzle.grid, storedSolution);
        if (tilingViolations.isEmpty) {
          notes.add('stored solution: valid tiling');
        } else {
          failures++;
          notes.add('HARD FAIL: stored solution invalid');
          for (final v in tilingViolations) {
            print('  - example stored solution: $v');
          }
        }
      }
      if (solution == null) {
        failures++;
        notes.add('HARD FAIL: solver found no tiling to cross-check');
      }
    }

    if (puzzle.note != null) {
      notes.add('data note: ${puzzle.note}');
    }

    final countLabel = solutionCount >= 2 ? '>=2' : '$solutionCount';
    rows.add(
      '${puzzle.id.padRight(8)} | digit-invariant: ${digitOk ? 'OK  ' : 'FAIL'} | '
      '#solutions: ${countLabel.padRight(3)} | '
      '${notes.isEmpty ? '-' : notes.join('; ')}',
    );
  }

  print('id       | digit-invariant | #solutions | notes');
  print('-' * 70);
  for (final row in rows) {
    print(row);
  }
  print('-' * 70);

  if (nonUnique.isNotEmpty) {
    print(
      'Non-unique puzzles (multiple valid tilings, allowed - constraint-'
      'satisfaction win rule applies): ${nonUnique.join(', ')}',
    );
  }

  if (failures == 0) {
    print('ALL CHECKS PASSED');
    exitCode = 0;
  } else {
    print('FAILURES: $failures');
    exitCode = 1;
  }
}
