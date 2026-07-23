import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('ru'),
  ];

  /// The application's display name.
  ///
  /// In ru, this message translates to:
  /// **'Головоломки'**
  String get appTitle;

  /// Title of Module 01.
  ///
  /// In ru, this message translates to:
  /// **'Ребусы с квадратиками'**
  String get moduleRebusTitle;

  /// Short description of Module 01, shown on its home-screen card.
  ///
  /// In ru, this message translates to:
  /// **'Арифметические ребусы: заполните квадратики цифрами, чтобы все уравнения сошлись.'**
  String get moduleRebusDescription;

  /// Title of Module 02.
  ///
  /// In ru, this message translates to:
  /// **'Цифровые ребусы'**
  String get moduleDigitRebusTitle;

  /// Short description of Module 02, shown on its home-screen card.
  ///
  /// In ru, this message translates to:
  /// **'Каждая строка и каждый столбец — пример: расставьте цифры по значкам-подсказкам.'**
  String get moduleDigitRebusDescription;

  /// Title of Module 02's puzzle list screen.
  ///
  /// In ru, this message translates to:
  /// **'Цифровые ребусы'**
  String get digitRebusListTitle;

  /// Body text of Module 02's reset confirmation dialog (no givens in this module).
  ///
  /// In ru, this message translates to:
  /// **'Все введённые цифры будут удалены.'**
  String get digitRebusResetConfirmBody;

  /// Module 02 tutorial step 1 of 9.
  ///
  /// In ru, this message translates to:
  /// **'Перед вами квадрат 4×4: каждая строка и каждый столбец — пример, решаемый строго слева направо (сверху вниз), без порядка действий. Четвёртая клетка — результат.'**
  String get digitRebusTutorialStep1;

  /// Module 02 tutorial step 2 of 9.
  ///
  /// In ru, this message translates to:
  /// **'Цифры скрыты значками. Каждый значок допускает лишь несколько цифр — таблица под сеткой всегда подскажет: например, кружок сверху — это 0, 8 или 9.'**
  String get digitRebusTutorialStep2;

  /// Module 02 tutorial step 3 of 9.
  ///
  /// In ru, this message translates to:
  /// **'Начнём со второй строки: (a + b) × c. Результат — одна цифра, а множитель не меньше 3, значит a + b не больше 3: подходят только a = 1 и b = 2.'**
  String get digitRebusTutorialStep3;

  /// Module 02 tutorial step 4 of 9.
  ///
  /// In ru, this message translates to:
  /// **'Тогда 1 + 2 = 3 и 3 × 3 = 9 — вторая строка: 1 + 2 × 3 = 9.'**
  String get digitRebusTutorialStep4;

  /// Module 02 tutorial step 5 of 9.
  ///
  /// In ru, this message translates to:
  /// **'Первый столбец: (a − 1) × c. Множитель снова не меньше 3, значит a − 1 = 3, то есть a = 4 — и 3 × 3 = 9: столбец 4 − 1 × 3 = 9.'**
  String get digitRebusTutorialStep5;

  /// Module 02 tutorial step 6 of 9.
  ///
  /// In ru, this message translates to:
  /// **'Третья строка: 3 + b + c. Из допустимых цифр подходит только 3 + 2 + 1 = 6.'**
  String get digitRebusTutorialStep6;

  /// Module 02 tutorial step 7 of 9.
  ///
  /// In ru, this message translates to:
  /// **'Третий столбец: a − 3 − 1. Из цифр 0, 6 и 8 подходит только 6: получаем 6 − 3 − 1 = 2.'**
  String get digitRebusTutorialStep7;

  /// Module 02 tutorial step 8 of 9.
  ///
  /// In ru, this message translates to:
  /// **'Остальные клетки следуют из своих строк: 4 + 8 : 6 = 2 и 9 − 3 : 2 = 3. Все восемь примеров сходятся.'**
  String get digitRebusTutorialStep8;

  /// Module 02 tutorial step 9 of 9.
  ///
  /// In ru, this message translates to:
  /// **'Готово! В ребусах нажимайте на клетку — меню покажет только допустимые цифры. Побеждает любое заполнение, где сходятся все восемь примеров.'**
  String get digitRebusTutorialStep9;

  /// Progress line on a module card.
  ///
  /// In ru, this message translates to:
  /// **'Решено: {solved} из {total}'**
  String homeModuleProgress(int solved, int total);

  /// Tooltip for the settings icon button on the home screen.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get homeSettingsTooltip;

  /// Tooltip for the help icon button on the home screen.
  ///
  /// In ru, this message translates to:
  /// **'Справка'**
  String get homeHelpTooltip;

  /// Title of the settings screen.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// Label for the language selector.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get settingsLanguage;

  /// Language option: follow the device locale.
  ///
  /// In ru, this message translates to:
  /// **'Как в системе'**
  String get languageSystem;

  /// Language option: Russian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get languageRu;

  /// Language option: English.
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get languageEn;

  /// Language option: German.
  ///
  /// In ru, this message translates to:
  /// **'Deutsch'**
  String get languageDe;

  /// Label for the sound-effects toggle.
  ///
  /// In ru, this message translates to:
  /// **'Звук'**
  String get settingsSound;

  /// Settings label: color theme selector.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get settingsTheme;

  /// Theme option: dark scheme.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get themeDark;

  /// Theme option: light scheme.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get themeLight;

  /// Title of the help screen.
  ///
  /// In ru, this message translates to:
  /// **'Справка'**
  String get helpTitle;

  /// Concise explanation of the puzzle rules.
  ///
  /// In ru, this message translates to:
  /// **'Каждая головоломка — это квадрат из четырёх строк вида «a op b op c op d = результат», где действия выполняются строго слева направо, без порядка операций. Сумма чисел в каждом столбце равна результату соответствующей строки, а в нижней строке показаны эти четыре суммы и их общий итог. Некоторые цифры уже вписаны и их нельзя менять. Головоломка решена, когда все клетки заполнены и ни одно правило не нарушено — даже если ваш вариант отличается от авторского.'**
  String get helpBody;

  /// Title of the puzzle list screen.
  ///
  /// In ru, this message translates to:
  /// **'Ребусы'**
  String get puzzleListTitle;

  /// Title for puzzle number n, used on the puzzle screen and list tiles.
  ///
  /// In ru, this message translates to:
  /// **'Ребус {n}'**
  String puzzleN(int n);

  /// Status label: a puzzle that has never been opened.
  ///
  /// In ru, this message translates to:
  /// **'Не начато'**
  String get puzzleStatusUntouched;

  /// Status label: a puzzle with saved progress that is not yet solved.
  ///
  /// In ru, this message translates to:
  /// **'В процессе'**
  String get puzzleStatusInProgress;

  /// Status label: a solved puzzle.
  ///
  /// In ru, this message translates to:
  /// **'Решено'**
  String get puzzleStatusSolved;

  /// Label for the Check action.
  ///
  /// In ru, this message translates to:
  /// **'Проверить'**
  String get check;

  /// Label for the Reset action.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get reset;

  /// Label for the Replay action.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get replay;

  /// Label for the Next puzzle action in the win dialog.
  ///
  /// In ru, this message translates to:
  /// **'Следующий ребус'**
  String get next;

  /// Label for the Back to list action in the win dialog.
  ///
  /// In ru, this message translates to:
  /// **'К списку'**
  String get backToList;

  /// Title of the reset confirmation dialog.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить ребус?'**
  String get resetConfirmTitle;

  /// Body text of the reset confirmation dialog.
  ///
  /// In ru, this message translates to:
  /// **'Все введённые цифры будут удалены. Подсказки останутся на месте.'**
  String get resetConfirmBody;

  /// Cancel button of the reset confirmation dialog.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get resetConfirmCancel;

  /// Confirm button of the reset confirmation dialog.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get resetConfirmOk;

  /// Title of the win dialog.
  ///
  /// In ru, this message translates to:
  /// **'Ребус решён!'**
  String get winTitle;

  /// Elapsed-time line of the win dialog, e.g. "Time: 03:47".
  ///
  /// In ru, this message translates to:
  /// **'Время: {time}'**
  String winTime(String time);

  /// Check-count line of the win dialog.
  ///
  /// In ru, this message translates to:
  /// **'Проверок: {count}'**
  String winChecks(int count);

  /// Banner shown when the grid is complete but violates a rule.
  ///
  /// In ru, this message translates to:
  /// **'Квадрат заполнен, но есть ошибка. Проверьте клетки.'**
  String get hasErrors;

  /// Accessibility (screen reader) label for a pre-filled, immutable grid cell.
  ///
  /// In ru, this message translates to:
  /// **'заданная цифра'**
  String get cellSemanticsGiven;

  /// Accessibility (screen reader) label for an editable grid cell.
  ///
  /// In ru, this message translates to:
  /// **'цифра для заполнения'**
  String get cellSemanticsEditable;

  /// Placeholder note for the not-yet-built guided tutorial.
  ///
  /// In ru, this message translates to:
  /// **'Обучение появится в следующем обновлении.'**
  String get tutorialComingSoon;

  /// Title of the guided tutorial screen.
  ///
  /// In ru, this message translates to:
  /// **'Как решать'**
  String get tutorialTitle;

  /// Label for the tutorial's Next action.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get tutorialNext;

  /// Label for the tutorial's Back action.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get tutorialBack;

  /// Label for the tutorial's Skip action.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get tutorialSkip;

  /// Label for the tutorial's final Done action.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get tutorialDone;

  /// Step counter shown on the tutorial screen, e.g. "Step 3 of 15".
  ///
  /// In ru, this message translates to:
  /// **'Шаг {current} из {total}'**
  String tutorialStepCounter(int current, int total);

  /// Tutorial step 1 of 15.
  ///
  /// In ru, this message translates to:
  /// **'Каждый квадратик — одна цифра. Ни одно число не равно нулю и не начинается с нуля (но может нулём оканчиваться).'**
  String get tutorialStep1;

  /// Tutorial step 2 of 15.
  ///
  /// In ru, this message translates to:
  /// **'Действия в строке выполняются строго по порядку, слева направо — как будто каждая строка снабжена скобками.'**
  String get tutorialStep2;

  /// Tutorial step 3 of 15.
  ///
  /// In ru, this message translates to:
  /// **'Сумма чисел каждого вертикального ряда равна результату соответствующей строки. Пятая строка — эти суммы и общий итог.'**
  String get tutorialStep3;

  /// Tutorial step 4 of 15.
  ///
  /// In ru, this message translates to:
  /// **'Результат первой строки начинается с 3 — он же первое число пятой строки. А второе число пятой строки оканчивается на 6 — значит, и результат второй строки оканчивается на 6.'**
  String get tutorialStep4;

  /// Tutorial step 5 of 15.
  ///
  /// In ru, this message translates to:
  /// **'Вторая строка: сумма двух однозначных чисел не больше 18, поэтому третье число начинается с 1 — это 16. Сумма первых двух чисел — 17 или 18.'**
  String get tutorialStep5;

  /// Tutorial step 6 of 15.
  ///
  /// In ru, this message translates to:
  /// **'Если сумма равна 17, то (17 − 16) × 8 — однозначное число, а в результате два квадратика. Противоречие.'**
  String get tutorialStep6;

  /// Tutorial step 7 of 15.
  ///
  /// In ru, this message translates to:
  /// **'Значит, сумма равна 18: первое число 9 и второе 9. Тогда (18 − 16) × 8 = 16: четвёртое число 8, результат строки 16 — он же второе число пятой строки.'**
  String get tutorialStep7;

  /// Tutorial step 8 of 15.
  ///
  /// In ru, this message translates to:
  /// **'Второй вертикальный ряд: 2 + 9 уже дают 11 из 16. На третье и четвёртое числа остаётся 5 — каждое из них меньше 5.'**
  String get tutorialStep8;

  /// Tutorial step 9 of 15.
  ///
  /// In ru, this message translates to:
  /// **'Анализ третьей строки допускает для её второго числа только 3 или 8. Меньше 5 — значит 3. Тогда второе число четвёртой строки — 2.'**
  String get tutorialStep9;

  /// Tutorial step 10 of 15.
  ///
  /// In ru, this message translates to:
  /// **'Результат первой строки начинается с 3 и делится на 5 — это 30 или 35. То же верно для первого числа пятой строки.'**
  String get tutorialStep10;

  /// Tutorial step 11 of 15.
  ///
  /// In ru, this message translates to:
  /// **'Первое число третьей строки оканчивается на 7: 17, 27, 37… Уже при 27 сумма первого ряда превысила бы 35. Значит, 17 — и третья строка: 17 + 3 : 5 × 8 = 32.'**
  String get tutorialStep11;

  /// Tutorial step 12 of 15.
  ///
  /// In ru, this message translates to:
  /// **'Пусть результат первой строки равен 35. Тогда (первое число + 2) × третье = 7, и в третьем вертикальном ряду на четвёртое число остаётся 32 − 1 − 16 − 5 = 10 — но оно однозначное. Противоречие — значит, 30.'**
  String get tutorialStep12;

  /// Tutorial step 13 of 15.
  ///
  /// In ru, this message translates to:
  /// **'Первая строка: 1 + 2 × 2 × 5 = 30 (слева направо).'**
  String get tutorialStep13;

  /// Tutorial step 14 of 15.
  ///
  /// In ru, this message translates to:
  /// **'Первый и второй ряды подсказывают четвёртую строку: 3 + 2 × 9 − 12 = 33.'**
  String get tutorialStep14;

  /// Tutorial step 15 of 15.
  ///
  /// In ru, this message translates to:
  /// **'Проверим итог: 30 + 16 + 32 + 33 = 111. Ребус решён!'**
  String get tutorialStep15;

  /// Title of Module 03.
  ///
  /// In ru, this message translates to:
  /// **'Домино-пасьянс'**
  String get moduleDominoTitle;

  /// Short description of Module 03, shown on its home-screen card.
  ///
  /// In ru, this message translates to:
  /// **'Восстановите 28 косточек домино в сетке из цифр — полный набор от 0:0 до 6:6.'**
  String get moduleDominoDescription;

  /// Title of Module 03's puzzle list screen.
  ///
  /// In ru, this message translates to:
  /// **'Домино-пасьянс'**
  String get dominoListTitle;

  /// Title for domino puzzle number n.
  ///
  /// In ru, this message translates to:
  /// **'Домино {n}'**
  String dominoPuzzleN(int n);

  /// Title of Module 03's reset confirmation dialog.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить домино?'**
  String get dominoResetConfirmTitle;

  /// Body of Module 03's reset confirmation dialog.
  ///
  /// In ru, this message translates to:
  /// **'Все выставленные косточки будут убраны.'**
  String get dominoResetConfirmBody;

  /// Title of Module 03's win dialog.
  ///
  /// In ru, this message translates to:
  /// **'Домино собрано!'**
  String get dominoWinTitle;

  /// Body of Module 03's win dialog.
  ///
  /// In ru, this message translates to:
  /// **'Вы восстановили полный набор домино. Все 28 косточек на месте.'**
  String get dominoWinBody;

  /// Progress counter on the domino play screen.
  ///
  /// In ru, this message translates to:
  /// **'Выставлено: {placed} из 28'**
  String dominoPlacedCounter(int placed);

  /// Header above the list of not-yet-used domino values.
  ///
  /// In ru, this message translates to:
  /// **'Осталось собрать:'**
  String get dominoRemainingLabel;

  /// Warning shown when duplicate domino value-pairs are on the board.
  ///
  /// In ru, this message translates to:
  /// **'Есть повторяющиеся косточки — они выделены красным.'**
  String get dominoDuplicateWarning;

  /// Accessibility label for a domino grid cell.
  ///
  /// In ru, this message translates to:
  /// **'клетка домино'**
  String get dominoCellSemantics;

  /// Module 03 tutorial step 1 of 10.
  ///
  /// In ru, this message translates to:
  /// **'Домино-пасьянс: перед вами 56 клеток с цифрами от 0 до 6. Разбейте их на 28 косточек так, чтобы вышел полный набор — каждая пара от 0:0 до 6:6 ровно один раз. Чтобы поставить косточку, коснитесь двух соседних клеток; чтобы убрать — коснитесь готовой косточки.'**
  String get dominoTutorialStep1;

  /// Module 03 tutorial step 2 of 10.
  ///
  /// In ru, this message translates to:
  /// **'Внизу — список ещё не собранных пар и счётчик «выставлено N из 28». Если одна и та же пара окажется дважды, обе косточки подсветятся красным: пасьянс не сойдётся, пока повтор не убран.'**
  String get dominoTutorialStep2;

  /// Module 03 tutorial step 3 of 10.
  ///
  /// In ru, this message translates to:
  /// **'Ищите клетки, у которых сосед-партнёр определён однозначно. Так ставятся первые три косточки: 0:1, 2:4 и 5:6 (они подсвечены).'**
  String get dominoTutorialStep3;

  /// Module 03 tutorial step 4 of 10.
  ///
  /// In ru, this message translates to:
  /// **'Дальше — два дубля: 5:5 и 3:3. Дубль занимает две одинаковые клетки рядом, и каждый дубль в наборе только один.'**
  String get dominoTutorialStep4;

  /// Module 03 tutorial step 5 of 10.
  ///
  /// In ru, this message translates to:
  /// **'Продолжаем внизу слева: 2:3 и 0:3 ложатся вынужденно, освобождая соседние цифры.'**
  String get dominoTutorialStep5;

  /// Module 03 tutorial step 6 of 10.
  ///
  /// In ru, this message translates to:
  /// **'Следующая четвёрка: 0:4, 4:4, 3:4 и 4:5. Косточки с четвёркой почти закончились — следите за списком снизу.'**
  String get dominoTutorialStep6;

  /// Module 03 tutorial step 7 of 10.
  ///
  /// In ru, this message translates to:
  /// **'Теперь пары с единицей: 1:4, 1:6 и 1:3.'**
  String get dominoTutorialStep7;

  /// Module 03 tutorial step 8 of 10.
  ///
  /// In ru, this message translates to:
  /// **'Ещё четыре: 3:5, 1:5, 1:2 и 2:5. Проверьте счётчик — уже больше половины.'**
  String get dominoTutorialStep8;

  /// Module 03 tutorial step 9 of 10.
  ///
  /// In ru, this message translates to:
  /// **'Верхняя часть поля: 2:6, 0:5, 0:6, 0:2 и 2:2.'**
  String get dominoTutorialStep9;

  /// Module 03 tutorial step 10 of 10.
  ///
  /// In ru, this message translates to:
  /// **'Последние пять закрывают набор: 0:0, 1:1, 6:6, 3:6 и 4:6. Все 28 пар на месте — пасьянс сошёлся! В любой головоломке действуйте так же: ищите вынужденные косточки и следите за списком оставшихся пар.'**
  String get dominoTutorialStep10;

  /// Title of Module 04.
  ///
  /// In ru, this message translates to:
  /// **'Лабиринт-алфавит'**
  String get moduleLabyrinthTitle;

  /// Short description of Module 04, shown on its home-screen card.
  ///
  /// In ru, this message translates to:
  /// **'Проведите единственный путь по сетке 8×8 от А до Я, используя каждую букву алфавита ровно один раз.'**
  String get moduleLabyrinthDescription;

  /// Title of Module 04's puzzle list screen.
  ///
  /// In ru, this message translates to:
  /// **'Лабиринт-алфавит'**
  String get labyrinthListTitle;

  /// Title for labyrinth puzzle number n.
  ///
  /// In ru, this message translates to:
  /// **'Лабиринт {n}'**
  String labyrinthPuzzleN(int n);

  /// Title of Module 04's reset confirmation dialog.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить путь?'**
  String get labyrinthResetConfirmTitle;

  /// Body of Module 04's reset confirmation dialog.
  ///
  /// In ru, this message translates to:
  /// **'Весь проведённый путь будет стёрт.'**
  String get labyrinthResetConfirmBody;

  /// Title of Module 04's win dialog.
  ///
  /// In ru, this message translates to:
  /// **'Путь найден!'**
  String get labyrinthWinTitle;

  /// Body of Module 04's win dialog.
  ///
  /// In ru, this message translates to:
  /// **'Вы провели путь через все 33 буквы алфавита от А до Я.'**
  String get labyrinthWinBody;

  /// Progress counter on the labyrinth play screen.
  ///
  /// In ru, this message translates to:
  /// **'Букв: {placed} из 33'**
  String labyrinthPlacedCounter(int placed);

  /// Header label above the labyrinth's alphabet tracker strip.
  ///
  /// In ru, this message translates to:
  /// **'Алфавит'**
  String get labyrinthAlphabetLabel;

  /// Warning shown when a letter appears twice on the labyrinth path.
  ///
  /// In ru, this message translates to:
  /// **'Одна из букв встречается на пути дважды — она выделена красным.'**
  String get labyrinthDuplicateWarning;

  /// Accessibility label for a labyrinth grid cell.
  ///
  /// In ru, this message translates to:
  /// **'клетка лабиринта'**
  String get labyrinthCellSemantics;

  /// Accessibility fragment appended to a labyrinth cell's label when the player has marked it as "must be on the path".
  ///
  /// In ru, this message translates to:
  /// **'отмечена как обязательная для пути'**
  String get labyrinthMarkedSemantics;

  /// Module 04 tutorial step 1 of 12.
  ///
  /// In ru, this message translates to:
  /// **'Путь начинается в клетке А — в левом верхнем углу. Нажмите на соседнюю клетку, чтобы продлить его.'**
  String get labyrinthTutorialStep1;

  /// Module 04 tutorial step 2 of 12.
  ///
  /// In ru, this message translates to:
  /// **'Второй конец закреплён в клетке Я — в правом нижнем углу. Он растёт навстречу первому; когда концы окажутся рядом, путь замкнётся.'**
  String get labyrinthTutorialStep2;

  /// Module 04 tutorial step 3 of 12.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на клетку не рядом с путём, чтобы поставить синюю метку: эта буква обязательно на пути — как У, которая встречается в лабиринте один раз. Долгое нажатие (на компьютере — правая кнопка мыши) зачёркивает клетку крестом: эта буква в путь не войдёт — например, одна из двух Ю. Как только одна из одинаковых букв попадает на путь, остальные зачёркиваются сами.'**
  String get labyrinthTutorialStep3;

  /// Module 04 tutorial step 4 of 12.
  ///
  /// In ru, this message translates to:
  /// **'Из А путь идёт вниз, к Р, и дальше поворачивает к Ю и Й.'**
  String get labyrinthTutorialStep4;

  /// Module 04 tutorial step 5 of 12.
  ///
  /// In ru, this message translates to:
  /// **'Через И и Щ путь поднимается в верхний ряд, к Д и Т.'**
  String get labyrinthTutorialStep5;

  /// Module 04 tutorial step 6 of 12.
  ///
  /// In ru, this message translates to:
  /// **'Буква У встречается в лабиринте один раз, значит она обязательно на пути. Справа от неё — край квадрата и зачёркнутая А, поэтому звенья идут к З и К.'**
  String get labyrinthTutorialStep6;

  /// Module 04 tutorial step 7 of 12.
  ///
  /// In ru, this message translates to:
  /// **'От К путь спускается через П и Е к Ж и Ь.'**
  String get labyrinthTutorialStep7;

  /// Module 04 tutorial step 8 of 12.
  ///
  /// In ru, this message translates to:
  /// **'Ц, Л, Б и Ш ведут путь влево и вниз.'**
  String get labyrinthTutorialStep8;

  /// Module 04 tutorial step 9 of 12.
  ///
  /// In ru, this message translates to:
  /// **'Через Г, Ъ и Ф путь выходит к правому краю, к С.'**
  String get labyrinthTutorialStep9;

  /// Module 04 tutorial step 10 of 12.
  ///
  /// In ru, this message translates to:
  /// **'Э, Н и Ы поворачивают путь вниз.'**
  String get labyrinthTutorialStep10;

  /// Module 04 tutorial step 11 of 12.
  ///
  /// In ru, this message translates to:
  /// **'В в левом нижнем углу окружена с трёх сторон — это тупик, она непроводима. Зато вторая В упирается в низ квадрата и в зачёркнутую З, поэтому звенья идут к О и Ё.'**
  String get labyrinthTutorialStep11;

  /// Module 04 tutorial step 12 of 12.
  ///
  /// In ru, this message translates to:
  /// **'Х у левого края оказывается в тупике, значит проводима другая Х. Остаются М, Х и Я — путь замкнулся.'**
  String get labyrinthTutorialStep12;

  /// Title of Module 05.
  ///
  /// In ru, this message translates to:
  /// **'Сквэрворды'**
  String get moduleSquarewordTitle;

  /// Short description of Module 05, shown on its home-screen card.
  ///
  /// In ru, this message translates to:
  /// **'Заполните сетку так, чтобы каждая буква ключевого слова встречалась ровно один раз в каждой строке, столбце и на обеих диагоналях.'**
  String get moduleSquarewordDescription;

  /// Title of Module 05's puzzle list screen.
  ///
  /// In ru, this message translates to:
  /// **'Сквэрворды'**
  String get squarewordListTitle;

  /// Title for squareword puzzle number n.
  ///
  /// In ru, this message translates to:
  /// **'Сквэрворд {n}'**
  String squarewordPuzzleN(int n);

  /// Title of Module 05's reset confirmation dialog.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить сетку?'**
  String get squarewordResetConfirmTitle;

  /// Body of Module 05's reset confirmation dialog.
  ///
  /// In ru, this message translates to:
  /// **'Все введённые буквы будут стёрты.'**
  String get squarewordResetConfirmBody;

  /// Title of Module 05's win dialog.
  ///
  /// In ru, this message translates to:
  /// **'Сетка заполнена!'**
  String get squarewordWinTitle;

  /// Body of Module 05's win dialog.
  ///
  /// In ru, this message translates to:
  /// **'Вы заполнили сетку без повторов в строках, столбцах и по диагоналям.'**
  String get squarewordWinBody;

  /// Progress counter on the squareword play screen.
  ///
  /// In ru, this message translates to:
  /// **'Заполнено: {filled} из {total}'**
  String squarewordFilledCounter(int filled, int total);

  /// Warning shown when a letter repeats in a row, column, or diagonal of the squareword grid.
  ///
  /// In ru, this message translates to:
  /// **'Буква повторяется в строке, столбце или по диагонали — она выделена красным.'**
  String get squarewordViolationWarning;

  /// Accessibility label for a squareword grid cell.
  ///
  /// In ru, this message translates to:
  /// **'клетка сквэрворда'**
  String get squarewordCellSemantics;

  /// Module 05 tutorial step 1 of 12.
  ///
  /// In ru, this message translates to:
  /// **'Верхняя строка — слово-ключ: С Л Е З А. В центре сетки уже вписано слово ЛЕС. Правило то же: в каждой строке, каждом столбце и на обеих главных диагоналях все пять букв встречаются ровно по одному разу.'**
  String get squarewordTutorialStep1;

  /// Module 05 tutorial step 2 of 12.
  ///
  /// In ru, this message translates to:
  /// **'Дальше каждая пустая клетка вычисляется однозначно — методом исключения, без угадывания.'**
  String get squarewordTutorialStep2;

  /// Module 05 tutorial step 3 of 12.
  ///
  /// In ru, this message translates to:
  /// **'Буква Л уже есть в столбцах b и c — значит её не может быть в b1 и c1. Клетка c3 стоит сразу на двух диагоналях (центр квадрата 5×5), и там уже стоит Л — поэтому Л нет ни в a1, ни в e1. Для неё остаётся только d1.'**
  String get squarewordTutorialStep3;

  /// Module 05 tutorial step 4 of 12.
  ///
  /// In ru, this message translates to:
  /// **'В столбце d уже есть З и Л. Клетка d4 лежит на побочной диагонали, где А уже занята (в e5) — значит в d2 может быть только А, а в d4 остаётся единственная буква С.'**
  String get squarewordTutorialStep4;

  /// Module 05 tutorial step 5 of 12.
  ///
  /// In ru, this message translates to:
  /// **'В столбце b букве С нет места ни на главной диагонали (С уже в a5), ни на побочной (С уже в d4), ни в третьей строке (С уже в e3). Остаётся только b1.'**
  String get squarewordTutorialStep5;

  /// Module 05 tutorial step 6 of 12.
  ///
  /// In ru, this message translates to:
  /// **'Пятая, последняя С встаёт в c2.'**
  String get squarewordTutorialStep6;

  /// Module 05 tutorial step 7 of 12.
  ///
  /// In ru, this message translates to:
  /// **'В нижней строке для А остаётся только клетка c1.'**
  String get squarewordTutorialStep7;

  /// Module 05 tutorial step 8 of 12.
  ///
  /// In ru, this message translates to:
  /// **'После этого в столбце c для буквы З остаётся только клетка c4.'**
  String get squarewordTutorialStep8;

  /// Module 05 tutorial step 9 of 12.
  ///
  /// In ru, this message translates to:
  /// **'Две оставшиеся А занимают a4 и b3.'**
  String get squarewordTutorialStep9;

  /// Module 05 tutorial step 10 of 12.
  ///
  /// In ru, this message translates to:
  /// **'В третьей строке для З остаётся только a3.'**
  String get squarewordTutorialStep10;

  /// Module 05 tutorial step 11 of 12.
  ///
  /// In ru, this message translates to:
  /// **'Всё остальное теперь однозначно: Е — в b4, Л — в e4, З — в e1, Е — в a1, Е — в e2, Л — в a2, З — в b2.'**
  String get squarewordTutorialStep11;

  /// Module 05 tutorial step 12 of 12.
  ///
  /// In ru, this message translates to:
  /// **'Сетка заполнена полностью, нарушений нет — головоломка решена. В каждой головоломке действуйте так же: ищите клетки, где буква вынуждена, и двигайтесь дальше по цепочке исключений.'**
  String get squarewordTutorialStep12;

  /// Note explaining that squareword letters stay Cyrillic in every locale. Empty for RU.
  ///
  /// In ru, this message translates to:
  /// **''**
  String get squarewordCyrillicNote;

  /// Header of the settings section for exporting/importing progress between devices.
  ///
  /// In ru, this message translates to:
  /// **'Перенос прогресса'**
  String get settingsSyncSection;

  /// Subtitle under the progress-sync section header.
  ///
  /// In ru, this message translates to:
  /// **'Сохраните прогресс в файл и откройте его на другом устройстве.'**
  String get settingsSyncHint;

  /// Label of the export tile in Settings.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить прогресс в файл'**
  String get settingsExportProgress;

  /// Label of the import tile in Settings.
  ///
  /// In ru, this message translates to:
  /// **'Загрузить прогресс из файла'**
  String get settingsImportProgress;

  /// Snackbar shown after a successful export.
  ///
  /// In ru, this message translates to:
  /// **'Прогресс сохранён.'**
  String get exportSuccess;

  /// Snackbar shown when writing the export file failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить файл.'**
  String get exportFailed;

  /// Title of the import confirmation dialog.
  ///
  /// In ru, this message translates to:
  /// **'Загрузить прогресс?'**
  String get importConfirmTitle;

  /// Body of the import confirmation dialog, reassuring that the merge is non-destructive.
  ///
  /// In ru, this message translates to:
  /// **'Файл создан: {date}. Ваш текущий прогресс не будет потерян — лучшие результаты сохранятся.'**
  String importConfirmBody(String date);

  /// Confirm button of the import dialog.
  ///
  /// In ru, this message translates to:
  /// **'Загрузить'**
  String get importConfirmApply;

  /// Cancel button of the import dialog.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get importConfirmCancel;

  /// Snackbar shown after a successful import.
  ///
  /// In ru, this message translates to:
  /// **'Добавлено головоломок: {added}, обновлено: {updated}.'**
  String importSuccess(int added, int updated);

  /// Snackbar shown when an import applied cleanly but changed nothing.
  ///
  /// In ru, this message translates to:
  /// **'Новых результатов не найдено.'**
  String get importNothingNew;

  /// Snackbar shown when the picked file is not a bundle.
  ///
  /// In ru, this message translates to:
  /// **'Это не файл прогресса.'**
  String get importFailedFormat;

  /// Snackbar shown when the bundle's version is newer than this build supports.
  ///
  /// In ru, this message translates to:
  /// **'Файл создан более новой версией приложения. Обновите приложение.'**
  String get importFailedVersion;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
