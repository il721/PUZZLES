/// Static, UI-agnostic description of a puzzle module.
///
/// A [PuzzleModuleDescriptor] is the piece of metadata a puzzle module
/// contributes to the app shell so it can be listed, localized, and
/// launched. It intentionally carries no widget/builder references: UI
/// entry builders (the function that actually creates the module's Flutter
/// screen) are bound separately in the Flutter layer starting at milestone
/// M2, so that this package — and the puzzle logic packages that depend on
/// it — stay entirely UI-agnostic.
class PuzzleModuleDescriptor {
  /// Stable, globally-unique identifier for the module (e.g. `module01_rebus`).
  final String id;

  /// Namespace used when persisting this module's save data via
  /// [SaveService]. Distinct from [id] so the two can evolve independently
  /// (e.g. a module rename need not migrate save files).
  final String saveNamespace;

  /// Localization key for the module's display title.
  final String titleKey;

  /// Localization key for the module's short description.
  final String descriptionKey;

  /// Package-qualified asset path for the module's icon
  /// (e.g. `packages/module_rebus/assets/icon.png`).
  final String iconAsset;

  /// Creates a const, immutable module descriptor.
  const PuzzleModuleDescriptor({
    required this.id,
    required this.saveNamespace,
    required this.titleKey,
    required this.descriptionKey,
    required this.iconAsset,
  });
}
