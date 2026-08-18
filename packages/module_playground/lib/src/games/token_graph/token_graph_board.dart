/// An immutable board of named nodes joined by straight lines: a line is an
/// ordered list of 2 or more collinear node ids (order matters - it is the
/// physical order along the line, used to walk outward from a node during
/// move generation). A single board is shared by every state of a
/// token-graph game; only the token placement changes between states.
///
/// Lookups ([indexOf], [lineMembershipOf], [degreesOnEmptyBoard]) are
/// computed on demand by scanning [nodeIds]/[lines] rather than cached in
/// fields, so the class can stay purely immutable (every field final,
/// [TokenGraphBoard.new] usable as a `const` constructor for compile-time
/// board literals) at the cost of a linear rescan per call - negligible at
/// the size of these puzzle boards (single-digit to low-dozens of nodes).
class TokenGraphBoard {
  /// Every node id on this board, in a stable declaration order.
  final List<String> nodeIds;

  /// Every straight line on the board, each a list of 2+ collinear node
  /// ids in physical order along the line.
  final List<List<String>> lines;

  /// Creates a board directly from [nodeIds] and [lines], with no
  /// validation - for compile-time board literals you have already
  /// reasoned about. Prefer [TokenGraphBoard.validated] for data parsed or
  /// assembled at runtime.
  const TokenGraphBoard(this.nodeIds, this.lines);

  /// Creates a board from [nodeIds] and [lines], validating the data first.
  ///
  /// Throws [ArgumentError] if: a line references an id not in [nodeIds];
  /// a line has fewer than 2 entries; a line contains the same node id
  /// twice; or [nodeIds] itself contains a duplicate id.
  factory TokenGraphBoard.validated(
    List<String> nodeIds,
    List<List<String>> lines,
  ) {
    final seenNodes = <String>{};
    for (final id in nodeIds) {
      if (!seenNodes.add(id)) {
        throw ArgumentError('TokenGraphBoard: duplicate node id "$id"');
      }
    }

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      if (line.length < 2) {
        throw ArgumentError(
          'TokenGraphBoard: line $lineIndex has fewer than 2 nodes: $line',
        );
      }
      final seenInLine = <String>{};
      for (final id in line) {
        if (!seenNodes.contains(id)) {
          throw ArgumentError(
            'TokenGraphBoard: line $lineIndex references unknown node "$id"',
          );
        }
        if (!seenInLine.add(id)) {
          throw ArgumentError(
            'TokenGraphBoard: line $lineIndex has duplicate node "$id": '
            '$line',
          );
        }
      }
    }

    return TokenGraphBoard(
      List<String>.unmodifiable(nodeIds),
      List<List<String>>.unmodifiable(
        lines.map((l) => List<String>.unmodifiable(l)),
      ),
    );
  }

  /// The index of [nodeId] within [nodeIds].
  ///
  /// Throws [ArgumentError] if [nodeId] is not a node on this board.
  int indexOf(String nodeId) {
    final index = nodeIds.indexOf(nodeId);
    if (index < 0) {
      throw ArgumentError('TokenGraphBoard: unknown node id "$nodeId"');
    }
    return index;
  }

  /// The `(lineIndex, positionInLine)` pairs recording every line [nodeId]
  /// belongs to, and its position within each.
  List<(int, int)> lineMembershipOf(String nodeId) {
    if (!nodeIds.contains(nodeId)) {
      throw ArgumentError('TokenGraphBoard: unknown node id "$nodeId"');
    }
    final result = <(int, int)>[];
    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final pos = lines[lineIndex].indexOf(nodeId);
      if (pos >= 0) result.add((lineIndex, pos));
    }
    return result;
  }

  /// For each node, how many distinct OTHER nodes it can reach by a single
  /// slide when every other node on the board is free.
  ///
  /// On an empty board a token is blocked by nothing, so from any node it
  /// can slide to ANY other node that shares a line with it - not just an
  /// immediate neighbour; a line with 3+ nodes lets the token jump clean
  /// over an intermediate node straight to the far end. A node's degree is
  /// therefore the number of distinct nodes appearing anywhere in any line
  /// the node belongs to (excluding itself), unioned across all of that
  /// node's lines.
  ///
  /// This is EMPTY-board reachability and must not be confused with the
  /// number of immediate neighbours a node has on a FULL board (every other
  /// node occupied), which corresponds instead to the edges actually drawn
  /// in a board diagram.
  Map<String, int> degreesOnEmptyBoard() {
    final degrees = <String, int>{};
    for (final id in nodeIds) {
      final reachable = <String>{};
      for (final line in lines) {
        if (line.contains(id)) {
          for (final other in line) {
            if (other != id) reachable.add(other);
          }
        }
      }
      degrees[id] = reachable.length;
    }
    return degrees;
  }
}
