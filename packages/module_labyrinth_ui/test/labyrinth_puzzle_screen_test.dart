import 'dart:io';

import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_labyrinth/module_labyrinth.dart';
import 'package:module_labyrinth_ui/module_labyrinth_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

class _FakeLabyrinthL10n implements LabyrinthL10n {
  const _FakeLabyrinthL10n();
  @override
  String glyphFor(String canonicalLetter) => canonicalLetter;
  @override
  String get puzzleListTitle => 'Labyrinth';
  @override
  String puzzleN(int n) => 'Labyrinth $n';
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
  String placedCounter(int placed) => 'Letters: $placed of 33';
  @override
  String get alphabetLabel => 'Alphabet';
  @override
  String get duplicateWarning => 'Duplicates!';
  @override
  String get cellSemantics => 'labyrinth cell';
  @override
  String get markedSemantics => 'marked';
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
  String tutorialStepCounter(int current, int total) => 'Step $current of $total';
  @override
  String tutorialStepText(int index) => 'step $index';
}

List<LabyrinthPuzzle> _loadPuzzles() {
  final file = File('../module_labyrinth/assets/puzzles/module04.json');
  return LabyrinthPuzzle.listFromJsonString(file.readAsStringSync());
}

Widget _wrap({
  required SaveService saveService,
  required List<LabyrinthPuzzle> puzzles,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      labyrinthPuzzlesProvider.overrideWith((ref) async => puzzles),
      labyrinthSaveServiceProvider.overrideWithValue(saveService),
      labyrinthL10nProvider.overrideWithValue(const _FakeLabyrinthL10n()),
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
  late List<LabyrinthPuzzle> puzzles;
  late Directory tempDir;
  late SaveService saveService;

  setUpAll(() {
    puzzles = _loadPuzzles();
  });

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    tempDir = Directory.systemTemp.createTempSync('module_labyrinth_ui_screen_test_');
    saveService = SaveService(() => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('tapping an adjacent cell extends the chain and updates the counter', (tester) async {
    await tester.pumpWidget(
      _wrap(
        saveService: saveService,
        puzzles: puzzles,
        child: const LabyrinthPuzzleScreen(puzzleId: 'example'),
      ),
    );
    await _settle(tester);

    // Both fixed anchors (А at (0,0), Я at (7,7)) count from the start.
    expect(find.text('Letters: 2 of 33'), findsOneWidget);

    // Cell (0,0) is the fixed А anchor; (1,0) is orthogonally adjacent to it
    // and is the example puzzle's first solution step, so tapping it must
    // extend chainA.
    await tester.tap(_cell(1, 0));
    await _settle(tester);
    expect(find.text('Letters: 3 of 33'), findsOneWidget);

    // Tapping the (now) head again retracts the chain.
    await tester.tap(_cell(1, 0));
    await _settle(tester);
    expect(find.text('Letters: 2 of 33'), findsOneWidget);
  });

  testWidgets('a secondary tap on a cell toggles a mark', (tester) async {
    await tester.pumpWidget(
      _wrap(
        saveService: saveService,
        puzzles: puzzles,
        child: const LabyrinthPuzzleScreen(puzzleId: 'example'),
      ),
    );
    await _settle(tester);

    // (0,7) is an interior cell untouched by either anchor/chain in the
    // fresh 'example' session, so a mark there is unambiguous.
    await tester.tap(_cell(0, 7), buttons: kSecondaryButton);
    await _settle(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LabyrinthPuzzleScreen)),
    );
    final board = container.read(labyrinthSessionProvider('example')).board;
    expect(board.marks, contains(const Cell(0, 7)));
  });

  testWidgets('puzzle list screen renders a tile per playable puzzle, plus a tutorial action', (tester) async {
    await tester.pumpWidget(
      _wrap(
        saveService: saveService,
        puzzles: puzzles,
        child: const LabyrinthPuzzleListScreen(),
      ),
    );
    await _settle(tester);

    expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    expect(find.text('Labyrinth'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
  });
}
