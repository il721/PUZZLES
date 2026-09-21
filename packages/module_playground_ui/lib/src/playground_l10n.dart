import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Localized strings needed by the playground module's list/game-chrome
/// widgets.
///
/// Unlike a per-puzzle-content module (e.g. `SquarewordL10n`), there is no
/// per-puzzle text to localize: each of the seven games is a fixed rule set
/// keyed by its stable [String] game id (one of `eight_chips`, `cats_dogs`,
/// `hourglass`, `three_each`, `patterns5`, `patterns4`, `swap_blocks`), so
/// [gameTitle] and [gameRules] take that id directly rather than an index.
abstract class PlaygroundL10n {
  /// Title for the game list screen.
  String get listTitle;

  /// Display title for the game identified by [gameId].
  String gameTitle(String gameId);

  /// Body text of the game's rules (ℹ) bottom sheet.
  String gameRules(String gameId);

  /// Trailing label shown on a disabled (not-yet-shipped) row.
  String get comingSoon;

  /// Semantic/status label for a never-opened game.
  String get statusUntouched;

  /// Semantic/status label for a game with saved progress but not yet
  /// solved.
  String get statusInProgress;

  /// Semantic/status label for a solved game.
  String get statusSolved;

  /// Move counter shown in the game footer, e.g. "Ходов: 12".
  String moveCounter(int moves);

  /// Best-recorded-moves line, e.g. "Ваш рекорд: 24 хода".
  String recordLine(int best);

  /// Line shown for a solver-proven par, e.g. "Минимум: 28 ходов".
  String parProvenLine(int par);

  /// Line shown for a book-claimed (not independently verified) par, e.g.
  /// "Лучшее известное: 28 ходов".
  String parBookLine(int par);

  /// Badge shown when the player's best matches a solver-proven par.
  String get optimalBadge;

  /// Badge shown when the player's best matches a book-claimed (unproven)
  /// par.
  String get bookMatchedBadge;

  /// Label for the "Undo" action.
  String get undo;

  /// Label for the "Restart" action.
  String get restart;

  /// Label for the "Rules" (info) action.
  String get rules;

  /// Label for the "Close" action.
  String get close;

  /// Title of the restart confirmation dialog.
  String get restartConfirmTitle;

  /// Body text of the restart confirmation dialog.
  String get restartConfirmBody;

  /// Cancel button of the restart confirmation dialog.
  String get restartConfirmCancel;

  /// Confirm button of the restart confirmation dialog.
  String get restartConfirmOk;

  /// Title of the win dialog.
  String get winTitle;

  /// Win dialog body for a non-optimal solve, given the move count.
  String winBody(int moves);

  /// Win dialog body shown instead of [winBody] when the completed solve
  /// matched (or beat) the game's par.
  String get winBodyOptimal;

  /// Label for the "Back to list" action.
  String get backToList;

  /// Label for the "Show solution" action, unlocked only after the game has
  /// been solved at least once.
  String get showSolution;

  /// Tooltip for the rotate-tile action button in tile-placement games.
  String get rotateTile;

  /// Tooltip for the return-tile-to-tray action button in tile-placement
  /// games.
  String get returnTileToTray;
}

/// Supplies the [PlaygroundL10n] implementation for the current app locale.
/// Must be overridden by the app shell before any module_playground_ui
/// widget is built.
final Provider<PlaygroundL10n> playgroundL10nProvider = Provider<PlaygroundL10n>((ref) {
  throw UnimplementedError(
    'playgroundL10nProvider must be overridden with a concrete PlaygroundL10n before use.',
  );
});
