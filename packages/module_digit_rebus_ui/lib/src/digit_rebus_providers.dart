import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_digit_rebus/module_digit_rebus.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'digit_rebus_module.dart';

/// Loads every puzzle in Module 02 from its bundled JSON asset.
///
/// Overridable for tests (e.g. to load from a file directly instead of
/// `rootBundle`, which is unavailable/awkward in pure widget tests without
/// a full asset bundle set up).
final FutureProvider<List<DigitRebusPuzzle>> digitRebusPuzzlesProvider =
    FutureProvider<List<DigitRebusPuzzle>>((ref) async {
  final jsonString = await rootBundle.loadString(
    'packages/module_digit_rebus/assets/puzzles/module02.json',
  );
  return DigitRebusPuzzle.listFromJsonString(jsonString);
});

/// The [SaveService] used to persist this module's progress. Must be
/// overridden by the app shell with a concrete instance (backed by a real
/// `path_provider` directory) before any module_digit_rebus_ui widget is
/// built. Named distinctly from module_rebus_ui's `saveServiceProvider` so
/// the app shell can import both UI packages without a symbol clash.
final Provider<SaveService> digitRebusSaveServiceProvider = Provider<SaveService>((ref) {
  throw UnimplementedError(
    'digitRebusSaveServiceProvider must be overridden with a concrete SaveService before use.',
  );
});

/// Loads the raw persisted save data for [digitRebusSaveNamespace] (shape:
/// `{"puzzles": {"<id>": {...}}}`). Used by the puzzle list screen and the
/// home-screen module card to compute per-puzzle/solved-count status.
/// Invalidate this provider after returning from a puzzle screen to pick
/// up any changes made during that session.
final FutureProvider<Map<String, dynamic>> digitRebusSaveDataProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  final saveService = ref.watch(digitRebusSaveServiceProvider);
  return saveService.load(digitRebusSaveNamespace);
});

/// The [AudioService] used to play SFX from this module's screens. Defaults
/// to a no-op so pure module_digit_rebus_ui tests/tools don't need an audio
/// backend; the app shell overrides this with its real [AudioService]
/// instance (the same one behind its own `audioServiceProvider`).
final Provider<AudioService> digitRebusAudioServiceProvider =
    Provider<AudioService>((ref) => const NoopAudioService());
