import 'dart:io';

import 'package:module_playground/module_playground.dart';
import 'package:test/test.dart';

void main() {
  final game = PatternsGame.patterns5();

  PatternsState partial() => game.applyMove(
        game.applyMove(
          game.initialState(),
          const PlaygroundMove(['T1', 'S1r0']),
        ),
        const PlaygroundMove(['T25', 'S13r2']),
      ) as PatternsState;

  PatternsState full() {
    var state = game.initialState();
    for (var t = 0; t < game.tiles.length; t++) {
      state = game.applyMove(
        state,
        PlaygroundMove([game.tileId(t), '${game.slotId(t)}r${t % 4}']),
      );
    }
    return state as PatternsState;
  }

  test('a partially filled board survives a JSON round trip unchanged', () {
    final state = partial();
    expect(game.stateFromJson(game.stateToJson(state)), state);
  });

  test('a fully filled board survives a JSON round trip unchanged', () {
    final state = full();
    expect(game.stateFromJson(game.stateToJson(state)), state);
  });

  test('stateFromJson returns null (never throws) on defective input', () {
    Map<String, dynamic> validSlots() {
      final json = Map<String, dynamic>.from(game.stateToJson(partial()));
      json['slots'] = List<dynamic>.from(json['slots'] as List);
      return json;
    }

    // Not a map at all.
    expect(game.stateFromJson('not a map'), isNull);
    expect(game.stateFromJson(42), isNull);
    expect(game.stateFromJson(null), isNull);
    expect(game.stateFromJson(<dynamic>['a', 'list']), isNull);

    // 'slots' is not a list.
    expect(game.stateFromJson({'slots': 'nope'}), isNull);

    // 'slots' list of the wrong length.
    final tooShort = validSlots()
      ..update('slots', (s) => (s as List)..removeLast());
    expect(game.stateFromJson(tooShort), isNull);

    // An entry that is not a string.
    final notAString = validSlots()
      ..update('slots', (s) => (s as List)..[1] = 7);
    expect(game.stateFromJson(notAString), isNull);

    // A token with an unknown tile id: T26 is past the end of the tray.
    final unknownTile = validSlots()
      ..update('slots', (s) => (s as List)..[1] = 'T26r0');
    expect(game.stateFromJson(unknownTile), isNull);

    // A token without the 'r' separator.
    final noSeparator = validSlots()
      ..update('slots', (s) => (s as List)..[1] = 'T2x0');
    expect(game.stateFromJson(noSeparator), isNull);

    // A token with rotation 4.
    final badRotation = validSlots()
      ..update('slots', (s) => (s as List)..[1] = 'T2r4');
    expect(game.stateFromJson(badRotation), isNull);

    // The same tile id in two slots.
    final duplicateTile = validSlots()
      ..update('slots', (s) => (s as List)..[1] = 'T1r0');
    expect(game.stateFromJson(duplicateTile), isNull);
  });

  test('the shipped data carries a replayable twenty-five placement solution',
      () {
    final data = PlaygroundData.fromJsonString(
      File('assets/puzzles/module06.json').readAsStringSync(),
    );
    final shipped = PatternsGame.patterns5(data.forId('patterns5'));
    final solution = shipped.optimalSolution;
    expect(solution, isNotNull);
    expect(solution, hasLength(25));

    var state = shipped.initialState();
    for (final move in solution!) {
      expect(shipped.legalMoves(state, from: move.from), contains(move));
      state = shipped.applyMove(state, move);
    }
    expect(shipped.isSolved(state), isTrue);
  });
}
