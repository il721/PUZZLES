import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_playground/module_playground.dart';
import 'package:module_playground_ui/module_playground_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'fake_playground_l10n.dart';

/// [ThreeEachBoard] is a leaf widget with no async-loading gate of its own,
/// same as [HourglassBoard] (see hourglass_board_test.dart) — build the
/// [ProviderContainer] up front and await the registry future before
/// pumping the widget, via `UncontrolledProviderScope`.
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

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// Selects tray tile [tileNum] (1-indexed), rotates it [rotation] quarter
/// turns via repeated taps on the same tray tile, then taps board slot
/// [slotNum] (1-indexed) to lay it down.
Future<void> _place(WidgetTester tester, int tileNum, int slotNum, int rotation) async {
  final trayKey = ValueKey('pg-te-tray-${tileNum - 1}');
  await tester.tap(find.byKey(trayKey));
  await tester.pump();
  for (var i = 0; i < rotation; i++) {
    await tester.tap(find.byKey(trayKey));
    await tester.pump();
  }
  await tester.tap(find.byKey(ValueKey('pg-te-slot-${slotNum - 1}')));
  await tester.pump();
}

void main() {
  late Directory tempDir;
  late SaveService saveService;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            SystemChannels.platform, (call) async => null);
    tempDir =
        Directory.systemTemp.createTempSync('module_playground_ui_board_test_');
    saveService = SaveService(() => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('tapping a tray tile then an empty slot places it',
      (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(
        _wrap(container, const ThreeEachBoard(gameId: 'three_each')));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('pg-te-tray-0')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-te-slot-0')));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 350));

    final state = container.read(playgroundSessionProvider('three_each')).board
        as ThreeEachState;
    expect(state.slotOfTile(0), 0);
  });

  testWidgets(
      'tapping the selected tray tile again rotates the preview without applying a move',
      (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(
        _wrap(container, const ThreeEachBoard(gameId: 'three_each')));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('pg-te-tray-0')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-te-tray-0')));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 350));

    expect(
        container.read(playgroundSessionProvider('three_each')).moveCount, 0);
  });

  testWidgets('the rotate button rotates a placed tile in place',
      (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(
        _wrap(container, const ThreeEachBoard(gameId: 'three_each')));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('pg-te-tray-0')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-te-slot-0')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-te-slot-0')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-te-rotate')));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 350));

    final session = container.read(playgroundSessionProvider('three_each'));
    final state = session.board as ThreeEachState;
    expect(state.slots[0], const ThreeEachPlacement(0, 1));
    expect(session.moveCount, 2);
  });

  testWidgets('the return button puts a placed tile back in the tray',
      (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(
        _wrap(container, const ThreeEachBoard(gameId: 'three_each')));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('pg-te-tray-0')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-te-slot-0')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-te-slot-0')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-te-return')));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 350));

    final state = container.read(playgroundSessionProvider('three_each')).board
        as ThreeEachState;
    expect(state.slotOfTile(0), isNull);
  });

  testWidgets('playing the book solution through taps solves the puzzle',
      (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(
        _wrap(container, const ThreeEachBoard(gameId: 'three_each')));
    await _settle(tester);

    await _place(tester, 2, 1, 2);
    await _place(tester, 3, 2, 0);
    await _place(tester, 1, 3, 3);
    await _place(tester, 4, 4, 1);
    await _place(tester, 5, 5, 3);
    await _place(tester, 6, 6, 0);
    await _place(tester, 9, 7, 0);
    await _place(tester, 8, 8, 3);
    await _place(tester, 7, 9, 2);

    // Flush the 300ms autosave debounce timer before the tree is torn down.
    await tester.pump(const Duration(milliseconds: 350));

    final session = container.read(playgroundSessionProvider('three_each'));
    expect(session.solved, isTrue);
    expect(session.moveCount, 9);
  });
}
