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

  testWidgets(
      'renders seven rows; exactly six are tappable; one shows comingSoon',
      (tester) async {
    await tester.pumpWidget(
      _wrap(saveService: saveService, child: const PlaygroundListScreen()),
    );
    await _settle(tester);

    expect(find.byType(ListTile), findsNWidgets(7));

    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect(tiles.where((t) => t.enabled).length, 6);
    expect(tiles.where((t) => t.onTap != null).length, 6);

    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('tapping a disabled row does not navigate', (tester) async {
    await tester.pumpWidget(
      _wrap(saveService: saveService, child: const PlaygroundListScreen()),
    );
    await _settle(tester);

    // 'swap_blocks' is the one disabled game left in the fixed registry
    // order.
    await tester.tap(find.byKey(const ValueKey('pg-row-swap_blocks')));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 400));

    // Still on the list screen: no game screen (AppBar with undo/restart
    // actions) was pushed.
    expect(find.byType(PlaygroundListScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('pg-undo')), findsNothing);
  });
}
