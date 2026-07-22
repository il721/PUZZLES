import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Localized strings needed by the labyrinth module's play/list/tutorial
/// widgets.
///
/// The app shell supplies a concrete implementation via an override of
/// [labyrinthL10nProvider].
abstract class LabyrinthL10n {
  /// Maps a canonical (Cyrillic) letter to the glyph rendered on screen.
  /// The RU adapter returns [canonicalLetter] unchanged; EN/DE adapters
  /// apply `letterGlyphs` from `module_labyrinth`. The UI must apply this
  /// to every rendered grid cell and to the alphabet tracker strip.
  String glyphFor(String canonicalLetter);

  /// Title for the puzzle list screen.
  String get puzzleListTitle;

  /// Title for puzzle number [n], e.g. "Labyrinth 3".
  String puzzleN(int n);

  /// Semantic label for an untouched (never opened) puzzle.
  String get statusUntouched;

  /// Semantic label for a puzzle with saved progress but not yet solved.
  String get statusInProgress;

  /// Semantic label for a solved puzzle.
  String get statusSolved;

  /// Label for the "Reset" action.
  String get reset;

  /// Label for the "Replay" action.
  String get replay;

  /// Title of the reset confirmation dialog.
  String get resetConfirmTitle;

  /// Body text of the reset confirmation dialog.
  String get resetConfirmBody;

  /// Cancel button of the reset confirmation dialog.
  String get resetConfirmCancel;

  /// Confirm button of the reset confirmation dialog.
  String get resetConfirmOk;

  /// Title of the win dialog.
  String get winTitle;

  /// Body text of the win dialog.
  String get winBody;

  /// Label for the "Next puzzle" action.
  String get next;

  /// Label for the "Back to list" action.
  String get backToList;

  /// Progress counter, e.g. "Letters: 12 of 33".
  String placedCounter(int placed);

  /// Header label above the alphabet tracker strip.
  String get alphabetLabel;

  /// One-line warning shown when a letter appears twice on the path.
  String get duplicateWarning;

  /// Accessibility (screen reader) label for a grid cell.
  String get cellSemantics;

  /// Accessibility (screen reader) fragment appended to a cell's semantics
  /// label when the player has marked it with [LabyrinthBoard.toggleMark]
  /// (the book's "this letter is unique in the grid, so it must be on the
  /// path" deduction). Appended after [cellSemantics]; keep it short.
  String get markedSemantics;

  /// Title of the guided tutorial screen.
  String get tutorialTitle;

  /// Label for the tutorial's Next action.
  String get tutorialNext;

  /// Label for the tutorial's Back action.
  String get tutorialBack;

  /// Label for the tutorial's Skip action.
  String get tutorialSkip;

  /// Label for the tutorial's final Done action.
  String get tutorialDone;

  /// Step counter shown on the tutorial screen, e.g. "Step 3 of 12".
  String tutorialStepCounter(int current, int total);

  /// Instructional text for tutorial step [index] (1..12).
  String tutorialStepText(int index);
}

/// Supplies the [LabyrinthL10n] implementation for the current app locale.
/// Must be overridden by the app shell before any module_labyrinth_ui
/// widget is built.
final Provider<LabyrinthL10n> labyrinthL10nProvider = Provider<LabyrinthL10n>((ref) {
  throw UnimplementedError(
    'labyrinthL10nProvider must be overridden with a concrete LabyrinthL10n before use.',
  );
});
