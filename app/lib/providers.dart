import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'audio.dart';
import 'bundle_transfer.dart';

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

/// The app's [AudioService], backed by [AudioPlayersAudioService]. Reads
/// [soundOnProvider] fresh on every `play` call (rather than once at
/// construction) so toggling sound in Settings applies immediately.
final Provider<AudioService> audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioPlayersAudioService(isSoundOn: () => ref.read(soundOnProvider));
  ref.onDispose(service.dispose);
  return service;
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

/// The user's color-theme preference (`dark` or `light`), mirrored the same
/// way as [languageOverrideProvider].
final StateProvider<String> themeOverrideProvider = StateProvider<String>((ref) {
  return ref.watch(settingsServiceProvider).theme;
});

/// The app's [ProgressBundleService], built in `main` from the registered
/// modules' save namespaces and supplied here via an override. Exporting
/// only registered module namespaces is what keeps the `settings` namespace
/// (a per-device preference, not progress) out of every bundle.
final Provider<ProgressBundleService> progressBundleServiceProvider =
    Provider<ProgressBundleService>((ref) {
  throw UnimplementedError(
      'progressBundleServiceProvider must be overridden with a concrete ProgressBundleService before use.');
});

/// How bundle text reaches the file system. Overridden in `main` with
/// [FilePickerBundleTransfer]; widget tests override it with a fake so the
/// export/import flow can run without a native file dialog.
final Provider<BundleTransfer> bundleTransferProvider = Provider<BundleTransfer>((ref) {
  throw UnimplementedError(
      'bundleTransferProvider must be overridden with a concrete BundleTransfer before use.');
});
