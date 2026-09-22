import 'dart:io';
import 'dart:typed_data';

import 'package:module_playground/module_playground.dart';

import 'hourglass_search.dart' show IdenticalTokenSearchResult;

/// Shortest-path search for «Поменяйте местами», proving the minimum number
/// of moves from the start layout to [SwapBlocksGame.goalState].
///
/// [solveIdenticalTokens] (used for «Песочные часы») cannot be reused here:
/// that search represents a position as a single occupancy bitmask because
/// its tokens are fully interchangeable *and* single-cell. Here twelve
/// 8-cell blocks each occupy one of only 70 bounding-box origins, and a move
/// slides a block through free space turning corners for free, so the state
/// is a tuple of twelve origins, not a set of occupied cells - a bitmask
/// alone cannot represent "which block sits where". A Python prototype of
/// this search reached 734128 states at depth 12 on EACH side without the
/// two frontiers meeting, so the true answer is at least 25 moves and the
/// closure runs into the tens of millions - hence the open-addressed
/// [_VisitedTable] below rather than a `Map`, and the packed-integer
/// canonical key rather than a string or list key.
///
/// A position is twelve blocks' bounding-box origins, `row * 8 + col`, in
/// block order, as a `Uint8List(12)`. Two blocks are interchangeable iff
/// they share both shape and colour ([swapBlocksShapes]/[swapBlocksColours]
/// pair up eight such classes); the CANONICAL key sorts a position's origin
/// codes within each class before packing, so two positions that differ
/// only by which same-class block sits where hash identically. The twelve
/// 7-bit codes (0..127) are packed into two 64-bit ints: the first nine into
/// [_keyLo] (63 bits), the last three into [_keyHi] (21 bits).
///
/// The [_VisitedTable] marks which side reached a canonical position and at
/// what depth, exactly like [IdenticalTokenSearchResult]'s hourglass
/// precedent: `0` unvisited, `1 + d` reached by the forward search at depth
/// `d`, `64 + d` by the backward search. The search is bidirectional,
/// always expanding the smaller frontier, and finishes the whole frontier
/// level before turning a meeting into an answer - so the first answer
/// returned is the true optimum. No parent pointers are stored; the
/// solution is re-walked afterwards through the depth marks, and each
/// consecutive pair of positions is turned back into a [PlaygroundMove] by
/// asking the shipped [SwapBlocksGame.legalMoves]/`applyMove` which move
/// produces it - canonicalized before comparison, since the canonical form
/// found during the walk may relabel which same-class block index the move
/// actually touched.
IdenticalTokenSearchResult searchSwapBlocks() => _Search().run();

/// Board dimension used to decode/encode origin codes; matches
/// [swapBlocksRows]/[swapBlocksCols].
const int _cols = swapBlocksCols;

/// The forward search's depth-0 mark; depth `d` is stored as `_forward + d`.
const int _forward = 1;

/// The backward search's depth-0 mark; depth `d` is stored as
/// `_backward + d`. Keeps forward marks (1..63) and backward marks
/// (64..126) in disjoint ranges of one byte.
const int _backward = 64;

/// The visited table's slot count. Must be a power of two. At the default
/// (33554432 slots) the table can hold ~23.4 million positions before
/// hitting the 70% load-factor ceiling in [_VisitedTable.markSlot]; bump
/// this constant (and re-run) if the search reports exceeding it.
const int _tableCapacity = 1 << 25;

/// One shape's precomputed per-origin data, indexed by origin code
/// (`row * 8 + col`, 0..127; only rows 0..13, cols 0..4 are ever valid,
/// since every shape's bounding box is 3 rows x 4 columns).
class _ShapeTable {
  /// `maskLo[code]`/`maskHi[code]`: the shape's occupancy at [code], split
  /// across cells 0..63 ([maskLo]) and 64..127 ([maskHi]). Zero at an
  /// invalid code.
  final Int64List maskLo;

  /// See [maskLo].
  final Int64List maskHi;

  /// Whether [code] is a legal bounding-box origin for this shape (i.e. the
  /// box fits inside the 16x8 board). Independent of any other block's
  /// position - that is what [_expand] checks dynamically.
  final Uint8List valid;

  /// `adjacent[code]`: the valid origin codes one orthogonal step (up,
  /// down, left, right) from [code].
  final List<List<int>> adjacent;

  _ShapeTable(this.maskLo, this.maskHi, this.valid, this.adjacent);

  factory _ShapeTable.build(SwapBlocksShape shape) {
    final maskLo = Int64List(128);
    final maskHi = Int64List(128);
    final valid = Uint8List(128);
    final offsets = swapBlocksShapeOffsets[shape]!;

    for (var row = 0; row <= swapBlocksRows - 3; row++) {
      for (var col = 0; col <= swapBlocksCols - 4; col++) {
        final code = row * _cols + col;
        valid[code] = 1;
        var lo = 0;
        var hi = 0;
        for (final (dr, dc) in offsets) {
          final cell = (row + dr) * _cols + (col + dc);
          if (cell < 64) {
            lo |= 1 << cell;
          } else {
            hi |= 1 << (cell - 64);
          }
        }
        maskLo[code] = lo;
        maskHi[code] = hi;
      }
    }

    final adjacent = List<List<int>>.generate(128, (code) {
      if (valid[code] == 0) return const [];
      final row = code ~/ _cols;
      final col = code % _cols;
      final result = <int>[];
      for (final (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
        final r = row + dr;
        final c = col + dc;
        if (r < 0 || c < 0 || r >= swapBlocksRows || c >= swapBlocksCols) {
          continue;
        }
        final neighbourCode = r * _cols + c;
        if (valid[neighbourCode] == 1) result.add(neighbourCode);
      }
      return result;
    });

    return _ShapeTable(maskLo, maskHi, valid, adjacent);
  }
}

/// An open-addressed set/map from a canonical position key (a `(lo, hi)`
/// pair, see the file comment) to a one-byte depth mark, sized to the tens
/// of millions of positions this search's closure needs. Linear probing;
/// `0` in [mark] means the slot is empty. Fails loudly rather than
/// degrading if the load factor would exceed 70%, since silent degradation
/// there would turn into unbounded probe chains.
class _VisitedTable {
  final Int64List keyLo = Int64List(_tableCapacity);
  final Int64List keyHi = Int64List(_tableCapacity);
  final Uint8List mark = Uint8List(_tableCapacity);
  int count = 0;

  static const int _maxCount = (_tableCapacity * 7) ~/ 10;

  int _hash(int lo, int hi) {
    var h = lo ^ (hi * 0x9E3779B97F4A7C15);
    h ^= h >>> 33;
    h *= 0xFF51AFD7ED558CCD;
    h ^= h >>> 33;
    return h & (_tableCapacity - 1);
  }

  /// Finds [lo]/[hi]'s slot: an existing slot holding that exact key, or the
  /// first empty slot on its probe sequence if it is not yet present.
  int findSlot(int lo, int hi) {
    var idx = _hash(lo, hi);
    while (true) {
      if (mark[idx] == 0) return idx;
      if (keyLo[idx] == lo && keyHi[idx] == hi) return idx;
      idx = (idx + 1) & (_tableCapacity - 1);
    }
  }

  /// Marks [slot] (as returned by [findSlot]) with [markValue], recording
  /// [lo]/[hi] as its key if the slot was empty. Throws [StateError] if this
  /// insertion would push the table's load factor past 70%.
  void markSlot(int slot, int lo, int hi, int markValue) {
    if (mark[slot] == 0) {
      count++;
      if (count > _maxCount) {
        throw StateError(
          'swap_blocks_search: visited table exceeded 70% load of '
          '_tableCapacity ($_tableCapacity slots); raise _tableCapacity',
        );
      }
      keyLo[slot] = lo;
      keyHi[slot] = hi;
    }
    mark[slot] = markValue;
  }
}

class _Search {
  final List<_ShapeTable> shapeTables =
      SwapBlocksShape.values.map(_ShapeTable.build).toList();

  /// Block indices grouped by (shape, colour) class, in block-index order;
  /// only classes with more than one member are kept, since a singleton
  /// class needs no sorting. Derived from the shipped [swapBlocksShapes]/
  /// [swapBlocksColours] so the classes are never hand-duplicated here.
  final List<List<int>> classGroups = _buildClassGroups();

  final _VisitedTable visited = _VisitedTable();

  /// Reused scratch buffers so the hot expand loop does not allocate per
  /// position/child.
  final Uint8List _origins = Uint8List(12);
  final Uint8List _childOrigins = Uint8List(12);
  final Uint8List _sortBuf = Uint8List(12);
  final Uint8List _floodSeen = Uint8List(128);
  final List<int> _floodStack = <int>[];
  final List<int> _childLo = <int>[];
  final List<int> _childHi = <int>[];

  static List<List<int>> _buildClassGroups() {
    final byClass = <String, List<int>>{};
    for (var b = 0; b < swapBlocksBlockCount; b++) {
      final key = '${swapBlocksShapes[b]}_${swapBlocksColours[b]}';
      byClass.putIfAbsent(key, () => <int>[]).add(b);
    }
    return [
      for (final group in byClass.values)
        if (group.length > 1) group,
    ];
  }

  /// Packs a 12-entry origin-code array into its two-int key, the first nine
  /// codes (7 bits each) into the low int, the last three into the high
  /// int. Does NOT canonicalize; callers pass an already-canonical array.
  (int, int) _pack(Uint8List origins) {
    var lo = 0;
    for (var i = 0; i < 9; i++) {
      lo |= origins[i] << (7 * i);
    }
    var hi = 0;
    for (var i = 0; i < 3; i++) {
      hi |= origins[9 + i] << (7 * i);
    }
    return (lo, hi);
  }

  /// Unpacks a key into [out] (must be length 12), inverse of [_pack].
  void _unpack(int lo, int hi, Uint8List out) {
    for (var i = 0; i < 9; i++) {
      out[i] = (lo >> (7 * i)) & 0x7F;
    }
    for (var i = 0; i < 3; i++) {
      out[9 + i] = (hi >> (7 * i)) & 0x7F;
    }
  }

  /// Sorts [origins] within each of [classGroups] in place, so two positions
  /// that differ only by which same-class block sits where produce the same
  /// array (and thus the same packed key).
  void _canonicalize(Uint8List origins) {
    for (final group in classGroups) {
      for (var i = 0; i < group.length; i++) {
        _sortBuf[i] = origins[group[i]];
      }
      // Small groups (size 2 here) - insertion sort is plenty.
      for (var i = 1; i < group.length; i++) {
        final v = _sortBuf[i];
        var j = i - 1;
        while (j >= 0 && _sortBuf[j] > v) {
          _sortBuf[j + 1] = _sortBuf[j];
          j--;
        }
        _sortBuf[j + 1] = v;
      }
      for (var i = 0; i < group.length; i++) {
        origins[group[i]] = _sortBuf[i];
      }
    }
  }

  (int, int) _canonicalKeyOf(Uint8List origins) {
    _canonicalize(origins);
    return _pack(origins);
  }

  /// Fills [_childLo]/[_childHi] with the canonical keys of every position
  /// one move from the position stored at [lo]/[hi]. For each block: strip
  /// its own occupancy from the total, then flood-fill over adjacent valid
  /// origins whose mask does not intersect what remains - a move may turn
  /// corners and cover any distance, but is one move regardless. Every
  /// reached origin other than the block's current one is a child.
  void _expand(int lo, int hi) {
    _childLo.clear();
    _childHi.clear();
    _unpack(lo, hi, _origins);

    var totalLo = 0;
    var totalHi = 0;
    for (var b = 0; b < 12; b++) {
      final table = shapeTables[swapBlocksShapes[b].index];
      totalLo |= table.maskLo[_origins[b]];
      totalHi |= table.maskHi[_origins[b]];
    }

    for (var b = 0; b < 12; b++) {
      final table = shapeTables[swapBlocksShapes[b].index];
      final origin = _origins[b];
      final baseLo = totalLo & ~table.maskLo[origin];
      final baseHi = totalHi & ~table.maskHi[origin];

      _floodSeen.fillRange(0, 128, 0);
      _floodSeen[origin] = 1;
      _floodStack.clear();
      _floodStack.add(origin);

      while (_floodStack.isNotEmpty) {
        final current = _floodStack.removeLast();
        for (final next in table.adjacent[current]) {
          if (_floodSeen[next] == 1) continue;
          if ((table.maskLo[next] & baseLo) != 0 ||
              (table.maskHi[next] & baseHi) != 0) {
            continue;
          }
          _floodSeen[next] = 1;
          _floodStack.add(next);

          _childOrigins.setRange(0, 12, _origins);
          _childOrigins[b] = next;
          final (childLoKey, childHiKey) = _canonicalKeyOf(_childOrigins);
          _childLo.add(childLoKey);
          _childHi.add(childHiKey);
        }
      }
    }
  }

  IdenticalTokenSearchResult run() {
    final startOrigins =
        Uint8List.fromList(swapBlocksStartOrigins);
    final goalOrigins =
        Uint8List.fromList(SwapBlocksGame.goalState().origins);
    final (startLo, startHi) = _canonicalKeyOf(startOrigins);
    final (goalLo, goalHi) = _canonicalKeyOf(goalOrigins);

    if (startLo == goalLo && startHi == goalHi) {
      return const IdenticalTokenSearchResult(
        optimalMoves: 0,
        moves: [],
        statesExplored: 1,
      );
    }

    final startSlot = visited.findSlot(startLo, startHi);
    visited.markSlot(startSlot, startLo, startHi, _forward);
    final goalSlot = visited.findSlot(goalLo, goalHi);
    visited.markSlot(goalSlot, goalLo, goalHi, _backward);

    var forwardFrontier = <int>[startSlot];
    var backwardFrontier = <int>[goalSlot];
    var forwardDepth = 0;
    var backwardDepth = 0;

    while (forwardFrontier.isNotEmpty && backwardFrontier.isNotEmpty) {
      final goingForward = forwardFrontier.length <= backwardFrontier.length;
      final frontier = goingForward ? forwardFrontier : backwardFrontier;
      final depth = (goingForward ? forwardDepth : backwardDepth) + 1;
      final mark = (goingForward ? _forward : _backward) + depth;
      final otherBase = goingForward ? _backward : _forward;

      final next = <int>[];
      int? best;
      var meetForwardSlot = 0;
      var meetForwardDepth = 0;
      var meetBackwardSlot = 0;
      var meetBackwardDepth = 0;

      for (final slot in frontier) {
        _expand(visited.keyLo[slot], visited.keyHi[slot]);
        for (var i = 0; i < _childLo.length; i++) {
          final childLo = _childLo[i];
          final childHi = _childHi[i];
          final childSlot = visited.findSlot(childLo, childHi);
          final seen = visited.mark[childSlot];
          if (seen == 0) {
            visited.markSlot(childSlot, childLo, childHi, mark);
            next.add(childSlot);
            continue;
          }
          final fromOtherSide =
              goingForward ? seen >= _backward : seen < _backward;
          if (!fromOtherSide) continue;

          final otherDepth = seen - otherBase;
          final candidate = depth + otherDepth;
          if (best != null && candidate >= best) continue;
          best = candidate;
          if (goingForward) {
            meetForwardSlot = slot;
            meetForwardDepth = depth - 1;
            meetBackwardSlot = childSlot;
            meetBackwardDepth = otherDepth;
          } else {
            meetForwardSlot = childSlot;
            meetForwardDepth = otherDepth;
            meetBackwardSlot = slot;
            meetBackwardDepth = depth - 1;
          }
        }
      }

      if (goingForward) {
        forwardDepth = depth;
        forwardFrontier = next;
      } else {
        backwardDepth = depth;
        backwardFrontier = next;
      }

      stderr.writeln(
        '${goingForward ? 'forward ' : 'backward'} depth=$depth '
        'frontier=${next.length} marked=${visited.count}',
      );

      if (best != null) {
        final slots = <int>[
          ..._walkToStart(meetForwardSlot, meetForwardDepth),
          ..._walkToGoal(meetBackwardSlot, meetBackwardDepth),
        ];
        final moves = _movesAlong(slots);
        if (moves.length != best) {
          throw StateError(
            'swap_blocks_search: reconstructed ${moves.length} moves for a '
            'par of $best',
          );
        }
        return IdenticalTokenSearchResult(
          optimalMoves: best,
          moves: moves,
          statesExplored: visited.count,
        );
      }
    }

    return IdenticalTokenSearchResult(
      optimalMoves: null,
      moves: const [],
      statesExplored: visited.count,
    );
  }

  /// The slots from the start up to and including [slot] (marked by the
  /// forward search at [depth]). Walks backwards by looking, at each step,
  /// for a neighbour the forward search marked exactly one level shallower.
  List<int> _walkToStart(int slot, int depth) {
    final chain = <int>[slot];
    var current = slot;
    for (var d = depth; d > 0; d--) {
      final wanted = _forward + (d - 1);
      var found = false;
      _expand(visited.keyLo[current], visited.keyHi[current]);
      for (var i = 0; i < _childLo.length; i++) {
        final candidateSlot = visited.findSlot(_childLo[i], _childHi[i]);
        if (visited.mark[candidateSlot] != wanted) continue;
        chain.insert(0, candidateSlot);
        current = candidateSlot;
        found = true;
        break;
      }
      if (!found) {
        throw StateError(
          'swap_blocks_search: no forward predecessor at depth ${d - 1}',
        );
      }
    }
    return chain;
  }

  /// The slots from [slot] (marked by the backward search at [depth]) down
  /// to the goal.
  List<int> _walkToGoal(int slot, int depth) {
    final chain = <int>[slot];
    var current = slot;
    for (var d = depth; d > 0; d--) {
      final wanted = _backward + (d - 1);
      var found = false;
      _expand(visited.keyLo[current], visited.keyHi[current]);
      for (var i = 0; i < _childLo.length; i++) {
        final candidateSlot = visited.findSlot(_childLo[i], _childHi[i]);
        if (visited.mark[candidateSlot] != wanted) continue;
        chain.add(candidateSlot);
        current = candidateSlot;
        found = true;
        break;
      }
      if (!found) {
        throw StateError(
          'swap_blocks_search: no backward predecessor at depth ${d - 1}',
        );
      }
    }
    return chain;
  }

  /// Turns a chain of slots into the moves joining them, by asking the
  /// shipped [SwapBlocksGame.legalMoves]/`applyMove` which move produces
  /// each next position - the cross-check against the app's own rules that
  /// this whole search exists to satisfy. The comparison is done in
  /// canonical-key space (not raw origin-array equality), because the
  /// canonical form stored at a slot may have relabelled which same-class
  /// block index a move actually touched.
  List<PlaygroundMove> _movesAlong(List<int> slots) {
    const game = SwapBlocksGame();
    final moves = <PlaygroundMove>[];
    for (var i = 0; i + 1 < slots.length; i++) {
      final fromOrigins = Uint8List(12);
      _unpack(visited.keyLo[slots[i]], visited.keyHi[slots[i]], fromOrigins);
      final targetLo = visited.keyLo[slots[i + 1]];
      final targetHi = visited.keyHi[slots[i + 1]];

      final state = SwapBlocksState(List<int>.from(fromOrigins));
      PlaygroundMove? found;
      for (final move in game.legalMoves(state)) {
        final resultState =
            game.applyMove(state, move) as SwapBlocksState;
        final candidate = Uint8List.fromList(resultState.origins);
        final (candidateLo, candidateHi) = _canonicalKeyOf(candidate);
        if (candidateLo == targetLo && candidateHi == targetHi) {
          found = move;
          break;
        }
      }
      if (found == null) {
        throw StateError(
          'swap_blocks_search: no legal move joins two positions of the '
          'reconstructed solution',
        );
      }
      moves.add(found);
    }
    return moves;
  }
}

Future<void> main(List<String> args) async {
  final stopwatch = Stopwatch()..start();
  final result = searchSwapBlocks();
  stopwatch.stop();

  print('');
  print('par: ${result.optimalMoves}');
  print('states explored: ${result.statesExplored}');
  print('elapsed: ${stopwatch.elapsed}');
  print('moves:');
  for (final move in result.moves) {
    print('  ${move.from} -> ${move.to}');
  }
}
