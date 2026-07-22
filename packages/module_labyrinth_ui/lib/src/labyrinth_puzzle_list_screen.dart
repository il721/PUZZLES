import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'labyrinth_l10n.dart';
import 'labyrinth_providers.dart';
import 'labyrinth_puzzle_screen.dart';
import 'labyrinth_tutorial_screen.dart';

enum _PuzzleStatus { untouched, inProgress, solved }

_PuzzleStatus _statusFor(String id, Map<String, dynamic> saveData) {
  final puzzles = saveData['puzzles'];
  if (puzzles is! Map) return _PuzzleStatus.untouched;
  final entry = puzzles[id];
  if (entry is! Map) return _PuzzleStatus.untouched;
  return entry['solved'] == true ? _PuzzleStatus.solved : _PuzzleStatus.inProgress;
}

/// Lists the 18 playable puzzles (`p01`..`p18`; the tutorial puzzle
/// `example` is excluded), each tile showing its number and status.
class LabyrinthPuzzleListScreen extends ConsumerWidget {
  /// Creates the puzzle list screen.
  const LabyrinthPuzzleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(labyrinthL10nProvider);
    final puzzlesAsync = ref.watch(labyrinthPuzzlesProvider);
    final saveDataAsync = ref.watch(labyrinthSaveDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.puzzleListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.school_outlined),
            tooltip: l10n.tutorialTitle,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LabyrinthTutorialScreen()),
              );
            },
          ),
        ],
      ),
      body: puzzlesAsync.when(
        data: (puzzles) {
          final list = puzzles.where((p) => !p.tutorial).toList()
            ..sort((a, b) => a.id.compareTo(b.id));
          final saveData = saveDataAsync.value ?? const <String, dynamic>{};

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final puzzle = list[index];
              final number = int.parse(puzzle.id.substring(1));
              final status = _statusFor(puzzle.id, saveData);
              return _PuzzleTile(
                number: number,
                status: status,
                l10n: l10n,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => LabyrinthPuzzleScreen(puzzleId: puzzle.id)),
                  );
                  ref.invalidate(labyrinthSaveDataProvider);
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

class _PuzzleTile extends StatelessWidget {
  final int number;
  final _PuzzleStatus status;
  final LabyrinthL10n l10n;
  final VoidCallback onTap;

  const _PuzzleTile({
    required this.number,
    required this.status,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    IconData? icon;
    String semanticStatus;
    switch (status) {
      case _PuzzleStatus.untouched:
        icon = null;
        semanticStatus = l10n.statusUntouched;
      case _PuzzleStatus.inProgress:
        icon = Icons.edit_outlined;
        semanticStatus = l10n.statusInProgress;
      case _PuzzleStatus.solved:
        icon = Icons.check_circle;
        semanticStatus = l10n.statusSolved;
    }

    final background =
        status == _PuzzleStatus.solved ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final foreground =
        status == _PuzzleStatus.solved ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      label: '${l10n.puzzleN(number)}, $semanticStatus',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$number', style: theme.textTheme.headlineMedium?.copyWith(color: foreground)),
                const SizedBox(height: 6),
                SizedBox(
                  height: 26,
                  child: icon == null ? null : Icon(icon, color: foreground, size: 26),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
