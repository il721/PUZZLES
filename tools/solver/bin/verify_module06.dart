import 'dart:convert';
import 'dart:io';

import 'package:module_playground/module_playground.dart';

/// Resolves the path to `module06.json`.
///
/// If the non-flag arguments in [args] have a first element, it is used
/// verbatim as the data file path. Otherwise the path is derived from this
/// script's own location (`tools/solver/bin/verify_module06.dart`), so the
/// default works regardless of the working directory the CLI is invoked
/// from.
String _resolveDataPath(List<String> args) {
  final positional = args.where((a) => !a.startsWith('--')).toList();
  if (positional.isNotEmpty) {
    return positional.first;
  }
  final scriptFile = File.fromUri(Platform.script);
  final binDir = scriptFile.parent;
  return '${binDir.path}/../../../packages/module_playground/assets/puzzles/'
      'module06.json';
}

/// Computes `eight_chips`' data from scratch (BFS par + one optimal move
/// list) and prints the full `module06.json` document it implies, so the
/// asset file can be regenerated deterministically from the board/rules
/// code rather than hand-edited.
void _emit() {
  const game = EightChipsGame();
  final board = EightChipsGame.board;
  final start = game.initialState() as TokenGraphState;
  final result = solveBfs(board, start, game.isSolved);

  final doc = {
    'schemaVersion': 1,
    'module': 'playground',
    'games': [
      {
        'id': 'eight_chips',
        'par': result.optimalMoves,
        'parProven': true,
        'parSource': 'solver',
        'solution': result.moves.map((m) => m.toJson()).toList(),
      },
    ],
  };

  print(const JsonEncoder.withIndent(' ').convert(doc));
}

/// Verifies `module06.json`'s `eight_chips` entry: recomputes par by BFS,
/// recomputes the full reachable-state closure size, replays the stored
/// solution move-by-move (asserting each move is legal at its point in the
/// replay and the final position is solved), and asserts stored par ==
/// computed par == stored solution length.
///
/// Exit code is non-zero if any of those checks fail.
void _verify(String dataPath) {
  final dataFile = File(dataPath);
  if (!dataFile.existsSync()) {
    stderr.writeln(
      'playground_verify: cannot find puzzle data at "$dataPath"',
    );
    exitCode = 1;
    return;
  }

  final data = PlaygroundData.fromJsonString(dataFile.readAsStringSync());

  final board = EightChipsGame.board;
  final game = EightChipsGame(data.forId('eight_chips'));
  final start = game.initialState() as TokenGraphState;

  final bfsResult = solveBfs(board, start, game.isSolved);
  final closureSize = reachableStateCount(board, start);

  final storedPar = game.par;
  final storedSolution = game.optimalSolution;

  var hardFailures = 0;
  final notes = <String>[];

  if (storedPar == null) {
    hardFailures++;
    notes.add('HARD FAIL: module06.json has no par for eight_chips');
  }
  if (bfsResult.optimalMoves == null) {
    hardFailures++;
    notes.add('HARD FAIL: goal state is unreachable by BFS');
  }
  if (storedPar != null &&
      bfsResult.optimalMoves != null &&
      storedPar != bfsResult.optimalMoves) {
    hardFailures++;
    notes.add(
      'HARD FAIL: stored par $storedPar != BFS-computed par '
      '${bfsResult.optimalMoves}',
    );
  }

  int? replayedLength;
  if (storedSolution == null) {
    hardFailures++;
    notes.add('HARD FAIL: module06.json has no solution for eight_chips');
  } else {
    var state = start;
    var replayOk = true;
    for (var i = 0; i < storedSolution.length; i++) {
      final move = storedSolution[i];
      final legalFromOrigin = game.legalMoves(state, from: move.from);
      if (!legalFromOrigin.contains(move)) {
        hardFailures++;
        notes.add(
          'HARD FAIL: stored solution move #$i ($move) is not legal at '
          'that point in the replay',
        );
        replayOk = false;
        break;
      }
      state = game.applyMove(state, move) as TokenGraphState;
    }
    replayedLength = storedSolution.length;
    if (replayOk && !game.isSolved(state)) {
      hardFailures++;
      notes.add('HARD FAIL: replaying the stored solution ends unsolved');
    }
    if (storedPar != null && storedSolution.length != storedPar) {
      hardFailures++;
      notes.add(
        'HARD FAIL: stored solution length ${storedSolution.length} != '
        'stored par $storedPar',
      );
    }
  }

  print(
    'game         | par(stored) | par(BFS) | solution length | reachable '
    'closure | status',
  );
  print('-' * 100);
  print(
    'eight_chips  | ${'${storedPar}'.padRight(11)} | '
    '${'${bfsResult.optimalMoves}'.padRight(8)} | '
    '${'${replayedLength}'.padRight(16)} | ${'$closureSize'.padRight(17)} | '
    '${notes.isEmpty ? 'OK' : 'FAIL'}',
  );
  print('-' * 100);
  for (final note in notes) {
    print(note);
  }

  if (hardFailures == 0) {
    print('');
    print('ALL CHECKS PASSED (eight_chips par=$storedPar, '
        'closure=$closureSize)');
    exitCode = 0;
  } else {
    print('');
    print('FAILURES: $hardFailures');
    exitCode = 1;
  }
}

Future<void> main(List<String> args) async {
  if (args.contains('--emit')) {
    _emit();
    return;
  }
  _verify(_resolveDataPath(args));
}
