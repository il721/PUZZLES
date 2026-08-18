import '../../data.dart';
import '../../playground_game.dart';
import '../token_graph/token_graph_board.dart';
import '../token_graph/token_graph_rules.dart';
import '../token_graph/token_graph_state.dart';

/// The valid token labels in «Восемь фишек»: chips `1` through `8`.
const Set<String> _validTokens = {'1', '2', '3', '4', '5', '6', '7', '8'};

/// The board's node ids: the 8 tips `P1`..`P8` (`P1` at the top, then
/// clockwise `P8, P7, P6, P5, P4, P3, P2`) plus the centre `C`. This data is
/// verified against the book scan (Мочалов, 1980, p. 68) and encoded
/// exactly - it is not re-derived here.
const List<String> _nodeIds = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8', 'C'];

/// The board's 10 straight lines, in collinear order. Verified against the
/// book scan and encoded exactly.
const List<List<String>> _lines = [
  ['P1', 'C', 'P5'],
  ['P3', 'C', 'P7'],
  ['P1', 'P4'],
  ['P1', 'P6'],
  ['P2', 'P5'],
  ['P2', 'P7'],
  ['P3', 'P6'],
  ['P3', 'P8'],
  ['P4', 'P7'],
  ['P5', 'P8'],
];

/// «Восемь фишек» (Мочалов, 1980, p. 68): 8 numbered chips sit on the 8
/// tips of an 8-pointed star, leaving the centre free; the player slides
/// chips along the star's straight lines to reverse the ring, so that chip
/// `t` (starting at tip `Pt`) ends up at the tip diametrically/rotationally
/// opposite in the book's numbering, `P(9-t)`, with the centre free again.
///
/// [par], [parProven], [parSource], and [optimalSolution] are supplied by
/// the parsed puzzle data ([PlaygroundGameData]) rather than hardcoded here,
/// so a data update (e.g. a re-verified par) does not require a code change.
class EightChipsGame extends PlaygroundGame {
  /// This game's board: 9 nodes, 10 lines, verified against the book scan.
  static const TokenGraphBoard board = TokenGraphBoard(_nodeIds, _lines);

  final PlaygroundGameData? _data;

  /// Creates the game, optionally backed by parsed puzzle data supplying
  /// [par]/[parProven]/[parSource]/[optimalSolution]. With no data, those
  /// all read as unset (`null`/`false`).
  const EightChipsGame([this._data]);

  @override
  String get id => 'eight_chips';

  @override
  PlaygroundFamily get family => PlaygroundFamily.tokenGraph;

  @override
  bool get enabled => true;

  @override
  int? get par => _data?.par;

  @override
  bool get parProven => _data?.parProven ?? false;

  @override
  ParSource? get parSource => _data?.parSource;

  @override
  List<PlaygroundMove>? get optimalSolution => _data?.solution;

  @override
  PlaygroundState initialState() {
    final tokens = List<String?>.filled(board.nodeIds.length, null);
    for (var t = 1; t <= 8; t++) {
      tokens[board.indexOf('P$t')] = '$t';
    }
    return TokenGraphState(tokens);
  }

  @override
  List<PlaygroundMove> legalMoves(PlaygroundState state, {String? from}) =>
      slideMoves(board, state as TokenGraphState, from: from);

  @override
  PlaygroundState applyMove(PlaygroundState state, PlaygroundMove move) =>
      applySlide(board, state as TokenGraphState, move);

  /// Whether every chip `t` sits on tip `P(9-t)` and the centre is free -
  /// checked as a predicate over the current position, not as equality
  /// against one stored winning state object.
  @override
  bool isSolved(PlaygroundState state) {
    final s = state as TokenGraphState;
    if (s.tokenAt(board.indexOf('C')) != null) return false;
    for (var t = 1; t <= 8; t++) {
      if (s.tokenAt(board.indexOf('P${9 - t}')) != '$t') return false;
    }
    return true;
  }

  @override
  Map<String, dynamic> stateToJson(PlaygroundState state) {
    final s = state as TokenGraphState;
    return {
      'positions': {
        for (final nodeId in board.nodeIds)
          nodeId: s.tokenAt(board.indexOf(nodeId)),
      },
    };
  }

  /// Parses a state saved by [stateToJson].
  ///
  /// Returns `null` (never throws) for: [json] not a map; a `positions`
  /// value that is not a map; a wrong node count (missing or extra node
  /// keys); an unknown or duplicate token label; or a position with no free
  /// node at all.
  @override
  PlaygroundState? stateFromJson(Object? json) {
    try {
      if (json is! Map) return null;
      final positions = json['positions'];
      if (positions is! Map) return null;
      if (positions.length != board.nodeIds.length) return null;

      final tokens = List<String?>.filled(board.nodeIds.length, null);
      final seenTokens = <String>{};
      var sawFreeNode = false;

      for (final nodeId in board.nodeIds) {
        if (!positions.containsKey(nodeId)) return null;
        final value = positions[nodeId];
        if (value == null) {
          sawFreeNode = true;
          continue;
        }
        if (value is! String) return null;
        if (!_validTokens.contains(value)) return null;
        if (!seenTokens.add(value)) return null;
        tokens[board.indexOf(nodeId)] = value;
      }

      if (!sawFreeNode) return null;

      return TokenGraphState(tokens);
    } catch (_) {
      return null;
    }
  }
}
