import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_playground/module_playground.dart';
import 'package:module_playground_ui/module_playground_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

List<PlaygroundGame> _loadGames() {
  final file = File('../module_playground/assets/puzzles/module06.json');
  final data = PlaygroundData.fromJsonString(file.readAsStringSync());
  return buildPlaygroundRegistry(data);
}

void main() {
  late List<PlaygroundGame> games;
  late PlaygroundGame eightChips;
  late Directory tempDir;
  late SaveService saveService;

  setUpAll(() {
    games = _loadGames();
    eightChips = games.firstWhere((g) => g.id == 'eight_chips');
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('module_playground_ui_persistence_test_');
    saveService = SaveService(() => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(overrides: [
      playgroundPuzzlesProvider.overrideWith((ref) async => games),
      playgroundSaveServiceProvider.overrideWithValue(saveService),
    ]);
  }

  test('after a move, the written entry has moveStack/moveCount/solved/elapsedMs/updatedAt',
      () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(playgroundPuzzlesProvider.future);

    final sub = container.listen(playgroundSessionProvider('eight_chips'), (prev, next) {});
    addTearDown(sub.close);

    final notifier = container.read(playgroundSessionProvider('eight_chips').notifier);
    final initial = container.read(playgroundSessionProvider('eight_chips'));
    final legalMove = eightChips.legalMoves(initial.board).first;
    notifier.apply(legalMove);

    Map? entry;
    for (var i = 0; i < 50 && entry == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final saved = await saveService.load('module_playground');
      final pz = saved['puzzles'];
      if (pz is Map && pz['eight_chips'] is Map) entry = pz['eight_chips'] as Map;
    }

    expect(entry, isNotNull, reason: 'move never landed on disk');
    expect(entry!['moveStack'], isA<List>());
    expect((entry['moveStack'] as List), hasLength(1));
    expect(entry['moveCount'], 1);
    expect(entry['solved'], isFalse);
    expect(entry['elapsedMs'], isA<int>());
    expect(entry['updatedAt'], isA<int>());
  });

  test(
      'a save entry with a corrupt board is discarded WHOLE: fresh board, solved false, '
      'bestMoves null, empty stack — even with solved:true stored alongside it', () async {
    await saveService.save('module_playground', <String, dynamic>{
      'puzzles': <String, dynamic>{
        'eight_chips': <String, dynamic>{
          // 'positions' must be a map of exactly the board's node ids;
          // a bare string trips EightChipsGame.stateFromJson's very first
          // shape check and makes it return null.
          'positions': 'not-a-map',
          'moveStack': <dynamic>[],
          'moveCount': 0,
          'bestMoves': 5,
          'solved': true,
          'elapsedMs': 12345,
        },
      },
    });

    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(playgroundPuzzlesProvider.future);

    final sub = container.listen(playgroundSessionProvider('eight_chips'), (prev, next) {});
    addTearDown(sub.close);

    // Give the notifier's async _loadPersisted a chance to run and (not)
    // apply the corrupt entry.
    Map<String, dynamic>? finalState;
    for (var i = 0; i < 25; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final s = container.read(playgroundSessionProvider('eight_chips'));
      finalState = {'solved': s.solved, 'bestMoves': s.bestMoves, 'moveCount': s.moveCount};
      if (s.solved == false && s.bestMoves == null) break;
    }

    expect(finalState!['solved'], isFalse);
    expect(finalState['bestMoves'], isNull);
    expect(finalState['moveCount'], 0);

    final state = container.read(playgroundSessionProvider('eight_chips'));
    expect(state.board, equals(eightChips.initialState()));
  });
}
