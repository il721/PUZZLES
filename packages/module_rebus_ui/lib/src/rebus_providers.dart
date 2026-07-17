import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_rebus/module_rebus.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'rebus_module.dart';

/// Loads every puzzle in Module 01 from its bundled JSON asset.
///
/// Overridable for tests (e.g. to load from a file directly instead of
/// `rootBundle`, which is unavailable/awkward in pure widget tests without
/// a full asset bundle set up).
final FutureProvider<List<RebusPuzzle>> rebusPuzzlesProvider =
    FutureProvider<List<RebusPuzzle>>((ref) async {
  final jsonString = await rootBundle.loadString(
    'packages/module_rebus/assets/puzzles/module01.json',
  );
  return RebusPuzzle.listFromJsonString(jsonString);
});

/// The [SaveService] used to persist this module's progress. Must be
/// overridden by the app shell with a concrete instance (backed by a real
/// `path_provider` directory) before any module_rebus_ui widget is built.
final Provider<SaveService> saveServiceProvider = Provider<SaveService>((ref) {
  throw UnimplementedError(
    'saveServiceProvider must be overridden with a concrete SaveService before use.',
  );
});

/// Loads the raw persisted save data for [rebusSaveNamespace] (shape:
/// `{"puzzles": {"<id>": {...}}}`). Used by [PuzzleListScreen] to compute
/// each puzzle's status. Invalidate this provider after returning from a
/// puzzle screen to pick up any changes made during that session.
final FutureProvider<Map<String, dynamic>> rebusSaveDataProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  final saveService = ref.watch(saveServiceProvider);
  return saveService.load(rebusSaveNamespace);
});

/// The [AudioService] used to play SFX from this module's screens. Defaults
/// to a no-op so pure module_rebus_ui tests/tools don't need an audio
/// backend; the app shell overrides this with its real [AudioService]
/// instance (the same one behind its own `audioServiceProvider`).
final Provider<AudioService> rebusAudioServiceProvider = Provider<AudioService>((ref) => const NoopAudioService());
