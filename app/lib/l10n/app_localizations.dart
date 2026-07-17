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

  /// Placeholder note for the not-yet-built guided tutorial.
  ///
  /// In ru, this message translates to:
  /// **'Обучение появится в следующем обновлении.'**
  String get tutorialComingSoon;
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
