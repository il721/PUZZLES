/// Pure-Dart, UI-agnostic core contracts shared by all puzzle modules.
///
/// This library defines the seams between puzzle modules and the Flutter
/// app shell: module registration/discovery, persistence (save/settings),
/// audio, and logging. Nothing in this package imports Flutter — the
/// Flutter-specific bindings (UI entry builders, `path_provider` directory
/// resolution, real audio playback) are wired up in the app shell starting
/// at milestone M2.
library puzzle_core;

export 'src/audio_service.dart';
export 'src/logger.dart';
export 'src/module_descriptor.dart';
export 'src/module_registry.dart';
export 'src/progress_bundle.dart';
export 'src/progress_merge.dart';
export 'src/save_service.dart';
export 'src/settings_service.dart';
