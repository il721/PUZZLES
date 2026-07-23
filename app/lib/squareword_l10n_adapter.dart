import 'package:module_squareword_ui/module_squareword_ui.dart';

import 'l10n/app_localizations.dart';

/// Adapts the app shell's generated [AppLocalizations] to the
/// [SquarewordL10n] interface expected by `module_squareword_ui` widgets,
/// so that package stays decoupled from this app's generated localization
/// class.
class AppSquarewordL10n implements SquarewordL10n {
  final AppLocalizations _l10n;

  /// Creates an adapter wrapping [l10n].
  const AppSquarewordL10n(AppLocalizations l10n) : _l10n = l10n;

  @override
  String get puzzleListTitle => _l10n.squarewordListTitle;

  @override
  String puzzleN(int n) => _l10n.squarewordPuzzleN(n);

  @override
  String get statusUntouched => _l10n.puzzleStatusUntouched;

  @override
  String get statusInProgress => _l10n.puzzleStatusInProgress;

  @override
  String get statusSolved => _l10n.puzzleStatusSolved;

  @override
  String get reset => _l10n.reset;

  @override
  String get replay => _l10n.replay;

  @override
  String get resetConfirmTitle => _l10n.squarewordResetConfirmTitle;

  @override
  String get resetConfirmBody => _l10n.squarewordResetConfirmBody;

  @override
  String get resetConfirmCancel => _l10n.resetConfirmCancel;

  @override
  String get resetConfirmOk => _l10n.resetConfirmOk;

  @override
  String get winTitle => _l10n.squarewordWinTitle;

  @override
  String get winBody => _l10n.squarewordWinBody;

  @override
  String get next => _l10n.next;

  @override
  String get backToList => _l10n.backToList;

  @override
  String filledCounter(int filled, int total) => _l10n.squarewordFilledCounter(filled, total);

  @override
  String get violationWarning => _l10n.squarewordViolationWarning;

  @override
  String get cellSemantics => _l10n.squarewordCellSemantics;
}
