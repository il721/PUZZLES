// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Головоломки';

  @override
  String get moduleRebusTitle => 'Ребусы с квадратиками';

  @override
  String get moduleRebusDescription =>
      'Арифметические ребусы: заполните квадратики цифрами, чтобы все уравнения сошлись.';

  @override
  String homeModuleProgress(int solved, int total) {
    return 'Решено: $solved из $total';
  }

  @override
  String get homeSettingsTooltip => 'Настройки';

  @override
  String get homeHelpTooltip => 'Справка';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageEn => 'English';

  @override
  String get languageDe => 'Deutsch';

  @override
  String get settingsSound => 'Звук';

  @override
  String get helpTitle => 'Справка';

  @override
  String get helpBody =>
      'Каждая головоломка — это квадрат из четырёх строк вида «a op b op c op d = результат», где действия выполняются строго слева направо, без порядка операций. Сумма чисел в каждом столбце равна результату соответствующей строки, а в нижней строке показаны эти четыре суммы и их общий итог. Некоторые цифры уже вписаны и их нельзя менять. Головоломка решена, когда все клетки заполнены и ни одно правило не нарушено — даже если ваш вариант отличается от авторского.';

  @override
  String get puzzleListTitle => 'Ребусы';

  @override
  String puzzleN(int n) {
    return 'Ребус $n';
  }

  @override
  String get puzzleStatusUntouched => 'Не начато';

  @override
  String get puzzleStatusInProgress => 'В процессе';

  @override
  String get puzzleStatusSolved => 'Решено';

  @override
  String get check => 'Проверить';

  @override
  String get reset => 'Сбросить';

  @override
  String get replay => 'Повторить';

  @override
  String get next => 'Следующий ребус';

  @override
  String get backToList => 'К списку';

  @override
  String get resetConfirmTitle => 'Сбросить ребус?';

  @override
  String get resetConfirmBody =>
      'Все введённые цифры будут удалены. Подсказки останутся на месте.';

  @override
  String get resetConfirmCancel => 'Отмена';

  @override
  String get resetConfirmOk => 'Сбросить';

  @override
  String get winTitle => 'Ребус решён!';

  @override
  String winTime(String time) {
    return 'Время: $time';
  }

  @override
  String winChecks(int count) {
    return 'Проверок: $count';
  }

  @override
  String get hasErrors => 'Квадрат заполнен, но есть ошибка. Проверьте клетки.';

  @override
  String get tutorialComingSoon => 'Обучение появится в следующем обновлении.';
}
