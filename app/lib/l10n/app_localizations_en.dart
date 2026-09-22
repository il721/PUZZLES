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
  String get helpRulesRebus =>
      'Each puzzle is a square of four rows in the form \"a op b op c op d = result\", evaluated strictly left to right, with no operator precedence. The sum of each column\'s numbers equals that row\'s result, and the bottom row shows those four sums plus their grand total. Some digits are already filled in and cannot be changed. A puzzle is solved once every cell is filled and no rule is broken — even if your answer differs from the book\'s.';

  @override
  String get helpRulesDigitRebus =>
      'A 4×4 square in which every row and every column is an equation, evaluated strictly left to right with no operator precedence; the fourth cell holds the result. The digits are hidden behind glyphs, and each glyph admits only a few digits — the legend below the grid shows which. Tap a cell and the menu offers only the digits its glyph allows. The puzzle is solved once all eight equations hold.';

  @override
  String get helpRulesDomino =>
      'The board holds 56 cells with the digits 0 to 6. Split them into 28 dominoes so that every value-pair from 0:0 to 6:6 appears exactly once — the full set. Tap two adjacent cells to place a domino, tap a finished domino to take it back. Below the board you get the list of pairs still to build and a \"placed N of 28\" counter; if the same pair appears twice, both dominoes turn red.';

  @override
  String get helpRulesLabyrinth =>
      'An 8×8 grid of letters. Thread a single path from the top-left corner to the bottom-right one so that it passes through every letter of the alphabet exactly once. Tap a cell next to either end to extend the path; the two ends grow towards each other and the path closes when they meet. Tapping a cell that is not next to the path marks it blue — that letter must be on the path; a long press (right-click on desktop) crosses a cell out. As soon as one of several identical letters joins the path, the others are crossed out automatically.';

  @override
  String get helpRulesSquareword =>
      'The top row of the grid is the keyword, and a few letters are filled in for you. Complete the grid so that each letter of the keyword appears exactly once in every row, every column, and on both main diagonals. A letter that repeats in a row, a column or a diagonal is shown in red. The letters are always Cyrillic: each keyword is a Russian word, so there is no English alphabet to substitute.';

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
  String get labyrinthMarkedSemantics => 'marked as required on the path';

  @override
  String get labyrinthTutorialStep1 =>
      'The path starts at A — the top-left corner. Tap a neighbouring cell to extend it.';

  @override
  String get labyrinthTutorialStep2 =>
      'The other end is fixed at Z — the bottom-right corner. It grows towards the first one; when the two ends meet, the path closes.';

  @override
  String get labyrinthTutorialStep3 =>
      'Tap a cell that isn\'t next to the path to add a blue mark: that letter must be on the path — like U, which occurs only once in the labyrinth. A long press (or right-click on desktop) crosses a cell out: that letter will not join the path — one of the two Y\'s, for instance. As soon as one of several identical letters joins the path, the rest are crossed out automatically.';

  @override
  String get labyrinthTutorialStep4 =>
      'From A the path runs down to R, then turns towards Y and J.';

  @override
  String get labyrinthTutorialStep5 =>
      'Through I and # the path climbs to the top row, to D and T.';

  @override
  String get labyrinthTutorialStep6 =>
      'U occurs only once in the labyrinth, so it must be on the path. To its right lie the edge of the square and a crossed-out A, so the links run to 3 and K.';

  @override
  String get labyrinthTutorialStep7 =>
      'From K the path descends through P and E to * and @.';

  @override
  String get labyrinthTutorialStep8 =>
      'C, L, B and W carry the path left and down.';

  @override
  String get labyrinthTutorialStep9 =>
      'Through G, & and F the path reaches the right edge, at S.';

  @override
  String get labyrinthTutorialStep10 => 'H, N and \$ turn the path downwards.';

  @override
  String get labyrinthTutorialStep11 =>
      'The V in the bottom-left corner is enclosed on three sides — a dead end, so it cannot conduct. The other V, though, backs onto the bottom of the square and a crossed-out 3, so the links run to O and =.';

  @override
  String get labyrinthTutorialStep12 =>
      'The X near the left edge is a dead end, so the other X must be on the path. M, X and Z remain — the path is closed.';

  @override
  String get moduleSquarewordTitle => 'Squarewords';

  @override
  String get moduleSquarewordDescription =>
      'Fill the grid so each keyword letter appears exactly once in every row, column, and both diagonals.';

  @override
  String get squarewordListTitle => 'Squarewords';

  @override
  String squarewordPuzzleN(int n) {
    return 'Squareword $n';
  }

  @override
  String get squarewordResetConfirmTitle => 'Reset the grid?';

  @override
  String get squarewordResetConfirmBody =>
      'All entered letters will be cleared.';

  @override
  String get squarewordWinTitle => 'Grid complete!';

  @override
  String get squarewordWinBody =>
      'You filled the grid with no repeats in any row, column, or diagonal.';

  @override
  String squarewordFilledCounter(int filled, int total) {
    return 'Filled: $filled of $total';
  }

  @override
  String get squarewordViolationWarning =>
      'A letter repeats in a row, column, or diagonal — it is shown in red.';

  @override
  String get squarewordCellSemantics => 'squareword cell';

  @override
  String get squarewordTutorialStep1 =>
      'The top row is the keyword: С Л Е З А. The word ЛЕС is already filled in at the center. Same rule as always: every row, every column, and both main diagonals hold each of the five letters exactly once.';

  @override
  String get squarewordTutorialStep2 =>
      'From here on, every empty cell is forced by elimination — no guessing needed.';

  @override
  String get squarewordTutorialStep3 =>
      'Л already appears in columns b and c, so it can\'t go in b1 or c1. Cell c3 sits on both diagonals at once (the center of a 5x5 grid) and already holds Л, so Л can\'t go in a1 or e1 either. That leaves only d1.';

  @override
  String get squarewordTutorialStep4 =>
      'Column d already has З and Л. Cell d4 sits on the anti-diagonal, which already has А (at e5) — so d2 must be А, leaving С as the only letter left for d4.';

  @override
  String get squarewordTutorialStep5 =>
      'In column b, С has nowhere to go on the main diagonal (С is already at a5), the anti-diagonal (С is already at d4), or row 3 (С is already at e3). Only b1 is left.';

  @override
  String get squarewordTutorialStep6 => 'The fifth and last С goes in c2.';

  @override
  String get squarewordTutorialStep7 =>
      'In the bottom row, only c1 is left for А.';

  @override
  String get squarewordTutorialStep8 =>
      'That leaves only c4 in column c for З.';

  @override
  String get squarewordTutorialStep9 =>
      'The two remaining А\'s land in a4 and b3.';

  @override
  String get squarewordTutorialStep10 => 'In row 3, only a3 is left for З.';

  @override
  String get squarewordTutorialStep11 =>
      'Everything else is now forced: Е at b4, Л at e4, З at e1, Е at a1, Е at e2, Л at a2, З at b2.';

  @override
  String get squarewordTutorialStep12 =>
      'The grid is complete with zero violations — solved. Do the same in every puzzle: find the cells a letter is forced into, and follow the chain of eliminations.';

  @override
  String get squarewordCyrillicNote =>
      'Puzzle letters are always shown in Cyrillic — each keyword is its own Russian word, so there\'s no English alphabet to substitute.';

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

  @override
  String get modulePlaygroundTitle => 'Puzzle games';

  @override
  String get modulePlaygroundDescription =>
      'Seven small play-puzzles: chips, tiles, blocks.';

  @override
  String get helpRulesPlayground =>
      'This section isn\'t variants of one puzzle, but seven separate small games: each has its own board and its own rules, shown by the ℹ button on its screen. A puzzle counts as solved once its goal position is reached. For the move-economy puzzles, the app also records your best move count and marks it when it matches the proven minimum. Games not yet available are shown greyed out. All seven are open — \"Eight chips\", \"Cats and dogs\", \"Hourglass\", \"Three of each\", \"Patterns 5 × 5\", \"Patterns 4 × 4\" and \"Swap the squares\": in Eight chips, pieces 1–8 stand at the tips of an eight-pointed star; they can only move along straight lines (a piece may slide further through the free centre), and the goal is to arrange them in reverse order; the proven minimum is 28 moves. In Cats and dogs, three cats and three dogs swap sides of a park: each move sends one animal to an adjacent free square, and a cat and a dog must never end up next to each other; the proven minimum is 32 moves. In Hourglass, fifteen pieces must be brought from the upper triangle into the lower one: a move either steps a piece onto an adjacent free circle or jumps it over an adjacent piece, checkers-style, and several jumps in a row by one piece count as a single move; the proven minimum is 26 moves. In Three of each, nine 3×3 tiles carrying red, white and black circles must be arranged into a 9×9 square so that every row, every column and both diagonals hold exactly one circle of each colour; the tiles can be rotated but not flipped, and the move count doesn\'t matter here. In Patterns 5 × 5, twenty-five tiles drawn over with lines must be laid into a 5 × 5 square so that all the segments join into one closed line that never crosses itself; the tiles can be rotated but not flipped, and the move count does not matter here either. In Patterns 4 × 4 the same closed line has to be built from only sixteen tiles - exactly the sixteen the book\'s own answer uses. In Swap the squares, twelve identical P-shaped blocks fill a box; each move slides one block through the free space and it may turn corners, but blocks are never rotated; the goal is for the red and blue squares to swap places while every other block returns home; the proven minimum is 32 moves.';

  @override
  String get playgroundListTitle => 'Puzzle games';

  @override
  String get playgroundTitleEightChips => 'Eight chips';

  @override
  String get playgroundTitleCatsDogs => 'Cats and dogs';

  @override
  String get playgroundTitleHourglass => 'Hourglass';

  @override
  String get playgroundTitleThreeEach => 'Three of each';

  @override
  String get playgroundTitlePatterns5 => 'Patterns 5×5';

  @override
  String get playgroundTitlePatterns4 => 'Patterns 4×4';

  @override
  String get playgroundTitleSwapBlocks => 'Swap the squares';

  @override
  String get playgroundRulesEightChips =>
      'Pieces 1–8 stand at the tips of an eight-pointed star. Move a piece only along a straight line to a free spot; through the free centre it may slide further along the same line. The goal is to arrange the pieces in reverse order. The proven minimum is 28 moves.';

  @override
  String get playgroundRulesCatsDogs =>
      'Three cats (C) sit on the left-hand squares of the park, three dogs (D) on the right. Each move sends one animal along an alley to an adjacent free square. A cat and a dog must never end up on adjacent squares — such moves are simply not offered. The goal is for the cats and the dogs to swap sides. The proven minimum is 32 moves: exactly what the cats promised in the book, so they were right.';

  @override
  String get playgroundRulesHourglass =>
      'Fifteen pieces fill the upper triangle of an hourglass; all of them must be brought into the lower one. A move either steps a piece along a line onto an adjacent free circle, or jumps it, checkers-style, over an adjacent piece onto the free circle straight beyond. Several jumps in a row by one piece count as a single move, and you may stop after any of them; a step and jumps may never be mixed in one move. Movement follows the drawn lines only. The book prints no answer — the minimum proven by exhaustive search is 26 moves.';

  @override
  String get playgroundRulesThreeEach =>
      'Nine cardboard 3×3 tiles are printed with red, white and black circles. Arrange them into a 9×9 square so that each of the nine rows, each of the nine columns and both main diagonals holds exactly one circle of each colour. Empty cells don\'t count: there are 27 circles in all, exactly three per line. Tiles may be rotated a quarter turn but not flipped — the cardboard is printed on one side only. Tap a tile in the tray to select it; tap again to rotate it; then tap a free spot in the square. A tile already placed can be rotated in place or returned to the tray. The move count doesn\'t matter here — only the finished square does. Exhaustive search shows there are exactly sixteen such squares, counting rotations of the whole square.';

  @override
  String get playgroundRulesPatterns5 =>
      'Twenty-five cardboard tiles are drawn over with lines. Assemble them into a 5 × 5 square so that the segments join into one closed line that never crosses itself. The line runs through every tile, so the only thing that can go wrong is a join: a line end meeting a neighbour\'s blank edge, a line end pointing off the square, or the segments closing into several separate loops instead of one. Tiles turn in quarter turns but never flip - the cardboard is one-sided. Tap a tile in the tray to pick it up; tap it again to turn it; then tap an empty place in the square. A tile already laid can be turned in place or sent back to the tray. The number of moves does not matter here - only the finished pattern does. An exhaustive search shows there are exactly 2048 such patterns, counting turns of the whole square.';

  @override
  String get playgroundRulesPatterns4 =>
      'The same lines, but only sixteen tiles now - exactly the sixteen of the twenty-five that the book\'s own answer uses. Assemble them into a 4 × 4 square so that the segments join into one closed line that never crosses itself. The line runs through every tile, so the only thing that can go wrong is a join: a line end meeting a neighbour\'s blank edge, a line end pointing off the square, or the segments closing into several separate loops instead of one. Tiles turn in quarter turns but never flip - the cardboard is one-sided. Tap a tile in the tray to pick it up; tap it again to turn it; then tap an empty place in the square. A tile already laid can be turned in place or sent back to the tray. The number of moves does not matter here - only the finished pattern does. An exhaustive search shows there are exactly 512 such patterns, counting turns of the whole square.';

  @override
  String get playgroundRulesSwapBlocks =>
      'A 16 by 8 rectangular box holds twelve identical P-shaped blocks. Each block covers eight cells, so 96 of the 128 cells are filled and 32 stay free — four empty rows across the middle. Two red blocks at the top form a square, two blue blocks at the bottom form another. One block moves per move: it slides through the free space horizontally and vertically, any distance, and may turn corners — the whole journey counts as a single move. Blocks are never rotated and never flipped, even when the free space would allow it. The goal is for the red square and the blue square to exchange places, with every other block ending up back where it started. Tap a block to select it; dots mark every place it can travel to; press and hold a dot to see a ghost of where the block will land, and release to move it. Illegal destinations are simply never marked. The book prints no answer for this puzzle. The minimum proven by exhaustive search is 32 moves.';

  @override
  String get playgroundComingSoon => 'Coming soon';

  @override
  String playgroundMoveCounter(int moves) {
    return 'Moves: $moves';
  }

  @override
  String playgroundRecordLine(int best) {
    return 'Your best: $best moves';
  }

  @override
  String playgroundParProvenLine(int par) {
    return 'Minimum: $par moves';
  }

  @override
  String playgroundParBookLine(int par) {
    return 'Best known: $par moves';
  }

  @override
  String get playgroundOptimalBadge => '★ optimal';

  @override
  String get playgroundBookMatchedBadge => 'matches the book result';

  @override
  String get playgroundUndo => 'Undo';

  @override
  String get playgroundRules => 'Rules';

  @override
  String get playgroundClose => 'Close';

  @override
  String get playgroundRestartConfirmTitle => 'Start over?';

  @override
  String get playgroundRestartConfirmBody =>
      'All progress in this game will be reset.';

  @override
  String get playgroundWinTitle => 'Solved!';

  @override
  String playgroundWinBody(int moves) {
    return 'You solved it in $moves moves.';
  }

  @override
  String get playgroundWinBodyOptimal =>
      'You solved it in the minimum number of moves!';

  @override
  String get playgroundShowSolution => 'Show solution';

  @override
  String get playgroundRotateTile => 'Rotate';

  @override
  String get playgroundReturnTileToTray => 'Return to tray';
}
