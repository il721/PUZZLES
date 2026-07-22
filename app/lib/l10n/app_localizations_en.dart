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
  String get digitRebusTutorialStep1 =>
      'This is a 4×4 square: every row and every column is an equation, solved strictly left to right (top to bottom), with no operator precedence. The fourth cell is the result.';

  @override
  String get digitRebusTutorialStep2 =>
      'The digits are hidden behind glyphs. Each glyph admits only a few digits — the legend below the grid always shows which: a loop on top, for example, means 0, 8 or 9.';

  @override
  String get digitRebusTutorialStep3 =>
      'Start with row 2: (a + b) × c. The result is a single digit and the multiplier is at least 3, so a + b is at most 3: only a = 1 and b = 2 fit.';

  @override
  String get digitRebusTutorialStep4 =>
      'Then 1 + 2 = 3 and 3 × 3 = 9 — row 2 reads 1 + 2 × 3 = 9.';

  @override
  String get digitRebusTutorialStep5 =>
      'Column 1: (a − 1) × c. The multiplier is again at least 3, so a − 1 = 3, meaning a = 4 — and 3 × 3 = 9: the column reads 4 − 1 × 3 = 9.';

  @override
  String get digitRebusTutorialStep6 =>
      'Row 3: 3 + b + c. Of the admitted digits only 3 + 2 + 1 = 6 works.';

  @override
  String get digitRebusTutorialStep7 =>
      'Column 3: a − 3 − 1. Of 0, 6 and 8 only 6 works: 6 − 3 − 1 = 2.';

  @override
  String get digitRebusTutorialStep8 =>
      'The remaining cells follow from their rows: 4 + 8 : 6 = 2 and 9 − 3 : 2 = 3. All eight equations hold.';

  @override
  String get digitRebusTutorialStep9 =>
      'Done! In the puzzles, tap a cell — the menu shows only the digits its glyph admits. Any filling where all eight equations hold wins.';

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

  @override
  String get moduleDominoTitle => 'Domino Solitaire';

  @override
  String get moduleDominoDescription =>
      'Rebuild the 28 dominoes hidden in a grid of digits — the full 0:0 to 6:6 set.';

  @override
  String get dominoListTitle => 'Domino Solitaire';

  @override
  String dominoPuzzleN(int n) {
    return 'Domino $n';
  }

  @override
  String get dominoResetConfirmTitle => 'Reset domino?';

  @override
  String get dominoResetConfirmBody => 'All placed dominoes will be removed.';

  @override
  String get dominoWinTitle => 'Domino complete!';

  @override
  String get dominoWinBody =>
      'You rebuilt the full domino set. All 28 tiles are in place.';

  @override
  String dominoPlacedCounter(int placed) {
    return 'Placed: $placed of 28';
  }

  @override
  String get dominoRemainingLabel => 'Still to place:';

  @override
  String get dominoDuplicateWarning =>
      'Some dominoes are duplicated — shown in red.';

  @override
  String get dominoCellSemantics => 'domino cell';

  @override
  String get dominoTutorialStep1 =>
      'Domino solitaire: 56 cells hold digits 0 to 6. Split them into 28 dominoes so you build the full set — every value-pair from 0:0 to 6:6 exactly once. To place a domino, tap two adjacent cells; to remove one, tap the finished domino.';

  @override
  String get dominoTutorialStep2 =>
      'Below the board: the list of pairs not yet built and a \"placed N of 28\" counter. If the same pair appears twice, both dominoes turn red — the solitaire won\'t come out until the duplicate is gone.';

  @override
  String get dominoTutorialStep3 =>
      'Look for cells whose neighbouring partner is forced. That fixes the first three dominoes: 0:1, 2:4 and 5:6 (highlighted).';

  @override
  String get dominoTutorialStep4 =>
      'Next, two doubles: 5:5 and 3:3. A double covers two equal cells side by side, and each double appears only once.';

  @override
  String get dominoTutorialStep5 =>
      'Continue in the lower left: 2:3 and 0:3 are forced, freeing their neighbours.';

  @override
  String get dominoTutorialStep6 =>
      'The next four: 0:4, 4:4, 3:4 and 4:5. The fours are almost used up — watch the list below.';

  @override
  String get dominoTutorialStep7 =>
      'Now the pairs with a one: 1:4, 1:6 and 1:3.';

  @override
  String get dominoTutorialStep8 =>
      'Four more: 3:5, 1:5, 1:2 and 2:5. Check the counter — over halfway now.';

  @override
  String get dominoTutorialStep9 =>
      'The upper part of the board: 2:6, 0:5, 0:6, 0:2 and 2:2.';

  @override
  String get dominoTutorialStep10 =>
      'The last five close the set: 0:0, 1:1, 6:6, 3:6 and 4:6. All 28 pairs are placed — the solitaire is out! In every puzzle, do the same: find the forced dominoes and watch the remaining-pairs list.';

  @override
  String get moduleLabyrinthTitle => 'Alphabet Labyrinth';

  @override
  String get moduleLabyrinthDescription =>
      'Thread a single path across the 8×8 grid from the top-left corner to the bottom-right, using each letter of the alphabet exactly once.';

  @override
  String get labyrinthListTitle => 'Alphabet Labyrinth';

  @override
  String labyrinthPuzzleN(int n) {
    return 'Labyrinth $n';
  }

  @override
  String get labyrinthResetConfirmTitle => 'Reset the path?';

  @override
  String get labyrinthResetConfirmBody =>
      'The whole drawn path will be cleared.';

  @override
  String get labyrinthWinTitle => 'Path complete!';

  @override
  String get labyrinthWinBody =>
      'You threaded a path through all 33 letters of the alphabet.';

  @override
  String labyrinthPlacedCounter(int placed) {
    return 'Letters: $placed of 33';
  }

  @override
  String get labyrinthAlphabetLabel => 'Alphabet';

  @override
  String get labyrinthDuplicateWarning =>
      'One letter appears twice on the path — it is shown in red.';

  @override
  String get labyrinthCellSemantics => 'labyrinth cell';

  @override
  String get settingsSyncSection => 'Transfer progress';

  @override
  String get settingsSyncHint =>
      'Save your progress to a file and open it on another device.';

  @override
  String get settingsExportProgress => 'Save progress to a file';

  @override
  String get settingsImportProgress => 'Load progress from a file';

  @override
  String get exportSuccess => 'Progress saved.';

  @override
  String get exportFailed => 'Could not save the file.';

  @override
  String get importConfirmTitle => 'Load progress?';

  @override
  String importConfirmBody(String date) {
    return 'File created: $date. Your current progress will not be lost — your best results are kept.';
  }

  @override
  String get importConfirmApply => 'Load';

  @override
  String get importConfirmCancel => 'Cancel';

  @override
  String importSuccess(int added, int updated) {
    return 'Puzzles added: $added, updated: $updated.';
  }

  @override
  String get importNothingNew => 'No new results found.';

  @override
  String get importFailedFormat => 'That is not a progress file.';

  @override
  String get importFailedVersion =>
      'This file was made by a newer version of the app. Please update.';
}
