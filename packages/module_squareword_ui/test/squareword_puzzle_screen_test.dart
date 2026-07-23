import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_squareword/module_squareword.dart';
import 'package:module_squareword_ui/module_squareword_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

class _FakeSquarewordL10n implements SquarewordL10n {
  const _FakeSquarewordL10n();
  @override
  String get puzzleListTitle => 'Squareword';
  @override
  String puzzleN(int n) => 'Squareword $n';
  @override
  String get statusUntouched => 'Untouched';
  @override
  String get statusInProgress => 'In progress';
  @override
  String get statusSolved => 'Solved';
  @override
  String get reset => 'Reset';
  @override
  String get replay => 'Replay';
  @override
  String get resetConfirmTitle => 'Reset?';
  @override
  String get resetConfirmBody => 'Sure?';
  @override
  String get resetConfirmCancel => 'Cancel';
  @override
  String get resetConfirmOk => 'OK';
  @override
  String get winTitle => 'You win!';
  @override
  String get winBody => 'Done.';
  @override
  String get next => 'Next';
  @override
  String get backToList => 'Back';
  @override
  String filledCounter(int filled, int total) => 'Filled: $filled of $total';
  @override
  String get violationWarning => 'Duplicates!';
  @override
  String get cellSemantics => 'squareword cell';
}

List<SquarewordPuzzle> _loadPuzzles() {
  final file = File('../module_squareword/assets/puzzles/module05.json');
  return SquarewordPuzzle.listFromJsonString(file.readAsStringSync());
}

Widget _wrap({
  required SaveService saveService,
  required List<SquarewordPuzzle> puzzles,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      squarewordPuzzlesProvider.overrideWith((ref) async => puzzles),
      squarewordSaveServiceProvider.overrideWithValue(saveService),
      squarewordL10nProvider.overrideWithValue(const _FakeSquarewordL10n()),
    ],
    child: MaterialApp(home: child),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Finder _cell(int r, int c) => find.byKey(ValueKey('cell_${r}_$c'));

void main() {
  late List<SquarewordPuzzle> puzzles;
  late Directory tempDir;
  late SaveService saveService;
  late SquarewordPuzzle p01;

  setUpAll(() {
    puzzles = _loadPuzzles();
    p01 = puzzles.firstWhere((p) => p.id == 'p01');
  });

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    tempDir = Directory.systemTemp.createTempSync('module_squareword_ui_screen_test_');
    saveService = SaveService(() => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('tapping an editable cell opens the letter picker and placing a letter fills it',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        saveService: saveService,
        puzzles: puzzles,
        child: const SquarewordPuzzleScreen(puzzleId: 'p01'),
      ),
    );
    await _settle(tester);

    // Row 0 is entirely given; (1,0) is editable in every puzzle shape.
    expect(find.text(p01.givens.first.letter), findsWidgets);

    await tester.tap(_cell(1, 0));
    await _settle(tester);

    // The letter picker popup is now open, offering every keyword letter.
    final firstLetter = p01.letters.first;
    expect(find.byKey(ValueKey('letterOption_$firstLetter')), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('letterOption_$firstLetter')));
    await _settle(tester);

    // The popup is closed and the counter reflects the new placement:
    // n*n givens-plus-one, since only (1,0) among editable cells was filled.
    final givenCount = p01.givens.length;
    expect(find.text('Filled: ${givenCount + 1} of ${p01.n * p01.n}'), findsOneWidget);
  });

  testWidgets('long-pressing a filled editable cell clears it', (tester) async {
    await tester.pumpWidget(
      _wrap(
        saveService: saveService,
        puzzles: puzzles,
        child: const SquarewordPuzzleScreen(puzzleId: 'p01'),
      ),
    );
    await _settle(tester);

    await tester.tap(_cell(1, 0));
    await _settle(tester);
    final firstLetter = p01.letters.first;
    await tester.tap(find.byKey(ValueKey('letterOption_$firstLetter')));
    await _settle(tester);

    final givenCount = p01.givens.length;
    expect(find.text('Filled: ${givenCount + 1} of ${p01.n * p01.n}'), findsOneWidget);

    await tester.longPress(_cell(1, 0));
    await _settle(tester);

    expect(find.text('Filled: $givenCount of ${p01.n * p01.n}'), findsOneWidget);
  });

  testWidgets('placing a duplicate letter in the same row shows the violation highlight',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        saveService: saveService,
        puzzles: puzzles,
        child: const SquarewordPuzzleScreen(puzzleId: 'p01'),
      ),
    );
    await _settle(tester);

    // Simplest reliable violation: place the SAME letter into two editable
    // cells that share only a row (Cell(1, 0) and Cell(1, n-1) — neither is
    // on a diagonal for n=5, and row 1 is never given in module05.json).
    // The letter itself must not already sit in column 0 or column (n-1)
    // via a given, or the very first placement would trip a COLUMN
    // violation instead of the intended row-only one.
    final n = p01.n;
    final blockedByColumn =
        p01.givens.where((g) => g.col == 0 || g.col == n - 1).map((g) => g.letter).toSet();
    final letter = p01.letters.firstWhere((l) => !blockedByColumn.contains(l));

    await tester.tap(_cell(1, 0));
    await _settle(tester);
    await tester.tap(find.byKey(ValueKey('letterOption_$letter')));
    await _settle(tester);

    expect(find.text('Duplicates!'), findsNothing);

    await tester.tap(_cell(1, p01.n - 1));
    await _settle(tester);
    await tester.tap(find.byKey(ValueKey('letterOption_$letter')));
    await _settle(tester);

    expect(find.text('Duplicates!'), findsOneWidget);
  });

  testWidgets('puzzle list screen renders a tile per playable puzzle, no tutorial tile',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        saveService: saveService,
        puzzles: puzzles,
        child: const SquarewordPuzzleListScreen(),
      ),
    );
    await _settle(tester);

    expect(find.text('Squareword'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    final playableCount = puzzles.where((p) => !p.tutorial).length;
    expect(find.text('$playableCount'), findsOneWidget);
  });

  testWidgets('filling the board with the solver-verified solution triggers the win dialog',
      (tester) async {
    final solveResult = solveSquareword(p01);
    expect(solveResult.solution, isNotNull, reason: 'p01 must have a solver-verified solution');
    final solution = solveResult.solution!;

    await tester.pumpWidget(
      _wrap(
        saveService: saveService,
        puzzles: puzzles,
        child: const SquarewordPuzzleScreen(puzzleId: 'p01'),
      ),
    );
    await _settle(tester);

    final givenCells = p01.givens.map((g) => Cell(g.row, g.col)).toSet();
    for (var r = 0; r < p01.n; r++) {
      for (var c = 0; c < p01.n; c++) {
        if (givenCells.contains(Cell(r, c))) continue;
        await tester.tap(_cell(r, c));
        await _settle(tester);
        final letter = solution[r][c];
        await tester.tap(find.byKey(ValueKey('letterOption_$letter')));
        await _settle(tester);
      }
    }

    expect(find.text('You win!'), findsOneWidget);
  });
}
