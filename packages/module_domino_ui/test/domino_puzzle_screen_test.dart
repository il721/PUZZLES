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
}

List<DominoPuzzle> _loadPuzzles() {
  final file = File('../module_domino/assets/puzzles/module03.json');
  return DominoPuzzle.listFromJsonString(file.readAsStringSync());
}

Widget _wrap({
  required SaveService saveService,
  required List<DominoPuzzle> puzzles,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      dominoPuzzlesProvider.overrideWith((ref) async => puzzles),
      dominoSaveServiceProvider.overrideWithValue(saveService),
      dominoL10nProvider.overrideWithValue(const _FakeDominoL10n()),
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
    tempDir = Directory.systemTemp.createTempSync('module_domino_ui_screen_test_');
    saveService = SaveService(() => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('tap two adjacent cells binds a domino; tapping it again splits', (tester) async {
    await tester.pumpWidget(
      _wrap(
        saveService: saveService,
        puzzles: puzzles,
        child: const DominoPuzzleScreen(puzzleId: 'example'),
      ),
    );
    await _settle(tester);

    expect(find.text('Placed: 0 of 28'), findsOneWidget);

    await tester.tap(_cell(0, 0));
    await tester.pump();
    await tester.tap(_cell(0, 1));
    await tester.pump();
    expect(find.text('Placed: 1 of 28'), findsOneWidget);

    await tester.tap(_cell(0, 0));
    await tester.pump();
    expect(find.text('Placed: 0 of 28'), findsOneWidget);
  });

  testWidgets('puzzle list screen renders a tile per playable puzzle', (tester) async {
    await tester.pumpWidget(
      _wrap(
        saveService: saveService,
        puzzles: puzzles,
        child: const DominoPuzzleListScreen(),
      ),
    );
    await _settle(tester);

    final playable = puzzles.where((p) => !p.tutorial).length;
    expect(find.byType(InkWell), findsNWidgets(playable));
    expect(find.text('Domino'), findsOneWidget);
  });
}
