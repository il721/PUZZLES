import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:module_digit_rebus_ui/module_digit_rebus_ui.dart';
import 'package:module_domino_ui/module_domino_ui.dart';
import 'package:module_labyrinth_ui/module_labyrinth_ui.dart';
import 'package:module_rebus_ui/module_rebus_ui.dart';

import '../l10n/app_localizations.dart';

/// The app's landing screen: title, module cards (progress + tap to
/// open), and icon buttons to Settings and Help.
class HomeScreen extends ConsumerWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final puzzlesAsync = ref.watch(rebusPuzzlesProvider);
    final saveDataAsync = ref.watch(rebusSaveDataProvider);

    final digitPuzzlesAsync = ref.watch(digitRebusPuzzlesProvider);
    final digitSaveDataAsync = ref.watch(digitRebusSaveDataProvider);

    final dominoPuzzlesAsync = ref.watch(dominoPuzzlesProvider);
    final dominoSaveDataAsync = ref.watch(dominoSaveDataProvider);

    final labyrinthPuzzlesAsync = ref.watch(labyrinthPuzzlesProvider);
    final labyrinthSaveDataAsync = ref.watch(labyrinthSaveDataProvider);

    final total = puzzlesAsync.value?.where((p) => !p.tutorial).length ?? 15;
    final solved = _countSolved(saveDataAsync.value);
    final digitTotal = digitPuzzlesAsync.value?.where((p) => !p.tutorial).length ?? 18;
    final digitSolved = _countSolved(digitSaveDataAsync.value);
    final dominoTotal = dominoPuzzlesAsync.value?.where((p) => !p.tutorial).length ?? 18;
    final dominoSolved = _countSolved(dominoSaveDataAsync.value);
    final labyrinthTotal = labyrinthPuzzlesAsync.value?.where((p) => !p.tutorial).length ?? 18;
    final labyrinthSolved = _countSolved(labyrinthSaveDataAsync.value);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.homeSettingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
          IconButton(
            tooltip: l10n.homeHelpTooltip,
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context).pushNamed('/help'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ModuleCard(
            title: l10n.moduleRebusTitle,
            description: l10n.moduleRebusDescription,
            progressLabel: l10n.homeModuleProgress(solved, total),
            iconAsset: 'assets/icons/icon_01.svg',
            iconAssetLight: 'assets/icons/icon_01_light.svg',
            onTap: () async {
              await Navigator.of(context).pushNamed('/module/rebus');
              ref.invalidate(rebusSaveDataProvider);
            },
          ),
          const SizedBox(height: 12),
          _ModuleCard(
            title: l10n.moduleDigitRebusTitle,
            description: l10n.moduleDigitRebusDescription,
            progressLabel: l10n.homeModuleProgress(digitSolved, digitTotal),
            iconAsset: 'assets/icons/icon_02.svg',
            iconAssetLight: 'assets/icons/icon_02_light.svg',
            onTap: () async {
              await Navigator.of(context).pushNamed('/module/digit_rebus');
              ref.invalidate(digitRebusSaveDataProvider);
            },
          ),
          const SizedBox(height: 12),
          _ModuleCard(
            title: l10n.moduleDominoTitle,
            description: l10n.moduleDominoDescription,
            progressLabel: l10n.homeModuleProgress(dominoSolved, dominoTotal),
            iconAsset: 'assets/icons/icon_03.svg',
            iconAssetLight: 'assets/icons/icon_03_light.svg',
            onTap: () async {
              await Navigator.of(context).pushNamed('/module/domino');
              ref.invalidate(dominoSaveDataProvider);
            },
          ),
          const SizedBox(height: 12),
          _ModuleCard(
            title: l10n.moduleLabyrinthTitle,
            description: l10n.moduleLabyrinthDescription,
            progressLabel: l10n.homeModuleProgress(labyrinthSolved, labyrinthTotal),
            iconAsset: 'assets/icons/icon_04.svg',
            iconAssetLight: 'assets/icons/icon_04_light.svg',
            onTap: () async {
              await Navigator.of(context).pushNamed('/module/labyrinth');
              ref.invalidate(labyrinthSaveDataProvider);
            },
          ),
        ],
      ),
    );
  }

  int _countSolved(Map<String, dynamic>? saveData) {
    if (saveData == null) return 0;
    final puzzles = saveData['puzzles'];
    if (puzzles is! Map) return 0;
    return puzzles.values.whereType<Map>().where((entry) => entry['solved'] == true).length;
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String description;
  final String progressLabel;

  /// SVG asset path used when the app is in dark theme (the default).
  final String iconAsset;

  /// SVG asset path used when the app is in light theme.
  final String iconAssetLight;

  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.description,
    required this.progressLabel,
    required this.iconAsset,
    required this.iconAssetLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedIconAsset = theme.brightness == Brightness.light ? iconAssetLight : iconAsset;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: SvgPicture.asset(resolvedIconAsset),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(description, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text(
                      progressLabel,
                      style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
