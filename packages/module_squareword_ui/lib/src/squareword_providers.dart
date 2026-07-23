import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_squareword/module_squareword.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'squareword_module.dart';

/// Loads every puzzle in Module 05 from its bundled JSON asset.
///
/// Overridable for tests (e.g. to load from a file directly instead of
/// `rootBundle`).
final FutureProvider<List<SquarewordPuzzle>> squarewordPuzzlesProvider =
    FutureProvider<List<SquarewordPuzzle>>((ref) async {
  final jsonString = await rootBundle.loadString(
    'packages/module_squareword/assets/puzzles/module05.json',
  );
  return SquarewordPuzzle.listFromJsonString(jsonString);
});

/// The [SaveService] used to persist this module's progress. Must be
/// overridden by the app shell with a concrete instance before any
/// module_squareword_ui widget is built. Named distinctly from the other
/// modules' save-service providers so the app shell can import all UI
/// packages without a symbol clash.
final Provider<SaveService> squarewordSaveServiceProvider = Provider<SaveService>((ref) {
  throw UnimplementedError(
    'squarewordSaveServiceProvider must be overridden with a concrete SaveService before use.',
  );
});

/// Loads the raw persisted save data for [squarewordSaveNamespace] (shape:
/// `{"puzzles": {"<id>": {...}}}`). Used by the puzzle list screen and the
/// home-screen module card. Invalidate after returning from a puzzle screen
/// to pick up changes.
final FutureProvider<Map<String, dynamic>> squarewordSaveDataProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  final saveService = ref.watch(squarewordSaveServiceProvider);
  return saveService.load(squarewordSaveNamespace);
});

/// The [AudioService] used to play SFX from this module's screens. Defaults
/// to a no-op; the app shell overrides this with its real [AudioService].
final Provider<AudioService> squarewordAudioServiceProvider =
    Provider<AudioService>((ref) => const NoopAudioService());
