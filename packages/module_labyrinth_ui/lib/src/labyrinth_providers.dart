import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_labyrinth/module_labyrinth.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'labyrinth_module.dart';

/// Loads every puzzle in Module 04 from its bundled JSON asset.
///
/// Overridable for tests (e.g. to load from a file directly instead of
/// `rootBundle`).
final FutureProvider<List<LabyrinthPuzzle>> labyrinthPuzzlesProvider =
    FutureProvider<List<LabyrinthPuzzle>>((ref) async {
  final jsonString = await rootBundle.loadString(
    'packages/module_labyrinth/assets/puzzles/module04.json',
  );
  return LabyrinthPuzzle.listFromJsonString(jsonString);
});

/// The [SaveService] used to persist this module's progress. Must be
/// overridden by the app shell with a concrete instance before any
/// module_labyrinth_ui widget is built. Named distinctly from the other
/// modules' save-service providers so the app shell can import all UI
/// packages without a symbol clash.
final Provider<SaveService> labyrinthSaveServiceProvider = Provider<SaveService>((ref) {
  throw UnimplementedError(
    'labyrinthSaveServiceProvider must be overridden with a concrete SaveService before use.',
  );
});

/// Loads the raw persisted save data for [labyrinthSaveNamespace] (shape:
/// `{"puzzles": {"<id>": {...}}}`). Used by the puzzle list screen and the
/// home-screen module card. Invalidate after returning from a puzzle screen
/// to pick up changes.
final FutureProvider<Map<String, dynamic>> labyrinthSaveDataProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  final saveService = ref.watch(labyrinthSaveServiceProvider);
  return saveService.load(labyrinthSaveNamespace);
});

/// The [AudioService] used to play SFX from this module's screens. Defaults
/// to a no-op; the app shell overrides this with its real [AudioService].
final Provider<AudioService> labyrinthAudioServiceProvider =
    Provider<AudioService>((ref) => const NoopAudioService());
