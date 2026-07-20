import 'package:puzzle_core/puzzle_core.dart';

/// The save-data namespace this module persists under via [SaveService].
const String dominoSaveNamespace = 'module_domino';

/// Static metadata for the "domino solitaire" puzzle module, for
/// registration with the app shell's [ModuleRegistry].
class DominoModule {
  DominoModule._();

  /// The module's descriptor, registered by the app shell.
  static const PuzzleModuleDescriptor descriptor = PuzzleModuleDescriptor(
    id: 'module03_domino',
    saveNamespace: dominoSaveNamespace,
    titleKey: 'moduleDominoTitle',
    descriptionKey: 'moduleDominoDescription',
    iconAsset: '',
  );
}
