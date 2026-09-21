import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_playground/module_playground.dart';
import 'package:module_playground_ui/module_playground_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'fake_playground_l10n.dart';

/// [HourglassBoard] is a leaf widget with no async-loading gate of its own,
/// same as [EightChipsBoard]/[CatsDogsBoard] (see cats_dogs_board_test.dart)
/// — build the [ProviderContainer] up front and await the registry future
/// before pumping the widget, via `UncontrolledProviderScope`.
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

const List<String> _allNodeIds = [
  'A1', 'A2', 'A3', 'A4', 'A5', //
  'B1', 'B2', 'B3', 'B4', //
  'C1', 'C2', 'C3', //
  'D1', 'D2', //
  'E1', //
  'F1', 'F2', //
  'G1', 'G2', 'G3', //
  'H1', 'H2', 'H3', 'H4', //
  'I1', 'I2', 'I3', 'I4', 'I5', //
];

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

  testWidgets('renders every node of the hourglass', (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(
        _wrap(container, const HourglassBoard(gameId: 'hourglass')));
    await _settle(tester);

    for (final id in _allNodeIds) {
      expect(find.byKey(ValueKey('pg-node-$id')), findsOneWidget,
          reason: 'missing node $id');
    }
  });

  testWidgets('tap-select then tap-target walks a token through the waist',
      (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(
        _wrap(container, const HourglassBoard(gameId: 'hourglass')));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('pg-node-E1')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-node-F1')));
    await _settle(tester);
    // Flush the 300ms autosave debounce timer before the tree is torn down.
    await tester.pump(const Duration(milliseconds: 350));

    final state = container.read(playgroundSessionProvider('hourglass'));
    expect(state.moveCount, 1);
    final board = state.board as TokenGraphState;
    expect(board.tokenAt(HourglassGame.board.indexOf('F1')), hourglassToken);
    expect(board.tokenAt(HourglassGame.board.indexOf('E1')), isNull);
  });

  testWidgets('a jump cascade is applied by tapping its far landing',
      (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(
        _wrap(container, const HourglassBoard(gameId: 'hourglass')));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('pg-node-D1')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-node-F2')));
    await _settle(tester);
    // Flush the 300ms autosave debounce timer before the tree is torn down.
    await tester.pump(const Duration(milliseconds: 350));

    final state = container.read(playgroundSessionProvider('hourglass'));
    expect(state.moveCount, 1);
    final board = state.board as TokenGraphState;
    expect(board.tokenAt(HourglassGame.board.indexOf('F2')), hourglassToken);
    expect(board.tokenAt(HourglassGame.board.indexOf('D1')), isNull);
  });
}
