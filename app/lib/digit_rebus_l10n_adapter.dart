import 'package:module_digit_rebus_ui/module_digit_rebus_ui.dart';

import 'l10n/app_localizations.dart';

/// Adapts the app shell's generated [AppLocalizations] to the
/// [DigitRebusL10n] interface expected by `module_digit_rebus_ui` widgets,
/// so that package can stay decoupled from this app's generated
/// localization class. Strings shared with module 01 (actions, statuses,
/// win dialog) reuse the same ARB keys; only module-02-specific wording
/// gets its own keys. Tutorial chrome strings (title/next/back/skip/done/
/// counter) are shared with module 01, while step texts are
/// module-02-specific.
class AppDigitRebusL10n implements DigitRebusL10n {
  final AppLocalizations _l10n;

  /// Creates an adapter wrapping [l10n].
  const AppDigitRebusL10n(AppLocalizations l10n) : _l10n = l10n;

  @override
  String get puzzleListTitle => _l10n.digitRebusListTitle;

  @override
  String puzzleN(int n) => _l10n.puzzleN(n);

  @override
  String get statusUntouched => _l10n.puzzleStatusUntouched;

  @override
  String get statusInProgress => _l10n.puzzleStatusInProgress;

  @override
  String get statusSolved => _l10n.puzzleStatusSolved;

  @override
  String get check => _l10n.check;

  @override
  String get reset => _l10n.reset;

  @override
  String get replay => _l10n.replay;

  @override
  String get next => _l10n.next;

  @override
  String get backToList => _l10n.backToList;

  @override
  String get resetConfirmTitle => _l10n.resetConfirmTitle;

  @override
  String get resetConfirmBody => _l10n.digitRebusResetConfirmBody;

  @override
  String get resetConfirmCancel => _l10n.resetConfirmCancel;

  @override
  String get resetConfirmOk => _l10n.resetConfirmOk;

  @override
  String get winTitle => _l10n.winTitle;

  @override
  String winTime(String formattedTime) => _l10n.winTime(formattedTime);

  @override
  String winChecks(int count) => _l10n.winChecks(count);

  @override
  String get hasErrors => _l10n.hasErrors;

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
        return _l10n.digitRebusTutorialStep1;
      case 2:
        return _l10n.digitRebusTutorialStep2;
      case 3:
        return _l10n.digitRebusTutorialStep3;
      case 4:
        return _l10n.digitRebusTutorialStep4;
      case 5:
        return _l10n.digitRebusTutorialStep5;
      case 6:
        return _l10n.digitRebusTutorialStep6;
      case 7:
        return _l10n.digitRebusTutorialStep7;
      case 8:
        return _l10n.digitRebusTutorialStep8;
      case 9:
        return _l10n.digitRebusTutorialStep9;
      default:
        throw ArgumentError.value(index, 'index', 'Must be 1..9');
    }
  }

  @override
  String get cellSemanticsEditable => _l10n.cellSemanticsEditable;
}
