import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_digit_rebus_ui/module_digit_rebus_ui.dart';
import 'package:module_domino_ui/module_domino_ui.dart';
import 'package:module_rebus_ui/module_rebus_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

import '../l10n/app_localizations.dart';
import '../providers.dart';

/// Language and sound preferences. Changes apply immediately and persist
/// via [SettingsService].
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageOverrideProvider);
    final soundOn = ref.watch(soundOnProvider);
    final theme = ref.watch(themeOverrideProvider);
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
          ListTile(title: Text(l10n.settingsTheme)),
          RadioGroup<String>(
            groupValue: theme,
            onChanged: (value) {
              if (value == null) return;
              ref.read(themeOverrideProvider.notifier).state = value;
              unawaited(settingsService.setTheme(value));
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text(l10n.themeDark),
                  value: 'dark',
                ),
                RadioListTile<String>(
                  title: Text(l10n.themeLight),
                  value: 'light',
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.settingsSyncSection),
            subtitle: Text(l10n.settingsSyncHint),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: Text(l10n.settingsExportProgress),
            onTap: _handleExport,
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: Text(l10n.settingsImportProgress),
            onTap: _handleImport,
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleExport() async {
    final l10n = AppLocalizations.of(context);
    final bundleService = ref.read(progressBundleServiceProvider);
    final transfer = ref.read(bundleTransferProvider);

    final jsonText = await bundleService.exportJson();
    final now = DateTime.now();
    final stamp = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final ok = await transfer.saveBundle(jsonText, 'puzzlebook-progress-$stamp.json');

    _showSnack(ok ? l10n.exportSuccess : l10n.exportFailed);
  }

  Future<void> _handleImport() async {
    final l10n = AppLocalizations.of(context);
    final bundleService = ref.read(progressBundleServiceProvider);
    final transfer = ref.read(bundleTransferProvider);

    final jsonText = await transfer.pickBundle();
    // Null means the user backed out of the file dialog — say nothing.
    if (jsonText == null) return;

    // Parse once up front purely to preview the bundle's date in the
    // confirmation dialog; the merge itself re-parses inside importJson.
    // decode() is pure and cheap, so paying for it twice is fine.
    final ProgressBundle preview;
    try {
      preview = ProgressBundle.decode(jsonText);
    } on BundleFormatException catch (e) {
      _showSnack(e.isVersionTooNew ? l10n.importFailedVersion : l10n.importFailedFormat);
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.importConfirmTitle),
        content: Text(l10n.importConfirmBody(preview.exportedAt)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.importConfirmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.importConfirmApply),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final report = await bundleService.importJson(jsonText);
    if (!report.ok) {
      _showSnack(
        report.error == ImportError.versionTooNew ? l10n.importFailedVersion : l10n.importFailedFormat,
      );
      return;
    }

    // Refresh the home screen's solved-counts so they reflect the just-
    // imported data. Deliberately do NOT invalidate the session provider
    // families here (rebusSessionProvider/puzzleSessionProvider/
    // digitRebusSessionProvider/dominoSessionProvider): invalidating a live
    // session triggers its onDispose flush, which would write that
    // session's stale in-memory state back over the progress that was just
    // imported. Only the read-only save-data providers are safe to touch.
    ref.invalidate(rebusSaveDataProvider);
    ref.invalidate(digitRebusSaveDataProvider);
    ref.invalidate(dominoSaveDataProvider);

    final changed = report.counts.added + report.counts.updated;
    _showSnack(
      changed == 0
          ? l10n.importNothingNew
          : l10n.importSuccess(report.counts.added, report.counts.updated),
    );
  }
}
