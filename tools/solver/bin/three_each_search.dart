import 'package:module_playground/module_playground.dart';

/// The outcome of a full «Всюду по три» search: how many valid 9x9 squares
/// exist ([solutions]), one of them as a ready-to-replay move list
/// ([moves], nine placements in slot order), and how many search nodes were
/// expanded getting there ([nodes]).
typedef ThreeEachSearchResult = ({
  int solutions,
  List<PlaygroundMove> moves,
  int nodes,
});

/// Which of the twenty constraint lines each of the 81 cells belongs to:
/// its row (index 0-8), its column (index 9-17), and the main (18) and/or
/// anti (19) diagonal when it lies on one.
List<List<int>> _cellLines() => [
      for (var r = 0; r < 9; r++)
        for (var c = 0; c < 9; c++)
          [
            r,
            9 + c,
            if (r == c) 18,
            if (r + c == 8) 19,
          ],
    ];

/// Exhaustively searches every way of laying the nine tiles into the nine
/// slots at every rotation, and returns all valid squares.
///
/// Slots are filled in row-major order. Two prunings carry the search: no
/// line may ever hold two circles of one colour (checked as each circle is
/// placed), and the moment a tile-row is complete its three grid rows must
/// each hold exactly one red, one white and one black. Columns and both
/// diagonals are only complete once the last tile is down, so they are
/// verified there - by then the count-never-exceeds-one rule has already
/// discarded almost everything.
///
/// Tiles rotate but never flip, matching the one-sided cardboard of the
/// book. Whole-square rotations of a solution are themselves solutions, so
/// [ThreeEachSearchResult.solutions] is always a multiple of four.
ThreeEachSearchResult searchThreeEach() {
  final cellLines = _cellLines();
  // counts[line][colorIndex]
  final counts = [for (var i = 0; i < 20; i++) List<int>.filled(3, 0)];
  final used = List<bool>.filled(9, false);
  final chosen = List<ThreeEachPlacement?>.filled(9, null);

  var solutions = 0;
  var nodes = 0;
  List<ThreeEachPlacement>? first;

  int colorIndex(String cell) => threeEachColors.indexOf(cell);

  /// Adds tile [tile] at rotation [rot] into slot [slot]; returns false (and
  /// rolls back) as soon as some line would hold two circles of one colour.
  bool place(int slot, int tile, int rot) {
    final rowBase = (slot ~/ 3) * 3;
    final colBase = (slot % 3) * 3;
    final touched = <(int, int)>[];
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        final cell = threeEachCell(tile, rot, r, c);
        if (cell == threeEachEmpty) continue;
        final color = colorIndex(cell);
        for (final line in cellLines[(rowBase + r) * 9 + colBase + c]) {
          counts[line][color]++;
          touched.add((line, color));
          if (counts[line][color] > 1) {
            for (final (l, k) in touched) {
              counts[l][k]--;
            }
            return false;
          }
        }
      }
    }
    return true;
  }

  void unplace(int slot, int tile, int rot) {
    final rowBase = (slot ~/ 3) * 3;
    final colBase = (slot % 3) * 3;
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        final cell = threeEachCell(tile, rot, r, c);
        if (cell == threeEachEmpty) continue;
        final color = colorIndex(cell);
        for (final line in cellLines[(rowBase + r) * 9 + colBase + c]) {
          counts[line][color]--;
        }
      }
    }
  }

  bool linesComplete(Iterable<int> lines) =>
      lines.every((line) => counts[line].every((n) => n == 1));

  void descend(int slot) {
    if (slot == 9) {
      if (!linesComplete([for (var i = 9; i < 20; i++) i])) return;
      solutions++;
      first ??= [for (final p in chosen) p!];
      return;
    }
    for (var tile = 0; tile < 9; tile++) {
      if (used[tile]) continue;
      for (var rot = 0; rot < 4; rot++) {
        nodes++;
        if (!place(slot, tile, rot)) continue;
        // A finished tile-row fixes its three grid rows for good.
        final rowsDone = slot % 3 == 2;
        if (!rowsDone ||
            linesComplete([
              for (var r = (slot ~/ 3) * 3; r < (slot ~/ 3) * 3 + 3; r++) r,
            ])) {
          used[tile] = true;
          chosen[slot] = ThreeEachPlacement(tile, rot);
          descend(slot + 1);
          used[tile] = false;
          chosen[slot] = null;
        }
        unplace(slot, tile, rot);
      }
    }
  }

  descend(0);

  return (
    solutions: solutions,
    nodes: nodes,
    moves: [
      if (first != null)
      for (var slot = 0; slot < 9; slot++)
        PlaygroundMove([
          threeEachTileIds[first![slot].tile],
          '${threeEachSlotIds[slot]}r${first![slot].rotation}',
        ]),
    ],
  );
}

/// Prints the full search result: how many valid squares exist, how many
/// nodes that took, and one solution as its nine placements.
void main() {
  final sw = Stopwatch()..start();
  final result = searchThreeEach();
  sw.stop();
  print('solutions: ${result.solutions}');
  print('nodes:     ${result.nodes}');
  print('elapsed:   ${sw.elapsedMilliseconds} ms');
  for (final move in result.moves) {
    print('  ${move.from} -> ${move.to}');
  }
}
