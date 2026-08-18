import 'dart:convert';
import 'dart:io';

import 'package:module_playground/module_playground.dart';

/// One shipped playground game's identity plus everything BFS needs to
/// derive its `module06.json` entry from scratch: its board, a factory
/// building the [PlaygroundGame] from optional parsed [PlaygroundGameData],
/// and its position-legality predicate ([isLegal]), `null` for games with no
/// such rule (see [solveBfs]/[reachableStateCount]).
typedef _GameDescriptor = ({
  String id,
  TokenGraphBoard board,
  PlaygroundGame Function(PlaygroundGameData? data) build,
  bool Function(TokenGraphState state)? isLegal,
});

/// Every shipped playground game, in the order they should appear in
/// `module06.json`. Adding a game here is the only change needed to bring it
/// under `--emit`/verification.
const List<_GameDescriptor> _shippedGames = [
  (
    id: 'eight_chips',
    board: EightChipsGame.board,
    build: EightChipsGame.new,
    isLegal: null,
  ),
  (
    id: 'cats_dogs',
    board: CatsDogsGame.board,
    build: CatsDogsGame.new,
    isLegal: isPeacefulPosition,
  ),
];

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

/// Computes one [descriptor]'s data from scratch (BFS par + one optimal move
/// list) as a `module06.json` `games` entry.
Map<String, dynamic> _emitGame(_GameDescriptor descriptor) {
  final game = descriptor.build(null);
  final start = game.initialState() as TokenGraphState;
  final result = solveBfs(
    descriptor.board,
    start,
    game.isSolved,
    isLegal: descriptor.isLegal,
  );

  return {
    'id': descriptor.id,
    'par': result.optimalMoves,
    'parProven': true,
    'parSource': 'solver',
    'solution': result.moves.map((m) => m.toJson()).toList(),
  };
}

/// Computes every [_shippedGames] entry's data from scratch (BFS par + one
/// optimal move list) and prints the full `module06.json` document it
/// implies, so the asset file can be regenerated deterministically from the
/// board/rules code rather than hand-edited.
void _emit() {
  final doc = {
    'schemaVersion': 1,
    'module': 'playground',
    'games': [for (final descriptor in _shippedGames) _emitGame(descriptor)],
  };

  print(const JsonEncoder.withIndent(' ').convert(doc));
}

/// Verifies `module06.json`'s entry for every [_shippedGames] game:
/// recomputes par by BFS, recomputes the full reachable-state closure size,
/// replays the stored solution move-by-move (asserting each move is legal
/// at its point in the replay and the final position is solved), and
/// asserts stored par == computed par == stored solution length.
///
/// Exit code is non-zero if any check fails for any game.
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

  print(
    'game         | par(stored) | par(BFS) | solution length | reachable '
    'closure | status',
  );
  print('-' * 100);

  var hardFailures = 0;
  final allNotes = <String>[];

  for (final descriptor in _shippedGames) {
    final game = descriptor.build(data.forId(descriptor.id));
    final start = game.initialState() as TokenGraphState;

    final bfsResult = solveBfs(
      descriptor.board,
      start,
      game.isSolved,
      isLegal: descriptor.isLegal,
    );
    final closureSize = reachableStateCount(
      descriptor.board,
      start,
      isLegal: descriptor.isLegal,
    );

    final storedPar = game.par;
    final storedSolution = game.optimalSolution;

    final notes = <String>[];

    if (storedPar == null) {
      hardFailures++;
      notes.add('HARD FAIL: module06.json has no par for ${descriptor.id}');
    }
    if (bfsResult.optimalMoves == null) {
      hardFailures++;
      notes.add(
        'HARD FAIL: goal state is unreachable by BFS (${descriptor.id})',
      );
    }
    if (storedPar != null &&
        bfsResult.optimalMoves != null &&
        storedPar != bfsResult.optimalMoves) {
      hardFailures++;
      notes.add(
        'HARD FAIL: stored par $storedPar != BFS-computed par '
        '${bfsResult.optimalMoves} (${descriptor.id})',
      );
    }

    int? replayedLength;
    if (storedSolution == null) {
      hardFailures++;
      notes.add(
        'HARD FAIL: module06.json has no solution for ${descriptor.id}',
      );
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
            'that point in the replay (${descriptor.id})',
          );
          replayOk = false;
          break;
        }
        state = game.applyMove(state, move) as TokenGraphState;
      }
      replayedLength = storedSolution.length;
      if (replayOk && !game.isSolved(state)) {
        hardFailures++;
        notes.add(
          'HARD FAIL: replaying the stored solution ends unsolved '
          '(${descriptor.id})',
        );
      }
      if (storedPar != null && storedSolution.length != storedPar) {
        hardFailures++;
        notes.add(
          'HARD FAIL: stored solution length ${storedSolution.length} != '
          'stored par $storedPar (${descriptor.id})',
        );
      }
    }

    print(
      '${descriptor.id.padRight(12)} | ${'$storedPar'.padRight(11)} | '
      '${'${bfsResult.optimalMoves}'.padRight(8)} | '
      '${'$replayedLength'.padRight(16)} | ${'$closureSize'.padRight(17)} | '
      '${notes.isEmpty ? 'OK' : 'FAIL'}',
    );
    allNotes.addAll(notes);
  }

  print('-' * 100);
  for (final note in allNotes) {
    print(note);
  }

  if (hardFailures == 0) {
    print('');
    print('ALL CHECKS PASSED');
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
