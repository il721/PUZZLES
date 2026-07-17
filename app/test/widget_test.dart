import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_rebus/module_rebus.dart';
import 'package:module_rebus_ui/module_rebus_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';
import 'package:puzzles/app.dart';
import 'package:puzzles/providers.dart';

List<RebusPuzzle> _loadPuzzles() {
  // Tests run from the app package directory (`flutter test` in app/);
  // module_rebus is a sibling package under packages/.
  final file = File('../packages/module_rebus/assets/puzzles/module01.json');
  return RebusPuzzle.listFromJsonString(file.readAsStringSync());
}

void main() {
  late Directory tempDir;
  late SaveService saveService;
  late SettingsService settingsService;
  late ModuleRegistry moduleRegistry;
  late List<RebusPuzzle> puzzles;

  setUp(() async {
    // In widget tests un-mocked platform channels never respond, so the
    // SystemChrome orientation-lock future on PuzzleScreen would never
    // complete and the screen would stay gated on its first frame.
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    tempDir = Directory.systemTemp.createTempSync('puzzles_app_test_');
    saveService = SaveService(() => tempDir);
    settingsService = SettingsService(saveService);
    await settingsService.init();
    // The test asserts Russian strings; the test environment's device
    // locale is English, so pin the app language explicitly.
    await settingsService.setLanguage('ru');
    moduleRegistry = ModuleRegistry()..register(RebusModule.descriptor);
    puzzles = _loadPuzzles();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget wrapApp() {
    return ProviderScope(
      overrides: [
        saveServiceProvider.overrideWithValue(saveService),
        settingsServiceProvider.overrideWithValue(settingsService),
        moduleRegistryProvider.overrideWithValue(moduleRegistry),
        rebusPuzzlesProvider.overrideWith((ref) async => puzzles),
      ],
      child: const PuzzleBookApp(),
    );
  }

  testWidgets('home renders the module card; navigating to the list and opening p01 works', (tester) async {
    await tester.pumpWidget(wrapApp());
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // Home screen: the module card is visible with its localized title.
    expect(find.text('Ребусы с квадратиками'), findsOneWidget);

    await tester.tap(find.text('Ребусы с квадратиками'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // Puzzle list: 15 numbered tiles (p01..p15), tutorial excluded.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);

    // Open puzzle 1.
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Ребус 1'), findsOneWidget);
  });
}
