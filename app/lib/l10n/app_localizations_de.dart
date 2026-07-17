// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Rätselbuch';

  @override
  String get moduleRebusTitle => 'Zahlenrätsel-Quadrate';

  @override
  String get moduleRebusDescription =>
      'Rechenrätsel: Füllen Sie die Kästchen so aus, dass jede Gleichung aufgeht.';

  @override
  String homeModuleProgress(int solved, int total) {
    return 'Gelöst: $solved von $total';
  }

  @override
  String get homeSettingsTooltip => 'Einstellungen';

  @override
  String get homeHelpTooltip => 'Hilfe';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get languageSystem => 'Systemsprache';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageEn => 'English';

  @override
  String get languageDe => 'Deutsch';

  @override
  String get settingsSound => 'Ton';

  @override
  String get helpTitle => 'Hilfe';

  @override
  String get helpBody =>
      'Jedes Rätsel besteht aus vier Zeilen der Form „a op b op c op d = Ergebnis“, die strikt von links nach rechts ausgewertet werden, ohne Punkt-vor-Strich-Regel. Die Summe der Zahlen jeder Spalte ergibt das Ergebnis der zugehörigen Zeile, und die untere Zeile zeigt diese vier Summen sowie deren Gesamtsumme. Einige Ziffern sind bereits vorgegeben und lassen sich nicht ändern. Ein Rätsel gilt als gelöst, sobald alle Felder ausgefüllt sind und keine Regel verletzt wird — auch wenn Ihre Lösung von der des Buches abweicht.';

  @override
  String get puzzleListTitle => 'Zahlenrätsel';

  @override
  String puzzleN(int n) {
    return 'Rätsel $n';
  }

  @override
  String get puzzleStatusUntouched => 'Nicht begonnen';

  @override
  String get puzzleStatusInProgress => 'In Bearbeitung';

  @override
  String get puzzleStatusSolved => 'Gelöst';

  @override
  String get check => 'Prüfen';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get replay => 'Wiederholen';

  @override
  String get next => 'Nächstes Rätsel';

  @override
  String get backToList => 'Zur Übersicht';

  @override
  String get resetConfirmTitle => 'Rätsel zurücksetzen?';

  @override
  String get resetConfirmBody =>
      'Alle eingegebenen Ziffern werden gelöscht. Vorgegebene Ziffern bleiben erhalten.';

  @override
  String get resetConfirmCancel => 'Abbrechen';

  @override
  String get resetConfirmOk => 'Zurücksetzen';

  @override
  String get winTitle => 'Rätsel gelöst!';

  @override
  String winTime(String time) {
    return 'Zeit: $time';
  }

  @override
  String winChecks(int count) {
    return 'Prüfungen: $count';
  }

  @override
  String get hasErrors =>
      'Das Quadrat ist vollständig ausgefüllt, aber etwas stimmt nicht. Prüfen Sie die markierten Felder.';

  @override
  String get tutorialComingSoon =>
      'Die geführte Einführung folgt in einem späteren Update.';
}
