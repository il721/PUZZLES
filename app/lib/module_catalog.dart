import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

/// One puzzle module as the shell presents it: its artwork, its route and the
/// three pieces of text shown about it.
///
/// [moduleCatalog] is the single place the shell learns about a module. Adding
/// a module means adding one entry here — the home screen grid and the help
/// screen both build themselves from this list.
@immutable
class ModuleCatalogEntry {
  /// Stable identifier the home screen uses to look up this module's progress.
  final String id;

  /// Named route that opens the module's puzzle list.
  final String route;

  /// SVG asset used in dark theme (the default).
  final String iconAsset;

  /// SVG asset used in light theme.
  final String iconAssetLight;

  /// Module name, e.g. on the home tile and as the help entry's heading.
  final String Function(AppLocalizations l10n) title;

  /// One-line summary, shown in the help screen.
  final String Function(AppLocalizations l10n) description;

  /// Full rules paragraph, shown in the help screen.
  final String Function(AppLocalizations l10n) rules;

  const ModuleCatalogEntry({
    required this.id,
    required this.route,
    required this.iconAsset,
    required this.iconAssetLight,
    required this.title,
    required this.description,
    required this.rules,
  });

  /// The icon variant matching [brightness].
  String iconFor(Brightness brightness) =>
      brightness == Brightness.light ? iconAssetLight : iconAsset;
}

/// Every puzzle module, in the order the player sees them.
const List<ModuleCatalogEntry> moduleCatalog = [
  ModuleCatalogEntry(
    id: 'rebus',
    route: '/module/rebus',
    iconAsset: 'assets/icons/icon_01.svg',
    iconAssetLight: 'assets/icons/icon_01_light.svg',
    title: _rebusTitle,
    description: _rebusDescription,
    rules: _rebusRules,
  ),
  ModuleCatalogEntry(
    id: 'digit_rebus',
    route: '/module/digit_rebus',
    iconAsset: 'assets/icons/icon_02.svg',
    iconAssetLight: 'assets/icons/icon_02_light.svg',
    title: _digitRebusTitle,
    description: _digitRebusDescription,
    rules: _digitRebusRules,
  ),
  ModuleCatalogEntry(
    id: 'domino',
    route: '/module/domino',
    iconAsset: 'assets/icons/icon_03.svg',
    iconAssetLight: 'assets/icons/icon_03_light.svg',
    title: _dominoTitle,
    description: _dominoDescription,
    rules: _dominoRules,
  ),
  ModuleCatalogEntry(
    id: 'labyrinth',
    route: '/module/labyrinth',
    iconAsset: 'assets/icons/icon_04.svg',
    iconAssetLight: 'assets/icons/icon_04_light.svg',
    title: _labyrinthTitle,
    description: _labyrinthDescription,
    rules: _labyrinthRules,
  ),
  ModuleCatalogEntry(
    id: 'squareword',
    route: '/module/squareword',
    iconAsset: 'assets/icons/icon_05.svg',
    iconAssetLight: 'assets/icons/icon_05_light.svg',
    title: _squarewordTitle,
    description: _squarewordDescription,
    rules: _squarewordRules,
  ),
  ModuleCatalogEntry(
    id: 'playground',
    route: '/module/playground',
    iconAsset: 'assets/icons/icon_06.svg',
    iconAssetLight: 'assets/icons/icon_06_light.svg',
    title: _playgroundTitle,
    description: _playgroundDescription,
    rules: _playgroundRules,
  ),
];

// Top-level tear-offs: const entries cannot hold closures.
String _rebusTitle(AppLocalizations l10n) => l10n.moduleRebusTitle;
String _rebusDescription(AppLocalizations l10n) => l10n.moduleRebusDescription;
String _rebusRules(AppLocalizations l10n) => l10n.helpRulesRebus;

String _digitRebusTitle(AppLocalizations l10n) => l10n.moduleDigitRebusTitle;
String _digitRebusDescription(AppLocalizations l10n) => l10n.moduleDigitRebusDescription;
String _digitRebusRules(AppLocalizations l10n) => l10n.helpRulesDigitRebus;

String _dominoTitle(AppLocalizations l10n) => l10n.moduleDominoTitle;
String _dominoDescription(AppLocalizations l10n) => l10n.moduleDominoDescription;
String _dominoRules(AppLocalizations l10n) => l10n.helpRulesDomino;

String _labyrinthTitle(AppLocalizations l10n) => l10n.moduleLabyrinthTitle;
String _labyrinthDescription(AppLocalizations l10n) => l10n.moduleLabyrinthDescription;
String _labyrinthRules(AppLocalizations l10n) => l10n.helpRulesLabyrinth;

String _squarewordTitle(AppLocalizations l10n) => l10n.moduleSquarewordTitle;
String _squarewordDescription(AppLocalizations l10n) => l10n.moduleSquarewordDescription;
String _squarewordRules(AppLocalizations l10n) => l10n.helpRulesSquareword;

String _playgroundTitle(AppLocalizations l10n) => l10n.modulePlaygroundTitle;
String _playgroundDescription(AppLocalizations l10n) => l10n.modulePlaygroundDescription;
String _playgroundRules(AppLocalizations l10n) => l10n.helpRulesPlayground;
