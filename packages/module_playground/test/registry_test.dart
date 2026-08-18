import 'package:module_playground/module_playground.dart';
import 'package:test/test.dart';

void main() {
  final registry = buildPlaygroundRegistry(
    const PlaygroundData(schemaVersion: 1, module: 'playground', games: []),
  );

  test('seven games, in the exact fixed order', () {
    expect(registry.map((g) => g.id).toList(), [
      'eight_chips',
      'cats_dogs',
      'hourglass',
      'three_each',
      'patterns5',
      'patterns4',
      'swap_blocks',
    ]);
  });

  test('ids are pairwise unique', () {
    final ids = registry.map((g) => g.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('exactly two enabled games: eight_chips, cats_dogs', () {
    final enabledIds =
        registry.where((g) => g.enabled).map((g) => g.id).toList();
    expect(enabledIds, ['eight_chips', 'cats_dogs']);
  });

  test('every game reports tutorial == false', () {
    for (final game in registry) {
      expect(game.tutorial, isFalse, reason: game.id);
    }
  });

  test('every disabled game throws UnimplementedError from initialState()',
      () {
    for (final game in registry.where((g) => !g.enabled)) {
      expect(
        () => game.initialState(),
        throwsA(isA<UnimplementedError>()),
        reason: game.id,
      );
    }
  });
}
