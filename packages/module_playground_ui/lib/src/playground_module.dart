import 'package:puzzle_core/puzzle_core.dart';

/// The save-data namespace this module persists under via [SaveService].
const String playgroundSaveNamespace = 'module_playground';

/// Static metadata for the "playground" puzzle module, for registration
/// with the app shell's [ModuleRegistry].
class PlaygroundModule {
  PlaygroundModule._();

  /// The module's descriptor, registered by the app shell.
  static const PuzzleModuleDescriptor descriptor = PuzzleModuleDescriptor(
    id: 'module06_playground',
    saveNamespace: playgroundSaveNamespace,
    titleKey: 'modulePlaygroundTitle',
    descriptionKey: 'modulePlaygroundDescription',
    iconAsset: '',
  );
}
