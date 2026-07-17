import 'package:puzzle_core/puzzle_core.dart';

/// The save-data namespace this module persists under via [SaveService].
const String rebusSaveNamespace = 'module_rebus';

/// Static metadata for the "rebus" arithmetic-square puzzle module, for
/// registration with the app shell's [ModuleRegistry].
class RebusModule {
  RebusModule._();

  /// The module's descriptor, registered by the app shell.
  static const PuzzleModuleDescriptor descriptor = PuzzleModuleDescriptor(
    id: 'module01_rebus',
    saveNamespace: rebusSaveNamespace,
    titleKey: 'moduleRebusTitle',
    descriptionKey: 'moduleRebusDescription',
    iconAsset: '',
  );
}
