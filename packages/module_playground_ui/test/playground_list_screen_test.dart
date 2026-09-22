import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_playground/module_playground.dart';
import 'package:module_playground_ui/module_playground_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'fake_playground_l10n.dart';

Widget _wrap({required SaveService saveService, required Widget child}) {
  return ProviderScope(
    overrides: [
      playgroundPuzzlesProvider.overrideWith(
        (ref) async => buildPlaygroundRegistry(
          const PlaygroundData(
              schemaVersion: 1, module: 'playground', games: []),
        ),
      ),
      playgroundSaveServiceProvider.overrideWithValue(saveService),
      playgroundL10nProvider.overrideWithValue(const FakePlaygroundL10n()),
    ],
    child: MaterialApp(home: child),
  );
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
        .setMockMethodCallHandler(
            SystemChannels.platform, (call) async => null);
    tempDir =
        Directory.systemTemp.createTempSync('module_playground_ui_list_test_');
    saveService = SaveService(() => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('renders seven rows; all seven are tappable; none shows comingSoon',
      (tester) async {
    await tester.pumpWidget(
      _wrap(saveService: saveService, child: const PlaygroundListScreen()),
    );
    await _settle(tester);

    expect(find.byType(ListTile), findsNWidgets(7));

    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect(tiles.where((t) => t.enabled).length, 7);
    expect(tiles.where((t) => t.onTap != null).length, 7);

    expect(find.text('Coming soon'), findsNothing);
  });

  testWidgets('tapping a disabled row does not navigate', (tester) async {
    // All seven shipped games are enabled now, so this coverage is driven
    // from a registry where 'swap_blocks' is swapped out for an
    // [UnshippedPlaygroundGame] instead - the disabled-row behaviour still
    // exists in the shared list-screen code (for whatever ships next) and
    // stays covered without asserting a permanently-false fact about the
    // real registry.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playgroundPuzzlesProvider.overrideWith((ref) async {
            final games = buildPlaygroundRegistry(
              const PlaygroundData(
                  schemaVersion: 1, module: 'playground', games: []),
            );
            return [
              for (final g in games)
                if (g.id == 'swap_blocks')
                  const UnshippedPlaygroundGame(
                      'swap_blocks', PlaygroundFamily.slidingBlocks)
                else
                  g,
            ];
          }),
          playgroundSaveServiceProvider.overrideWithValue(saveService),
          playgroundL10nProvider.overrideWithValue(const FakePlaygroundL10n()),
        ],
        child: const MaterialApp(home: PlaygroundListScreen()),
      ),
    );
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('pg-row-swap_blocks')));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 400));

    // Still on the list screen: no game screen (AppBar with undo/restart
    // actions) was pushed.
    expect(find.byType(PlaygroundListScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('pg-undo')), findsNothing);
  });
}
