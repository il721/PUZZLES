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
}
