import 'package:puzzle_core/puzzle_core.dart';

/// The save-data namespace this module persists under via [SaveService].
const String squarewordSaveNamespace = 'module_squareword';

/// Static metadata for the "squareword" puzzle module, for registration
/// with the app shell's [ModuleRegistry].
class SquarewordModule {
  SquarewordModule._();

  /// The module's descriptor, registered by the app shell.
  static const PuzzleModuleDescriptor descriptor = PuzzleModuleDescriptor(
    id: 'module05_squareword',
    saveNamespace: squarewordSaveNamespace,
    titleKey: 'moduleSquarewordTitle',
    descriptionKey: 'moduleSquarewordDescription',
    iconAsset: '',
  );
}
