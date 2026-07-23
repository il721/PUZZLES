import 'dart:io';

import 'package:module_squareword/module_squareword.dart';

import 'module05_book_solutions.dart';

/// Resolves the path to `module05.json`.
///
/// If [args] has a first element, it is used verbatim as the data file
/// path. Otherwise the path is derived from this script's own location
/// (`tools/solver/bin/verify_module05.dart`), so the default works
/// regardless of the working directory the CLI is invoked from.
String _resolveDataPath(List<String> args) {
  if (args.isNotEmpty) {
    return args.first;
  }
  final scriptFile = File.fromUri(Platform.script);
  final binDir = scriptFile.parent;
  return '${binDir.path}/../../../packages/module_squareword/assets/puzzles/module05.json';
}

/// Verifies all 17 numbered squareword puzzles (the tutorial example is
/// covered separately by `module_squareword`'s own `solver_test.dart`):
/// each must have a unique solution (per [solveSquareword], `cap: 2`, so
/// `multiple` is distinguishable from `unique`), and that solution must
/// match the corresponding entry of [module05BookSolutions] - the book's
/// printed answer (`05-solve.pdf`), transcribed and cross-verified
/// independently of `module05.json`'s givens.
///
/// Exit code is non-zero if ANY puzzle is not uniquely solvable (zero or
/// multiple solutions), if the solver's solution mismatches the book
/// answer, or if the search times out on any puzzle - a timeout is
/// reported distinctly and is never silently treated as a pass or a fail,
/// since an unresolved puzzle needs human attention either way.
Future<void> main(List<String> args) async {
  final dataPath = _resolveDataPath(args);
  final dataFile = File(dataPath);

  if (!dataFile.existsSync()) {
    stderr.writeln(
      'squareword_verify: cannot find puzzle data at "$dataPath"',
    );
    exitCode = 1;
    return;
  }

  final allPuzzles =
      SquarewordPuzzle.listFromJsonString(dataFile.readAsStringSync());
  final puzzles = allPuzzles.where((p) => !p.tutorial).toList(growable: false);

  var hardFailures = 0;
  final hardFailIds = <String>{};
  final timeouts = <String>[];
  final rows = <String>[];

  for (final puzzle in puzzles) {
    final result = solveSquareword(
      puzzle,
      cap: 2,
      timeout: const Duration(seconds: 60),
    );

    final notes = <String>[];
    String statusLabel;
    String countLabel;

    switch (result.status) {
      case SquarewordSolveStatus.zero:
        hardFailures++;
        hardFailIds.add(puzzle.id);
        statusLabel = 'HARD FAIL';
        countLabel = '0';
        notes.add('HARD FAIL: no valid completion exists');
        break;
      case SquarewordSolveStatus.unique:
        statusLabel = 'OK';
        countLabel = '1';
        break;
      case SquarewordSolveStatus.multiple:
        hardFailures++;
        hardFailIds.add(puzzle.id);
        statusLabel = 'HARD FAIL';
        countLabel = '>=2';
        notes.add('HARD FAIL: not uniquely solvable (>= 2 completions)');
        break;
      case SquarewordSolveStatus.timeout:
        timeouts.add(puzzle.id);
        statusLabel = 'TIMEOUT';
        countLabel = 'n/a';
        notes.add(
          'INCONCLUSIVE: search timed out (not a transcription failure, '
          'needs human attention)',
        );
        break;
    }

    final bookSolution = module05BookSolutions[puzzle.id];
    if (bookSolution == null) {
      hardFailures++;
      hardFailIds.add(puzzle.id);
      notes.add('HARD FAIL: no book-solution oracle entry for this id');
    } else if (result.solution != null) {
      if (_solutionsEqual(result.solution!, bookSolution)) {
        notes.add('matches book answer');
      } else {
        hardFailures++;
        hardFailIds.add(puzzle.id);
        notes.add('HARD FAIL: solver solution does not match book answer');
        print('${puzzle.id}: HARD FAIL - solution mismatch');
        print('  solver: ${result.solution}');
        print('  book:   $bookSolution');
      }
    }

    rows.add(
      '${puzzle.id.padRight(8)} | n: ${puzzle.n} | keyword: '
      '${puzzle.keyword.padRight(8)} | #solutions: '
      '${countLabel.padRight(5)} | status: ${statusLabel.padRight(9)} | '
      '${notes.isEmpty ? '-' : notes.join('; ')}',
    );
  }

  print('id       | n | keyword  | #solutions | status    | notes');
  print('-' * 100);
  for (final row in rows) {
    print(row);
  }
  print('-' * 100);

  if (timeouts.isNotEmpty) {
    print(
      'Timeouts (inconclusive - search did not finish, needs human '
      'attention, not auto-passed or auto-failed): ${timeouts.join(', ')}',
    );
  }
  if (hardFailIds.isNotEmpty) {
    print('Hard failures: ${hardFailIds.join(', ')}');
  }

  if (hardFailures == 0 && timeouts.isEmpty) {
    print('');
    print('ALL 17 PUZZLES UNIQUELY SOLVABLE AND MATCH THE BOOK');
    exitCode = 0;
  } else {
    print('');
    print('FAILURES: $hardFailures hard, ${timeouts.length} timeout(s)');
    exitCode = 1;
  }
}

bool _solutionsEqual(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
