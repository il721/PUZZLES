import 'dart:io';

import 'package:module_rebus/module_rebus.dart';

/// Solution counting stops after this many solutions are found (matches
/// the "solutions: k (capped at 2)" report line — we only need to
/// distinguish "exactly one" from "more than one").
const int _solutionCap = 2;

/// Resolves the path to `module01.json`.
///
/// If [args] has a first element, it is used verbatim as the data file
/// path — this is the robust override (`dart run rebus_verify
/// path/to/module01.json`). Otherwise the path is derived from this
/// script's own location (`tools/solver/bin/verify.dart`), so the default
/// works regardless of the working directory the CLI happens to be
/// invoked from.
String _resolveDataPath(List<String> args) {
  if (args.isNotEmpty) {
    return args.first;
  }
  final scriptFile = File.fromUri(Platform.script);
  final binDir = scriptFile.parent;
  return '${binDir.path}/../../../packages/module_rebus/assets/puzzles/module01.json';
}

/// Validates every puzzle in the module_rebus data set: that its canonical
/// (author-supplied) solution is internally consistent and satisfies every
/// constraint. Solution count is reported for every puzzle but is
/// informational only — the win condition is constraint-satisfaction, so a
/// non-unique puzzle is not a failure. Only canonical verification failures
/// are treated as hard failures.
Future<void> main(List<String> args) async {
  final dataPath = _resolveDataPath(args);
  final dataFile = File(dataPath);

  if (!dataFile.existsSync()) {
    stderr.writeln('rebus_verify: cannot find puzzle data at "$dataPath"');
    exitCode = 1;
    return;
  }

  final puzzles = RebusPuzzle.listFromJsonString(dataFile.readAsStringSync());

  var failures = 0;

  for (final puzzle in puzzles) {
    final violations = verifyCanonical(puzzle);
    final canonicalOk = violations.isEmpty;
    final solutions = countSolutions(puzzle, cap: _solutionCap);

    print(
      '${puzzle.id} | canonical: ${canonicalOk ? 'OK' : 'FAIL'} | '
      'givens: ${puzzle.givens.length} | solutions: $solutions (capped at $_solutionCap)',
    );

    if (!canonicalOk) {
      failures++;
      for (final violation in violations) {
        print('  - $violation');
      }
    }

    if (solutions != 1) {
      print(
        '  note: $solutions solutions found (win condition is constraint '
        'satisfaction; non-unique allowed)',
      );
    }
  }

  if (failures == 0) {
    print('ALL CHECKS PASSED');
    exitCode = 0;
  } else {
    print('FAILURES: $failures');
    exitCode = 1;
  }
}
