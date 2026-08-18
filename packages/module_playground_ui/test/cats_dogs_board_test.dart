import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_playground/module_playground.dart';
import 'package:module_playground_ui/module_playground_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'fake_playground_l10n.dart';

/// [CatsDogsBoard] is a leaf widget with no async-loading gate of its own,
/// same as [EightChipsBoard] (see eight_chips_board_test.dart) — build the
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

const List<String> _allNodeIds = [
  'L1', 'L2', 'L3', 'R1', 'R2', 'R3', 'TM', 'BM', 'U1', 'U2', 'M', 'D1', 'D2', //
];

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

  testWidgets('renders thirteen node widgets with the initial cat/dog seating', (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container, const CatsDogsBoard(gameId: 'cats_dogs')));
    await _settle(tester);

    for (final id in _allNodeIds) {
      expect(find.byKey(ValueKey('pg-node-$id')), findsOneWidget, reason: 'missing node $id');
    }

    for (final seat in const ['L1', 'L2', 'L3']) {
      expect(
        find.descendant(of: find.byKey(ValueKey('pg-node-$seat')), matching: find.text('C')),
        findsOneWidget,
        reason: 'missing C on $seat',
      );
    }
    for (final seat in const ['R1', 'R2', 'R3']) {
      expect(
        find.descendant(of: find.byKey(ValueKey('pg-node-$seat')), matching: find.text('D')),
        findsOneWidget,
        reason: 'missing D on $seat',
      );
    }
  });

  testWidgets('tapping L1 then U1 applies a move (counter reads 1, cat lands on U1)', (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container, const CatsDogsBoard(gameId: 'cats_dogs')));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('pg-node-L1')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-node-U1')));
    await _settle(tester);
    // Flush the 300ms autosave debounce timer before the tree is torn down.
    await tester.pump(const Duration(milliseconds: 350));

    final state = container.read(playgroundSessionProvider('cats_dogs'));
    expect(state.moveCount, 1);
    final board = state.board as TokenGraphState;
    expect(board.tokenAt(CatsDogsGame.board.indexOf('U1')), catToken);
    expect(board.tokenAt(CatsDogsGame.board.indexOf('L1')), isNull);
  });

  testWidgets('tapping the selected node again deselects without changing the board', (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container, const CatsDogsBoard(gameId: 'cats_dogs')));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('pg-node-L1')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-node-L1')));
    await _settle(tester);

    final state = container.read(playgroundSessionProvider('cats_dogs'));
    expect(state.moveCount, 0);
  });

  testWidgets('never-adjacent rule: a cat on U1 next to a dog on U2 cannot slide to M', (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container, const CatsDogsBoard(gameId: 'cats_dogs')));
    await _settle(tester);

    // Drive the session to a cat-on-U1 / dog-on-U2 position with two legal
    // moves from the start.
    await tester.tap(find.byKey(const ValueKey('pg-node-L1')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-node-U1')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-node-R1')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-node-U2')));
    await _settle(tester);

    final before = container.read(playgroundSessionProvider('cats_dogs'));
    expect(before.moveCount, 2);

    // M is not a legal destination (it is adjacent to the dog on U2), so
    // selecting the cat on U1 and tapping M must be a silent no-op.
    await tester.tap(find.byKey(const ValueKey('pg-node-U1')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-node-M')));
    await _settle(tester);
    // Flush the 300ms autosave debounce timer before the tree is torn down.
    await tester.pump(const Duration(milliseconds: 350));

    final after = container.read(playgroundSessionProvider('cats_dogs'));
    expect(after.moveCount, 2);
    expect(after.board, equals(before.board));
  });

  testWidgets('previewState makes the board non-interactive', (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    final initial = const CatsDogsGame().initialState() as TokenGraphState;

    await tester.pumpWidget(
      _wrap(container, CatsDogsBoard(gameId: 'cats_dogs', previewState: initial)),
    );
    await _settle(tester);

    // L1 -> U1 is legal from the start position, but with previewState set
    // taps must not touch the live session at all.
    await tester.tap(find.byKey(const ValueKey('pg-node-L1')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('pg-node-U1')));
    await _settle(tester);

    final state = container.read(playgroundSessionProvider('cats_dogs'));
    expect(state.moveCount, 0);
    expect(state.board, equals(initial));
  });
}
