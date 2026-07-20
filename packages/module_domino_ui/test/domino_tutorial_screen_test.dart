import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_domino/module_domino.dart';
import 'package:module_domino_ui/module_domino_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

class _FakeDominoL10n implements DominoL10n {
  const _FakeDominoL10n();
  @override
  String get puzzleListTitle => 'Domino';
  @override
  String puzzleN(int n) => 'Domino $n';
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
  String placedCounter(int placed) => 'Placed: $placed of 28';
  @override
  String get remainingLabel => 'Remaining:';
  @override
  String get duplicateWarning => 'Duplicates!';
  @override
  String get cellSemantics => 'domino cell';
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

List<DominoPuzzle> _loadPuzzles() {
  final file = File('../module_domino/assets/puzzles/module03.json');
  return DominoPuzzle.listFromJsonString(file.readAsStringSync());
}

Widget _wrapScreen({required SaveService saveService, required List<DominoPuzzle> puzzles}) {
  return ProviderScope(
    overrides: [
      dominoPuzzlesProvider.overrideWith((ref) async => puzzles),
      dominoSaveServiceProvider.overrideWithValue(saveService),
      dominoL10nProvider.overrideWithValue(const _FakeDominoL10n()),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const DominoTutorialScreen()),
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
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

void main() {
  late List<DominoPuzzle> puzzles;
  late Directory tempDir;
  late SaveService saveService;

  setUpAll(() {
    puzzles = _loadPuzzles();
  });

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    tempDir = Directory.systemTemp.createTempSync('module_domino_ui_tutorial_test_');
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

  testWidgets('last step Done persists completion and preserves existing save data', (tester) async {
    await tester.runAsync(() => saveService.save('module_domino', <String, dynamic>{
          'puzzles': <String, dynamic>{
            'p01': <String, dynamic>{'solved': true},
          },
        }));

    await openTutorial(tester);
    for (var i = 0; i < dominoTutorialSteps.length - 1; i++) {
      await tapNext(tester);
    }
    expect(find.text('step ${dominoTutorialSteps.length}'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tutorialNextButton')));
    await tester.pump();

    Map<String, dynamic>? saved;
    for (var i = 0; i < 50 && saved == null; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
      final data = (await tester.runAsync(() => saveService.load('module_domino')))!;
      final tutorial = data['tutorial'];
      if (tutorial is Map && tutorial['completed'] == true) {
        saved = data;
      }
    }
    expect(saved, isNotNull, reason: 'tutorial completion never landed on disk');
    expect(((saved!['puzzles'] as Map)['p01'] as Map)['solved'], true,
        reason: 'pre-existing puzzles data must survive the tutorial-completion write');

    await tester.pump();
    await tester.pump();
    expect(find.text('open tutorial'), findsOneWidget);
  });
}
