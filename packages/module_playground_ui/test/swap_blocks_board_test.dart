import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_playground/module_playground.dart';
import 'package:module_playground_ui/module_playground_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'fake_playground_l10n.dart';

/// [SwapBlocksBoard] is a leaf widget with no async-loading gate of its own,
/// same as [ThreeEachBoard] (see three_each_board_test.dart) — build the
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

/// Block 4's start origin is (row 3, col 0) — shape C, plain colour — and
/// (row 4, col 0) is a single-step legal destination for it: the free gap
/// rows (6-9) are all empty, but that's irrelevant here since this is a
/// direct one-cell slide down, confirmed against [SwapBlocksGame.legalMoves]
/// in the task's own trace of `swap_blocks.dart`.
const int _block4Row = 3;
const int _block4Col = 0;
const int _block4DestRow = 4;
const int _block4DestCol = 0;

/// A free cell that is never a legal destination for block 4: its shape (C)
/// needs bounding-box columns 0-3, so any origin column beyond 4 is out of
/// reach regardless of how far the flood fill travels through the open
/// rows 6-9.
const int _unreachableRow = 6;
const int _unreachableCol = 7;

Future<Offset> _cellCenter(WidgetTester tester, int row, int col) async {
  final boardFinder = find.byKey(const ValueKey('pg-sb-board'));
  final topLeft = tester.getTopLeft(boardFinder);
  final size = tester.getSize(boardFinder);
  final cellSize = size.width / swapBlocksCols;
  return topLeft + Offset((col + 0.5) * cellSize, (row + 0.5) * cellSize);
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
        Directory.systemTemp.createTempSync('module_playground_ui_sb_test_');
    saveService = SaveService(() => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('renders the start layout', (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(
        _wrap(container, const SwapBlocksBoard(gameId: 'swap_blocks')));
    await _settle(tester);

    expect(find.byKey(const ValueKey('pg-sb-board')), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    final state =
        container.read(playgroundSessionProvider('swap_blocks')).board
            as SwapBlocksState;
    expect(state.origins, swapBlocksStartOrigins);
  });

  testWidgets(
      'tapping a block selects it and shows destination markers (only a '
      'marked cell responds)', (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(
        _wrap(container, const SwapBlocksBoard(gameId: 'swap_blocks')));
    await _settle(tester);

    await tester.tapAt(await _cellCenter(tester, _block4Row, _block4Col));
    await _settle(tester);

    // A cell that is free but out of the selected block's reach must not
    // respond, proving the destination set is legality-gated, not "any free
    // cell".
    await tester.tapAt(await _cellCenter(tester, _unreachableRow, _unreachableCol));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 350));
    expect(
        container.read(playgroundSessionProvider('swap_blocks')).moveCount, 0);

    // The real marked destination does respond.
    await tester.tapAt(
        await _cellCenter(tester, _block4DestRow, _block4DestCol));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 350));

    final session = container.read(playgroundSessionProvider('swap_blocks'));
    expect(session.moveCount, 1);
    final state = session.board as SwapBlocksState;
    expect(state.originRow(4), _block4DestRow);
    expect(state.originCol(4), _block4DestCol);
  });

  testWidgets('tapping the selected block again deselects it', (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(
        _wrap(container, const SwapBlocksBoard(gameId: 'swap_blocks')));
    await _settle(tester);

    await tester.tapAt(await _cellCenter(tester, _block4Row, _block4Col));
    await _settle(tester);
    await tester.tapAt(await _cellCenter(tester, _block4Row, _block4Col));
    await _settle(tester);

    // With the selection cleared, the same destination cell that would
    // have worked while selected must now be a no-op.
    await tester.tapAt(
        await _cellCenter(tester, _block4DestRow, _block4DestCol));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 350));

    expect(
        container.read(playgroundSessionProvider('swap_blocks')).moveCount, 0);
  });

  testWidgets(
      'pressing and releasing on a destination marker applies the move',
      (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(
        _wrap(container, const SwapBlocksBoard(gameId: 'swap_blocks')));
    await _settle(tester);

    await tester.tapAt(await _cellCenter(tester, _block4Row, _block4Col));
    await _settle(tester);

    final destCenter =
        await _cellCenter(tester, _block4DestRow, _block4DestCol);
    final gesture = await tester.startGesture(destCenter);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 350));

    expect(
        container.read(playgroundSessionProvider('swap_blocks')).moveCount, 1);
  });

  testWidgets('an unselected board shows no markers - tapping a would-be '
      'destination does nothing', (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(
        _wrap(container, const SwapBlocksBoard(gameId: 'swap_blocks')));
    await _settle(tester);

    // No block selected yet - tapping block 4's would-be destination cell
    // must be a no-op.
    await tester.tapAt(
        await _cellCenter(tester, _block4DestRow, _block4DestCol));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 350));

    expect(
        container.read(playgroundSessionProvider('swap_blocks')).moveCount, 0);
  });
}
