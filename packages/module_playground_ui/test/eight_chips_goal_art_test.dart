import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_playground/module_playground.dart';
import 'package:module_playground_ui/module_playground_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'fake_playground_l10n.dart';

/// Covers two things the eight-chips board+screen changed for the goal-art
/// feature: the screen shows the goal SVG at both narrow and wide surface
/// sizes, and the board rotates each tip's digit label to match the
/// artwork.
Widget _wrap(ProviderContainer container, Widget child) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: child),
  );
}

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

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  late Directory tempDir;
  late SaveService saveService;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    tempDir = Directory.systemTemp.createTempSync('module_playground_ui_goal_art_test_');
    saveService = SaveService(() => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('shows the goal art at a narrow surface size', (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _wrap(container, const PlaygroundGameScreen(gameId: 'eight_chips')),
    );
    await _settle(tester);

    expect(find.byKey(const ValueKey('pg-goal-art')), findsOneWidget);

    // PlaygroundGameScreen.dispose() schedules a microtask that starts the
    // 300ms autosave debounce timer; tear the tree down ourselves and flush
    // both before the test ends, or flutter_test's end-of-test invariant
    // check fails on the still-pending Timer.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  });

  testWidgets('shows the goal art at a wide (desktop) surface size', (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(container, const PlaygroundGameScreen(gameId: 'eight_chips')),
    );
    await _settle(tester);

    expect(find.byKey(const ValueKey('pg-goal-art')), findsOneWidget);

    // PlaygroundGameScreen.dispose() schedules a microtask that starts the
    // 300ms autosave debounce timer; tear the tree down ourselves and flush
    // both before the test ends, or flutter_test's end-of-test invariant
    // check fails on the still-pending Timer.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  });

  testWidgets('rotates the P5 tip digit label by pi, matching the goal artwork',
      (tester) async {
    final container = await _makeContainer(saveService);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _wrap(container, const EightChipsBoard(gameId: 'eight_chips')),
    );
    await _settle(tester);

    // P5 is 4 tips clockwise from P1 (see `_clockwiseTips`), so its
    // rotation is 4 * (2*pi/8) = pi. Transform.rotate builds a rotation-Z
    // matrix; recover the angle via atan2 of its sin/cos entries.
    final transform = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey('pg-node-P5')),
        matching: find.byType(Transform),
      ),
    );
    final matrix = transform.transform;
    final angle = math.atan2(matrix.entry(1, 0), matrix.entry(0, 0));
    expect(angle, closeTo(math.pi, 0.01));
  });
}
