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
  @override
  String get cyrillicNote => '';
}

List<SquarewordPuzzle> _loadPuzzles() {
  final file = File('../module_squareword/assets/puzzles/module05.json');
  return SquarewordPuzzle.listFromJsonString(file.readAsStringSync());
}

Widget _wrapScreen({required SaveService saveService, required List<SquarewordPuzzle> puzzles}) {
  return ProviderScope(
    overrides: [
      squarewordPuzzlesProvider.overrideWith((ref) async => puzzles),
      squarewordSaveServiceProvider.overrideWithValue(saveService),
      squarewordL10nProvider.overrideWithValue(const _FakeSquarewordL10n()),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SquarewordTutorialScreen()),
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
  late List<SquarewordPuzzle> puzzles;
  late Directory tempDir;
  late SaveService saveService;

  setUpAll(() {
    puzzles = _loadPuzzles();
  });

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    tempDir = Directory.systemTemp.createTempSync('module_squareword_ui_tutorial_test_');
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

  int filledCount(WidgetTester tester) => tester
      .widget<SquarewordGridWidget>(find.byType(SquarewordGridWidget))
      .board
      .status()
      .filledCount;

  testWidgets('step 1 renders: text visible, Next visible, Back absent', (tester) async {
    await openTutorial(tester);
    expect(find.text('step 1'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.byKey(const ValueKey('tutorialBackButton')), findsNothing);
    // Only the 8 given cells (keyword row + ЛЕС) are filled at step 1.
    expect(filledCount(tester), 8);
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

  testWidgets('Next reveals the right cumulative cell count as steps progress', (tester) async {
    await openTutorial(tester);

    // Steps 1-2 (index 0-1) reveal nothing: 8 given cells only.
    expect(filledCount(tester), 8);
    await tapNext(tester);
    expect(find.text('step 2'), findsOneWidget);
    expect(filledCount(tester), 8);

    // Step 3 (index 2) reveals 1 cell -> 9.
    await tapNext(tester);
    expect(find.text('step 3'), findsOneWidget);
    expect(filledCount(tester), 9);

    // Step 4 (index 3) reveals 2 more cells -> 11.
    await tapNext(tester);
    expect(find.text('step 4'), findsOneWidget);
    expect(filledCount(tester), 11);

    // Advance through steps 5-11 (index 4-10); step 11 (index 10) reveals
    // the last 7 cells, bringing the grid to fully filled (25 of 25).
    for (var i = 0; i < 7; i++) {
      await tapNext(tester);
    }
    expect(find.text('step 11'), findsOneWidget);
    expect(filledCount(tester), 25);

    // Step 12 (index 11) is the closing step: still fully filled.
    await tapNext(tester);
    expect(find.text('step 12'), findsOneWidget);
    expect(filledCount(tester), 25);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('last step Done persists completion and preserves existing save data', (tester) async {
    await tester.runAsync(() => saveService.save('module_squareword', <String, dynamic>{
          'puzzles': <String, dynamic>{
            'p01': <String, dynamic>{'solved': true},
          },
        }));

    await openTutorial(tester);
    for (var i = 0; i < squarewordTutorialSteps.length - 1; i++) {
      await tapNext(tester);
    }
    expect(find.text('step ${squarewordTutorialSteps.length}'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tutorialNextButton')));
    await tester.pump();

    Map<String, dynamic>? saved;
    for (var i = 0; i < 50 && saved == null; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
      final data = (await tester.runAsync(() => saveService.load('module_squareword')))!;
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
    final data = (await tester.runAsync(() => saveService.load('module_squareword')))!;
    expect(data['tutorial'], isNull);
  });
}
