import '../../data.dart';
import '../../playground_game.dart';

/// Board dimensions: 16 rows, 8 columns, 128 cells.
const int swapBlocksRows = 16;

/// See [swapBlocksRows].
const int swapBlocksCols = 8;

/// How many blocks are on the board.
const int swapBlocksBlockCount = 12;

/// The cell id for board position ([row], [col]), both 0-based: `r1c1` is
/// the top-left cell, `r16c8` the bottom-right one (1-based in the id, as
/// printed in the book).
String swapBlocksCellId(int row, int col) => 'r${row + 1}c${col + 1}';

/// Parses a cell id produced by [swapBlocksCellId] back to its 0-based
/// (row, col), or `null` if [id] is not a well-formed, in-bounds cell id.
(int, int)? swapBlocksParseCellId(String id) {
  final match = RegExp(r'^r(\d+)c(\d+)$').firstMatch(id);
  if (match == null) return null;
  final row = int.parse(match.group(1)!) - 1;
  final col = int.parse(match.group(2)!) - 1;
  if (row < 0 || row >= swapBlocksRows || col < 0 || col >= swapBlocksCols) {
    return null;
  }
  return (row, col);
}

/// The four distinct P-block footprints in the layout: rotations/reflections
/// of one physical piece, frozen at the start (a block never rotates or
/// flips during play). Each is 8 cells in a 3-row x 4-column bounding box,
/// given as (dRow, dCol) offsets from the box's top-left corner.
enum SwapBlocksShape { a, b, c, d }

/// Each shape's 8 occupied cells, as offsets from its bounding-box origin.
/// Transcribed from Мочалов, 1980, p. 58.
const Map<SwapBlocksShape, List<(int, int)>> swapBlocksShapeOffsets = {
  SwapBlocksShape.a: [
    (0, 0), (0, 1), (0, 2), (0, 3),
    (1, 0), (1, 1),
    (2, 0), (2, 1),
  ],
  SwapBlocksShape.b: [
    (0, 0), (0, 1), (0, 2), (0, 3),
    (1, 2), (1, 3),
    (2, 2), (2, 3),
  ],
  SwapBlocksShape.c: [
    (0, 0), (0, 1),
    (1, 0), (1, 1),
    (2, 0), (2, 1), (2, 2), (2, 3),
  ],
  SwapBlocksShape.d: [
    (0, 2), (0, 3),
    (1, 2), (1, 3),
    (2, 0), (2, 1), (2, 2), (2, 3),
  ],
};

/// Each shape's anchor offset: the (dRow, dCol) of its first occupied cell
/// in row-major order (top-most, then left-most), relative to its
/// bounding-box origin. For shapes A/B/C that is the origin itself; shape D
/// has no cell at its own origin, so its anchor is origin + (0, 2). The
/// anchor - never the raw bounding-box origin - is what every public id
/// uses, so it always names a cell the block really occupies and the UI can
/// highlight it directly.
const Map<SwapBlocksShape, (int, int)> swapBlocksAnchorOffset = {
  SwapBlocksShape.a: (0, 0),
  SwapBlocksShape.b: (0, 0),
  SwapBlocksShape.c: (0, 0),
  SwapBlocksShape.d: (0, 2),
};

/// A block's colour, used only to define the interchangeability classes for
/// [SwapBlocksGame.isSolved] - it has no effect on movement.
enum SwapBlocksColour { plain, red, black }

/// The twelve blocks' fixed shapes, in block order (index 0-11), matching
/// Мочалов, 1980, p. 58. Never changes during play.
const List<SwapBlocksShape> swapBlocksShapes = [
  SwapBlocksShape.a,
  SwapBlocksShape.b,
  SwapBlocksShape.b,
  SwapBlocksShape.c,
  SwapBlocksShape.c,
  SwapBlocksShape.d,
  SwapBlocksShape.a,
  SwapBlocksShape.b,
  SwapBlocksShape.b,
  SwapBlocksShape.c,
  SwapBlocksShape.c,
  SwapBlocksShape.d,
];

/// The twelve blocks' fixed colours, in block order. Never changes during
/// play. Two blocks are interchangeable (same class, for [SwapBlocksGame
/// .isSolved]) iff they share both [swapBlocksShapes] and this colour -
/// eight such classes occur in this layout.
const List<SwapBlocksColour> swapBlocksColours = [
  SwapBlocksColour.plain,
  SwapBlocksColour.plain,
  SwapBlocksColour.red,
  SwapBlocksColour.red,
  SwapBlocksColour.plain,
  SwapBlocksColour.plain,
  SwapBlocksColour.plain,
  SwapBlocksColour.plain,
  SwapBlocksColour.black,
  SwapBlocksColour.black,
  SwapBlocksColour.plain,
  SwapBlocksColour.plain,
];

/// The twelve blocks' starting bounding-box origins, in block order, each
/// encoded as `row * swapBlocksCols + col` (0-based). Decodes to: (0,0),
/// (0,4), (1,2), (2,2), (3,0), (3,4), (10,0), (10,4), (11,2), (12,2),
/// (13,0), (13,4).
const List<int> swapBlocksStartOrigins = [
  0, 4, 10, 18, 24, 28,
  80, 84, 90, 98, 104, 108,
];

/// The class token used by [SwapBlocksGame.isSolved]'s painting: two blocks
/// with the same token are interchangeable.
String _classToken(int block) =>
    '${swapBlocksShapes[block].name}_${swapBlocksColours[block].name}';

/// Paints a 128-entry board (row-major, `row * swapBlocksCols + col`) with
/// each occupied cell's class token ([_classToken]), `null` where free.
List<String?> _paint(List<int> origins) {
  final board =
      List<String?>.filled(swapBlocksRows * swapBlocksCols, null);
  for (var b = 0; b < origins.length; b++) {
    final r0 = origins[b] ~/ swapBlocksCols;
    final c0 = origins[b] % swapBlocksCols;
    final token = _classToken(b);
    for (final (dr, dc) in swapBlocksShapeOffsets[swapBlocksShapes[b]]!) {
      board[(r0 + dr) * swapBlocksCols + (c0 + dc)] = token;
    }
  }
  return board;
}

/// The goal layout: the start layout with the red pair (block 2) and the
/// black pair (block 8), and separately block 3 and block 9, exchanged.
List<int> _goalOrigins() {
  final g = List<int>.from(swapBlocksStartOrigins);
  final t2 = g[2];
  g[2] = g[8];
  g[8] = t2;
  final t3 = g[3];
  g[3] = g[9];
  g[9] = t3;
  return g;
}

/// The play state of «Поменяйте местами»: the twelve blocks' bounding-box
/// origins, in block order, each `row * swapBlocksCols + col`. A block's
/// shape and colour never change - only its position - so those live in
/// the top-level [swapBlocksShapes]/[swapBlocksColours] lists, not here.
/// Immutable and content-comparable.
class SwapBlocksState extends PlaygroundState {
  /// The twelve blocks' bounding-box origins, in block order.
  final List<int> origins;

  /// Creates a state from a per-block [origins] list.
  SwapBlocksState(List<int> origins) : origins = List<int>.unmodifiable(origins);

  /// Block [block]'s bounding-box origin row.
  int originRow(int block) => origins[block] ~/ swapBlocksCols;

  /// Block [block]'s bounding-box origin column.
  int originCol(int block) => origins[block] % swapBlocksCols;

  /// The cell indices (`row * swapBlocksCols + col`) block [block] occupies
  /// at its current origin.
  List<int> occupiedCells(int block) {
    final r0 = originRow(block);
    final c0 = originCol(block);
    return [
      for (final (dr, dc) in swapBlocksShapeOffsets[swapBlocksShapes[block]]!)
        (r0 + dr) * swapBlocksCols + (c0 + dc),
    ];
  }

  /// The block index occupying cell [cell] (`row * swapBlocksCols + col`),
  /// or `null` if that cell is free.
  int? blockAtCell(int cell) {
    for (var b = 0; b < origins.length; b++) {
      if (occupiedCells(b).contains(cell)) return b;
    }
    return null;
  }

  /// Block [block]'s anchor: the id of its first occupied cell in row-major
  /// order (see [swapBlocksAnchorOffset]). Used in every public move id.
  String anchorId(int block) {
    final (dr, dc) = swapBlocksAnchorOffset[swapBlocksShapes[block]]!;
    return swapBlocksCellId(originRow(block) + dr, originCol(block) + dc);
  }

  /// The block index whose current anchor is [id], or `null`.
  int? blockAtAnchor(String id) {
    for (var b = 0; b < origins.length; b++) {
      if (anchorId(b) == id) return b;
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (other is! SwapBlocksState) return false;
    if (other.origins.length != origins.length) return false;
    for (var i = 0; i < origins.length; i++) {
      if (other.origins[i] != origins[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(origins);

  @override
  String toString() => 'SwapBlocksState(${origins.join(', ')})';
}

/// «Поменяйте местами» (Мочалов, 1980, p. 58): twelve identical P-shaped
/// blocks fill all but 32 cells of a 16x8 box. A move slides one block
/// through the free space, orthogonally, any distance, turning corners
/// freely - the whole journey is one move regardless of length. The goal is
/// to exchange the red pair and the black pair (which sit in the box's two
/// halves) while every other block returns to its start.
///
/// Move economy applies: [par]/[parProven]/[parSource]/[optimalSolution]
/// all come from the parsed puzzle data, exactly like every other
/// move-counted playground game.
class SwapBlocksGame extends PlaygroundGame {
  final PlaygroundGameData? _data;

  /// Creates the game, optionally backed by parsed puzzle data supplying
  /// [par]/[parProven]/[parSource]/[optimalSolution].
  const SwapBlocksGame([this._data]);

  @override
  String get id => 'swap_blocks';

  @override
  PlaygroundFamily get family => PlaygroundFamily.slidingBlocks;

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
  PlaygroundState initialState() =>
      SwapBlocksState(List<int>.from(swapBlocksStartOrigins));

  /// The goal layout: the start layout with the red pair and the black pair
  /// exchanged (see [_goalOrigins]). Exposed the way [HourglassGame
  /// .goalState] is, so a search can target it directly instead of
  /// reimplementing the exchange.
  static SwapBlocksState goalState() => SwapBlocksState(_goalOrigins());

  /// Every legal move available from [state]. For each block, in block
  /// order, this floods the grid of bounding-box origins reachable from its
  /// current origin by single-cell up/down/left/right steps that stay in
  /// the box and never overlap another block's current footprint - that is
  /// exactly "translate through free space, corners allowed, one move
  /// however long". Destinations are emitted in row-major order of the
  /// destination anchor.
  @override
  List<PlaygroundMove> legalMoves(PlaygroundState state, {String? from}) {
    final s = state as SwapBlocksState;
    final moves = <PlaygroundMove>[];

    for (var b = 0; b < s.origins.length; b++) {
      final fromId = s.anchorId(b);
      if (from != null && from != fromId) continue;

      final otherCells = <int>{};
      for (var ob = 0; ob < s.origins.length; ob++) {
        if (ob == b) continue;
        otherCells.addAll(s.occupiedCells(ob));
      }
      final offsets = swapBlocksShapeOffsets[swapBlocksShapes[b]]!;
      final anchorOffset = swapBlocksAnchorOffset[swapBlocksShapes[b]]!;

      bool validOrigin(int r, int c) {
        if (r < 0 ||
            c < 0 ||
            r + 2 >= swapBlocksRows ||
            c + 3 >= swapBlocksCols) {
          return false;
        }
        for (final (dr, dc) in offsets) {
          if (otherCells.contains((r + dr) * swapBlocksCols + (c + dc))) {
            return false;
          }
        }
        return true;
      }

      final startR = s.originRow(b);
      final startC = s.originCol(b);
      final visited = <(int, int)>{(startR, startC)};
      final queue = <(int, int)>[(startR, startC)];
      final reachable = <(int, int)>[];

      while (queue.isNotEmpty) {
        final (r, c) = queue.removeAt(0);
        for (final (ddr, ddc) in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
          final next = (r + ddr, c + ddc);
          if (visited.contains(next)) continue;
          if (!validOrigin(next.$1, next.$2)) continue;
          visited.add(next);
          reachable.add(next);
          queue.add(next);
        }
      }

      reachable.sort((x, y) {
        final ax = x.$1 * swapBlocksCols + x.$2;
        final ay = y.$1 * swapBlocksCols + y.$2;
        return ax.compareTo(ay);
      });

      for (final (r, c) in reachable) {
        final anchor =
            swapBlocksCellId(r + anchorOffset.$1, c + anchorOffset.$2);
        moves.add(PlaygroundMove([fromId, anchor]));
      }
    }

    return moves;
  }

  @override
  PlaygroundState applyMove(PlaygroundState state, PlaygroundMove move) {
    final s = state as SwapBlocksState;
    if (!legalMoves(s, from: move.from).contains(move)) {
      throw ArgumentError('swap_blocks: illegal move $move');
    }

    final block = s.blockAtAnchor(move.from)!;
    final dest = swapBlocksParseCellId(move.to)!;
    final anchorOffset = swapBlocksAnchorOffset[swapBlocksShapes[block]]!;
    final destOriginRow = dest.$1 - anchorOffset.$1;
    final destOriginCol = dest.$2 - anchorOffset.$2;

    final origins = List<int>.from(s.origins);
    origins[block] = destOriginRow * swapBlocksCols + destOriginCol;
    return SwapBlocksState(origins);
  }

  /// Whether [state] matches the goal layout up to interchangeability
  /// within a (shape, colour) class - never equality against one stored
  /// winning state. Two blocks of the same class are indistinguishable
  /// pieces, so any permutation of a class among its own cells still
  /// counts as solved. Implemented by painting the 128 cells of both
  /// [state] and the goal layout with each occupied cell's class token and
  /// comparing the two paintings cell by cell.
  @override
  bool isSolved(PlaygroundState state) {
    final s = state as SwapBlocksState;
    final candidate = _paint(s.origins);
    final goal = _paint(SwapBlocksGame.goalState().origins);
    for (var i = 0; i < candidate.length; i++) {
      if (candidate[i] != goal[i]) return false;
    }
    return true;
  }

  @override
  Map<String, dynamic> stateToJson(PlaygroundState state) {
    final s = state as SwapBlocksState;
    return {'origins': List<int>.from(s.origins)};
  }

  /// Parses a state saved by [stateToJson].
  ///
  /// Returns null (never throws) for: [json] not a map; an `origins` value
  /// that is not a list of exactly [swapBlocksBlockCount] ints; an origin
  /// out of the encodable range; an origin whose fixed footprint would
  /// leave the 16x8 box; or two blocks whose footprints overlap.
  @override
  PlaygroundState? stateFromJson(Object? json) {
    try {
      if (json is! Map) return null;
      final raw = json['origins'];
      if (raw is! List) return null;
      if (raw.length != swapBlocksBlockCount) return null;

      final origins = <int>[];
      for (final entry in raw) {
        if (entry is! int) return null;
        origins.add(entry);
      }

      final occupied = <int>{};
      for (var b = 0; b < origins.length; b++) {
        final o = origins[b];
        if (o < 0 || o >= swapBlocksRows * swapBlocksCols) return null;
        final r0 = o ~/ swapBlocksCols;
        final c0 = o % swapBlocksCols;
        if (r0 < 0 ||
            c0 < 0 ||
            r0 + 2 >= swapBlocksRows ||
            c0 + 3 >= swapBlocksCols) {
          return null;
        }
        for (final (dr, dc)
            in swapBlocksShapeOffsets[swapBlocksShapes[b]]!) {
          final cell = (r0 + dr) * swapBlocksCols + (c0 + dc);
          if (!occupied.add(cell)) return null;
        }
      }

      return SwapBlocksState(origins);
    } catch (_) {
      return null;
    }
  }
}
