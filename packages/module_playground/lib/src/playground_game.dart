/// The families of play-puzzle this module ships, grouped by the engine
/// that drives them rather than by theme: [tokenGraph] games slide labelled
/// tokens between named nodes along straight lines (see
/// `token_graph_board.dart`); [tilePlacement] games arrange discrete tiles
/// onto a fixed layout; [slidingBlocks] games slide rectangular blocks
/// inside a bounded frame. A game's `family` never changes after it ships -
/// it is metadata the list screen uses to route to the right engine/widget,
/// not gameplay state.
enum PlaygroundFamily { tokenGraph, tilePlacement, slidingBlocks }

/// Where a game's [PlaygroundGame.par] figure came from: [solver] means an
/// exhaustive search (typically breadth-first) proved it is the true
/// optimum; [book] means it is only the source book's printed claim,
/// transcribed but not independently verified. `null` on the owning game
/// means there is no move-economy question for that puzzle at all.
enum ParSource { solver, book }

/// The base type for a game's mutable play state. Each game family defines
/// its own concrete subclass (e.g. `TokenGraphState`); this module never
/// inspects a [PlaygroundState] except through the owning
/// [PlaygroundGame]'s own methods, so subclasses are free to shape their
/// data however suits the family.
abstract class PlaygroundState {
  const PlaygroundState();
}

/// A single move: the ordered sequence of node/cell ids a piece travels
/// through, from its origin to its destination. [path] always has at least
/// two entries - the first is where the piece starts ([from]), the last is
/// where it ends up ([to]); anything in between is the intermediate nodes a
/// slide passes over. Value equality and [hashCode] are content-based (two
/// moves with the same path in the same order are the same move), so a move
/// can be used as a `Set`/`Map` key or compared after a JSON round-trip.
class PlaygroundMove {
  /// The ordered ids the piece travels: first = origin, last = destination.
  /// Always at least 2 entries.
  final List<String> path;

  /// Creates a move from its travelled [path].
  const PlaygroundMove(this.path);

  /// The id the piece starts at.
  String get from => path.first;

  /// The id the piece ends at.
  String get to => path.last;

  @override
  bool operator ==(Object other) {
    if (other is! PlaygroundMove) return false;
    if (other.path.length != path.length) return false;
    for (var i = 0; i < path.length; i++) {
      if (other.path[i] != path[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(path);

  @override
  String toString() => 'PlaygroundMove(${path.join(' -> ')})';

  /// Serializes this move as a JSON-friendly list of ids, matching a
  /// `solution` entry in `module06.json`.
  List<String> toJson() => List<String>.unmodifiable(path);

  /// Parses a move from its JSON list-of-ids representation.
  ///
  /// Throws a [FormatException] if [json] is not a list of strings, or has
  /// fewer than 2 entries.
  factory PlaygroundMove.fromJson(Object? json) {
    if (json is! List) {
      throw FormatException('PlaygroundMove.fromJson: expected a list, got '
          '${json.runtimeType}');
    }
    if (json.length < 2) {
      throw FormatException(
        'PlaygroundMove.fromJson: path must have at least 2 entries, got '
        '${json.length}',
      );
    }
    final path = <String>[];
    for (final entry in json) {
      if (entry is! String) {
        throw FormatException(
          'PlaygroundMove.fromJson: path entries must be strings, got '
          '${entry.runtimeType}',
        );
      }
      path.add(entry);
    }
    return PlaygroundMove(path);
  }
}

/// The contract every playground game implements: a game knows its own
/// identity and shipping status ([id], [family], [enabled]), its
/// move-economy metadata ([par], [parProven], [parSource],
/// [optimalSolution]), and how to drive a play session (state creation,
/// legal-move enumeration, move application, win detection, and JSON
/// save/load of its state).
abstract class PlaygroundGame {
  const PlaygroundGame();

  /// Stable identifier within the module's registry (e.g. `eight_chips`).
  String get id;

  /// Which engine drives this game's rules and (later) UI.
  PlaygroundFamily get family;

  /// Whether this game is shipped and playable. `false` means the game is
  /// on the roadmap but not yet implemented; the list screen greys out and
  /// disables its row, and none of the state-touching methods below may be
  /// called on it.
  bool get enabled;

  /// Whether this is an introductory/tutorial entry. `false` for every
  /// playground game so far. The app's home screen counts puzzles via
  /// `(p as dynamic).tutorial` across all modules - do not remove this
  /// getter even though no playground game currently uses `true`.
  bool get tutorial => false;

  /// The proven-optimal (or book-claimed) minimum move count to solve this
  /// game, or `null` for games with no move-economy question at all (e.g. a
  /// game whose only goal is reaching *a* solved state, not the shortest
  /// path to one).
  int? get par;

  /// Whether [par] is a proven optimum (an exhaustive search found it),
  /// as opposed to merely the source book's printed claim.
  bool get parProven;

  /// Where [par] came from. `null` exactly when [par] is `null`.
  ParSource? get parSource;

  /// One recorded optimal solution reaching [par] moves from
  /// [initialState], if known.
  List<PlaygroundMove>? get optimalSolution;

  /// Builds this game's starting state.
  PlaygroundState initialState();

  /// Every legal move available from [state]. If [from] is non-null, the
  /// result is filtered to moves whose [PlaygroundMove.from] equals [from].
  List<PlaygroundMove> legalMoves(PlaygroundState state, {String? from});

  /// Applies [move] to [state], returning the resulting state.
  ///
  /// Throws [ArgumentError] if [move] is not currently legal in [state].
  PlaygroundState applyMove(PlaygroundState state, PlaygroundMove move);

  /// Whether [state] satisfies this game's win condition.
  bool isSolved(PlaygroundState state);

  /// Serializes [state] to a JSON-friendly map, for a save file.
  Map<String, dynamic> stateToJson(PlaygroundState state);

  /// Parses a state from its JSON representation, as produced by
  /// [stateToJson].
  ///
  /// Returns `null` on ANY defect in [json] (wrong shape, unknown ids,
  /// duplicate tokens, missing fields) - never throws. A `null` result
  /// means the session's load path must reset that save entry as a whole
  /// (board, solved, bestMoves, moveCount, moveStack all reset together),
  /// never keep a stale `solved: true` flag beside a freshly-reset board.
  PlaygroundState? stateFromJson(Object? json);
}
