import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_playground/module_playground.dart';

import 'playground_game_screen.dart';
import 'playground_l10n.dart';
import 'playground_providers.dart';

enum _GameStatus { untouched, inProgress, solved }

Map? _entryFor(String gameId, Map<String, dynamic> saveData) {
  final puzzles = saveData['puzzles'];
  if (puzzles is! Map) return null;
  final entry = puzzles[gameId];
  return entry is Map ? entry : null;
}

_GameStatus _statusFor(Map? entry) {
  if (entry == null) return _GameStatus.untouched;
  return entry['solved'] == true ? _GameStatus.solved : _GameStatus.inProgress;
}

/// Whether [bestMoves] matches or beats [game]'s recorded par at all (proven
/// or book-claimed) — the shared condition behind both the
/// [PlaygroundL10n.optimalBadge] and [PlaygroundL10n.bookMatchedBadge] rows,
/// and behind the win dialog's `winBodyOptimal` choice. Null-safe: three of
/// the seven games have no par at all.
bool _matchesPar(PlaygroundGame game, int? bestMoves) {
  final par = game.par;
  if (par == null || bestMoves == null) return false;
  return bestMoves <= par;
}

/// Lists the module's seven games in registry order, each row showing its
/// title and status. Disabled (not-yet-shipped) rows are greyed out,
/// non-tappable, and show [PlaygroundL10n.comingSoon] instead of a status.
class PlaygroundListScreen extends ConsumerWidget {
  /// Creates the game list screen.
  const PlaygroundListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(playgroundL10nProvider);
    final gamesAsync = ref.watch(playgroundPuzzlesProvider);
    final saveDataAsync = ref.watch(playgroundSaveDataProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.listTitle)),
      body: gamesAsync.when(
        data: (games) {
          final saveData = saveDataAsync.value ?? const <String, dynamic>{};
          return ListView.builder(
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return _GameRow(
                game: game,
                l10n: l10n,
                entry: _entryFor(game.id, saveData),
                onTap: !game.enabled
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PlaygroundGameScreen(gameId: game.id),
                          ),
                        );
                        ref.invalidate(playgroundSaveDataProvider);
                      },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
      ),
    );
  }
}

class _GameRow extends StatelessWidget {
  final PlaygroundGame game;
  final PlaygroundL10n l10n;
  final Map? entry;
  final VoidCallback? onTap;

  const _GameRow({
    required this.game,
    required this.l10n,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _statusFor(entry);
    final bestMoves = (entry?['bestMoves'] as num?)?.toInt();

    Widget trailing;
    if (!game.enabled) {
      trailing = Text(l10n.comingSoon, style: theme.textTheme.bodyMedium);
    } else {
      final lines = <Widget>[Text(_statusLabel(status))];
      if (status == _GameStatus.solved && bestMoves != null) {
        lines.add(Text(l10n.recordLine(bestMoves)));
        if (_matchesPar(game, bestMoves)) {
          lines.add(Text(
            game.parProven ? l10n.optimalBadge : l10n.bookMatchedBadge,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
          ));
        }
      }
      trailing = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: lines,
      );
    }

    return Opacity(
      opacity: game.enabled ? 1.0 : 0.5,
      child: ListTile(
        key: ValueKey('pg-row-${game.id}'),
        enabled: game.enabled,
        title: Text(l10n.gameTitle(game.id)),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  String _statusLabel(_GameStatus status) {
    switch (status) {
      case _GameStatus.untouched:
        return l10n.statusUntouched;
      case _GameStatus.inProgress:
        return l10n.statusInProgress;
      case _GameStatus.solved:
        return l10n.statusSolved;
    }
  }
}
