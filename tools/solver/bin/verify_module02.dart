import 'dart:io';

import 'package:module_digit_rebus/module_digit_rebus.dart';

/// Resolves the path to `module02.json`.
///
/// If [args] has a first element, it is used verbatim as the data file
/// path. Otherwise the path is derived from this script's own location
/// (`tools/solver/bin/verify_module02.dart`), so the default works
/// regardless of the working directory the CLI is invoked from.
String _resolveDataPath(List<String> args) {
  if (args.isNotEmpty) {
    return args.first;
  }
  final scriptFile = File.fromUri(Platform.script);
  final binDir = scriptFile.parent;
  return '${binDir.path}/../../../packages/module_digit_rebus/assets/puzzles/module02.json';
}

/// Validates every module-02 puzzle: the printed answer must satisfy every
/// constraint (glyph sets + all 8 equations), and the solution count is
/// enumerated up to the cap. Ship gate per PLAN-02: solution count 0 is a
/// hard failure (broken transcription or semantics); counts above 1 are
/// listed for an explicit user keep/drop decision, not failed.
Future<void> main(List<String> args) async {
  final dataPath = _resolveDataPath(args);
  final dataFile = File(dataPath);

  if (!dataFile.existsSync()) {
    stderr.writeln(
        'digit_rebus_verify: cannot find puzzle data at "$dataPath"');
    exitCode = 1;
    return;
  }

  final puzzles =
      DigitRebusPuzzle.listFromJsonString(dataFile.readAsStringSync());

  var failures = 0;
  final nonUnique = <String>[];

  for (final puzzle in puzzles) {
    final violations = verifyCanonical(puzzle);
    final canonicalOk = violations.isEmpty;
    final solutions = countSolutions(puzzle);

    final capNote = solutions >= solutionCap ? ' (>= cap $solutionCap)' : '';
    print(
      '${puzzle.id} | canonical: ${canonicalOk ? 'OK' : 'FAIL'} | '
      'solutions: $solutions$capNote'
      '${puzzle.note != null ? ' | note: ${puzzle.note}' : ''}',
    );

    if (!canonicalOk) {
      failures++;
      for (final violation in violations) {
        print('  - $violation');
      }
    }
    if (solutions == 0) {
      failures++;
      print('  - HARD FAIL: no valid assignment exists');
    } else if (solutions > 1) {
      nonUnique.add('${puzzle.id} ($solutions)');
    }
  }

  if (nonUnique.isNotEmpty) {
    print('SHIP GATE - non-unique puzzles for user keep/drop decision: '
        '${nonUnique.join(', ')}');
  }

  if (failures == 0) {
    print('ALL CHECKS PASSED');
    exitCode = 0;
  } else {
    print('FAILURES: $failures');
    exitCode = 1;
  }
}
