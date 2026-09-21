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
  String get helpRulesRebus =>
      'Jedes Rätsel besteht aus vier Zeilen der Form „a op b op c op d = Ergebnis“, die strikt von links nach rechts ausgewertet werden, ohne Punkt-vor-Strich-Regel. Die Summe der Zahlen jeder Spalte ergibt das Ergebnis der zugehörigen Zeile, und die untere Zeile zeigt diese vier Summen sowie deren Gesamtsumme. Einige Ziffern sind bereits vorgegeben und lassen sich nicht ändern. Ein Rätsel gilt als gelöst, sobald alle Felder ausgefüllt sind und keine Regel verletzt wird — auch wenn Ihre Lösung von der des Buches abweicht.';

  @override
  String get helpRulesDigitRebus =>
      'Ein 4×4-Quadrat, in dem jede Zeile und jede Spalte eine Rechenaufgabe ist: streng von links nach rechts ausgewertet, ohne Punkt-vor-Strich-Regel, das vierte Feld ist das Ergebnis. Die Ziffern sind hinter Symbolen verborgen, und jedes Symbol lässt nur wenige Ziffern zu — die Legende unter dem Raster zeigt welche. Tippen Sie ein Feld an, bietet das Menü nur die für sein Symbol zulässigen Ziffern an. Das Rätsel ist gelöst, sobald alle acht Gleichungen aufgehen.';

  @override
  String get helpRulesDomino =>
      'Das Brett enthält 56 Felder mit den Ziffern 0 bis 6. Teilen Sie sie in 28 Dominosteine, sodass jedes Wertepaar von 0:0 bis 6:6 genau einmal vorkommt — der volle Satz. Zum Setzen tippen Sie zwei benachbarte Felder an, zum Entfernen den fertigen Stein. Unter dem Brett stehen die Liste der noch fehlenden Paare und ein Zähler „N von 28 gesetzt“; kommt ein Paar doppelt vor, färben sich beide Steine rot.';

  @override
  String get helpRulesLabyrinth =>
      'Ein 8×8-Raster aus Buchstaben. Ziehen Sie einen einzigen Pfad von der oberen linken zur unteren rechten Ecke, der jeden Buchstaben des Alphabets genau einmal berührt. Tippen Sie ein Feld neben einem Pfadende an, um den Pfad zu verlängern; beide Enden wachsen aufeinander zu, und der Pfad schließt sich, wenn sie sich treffen. Ein Tipp auf ein Feld, das nicht am Pfad liegt, setzt eine blaue Markierung — dieser Buchstabe muss auf dem Pfad liegen; ein langer Druck (Rechtsklick am Desktop) streicht ein Feld durch. Sobald einer von mehreren gleichen Buchstaben auf dem Pfad landet, werden die übrigen automatisch durchgestrichen.';

  @override
  String get helpRulesSquareword =>
      'Die oberste Zeile des Rasters ist das Schlüsselwort, einige Buchstaben sind bereits eingetragen. Füllen Sie das Raster so aus, dass jeder Buchstabe des Schlüsselworts in jeder Zeile, jeder Spalte und auf beiden Hauptdiagonalen genau einmal vorkommt. Ein Buchstabe, der sich in einer Zeile, Spalte oder Diagonale wiederholt, wird rot dargestellt. Die Buchstaben werden immer kyrillisch angezeigt — jedes Schlüsselwort ist ein russisches Wort, es gibt keine deutsche Entsprechung zum Einsetzen.';

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
  String get moduleLabyrinthTitle => 'Buchstaben-Labyrinth';

  @override
  String get moduleLabyrinthDescription =>
      'Ziehe einen einzigen Pfad durchs 8×8-Raster von der oberen linken bis zur unteren rechten Ecke und verwende dabei jeden Buchstaben des Alphabets genau einmal.';

  @override
  String get labyrinthListTitle => 'Buchstaben-Labyrinth';

  @override
  String labyrinthPuzzleN(int n) {
    return 'Labyrinth $n';
  }

  @override
  String get labyrinthResetConfirmTitle => 'Pfad zurücksetzen?';

  @override
  String get labyrinthResetConfirmBody =>
      'Der gesamte gezeichnete Pfad wird gelöscht.';

  @override
  String get labyrinthWinTitle => 'Pfad vollständig!';

  @override
  String get labyrinthWinBody =>
      'Du hast einen Pfad durch alle 33 Buchstaben des Alphabets gezogen.';

  @override
  String labyrinthPlacedCounter(int placed) {
    return 'Buchstaben: $placed von 33';
  }

  @override
  String get labyrinthAlphabetLabel => 'Alphabet';

  @override
  String get labyrinthDuplicateWarning =>
      'Ein Buchstabe kommt zweimal im Pfad vor — er ist rot markiert.';

  @override
  String get labyrinthCellSemantics => 'Labyrinth-Feld';

  @override
  String get labyrinthMarkedSemantics =>
      'als erforderlich für den Pfad markiert';

  @override
  String get labyrinthTutorialStep1 =>
      'Der Weg beginnt bei A — oben links. Tippe auf ein Nachbarfeld, um ihn zu verlängern.';

  @override
  String get labyrinthTutorialStep2 =>
      'Das andere Ende liegt fest bei Z — unten rechts. Es wächst dem ersten entgegen; treffen sich beide Enden, schließt sich der Weg.';

  @override
  String get labyrinthTutorialStep3 =>
      'Tippe auf ein Feld, das nicht neben dem Weg liegt, um eine blaue Markierung zu setzen: dieser Buchstabe muss auf dem Weg liegen — wie U, das im Labyrinth nur einmal vorkommt. Ein langer Druck (oder Rechtsklick am Computer) streicht ein Feld durch: dieser Buchstabe kommt nicht auf den Weg — etwa eines der beiden Y. Sobald einer von mehreren gleichen Buchstaben auf dem Weg liegt, werden die übrigen automatisch durchgestrichen.';

  @override
  String get labyrinthTutorialStep4 =>
      'Von A führt der Weg hinunter zu R und wendet sich dann zu Y und J.';

  @override
  String get labyrinthTutorialStep5 =>
      'Über I und # steigt der Weg in die obere Reihe, zu D und T.';

  @override
  String get labyrinthTutorialStep6 =>
      'U kommt im Labyrinth nur einmal vor, muss also auf dem Weg liegen. Rechts davon liegen der Rand des Quadrats und ein durchgestrichenes A, daher führen die Verbindungen zu 3 und K.';

  @override
  String get labyrinthTutorialStep7 =>
      'Von K führt der Weg über P und E hinab zu * und @.';

  @override
  String get labyrinthTutorialStep8 =>
      'C, L, B und W führen den Weg nach links und nach unten.';

  @override
  String get labyrinthTutorialStep9 =>
      'Über G, & und F erreicht der Weg den rechten Rand bei S.';

  @override
  String get labyrinthTutorialStep10 =>
      'H, N und \$ lenken den Weg nach unten.';

  @override
  String get labyrinthTutorialStep11 =>
      'Das V unten links ist von drei Seiten eingeschlossen — eine Sackgasse, es leitet nicht. Das andere V dagegen grenzt an den unteren Rand des Quadrats und ein durchgestrichenes 3, daher führen die Verbindungen zu O und =.';

  @override
  String get labyrinthTutorialStep12 =>
      'Das X am linken Rand ist eine Sackgasse, also muss das andere X auf dem Weg liegen. Es bleiben M, X und Z — der Weg ist geschlossen.';

  @override
  String get moduleSquarewordTitle => 'Quadratwörter';

  @override
  String get moduleSquarewordDescription =>
      'Fülle das Raster so, dass jeder Buchstabe des Schlüsselworts in jeder Zeile, jeder Spalte und auf beiden Diagonalen genau einmal vorkommt.';

  @override
  String get squarewordListTitle => 'Quadratwörter';

  @override
  String squarewordPuzzleN(int n) {
    return 'Quadratwort $n';
  }

  @override
  String get squarewordResetConfirmTitle => 'Raster zurücksetzen?';

  @override
  String get squarewordResetConfirmBody =>
      'Alle eingegebenen Buchstaben werden gelöscht.';

  @override
  String get squarewordWinTitle => 'Raster vollständig!';

  @override
  String get squarewordWinBody =>
      'Du hast das Raster ohne Wiederholungen in Zeile, Spalte oder Diagonale gefüllt.';

  @override
  String squarewordFilledCounter(int filled, int total) {
    return 'Ausgefüllt: $filled von $total';
  }

  @override
  String get squarewordViolationWarning =>
      'Ein Buchstabe wiederholt sich in einer Zeile, Spalte oder Diagonale — er ist rot markiert.';

  @override
  String get squarewordCellSemantics => 'Quadratwort-Feld';

  @override
  String get squarewordTutorialStep1 =>
      'Die oberste Zeile ist das Schlüsselwort: С Л Е З А. In der Mitte steht bereits das Wort ЛЕС. Es gilt dieselbe Regel: In jeder Zeile, jeder Spalte und auf beiden Hauptdiagonalen kommt jeder der fünf Buchstaben genau einmal vor.';

  @override
  String get squarewordTutorialStep2 =>
      'Ab jetzt ergibt sich jede leere Zelle zwingend durch Ausschluss — Raten ist nicht nötig.';

  @override
  String get squarewordTutorialStep3 =>
      'Л steht bereits in den Spalten b und c, also kann es nicht in b1 oder c1 stehen. Zelle c3 liegt auf beiden Diagonalen zugleich (Mittelpunkt des 5×5-Feldes) und enthält bereits Л — also auch nicht in a1 oder e1. Es bleibt nur d1.';

  @override
  String get squarewordTutorialStep4 =>
      'Spalte d hat bereits З und Л. Zelle d4 liegt auf der Nebendiagonale, auf der schon ein А steht (bei e5) — also muss d2 ein А sein, und für d4 bleibt nur noch С übrig.';

  @override
  String get squarewordTutorialStep5 =>
      'In Spalte b hat С keinen Platz auf der Hauptdiagonale (С steht schon bei a5), der Nebendiagonale (С steht schon bei d4) oder in Zeile 3 (С steht schon bei e3). Es bleibt nur b1.';

  @override
  String get squarewordTutorialStep6 =>
      'Das fünfte und letzte С kommt nach c2.';

  @override
  String get squarewordTutorialStep7 =>
      'In der untersten Zeile bleibt nur c1 für А übrig.';

  @override
  String get squarewordTutorialStep8 =>
      'Damit bleibt in Spalte c nur noch c4 für З.';

  @override
  String get squarewordTutorialStep9 =>
      'Die zwei verbleibenden А landen auf a4 und b3.';

  @override
  String get squarewordTutorialStep10 => 'In Zeile 3 bleibt nur a3 für З.';

  @override
  String get squarewordTutorialStep11 =>
      'Der Rest ergibt sich jetzt von selbst: Е bei b4, Л bei e4, З bei e1, Е bei a1, Е bei e2, Л bei a2, З bei b2.';

  @override
  String get squarewordTutorialStep12 =>
      'Das Gitter ist vollständig und ohne Verstöße ausgefüllt — gelöst. Geh in jedem Rätsel genauso vor: Suche Zellen, in denen ein Buchstabe erzwungen ist, und folge der Kette der Ausschlüsse.';

  @override
  String get squarewordCyrillicNote =>
      'Die Buchstaben werden immer kyrillisch angezeigt — jedes Schlüsselwort ist ein russisches Wort, es gibt keine deutsche Entsprechung zum Einsetzen.';

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

  @override
  String get modulePlaygroundTitle => 'Denkspiele';

  @override
  String get modulePlaygroundDescription =>
      'Sieben kleine Spielrätsel: Chips, Plättchen, Blöcke.';

  @override
  String get helpRulesPlayground =>
      'Dieser Abschnitt ist keine Variante eines einzigen Rätsels, sondern sieben eigenständige kleine Spiele: Jedes hat sein eigenes Spielfeld und eigene Regeln, die über die Schaltfläche ℹ auf seinem Bildschirm angezeigt werden. Ein Rätsel gilt als gelöst, sobald die Zielstellung erreicht ist. Bei den Rätseln, bei denen es auf Zugökonomie ankommt, merkt sich die App außerdem Ihre beste Zugzahl und kennzeichnet sie, wenn sie dem bewiesenen Minimum entspricht. Noch nicht verfügbare Spiele werden ausgegraut dargestellt. Bisher sind nur die ersten drei freigeschaltet – „Acht Chips“, „Katzen und Hunde“ und „Sanduhr“: Bei „Acht Chips“ stehen die Chips 1–8 an den Spitzen eines achtzackigen Sterns, sie dürfen nur entlang gerader Linien bewegt werden (durch die freie Mitte kann ein Chip weiterrutschen), und das Ziel ist, sie in umgekehrter Reihenfolge aufzustellen; das bewiesene Minimum sind 28 Züge. Bei „Katzen und Hunde“ tauschen drei Katzen und drei Hunde die Seiten eines Parks: Pro Zug läuft ein Tier auf einen benachbarten freien Platz, und Katze und Hund dürfen nie nebeneinander stehen; das bewiesene Minimum sind 32 Züge. Bei „Sanduhr“ müssen fünfzehn Steine aus dem oberen Dreieck in das untere gebracht werden: Pro Zug rückt ein Stein auf einen benachbarten freien Kreis oder springt wie beim Damespiel über einen benachbarten Stein, wobei mehrere Sprünge nacheinander mit demselben Stein als ein Zug zählen; das bewiesene Minimum sind 26 Züge.';

  @override
  String get playgroundListTitle => 'Denkspiele';

  @override
  String get playgroundTitleEightChips => 'Acht Chips';

  @override
  String get playgroundTitleCatsDogs => 'Katzen und Hunde';

  @override
  String get playgroundTitleHourglass => 'Sanduhr';

  @override
  String get playgroundTitleThreeEach => 'Überall drei';

  @override
  String get playgroundTitlePatterns5 => 'Muster 5×5';

  @override
  String get playgroundTitlePatterns4 => 'Muster 4×4';

  @override
  String get playgroundTitleSwapBlocks => 'Tausche die Quadrate';

  @override
  String get playgroundRulesEightChips =>
      'Die Chips 1–8 stehen an den Spitzen eines achtzackigen Sterns. Bewege einen Chip nur entlang einer geraden Linie zu einem freien Platz; durch die freie Mitte kann er auf derselben Linie weiterrutschen. Ziel ist es, die Chips in umgekehrter Reihenfolge aufzustellen. Das bewiesene Minimum sind 28 Züge.';

  @override
  String get playgroundRulesCatsDogs =>
      'Drei Katzen (C) sitzen auf den linken Plätzen des Parks, drei Hunde (D) auf den rechten. Pro Zug läuft ein Tier über eine Allee auf einen benachbarten freien Platz. Katze und Hund dürfen nie auf benachbarten Plätzen stehen — solche Züge werden gar nicht erst angeboten. Ziel ist, dass Katzen und Hunde die Seiten tauschen. Das bewiesene Minimum sind 32 Züge: genau so viele, wie die Katzen im Buch versprochen haben — sie hatten also recht.';

  @override
  String get playgroundRulesHourglass =>
      'Fünfzehn Steine füllen das obere Dreieck einer Sanduhr; alle müssen in das untere gebracht werden. Pro Zug rückt ein Stein entlang einer Linie auf einen benachbarten freien Kreis oder springt wie beim Damespiel über einen benachbarten Stein auf den freien Kreis direkt dahinter. Mehrere Sprünge nacheinander mit demselben Stein zählen als ein Zug, und man darf nach jedem Sprung anhalten; Rücken und Springen dürfen in einem Zug nicht gemischt werden. Bewegt wird nur entlang der gezeichneten Linien. Das Buch nennt keine Lösung — das durch vollständige Suche bewiesene Minimum sind 26 Züge.';

  @override
  String get playgroundComingSoon => 'In Arbeit';

  @override
  String playgroundMoveCounter(int moves) {
    return 'Züge: $moves';
  }

  @override
  String playgroundRecordLine(int best) {
    return 'Deine Bestleistung: $best Züge';
  }

  @override
  String playgroundParProvenLine(int par) {
    return 'Minimum: $par Züge';
  }

  @override
  String playgroundParBookLine(int par) {
    return 'Bestbekannt: $par Züge';
  }

  @override
  String get playgroundOptimalBadge => '★ optimal';

  @override
  String get playgroundBookMatchedBadge => 'Buchergebnis erreicht';

  @override
  String get playgroundUndo => 'Rückgängig';

  @override
  String get playgroundRules => 'Regeln';

  @override
  String get playgroundClose => 'Schließen';

  @override
  String get playgroundRestartConfirmTitle => 'Neu starten?';

  @override
  String get playgroundRestartConfirmBody =>
      'Der gesamte Fortschritt in diesem Spiel wird zurückgesetzt.';

  @override
  String get playgroundWinTitle => 'Gelöst!';

  @override
  String playgroundWinBody(int moves) {
    return 'Du hast es in $moves Zügen gelöst.';
  }

  @override
  String get playgroundWinBodyOptimal =>
      'Du hast es mit der minimalen Zugzahl gelöst!';

  @override
  String get playgroundShowSolution => 'Lösung zeigen';

  @override
  String get playgroundRotateTile => 'Drehen';

  @override
  String get playgroundReturnTileToTray => 'Zurück in den Vorrat';
}
