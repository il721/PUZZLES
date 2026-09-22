import 'package:module_playground/module_playground.dart';
import 'package:test/test.dart';

/// The pattern printed as the answer in the book (Мочалов, 1980, p. 116),
/// transcribed from that page independently of the tile figure on p. 62 and
/// matched back onto the tiles: one entry per slot, S1..S25 in row-major
/// order.
const List<String> bookAnswer = [
  'T6r3', 'T14r1', 'T20r0', 'T21r1', 'T12r1', //
  'T18r1', 'T25r2', 'T1r3', 'T16r0', 'T10r1', //
  'T19r3', 'T22r1', 'T9r2', 'T23r1', 'T7r0', //
  'T11r2', 'T3r3', 'T2r3', 'T4r1', 'T8r1', //
  'T13r3', 'T5r2', 'T15r3', 'T17r0', 'T24r3', //
];

PlaygroundState _lay(PatternsGame game, List<String> placements) {
  var state = game.initialState();
  for (var slot = 0; slot < placements.length; slot++) {
    final parts = placements[slot].split('r');
    state = game.applyMove(
      state,
      PlaygroundMove([parts[0], '${game.slotId(slot)}r${parts[1]}']),
    );
  }
  return state;
}

void main() {
  final game = PatternsGame.patterns5();

  test("the book's printed answer is a solution under the shipped rules", () {
    expect(game.isSolved(_lay(game, bookAnswer)), isTrue);
  });

  test('the answer uses each of the twenty-five tiles exactly once', () {
    final tiles = bookAnswer.map((p) => p.split('r').first).toSet();
    expect(tiles, hasLength(25));
  });

  test('an unfinished board is never solved', () {
    final state = _lay(game, bookAnswer.sublist(0, 24)) as PatternsState;
    expect(state.slots.last, isNull);
    expect(game.isSolved(state), isFalse);
  });

  test('turning one tile of the answer breaks it', () {
    var state = _lay(game, bookAnswer);
    state = game.applyMove(state, const PlaygroundMove(['S13', 'S13r0']));
    expect(game.isSolved(state), isFalse);
  });

  test('swapping two tiles of the answer breaks it', () {
    final swapped = [...bookAnswer];
    swapped[0] = bookAnswer[1];
    swapped[1] = bookAnswer[0];
    expect(game.isSolved(_lay(game, swapped)), isFalse);
  });

  test('a board of four self-closed rings is matched but not one loop', () {
    // Each tile closes a loop inside itself: nothing points outwards, so
    // every edge matches and the border is clean, yet the board carries
    // four separate loops instead of one.
    final rings = PatternsGame(
      id: 'rings',
      tiles: const [
        ['SE', 'SW', 'NE', 'NW'],
        ['SE', 'SW', 'NE', 'NW'],
        ['SE', 'SW', 'NE', 'NW'],
        ['SE', 'SW', 'NE', 'NW'],
      ],
      size: 2,
    );
    expect(
      rings.isSolved(_lay(rings, const ['T1r0', 'T2r0', 'T3r0', 'T4r0'])),
      isFalse,
    );
  });

  test('a two-by-two board whose sixteen cells form one loop is solved', () {
    final loop = PatternsGame(
      id: 'loop',
      tiles: const [
        ['SE', 'EW', 'NS', 'SE'],
        ['EW', 'SW', 'EW', 'NW'],
        ['NS', 'NE', 'NE', 'EW'],
        ['EW', 'SW', 'EW', 'NW'],
      ],
      size: 2,
    );
    expect(
      loop.isSolved(_lay(loop, const ['T1r0', 'T2r0', 'T3r0', 'T4r0'])),
      isTrue,
    );
  });
}
