import 'package:module_domino_ui/module_domino_ui.dart';

import 'l10n/app_localizations.dart';

/// Adapts the app shell's generated [AppLocalizations] to the [DominoL10n]
/// interface expected by `module_domino_ui` widgets, so that package stays
/// decoupled from this app's generated localization class. Strings shared
/// with earlier modules (statuses, reset/replay, next/back) reuse the same
/// ARB keys; module-03-specific wording gets its own keys.
class AppDominoL10n implements DominoL10n {
  final AppLocalizations _l10n;

  /// Creates an adapter wrapping [l10n].
  const AppDominoL10n(AppLocalizations l10n) : _l10n = l10n;

  @override
  String get puzzleListTitle => _l10n.dominoListTitle;

  @override
  String puzzleN(int n) => _l10n.dominoPuzzleN(n);

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
  String get resetConfirmTitle => _l10n.dominoResetConfirmTitle;

  @override
  String get resetConfirmBody => _l10n.dominoResetConfirmBody;

  @override
  String get resetConfirmCancel => _l10n.resetConfirmCancel;

  @override
  String get resetConfirmOk => _l10n.resetConfirmOk;

  @override
  String get winTitle => _l10n.dominoWinTitle;

  @override
  String get winBody => _l10n.dominoWinBody;

  @override
  String get next => _l10n.next;

  @override
  String get backToList => _l10n.backToList;

  @override
  String placedCounter(int placed) => _l10n.dominoPlacedCounter(placed);

  @override
  String get remainingLabel => _l10n.dominoRemainingLabel;

  @override
  String get duplicateWarning => _l10n.dominoDuplicateWarning;

  @override
  String get cellSemantics => _l10n.dominoCellSemantics;

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
        return _l10n.dominoTutorialStep1;
      case 2:
        return _l10n.dominoTutorialStep2;
      case 3:
        return _l10n.dominoTutorialStep3;
      case 4:
        return _l10n.dominoTutorialStep4;
      case 5:
        return _l10n.dominoTutorialStep5;
      case 6:
        return _l10n.dominoTutorialStep6;
      case 7:
        return _l10n.dominoTutorialStep7;
      case 8:
        return _l10n.dominoTutorialStep8;
      case 9:
        return _l10n.dominoTutorialStep9;
      case 10:
        return _l10n.dominoTutorialStep10;
      default:
        throw ArgumentError.value(index, 'index', 'Must be 1..10');
    }
  }
}
