import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_rebus_ui/module_rebus_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'l10n/app_localizations.dart';
import 'providers.dart';
import 'rebus_l10n_adapter.dart';
import 'screens/help_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

/// Material 3 seed color shared by the light and dark themes — a calm,
/// desaturated teal.
const Color _seedColor = Color(0xFF2E6E62);

/// The app's root widget: theme, localization, and routing.
class PuzzleBookApp extends ConsumerWidget {
  /// Creates the app.
  const PuzzleBookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageOverride = ref.watch(languageOverrideProvider);
    final localeOverride = languageOverride == SettingsService.defaultLanguage ? null : Locale(languageOverride);

    return MaterialApp(
      title: 'Puzzle Book',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.light),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark),
      ),
      themeMode: ThemeMode.system,
      locale: localeOverride,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeListResolutionCallback: (locales, supported) {
        if (localeOverride != null) return localeOverride;
        final deviceCode = (locales != null && locales.isNotEmpty) ? locales.first.languageCode : null;
        return Locale(SettingsService.resolveLanguage(deviceCode));
      },
      // Wraps the routed content in a nested ProviderScope that overrides
      // `rebusL10nProvider` with an adapter over this MaterialApp's
      // resolved `AppLocalizations` — module_rebus_ui cannot depend on
      // this app's generated localization class directly (that would be a
      // circular package dependency), so it is supplied here instead.
      // Providers not overridden in this nested scope (save service,
      // puzzle data, ...) still resolve from the root ProviderScope.
      builder: (context, child) {
        return ProviderScope(
          overrides: [
            rebusL10nProvider.overrideWithValue(AppRebusL10n(AppLocalizations.of(context))),
          ],
          child: child!,
        );
      },
      routes: {
        '/': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/help': (context) => const HelpScreen(),
        '/module/rebus': (context) => const PuzzleListScreen(),
      },
    );
  }
}
