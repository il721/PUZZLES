import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_digit_rebus_ui/module_digit_rebus_ui.dart';
import 'package:module_domino_ui/module_domino_ui.dart';
import 'package:module_labyrinth_ui/module_labyrinth_ui.dart';
import 'package:module_rebus_ui/module_rebus_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'digit_rebus_l10n_adapter.dart';
import 'domino_l10n_adapter.dart';
import 'l10n/app_localizations.dart';
import 'labyrinth_l10n_adapter.dart';
import 'providers.dart';
import 'rebus_l10n_adapter.dart';
import 'screens/help_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

/// Material 3 seed color shared by the light and dark themes, per
/// DESIGN.md's "Modern Dark" palette — the primary accent blue.
const Color _seedColor = Color(0xFF2B79C2);

/// DESIGN.md "Modern Dark" background/surface color.
const Color _darkSurface = Color(0xFF1E1E1E);

/// DESIGN.md "Modern Dark" primary text color.
const Color _darkOnSurface = Color(0xFFE6E6E6);

/// DESIGN.md "Modern Dark" secondary text color.
const Color _darkOnSurfaceVariant = Color(0xFF969696);

/// DESIGN.md "Modern Dark" standard button background.
const Color _darkButtonBackground = Color(0xFF3C3C3C);

/// Shared corner radius for buttons and cards, per DESIGN.md's 10-15px
/// rounded-corner guidance.
const double _cornerRadius = 12;

/// Button and card theming shared by the light and dark themes: rounded
/// corners per DESIGN.md.
ThemeData _applySharedShapeThemes(ThemeData base) {
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cornerRadius));
  return base.copyWith(
    cardTheme: base.cardTheme.copyWith(shape: shape),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: shape)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: shape)),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: shape)),
    iconTheme: base.iconTheme.copyWith(size: 28),
    appBarTheme: base.appBarTheme.copyWith(
      iconTheme: const IconThemeData(size: 28),
      actionsIconTheme: const IconThemeData(size: 28),
    ),
  );
}

/// The app's root widget: theme, localization, and routing.
class PuzzleBookApp extends ConsumerWidget {
  /// Creates the app.
  const PuzzleBookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageOverride = ref.watch(languageOverrideProvider);
    final localeOverride = languageOverride == SettingsService.defaultLanguage ? null : Locale(languageOverride);
    final themeOverride = ref.watch(themeOverrideProvider);

    return MaterialApp(
      title: 'Puzzle Book',
      debugShowCheckedModeBanner: false,
      theme: _applySharedShapeThemes(ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.light),
      )),
      darkTheme: _applySharedShapeThemes(ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark).copyWith(
          surface: _darkSurface,
          onSurface: _darkOnSurface,
          onSurfaceVariant: _darkOnSurfaceVariant,
          primary: _seedColor,
          surfaceContainerHighest: _darkButtonBackground,
        ),
        scaffoldBackgroundColor: _darkSurface,
        dialogTheme: const DialogThemeData(backgroundColor: _darkSurface),
      )),
      // Dark is the default; never ThemeMode.system, per DESIGN.md.
      themeMode: themeOverride == 'light' ? ThemeMode.light : ThemeMode.dark,
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
            rebusAudioServiceProvider.overrideWithValue(ref.watch(audioServiceProvider)),
            digitRebusL10nProvider.overrideWithValue(AppDigitRebusL10n(AppLocalizations.of(context))),
            digitRebusAudioServiceProvider.overrideWithValue(ref.watch(audioServiceProvider)),
            dominoL10nProvider.overrideWithValue(AppDominoL10n(AppLocalizations.of(context))),
            dominoAudioServiceProvider.overrideWithValue(ref.watch(audioServiceProvider)),
            labyrinthL10nProvider.overrideWithValue(AppLabyrinthL10n(AppLocalizations.of(context))),
            labyrinthAudioServiceProvider.overrideWithValue(ref.watch(audioServiceProvider)),
          ],
          child: child!,
        );
      },
      routes: {
        '/': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/help': (context) => const HelpScreen(),
        '/module/rebus': (context) => const PuzzleListScreen(),
        '/module/digit_rebus': (context) => const DigitRebusPuzzleListScreen(),
        '/module/domino': (context) => const DominoPuzzleListScreen(),
        '/module/labyrinth': (context) => const LabyrinthPuzzleListScreen(),
      },
    );
  }
}
