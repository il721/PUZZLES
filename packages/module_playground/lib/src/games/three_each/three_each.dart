import '../../data.dart';
import '../../playground_game.dart';

/// A red circle.
const String threeEachRed = 'R';

/// A white circle (drawn as a black ring in the book).
const String threeEachWhite = 'W';

/// A black circle.
const String threeEachBlack = 'B';

/// A tile cell with no circle on it.
const String threeEachEmpty = '.';

/// Every colour the win condition counts, in a fixed order.
const List<String> threeEachColors = [
  threeEachRed,
  threeEachWhite,
  threeEachBlack,
];

/// The nine cardboard tiles, in the reading order of the book's figure
/// (Мочалов, 1980, p. 59): three per row, left to right, top to bottom.
/// Each tile is three rows of three cells, unrotated, using [threeEachRed] /
/// [threeEachWhite] / [threeEachBlack] / [threeEachEmpty].
///
/// Transcribed from the 600-dpi scan by blob detection (red mask for red
/// discs, dark mask split by fill ratio into filled discs and rings), the
/// result rendered back to PICT/06-three-each-encoding.png and confirmed by
/// the user. The transcription is additionally cross-checked against the
/// book's printed answer on p. 114: the nine tiles of that answer square are
/// a bijection onto these nine tiles under rotation alone.
///
/// The 27 circles are nine of each colour - exactly three per line of the
/// finished 9x9 square.
const List<List<String>> threeEachTiles = [
  ['..R', 'RB.', '..W'],
  ['W..', '...', '.B.'],
  ['...', 'R.W', '.B.'],
  ['B..', '.WR', '.R.'],
  ['.B.', 'W..', 'B.R'],
  ['W..', '...', '...'],
  ['R.B', 'B..', '.W.'],
  ['W..', '..R', '...'],
  ['B..', 'W.R', '...'],
];

/// The nine tile ids, T1..T9, indexed as [threeEachTiles].
const List<String> threeEachTileIds = [
  'T1',
  'T2',
  'T3',
  'T4',
  'T5',
  'T6',
  'T7',
  'T8',
  'T9',
];

/// The nine board slot ids, S1..S9, in row-major order of the 3x3
/// arrangement of tiles: S1 is the top-left tile position, S9 the
/// bottom-right one.
const List<String> threeEachSlotIds = [
  'S1',
  'S2',
  'S3',
  'S4',
  'S5',
  'S6',
  'S7',
  'S8',
  'S9',
];

/// The cell at row [r], column [c] of tile [tile] after [rotation] quarter
/// turns clockwise. One clockwise turn sends the unrotated cell (r, c) to
/// (c, 2 - r), so reading position (r, c) of the turned tile means reading
/// (2 - c, r) of the one before it.
String threeEachCell(int tile, int rotation, int r, int c) {
  var row = r;
  var col = c;
  for (var i = 0; i < (rotation % 4); i++) {
    final nextRow = 2 - col;
    final nextCol = row;
    row = nextRow;
    col = nextCol;
  }
  return threeEachTiles[tile][row][col];
}

/// One tile laid on the board: which tile ([tile], an index into
/// [threeEachTiles]) and how far it has been turned clockwise ([rotation],
/// 0-3 quarter turns). Tiles are one-sided cardboard, so they rotate but
/// never flip.
class ThreeEachPlacement {
  /// Index into [threeEachTiles].
  final int tile;

  /// Quarter turns clockwise, 0-3.
  final int rotation;

  /// Creates a placement of [tile] turned [rotation] quarter turns.
  const ThreeEachPlacement(this.tile, this.rotation);

  /// The cell at row [r], column [c] of this tile as it lies on the board,
  /// i.e. after [rotation] quarter turns clockwise.
  String cellAt(int r, int c) => threeEachCell(tile, rotation, r, c);

  /// This placement's tile-id-plus-rotation short form, e.g. T4r2, as used
  /// in move paths and in the save file.
  String get token => '${threeEachTileIds[tile]}r$rotation';

  @override
  bool operator ==(Object other) =>
      other is ThreeEachPlacement &&
      other.tile == tile &&
      other.rotation == rotation;

  @override
  int get hashCode => Object.hash(tile, rotation);

  @override
  String toString() => 'ThreeEachPlacement($token)';
}

/// The play state of «Всюду по три»: which tile (if any) lies in each of the
/// nine board slots, and at which rotation. [slots] is indexed by slot index
/// (matching [threeEachSlotIds]); a null entry means that slot is empty, and
/// the tiles not present in [slots] are the ones still in the tray.
/// Immutable and content-comparable.
class ThreeEachState extends PlaygroundState {
  /// What lies in each slot, indexed by slot index; null means empty.
  final List<ThreeEachPlacement?> slots;

  /// Creates a state directly from a per-slot [slots] list.
  const ThreeEachState(this.slots);

  /// The empty board: all nine tiles in the tray.
  factory ThreeEachState.empty() =>
      ThreeEachState(List<ThreeEachPlacement?>.filled(9, null));

  /// The slot index holding tile [tile], or null if it is still in the tray.
  int? slotOfTile(int tile) {
    for (var i = 0; i < slots.length; i++) {
      if (slots[i]?.tile == tile) return i;
    }
    return null;
  }

  /// The tile indexes still in the tray, in tile order.
  List<int> get trayTiles => [
        for (var t = 0; t < threeEachTiles.length; t++)
          if (slotOfTile(t) == null) t,
      ];

  /// The assembled 9x9 square as it currently stands: nine rows of nine
  /// cells, each [threeEachRed] / [threeEachWhite] / [threeEachBlack] /
  /// [threeEachEmpty]. Cells belonging to an empty slot read as
  /// [threeEachEmpty], so a partial board is still a well-formed grid.
  List<List<String>> grid() {
    final out = [
      for (var r = 0; r < 9; r++) List<String>.filled(9, threeEachEmpty),
    ];
    for (var s = 0; s < slots.length; s++) {
      final placement = slots[s];
      if (placement == null) continue;
      final rowBase = (s ~/ 3) * 3;
      final colBase = (s % 3) * 3;
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          out[rowBase + r][colBase + c] = placement.cellAt(r, c);
        }
      }
    }
    return out;
  }

  @override
  bool operator ==(Object other) {
    if (other is! ThreeEachState) return false;
    if (other.slots.length != slots.length) return false;
    for (var i = 0; i < slots.length; i++) {
      if (other.slots[i] != slots[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(slots);

  @override
  String toString() =>
      'ThreeEachState(${slots.map((p) => p?.token ?? '-').join(', ')})';
}

/// The twenty lines the win condition tests: nine rows, nine columns and
/// both main diagonals of the 9x9 square, each as a list of (row, column)
/// cell coordinates.
List<List<(int, int)>> threeEachLines() => [
      for (var r = 0; r < 9; r++) [for (var c = 0; c < 9; c++) (r, c)],
      for (var c = 0; c < 9; c++) [for (var r = 0; r < 9; r++) (r, c)],
      [for (var i = 0; i < 9; i++) (i, i)],
      [for (var i = 0; i < 9; i++) (i, 8 - i)],
    ];

/// «Всюду по три» (Мочалов, 1980, p. 59): nine 3x3 cardboard tiles carrying
/// red, white and black circles are assembled into a 9x9 square so that each
/// of its nine rows, nine columns and both main diagonals carries exactly
/// one circle of each colour.
///
/// A move either lays a tray tile into an empty slot at a chosen rotation
/// (T4 -> S6r2), turns a tile already on the board (S6 -> S6r3), or takes a
/// tile back to the tray (S6 -> T4). Tiles rotate in quarter turns but never
/// flip - the physical model is one-sided cardboard.
///
/// There is no move economy here: the puzzle asks only for a valid square,
/// never for the fewest placements, so [par] is null and no star is ever
/// awarded. [optimalSolution] is nonetheless recorded - it is the nine
/// placements of one valid square, used by the post-solve replay.
class ThreeEachGame extends PlaygroundGame {
  final PlaygroundGameData? _data;

  /// Creates the game, optionally backed by parsed puzzle data supplying
  /// [optimalSolution].
  const ThreeEachGame([this._data]);

  @override
  String get id => 'three_each';

  @override
  PlaygroundFamily get family => PlaygroundFamily.tilePlacement;

  @override
  bool get enabled => true;

  @override
  int? get par => null;

  @override
  bool get parProven => false;

  @override
  ParSource? get parSource => null;

  @override
  List<PlaygroundMove>? get optimalSolution => _data?.solution;

  @override
  PlaygroundState initialState() => ThreeEachState.empty();

  @override
  List<PlaygroundMove> legalMoves(PlaygroundState state, {String? from}) {
    final s = state as ThreeEachState;
    final moves = <PlaygroundMove>[];

    for (var t = 0; t < threeEachTiles.length; t++) {
      final tileId = threeEachTileIds[t];
      if (s.slotOfTile(t) != null) continue;
      if (from != null && from != tileId) continue;
      for (var slot = 0; slot < s.slots.length; slot++) {
        if (s.slots[slot] != null) continue;
        for (var rotation = 0; rotation < 4; rotation++) {
          moves.add(
            PlaygroundMove([tileId, '${threeEachSlotIds[slot]}r$rotation']),
          );
        }
      }
    }

    for (var slot = 0; slot < s.slots.length; slot++) {
      final placement = s.slots[slot];
      if (placement == null) continue;
      final slotId = threeEachSlotIds[slot];
      if (from != null && from != slotId) continue;
      for (var rotation = 0; rotation < 4; rotation++) {
        if (rotation == placement.rotation) continue;
        moves.add(PlaygroundMove([slotId, '${slotId}r$rotation']));
      }
      moves.add(PlaygroundMove([slotId, threeEachTileIds[placement.tile]]));
    }

    return moves;
  }

  @override
  PlaygroundState applyMove(PlaygroundState state, PlaygroundMove move) {
    final s = state as ThreeEachState;
    if (!legalMoves(s, from: move.from).contains(move)) {
      throw ArgumentError('three_each: illegal move $move');
    }

    final slots = List<ThreeEachPlacement?>.from(s.slots);
    final fromSlot = threeEachSlotIds.indexOf(move.from);

    if (fromSlot >= 0) {
      final placement = slots[fromSlot]!;
      if (threeEachTileIds.contains(move.to)) {
        slots[fromSlot] = null;
      } else {
        slots[fromSlot] = ThreeEachPlacement(
          placement.tile,
          int.parse(move.to.substring(move.to.length - 1)),
        );
      }
      return ThreeEachState(slots);
    }

    final tile = threeEachTileIds.indexOf(move.from);
    final slot = threeEachSlotIds.indexOf(move.to.substring(0, 2));
    slots[slot] = ThreeEachPlacement(
      tile,
      int.parse(move.to.substring(move.to.length - 1)),
    );
    return ThreeEachState(slots);
  }

  /// Whether all nine tiles are laid and every one of the twenty lines
  /// ([threeEachLines]) carries exactly one red, one white and one black
  /// circle.
  ///
  /// This is a predicate on the assembled square, never equality against one
  /// stored winning arrangement: the puzzle has many valid squares (every
  /// solution turned as a whole is another one). Cells with no circle are
  /// ignored - the square holds 27 circles in 81 cells, so "exactly one of
  /// each colour" is a statement about the circles present on a line, not a
  /// claim that all nine of its cells are filled.
  @override
  bool isSolved(PlaygroundState state) {
    final s = state as ThreeEachState;
    if (s.slots.any((p) => p == null)) return false;

    final grid = s.grid();
    for (final line in threeEachLines()) {
      final counts = {for (final color in threeEachColors) color: 0};
      for (final (r, c) in line) {
        final cell = grid[r][c];
        if (cell == threeEachEmpty) continue;
        counts[cell] = counts[cell]! + 1;
      }
      if (counts.values.any((n) => n != 1)) return false;
    }
    return true;
  }

  @override
  Map<String, dynamic> stateToJson(PlaygroundState state) {
    final s = state as ThreeEachState;
    return {
      'slots': [for (final p in s.slots) p?.token],
    };
  }

  /// Parses a state saved by [stateToJson].
  ///
  /// Returns null (never throws) for: [json] not a map; a slots value that
  /// is not a list of exactly nine entries; an entry that is neither null
  /// nor a tile-id-plus-rotation token with a known tile id and a rotation
  /// in 0-3; or the same tile appearing in two slots.
  @override
  PlaygroundState? stateFromJson(Object? json) {
    try {
      if (json is! Map) return null;
      final raw = json['slots'];
      if (raw is! List) return null;
      if (raw.length != threeEachSlotIds.length) return null;

      final slots = List<ThreeEachPlacement?>.filled(raw.length, null);
      final seen = <int>{};

      for (var i = 0; i < raw.length; i++) {
        final token = raw[i];
        if (token == null) continue;
        if (token is! String || token.length != 4) return null;
        final tile = threeEachTileIds.indexOf(token.substring(0, 2));
        if (tile < 0) return null;
        if (token[2] != 'r') return null;
        final rotation = int.tryParse(token.substring(3));
        if (rotation == null || rotation < 0 || rotation > 3) return null;
        if (!seen.add(tile)) return null;
        slots[i] = ThreeEachPlacement(tile, rotation);
      }

      return ThreeEachState(slots);
    } catch (_) {
      return null;
    }
  }
}
