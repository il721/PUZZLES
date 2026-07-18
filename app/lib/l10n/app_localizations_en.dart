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
  String get moduleDigitRebusTitle => 'Digit Rebuses';

  @override
  String get moduleDigitRebusDescription =>
      'Every row and every column is an equation: place digits following the glyph hints.';

  @override
  String get digitRebusListTitle => 'Digit Rebuses';

  @override
  String get digitRebusResetConfirmBody =>
      'All entered digits will be removed.';

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
  String get settingsTheme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

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
  String get cellSemanticsGiven => 'given digit';

  @override
  String get cellSemanticsEditable => 'editable digit';

  @override
  String get tutorialComingSoon =>
      'The guided tutorial is coming in a future update.';

  @override
  String get tutorialTitle => 'How to solve';

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialBack => 'Back';

  @override
  String get tutorialSkip => 'Skip';

  @override
  String get tutorialDone => 'Done';

  @override
  String tutorialStepCounter(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get tutorialStep1 =>
      'Each square holds exactly one digit. No number equals zero, and no number starts with zero (though numbers may end with zero).';

  @override
  String get tutorialStep2 =>
      'Operations in a row are performed strictly in order, left to right — as if each row were fully bracketed.';

  @override
  String get tutorialStep3 =>
      'The numbers in each vertical column add up to the result of the corresponding row. The fifth row holds these sums and the grand total.';

  @override
  String get tutorialStep4 =>
      'The result of row 1 starts with 3 — it is also the first number of the fifth row. And the second number of the fifth row ends in 6, so the result of row 2 ends in 6 too.';

  @override
  String get tutorialStep5 =>
      'Row 2: the sum of two single-digit numbers is at most 18, so the third number starts with 1 — it is 16. The sum of the first two numbers is 17 or 18.';

  @override
  String get tutorialStep6 =>
      'If the sum were 17, then (17 − 16) × 8 would be a single-digit number, but the result has two squares. Contradiction.';

  @override
  String get tutorialStep7 =>
      'So the sum is 18: the first number is 9 and the second is 9. Then (18 − 16) × 8 = 16: the fourth number is 8, and the row\'s result 16 is also the second number of the fifth row.';

  @override
  String get tutorialStep8 =>
      'Second vertical column: 2 + 9 already make 11 of 16. That leaves 5 for the third and fourth numbers — each is less than 5.';

  @override
  String get tutorialStep9 =>
      'Analysis of row 3 allows only 3 or 8 for its second number. Less than 5 — so it is 3. Then the second number of row 4 is 2.';

  @override
  String get tutorialStep10 =>
      'The result of row 1 starts with 3 and is divisible by 5 — it is 30 or 35. The same holds for the first number of the fifth row.';

  @override
  String get tutorialStep11 =>
      'The first number of row 3 ends in 7: 17, 27, 37… Already at 27 the first column\'s sum would exceed 35. So it is 17 — and row 3 reads 17 + 3 : 5 × 8 = 32.';

  @override
  String get tutorialStep12 =>
      'Suppose the result of row 1 were 35. Then (first number + 2) × third = 7, and the third vertical column would leave 32 − 1 − 16 − 5 = 10 for the fourth, single-digit number. Contradiction — so it is 30.';

  @override
  String get tutorialStep13 => 'Row 1: 1 + 2 × 2 × 5 = 30, left to right.';

  @override
  String get tutorialStep14 =>
      'The first and second columns now pin down row 4: 3 + 2 × 9 − 12 = 33.';

  @override
  String get tutorialStep15 =>
      'Check the total: 30 + 16 + 32 + 33 = 111. The rebus is solved!';
}
