import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_playground/module_playground.dart';
import 'package:puzzles/l10n/app_localizations.dart';
import 'package:puzzles/playground_l10n_adapter.dart';

/// Loads the module's real game registry, exactly as
/// `playground_home_screen_test.dart`'s `_loadGames` does.
List<PlaygroundGame> _loadGames() {
  final file = File('../packages/module_playground/assets/puzzles/module06.json');
  final data = PlaygroundData.fromJsonString(file.readAsStringSync());
  return buildPlaygroundRegistry(data);
}

void main() {
  test(
    'every enabled playground game has a non-empty title and rules text',
    () {
      final l10n = lookupAppLocalizations(const Locale('ru'));
      final adapter = AppPlaygroundL10n(l10n);
      final enabledGames = _loadGames().where((game) => game.enabled);

      // Guards against a future game shipping (enabled: true) before its
      // gameTitle/gameRules case is wired into the adapter, which would
      // otherwise silently show an empty ℹ sheet.
      expect(enabledGames, isNotEmpty);
      for (final game in enabledGames) {
        expect(
          adapter.gameTitle(game.id),
          isNotEmpty,
          reason: '${game.id} has an empty gameTitle',
        );
        expect(
          adapter.gameRules(game.id),
          isNotEmpty,
          reason: '${game.id} has an empty gameRules',
        );
      }
    },
  );
}
