import 'dart:collection';

import '../../playground_game.dart';
import 'token_graph_board.dart';
import 'token_graph_state.dart';

/// The per-node move tables a step-and-jump game needs, derived from a
/// board's [TokenGraphBoard.lines]: [steps] lists each node's immediate
/// line neighbours, and [jumps] lists, for each node, every
/// `(over, landing)` pair it can hop - three nodes consecutive on one line,
/// which is what makes a jump a straight checkers hop rather than a turn.
class TokenGraphJumpTables {
  /// For each node index, the node indexes exactly one position away along
  /// some line.
  final List<List<int>> steps;

  /// For each node index, the `(over, landing)` index pairs of every
  /// straight jump starting there.
  final List<List<(int, int)>> jumps;

  /// Creates the tables directly from their per-node lists.
  const TokenGraphJumpTables(this.steps, this.jumps);

  /// Derives [board]'s tables by walking every line's consecutive pairs and
  /// triples, in both directions.
  factory TokenGraphJumpTables.of(TokenGraphBoard board) {
    final steps = List.generate(board.nodeIds.length, (_) => <int>[]);
    final jumps = List.generate(board.nodeIds.length, (_) => <(int, int)>[]);

    for (final line in board.lines) {
      final indexes = [for (final id in line) board.indexOf(id)];
      for (var i = 0; i + 1 < indexes.length; i++) {
        steps[indexes[i]].add(indexes[i + 1]);
        steps[indexes[i + 1]].add(indexes[i]);
      }
      for (var i = 0; i + 2 < indexes.length; i++) {
        jumps[indexes[i]].add((indexes[i + 1], indexes[i + 2]));
        jumps[indexes[i + 2]].add((indexes[i + 1], indexes[i]));
      }
    }

    return TokenGraphJumpTables(steps, jumps);
  }
}

/// Every legal move available in [state] on [board] under the
/// step-or-jump-cascade rule (Мочалов, 1980, «Песочные часы», pp. 67-68):
///
/// * a token STEPS along a line to an adjacent free node, or
/// * it JUMPS straight over an adjacent occupied node onto the free node
///   directly beyond, and may go on jumping - a cascade of consecutive
///   jumps by one token is a SINGLE move. The player may stop after any
///   hop, so every landing of the cascade is offered as its own
///   destination, and a step may never be mixed into a cascade.
///
/// The moving token counts as gone from its origin for the whole move: the
/// origin may not be hopped over, and a cascade never lands back on it.
/// Nothing else on the board changes while a cascade runs, so the set of
/// reachable landings is plain graph reachability over the jump table - a
/// breadth-first walk, which also yields the shortest hop sequence to each
/// landing. A destination reachable both by a step and by a cascade is
/// reported as the step, so a move's path is always its shortest
/// description.
///
/// If [from] is non-null, only moves whose origin is [from] are returned.
/// The order is stable: by origin node index, then by destination node
/// index.
List<PlaygroundMove> stepJumpMoves(
  TokenGraphBoard board,
  TokenGraphState state, {
  String? from,
}) {
  final tables = TokenGraphJumpTables.of(board);
  final moves = <PlaygroundMove>[];

  for (var origin = 0; origin < board.nodeIds.length; origin++) {
    if (state.tokenAt(origin) == null) continue;
    if (from != null && board.nodeIds[origin] != from) continue;

    // Destination node index -> the path of node indexes taken to reach it.
    final paths = <int, List<int>>{};

    for (final neighbour in tables.steps[origin]) {
      if (state.tokenAt(neighbour) == null) {
        paths[neighbour] = [origin, neighbour];
      }
    }

    // The origin is in `seen` from the start, which is what keeps a cascade
    // from landing back where it began and what terminates a cascade that
    // could otherwise hop round a cycle forever.
    final cameFrom = <int, int>{};
    final seen = <int>{origin};
    final queue = Queue<int>()..add(origin);
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final (over, landing) in tables.jumps[current]) {
        if (over == origin || state.tokenAt(over) == null) continue;
        if (state.tokenAt(landing) != null) continue;
        if (!seen.add(landing)) continue;
        cameFrom[landing] = current;
        queue.add(landing);
      }
    }

    for (final landing in seen) {
      if (landing == origin) continue;
      if (paths.containsKey(landing)) continue;
      final path = <int>[landing];
      var node = landing;
      while (node != origin) {
        node = cameFrom[node]!;
        path.insert(0, node);
      }
      paths[landing] = path;
    }

    final destinations = paths.keys.toList()..sort();
    for (final destination in destinations) {
      moves.add(
        PlaygroundMove([
          for (final index in paths[destination]!) board.nodeIds[index],
        ]),
      );
    }
  }

  return moves;
}

/// Applies [move] to [state] on [board], returning the resulting state.
///
/// Throws [ArgumentError] if [move] is not currently legal in [state] -
/// including a path that reaches a legal destination by a route
/// [stepJumpMoves] does not generate, since a move is identified by its
/// whole path, not just its endpoints.
TokenGraphState applyStepJump(
  TokenGraphBoard board,
  TokenGraphState state,
  PlaygroundMove move,
) {
  final legalFromOrigin = stepJumpMoves(board, state, from: move.from);
  if (!legalFromOrigin.contains(move)) {
    throw ArgumentError(
      'stepJumpMoves: $move is not a legal move in state $state',
    );
  }

  final tokens = List<String?>.of(state.tokens);
  final fromIndex = board.indexOf(move.from);
  final toIndex = board.indexOf(move.to);
  tokens[toIndex] = tokens[fromIndex];
  tokens[fromIndex] = null;
  return TokenGraphState(tokens);
}
