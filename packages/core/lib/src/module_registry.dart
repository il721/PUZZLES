import 'module_descriptor.dart';

/// In-memory registry of the puzzle modules available to the app.
///
/// Modules register themselves (typically during app startup) via
/// [register]. Registration order is preserved and is the order in which
/// modules are exposed through [modules] — the app shell renders them in
/// that order (e.g. a module picker screen).
class ModuleRegistry {
  final List<PuzzleModuleDescriptor> _modules = <PuzzleModuleDescriptor>[];

  /// Registers [d]. Throws a [StateError] if a module with the same [id]
  /// has already been registered.
  void register(PuzzleModuleDescriptor d) {
    for (final existing in _modules) {
      if (existing.id == d.id) {
        throw StateError('A module with id "${d.id}" is already registered.');
      }
    }
    _modules.add(d);
  }

  /// All registered modules, in registration order. The returned list is
  /// unmodifiable — callers must go through [register] to add modules.
  List<PuzzleModuleDescriptor> get modules => List.unmodifiable(_modules);
}
