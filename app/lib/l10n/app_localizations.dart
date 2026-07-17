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
