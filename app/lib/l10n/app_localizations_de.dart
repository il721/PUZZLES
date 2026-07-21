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
  String get moduleDigitRebusTitle => 'Ziffernrebusse';

  @override
  String get moduleDigitRebusDescription =>
      'Jede Zeile und jede Spalte ist eine Rechenaufgabe: Setzen Sie die Ziffern anhand der Symbolhinweise.';

  @override
  String get digitRebusListTitle => 'Ziffernrebusse';

  @override
  String get digitRebusResetConfirmBody =>
      'Alle eingetragenen Ziffern werden gelöscht.';

  @override
  String get digitRebusTutorialStep1 =>
      'Dies ist ein 4×4-Quadrat: Jede Zeile und jede Spalte ist eine Rechenaufgabe, die streng von links nach rechts (von oben nach unten) gelöst wird, ohne Punkt-vor-Strich. Die vierte Zelle ist das Ergebnis.';

  @override
  String get digitRebusTutorialStep2 =>
      'Die Ziffern sind hinter Symbolen verborgen. Jedes Symbol lässt nur wenige Ziffern zu — die Legende unter dem Gitter zeigt stets welche: Ein Kreis oben bedeutet zum Beispiel 0, 8 oder 9.';

  @override
  String get digitRebusTutorialStep3 =>
      'Beginnen wir mit Zeile 2: (a + b) × c. Das Ergebnis ist einstellig und der Faktor mindestens 3, also ist a + b höchstens 3: Nur a = 1 und b = 2 passen.';

  @override
  String get digitRebusTutorialStep4 =>
      'Dann ist 1 + 2 = 3 und 3 × 3 = 9 — Zeile 2 lautet 1 + 2 × 3 = 9.';

  @override
  String get digitRebusTutorialStep5 =>
      'Spalte 1: (a − 1) × c. Der Faktor ist wieder mindestens 3, also a − 1 = 3, das heißt a = 4 — und 3 × 3 = 9: Die Spalte lautet 4 − 1 × 3 = 9.';

  @override
  String get digitRebusTutorialStep6 =>
      'Zeile 3: 3 + b + c. Von den zulässigen Ziffern passt nur 3 + 2 + 1 = 6.';

  @override
  String get digitRebusTutorialStep7 =>
      'Spalte 3: a − 3 − 1. Von 0, 6 und 8 passt nur die 6: 6 − 3 − 1 = 2.';

  @override
  String get digitRebusTutorialStep8 =>
      'Die übrigen Zellen folgen aus ihren Zeilen: 4 + 8 : 6 = 2 und 9 − 3 : 2 = 3. Alle acht Aufgaben stimmen.';

  @override
  String get digitRebusTutorialStep9 =>
      'Fertig! Tippen Sie in den Rätseln auf eine Zelle — das Menü zeigt nur die zulässigen Ziffern. Jede Füllung, bei der alle acht Aufgaben stimmen, gewinnt.';

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
  String get settingsTheme => 'Design';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeLight => 'Hell';

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
  String get cellSemanticsGiven => 'vorgegebene Ziffer';

  @override
  String get cellSemanticsEditable => 'editierbare Ziffer';

  @override
  String get tutorialComingSoon =>
      'Die geführte Einführung folgt in einem späteren Update.';

  @override
  String get tutorialTitle => 'So wird gelöst';

  @override
  String get tutorialNext => 'Weiter';

  @override
  String get tutorialBack => 'Zurück';

  @override
  String get tutorialSkip => 'Überspringen';

  @override
  String get tutorialDone => 'Fertig';

  @override
  String tutorialStepCounter(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get tutorialStep1 =>
      'Jedes Kästchen steht für genau eine Ziffer. Keine Zahl ist gleich null, und keine Zahl beginnt mit einer Null (sie darf aber auf null enden).';

  @override
  String get tutorialStep2 =>
      'Die Rechenschritte einer Zeile werden strikt der Reihe nach ausgeführt, von links nach rechts — als wäre jede Zeile vollständig eingeklammert.';

  @override
  String get tutorialStep3 =>
      'Die Zahlen jeder senkrechten Spalte ergeben zusammen das Ergebnis der entsprechenden Zeile. Die fünfte Zeile enthält diese Summen und die Gesamtsumme.';

  @override
  String get tutorialStep4 =>
      'Das Ergebnis der 1. Zeile beginnt mit 3 — es ist zugleich die erste Zahl der fünften Zeile. Und die zweite Zahl der fünften Zeile endet auf 6, also endet auch das Ergebnis der 2. Zeile auf 6.';

  @override
  String get tutorialStep5 =>
      'Zeile 2: Die Summe zweier einstelliger Zahlen ist höchstens 18, also beginnt die dritte Zahl mit 1 — sie ist 16. Die Summe der ersten beiden Zahlen ist 17 oder 18.';

  @override
  String get tutorialStep6 =>
      'Wäre die Summe 17, dann wäre (17 − 16) × 8 einstellig, doch das Ergebnis hat zwei Kästchen. Widerspruch.';

  @override
  String get tutorialStep7 =>
      'Also ist die Summe 18: die erste Zahl 9, die zweite 9. Dann ist (18 − 16) × 8 = 16: die vierte Zahl ist 8, und das Zeilenergebnis 16 ist zugleich die zweite Zahl der fünften Zeile.';

  @override
  String get tutorialStep8 =>
      'Zweite senkrechte Spalte: 2 + 9 ergeben bereits 11 von 16. Für die dritte und vierte Zahl bleiben 5 — jede ist kleiner als 5.';

  @override
  String get tutorialStep9 =>
      'Die Analyse der 3. Zeile lässt für deren zweite Zahl nur 3 oder 8 zu. Kleiner als 5 — also 3. Dann ist die zweite Zahl der 4. Zeile 2.';

  @override
  String get tutorialStep10 =>
      'Das Ergebnis der 1. Zeile beginnt mit 3 und ist durch 5 teilbar — 30 oder 35. Dasselbe gilt für die erste Zahl der fünften Zeile.';

  @override
  String get tutorialStep11 =>
      'Die erste Zahl der 3. Zeile endet auf 7: 17, 27, 37 … Schon bei 27 überstiege die Summe der ersten Spalte 35. Also 17 — und die 3. Zeile lautet 17 + 3 : 5 × 8 = 32.';

  @override
  String get tutorialStep12 =>
      'Angenommen, das Ergebnis der 1. Zeile wäre 35. Dann wäre (erste Zahl + 2) × dritte = 7, und in der dritten Spalte blieben 32 − 1 − 16 − 5 = 10 für die vierte, einstellige Zahl. Widerspruch — also 30.';

  @override
  String get tutorialStep13 =>
      'Zeile 1: 1 + 2 × 2 × 5 = 30, von links nach rechts.';

  @override
  String get tutorialStep14 =>
      'Die erste und zweite Spalte legen nun Zeile 4 fest: 3 + 2 × 9 − 12 = 33.';

  @override
  String get tutorialStep15 =>
      'Zur Probe: 30 + 16 + 32 + 33 = 111. Das Rätsel ist gelöst!';

  @override
  String get moduleDominoTitle => 'Domino-Patience';

  @override
  String get moduleDominoDescription =>
      'Setze die 28 Dominosteine im Zahlengitter wieder zusammen — der volle Satz von 0:0 bis 6:6.';

  @override
  String get dominoListTitle => 'Domino-Patience';

  @override
  String dominoPuzzleN(int n) {
    return 'Domino $n';
  }

  @override
  String get dominoResetConfirmTitle => 'Domino zurücksetzen?';

  @override
  String get dominoResetConfirmBody =>
      'Alle gelegten Dominosteine werden entfernt.';

  @override
  String get dominoWinTitle => 'Domino vollständig!';

  @override
  String get dominoWinBody =>
      'Du hast den vollen Dominosatz wiederhergestellt. Alle 28 Steine liegen richtig.';

  @override
  String dominoPlacedCounter(int placed) {
    return 'Gelegt: $placed von 28';
  }

  @override
  String get dominoRemainingLabel => 'Noch zu legen:';

  @override
  String get dominoDuplicateWarning =>
      'Einige Dominosteine sind doppelt — rot markiert.';

  @override
  String get dominoCellSemantics => 'Domino-Feld';

  @override
  String get dominoTutorialStep1 =>
      'Domino-Patience: 56 Felder tragen Ziffern von 0 bis 6. Teile sie in 28 Dominosteine, sodass der volle Satz entsteht — jedes Wertepaar von 0:0 bis 6:6 genau einmal. Zum Legen tippe zwei benachbarte Felder an; zum Entfernen tippe den fertigen Stein an.';

  @override
  String get dominoTutorialStep2 =>
      'Unter dem Feld: die Liste der noch offenen Paare und ein Zähler „Gelegt N von 28\". Kommt dasselbe Paar zweimal vor, färben sich beide Steine rot — die Patience geht erst auf, wenn die Dopplung weg ist.';

  @override
  String get dominoTutorialStep3 =>
      'Suche Felder, deren benachbarter Partner eindeutig ist. So stehen die ersten drei Steine fest: 0:1, 2:4 und 5:6 (hervorgehoben).';

  @override
  String get dominoTutorialStep4 =>
      'Dann zwei Pasch-Steine: 5:5 und 3:3. Ein Pasch bedeckt zwei gleiche Felder nebeneinander, und jeder Pasch kommt nur einmal vor.';

  @override
  String get dominoTutorialStep5 =>
      'Weiter unten links: 2:3 und 0:3 sind erzwungen und geben die Nachbarn frei.';

  @override
  String get dominoTutorialStep6 =>
      'Die nächsten vier: 0:4, 4:4, 3:4 und 4:5. Die Vieren sind fast verbraucht — achte auf die Liste unten.';

  @override
  String get dominoTutorialStep7 =>
      'Nun die Paare mit einer Eins: 1:4, 1:6 und 1:3.';

  @override
  String get dominoTutorialStep8 =>
      'Vier weitere: 3:5, 1:5, 1:2 und 2:5. Prüfe den Zähler — schon über die Hälfte.';

  @override
  String get dominoTutorialStep9 =>
      'Der obere Teil des Feldes: 2:6, 0:5, 0:6, 0:2 und 2:2.';

  @override
  String get dominoTutorialStep10 =>
      'Die letzten fünf schließen den Satz: 0:0, 1:1, 6:6, 3:6 und 4:6. Alle 28 Paare liegen — die Patience ist aufgegangen! Geh in jedem Rätsel gleich vor: finde die erzwungenen Steine und behalte die Liste der offenen Paare im Blick.';

  @override
  String get settingsSyncSection => 'Fortschritt übertragen';

  @override
  String get settingsSyncHint =>
      'Fortschritt in eine Datei speichern und auf einem anderen Gerät öffnen.';

  @override
  String get settingsExportProgress => 'Fortschritt in Datei speichern';

  @override
  String get settingsImportProgress => 'Fortschritt aus Datei laden';

  @override
  String get exportSuccess => 'Fortschritt gespeichert.';

  @override
  String get exportFailed => 'Datei konnte nicht gespeichert werden.';

  @override
  String get importConfirmTitle => 'Fortschritt laden?';

  @override
  String importConfirmBody(String date) {
    return 'Datei erstellt: $date. Dein bisheriger Fortschritt geht nicht verloren — die besten Ergebnisse bleiben erhalten.';
  }

  @override
  String get importConfirmApply => 'Laden';

  @override
  String get importConfirmCancel => 'Abbrechen';

  @override
  String importSuccess(int added, int updated) {
    return 'Rätsel hinzugefügt: $added, aktualisiert: $updated.';
  }

  @override
  String get importNothingNew => 'Keine neuen Ergebnisse gefunden.';

  @override
  String get importFailedFormat => 'Das ist keine Fortschrittsdatei.';

  @override
  String get importFailedVersion =>
      'Diese Datei stammt aus einer neueren App-Version. Bitte aktualisiere die App.';
}
