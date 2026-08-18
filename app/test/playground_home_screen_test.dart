import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_playground/module_playground.dart';
import 'package:module_playground_ui/module_playground_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';
import 'package:puzzles/app.dart';
import 'package:puzzles/providers.dart';

/// Loads the module's real game registry (the shipped `eight_chips` plus
/// six [UnshippedPlaygroundGame] placeholders), exactly as `main.dart`'s
/// `playgroundPuzzlesProvider` would via `rootBundle` — reading the JSON
/// asset directly with `dart:io` instead, matching the pattern the sibling
/// `_loadPuzzles` helpers in `widget_test.dart` and
/// `home_screen_theme_icon_test.dart` use for their own modules.
List<PlaygroundGame> _loadGames() {
  // Tests run from the app package directory (`flutter test` in app/);
  // module_playground is a sibling package under packages/.
  final file = File('../packages/module_playground/assets/puzzles/module06.json');
  final data = PlaygroundData.fromJsonString(file.readAsStringSync());
  return buildPlaygroundRegistry(data);
}

void main() {
  late Directory tempDir;
  late SaveService saveService;
  late SettingsService settingsService;
  late ModuleRegistry moduleRegistry;
  late List<PlaygroundGame> games;

  setUp(() async {
    // In widget tests un-mocked platform channels never respond, so the
    // SystemChrome orientation-lock future on any puzzle screen would never
    // complete and the screen would stay gated on its first frame.
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    tempDir = Directory.systemTemp.createTempSync('puzzles_playground_home_test_');
    saveService = SaveService(() => tempDir);
    settingsService = SettingsService(saveService);
    await settingsService.init();
    // The test asserts Russian strings; the test environment's device
    // locale is English, so pin the app language explicitly.
    await settingsService.setLanguage('ru');
    moduleRegistry = ModuleRegistry()..register(PlaygroundModule.descriptor);
    games = _loadGames();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget wrapApp() {
    return ProviderScope(
      overrides: [
        settingsServiceProvider.overrideWithValue(settingsService),
        moduleRegistryProvider.overrideWithValue(moduleRegistry),
        playgroundSaveServiceProvider.overrideWithValue(saveService),
        // Overridden with the module's *real*, fully-built game list (not a
        // stub) so the home screen's progress lookup genuinely resolves
        // playgroundPuzzlesProvider and _countPuzzles's
        // `(p as dynamic).tutorial` call runs against real PlaygroundGame
        // instances — a test that only ever sees the provider's loading
        // state (and falls back to the hard-coded total) would prove
        // nothing about that code path.
        playgroundPuzzlesProvider.overrideWith((ref) async => games),
      ],
      child: const PuzzleBookApp(),
    );
  }

  testWidgets('home screen shows the playground tile with 0 of 7 progress '
      'once playgroundPuzzlesProvider resolves for real', (tester) async {
    await tester.pumpWidget(wrapApp());
    await tester.pumpAndSettle();

    expect(find.text('Головоломки-игры'), findsOneWidget);
    expect(find.text('Решено: 0 из 7'), findsOneWidget);
  });
}
