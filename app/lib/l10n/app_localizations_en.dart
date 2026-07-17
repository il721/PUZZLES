// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Puzzle Book';

  @override
  String get moduleRebusTitle => 'Square Rebuses';

  @override
  String get moduleRebusDescription =>
      'Arithmetic rebuses: fill in the boxes so every equation checks out.';

  @override
  String homeModuleProgress(int solved, int total) {
    return 'Solved: $solved of $total';
  }

  @override
  String get homeSettingsTooltip => 'Settings';

  @override
  String get homeHelpTooltip => 'Help';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageEn => 'English';

  @override
  String get languageDe => 'Deutsch';

  @override
  String get settingsSound => 'Sound';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpBody =>
      'Each puzzle is a square of four rows in the form \"a op b op c op d = result\", evaluated strictly left to right, with no operator precedence. The sum of each column\'s numbers equals that row\'s result, and the bottom row shows those four sums plus their grand total. Some digits are already filled in and cannot be changed. A puzzle is solved once every cell is filled and no rule is broken — even if your answer differs from the book\'s.';

  @override
  String get puzzleListTitle => 'Rebuses';

  @override
  String puzzleN(int n) {
    return 'Puzzle $n';
  }

  @override
  String get puzzleStatusUntouched => 'Not started';

  @override
  String get puzzleStatusInProgress => 'In progress';

  @override
  String get puzzleStatusSolved => 'Solved';

  @override
  String get check => 'Check';

  @override
  String get reset => 'Reset';

  @override
  String get replay => 'Replay';

  @override
  String get next => 'Next puzzle';

  @override
  String get backToList => 'Back to list';

  @override
  String get resetConfirmTitle => 'Reset this puzzle?';

  @override
  String get resetConfirmBody =>
      'Every digit you\'ve entered will be cleared. Given digits stay in place.';

  @override
  String get resetConfirmCancel => 'Cancel';

  @override
  String get resetConfirmOk => 'Reset';

  @override
  String get winTitle => 'Puzzle solved!';

  @override
  String winTime(String time) {
    return 'Time: $time';
  }

  @override
  String winChecks(int count) {
    return 'Checks: $count';
  }

  @override
  String get hasErrors =>
      'The grid is full, but something doesn\'t add up. Check the highlighted cells.';

  @override
  String get tutorialComingSoon =>
      'The guided tutorial is coming in a future update.';
}
