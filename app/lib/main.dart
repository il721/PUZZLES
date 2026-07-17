import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_rebus_ui/module_rebus_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:puzzle_core/puzzle_core.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'providers.dart';

/// Minimum logical window size enforced on Windows so the puzzle grid
/// always has comfortable room, regardless of how small the player resizes
/// the window.
const Size _minimumWindowSize = Size(960, 540);

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

  final moduleRegistry = ModuleRegistry()..register(RebusModule.descriptor);

  runApp(
    ProviderScope(
      overrides: [
        saveServiceProvider.overrideWithValue(saveService),
        settingsServiceProvider.overrideWithValue(settingsService),
        moduleRegistryProvider.overrideWithValue(moduleRegistry),
      ],
      child: const PuzzleBookApp(),
    ),
  );
}
