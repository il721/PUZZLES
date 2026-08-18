import 'package:module_playground_ui/module_playground_ui.dart';

import 'l10n/app_localizations.dart';

/// Adapts the app shell's generated [AppLocalizations] to the
/// [PlaygroundL10n] interface expected by `module_playground_ui` widgets, so
/// that package stays decoupled from this app's generated localization
/// class. Strings shared with earlier modules (statuses, reset/back-to-list)
/// reuse the same ARB keys; module-06-specific wording gets its own keys.
class AppPlaygroundL10n implements PlaygroundL10n {
  final AppLocalizations _l10n;

  /// Creates an adapter wrapping [l10n].
  const AppPlaygroundL10n(AppLocalizations l10n) : _l10n = l10n;

  @override
  String get listTitle => _l10n.playgroundListTitle;

  @override
  String gameTitle(String gameId) {
    switch (gameId) {
      case 'eight_chips':
        return _l10n.playgroundTitleEightChips;
      case 'cats_dogs':
        return _l10n.playgroundTitleCatsDogs;
      case 'hourglass':
        return _l10n.playgroundTitleHourglass;
      case 'three_each':
        return _l10n.playgroundTitleThreeEach;
      case 'patterns5':
        return _l10n.playgroundTitlePatterns5;
      case 'patterns4':
        return _l10n.playgroundTitlePatterns4;
      case 'swap_blocks':
        return _l10n.playgroundTitleSwapBlocks;
      default:
        return gameId;
    }
  }

  @override
  String gameRules(String gameId) {
    switch (gameId) {
      case 'eight_chips':
        return _l10n.playgroundRulesEightChips;
      default:
        // The other six games are greyed out and unreachable; their rules
        // keys arrive in their own milestones.
        return '';
    }
  }

  @override
  String get comingSoon => _l10n.playgroundComingSoon;

  @override
  String get statusUntouched => _l10n.puzzleStatusUntouched;

  @override
  String get statusInProgress => _l10n.puzzleStatusInProgress;

  @override
  String get statusSolved => _l10n.puzzleStatusSolved;

  @override
  String moveCounter(int moves) => _l10n.playgroundMoveCounter(moves);

  @override
  String recordLine(int best) => _l10n.playgroundRecordLine(best);

  @override
  String parProvenLine(int par) => _l10n.playgroundParProvenLine(par);

  @override
  String parBookLine(int par) => _l10n.playgroundParBookLine(par);

  @override
  String get optimalBadge => _l10n.playgroundOptimalBadge;

  @override
  String get bookMatchedBadge => _l10n.playgroundBookMatchedBadge;

  @override
  String get undo => _l10n.playgroundUndo;

  @override
  String get restart => _l10n.reset;

  @override
  String get rules => _l10n.playgroundRules;

  @override
  String get close => _l10n.playgroundClose;

  @override
  String get restartConfirmTitle => _l10n.playgroundRestartConfirmTitle;

  @override
  String get restartConfirmBody => _l10n.playgroundRestartConfirmBody;

  @override
  String get restartConfirmCancel => _l10n.resetConfirmCancel;

  @override
  String get restartConfirmOk => _l10n.resetConfirmOk;

  @override
  String get winTitle => _l10n.playgroundWinTitle;

  @override
  String winBody(int moves) => _l10n.playgroundWinBody(moves);

  @override
  String get winBodyOptimal => _l10n.playgroundWinBodyOptimal;

  @override
  String get backToList => _l10n.backToList;

  @override
  String get showSolution => _l10n.playgroundShowSolution;
}
