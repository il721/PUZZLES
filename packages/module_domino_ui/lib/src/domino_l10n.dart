import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Localized strings needed by the domino module's play/list widgets.
///
/// The app shell supplies a concrete implementation via an override of
/// [dominoL10nProvider]. Tutorial-specific strings are added in a later
/// milestone.
abstract class DominoL10n {
  /// Title for the puzzle list screen.
  String get puzzleListTitle;

  /// Title for puzzle number [n], e.g. "Domino 3".
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

  /// Progress counter, e.g. "Placed: 12 of 28".
  String placedCounter(int placed);

  /// Header label above the remaining-values list.
  String get remainingLabel;

  /// One-line warning shown when duplicate value-pairs are on the board.
  String get duplicateWarning;

  /// Accessibility (screen reader) label for a grid cell.
  String get cellSemantics;
}

/// Supplies the [DominoL10n] implementation for the current app locale.
/// Must be overridden by the app shell before any module_domino_ui widget
/// is built.
final Provider<DominoL10n> dominoL10nProvider = Provider<DominoL10n>((ref) {
  throw UnimplementedError(
    'dominoL10nProvider must be overridden with a concrete DominoL10n before use.',
  );
});
