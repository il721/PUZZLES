import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../module_catalog.dart';

/// The rules of every puzzle module, one entry per module, built from
/// [moduleCatalog].
class HelpScreen extends StatelessWidget {
  /// Creates the help screen.
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpTitle)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: moduleCatalog.length,
        separatorBuilder: (context, index) => const Divider(height: 40),
        itemBuilder: (context, index) => _ModuleHelpEntry(entry: moduleCatalog[index]),
      ),
    );
  }
}

class _ModuleHelpEntry extends StatelessWidget {
  final ModuleCatalogEntry entry;

  const _ModuleHelpEntry({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: SvgPicture.asset(entry.iconFor(theme.brightness)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(entry.title(l10n), style: theme.textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          entry.description(l10n),
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 8),
        Text(entry.rules(l10n), style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
