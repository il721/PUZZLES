import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  const moduleA = PuzzleModuleDescriptor(
    id: 'a',
    saveNamespace: 'a',
    titleKey: 'a.title',
    descriptionKey: 'a.description',
    iconAsset: 'packages/module_a/assets/icon.png',
  );
  const moduleB = PuzzleModuleDescriptor(
    id: 'b',
    saveNamespace: 'b',
    titleKey: 'b.title',
    descriptionKey: 'b.description',
    iconAsset: 'packages/module_b/assets/icon.png',
  );

  test('modules are returned in registration order', () {
    final registry = ModuleRegistry();
    registry.register(moduleA);
    registry.register(moduleB);

    expect(registry.modules.map((m) => m.id).toList(), ['a', 'b']);
  });

  test('registering a duplicate id throws StateError', () {
    final registry = ModuleRegistry();
    registry.register(moduleA);

    expect(() => registry.register(moduleA), throwsStateError);
  });

  test('the modules list is unmodifiable', () {
    final registry = ModuleRegistry();
    registry.register(moduleA);

    expect(() => registry.modules.add(moduleB), throwsUnsupportedError);
  });
}
