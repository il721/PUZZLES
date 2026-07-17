import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:puzzle_core/puzzle_core.dart';

/// The app's [SettingsService], initialized in `main` before [runApp] and
/// supplied here via an override.
final Provider<SettingsService> settingsServiceProvider = Provider<SettingsService>((ref) {
  throw UnimplementedError('settingsServiceProvider must be overridden with a concrete SettingsService before use.');
});

/// The app's [ModuleRegistry], populated in `main` before [runApp] and
/// supplied here via an override.
final Provider<ModuleRegistry> moduleRegistryProvider = Provider<ModuleRegistry>((ref) {
  throw UnimplementedError('moduleRegistryProvider must be overridden with a concrete ModuleRegistry before use.');
});

/// The app's [AudioService]. Real SFX playback (via `audioplayers`) is
/// wired up in milestone M4; for now this is always a no-op.
final Provider<AudioService> audioServiceProvider = Provider<AudioService>((ref) {
  return const NoopAudioService();
});

/// The user's language preference: `system`, `ru`, `en`, or `de`. Seeded
/// from the persisted [SettingsService] value and updated immediately (and
/// persisted) when the player changes it in Settings, so the UI reacts
/// without needing an app restart.
final StateProvider<String> languageOverrideProvider = StateProvider<String>((ref) {
  return ref.watch(settingsServiceProvider).language;
});

/// The user's sound-effects preference, mirrored the same way as
/// [languageOverrideProvider].
final StateProvider<bool> soundOnProvider = StateProvider<bool>((ref) {
  return ref.watch(settingsServiceProvider).soundOn;
});
