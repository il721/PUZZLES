import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_domino/module_domino.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'domino_module.dart';

/// Loads every puzzle in Module 03 from its bundled JSON asset.
///
/// Overridable for tests (e.g. to load from a file directly instead of
/// `rootBundle`).
final FutureProvider<List<DominoPuzzle>> dominoPuzzlesProvider =
    FutureProvider<List<DominoPuzzle>>((ref) async {
  final jsonString = await rootBundle.loadString(
    'packages/module_domino/assets/puzzles/module03.json',
  );
  return DominoPuzzle.listFromJsonString(jsonString);
});

/// The [SaveService] used to persist this module's progress. Must be
/// overridden by the app shell with a concrete instance before any
/// module_domino_ui widget is built. Named distinctly from the other
/// modules' save-service providers so the app shell can import all UI
/// packages without a symbol clash.
final Provider<SaveService> dominoSaveServiceProvider = Provider<SaveService>((ref) {
  throw UnimplementedError(
    'dominoSaveServiceProvider must be overridden with a concrete SaveService before use.',
  );
});

/// Loads the raw persisted save data for [dominoSaveNamespace] (shape:
/// `{"puzzles": {"<id>": {...}}}`). Used by the puzzle list screen and the
/// home-screen module card. Invalidate after returning from a puzzle screen
/// to pick up changes.
final FutureProvider<Map<String, dynamic>> dominoSaveDataProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  final saveService = ref.watch(dominoSaveServiceProvider);
  return saveService.load(dominoSaveNamespace);
});

/// The [AudioService] used to play SFX from this module's screens. Defaults
/// to a no-op; the app shell overrides this with its real [AudioService].
final Provider<AudioService> dominoAudioServiceProvider =
    Provider<AudioService>((ref) => const NoopAudioService());
