import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_rebus/module_rebus.dart';
import 'package:module_rebus_ui/module_rebus_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

/// A minimal [RebusL10n] for widget tests, independent of any real
/// localization setup.
class _FakeRebusL10n implements RebusL10n {
  const _FakeRebusL10n();

  @override
  String get puzzleListTitle => 'Rebuses';
  @override
  String puzzleN(int n) => 'Puzzle $n';
  @override
  String get statusUntouched => 'Untouched';
  @override
  String get statusInProgress => 'In progress';
  @override
  String get statusSolved => 'Solved';
  @override
  String get check => 'Check';
  @override
  String get reset => 'Reset';
  @override
  String get replay => 'Replay';
  @override
  String get next => 'Next';
  @override
  String get backToList => 'Back';
  @override
  String get resetConfirmTitle => 'Reset?';
  @override
  String get resetConfirmBody => 'Are you sure?';
  @override
  String get resetConfirmCancel => 'Cancel';
  @override
  String get resetConfirmOk => 'OK';
  @override
  String get winTitle => 'You win!';
  @override
  String winTime(String formattedTime) => 'Time: $formattedTime';
  @override
  String winChecks(int count) => 'Checks: $count';
  @override
  String get hasErrors => 'Has errors';
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
  String get cellSemanticsGiven => 'given digit';
  @override
  String get cellSemanticsEditable => 'editable digit';
}

List<RebusPuzzle> _loadPuzzles() {
  // Tests run from the package directory (`flutter test` in
  // packages/module_rebus_ui); module_rebus is a sibling package.
  final file = File('../module_rebus/assets/puzzles/module01.json');
  return RebusPuzzle.listFromJsonString(file.readAsStringSync());
}

/// Wraps [TutorialScreen] behind a "home" screen with a button that pushes
/// it, so tests can verify a Done/Skip/close action actually pops back.
Widget _wrapScreen({
  required SaveService saveService,
  required List<RebusPuzzle> puzzles,
}) {
  return ProviderScope(
    overrides: [
      rebusPuzzlesProvider.overrideWith((ref) async => puzzles),
      saveServiceProvider.overrideWithValue(saveService),
      rebusL10nProvider.overrideWithValue(const _FakeRebusL10n()),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const TutorialScreen()),
              ),
              child: const Text('open tutorial'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  // Lets the (test-default-Android) orientation-lock future, the puzzle
  // FutureProvider, and the pushed route's transition all resolve.
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Finder _cellContainer(CellRef ref) => find.byKey(ValueKey('cell_${ref.key}'));

void main() {
  late List<RebusPuzzle> puzzles;
  late Directory tempDir;
  late SaveService saveService;

  setUpAll(() {
    puzzles = _loadPuzzles();
  });

  setUp(() {
    // In widget tests un-mocked platform channels never respond, so the
    // SystemChrome orientation-lock future would never complete and the
    // screen would stay gated on its first-frame SizedBox forever.
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    tempDir = Directory.systemTemp.createTempSync('module_rebus_ui_tutorial_test_');
    saveService = SaveService(() => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
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

  testWidgets('step 1 renders: step text visible, Next visible, Back absent', (tester) async {
    await openTutorial(tester);

    expect(find.text('step 1'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.byKey(const ValueKey('tutorialBackButton')), findsNothing);
    expect(find.text('Back'), findsNothing);
  });

  testWidgets('tapping Next advances the step, and reveals digits by step 5', (tester) async {
    await openTutorial(tester);

    await tapNext(tester);
    expect(find.text('step 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('tutorialBackButton')), findsOneWidget);

    await tapNext(tester); // step 3
    await tapNext(tester); // step 4
    await tapNext(tester); // step 5 — reveals (1,2,0) as canonical digit '1'.

    expect(find.text('step 5'), findsOneWidget);
    const revealed = CellRef(1, 2, 0);
    expect(find.descendant(of: _cellContainer(revealed), matching: find.text('1')), findsOneWidget);
  });

  testWidgets('pressing Back returns to the previous step', (tester) async {
    await openTutorial(tester);

    await tapNext(tester);
    expect(find.text('step 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tutorialBackButton')));
    await tester.pump();

    expect(find.text('step 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('tutorialBackButton')), findsNothing);
  });

  testWidgets(
      'on the last step the button reads Done; tapping it pops the screen and persists the '
      'tutorial-completion flag, preserving pre-existing save data (regression for the '
      '_persistNow merge fix)', (tester) async {
    // Pre-write an existing 'puzzles' entry directly through SaveService,
    // simulating progress already made on p01 before the player opens the
    // tutorial.
    await tester.runAsync(() => saveService.save('module_rebus', <String, dynamic>{
          'puzzles': <String, dynamic>{
            'p01': <String, dynamic>{'solved': true},
          },
        }));

    await openTutorial(tester);

    for (var i = 0; i < 14; i++) {
      await tapNext(tester);
    }
    expect(find.text('step 15'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tutorialNextButton')));
    await tester.pump();

    // The save pipeline mixes real dart:io awaits (which only complete
    // while runAsync runs the real event loop) with continuations queued
    // on the test's FakeAsync microtask queue (which only drain on pump).
    // Ratchet both until the write — and the pop that follows it — land.
    Map<String, dynamic>? saved;
    for (var i = 0; i < 50 && saved == null; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
      final data = (await tester.runAsync(() => saveService.load('module_rebus')))!;
      final tutorial = data['tutorial'];
      if (tutorial is Map && tutorial['completed'] == true) {
        saved = data;
      }
    }
    expect(saved, isNotNull, reason: 'tutorial completion never landed on disk');
    expect((saved!['tutorial'] as Map)['completed'], true);
    expect(((saved['puzzles'] as Map)['p01'] as Map)['solved'], true,
        reason: 'pre-existing puzzles data must survive the tutorial-completion write');

    // A couple more pumps to let the pop's route transition settle.
    await tester.pump();
    await tester.pump();
    expect(find.text('open tutorial'), findsOneWidget);
  });
}
