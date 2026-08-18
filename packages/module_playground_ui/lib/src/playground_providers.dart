import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_playground/module_playground.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'playground_module.dart';

/// Loads Module 06's parsed game data (par/solution metadata) from its
/// bundled JSON asset.
///
/// Overridable for tests (e.g. to load from a file directly instead of
/// `rootBundle`).
final FutureProvider<PlaygroundData> playgroundDataProvider =
    FutureProvider<PlaygroundData>((ref) async {
  final jsonString = await rootBundle.loadString(
    'packages/module_playground/assets/puzzles/module06.json',
  );
  return PlaygroundData.fromJsonString(jsonString);
});

/// Builds the module's full game registry from [playgroundDataProvider].
///
/// Named exactly `playgroundPuzzlesProvider` (not `...GamesProvider`): the
/// app's home screen counts entries in it and calls `.tutorial` on each,
/// matching the pattern used by every sibling module's puzzle-list
/// provider.
final FutureProvider<List<PlaygroundGame>> playgroundPuzzlesProvider =
    FutureProvider<List<PlaygroundGame>>((ref) async {
  final data = await ref.watch(playgroundDataProvider.future);
  return buildPlaygroundRegistry(data);
});

/// The [SaveService] used to persist this module's progress. Must be
/// overridden by the app shell with a concrete instance before any
/// module_playground_ui widget is built. Named distinctly from the other
/// modules' save-service providers so the app shell can import all UI
/// packages without a symbol clash.
final Provider<SaveService> playgroundSaveServiceProvider = Provider<SaveService>((ref) {
  throw UnimplementedError(
    'playgroundSaveServiceProvider must be overridden with a concrete SaveService before use.',
  );
});

/// Loads the raw persisted save data for [playgroundSaveNamespace] (shape:
/// `{"puzzles": {"<gameId>": {...}}}`). Used by the game list screen and the
/// home-screen module card. Invalidate after returning from a game screen to
/// pick up changes.
final FutureProvider<Map<String, dynamic>> playgroundSaveDataProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  final saveService = ref.watch(playgroundSaveServiceProvider);
  return saveService.load(playgroundSaveNamespace);
});

/// The [AudioService] used to play SFX from this module's screens. Defaults
/// to a no-op; the app shell overrides this with its real [AudioService].
final Provider<AudioService> playgroundAudioServiceProvider =
    Provider<AudioService>((ref) => const NoopAudioService());
