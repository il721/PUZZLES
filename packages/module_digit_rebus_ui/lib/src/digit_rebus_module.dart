import 'package:puzzle_core/puzzle_core.dart';

/// The save-data namespace this module persists under via [SaveService].
const String digitRebusSaveNamespace = 'module_digit_rebus';

/// Static metadata for the "digit rebus" puzzle module, for registration
/// with the app shell's [ModuleRegistry].
class DigitRebusModule {
  DigitRebusModule._();

  /// The module's descriptor, registered by the app shell.
  static const PuzzleModuleDescriptor descriptor = PuzzleModuleDescriptor(
    id: 'module02_digit_rebus',
    saveNamespace: digitRebusSaveNamespace,
    titleKey: 'moduleDigitRebusTitle',
    descriptionKey: 'moduleDigitRebusDescription',
    iconAsset: '',
  );
}
