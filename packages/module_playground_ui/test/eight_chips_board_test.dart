import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_playground/module_playground.dart';
import 'package:module_playground_ui/module_playground_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'fake_playground_l10n.dart';

/// [EightChipsBoard] is a leaf widget with no async-loading gate of its own
/// (that gate lives one layer up, in `PlaygroundGameScreen`) — it expects
/// `playgroundPuzzlesProvider` to already be resolved by the time it first
/// builds. So, unlike the list-screen test (which mounts the gate-having
/// `PlaygroundListScreen` and can afford a couple of `pump()`s to let the
/// future resolve), these tests build the `ProviderContainer` up front and
/// await the registry future BEFORE pumping the widget, via
/// `UncontrolledProviderScope`.
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

const List<String> _allNodeIds = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8', 'C'];

void main() {
  late Directory tempDir;
  late SaveService saveService;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    tempDir = Directory.systemTemp.createTempSync('module_playground_ui_board_test_');
    saveService = SaveService(() => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('renders nine node widgets', (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container, const EightChipsBoard(gameId: 'eight_chips')));
    await _settle(tester);

    for (final id in _allNodeIds) {
      expect(find.byKey(ValueKey('pg-node-$id')), findsOneWidget, reason: 'missing node $id');
    }
  });

  testWidgets('tapping token 1 then node C applies a move (counter reads 1)', (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container, const EightChipsBoard(gameId: 'eight_chips')));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('pg-node-P1')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-node-C')));
    await _settle(tester);
    // Flush the 300ms autosave debounce timer before the tree is torn down —
    // an unflushed pending Timer fails flutter_test's end-of-test invariant
    // check even though the assertion under test has nothing to do with
    // persistence.
    await tester.pump(const Duration(milliseconds: 350));

    final state = container.read(playgroundSessionProvider('eight_chips'));
    expect(state.moveCount, 1);
  });

  testWidgets(
      'tapping token 2 (no legal move from the start position) then any node changes nothing',
      (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container, const EightChipsBoard(gameId: 'eight_chips')));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('pg-node-P2')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-node-C')));
    await _settle(tester);

    final state = container.read(playgroundSessionProvider('eight_chips'));
    expect(state.moveCount, 0);
  });
}
