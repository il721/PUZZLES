import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_playground/module_playground.dart';
import 'package:module_playground_ui/module_playground_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'fake_playground_l10n.dart';

/// The pattern printed as the answer in the book (Мочалов, 1980, p. 116),
/// one entry per slot S1..S25 in row-major order, as (tile number, quarter
/// turns). Pinned in module_playground's patterns5_solved_test as well; here
/// it drives the board through real taps.
const List<(int, int)> _bookAnswer = [
  (6, 3), (14, 1), (20, 0), (21, 1), (12, 1), //
  (18, 1), (25, 2), (1, 3), (16, 0), (10, 1), //
  (19, 3), (22, 1), (9, 2), (23, 1), (7, 0), //
  (11, 2), (3, 3), (2, 3), (4, 1), (8, 1), //
  (13, 3), (5, 2), (15, 3), (17, 0), (24, 3), //
];

Future<ProviderContainer> _makeContainer(SaveService saveService) async {
  final container = ProviderContainer(overrides: [
    playgroundPuzzlesProvider.overrideWith(
      (ref) async => buildPlaygroundRegistry(
        const PlaygroundData(schemaVersion: 1, module: 'playground', games: []),
      ),
    ),
    playgroundSaveServiceProvider.overrideWithValue(saveService),
    playgroundL10nProvider.overrideWithValue(const FakePlaygroundL10n()),
  ]);
  await container.read(playgroundPuzzlesProvider.future);
  return container;
}

Widget _wrap(ProviderContainer container, Widget child) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

Widget _board() => PatternsBoard(
      gameId: 'patterns5',
      game: PatternsGame.patterns5(),
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// Taps [key], scrolling the tray to it first - twenty-five tray tiles do
/// not all fit on screen at once.
Future<void> _tap(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

/// Selects tray tile [tileNum] (1-indexed), turns it [rotation] quarter
/// turns by tapping it again, then taps board slot [slotNum] (1-indexed).
Future<void> _place(
    WidgetTester tester, int tileNum, int slotNum, int rotation) async {
  final trayKey = ValueKey('pg-p5-tray-${tileNum - 1}');
  await _tap(tester, trayKey);
  for (var i = 0; i < rotation; i++) {
    await _tap(tester, trayKey);
  }
  await _tap(tester, ValueKey('pg-p5-slot-${slotNum - 1}'));
}

void main() {
  late Directory tempDir;
  late SaveService saveService;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            SystemChannels.platform, (call) async => null);
    tempDir = Directory.systemTemp
        .createTempSync('module_playground_ui_patterns_test_');
    saveService = SaveService(() => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('tapping a tray tile then an empty slot places it',
      (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container, _board()));
    await _settle(tester);

    await _tap(tester, const ValueKey('pg-p5-tray-0'));
    await _tap(tester, const ValueKey('pg-p5-slot-0'));
    await tester.pump(const Duration(milliseconds: 350));

    final state =
        container.read(playgroundSessionProvider('patterns5')).board
            as PatternsState;
    expect(state.slotOfTile(0), 0);
  });

  testWidgets('tapping the selected tray tile again only turns the preview',
      (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container, _board()));
    await _settle(tester);

    await _tap(tester, const ValueKey('pg-p5-tray-0'));
    await _tap(tester, const ValueKey('pg-p5-tray-0'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(container.read(playgroundSessionProvider('patterns5')).moveCount, 0);
  });

  testWidgets('the rotate and return buttons drive a placed tile',
      (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container, _board()));
    await _settle(tester);

    await _tap(tester, const ValueKey('pg-p5-tray-0'));
    await _tap(tester, const ValueKey('pg-p5-slot-0'));
    await _tap(tester, const ValueKey('pg-p5-slot-0'));
    await _tap(tester, const ValueKey('pg-p5-rotate'));
    await tester.pump(const Duration(milliseconds: 350));

    var session = container.read(playgroundSessionProvider('patterns5'));
    expect((session.board as PatternsState).slots[0],
        const PatternsPlacement(0, 1));
    expect(session.moveCount, 2);

    await _tap(tester, const ValueKey('pg-p5-return'));
    await tester.pump(const Duration(milliseconds: 350));

    session = container.read(playgroundSessionProvider('patterns5'));
    expect((session.board as PatternsState).slotOfTile(0), isNull);
    expect(session.moveCount, 3);
  });

  testWidgets('playing the book pattern through taps solves the puzzle',
      (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container, _board()));
    await _settle(tester);

    for (var slot = 0; slot < _bookAnswer.length; slot++) {
      final (tile, rotation) = _bookAnswer[slot];
      await _place(tester, tile, slot + 1, rotation);
    }

    // Flush the 300ms autosave debounce timer before the tree is torn down.
    await tester.pump(const Duration(milliseconds: 350));

    final session = container.read(playgroundSessionProvider('patterns5'));
    expect(session.solved, isTrue);
    expect(session.moveCount, 25);
  });
}
