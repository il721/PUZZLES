import 'package:module_labyrinth/module_labyrinth.dart' show letterGlyphs;
import 'package:module_labyrinth_ui/module_labyrinth_ui.dart';

import 'l10n/app_localizations.dart';

/// Adapts the app shell's generated [AppLocalizations] to the [LabyrinthL10n]
/// interface expected by `module_labyrinth_ui` widgets, so that package
/// stays decoupled from this app's generated localization class.
class AppLabyrinthL10n implements LabyrinthL10n {
  final AppLocalizations _l10n;

  /// Creates an adapter wrapping [l10n].
  const AppLabyrinthL10n(AppLocalizations l10n) : _l10n = l10n;

  @override
  String glyphFor(String canonicalLetter) {
    if (_l10n.localeName == 'ru') return canonicalLetter;
    return letterGlyphs[canonicalLetter] ?? canonicalLetter;
  }

  @override
  String get puzzleListTitle => _l10n.labyrinthListTitle;

  @override
  String puzzleN(int n) => _l10n.labyrinthPuzzleN(n);

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
  String get resetConfirmTitle => _l10n.labyrinthResetConfirmTitle;

  @override
  String get resetConfirmBody => _l10n.labyrinthResetConfirmBody;

  @override
  String get resetConfirmCancel => _l10n.resetConfirmCancel;

  @override
  String get resetConfirmOk => _l10n.resetConfirmOk;

  @override
  String get winTitle => _l10n.labyrinthWinTitle;

  @override
  String get winBody => _l10n.labyrinthWinBody;

  @override
  String get next => _l10n.next;

  @override
  String get backToList => _l10n.backToList;

  @override
  String placedCounter(int placed) => _l10n.labyrinthPlacedCounter(placed);

  @override
  String get alphabetLabel => _l10n.labyrinthAlphabetLabel;

  @override
  String get duplicateWarning => _l10n.labyrinthDuplicateWarning;

  @override
  String get cellSemantics => _l10n.labyrinthCellSemantics;

  @override
  String get markedSemantics => _l10n.labyrinthMarkedSemantics;

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
        return _l10n.labyrinthTutorialStep1;
      case 2:
        return _l10n.labyrinthTutorialStep2;
      case 3:
        return _l10n.labyrinthTutorialStep3;
      case 4:
        return _l10n.labyrinthTutorialStep4;
      case 5:
        return _l10n.labyrinthTutorialStep5;
      case 6:
        return _l10n.labyrinthTutorialStep6;
      case 7:
        return _l10n.labyrinthTutorialStep7;
      case 8:
        return _l10n.labyrinthTutorialStep8;
      case 9:
        return _l10n.labyrinthTutorialStep9;
      case 10:
        return _l10n.labyrinthTutorialStep10;
      case 11:
        return _l10n.labyrinthTutorialStep11;
      case 12:
        return _l10n.labyrinthTutorialStep12;
      default:
        throw ArgumentError.value(index, 'index', 'Must be 1..12');
    }
  }
}
