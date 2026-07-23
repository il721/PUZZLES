import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:module_digit_rebus_ui/module_digit_rebus_ui.dart';
import 'package:module_domino_ui/module_domino_ui.dart';
import 'package:module_labyrinth_ui/module_labyrinth_ui.dart';
import 'package:module_rebus_ui/module_rebus_ui.dart';
import 'package:module_squareword_ui/module_squareword_ui.dart';

import '../l10n/app_localizations.dart';
import '../module_catalog.dart';

/// A module's solved count, its puzzle count, and the provider to refresh
/// once the player comes back from it.
typedef _ModuleProgress = ({int solved, int total, void Function() refresh});

/// The app's landing screen: title bar with Help and Settings, and a grid of
/// circular module tiles built from [moduleCatalog].
class HomeScreen extends ConsumerWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final progress = _progressByModuleId(ref);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Text(l10n.appTitle, overflow: TextOverflow.ellipsis),
            ),
            const Spacer(),
            IconButton(
              tooltip: l10n.homeHelpTooltip,
              icon: Icon(Icons.help, color: theme.colorScheme.primary),
              iconSize: 30,
              onPressed: () => Navigator.of(context).pushNamed('/help'),
            ),
            const Spacer(),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.homeSettingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisExtent: 210,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: moduleCatalog.length,
        itemBuilder: (context, index) {
          final entry = moduleCatalog[index];
          final moduleProgress = progress[entry.id];
          return _ModuleTile(
            title: entry.title(l10n),
            iconAsset: entry.iconFor(theme.brightness),
            progressLabel: moduleProgress == null
                ? null
                : l10n.homeModuleProgress(moduleProgress.solved, moduleProgress.total),
            onTap: () async {
              await Navigator.of(context).pushNamed(entry.route);
              moduleProgress?.refresh();
            },
          );
        },
      ),
    );
  }

  /// Reads every module's save data and puzzle list, keyed by
  /// [ModuleCatalogEntry.id]. A module missing from this map still gets a
  /// tile — just without a progress line.
  Map<String, _ModuleProgress> _progressByModuleId(WidgetRef ref) {
    return {
      'rebus': (
        solved: _countSolved(ref.watch(rebusSaveDataProvider).value),
        total: _countPuzzles(ref.watch(rebusPuzzlesProvider).value, 15),
        refresh: () => ref.invalidate(rebusSaveDataProvider),
      ),
      'digit_rebus': (
        solved: _countSolved(ref.watch(digitRebusSaveDataProvider).value),
        total: _countPuzzles(ref.watch(digitRebusPuzzlesProvider).value, 18),
        refresh: () => ref.invalidate(digitRebusSaveDataProvider),
      ),
      'domino': (
        solved: _countSolved(ref.watch(dominoSaveDataProvider).value),
        total: _countPuzzles(ref.watch(dominoPuzzlesProvider).value, 18),
        refresh: () => ref.invalidate(dominoSaveDataProvider),
      ),
      'labyrinth': (
        solved: _countSolved(ref.watch(labyrinthSaveDataProvider).value),
        total: _countPuzzles(ref.watch(labyrinthPuzzlesProvider).value, 18),
        refresh: () => ref.invalidate(labyrinthSaveDataProvider),
      ),
      'squareword': (
        solved: _countSolved(ref.watch(squarewordSaveDataProvider).value),
        total: _countPuzzles(ref.watch(squarewordPuzzlesProvider).value, 17),
        refresh: () => ref.invalidate(squarewordSaveDataProvider),
      ),
    };
  }

  /// Playable puzzles in [puzzles] (the tutorial one does not count), or
  /// [fallback] while the list is still loading.
  int _countPuzzles(List<dynamic>? puzzles, int fallback) {
    if (puzzles == null) return fallback;
    return puzzles.where((p) => (p as dynamic).tutorial != true).length;
  }

  int _countSolved(Map<String, dynamic>? saveData) {
    if (saveData == null) return 0;
    final puzzles = saveData['puzzles'];
    if (puzzles is! Map) return 0;
    return puzzles.values.whereType<Map>().where((entry) => entry['solved'] == true).length;
  }
}

/// A single circular module tile: artwork, name, and solved count.
class _ModuleTile extends StatelessWidget {
  final String title;
  final String iconAsset;
  final String? progressLabel;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.title,
    required this.iconAsset,
    required this.progressLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: SvgPicture.asset(iconAsset),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (progressLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                progressLabel!,
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
