import '../../data.dart';
import '../../playground_game.dart';
import '../token_graph/token_graph_board.dart';
import '../token_graph/token_graph_rules.dart';
import '../token_graph/token_graph_state.dart';

/// The label carried by each of the three cats («кошки»). All three cats are
/// interchangeable, so they share one label - the puzzle never asks which
/// cat ended up where, only that cats and dogs swapped sides. The book
/// prints these as К (cat) and С (dog); the app uses the Latin letters C
/// (cat) and D (dog) instead.
const String catToken = 'C';

/// The label carried by each of the three dogs («собаки»). Interchangeable
/// for the same reason as [catToken].
const String dogToken = 'D';

/// The board's node ids: three left seats (`L1`..`L3`, top to bottom) where
/// the cats start, three right seats (`R1`..`R3`) where the dogs start, the
/// lone top and bottom nodes (`TM`, `BM`), the upper and lower inner pairs
/// (`U1`/`U2`, `D1`/`D2`, left then right) and the centre `M`.
const List<String> _nodeIds = [
  'L1',
  'L2',
  'L3',
  'R1',
  'R2',
  'R3',
  'TM',
  'BM',
  'U1',
  'U2',
  'M',
  'D1',
  'D2',
];

/// The board's 16 alleys. Transcribed from the book scan (Мочалов, 1980,
/// p. 66) and confirmed by the user against a render-back of this encoding:
/// the thirteen nodes sit on a diagonal lattice and an alley joins every
/// pair of diagonal neighbours.
///
/// Every line here has exactly TWO nodes, and that is what reduces the
/// shared token-graph slide engine (slide along a line any distance, blocked
/// by an occupied node) to this game's rule "step to an ADJACENT free node":
/// with no third node on a line there is nothing to slide past.
const List<List<String>> _lines = [
  ['L1', 'U1'],
  ['TM', 'U1'],
  ['TM', 'U2'],
  ['R1', 'U2'],
  ['U1', 'L2'],
  ['U1', 'M'],
  ['U2', 'M'],
  ['U2', 'R2'],
  ['L2', 'D1'],
  ['M', 'D1'],
  ['M', 'D2'],
  ['R2', 'D2'],
  ['D1', 'L3'],
  ['D1', 'BM'],
  ['D2', 'BM'],
  ['D2', 'R3'],
];

/// The three seats the cats start on - and the three the dogs must end on.
const List<String> catSeats = ['L1', 'L2', 'L3'];

/// The three seats the dogs start on - and the three the cats must end on.
const List<String> dogSeats = ['R1', 'R2', 'R3'];

/// Whether [state] is a position the puzzle permits at all: no cat stands on
/// a node adjacent to a dog. Positions violating this are not merely
/// undesirable, they are illegal - the corresponding move is never offered,
/// so a player cannot walk into one (see [CatsDogsGame.legalMoves]).
///
/// Relies on every line of [CatsDogsGame.board] having exactly two nodes, so
/// "shares a line" and "is adjacent" are the same relation here.
bool isPeacefulPosition(TokenGraphState state) {
  final board = CatsDogsGame.board;
  for (final line in board.lines) {
    final a = state.tokenAt(board.indexOf(line[0]));
    if (a == null) continue;
    final b = state.tokenAt(board.indexOf(line[1]));
    if (b == null) continue;
    if (a != b) return false;
  }
  return true;
}

/// «Кошки и собаки» (Мочалов, 1980, p. 66): three cats sit on the left
/// column of a thirteen-node park, three dogs on the right, and they want to
/// swap sides. One animal per move steps along an alley to an adjacent free
/// node, and no cat may ever end up adjacent to a dog.
///
/// [par], [parProven], [parSource] and [optimalSolution] come from the
/// parsed puzzle data ([PlaygroundGameData]) rather than being hardcoded, so
/// a data update does not require a code change.
class CatsDogsGame extends PlaygroundGame {
  /// This game's board: 13 nodes, 16 two-node alleys, transcribed from the
  /// book scan and confirmed by render-back.
  static const TokenGraphBoard board = TokenGraphBoard(_nodeIds, _lines);

  final PlaygroundGameData? _data;

  /// Creates the game, optionally backed by parsed puzzle data supplying
  /// [par]/[parProven]/[parSource]/[optimalSolution].
  const CatsDogsGame([this._data]);

  @override
  String get id => 'cats_dogs';

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
    for (final seat in catSeats) {
      tokens[board.indexOf(seat)] = catToken;
    }
    for (final seat in dogSeats) {
      tokens[board.indexOf(seat)] = dogToken;
    }
    return TokenGraphState(tokens);
  }

  /// Every step available in [state] whose RESULT is a peaceful position:
  /// a move that would put a cat next to a dog is simply not offered, which
  /// is how the "never adjacent" rule is enforced - there is no error path
  /// for the player to hit.
  @override
  List<PlaygroundMove> legalMoves(PlaygroundState state, {String? from}) {
    final s = state as TokenGraphState;
    return [
      for (final move in slideMoves(board, s, from: from))
        if (isPeacefulPosition(_moved(s, move))) move,
    ];
  }

  @override
  PlaygroundState applyMove(PlaygroundState state, PlaygroundMove move) {
    final legalFromOrigin = legalMoves(state, from: move.from);
    if (!legalFromOrigin.contains(move)) {
      throw ArgumentError(
        'CatsDogsGame: $move is not a legal move in state $state',
      );
    }
    return applySlide(board, state as TokenGraphState, move);
  }

  /// Whether the animals have swapped sides: every cat seat holds a dog and
  /// every dog seat holds a cat. Since exactly three of each token are on
  /// the board, that also forces every other node to be free - checked as a
  /// predicate over occupancy by token CLASS, never as equality against one
  /// stored winning arrangement (the cats are interchangeable, so there is
  /// no single winning arrangement).
  @override
  bool isSolved(PlaygroundState state) {
    final s = state as TokenGraphState;
    for (final seat in catSeats) {
      if (s.tokenAt(board.indexOf(seat)) != dogToken) return false;
    }
    for (final seat in dogSeats) {
      if (s.tokenAt(board.indexOf(seat)) != catToken) return false;
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
  /// value that is not a map; a wrong node count or a missing node key; an
  /// unknown token label; a token census other than exactly three cats and
  /// three dogs; or a position in which a cat stands next to a dog, which no
  /// legal play can produce.
  @override
  PlaygroundState? stateFromJson(Object? json) {
    try {
      if (json is! Map) return null;
      final positions = json['positions'];
      if (positions is! Map) return null;
      if (positions.length != board.nodeIds.length) return null;

      final tokens = List<String?>.filled(board.nodeIds.length, null);
      var cats = 0;
      var dogs = 0;

      for (final nodeId in board.nodeIds) {
        if (!positions.containsKey(nodeId)) return null;
        final value = positions[nodeId];
        if (value == null) continue;
        if (value is! String) return null;
        if (value == catToken) {
          cats++;
        } else if (value == dogToken) {
          dogs++;
        } else {
          return null;
        }
        tokens[board.indexOf(nodeId)] = value;
      }

      if (cats != catSeats.length || dogs != dogSeats.length) return null;

      final state = TokenGraphState(tokens);
      if (!isPeacefulPosition(state)) return null;
      return state;
    } catch (_) {
      return null;
    }
  }

  /// [state] with [move]'s piece relocated, WITHOUT re-validating the move -
  /// used by [legalMoves] to test a candidate's result before offering it,
  /// where re-validation would recurse.
  TokenGraphState _moved(TokenGraphState state, PlaygroundMove move) {
    final tokens = List<String?>.of(state.tokens);
    final fromIndex = board.indexOf(move.from);
    final toIndex = board.indexOf(move.to);
    tokens[toIndex] = tokens[fromIndex];
    tokens[fromIndex] = null;
    return TokenGraphState(tokens);
  }
}
