/// One step of the guided "how to solve" tutorial overlaid on the
/// `example` puzzle.
///
/// Unlike module_digit_rebus's `TutorialStep` (which references grid
/// cells directly), steps here reference dominoes by their index into
/// `example.solution` — the book's recorded deduction order — so the
/// tutorial's shape stays decoupled from that puzzle's coordinates.
///
/// [revealSolutionIndices] lists the *new* dominoes (indices into
/// `example.solution`) that become auto-placed as of this step, in
/// addition to every domino revealed by earlier steps (reveals are
/// cumulative across steps, mirroring module_digit_rebus's
/// `TutorialStep.reveal`). [highlightSolutionIndices] lists the solution
/// indices to visually emphasize for this step.
class DominoTutorialStep {
  /// Solution indices newly revealed (auto-placed) as of this step.
  final List<int> revealSolutionIndices;

  /// Solution indices to visually emphasize for this step.
  final List<int> highlightSolutionIndices;

  /// Creates a tutorial step.
  const DominoTutorialStep({
    this.revealSolutionIndices = const [],
    this.highlightSolutionIndices = const [],
  });
}

/// The 10 fixed steps of the guided tutorial, walking the player through
/// solving the `example` puzzle along the book's deduction order recorded
/// in `example.solution`. Step `i` (1-based) corresponds to
/// `dominoTutorialSteps[i - 1]`; step count 10 means l10n keys
/// `dominoTutorialStep1`..`dominoTutorialStep10` are authored in a later
/// milestone (M-d).
///
/// The union of every step's [DominoTutorialStep.revealSolutionIndices]
/// is exactly `{0, 1, ..., 27}` with no duplicates and no gaps: across
/// the 10 steps, the tutorial places each of the example's 28 dominoes
/// exactly once.
const List<DominoTutorialStep> dominoTutorialSteps = [
  // 1: intro — how to bind two cells into a domino. No reveal, no
  // highlight.
  DominoTutorialStep(),
  // 2: the value tracker and the duplicate-value rule. No reveal.
  DominoTutorialStep(),
  // 3: first three forced dominoes.
  DominoTutorialStep(
    revealSolutionIndices: [0, 1, 2],
    highlightSolutionIndices: [0, 1, 2],
  ),
  // 4: next two forced dominoes.
  DominoTutorialStep(
    revealSolutionIndices: [3, 4],
    highlightSolutionIndices: [3, 4],
  ),
  // 5
  DominoTutorialStep(
    revealSolutionIndices: [5, 6],
    highlightSolutionIndices: [5, 6],
  ),
  // 6
  DominoTutorialStep(
    revealSolutionIndices: [7, 8, 9, 10],
    highlightSolutionIndices: [7, 8, 9, 10],
  ),
  // 7
  DominoTutorialStep(
    revealSolutionIndices: [11, 12, 13],
    highlightSolutionIndices: [11, 12, 13],
  ),
  // 8
  DominoTutorialStep(
    revealSolutionIndices: [14, 15, 16, 17],
    highlightSolutionIndices: [14, 15, 16, 17],
  ),
  // 9
  DominoTutorialStep(
    revealSolutionIndices: [18, 19, 20, 21, 22],
    highlightSolutionIndices: [18, 19, 20, 21, 22],
  ),
  // 10: final dominoes — board complete, win.
  DominoTutorialStep(
    revealSolutionIndices: [23, 24, 25, 26, 27],
    highlightSolutionIndices: [23, 24, 25, 26, 27],
  ),
];
