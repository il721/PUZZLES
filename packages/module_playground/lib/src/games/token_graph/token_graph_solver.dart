import 'dart:collection';

import '../../playground_game.dart';
import 'token_graph_board.dart';
import 'token_graph_rules.dart';
import 'token_graph_state.dart';

/// The outcome of a [solveBfs] search: either a shortest solution was found
/// ([optimalMoves] non-null, [moves] the path realizing it), or the goal is
/// unreachable from the searched start state ([optimalMoves] `null`,
/// [moves] empty). [statesExplored] is the number of distinct states the
/// search discovered before returning, for diagnostics.
class TokenGraphSearchResult {
  /// The minimum number of moves to reach a goal state, or `null` if no
  /// goal state is reachable at all.
  final int? optimalMoves;

  /// One move sequence realizing [optimalMoves], or empty if unreachable.
  final List<PlaygroundMove> moves;

  /// The number of distinct states discovered during the search.
  final int statesExplored;

  const TokenGraphSearchResult({
    required this.optimalMoves,
    required this.moves,
    required this.statesExplored,
  });
}

/// Breadth-first search for the shortest path from [start] to any state
/// satisfying [isGoal], generating moves via [slideMoves]/[applySlide].
///
/// Some games forbid certain POSITIONS outright, rather than certain moves -
/// e.g. `cats_dogs`, where a cat may never stand adjacent to a dog. Such a
/// game passes its position predicate as [isLegal]; a successor state for
/// which [isLegal] returns false is skipped entirely (never visited, never
/// queued, never tested against [isGoal]), so the search only explores
/// reachable legal play. Leaving [isLegal] `null` preserves today's
/// behaviour exactly (used by `eight_chips`, which has no such rule).
///
/// Returns the optimal move count and one optimal move sequence, or an
/// [TokenGraphSearchResult] with `optimalMoves == null` if no reachable
/// state satisfies [isGoal].
TokenGraphSearchResult solveBfs(
  TokenGraphBoard board,
  TokenGraphState start,
  bool Function(TokenGraphState state) isGoal, {
  bool Function(TokenGraphState state)? isLegal,
}) {
  final startKey = start.key();
  if (isGoal(start)) {
    return const TokenGraphSearchResult(
      optimalMoves: 0,
      moves: [],
      statesExplored: 1,
    );
  }

  final visited = <String>{startKey};
  final queue = Queue<TokenGraphState>()..add(start);
  // childKey -> (parentKey, move used to reach child from parent).
  final cameFrom = <String, (String, PlaygroundMove)>{};

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    final currentKey = current.key();

    for (final move in slideMoves(board, current)) {
      final next = applySlide(board, current, move);
      if (isLegal != null && !isLegal(next)) continue;
      final nextKey = next.key();
      if (visited.contains(nextKey)) continue;
      visited.add(nextKey);
      cameFrom[nextKey] = (currentKey, move);

      if (isGoal(next)) {
        final path = <PlaygroundMove>[];
        var key = nextKey;
        while (key != startKey) {
          final entry = cameFrom[key]!;
          path.insert(0, entry.$2);
          key = entry.$1;
        }
        return TokenGraphSearchResult(
          optimalMoves: path.length,
          moves: path,
          statesExplored: visited.length,
        );
      }

      queue.add(next);
    }
  }

  return TokenGraphSearchResult(
    optimalMoves: null,
    moves: const [],
    statesExplored: visited.length,
  );
}

/// The full breadth-first-search closure size from [start]: the number of
/// distinct reachable states (including [start] itself), running the
/// search to exhaustion rather than stopping at any particular state.
///
/// Some games forbid certain POSITIONS outright, rather than certain moves -
/// e.g. `cats_dogs`, where a cat may never stand adjacent to a dog. Such a
/// game passes its position predicate as [isLegal]; a successor state for
/// which [isLegal] returns false is skipped entirely (never visited, never
/// queued), so only reachable legal play is counted. Leaving [isLegal]
/// `null` preserves today's behaviour exactly (used by `eight_chips`, which
/// has no such rule).
int reachableStateCount(
  TokenGraphBoard board,
  TokenGraphState start, {
  bool Function(TokenGraphState state)? isLegal,
}) {
  final visited = <String>{start.key()};
  final queue = Queue<TokenGraphState>()..add(start);

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    for (final move in slideMoves(board, current)) {
      final next = applySlide(board, current, move);
      if (isLegal != null && !isLegal(next)) continue;
      if (visited.add(next.key())) {
        queue.add(next);
      }
    }
  }

  return visited.length;
}
