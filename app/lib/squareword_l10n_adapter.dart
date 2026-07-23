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

  @override
  String get tutorialTitle => _l10n.tutorialTitle;

  @override
  String get tutorialNext => _l10n.tutorialNext;

  @override
  String get tutorialBack => _l10n.tutorialBack;

  @override
  String get tutorialSkip => _l10n.tutorialSkip;

  @override
  String get tutorialDone => _l10n.tutorialDone;

  @override
  String tutorialStepCounter(int current, int total) => _l10n.tutorialStepCounter(current, total);

  @override
  String tutorialStepText(int index) {
    switch (index) {
      case 1:
        return _l10n.squarewordTutorialStep1;
      case 2:
        return _l10n.squarewordTutorialStep2;
      case 3:
        return _l10n.squarewordTutorialStep3;
      case 4:
        return _l10n.squarewordTutorialStep4;
      case 5:
        return _l10n.squarewordTutorialStep5;
      case 6:
        return _l10n.squarewordTutorialStep6;
      case 7:
        return _l10n.squarewordTutorialStep7;
      case 8:
        return _l10n.squarewordTutorialStep8;
      case 9:
        return _l10n.squarewordTutorialStep9;
      case 10:
        return _l10n.squarewordTutorialStep10;
      case 11:
        return _l10n.squarewordTutorialStep11;
      case 12:
        return _l10n.squarewordTutorialStep12;
      default:
        throw ArgumentError.value(index, 'index', 'Must be 1..12');
    }
  }

  @override
  String get cyrillicNote => _l10n.squarewordCyrillicNote;
}
