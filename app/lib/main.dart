import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_digit_rebus_ui/module_digit_rebus_ui.dart';
import 'package:module_domino_ui/module_domino_ui.dart';
import 'package:module_labyrinth_ui/module_labyrinth_ui.dart';
import 'package:module_rebus_ui/module_rebus_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:puzzle_core/puzzle_core.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'bundle_transfer.dart';
import 'providers.dart';

/// Minimum logical window size enforced on Windows so the puzzle grid
/// always has comfortable room, regardless of how small the player resizes
/// the window.
const Size _minimumWindowSize = Size(960, 540);

/// Builds the app's module registry. Exposed as a named function (rather
/// than being inlined into [main]) so tests can assert against the very
/// registry the app ships with — the export/import namespace list is
/// derived from it, so a module missing here is silently missing from
/// progress sync.
ModuleRegistry buildModuleRegistry() => ModuleRegistry()
  ..register(RebusModule.descriptor)
  ..register(DigitRebusModule.descriptor)
  ..register(DominoModule.descriptor)
  ..register(LabyrinthModule.descriptor);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(_minimumWindowSize);
  }

  final supportDirectory = await getApplicationSupportDirectory();
  final saveService = SaveService(() => supportDirectory, logger: const ConsoleLogger());

  final settingsService = SettingsService(saveService);
  await settingsService.init();

  final moduleRegistry = buildModuleRegistry();

  final progressBundleService = ProgressBundleService(
    saveService,
    moduleRegistry.modules.map((m) => m.saveNamespace).toList(),
  );

  runApp(
    ProviderScope(
      overrides: [
        saveServiceProvider.overrideWithValue(saveService),
        digitRebusSaveServiceProvider.overrideWithValue(saveService),
        dominoSaveServiceProvider.overrideWithValue(saveService),
        labyrinthSaveServiceProvider.overrideWithValue(saveService),
        settingsServiceProvider.overrideWithValue(settingsService),
        moduleRegistryProvider.overrideWithValue(moduleRegistry),
        progressBundleServiceProvider.overrideWithValue(progressBundleService),
        bundleTransferProvider.overrideWithValue(const FilePickerBundleTransfer()),
      ],
      child: const PuzzleBookApp(),
    ),
  );
}
