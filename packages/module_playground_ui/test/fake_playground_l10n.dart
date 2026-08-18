import 'package:module_playground_ui/module_playground_ui.dart';

/// ASCII test double for [PlaygroundL10n], shared by every widget test in
/// this package.
class FakePlaygroundL10n implements PlaygroundL10n {
  const FakePlaygroundL10n();

  @override
  String get listTitle => 'Games';
  @override
  String gameTitle(String gameId) => 'Game $gameId';
  @override
  String gameRules(String gameId) => 'Rules for $gameId';
  @override
  String get comingSoon => 'Coming soon';
  @override
  String get statusUntouched => 'Untouched';
  @override
  String get statusInProgress => 'In progress';
  @override
  String get statusSolved => 'Solved';
  @override
  String moveCounter(int moves) => 'Moves: $moves';
  @override
  String recordLine(int best) => 'Best: $best';
  @override
  String parProvenLine(int par) => 'Par (proven): $par';
  @override
  String parBookLine(int par) => 'Par (book): $par';
  @override
  String get optimalBadge => 'Optimal';
  @override
  String get bookMatchedBadge => 'Book match';
  @override
  String get undo => 'Undo';
  @override
  String get restart => 'Restart';
  @override
  String get rules => 'Rules';
  @override
  String get close => 'Close';
  @override
  String get restartConfirmTitle => 'Restart?';
  @override
  String get restartConfirmBody => 'Are you sure?';
  @override
  String get restartConfirmCancel => 'Cancel';
  @override
  String get restartConfirmOk => 'OK';
  @override
  String get winTitle => 'You win!';
  @override
  String winBody(int moves) => 'Solved in $moves moves.';
  @override
  String get winBodyOptimal => 'Optimal solve!';
  @override
  String get backToList => 'Back to list';
  @override
  String get showSolution => 'Show solution';
}
