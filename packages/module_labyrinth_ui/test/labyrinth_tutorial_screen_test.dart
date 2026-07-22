import 'dart:io';

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

Widget _wrapScreen({required SaveService saveService, required List<LabyrinthPuzzle> puzzles}) {
  return ProviderScope(
    overrides: [
      labyrinthPuzzlesProvider.overrideWith((ref) async => puzzles),
      labyrinthSaveServiceProvider.overrideWithValue(saveService),
      labyrinthL10nProvider.overrideWithValue(const _FakeLabyrinthL10n()),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LabyrinthTutorialScreen()),
              ),
              child: const Text('open tutorial'),
            ),
          ),
        ),
      ),
    ),
  );
}

// Deliberately not pumpAndSettle: the screen has a CircularProgressIndicator
// in its loading branch, and pumpAndSettle would spin on that animation
// (and time out) if the puzzles provider is ever slow to resolve. One pump
// starts the MaterialPageRoute transition, then an explicit duration pump
// runs it past its ~300ms default so the pushed/popped screen is fully
// settled before assertions run.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

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
    tempDir = Directory.systemTemp.createTempSync('module_labyrinth_ui_tutorial_test_');
    saveService = SaveService(() => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> openTutorial(WidgetTester tester) async {
    await tester.pumpWidget(_wrapScreen(saveService: saveService, puzzles: puzzles));
    await tester.pump();
    await tester.tap(find.text('open tutorial'));
    await _settle(tester);
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('tutorialNextButton')));
    await tester.pump();
  }

  testWidgets('step 1 renders: text visible, Next visible, Back absent', (tester) async {
    await openTutorial(tester);
    expect(find.text('step 1'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.byKey(const ValueKey('tutorialBackButton')), findsNothing);
  });

  testWidgets('Next advances a step, Back returns', (tester) async {
    await openTutorial(tester);
    await tapNext(tester);
    expect(find.text('step 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('tutorialBackButton')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tutorialBackButton')));
    await tester.pump();
    expect(find.text('step 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('tutorialBackButton')), findsNothing);
  });

  testWidgets('Next reveals more path cells as steps 4+ are reached', (tester) async {
    await openTutorial(tester);

    int placedCount() =>
        tester.widget<LabyrinthGridWidget>(find.byType(LabyrinthGridWidget)).board.pathCells.length;

    // Steps 1-3 (index 0-2) reveal no path cells: only the two fixed
    // anchors (А at (0,0), Я at (7,7)) are on the path.
    expect(placedCount(), 2);
    for (var i = 0; i < 2; i++) {
      await tapNext(tester);
      expect(placedCount(), 2);
    }

    // Step 4 (index 3) reveals solution indices [0,1,2,3] -> 4 cells, plus
    // the untouched Я anchor -> 5 cells total.
    await tapNext(tester);
    expect(find.text('step 4'), findsOneWidget);
    expect(placedCount(), 5);

    // Step 5 (index 4) reveals [4,5,6,7] on top of the prior 4 -> 8 cells,
    // plus Я -> 9 cells total. Reveals are cumulative.
    await tapNext(tester);
    expect(find.text('step 5'), findsOneWidget);
    expect(placedCount(), 9);
  });

  testWidgets('last step Done persists completion and preserves existing save data', (tester) async {
    await tester.runAsync(() => saveService.save('module_labyrinth', <String, dynamic>{
          'puzzles': <String, dynamic>{
            'p01': <String, dynamic>{'solved': true},
          },
        }));

    await openTutorial(tester);
    for (var i = 0; i < labyrinthTutorialSteps.length - 1; i++) {
      await tapNext(tester);
    }
    expect(find.text('step ${labyrinthTutorialSteps.length}'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tutorialNextButton')));
    await tester.pump();

    Map<String, dynamic>? saved;
    for (var i = 0; i < 50 && saved == null; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
      final data = (await tester.runAsync(() => saveService.load('module_labyrinth')))!;
      final tutorial = data['tutorial'];
      if (tutorial is Map && tutorial['completed'] == true) {
        saved = data;
      }
    }
    expect(saved, isNotNull, reason: 'tutorial completion never landed on disk');
    expect(((saved!['puzzles'] as Map)['p01'] as Map)['solved'], true,
        reason: 'pre-existing puzzles data must survive the tutorial-completion write');

    await _settle(tester);
    expect(find.text('open tutorial'), findsOneWidget);
  });

  testWidgets('Skip pops without writing tutorial completion', (tester) async {
    await openTutorial(tester);
    await tester.tap(find.text('Skip'));
    await _settle(tester);

    expect(find.text('open tutorial'), findsOneWidget);
    final data = (await tester.runAsync(() => saveService.load('module_labyrinth')))!;
    expect(data['tutorial'], isNull);
  });
}
