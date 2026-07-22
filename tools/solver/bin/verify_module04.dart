import 'dart:io';

import 'package:module_labyrinth/module_labyrinth.dart';

/// Resolves the path to `module04.json`.
///
/// If [args] has a first element, it is used verbatim as the data file
/// path. Otherwise the path is derived from this script's own location
/// (`tools/solver/bin/verify_module04.dart`), so the default works
/// regardless of the working directory the CLI is invoked from.
String _resolveDataPath(List<String> args) {
  if (args.isNotEmpty) {
    return args.first;
  }
  final scriptFile = File.fromUri(Platform.script);
  final binDir = scriptFile.parent;
  return '${binDir.path}/../../../packages/module_labyrinth/assets/puzzles/module04.json';
}

/// Checks the book's construction invariant for an alphabet-labyrinth
/// grid: 64 cells total, `grid[0][0] == 'А'`, `grid[7][7] == 'Я'`, all 33
/// Russian alphabet letters present, exactly 31 of them occurring exactly
/// twice and exactly 2 occurring exactly once (no letter outside that
/// 1-or-2 range, and no non-alphabet character). Returns human-readable
/// violations; an empty list means the invariant holds.
List<String> _checkConstructionInvariant(LabyrinthPuzzle puzzle) {
  final violations = <String>[];
  final grid = puzzle.grid;

  if (grid.length != LabyrinthPuzzle.rows) {
    violations.add(
      'grid has ${grid.length} rows, expected ${LabyrinthPuzzle.rows}',
    );
  }

  var cellCount = 0;
  for (final row in grid) {
    cellCount += row.length;
  }
  final expectedCells = LabyrinthPuzzle.rows * LabyrinthPuzzle.cols;
  if (cellCount != expectedCells) {
    violations.add('grid has $cellCount cells, expected $expectedCells');
  }

  if (grid.isNotEmpty && grid[0].isNotEmpty && grid[0][0] != 'А') {
    violations.add('grid[0][0] is "${grid[0][0]}", expected "А"');
  }
  if (grid.length == LabyrinthPuzzle.rows &&
      grid.last.length == LabyrinthPuzzle.cols) {
    final last = grid[LabyrinthPuzzle.rows - 1][LabyrinthPuzzle.cols - 1];
    if (last != 'Я') {
      violations.add('grid[7][7] is "$last", expected "Я"');
    }
  }

  final counts = <String, int>{};
  for (final row in grid) {
    for (final letter in row) {
      counts[letter] = (counts[letter] ?? 0) + 1;
    }
  }

  final missing = russianAlphabet.where((l) => !counts.containsKey(l)).toList();
  if (missing.isNotEmpty) {
    violations.add('missing alphabet letters: ${missing.join(', ')}');
  }

  final unexpected =
      counts.keys.where((l) => !russianAlphabet.contains(l)).toList();
  if (unexpected.isNotEmpty) {
    violations.add('non-alphabet characters present: ${unexpected.join(', ')}');
  }

  final twiceCount = counts.values.where((c) => c == 2).length;
  final onceCount = counts.values.where((c) => c == 1).length;
  final otherEntries =
      counts.entries.where((e) => e.value != 1 && e.value != 2).toList();

  if (twiceCount != 31) {
    violations.add('$twiceCount letters occur exactly twice, expected 31');
  }
  if (onceCount != 2) {
    violations.add('$onceCount letters occur exactly once, expected 2');
  }
  for (final e in otherEntries) {
    violations.add('letter "${e.key}" occurs ${e.value} times (expected 1 or 2)');
  }

  return violations;
}

/// Validates a candidate solution path independently of the solver: exactly
/// [LabyrinthPuzzle.pathLength] cells, starting at `Cell(0, 0)` and ending
/// at `Cell(7, 7)`, all cells distinct and in bounds, every consecutive
/// pair orthogonally adjacent, and the letters visited are exactly the 33
/// Russian alphabet letters, each once. Returns human-readable violations;
/// an empty list means the path is valid.
List<String> _validatePath(LabyrinthPuzzle puzzle, List<Cell> path) {
  final violations = <String>[];
  const start = Cell(0, 0);
  const target = Cell(7, 7);

  if (path.length != LabyrinthPuzzle.pathLength) {
    violations.add(
      'path has ${path.length} cells, expected ${LabyrinthPuzzle.pathLength}',
    );
  }
  if (path.isEmpty || path.first != start) {
    violations.add('path does not start at $start');
  }
  if (path.isEmpty || path.last != target) {
    violations.add('path does not end at $target');
  }

  final seenCells = <Cell>{};
  final inBoundsCells = <Cell>[];
  for (final cell in path) {
    if (cell.row < 0 ||
        cell.row >= LabyrinthPuzzle.rows ||
        cell.col < 0 ||
        cell.col >= LabyrinthPuzzle.cols) {
      violations.add('cell $cell out of bounds');
      continue;
    }
    inBoundsCells.add(cell);
    if (!seenCells.add(cell)) {
      violations.add('cell $cell visited more than once');
    }
  }

  for (var i = 1; i < path.length; i++) {
    final a = path[i - 1];
    final b = path[i];
    final delta = (a.row - b.row).abs() + (a.col - b.col).abs();
    if (delta != 1) {
      violations.add('cells $a and $b are not orthogonally adjacent');
    }
  }

  final letters = inBoundsCells.map((c) => puzzle.grid[c.row][c.col]).toList();
  final letterSet = letters.toSet();
  if (letterSet.length != letters.length) {
    violations.add('path letters are not all distinct');
  }

  final alphabetSet = russianAlphabet.toSet();
  if (!(letterSet.length == alphabetSet.length &&
      letterSet.containsAll(alphabetSet))) {
    final missing = alphabetSet.difference(letterSet);
    final extra = letterSet.difference(alphabetSet);
    violations.add(
      'path letters do not match the full alphabet '
      '(missing: ${missing.isEmpty ? '-' : missing.join(', ')}, '
      'extra: ${extra.isEmpty ? '-' : extra.join(', ')})',
    );
  }

  return violations;
}

/// Validates every module-04 puzzle: the grid must satisfy the
/// construction invariant, and a self-avoiding А-to-Я path visiting all 33
/// letters must exist (ship gate: zero valid paths is a hard failure; a
/// search timeout is inconclusive, not a failure). Any path found - by the
/// solver, or stored in the data as the book's printed `solution` - is
/// independently re-validated rather than trusted from the solver.
Future<void> main(List<String> args) async {
  final dataPath = _resolveDataPath(args);
  final dataFile = File(dataPath);

  if (!dataFile.existsSync()) {
    stderr.writeln('labyrinth_verify: cannot find puzzle data at "$dataPath"');
    exitCode = 1;
    return;
  }

  final puzzles =
      LabyrinthPuzzle.listFromJsonString(dataFile.readAsStringSync());

  var hardFailures = 0;
  final hardFailIds = <String>{};
  final nonUnique = <String>[];
  final timeouts = <String>[];
  final rows = <String>[];
  final solutionPaths = <String, List<Cell>>{};

  for (final puzzle in puzzles) {
    final invariantViolations = _checkConstructionInvariant(puzzle);
    final invariantOk = invariantViolations.isEmpty;
    if (!invariantOk) {
      hardFailures++;
      hardFailIds.add(puzzle.id);
      print('${puzzle.id}: HARD FAIL - construction invariant violated');
      for (final v in invariantViolations) {
        print('  - $v');
      }
    }

    final result = solveLabyrinth(
      puzzle,
      cap: 2,
      timeout: const Duration(seconds: 120),
    );

    final notes = <String>[];
    String statusLabel;
    String countLabel;

    switch (result.status) {
      case LabyrinthSolveStatus.zero:
        hardFailures++;
        hardFailIds.add(puzzle.id);
        statusLabel = 'HARD FAIL';
        countLabel = '0';
        notes.add('HARD FAIL: no valid path exists');
        break;
      case LabyrinthSolveStatus.unique:
        statusLabel = 'OK';
        countLabel = '1';
        break;
      case LabyrinthSolveStatus.multiple:
        statusLabel = 'OK';
        countLabel = '>=2';
        nonUnique.add(puzzle.id);
        notes.add('non-unique (>= 2)');
        break;
      case LabyrinthSolveStatus.timeout:
        timeouts.add(puzzle.id);
        statusLabel = 'TIMEOUT';
        countLabel = 'n/a';
        notes.add(
          'INCONCLUSIVE: search timed out (not a transcription failure)',
        );
        break;
    }

    if (result.path != null) {
      final pathViolations = _validatePath(puzzle, result.path!);
      if (pathViolations.isEmpty) {
        notes.add('solver path: valid');
        solutionPaths[puzzle.id] = result.path!;
      } else {
        hardFailures++;
        hardFailIds.add(puzzle.id);
        notes.add('HARD FAIL: solver path invalid');
        print('${puzzle.id}: HARD FAIL - solver path invalid');
        for (final v in pathViolations) {
          print('  - $v');
        }
      }
    }

    final storedSolution = puzzle.solution;
    if (storedSolution != null) {
      final storedViolations = _validatePath(puzzle, storedSolution);
      if (storedViolations.isEmpty) {
        notes.add('stored solution: valid');
      } else {
        hardFailures++;
        hardFailIds.add(puzzle.id);
        notes.add('HARD FAIL: stored solution invalid');
        print('${puzzle.id}: HARD FAIL - stored solution invalid');
        for (final v in storedViolations) {
          print('  - $v');
        }
      }
    }

    if (puzzle.note != null) {
      notes.add('data note: ${puzzle.note}');
    }

    rows.add(
      '${puzzle.id.padRight(8)} | invariant: ${invariantOk ? 'OK  ' : 'FAIL'} | '
      '#solutions: ${countLabel.padRight(5)} | status: ${statusLabel.padRight(9)} | '
      '${notes.isEmpty ? '-' : notes.join('; ')}',
    );
  }

  print('id       | invariant | #solutions | status    | notes');
  print('-' * 90);
  for (final row in rows) {
    print(row);
  }
  print('-' * 90);

  if (nonUnique.isNotEmpty) {
    print(
      'Non-unique puzzles (multiple valid paths, allowed - constraint-'
      'satisfaction win rule applies): ${nonUnique.join(', ')}',
    );
  }
  if (timeouts.isNotEmpty) {
    print(
      'Timeouts (inconclusive - search did not finish, not counted as '
      'transcription failures): ${timeouts.join(', ')}',
    );
  }
  if (hardFailIds.isNotEmpty) {
    print('Hard failures: ${hardFailIds.join(', ')}');
  }

  print('');
  print('--- SOLUTION PATHS (JSON) ---');
  for (final puzzle in puzzles) {
    final path = solutionPaths[puzzle.id];
    if (path == null) {
      continue;
    }
    final coords = path.map((c) => '[${c.row},${c.col}]').join(',');
    print('"${puzzle.id}": [$coords]');
  }

  if (hardFailures == 0 && timeouts.isEmpty) {
    print('');
    print('ALL CHECKS PASSED');
    exitCode = 0;
  } else {
    print('');
    print('FAILURES: $hardFailures hard, ${timeouts.length} timeout(s)');
    exitCode = 1;
  }
}
