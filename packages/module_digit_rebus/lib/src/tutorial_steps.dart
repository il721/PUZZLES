import 'model.dart';
import 'verifier.dart';

/// One step of the guided "how to solve" tutorial overlaid on the
/// `example` puzzle.
///
/// [reveal] lists cells that become pre-filled with their canonical digit
/// as of this step, in addition to every cell revealed by earlier steps
/// (reveals are cumulative across steps). [highlightCells] lists
/// individual cells to visually emphasize for this step. [highlightRow] /
/// [highlightColumn], if set (0..3), emphasize every cell of that grid row
/// or column.
class TutorialStep {
  /// Cells revealed (pre-filled with their canonical digit) as of this
  /// step.
  final List<CellRef> reveal;

  /// Individual cells to emphasize for this step.
  final List<CellRef> highlightCells;

  /// If non-null (0..3), emphasize every cell of this grid row.
  final int? highlightRow;

  /// If non-null (0..3), emphasize every cell of this grid column.
  final int? highlightColumn;

  /// Creates a tutorial step.
  const TutorialStep({
    this.reveal = const [],
    this.highlightCells = const [],
    this.highlightRow,
    this.highlightColumn,
  });
}

/// The canonical digit at [ref] for [puzzle] — the book's printed answer
/// digit for that cell.
int canonicalDigitAt(DigitRebusPuzzle puzzle, CellRef ref) =>
    puzzle.answer[ref.row][ref.col];

/// The 9 fixed steps of the guided tutorial, walking the player through
/// solving the `example` puzzle along the book's deduction chain
/// (pp. 31-33): row 2, then column 1, then row 3, then column 3, then the
/// remaining cells. Step `i` (1-based, as referenced by
/// `DigitRebusL10n.tutorialStepText`) corresponds to `tutorialSteps[i - 1]`.
///
/// Book references are 1-based; [TutorialStep] indices are 0-based (book
/// row 2 = `highlightRow: 1`, book column 1 = `highlightColumn: 0`).
const List<TutorialStep> tutorialSteps = [
  // 1: intro — every cell is masked by a glyph; no reveal, no highlight.
  TutorialStep(),
  // 2: the glyph legend — each glyph admits 2-3 digits (text-only step).
  TutorialStep(),
  // 3: examine row 2: its glyph sets force the equation 1 + 2 * 3 = 9.
  TutorialStep(highlightRow: 1),
  // 4: reveal row 2 (1, 2, 3, 9).
  TutorialStep(
    reveal: [CellRef(1, 0), CellRef(1, 1), CellRef(1, 2), CellRef(1, 3)],
    highlightRow: 1,
  ),
  // 5: column 1 now has its second cell — deduce 4 - 1 * 3 = 9 and
  // reveal the rest of the column.
  TutorialStep(
    reveal: [CellRef(0, 0), CellRef(2, 0), CellRef(3, 0)],
    highlightColumn: 0,
  ),
  // 6: row 3 starts with 3 — deduce 3 + 2 + 1 = 6 and reveal the rest.
  TutorialStep(
    reveal: [CellRef(2, 1), CellRef(2, 2), CellRef(2, 3)],
    highlightRow: 2,
  ),
  // 7: column 3 — deduce 6 - 3 - 1 = 2 and reveal its remaining cells.
  TutorialStep(
    reveal: [CellRef(0, 2), CellRef(3, 2)],
    highlightColumn: 2,
  ),
  // 8: the remaining four cells follow from their rows and columns.
  TutorialStep(
    reveal: [CellRef(0, 1), CellRef(0, 3), CellRef(3, 1), CellRef(3, 3)],
  ),
  // 9: done — the full grid satisfies all 8 equations.
  TutorialStep(),
];
