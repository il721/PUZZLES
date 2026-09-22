import 'data.dart';
import 'games/cats_dogs/cats_dogs.dart';
import 'games/eight_chips/eight_chips.dart';
import 'games/hourglass/hourglass.dart';
import 'games/patterns/patterns.dart';
import 'games/swap_blocks/swap_blocks.dart';
import 'games/three_each/three_each.dart';
import 'playground_game.dart';

/// A game that is on the playground module's roadmap but not yet shipped.
/// [enabled] is always `false`; every state-touching method throws
/// [UnimplementedError] naming [id], since there is no rules engine behind
/// it yet. The list screen must never call [initialState], [legalMoves],
/// [applyMove], [isSolved], [stateToJson], or [stateFromJson] on a disabled
/// row - it should check [enabled] first and grey out/disable the row
/// instead.
class UnshippedPlaygroundGame extends PlaygroundGame {
  @override
  final String id;

  @override
  final PlaygroundFamily family;

  /// Creates a placeholder entry for the not-yet-shipped game [id].
  const UnshippedPlaygroundGame(this.id, this.family);

  @override
  bool get enabled => false;

  @override
  int? get par => null;

  @override
  bool get parProven => false;

  @override
  ParSource? get parSource => null;

  @override
  List<PlaygroundMove>? get optimalSolution => null;

  @override
  PlaygroundState initialState() =>
      throw UnimplementedError('"$id" is not yet implemented');

  @override
  List<PlaygroundMove> legalMoves(PlaygroundState state, {String? from}) =>
      throw UnimplementedError('"$id" is not yet implemented');

  @override
  PlaygroundState applyMove(PlaygroundState state, PlaygroundMove move) =>
      throw UnimplementedError('"$id" is not yet implemented');

  @override
  bool isSolved(PlaygroundState state) =>
      throw UnimplementedError('"$id" is not yet implemented');

  @override
  Map<String, dynamic> stateToJson(PlaygroundState state) =>
      throw UnimplementedError('"$id" is not yet implemented');

  @override
  PlaygroundState? stateFromJson(Object? json) =>
      throw UnimplementedError('"$id" is not yet implemented');
}

/// Builds the playground module's full game registry, in the fixed order
/// the list screen displays: `eight_chips`, `cats_dogs`, `hourglass`,
/// `three_each`, `patterns5`, `patterns4` and `swap_blocks` - all seven now
/// shipped. [UnshippedPlaygroundGame] stays in this file for the next
/// planned game and for tests/UI that still reference it.
///
/// [data] supplies every shipped game's parsed par/solution metadata (see
/// `assets/puzzles/module06.json`).
List<PlaygroundGame> buildPlaygroundRegistry(PlaygroundData data) => [
      EightChipsGame(data.forId('eight_chips')),
      CatsDogsGame(data.forId('cats_dogs')),
      HourglassGame(data.forId('hourglass')),
      ThreeEachGame(data.forId('three_each')),
      PatternsGame.patterns5(data.forId('patterns5')),
      PatternsGame.patterns4(data.forId('patterns4')),
      SwapBlocksGame(data.forId('swap_blocks')),
    ];
