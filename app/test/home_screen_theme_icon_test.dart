import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

/// The asset name flutter_svg's [SvgAssetLoader] resolves each module card's
/// [SvgPicture.asset] to; used to check which icon variant (dark vs. light)
/// the home screen chose for the current theme.
List<String> _moduleCardIconAssetNames(WidgetTester tester) {
  return tester
      .widgetList<SvgPicture>(find.byType(SvgPicture))
      .map((picture) => (picture.bytesLoader as SvgAssetLoader).assetName)
      .toList();
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
    tempDir = Directory.systemTemp.createTempSync('puzzles_home_theme_icon_test_');
    saveService = SaveService(() => tempDir);
    settingsService = SettingsService(saveService);
    await settingsService.init();
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

  testWidgets('home screen module cards use the *_light.svg icons in light theme', (tester) async {
    // settingsService.setTheme performs a real dart:io file write. Awaited
    // directly inside a testWidgets body (a FakeAsync-like zone) it never
    // completes, so it must run through tester.runAsync (see the
    // flutter-widget-test-gotchas project note on real dart:io in
    // testWidgets zones).
    await tester.runAsync(() => settingsService.setTheme('light'));

    await tester.pumpWidget(wrapApp());
    await tester.pump();
    await tester.pump();
    await tester.pump();

    final assetNames = _moduleCardIconAssetNames(tester);
    expect(assetNames, isNotEmpty);
    for (final assetName in assetNames) {
      expect(assetName, endsWith('_light.svg'));
    }
  });

  testWidgets('home screen module cards use the dark icons in dark theme', (tester) async {
    await tester.runAsync(() => settingsService.setTheme('dark'));

    await tester.pumpWidget(wrapApp());
    await tester.pump();
    await tester.pump();
    await tester.pump();

    final assetNames = _moduleCardIconAssetNames(tester);
    expect(assetNames, isNotEmpty);
    for (final assetName in assetNames) {
      expect(assetName, isNot(endsWith('_light.svg')));
    }
  });
}
