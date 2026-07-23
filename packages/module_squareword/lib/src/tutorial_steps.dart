import 'model.dart';

/// One step of the guided "how to solve" tutorial overlaid on the
/// `tutorial` puzzle (keyword СЛЕЗА, 5x5, `05--d_t.pdf` pp.80-82).
///
/// Mirrors `module_labyrinth`'s `LabyrinthTutorialStep`: [textKey] is an
/// l10n key, not raw text - actual RU/EN/DE strings are added to the ARB
/// files in a later milestone (M-d), matching how `module_labyrinth`'s
/// `LabyrinthTutorialStep.textKey` defers to `LabyrinthL10n` rather than
/// embedding text here. [reveal] lists the cells newly placed as of this
/// step (in addition to every cell revealed by earlier steps - reveals are
/// cumulative across [squarewordTutorialSteps], but each step's own
/// [reveal] list holds only what's new in that step, not the running
/// total). Reused directly as [Given] triples, since a tutorial reveal and
/// a puzzle given are the same shape: a cell plus the letter that belongs
/// there.
class SquarewordTutorialStep {
  /// The l10n key for this step's instructional text.
  final String textKey;

  /// Cells newly revealed (auto-placed) as of this step.
  final List<Given> reveal;

  /// Creates a tutorial step.
  const SquarewordTutorialStep({
    required this.textKey,
    this.reveal = const [],
  });
}

/// The 12 fixed steps of the guided tutorial, walking the player through
/// solving the `tutorial` puzzle (keyword СЛЕЗА).
///
/// Step 1 introduces the grid and the rule (every row, every column, the
/// main diagonal, and the anti-diagonal each contain every one of the 5
/// keyword letters exactly once) and reveals nothing. Step 2 frames the
/// book's own deduction chain and also reveals nothing. Steps 3-11 then
/// replay that deduction chain cell by cell, transcribed and independently
/// verified against the book's actual printed reasoning (not paraphrased
/// or invented) - the cumulative union of every step's [reveal] across
/// steps 3-11 is exactly the `tutorial` puzzle's 17 non-given cells, no
/// gaps, no cell revealed twice. Step 12 is a closing step (grid complete,
/// no violations) and reveals nothing.
const List<SquarewordTutorialStep> squarewordTutorialSteps = [
  // 1: intro - the grid, the keyword row, the scattered given word, and
  // the rule itself (row/column/main-diagonal/anti-diagonal each hold
  // every one of the 5 letters exactly once).
  SquarewordTutorialStep(textKey: 'squarewordTutorialStep1'),

  // 2: framing - from here on, every remaining cell is forced by
  // elimination against the givens and the rule; no guessing needed.
  SquarewordTutorialStep(textKey: 'squarewordTutorialStep2'),

  // 3: d1=Л; excluded from b1,c1 (columns already have Л), and from a1,e1
  // because c3=Л sits on BOTH diagonals at once (center cell of a 5x5).
  SquarewordTutorialStep(
    textKey: 'squarewordTutorialStep3',
    reveal: [Given(4, 3, 'Л')],
  ),

  // 4: column d: А forced to d2 (d4 is on the anti-diagonal, which already
  // has А via e5); С then forced to d4.
  SquarewordTutorialStep(
    textKey: 'squarewordTutorialStep4',
    reveal: [Given(3, 3, 'А'), Given(1, 3, 'С')],
  ),

  // 5: column b: С excluded from b4 (main diagonal already has С via a5),
  // from b2 (anti-diagonal already has С via d4), from b3 (row 3 already
  // has С via e3) -> forced to b1.
  SquarewordTutorialStep(
    textKey: 'squarewordTutorialStep5',
    reveal: [Given(4, 1, 'С')],
  ),

  // 6: the fifth and last С -> c2.
  SquarewordTutorialStep(
    textKey: 'squarewordTutorialStep6',
    reveal: [Given(3, 2, 'С')],
  ),

  // 7: row 1: only c1 remains for А.
  SquarewordTutorialStep(
    textKey: 'squarewordTutorialStep7',
    reveal: [Given(4, 2, 'А')],
  ),

  // 8: column c now forces З into c4.
  SquarewordTutorialStep(
    textKey: 'squarewordTutorialStep8',
    reveal: [Given(1, 2, 'З')],
  ),

  // 9: the two remaining А land at a4 and b3.
  SquarewordTutorialStep(
    textKey: 'squarewordTutorialStep9',
    reveal: [Given(1, 0, 'А'), Given(2, 1, 'А')],
  ),

  // 10: row 3: а3 must be З.
  SquarewordTutorialStep(
    textKey: 'squarewordTutorialStep10',
    reveal: [Given(2, 0, 'З')],
  ),

  // 11: the rest is now forced: Е-b4, Л-e4, З-e1, Е-a1, Е-e2, Л-a2, З-b2.
  SquarewordTutorialStep(
    textKey: 'squarewordTutorialStep11',
    reveal: [
      Given(1, 1, 'Е'),
      Given(1, 4, 'Л'),
      Given(4, 4, 'З'),
      Given(4, 0, 'Е'),
      Given(3, 4, 'Е'),
      Given(3, 0, 'Л'),
      Given(3, 1, 'З'),
    ],
  ),

  // 12: closing - grid complete, zero violations, solved.
  SquarewordTutorialStep(textKey: 'squarewordTutorialStep12'),
];
