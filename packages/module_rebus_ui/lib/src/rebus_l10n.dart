import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Localized strings needed by the rebus module's widgets.
///
/// This package cannot depend on the app shell's generated
/// `AppLocalizations` (that would be a circular dependency — the app shell
/// depends on this package, not the other way around). Instead, the app
/// shell supplies a concrete implementation of this interface, backed by
/// its own generated localizations, via an override of [rebusL10nProvider].
abstract class RebusL10n {
  /// Title for the puzzle list screen.
  String get puzzleListTitle;

  /// Title for puzzle number [n], e.g. "Puzzle 3".
  String puzzleN(int n);

  /// Semantic label for an untouched (never opened) puzzle.
  String get statusUntouched;

  /// Semantic label for a puzzle with saved progress but not yet solved.
  String get statusInProgress;

  /// Semantic label for a solved puzzle.
  String get statusSolved;

  /// Label for the "Check" action.
  String get check;

  /// Label for the "Reset" action.
  String get reset;

  /// Label for the "Replay" action.
  String get replay;

  /// Label for the "Next puzzle" action.
  String get next;

  /// Label for the "Back to list" action.
  String get backToList;

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

  /// Elapsed-time line of the win dialog, given a formatted `mm:ss` string.
  String winTime(String formattedTime);

  /// Check-count line of the win dialog.
  String winChecks(int count);

  /// Banner text shown when the grid is complete but violates a rule.
  String get hasErrors;
}

/// Supplies the [RebusL10n] implementation for the current app locale. Must
/// be overridden by the app shell (typically in a nested `ProviderScope`
/// that has access to `BuildContext`-based localizations) before any
/// module_rebus_ui widget is built.
final Provider<RebusL10n> rebusL10nProvider = Provider<RebusL10n>((ref) {
  throw UnimplementedError(
    'rebusL10nProvider must be overridden with a concrete RebusL10n before use.',
  );
});
