import 'model.dart';

/// One step of the guided "how to solve" tutorial overlaid on the
/// `example` puzzle.
///
/// Mirrors module_domino's `DominoTutorialStep`, adapted for a path
/// instead of a domino set: [revealPathIndices] and [highlightPathIndices]
/// reference the example puzzle's stored 33-cell `solution` by index
/// rather than embedding cells directly, so the tutorial's shape stays
/// decoupled from that puzzle's coordinates. Reveals are cumulative
/// across steps (see [labyrinthTutorialSteps]). [crossCells] are absolute
/// grid cells (not solution indices) this step calls out to demonstrate
/// the long-press-to-cross mechanic, independent of the path reveal.
/// [markCells] are likewise absolute grid cells, calling out the "must be
/// on path" mark mechanic instead.
class LabyrinthTutorialStep {
  /// The l10n key for this step's instructional text.
  final String textKey;

  /// Solution indices newly revealed (auto-placed on the path) as of this
  /// step, in addition to every index revealed by earlier steps.
  final List<int> revealPathIndices;

  /// Solution indices to visually emphasize for this step.
  final List<int> highlightPathIndices;

  /// Grid cells this step calls out directly (e.g. a manual-cross demo).
  final List<Cell> crossCells;

  /// Grid cells this step calls out with the "must be on path" mark (the
  /// book's dot notation), to demonstrate the marking mechanic. Absolute
  /// grid cells, not solution indices - same convention as [crossCells].
  final List<Cell> markCells;

  /// Creates a tutorial step.
  const LabyrinthTutorialStep({
    required this.textKey,
    this.revealPathIndices = const [],
    this.highlightPathIndices = const [],
    this.crossCells = const [],
    this.markCells = const [],
  });
}

/// The 12 fixed steps of the guided tutorial, walking the player through
/// solving the `example` puzzle along its stored `solution` order. Step
/// `i` (1-based) corresponds to `labyrinthTutorialSteps[i - 1]`.
///
/// Steps 1-3 teach the mechanic - extending from `А`, extending from `Я`
/// as a second, independent chain, and long-pressing to mark a manual
/// cross plus the resulting automatic crosses, plus the "must be on path"
/// mark - and reveal no path cells
/// ([LabyrinthTutorialStep.revealPathIndices] is empty for all three).
/// Steps 4-12 then walk the full 33-cell solution in nine contiguous,
/// ascending, non-overlapping chunks of sizes 4, 4, 4, 4, 4, 4, 3, 3, 3
/// (summing to 33): the cumulative union of every step's
/// [LabyrinthTutorialStep.revealPathIndices] across steps 4-12 is exactly
/// `{0, 1, ..., 32}`, with no index appearing twice and none missing.
const List<LabyrinthTutorialStep> labyrinthTutorialSteps = [
  // 1: intro - extend the path from А by tapping an adjacent cell.
  LabyrinthTutorialStep(
    textKey: 'labyrinthTutorialStep1',
    highlightPathIndices: [0],
  ),
  // 2: Я grows its own chain the same way; the two chains meet later.
  LabyrinthTutorialStep(
    textKey: 'labyrinthTutorialStep2',
    highlightPathIndices: [32],
  ),
  // 3: long-press to mark a manual cross, and the automatic-cross rule -
  // demonstrated on the example grid's duplicate Ю pair at (1,7)/(2,0) -
  // plus the "must be on path" mark, demonstrated on У at (0,6), which
  // occurs exactly once in the grid.
  LabyrinthTutorialStep(
    textKey: 'labyrinthTutorialStep3',
    crossCells: [Cell(1, 7), Cell(2, 0)],
    markCells: [Cell(0, 6)],
  ),
  // 4
  LabyrinthTutorialStep(
    textKey: 'labyrinthTutorialStep4',
    revealPathIndices: [0, 1, 2, 3],
    highlightPathIndices: [0, 1, 2, 3],
  ),
  // 5
  LabyrinthTutorialStep(
    textKey: 'labyrinthTutorialStep5',
    revealPathIndices: [4, 5, 6, 7],
    highlightPathIndices: [4, 5, 6, 7],
  ),
  // 6
  LabyrinthTutorialStep(
    textKey: 'labyrinthTutorialStep6',
    revealPathIndices: [8, 9, 10, 11],
    highlightPathIndices: [8, 9, 10, 11],
  ),
  // 7
  LabyrinthTutorialStep(
    textKey: 'labyrinthTutorialStep7',
    revealPathIndices: [12, 13, 14, 15],
    highlightPathIndices: [12, 13, 14, 15],
  ),
  // 8
  LabyrinthTutorialStep(
    textKey: 'labyrinthTutorialStep8',
    revealPathIndices: [16, 17, 18, 19],
    highlightPathIndices: [16, 17, 18, 19],
  ),
  // 9
  LabyrinthTutorialStep(
    textKey: 'labyrinthTutorialStep9',
    revealPathIndices: [20, 21, 22, 23],
    highlightPathIndices: [20, 21, 22, 23],
  ),
  // 10
  LabyrinthTutorialStep(
    textKey: 'labyrinthTutorialStep10',
    revealPathIndices: [24, 25, 26],
    highlightPathIndices: [24, 25, 26],
  ),
  // 11
  LabyrinthTutorialStep(
    textKey: 'labyrinthTutorialStep11',
    revealPathIndices: [27, 28, 29],
    highlightPathIndices: [27, 28, 29],
  ),
  // 12: final stretch - path complete, join detected, win.
  LabyrinthTutorialStep(
    textKey: 'labyrinthTutorialStep12',
    revealPathIndices: [30, 31, 32],
    highlightPathIndices: [30, 31, 32],
  ),
];
