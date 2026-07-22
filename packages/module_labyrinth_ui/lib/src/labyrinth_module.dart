import 'package:puzzle_core/puzzle_core.dart';

/// The save-data namespace this module persists under via [SaveService].
const String labyrinthSaveNamespace = 'module_labyrinth';

/// Static metadata for the "alphabet labyrinth" puzzle module, for
/// registration with the app shell's [ModuleRegistry].
class LabyrinthModule {
  LabyrinthModule._();

  /// The module's descriptor, registered by the app shell.
  static const PuzzleModuleDescriptor descriptor = PuzzleModuleDescriptor(
    id: 'module04_labyrinth',
    saveNamespace: labyrinthSaveNamespace,
    titleKey: 'moduleLabyrinthTitle',
    descriptionKey: 'moduleLabyrinthDescription',
    iconAsset: '',
  );
}
