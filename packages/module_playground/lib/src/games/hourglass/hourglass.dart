import '../../data.dart';
import '../../playground_game.dart';
import '../token_graph/token_graph_board.dart';
import '../token_graph/token_graph_jump_rules.dart';
import '../token_graph/token_graph_state.dart';

/// The label every one of the fifteen tokens carries. They are completely
/// interchangeable - the puzzle only asks that the lower triangle end up
/// full, never which token landed where - so they share a single label and
/// [HourglassGame.isSolved] is a pure occupancy test.
const String hourglassToken = 'T';

/// The board's 29 node ids, row by row from the top: the upper triangle
/// narrows `A`(5) - `B`(4) - `C`(3) - `D`(2) down to the single waist node
/// `E1`, and the lower triangle widens again `F`(2) - `G`(3) - `H`(4) -
/// `I`(5). Within a row the index runs left to right.
const List<String> _nodeIds = [
  'A1',
  'A2',
  'A3',
  'A4',
  'A5',
  'B1',
  'B2',
  'B3',
  'B4',
  'C1',
  'C2',
  'C3',
  'D1',
  'D2',
  'E1',
  'F1',
  'F2',
  'G1',
  'G2',
  'G3',
  'H1',
  'H2',
  'H3',
  'H4',
  'I1',
  'I2',
  'I3',
  'I4',
  'I5',
];

/// The board's 14 straight lines - every maximal diagonal of the lattice,
/// each listed in physical order along the line. Transcribed from the book
/// scan (Мочалов, 1980, p. 67) and confirmed by the user against a
/// render-back of this encoding: the drawn edges are exactly the
/// consecutive pairs of these lines (40 of them), and there are no
/// horizontal edges - the red curves in the scan are the glass itself, not
/// playable lines.
///
/// Lines carry two rules at once here: a step goes to a node ONE position
/// away on some line, and a jump goes over the next node onto the one
/// straight beyond - three consecutive entries of a single line. Two lines
/// run the full height of the hourglass through the waist (`A1`..`I5` and
/// `A5`..`I1`); they are what lets a token cross from the upper triangle
/// into the lower one.
const List<List<String>> _lines = [
  ['A1', 'B1', 'C1', 'D1', 'E1', 'F2', 'G3', 'H4', 'I5'],
  ['A2', 'B2', 'C2', 'D2'],
  ['A3', 'B3', 'C3'],
  ['A4', 'B4'],
  ['F1', 'G2', 'H3', 'I4'],
  ['G1', 'H2', 'I3'],
  ['H1', 'I2'],
  ['A2', 'B1'],
  ['A3', 'B2', 'C1'],
  ['A4', 'B3', 'C2', 'D1'],
  ['A5', 'B4', 'C3', 'D2', 'E1', 'F1', 'G1', 'H1', 'I1'],
  ['F2', 'G2', 'H2', 'I2'],
  ['G3', 'H3', 'I3'],
  ['H4', 'I4'],
];

/// The fifteen nodes of the upper triangle, where all fifteen tokens start.
/// The waist node `E1` belongs to BOTH triangles - it is the one node they
/// share, exactly as drawn.
const List<String> hourglassTopNodes = [
  'A1',
  'A2',
  'A3',
  'A4',
  'A5',
  'B1',
  'B2',
  'B3',
  'B4',
  'C1',
  'C2',
  'C3',
  'D1',
  'D2',
  'E1',
];

/// The fifteen nodes of the lower triangle, the ones every token must end
/// up on. Shares the waist node `E1` with [hourglassTopNodes].
const List<String> hourglassBottomNodes = [
  'E1',
  'F1',
  'F2',
  'G1',
  'G2',
  'G3',
  'H1',
  'H2',
  'H3',
  'H4',
  'I1',
  'I2',
  'I3',
  'I4',
  'I5',
];

/// «Песочные часы» (Мочалов, 1980, pp. 67-68): fifteen tokens fill the
/// upper triangle of an hourglass-shaped board and must all be brought into
/// the lower one. A token either steps along a drawn line to an adjacent
/// free circle or jumps, checkers-style, straight over an adjacent token
/// onto the free circle beyond; a cascade of consecutive jumps by one token
/// counts as a single move, and a step may never be mixed into a cascade
/// (see [stepJumpMoves]).
///
/// The book prints no answer for this puzzle, so [par] comes from this
/// project's own search (`tools/solver/bin/verify_module06.dart`) through
/// the parsed puzzle data, exactly like every other playground game.
class HourglassGame extends PlaygroundGame {
  /// This game's board: 29 nodes on 14 straight lines, transcribed from the
  /// book scan and confirmed by render-back.
  static const TokenGraphBoard board = TokenGraphBoard(_nodeIds, _lines);

  final PlaygroundGameData? _data;

  /// Creates the game, optionally backed by parsed puzzle data supplying
  /// [par]/[parProven]/[parSource]/[optimalSolution].
  const HourglassGame([this._data]);

  @override
  String get id => 'hourglass';

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
  PlaygroundState initialState() => _stateOn(hourglassTopNodes);

  /// The one and only solved position: the lower triangle full. Fifteen
  /// tokens on fifteen nodes leaves no freedom, so unlike `cats_dogs` this
  /// game really does have a unique target - which a meet-in-the-middle
  /// search needs, since it must search backwards from the goal as a STATE,
  /// not merely as a predicate.
  static TokenGraphState goalState() => _stateOn(hourglassBottomNodes);

  static TokenGraphState _stateOn(List<String> nodes) {
    final tokens = List<String?>.filled(_nodeIds.length, null);
    for (final id in nodes) {
      tokens[board.indexOf(id)] = hourglassToken;
    }
    return TokenGraphState(tokens);
  }

  @override
  List<PlaygroundMove> legalMoves(PlaygroundState state, {String? from}) =>
      stepJumpMoves(board, state as TokenGraphState, from: from);

  @override
  PlaygroundState applyMove(PlaygroundState state, PlaygroundMove move) =>
      applyStepJump(board, state as TokenGraphState, move);

  /// Whether every node of the lower triangle is occupied. With exactly
  /// fifteen tokens on the board and fifteen nodes in that triangle, a full
  /// lower triangle also forces the upper one empty - tested as occupancy,
  /// never as equality against a stored winning arrangement, because the
  /// tokens are interchangeable.
  @override
  bool isSolved(PlaygroundState state) {
    final s = state as TokenGraphState;
    for (final id in hourglassBottomNodes) {
      if (s.tokenAt(board.indexOf(id)) == null) return false;
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
  /// value that is not a map; a wrong node count or a missing node key; a
  /// value that is neither `null` nor [hourglassToken]; or a token census
  /// other than exactly fifteen tokens.
  @override
  PlaygroundState? stateFromJson(Object? json) {
    try {
      if (json is! Map) return null;
      final positions = json['positions'];
      if (positions is! Map) return null;
      if (positions.length != board.nodeIds.length) return null;

      final tokens = List<String?>.filled(board.nodeIds.length, null);
      var count = 0;

      for (final nodeId in board.nodeIds) {
        if (!positions.containsKey(nodeId)) return null;
        final value = positions[nodeId];
        if (value == null) continue;
        if (value != hourglassToken) return null;
        tokens[board.indexOf(nodeId)] = hourglassToken;
        count++;
      }

      if (count != hourglassTopNodes.length) return null;

      return TokenGraphState(tokens);
    } catch (_) {
      return null;
    }
  }
}
