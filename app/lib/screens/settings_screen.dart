import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers.dart';

/// Language and sound preferences. Changes apply immediately and persist
/// via [SettingsService].
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageOverrideProvider);
    final soundOn = ref.watch(soundOnProvider);
    final settingsService = ref.read(settingsServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.settingsLanguage),
            trailing: DropdownButton<String>(
              value: language,
              items: [
                DropdownMenuItem(value: 'system', child: Text(l10n.languageSystem)),
                DropdownMenuItem(value: 'ru', child: Text(l10n.languageRu)),
                DropdownMenuItem(value: 'en', child: Text(l10n.languageEn)),
                DropdownMenuItem(value: 'de', child: Text(l10n.languageDe)),
              ],
              onChanged: (value) {
                if (value == null) return;
                ref.read(languageOverrideProvider.notifier).state = value;
                unawaited(settingsService.setLanguage(value));
              },
            ),
          ),
          SwitchListTile(
            title: Text(l10n.settingsSound),
            value: soundOn,
            onChanged: (value) {
              ref.read(soundOnProvider.notifier).state = value;
              unawaited(settingsService.setSoundOn(value));
            },
          ),
        ],
      ),
    );
  }
}
