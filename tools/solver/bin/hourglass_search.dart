import 'dart:typed_data';

import 'package:module_playground/module_playground.dart';

/// The outcome of [solveIdenticalTokens]: either a shortest solution was
/// found ([optimalMoves] non-null, [moves] realizing it), or the goal is
/// unreachable ([optimalMoves] `null`, [moves] empty). [statesExplored] is
/// how many distinct positions the two searches marked between them.
class IdenticalTokenSearchResult {
  /// The minimum number of moves from start to goal, or `null` if the goal
  /// is unreachable.
  final int? optimalMoves;

  /// One move sequence realizing [optimalMoves], or empty if unreachable.
  final List<PlaygroundMove> moves;

  /// How many distinct positions the search marked.
  final int statesExplored;

  /// Creates a result.
  const IdenticalTokenSearchResult({
    required this.optimalMoves,
    required this.moves,
    required this.statesExplored,
  });
}

/// Shortest-path search for a step-and-jump token-graph game whose tokens
/// are all interchangeable, e.g. «Песочные часы».
///
/// The generic [solveBfs] in `module_playground` keys its visited set on a
/// state's comma-joined labels and walks forward only. That is fine for the
/// 181440 and 2264 state closures of the first two playground games and
/// hopeless here: fifteen identical tokens on 29 nodes give C(29,15) =
/// 77558760 positions. So this search represents a position as a 64-bit
/// occupancy BITMASK (legal because the tokens are indistinguishable),
/// stores one byte per position in a flat table addressed by the position's
/// combinatorial rank, and runs BIDIRECTIONALLY - forward from [start] and
/// backward from [goal], always expanding the smaller frontier. Moves are
/// reversible (nothing is added to or removed from the board, a jumped-over
/// token is never captured), so a backward step is just a forward step
/// taken from the goal.
///
/// The byte table encodes which side reached a position and at what depth:
/// `0` unvisited, `1 + d` reached by the forward search at depth `d`,
/// `64 + d` by the backward search. The frontier level being expanded is
/// always finished before a meeting is turned into an answer, so the first
/// answer returned is the true optimum, not merely the first meeting seen.
///
/// No parent pointers are stored - at 77.5 million positions they would
/// cost more than the search itself. The solution is instead re-walked
/// afterwards through the depth marks (a predecessor of a depth-`d`
/// position is any neighbour marked depth `d - 1`), and each pair of
/// consecutive positions is turned back into a [PlaygroundMove] by asking
/// the shipped [stepJumpMoves] generator which of its moves produces it -
/// so a solution that replays here is a solution under the app's own rules,
/// not merely under this file's bitmask copy of them.
///
/// Throws [ArgumentError] if the board has more than 62 nodes, or if
/// [start] and [goal] do not hold the same number of tokens.
IdenticalTokenSearchResult solveIdenticalTokens(
  TokenGraphBoard board,
  TokenGraphState start,
  TokenGraphState goal,
) =>
    _Search(board, start, goal).run();

/// The forward search's depth-0 mark; depth `d` is stored as `_forward + d`.
const int _forward = 1;

/// The backward search's depth-0 mark; depth `d` is stored as
/// `_backward + d`. Keeps forward marks (1..63) and backward marks
/// (64..126) in disjoint ranges of one byte.
const int _backward = 64;

class _Search {
  final TokenGraphBoard board;
  final TokenGraphState start;
  final TokenGraphState goal;

  final int nodeCount;
  final String label;
  final int startMask;
  final int goalMask;

  final List<Int32List> steps;
  final List<Int32List> jumpOver;
  final List<Int32List> jumpLanding;

  final List<Int64List> binomial;
  final Uint8List visited;

  /// Reused scratch buffer for one position's successor masks, so the hot
  /// loop does not allocate a list per expanded position.
  final List<int> successors = <int>[];

  int explored = 0;

  factory _Search(
    TokenGraphBoard board,
    TokenGraphState start,
    TokenGraphState goal,
  ) {
    final nodeCount = board.nodeIds.length;
    if (nodeCount > 62) {
      throw ArgumentError(
        'solveIdenticalTokens: board has $nodeCount nodes, more than the 62 '
        'a 64-bit occupancy mask can carry',
      );
    }

    var label = '';
    var startMask = 0;
    var goalMask = 0;
    var tokens = 0;
    for (var i = 0; i < nodeCount; i++) {
      final token = start.tokenAt(i);
      if (token != null) {
        label = token;
        startMask |= 1 << i;
        tokens++;
      }
      if (goal.tokenAt(i) != null) goalMask |= 1 << i;
    }

    var goalTokens = 0;
    for (var i = 0; i < nodeCount; i++) {
      if ((goalMask >> i) & 1 == 1) goalTokens++;
    }
    if (goalTokens != tokens) {
      throw ArgumentError(
        'solveIdenticalTokens: start holds $tokens tokens but goal holds '
        '$goalTokens',
      );
    }

    final tables = TokenGraphJumpTables.of(board);
    final binomial = _binomialTable(nodeCount, tokens);

    return _Search._(
      board,
      start,
      goal,
      nodeCount,
      label,
      startMask,
      goalMask,
      [for (final s in tables.steps) Int32List.fromList(s)],
      [
        for (final j in tables.jumps)
          Int32List.fromList([for (final pair in j) pair.$1]),
      ],
      [
        for (final j in tables.jumps)
          Int32List.fromList([for (final pair in j) pair.$2]),
      ],
      binomial,
      Uint8List(binomial[nodeCount][tokens]),
    );
  }

  _Search._(
    this.board,
    this.start,
    this.goal,
    this.nodeCount,
    this.label,
    this.startMask,
    this.goalMask,
    this.steps,
    this.jumpOver,
    this.jumpLanding,
    this.binomial,
    this.visited,
  );

  /// `C(i, j)` for every `i <= n`, `j <= k`, as a flat lookup for [rank].
  static List<Int64List> _binomialTable(int n, int k) {
    final table = List.generate(n + 1, (_) => Int64List(k + 1));
    for (var i = 0; i <= n; i++) {
      table[i][0] = 1;
      for (var j = 1; j <= k; j++) {
        table[i][j] = i == 0 ? 0 : table[i - 1][j - 1] + table[i - 1][j];
      }
    }
    return table;
  }

  /// The combinatorial rank of [mask] among all same-size subsets, i.e. its
  /// index into [visited]: the sum of `C(position, i)` over the mask's set
  /// bits taken in ascending order, `i` counting from 1. A bijection onto
  /// `0 ..< C(nodeCount, tokens)`, which is what lets the visited table be
  /// a flat byte array instead of a hash map.
  int rank(int mask) {
    var result = 0;
    var i = 1;
    for (var c = 0; c < nodeCount; c++) {
      if ((mask >> c) & 1 == 1) {
        result += binomial[c][i];
        i++;
      }
    }
    return result;
  }

  /// Fills [successors] with every position one move from [mask].
  ///
  /// Mirrors [stepJumpMoves] exactly, in bitmask form: the mover's origin
  /// bit is cleared FIRST (`base`), so the origin can be neither hopped over
  /// nor landed on, and a cascade is a breadth-walk over the jump table with
  /// a `seen` mask, every landing of which is its own successor. The list
  /// may contain a position twice (a step and a cascade can share a
  /// destination); the caller's visited check absorbs that.
  void expand(int mask) {
    successors.clear();
    for (var origin = 0; origin < nodeCount; origin++) {
      if ((mask >> origin) & 1 == 0) continue;
      final base = mask & ~(1 << origin);

      final neighbours = steps[origin];
      for (var i = 0; i < neighbours.length; i++) {
        final neighbour = neighbours[i];
        if ((base >> neighbour) & 1 == 0) {
          successors.add(base | (1 << neighbour));
        }
      }

      var seen = 1 << origin;
      final queue = <int>[origin];
      while (queue.isNotEmpty) {
        final current = queue.removeLast();
        final overs = jumpOver[current];
        final landings = jumpLanding[current];
        for (var i = 0; i < overs.length; i++) {
          final over = overs[i];
          if ((base >> over) & 1 == 0) continue;
          final landing = landings[i];
          if ((base >> landing) & 1 == 1) continue;
          if ((seen >> landing) & 1 == 1) continue;
          seen |= 1 << landing;
          queue.add(landing);
          successors.add(base | (1 << landing));
        }
      }
    }
  }

  IdenticalTokenSearchResult run() {
    if (startMask == goalMask) {
      return const IdenticalTokenSearchResult(
        optimalMoves: 0,
        moves: [],
        statesExplored: 1,
      );
    }

    visited[rank(startMask)] = _forward;
    visited[rank(goalMask)] = _backward;
    explored = 2;

    var forwardFrontier = <int>[startMask];
    var backwardFrontier = <int>[goalMask];
    var forwardDepth = 0;
    var backwardDepth = 0;

    while (forwardFrontier.isNotEmpty && backwardFrontier.isNotEmpty) {
      final goingForward = forwardFrontier.length <= backwardFrontier.length;
      final frontier = goingForward ? forwardFrontier : backwardFrontier;
      final depth = (goingForward ? forwardDepth : backwardDepth) + 1;
      final mark = (goingForward ? _forward : _backward) + depth;
      final otherBase = goingForward ? _backward : _forward;

      final next = <int>[];
      int? best;
      var meetForwardMask = 0;
      var meetForwardDepth = 0;
      var meetBackwardMask = 0;
      var meetBackwardDepth = 0;

      for (final position in frontier) {
        expand(position);
        for (final successor in successors) {
          final index = rank(successor);
          final seen = visited[index];
          if (seen == 0) {
            visited[index] = mark;
            explored++;
            next.add(successor);
            continue;
          }
          final fromOtherSide =
              goingForward ? seen >= _backward : seen < _backward;
          if (!fromOtherSide) continue;

          final otherDepth = seen - otherBase;
          final candidate = depth + otherDepth;
          if (best != null && candidate >= best) continue;
          best = candidate;
          if (goingForward) {
            meetForwardMask = position;
            meetForwardDepth = depth - 1;
            meetBackwardMask = successor;
            meetBackwardDepth = otherDepth;
          } else {
            meetForwardMask = successor;
            meetForwardDepth = otherDepth;
            meetBackwardMask = position;
            meetBackwardDepth = depth - 1;
          }
        }
      }

      if (goingForward) {
        forwardDepth = depth;
        forwardFrontier = next;
      } else {
        backwardDepth = depth;
        backwardFrontier = next;
      }

      if (best != null) {
        final masks = <int>[
          ..._walkToStart(meetForwardMask, meetForwardDepth),
          ..._walkToGoal(meetBackwardMask, meetBackwardDepth),
        ];
        final moves = _movesAlong(masks);
        if (moves.length != best) {
          throw StateError(
            'solveIdenticalTokens: reconstructed ${moves.length} moves for a '
            'par of $best',
          );
        }
        return IdenticalTokenSearchResult(
          optimalMoves: best,
          moves: moves,
          statesExplored: explored,
        );
      }
    }

    return IdenticalTokenSearchResult(
      optimalMoves: null,
      moves: const [],
      statesExplored: explored,
    );
  }

  /// The positions from the start up to and including [mask], which the
  /// forward search marked at [depth]. Walks backwards by looking for a
  /// neighbour the forward search marked one level shallower; moves being
  /// reversible, such a neighbour is always a genuine predecessor.
  List<int> _walkToStart(int mask, int depth) {
    final chain = <int>[mask];
    var current = mask;
    for (var d = depth; d > 0; d--) {
      final wanted = _forward + (d - 1);
      var found = false;
      expand(current);
      for (final candidate in successors) {
        if (visited[rank(candidate)] != wanted) continue;
        chain.insert(0, candidate);
        current = candidate;
        found = true;
        break;
      }
      if (!found) {
        throw StateError(
          'solveIdenticalTokens: no forward predecessor at depth ${d - 1}',
        );
      }
    }
    return chain;
  }

  /// The positions from [mask], which the backward search marked at [depth],
  /// down to the goal.
  List<int> _walkToGoal(int mask, int depth) {
    final chain = <int>[mask];
    var current = mask;
    for (var d = depth; d > 0; d--) {
      final wanted = _backward + (d - 1);
      var found = false;
      expand(current);
      for (final candidate in successors) {
        if (visited[rank(candidate)] != wanted) continue;
        chain.add(candidate);
        current = candidate;
        found = true;
        break;
      }
      if (!found) {
        throw StateError(
          'solveIdenticalTokens: no backward predecessor at depth ${d - 1}',
        );
      }
    }
    return chain;
  }

  /// Turns a chain of positions into the moves joining them, by asking the
  /// shipped [stepJumpMoves] generator for the move that produces each next
  /// position. Doubles as a cross-check of this file's bitmask move
  /// generation against the rules the app actually plays by.
  List<PlaygroundMove> _movesAlong(List<int> masks) {
    final moves = <PlaygroundMove>[];
    for (var i = 0; i + 1 < masks.length; i++) {
      final state = _stateOf(masks[i]);
      PlaygroundMove? found;
      for (final move in stepJumpMoves(board, state)) {
        final applied = (masks[i] & ~(1 << board.indexOf(move.from))) |
            (1 << board.indexOf(move.to));
        if (applied == masks[i + 1]) {
          found = move;
          break;
        }
      }
      if (found == null) {
        throw StateError(
          'solveIdenticalTokens: no legal move joins two positions of the '
          'reconstructed solution',
        );
      }
      moves.add(found);
    }
    return moves;
  }

  TokenGraphState _stateOf(int mask) => TokenGraphState([
        for (var i = 0; i < nodeCount; i++)
          if ((mask >> i) & 1 == 1) label else null,
      ]);
}
