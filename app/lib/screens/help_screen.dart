import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Static game-rules explanation.
class HelpScreen extends StatelessWidget {
  /// Creates the help screen.
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.helpBody, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
