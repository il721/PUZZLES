import 'model.dart';

/// An order-independent canonical value-pair for a domino: the sorted pair
/// of the two printed digits it covers. `DominoValue.of(a, b)` and
/// `DominoValue.of(b, a)` are always equal, so a value can be used as a
/// dedup/lookup key regardless of which of a domino's two cells is deemed
/// "first" (which itself is arbitrary — [Domino] equality is unordered).
class DominoValue {
  /// The smaller of the two printed digits.
  final int low;

  /// The larger of the two printed digits.
  final int high;

  /// Creates a value directly from an already-sorted pair
  /// (`low <= high`). Prefer [DominoValue.of] when the order of the
  /// source digits is not already known to be sorted.
  const DominoValue(this.low, this.high);

  /// Canonicalizes the printed digits [a] and [b] into sorted order.
  factory DominoValue.of(int a, int b) =>
      a <= b ? DominoValue(a, b) : DominoValue(b, a);

  @override
  bool operator ==(Object other) =>
      other is DominoValue && other.low == low && other.high == high;

  @override
  int get hashCode => Object.hash(low, high);

  @override
  String toString() => '$low:$high';
}

/// The 28 distinct value-pairs of a standard double-six domino set: every
/// `(i, j)` with `0 <= i <= j <= 6`. A fresh [Set] (in ascending
/// `(low, high)` order) is built on each access so callers can never
/// accidentally mutate shared state.
Set<DominoValue> get doubleSixSet => {
      for (var i = 0; i <= 6; i++)
        for (var j = i; j <= 6; j++) DominoValue(i, j),
    };

/// The canonical [DominoValue] of [d] on [puzzle]'s grid — the sorted pair
/// of the printed digits under its two cells.
DominoValue valueOf(DominoPuzzle puzzle, Domino d) =>
    DominoValue.of(puzzle.valueAt(d.a), puzzle.valueAt(d.b));

/// The result of [verifyBoard]: everything needed to render the board's
/// current state and drive the win condition.
///
/// Scope rules mirror module_digit_rebus's verifier: this is a snapshot
/// computed purely from the dominoes currently placed, with no dependency
/// on placement order or history.
///  * [conflicts] is computed from whichever dominoes are placed *right
///    now* — a duplicate value-pair is flagged the moment both dominoes
///    sharing it are on the board, whether or not the rest of the grid is
///    covered.
///  * [isComplete] (and therefore [isSolved]) requires all 56 cells to be
///    covered by *non-overlapping* placed dominoes: two placed dominoes
///    that overlap collapse [coveredCells] to fewer than 56 distinct
///    cells, so an overlapping board is never falsely reported complete.
///  * A partial board is therefore never falsely "solved": [isSolved]
///    requires both full, non-overlapping coverage and zero conflicts.
class BoardStatus {
  /// Every distinct cell covered by at least one placed domino.
  final Set<Cell> coveredCells;

  /// The number of dominoes placed (as passed to [verifyBoard]).
  final int placedCount;

  /// Every placed domino whose canonical value is shared with at least
  /// one other placed domino (a duplicate value-pair). If a value is used
  /// by 3+ placed dominoes, all of them are included.
  final Set<Domino> conflicts;

  /// The canonical value of every placed domino, deduplicated.
  final Set<DominoValue> usedValues;

  /// Creates a board status snapshot.
  BoardStatus({
    required this.coveredCells,
    required this.placedCount,
    required this.conflicts,
    required this.usedValues,
  });

  /// Whether all 56 cells are covered by non-overlapping placed dominoes.
  bool get isComplete => coveredCells.length == 56;

  /// The win condition: full, non-overlapping coverage with no duplicate
  /// value-pairs. 28 non-overlapping dominoes with no duplicate value is
  /// equivalent (by pigeonhole, since there are exactly 28 possible
  /// value-pairs for digits 0..6) to exactly the full double-six set.
  bool get isSolved => isComplete && conflicts.isEmpty;

  /// The double-six values not yet used by any placed domino, in stable
  /// ascending `(low, high)` order.
  List<DominoValue> get remaining => [
        for (final v in doubleSixSet)
          if (!usedValues.contains(v)) v,
      ];
}

/// Computes the current [BoardStatus] for [placed] dominoes on [puzzle].
///
/// [placed] need not be non-overlapping or complete: this is a pure
/// snapshot function, safe to call after every player action.
BoardStatus verifyBoard(DominoPuzzle puzzle, Iterable<Domino> placed) {
  final placedList = placed.toList(growable: false);

  final coveredCells = <Cell>{};
  for (final d in placedList) {
    coveredCells.add(d.a);
    coveredCells.add(d.b);
  }

  final byValue = <DominoValue, List<Domino>>{};
  for (final d in placedList) {
    byValue.putIfAbsent(valueOf(puzzle, d), () => []).add(d);
  }

  final conflicts = <Domino>{};
  final usedValues = <DominoValue>{};
  for (final entry in byValue.entries) {
    usedValues.add(entry.key);
    if (entry.value.length > 1) {
      conflicts.addAll(entry.value);
    }
  }

  return BoardStatus(
    coveredCells: coveredCells,
    placedCount: placedList.length,
    conflicts: conflicts,
    usedValues: usedValues,
  );
}
