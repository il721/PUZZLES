import 'model.dart';
import 'player_grid.dart';

/// One step of the guided "how to solve" tutorial overlaid on the
/// `example` puzzle.
///
/// [reveal] lists cells that become pre-filled with their canonical digit
/// as of this step, in addition to every cell revealed by earlier steps
/// (reveals are cumulative across steps). [highlightCells] lists individual
/// cells to visually emphasize for this step. [highlightRow], if set (0..4),
/// emphasizes every cell of that grid row, including its result/total box.
/// [highlightColumn], if set (0..3), emphasizes that operand slot across
/// arithmetic rows 0..3 plus the corresponding summary cell
/// `(4, highlightColumn)`.
class TutorialStep {
  /// Cells revealed (pre-filled with their canonical digit) as of this
  /// step.
  final List<CellRef> reveal;

  /// Individual cells to emphasize for this step.
  final List<CellRef> highlightCells;

  /// If non-null (0..4), emphasize every cell of this grid row.
  final int? highlightRow;

  /// If non-null (0..3), emphasize this operand slot across rows 0..3 plus
  /// the corresponding summary cell.
  final int? highlightColumn;

  /// Creates a tutorial step.
  const TutorialStep({
    this.reveal = const [],
    this.highlightCells = const [],
    this.highlightRow,
    this.highlightColumn,
  });
}

/// The canonical digit at [ref] for [puzzle], derived from its canonical
/// solution strings: an arithmetic row's operands/result for `row <= 3`, or
/// the summary row's column sums (the corresponding row's result) and grand
/// total for `row == 4`.
int canonicalDigitAt(RebusPuzzle puzzle, CellRef ref) {
  final String s;
  if (ref.row <= 3) {
    s = ref.slot <= 3 ? puzzle.rows[ref.row].nums[ref.slot] : puzzle.rows[ref.row].result;
  } else {
    s = ref.slot <= 3 ? puzzle.rows[ref.slot].result : puzzle.total;
  }
  return int.parse(s[ref.pos]);
}

/// The 15 fixed steps of the guided tutorial, walking the player through
/// solving the `example` puzzle. Step `i` (1-based, as referenced by
/// `RebusL10n.tutorialStepText`) corresponds to `tutorialSteps[i - 1]`.
const List<TutorialStep> tutorialSteps = [
  // 1: intro — no reveal, no highlight.
  TutorialStep(),
  // 2: point out the equation rows.
  TutorialStep(highlightRow: 0),
  // 3: point out the summary row.
  TutorialStep(highlightRow: 4),
  // 4: link row 1's result to the summary row and row 2's result.
  TutorialStep(
    highlightCells: [CellRef(0, 4, 0), CellRef(4, 0, 0), CellRef(4, 1, 1), CellRef(1, 4, 1)],
  ),
  // 5: reveal the tens digit of row 2's third number.
  TutorialStep(reveal: [CellRef(1, 2, 0)], highlightRow: 1),
  // 6: focus on row 2's result.
  TutorialStep(highlightCells: [CellRef(1, 4, 0), CellRef(1, 4, 1)]),
  // 7: reveal the rest of row 2.
  TutorialStep(
    reveal: [CellRef(1, 0, 0), CellRef(1, 1, 0), CellRef(1, 3, 0), CellRef(1, 4, 0), CellRef(4, 1, 0)],
    highlightRow: 1,
  ),
  // 8: focus on the second column.
  TutorialStep(highlightColumn: 1),
  // 9: reveal the second column's row-3/row-4 entries.
  TutorialStep(reveal: [CellRef(2, 1, 0), CellRef(3, 1, 0)], highlightColumn: 1),
  // 10: link row 1's result to the summary row.
  TutorialStep(
    highlightCells: [CellRef(0, 4, 0), CellRef(0, 4, 1), CellRef(4, 0, 0), CellRef(4, 0, 1)],
  ),
  // 11: reveal row 3.
  TutorialStep(
    reveal: [CellRef(2, 0, 0), CellRef(2, 4, 0), CellRef(2, 4, 1), CellRef(4, 2, 0), CellRef(4, 2, 1)],
    highlightRow: 2,
  ),
  // 12: focus on the third column.
  TutorialStep(highlightColumn: 2),
  // 13: reveal the rest of row 1.
  TutorialStep(
    reveal: [CellRef(0, 0, 0), CellRef(0, 2, 0), CellRef(0, 4, 1), CellRef(4, 0, 1)],
    highlightRow: 0,
  ),
  // 14: reveal row 4.
  TutorialStep(
    reveal: [
      CellRef(3, 0, 0),
      CellRef(3, 2, 0),
      CellRef(3, 3, 0),
      CellRef(3, 3, 1),
      CellRef(3, 4, 0),
      CellRef(3, 4, 1),
      CellRef(4, 3, 0),
      CellRef(4, 3, 1),
    ],
    highlightRow: 3,
  ),
  // 15: reveal the grand total.
  TutorialStep(reveal: [CellRef(4, 4, 0), CellRef(4, 4, 1), CellRef(4, 4, 2)], highlightRow: 4),
];
