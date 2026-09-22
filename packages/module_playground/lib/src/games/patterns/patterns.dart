import '../../data.dart';
import '../../playground_game.dart';
import 'patterns_tiles.dart';

/// One tile laid on the board: which tile ([tile], an index into the game's
/// tile list) and how far it has been turned clockwise ([rotation], 0-3
/// quarter turns). Tiles are one-sided cardboard, so they rotate but never
/// flip.
class PatternsPlacement {
  /// Index into the owning game's tile list.
  final int tile;

  /// Quarter turns clockwise, 0-3.
  final int rotation;

  /// Creates a placement of [tile] turned [rotation] quarter turns.
  const PatternsPlacement(this.tile, this.rotation);

  @override
  bool operator ==(Object other) =>
      other is PatternsPlacement &&
      other.tile == tile &&
      other.rotation == rotation;

  @override
  int get hashCode => Object.hash(tile, rotation);

  @override
  String toString() => 'PatternsPlacement(T${tile + 1}r$rotation)';
}

/// The play state of «Узоры»: which tile (if any) lies in each board slot,
/// and at which rotation. [slots] is indexed in row-major order of the
/// square; a null entry means that slot is empty, and the tiles not present
/// in [slots] are the ones still in the tray. Immutable and
/// content-comparable.
class PatternsState extends PlaygroundState {
  /// What lies in each slot, row-major; null means empty.
  final List<PatternsPlacement?> slots;

  /// Creates a state directly from a per-slot [slots] list.
  const PatternsState(this.slots);

  /// The empty board of [slotCount] slots: every tile still in the tray.
  factory PatternsState.empty(int slotCount) =>
      PatternsState(List<PatternsPlacement?>.filled(slotCount, null));

  /// The slot index holding tile [tile], or null if it is still in the tray.
  int? slotOfTile(int tile) {
    for (var i = 0; i < slots.length; i++) {
      if (slots[i]?.tile == tile) return i;
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (other is! PatternsState) return false;
    if (other.slots.length != slots.length) return false;
    for (var i = 0; i < slots.length; i++) {
      if (other.slots[i] != slots[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(slots);

  @override
  String toString() {
    final cells = slots.map(
      (p) => p == null ? '-' : 'T${p.tile + 1}r${p.rotation}',
    );
    return 'PatternsState(${cells.join(', ')})';
  }
}

/// «Узоры» (Мочалов, 1980, p. 62): square cardboard tiles carrying red line
/// segments are laid into a [size] x [size] square so that the segments join
/// into one closed, non-self-intersecting line.
///
/// Each tile is a 2x2 block of cells and each cell's connector joins two of
/// its four sides, so on a full board the line passes through every one of
/// the (2 * [size])^2 cells. What a player can get wrong is therefore not
/// coverage but continuity: a red end may meet a neighbour's blank edge, a
/// red end may point off the board, or the segments may close into several
/// separate loops instead of one. [isSolved] tests exactly those three
/// things.
///
/// A move either lays a tray tile into an empty slot at a chosen rotation
/// (T4 -> S6r2), turns a tile already on the board (S6 -> S6r3), or takes a
/// tile back to the tray (S6 -> T4) - the same vocabulary as «Всюду по три».
///
/// There is no move economy: the puzzle asks for a valid pattern, never for
/// the fewest placements, so [par] is null and no star is ever awarded.
/// [optimalSolution] is nonetheless recorded - the placements of one valid
/// pattern, used by the post-solve replay.
class PatternsGame extends PlaygroundGame {
  final PlaygroundGameData? _data;

  /// The tiles this game ships, in tray order.
  final List<List<String>> tiles;

  /// The board's side in tiles; the square holds [size] * [size] slots.
  final int size;

  @override
  final String id;

  /// Creates a «Узоры» game of [size] x [size] tiles over [tiles],
  /// optionally backed by parsed puzzle data supplying [optimalSolution].
  const PatternsGame({
    required this.id,
    required this.tiles,
    required this.size,
    PlaygroundGameData? data,
  }) : _data = data;

  /// «Узоры 5x5»: all twenty-five tiles, laid into a 5x5 square.
  factory PatternsGame.patterns5([PlaygroundGameData? data]) => PatternsGame(
        id: 'patterns5',
        tiles: patterns5Tiles,
        size: 5,
        data: data,
      );

  /// «Узоры 4x4»: the sixteen tiles of [patterns4Tiles], laid into a 4x4
  /// square. Same rules and same win predicate as [PatternsGame.patterns5],
  /// a separate game with its own tray, board and solved flag.
  factory PatternsGame.patterns4([PlaygroundGameData? data]) => PatternsGame(
        id: 'patterns4',
        tiles: patterns4Tiles,
        size: 4,
        data: data,
      );

  /// The number of board slots, [size] squared.
  int get slotCount => size * size;

  /// The board's side in cells - two cells per tile.
  int get cellSide => size * 2;

  /// The tray id of tile [tile], T1-based.
  String tileId(int tile) => 'T${tile + 1}';

  /// The board id of slot [slot], S1-based in row-major order.
  String slotId(int slot) => 'S${slot + 1}';

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
  PlaygroundState initialState() => PatternsState.empty(slotCount);

  /// The [cellSide] x [cellSide] grid of direction masks the laid tiles
  /// draw, row-major. Cells of an empty slot read as 0, so a partial board
  /// is still a well-formed grid.
  List<int> cellMasks(PatternsState state) {
    final cells = List<int>.filled(cellSide * cellSide, 0);
    for (var slot = 0; slot < state.slots.length; slot++) {
      final placement = state.slots[slot];
      if (placement == null) continue;
      final masks =
          patternsTileMasks(tiles[placement.tile], placement.rotation);
      final rowBase = (slot ~/ size) * 2;
      final colBase = (slot % size) * 2;
      for (var k = 0; k < 4; k++) {
        cells[(rowBase + k ~/ 2) * cellSide + colBase + k % 2] = masks[k];
      }
    }
    return cells;
  }

  @override
  List<PlaygroundMove> legalMoves(PlaygroundState state, {String? from}) {
    final s = state as PatternsState;
    final moves = <PlaygroundMove>[];

    for (var t = 0; t < tiles.length; t++) {
      if (s.slotOfTile(t) != null) continue;
      if (from != null && from != tileId(t)) continue;
      for (var slot = 0; slot < s.slots.length; slot++) {
        if (s.slots[slot] != null) continue;
        for (var rotation = 0; rotation < 4; rotation++) {
          moves.add(PlaygroundMove([tileId(t), '${slotId(slot)}r$rotation']));
        }
      }
    }

    for (var slot = 0; slot < s.slots.length; slot++) {
      final placement = s.slots[slot];
      if (placement == null) continue;
      if (from != null && from != slotId(slot)) continue;
      for (var rotation = 0; rotation < 4; rotation++) {
        if (rotation == placement.rotation) continue;
        moves.add(PlaygroundMove([slotId(slot), '${slotId(slot)}r$rotation']));
      }
      moves.add(PlaygroundMove([slotId(slot), tileId(placement.tile)]));
    }

    return moves;
  }

  @override
  PlaygroundState applyMove(PlaygroundState state, PlaygroundMove move) {
    final s = state as PatternsState;
    if (!legalMoves(s, from: move.from).contains(move)) {
      throw ArgumentError('$id: illegal move $move');
    }

    final slots = List<PatternsPlacement?>.from(s.slots);
    final fromSlot = _slotIndex(move.from);

    if (fromSlot != null) {
      final placement = slots[fromSlot]!;
      final toSlot = _slotIndex(move.to.split('r').first);
      slots[fromSlot] = toSlot == null
          ? null
          : PatternsPlacement(placement.tile, _rotationOf(move.to)!);
      return PatternsState(slots);
    }

    final tile = _tileIndex(move.from)!;
    final slot = _slotIndex(move.to.split('r').first)!;
    slots[slot] = PatternsPlacement(tile, _rotationOf(move.to)!);
    return PatternsState(slots);
  }

  int? _slotIndex(String id) {
    if (!id.startsWith('S')) return null;
    final n = int.tryParse(id.substring(1));
    if (n == null || n < 1 || n > slotCount) return null;
    return n - 1;
  }

  int? _tileIndex(String id) {
    if (!id.startsWith('T')) return null;
    final n = int.tryParse(id.substring(1));
    if (n == null || n < 1 || n > tiles.length) return null;
    return n - 1;
  }

  int? _rotationOf(String token) {
    final parts = token.split('r');
    if (parts.length != 2) return null;
    final rotation = int.tryParse(parts[1]);
    if (rotation == null || rotation < 0 || rotation > 3) return null;
    return rotation;
  }

  /// Whether every slot is filled, every red end meets a red end (inside the
  /// square and never over its border), and the segments form a single
  /// closed loop rather than several.
  ///
  /// This is a predicate on the drawn line, never equality against one
  /// stored winning arrangement: the puzzle has many valid patterns, every
  /// one of them turned as a whole among them.
  @override
  bool isSolved(PlaygroundState state) {
    final s = state as PatternsState;
    if (s.slots.any((p) => p == null)) return false;

    final cells = cellMasks(s);
    for (var r = 0; r < cellSide; r++) {
      for (var c = 0; c < cellSide; c++) {
        final mask = cells[r * cellSide + c];
        if (mask & patternsNorth != 0 &&
            (r == 0 || cells[(r - 1) * cellSide + c] & patternsSouth == 0)) {
          return false;
        }
        if (mask & patternsSouth != 0 &&
            (r == cellSide - 1 ||
                cells[(r + 1) * cellSide + c] & patternsNorth == 0)) {
          return false;
        }
        if (mask & patternsWest != 0 &&
            (c == 0 || cells[r * cellSide + c - 1] & patternsEast == 0)) {
          return false;
        }
        if (mask & patternsEast != 0 &&
            (c == cellSide - 1 ||
                cells[r * cellSide + c + 1] & patternsWest == 0)) {
          return false;
        }
      }
    }

    // Every cell carries exactly two ends, so a fully matched board is a
    // union of closed loops. One walk from cell 0 comes back to it after
    // visiting every cell exactly when that union is a single loop.
    var cell = 0;
    var entered = 0;
    var steps = 0;
    do {
      final exit = cells[cell] & ~entered;
      if (exit == 0) return false;
      final direction = exit & -exit;
      final r = cell ~/ cellSide;
      final c = cell % cellSide;
      cell = switch (direction) {
        patternsNorth => (r - 1) * cellSide + c,
        patternsSouth => (r + 1) * cellSide + c,
        patternsWest => r * cellSide + c - 1,
        _ => r * cellSide + c + 1,
      };
      entered = switch (direction) {
        patternsNorth => patternsSouth,
        patternsSouth => patternsNorth,
        patternsWest => patternsEast,
        _ => patternsWest,
      };
      steps++;
    } while (cell != 0 && steps <= cells.length);

    return steps == cells.length;
  }

  @override
  Map<String, dynamic> stateToJson(PlaygroundState state) {
    final s = state as PatternsState;
    return {
      'slots': [
        for (final p in s.slots)
          if (p == null) null else '${tileId(p.tile)}r${p.rotation}',
      ],
    };
  }

  /// Parses a state saved by [stateToJson].
  ///
  /// Returns null (never throws) for: [json] not a map; a slots value that
  /// is not a list of exactly [slotCount] entries; an entry that is neither
  /// null nor a tile-id-plus-rotation token with a known tile id and a
  /// rotation in 0-3; or the same tile appearing in two slots.
  @override
  PlaygroundState? stateFromJson(Object? json) {
    try {
      if (json is! Map) return null;
      final raw = json['slots'];
      if (raw is! List) return null;
      if (raw.length != slotCount) return null;

      final slots = List<PatternsPlacement?>.filled(raw.length, null);
      final seen = <int>{};

      for (var i = 0; i < raw.length; i++) {
        final token = raw[i];
        if (token == null) continue;
        if (token is! String) return null;
        final parts = token.split('r');
        if (parts.length != 2) return null;
        final tile = _tileIndex(parts[0]);
        if (tile == null) return null;
        final rotation = _rotationOf(token);
        if (rotation == null) return null;
        if (!seen.add(tile)) return null;
        slots[i] = PatternsPlacement(tile, rotation);
      }

      return PatternsState(slots);
    } catch (_) {
      return null;
    }
  }
}
