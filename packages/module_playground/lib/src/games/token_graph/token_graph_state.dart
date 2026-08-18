import '../../playground_game.dart';

/// The play state of a token-graph game: which token (if any) sits on each
/// board node. [tokens] is indexed by node index (matching
/// `TokenGraphBoard.indexOf`/`nodeIds`), so `tokens[i]` is the token label
/// on node `i`, or `null` if that node is free. Immutable and
/// content-comparable: two states with the same tokens in the same node
/// order are `==` and share a [hashCode], regardless of how they were
/// built - this is what lets the BFS solver use states as visited-set keys.
class TokenGraphState extends PlaygroundState {
  /// The token label on each node, indexed by node index; `null` means the
  /// node is free.
  final List<String?> tokens;

  /// Creates a state directly from a per-node [tokens] list.
  const TokenGraphState(this.tokens);

  /// The token on node index [index], or `null` if it is free.
  String? tokenAt(int index) => tokens[index];

  /// The node index holding [token].
  ///
  /// Throws [StateError] if no node currently holds [token].
  int indexOfToken(String token) {
    final index = tokens.indexOf(token);
    if (index < 0) {
      throw StateError('TokenGraphState: token "$token" is not on the board');
    }
    return index;
  }

  /// Every node index that is currently free.
  List<int> get freeIndexes => [
        for (var i = 0; i < tokens.length; i++)
          if (tokens[i] == null) i,
      ];

  /// A compact string uniquely determined by [tokens] - used as a hash-map
  /// key by the BFS solver, so it must be cheap to compute and collision-free
  /// across distinct token arrangements. Free nodes are represented by an
  /// empty segment so two different token labels never collide with a gap.
  String key() => tokens.map((t) => t ?? '').join(',');

  @override
  bool operator ==(Object other) {
    if (other is! TokenGraphState) return false;
    if (other.tokens.length != tokens.length) return false;
    for (var i = 0; i < tokens.length; i++) {
      if (other.tokens[i] != tokens[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(tokens);

  @override
  String toString() => 'TokenGraphState(${tokens.join(', ')})';
}
