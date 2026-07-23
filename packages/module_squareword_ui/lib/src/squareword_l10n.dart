import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Localized strings needed by the squareword module's play/list/tutorial
/// widgets.
///
/// Unlike `module_labyrinth`'s `LabyrinthL10n`, there is no `glyphFor()`:
/// every squareword puzzle's letters are its own Cyrillic keyword, and (per
/// the module's locked M-c scope) that keyword is shown as-is in every
/// locale — no EN/DE glyph substitution table exists for this module.
abstract class SquarewordL10n {
  /// Title for the puzzle list screen.
  String get puzzleListTitle;

  /// Title for puzzle number [n], e.g. "Squareword 3".
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

  /// Progress counter, e.g. "Filled: 12 of 25".
  String filledCounter(int filled, int total);

  /// One-line warning shown when a letter repeats in a row, column, or
  /// diagonal.
  String get violationWarning;

  /// Accessibility (screen reader) label for a grid cell.
  String get cellSemantics;

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

  /// Short note explaining that puzzle letters stay Cyrillic in every
  /// locale (no EN/DE substitution alphabet exists for this module). Empty
  /// in the RU adapter (nothing to explain to a Russian reader); shown as a
  /// small caption on the puzzle list screen only when non-empty.
  String get cyrillicNote;
}

/// Supplies the [SquarewordL10n] implementation for the current app locale.
/// Must be overridden by the app shell before any module_squareword_ui
/// widget is built.
final Provider<SquarewordL10n> squarewordL10nProvider = Provider<SquarewordL10n>((ref) {
  throw UnimplementedError(
    'squarewordL10nProvider must be overridden with a concrete SquarewordL10n before use.',
  );
});
