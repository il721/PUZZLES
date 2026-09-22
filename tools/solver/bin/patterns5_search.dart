import 'package:module_playground/module_playground.dart';

/// The outcome of a full «Узоры» search: how many valid patterns exist
/// ([solutions]), one of them as a ready-to-replay move list ([moves], one
/// placement per slot in slot order), and how many search nodes were
/// expanded getting there ([nodes]).
typedef PatternsSearchResult = ({
  int solutions,
  List<PlaygroundMove> moves,
  int nodes,
});

/// A union-find over the board's cells that can be rolled back, so the
/// search can undo a placement's unions when it backtracks.
///
/// [union] returns false when the two cells were already connected, i.e.
/// when joining them closes a loop - the search uses that as its main
/// pruning signal.
class _Rollback {
  final List<int> _parent;
  final List<int> _size;
  final List<int> _log = [];

  _Rollback(int n)
      : _parent = List<int>.generate(n, (i) => i),
        _size = List<int>.filled(n, 1);

  int find(int x) {
    var root = x;
    while (_parent[root] != root) {
      root = _parent[root];
    }
    return root;
  }

  bool union(int a, int b) {
    var ra = find(a);
    var rb = find(b);
    if (ra == rb) return false;
    if (_size[ra] < _size[rb]) {
      final swap = ra;
      ra = rb;
      rb = swap;
    }
    _parent[rb] = ra;
    _size[ra] += _size[rb];
    _log.add(rb);
    return true;
  }

  /// The number of unions performed so far; pass it back to [rollbackTo].
  int get mark => _log.length;

  void rollbackTo(int mark) {
    while (_log.length > mark) {
      final child = _log.removeLast();
      final root = _parent[child];
      _size[root] -= _size[child];
      _parent[child] = child;
    }
  }
}

/// One tile at one rotation, with the four edge signatures the search
/// matches on. A signature is two bits, one per cell on that edge, set when
/// the red line leaves the tile there: [left] is (top-left cell, bottom-left
/// cell), [top] is (top-left, top-right), [right] is (top-right,
/// bottom-right), [bottom] is (bottom-left, bottom-right).
typedef _Form = ({
  int tile,
  int rotation,
  List<int> masks,
  int left,
  int top,
  int right,
  int bottom,
});

/// Every tile at every rotation, as [_Form]s.
List<_Form> _forms(PatternsGame game) => [
      for (var tile = 0; tile < game.tiles.length; tile++)
        for (var rotation = 0; rotation < 4; rotation++)
          () {
            final m = patternsTileMasks(game.tiles[tile], rotation);
            int bit(int mask, int direction) => mask & direction != 0 ? 1 : 0;
            return (
              tile: tile,
              rotation: rotation,
              masks: m,
              left: bit(m[0], patternsWest) | bit(m[2], patternsWest) << 1,
              top: bit(m[0], patternsNorth) | bit(m[1], patternsNorth) << 1,
              right: bit(m[1], patternsEast) | bit(m[3], patternsEast) << 1,
              bottom: bit(m[2], patternsSouth) | bit(m[3], patternsSouth) << 1,
            );
          }(),
    ];

/// Exhaustively searches every way of laying [game]'s tiles into its slots
/// at every rotation, and returns all valid patterns.
///
/// Slots are filled in row-major order, and a slot's left and top edge
/// signatures are fully determined by the tiles already laid (by the board
/// border in the first row and column, where no red end may point outwards).
/// Forms are therefore bucketed by those two signatures up front, and the
/// search only ever looks at tiles that already fit - the remaining checks
/// are the tile still being in the tray, the right/bottom border, and the
/// loop test.
///
/// The loop test is the pruning that makes the search finish: no loop may
/// close before the last tile is down, because every cell of every tile has
/// the line running through it, so a loop that closes early can never grow
/// to cover the rest of the board and the whole branch is dead.
///
/// Tiles rotate but never flip, matching the one-sided cardboard of the
/// book. Whole-board rotations of a solution are themselves solutions.
///
/// Passing [stopAfter] cuts the search off once that many solutions have
/// been found, for callers that only need an example rather than a count.
PatternsSearchResult searchPatterns(PatternsGame game, {int? stopAfter}) {
  final size = game.size;
  final side = game.cellSide;
  final slotCount = game.slotCount;

  final byEdges = List<List<_Form>>.generate(16, (_) => <_Form>[]);
  for (final form in _forms(game)) {
    byEdges[form.left << 2 | form.top].add(form);
  }

  final cells = List<int>.filled(side * side, 0);
  final used = List<bool>.filled(game.tiles.length, false);
  final chosen = List<PatternsPlacement?>.filled(slotCount, null);
  final dsu = _Rollback(side * side);

  var solutions = 0;
  var nodes = 0;
  List<PatternsPlacement>? first;

  void descend(int slot) {
    if (slot == slotCount) {
      solutions++;
      first ??= [for (final p in chosen) p!];
      return;
    }
    final tr = slot ~/ size;
    final tc = slot % size;
    final tl = (2 * tr) * side + 2 * tc;
    final tt = tl + 1;
    final bl = tl + side;
    final br = bl + 1;

    final wantLeft = tc == 0
        ? 0
        : (cells[tl - 1] & patternsEast != 0 ? 1 : 0) |
            (cells[bl - 1] & patternsEast != 0 ? 2 : 0);
    final wantTop = tr == 0
        ? 0
        : (cells[tl - side] & patternsSouth != 0 ? 1 : 0) |
            (cells[tt - side] & patternsSouth != 0 ? 2 : 0);

    for (final form in byEdges[wantLeft << 2 | wantTop]) {
      nodes++;
      if (used[form.tile]) continue;
      if (tc == size - 1 && form.right != 0) continue;
      if (tr == size - 1 && form.bottom != 0) continue;

      final masks = form.masks;
      final mTl = masks[0];
      final mTr = masks[1];
      final mBl = masks[2];

      final mark = dsu.mark;
      var closedEarly = false;
      void join(int a, int b) {
        if (!dsu.union(a, b)) closedEarly = true;
      }

      if (mTl & patternsEast != 0) join(tl, tt);
      if (mTl & patternsSouth != 0) join(tl, bl);
      if (mTr & patternsSouth != 0) join(tt, br);
      if (mBl & patternsEast != 0) join(bl, br);
      if (tc > 0) {
        if (mTl & patternsWest != 0) join(tl, tl - 1);
        if (mBl & patternsWest != 0) join(bl, bl - 1);
      }
      if (tr > 0) {
        if (mTl & patternsNorth != 0) join(tl, tl - side);
        if (mTr & patternsNorth != 0) join(tt, tt - side);
      }

      if (closedEarly && slot != slotCount - 1) {
        dsu.rollbackTo(mark);
        continue;
      }

      cells[tl] = mTl;
      cells[tt] = mTr;
      cells[bl] = mBl;
      cells[br] = masks[3];
      used[form.tile] = true;
      chosen[slot] = PatternsPlacement(form.tile, form.rotation);

      descend(slot + 1);

      chosen[slot] = null;
      used[form.tile] = false;
      cells[tl] = 0;
      cells[tt] = 0;
      cells[bl] = 0;
      cells[br] = 0;
      dsu.rollbackTo(mark);

      if (stopAfter != null && solutions >= stopAfter) return;
    }
  }

  descend(0);

  return (
    solutions: solutions,
    nodes: nodes,
    moves: [
      if (first != null)
        for (var slot = 0; slot < slotCount; slot++)
          PlaygroundMove([
            game.tileId(first![slot].tile),
            '${game.slotId(slot)}r${first![slot].rotation}',
          ]),
    ],
  );
}

/// Prints the full «Узоры 5x5» search result: how many valid patterns
/// exist, how many nodes that took, and one pattern as its 25 placements.
void main() {
  final sw = Stopwatch()..start();
  final result = searchPatterns(PatternsGame.patterns5());
  sw.stop();
  print('solutions: ${result.solutions}');
  print('nodes:     ${result.nodes}');
  print('elapsed:   ${sw.elapsedMilliseconds} ms');
  for (final move in result.moves) {
    print('  ${move.from} -> ${move.to}');
  }
}
