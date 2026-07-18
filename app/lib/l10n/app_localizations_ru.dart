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
  String get moduleDigitRebusTitle => 'Цифровые ребусы';

  @override
  String get moduleDigitRebusDescription =>
      'Каждая строка и каждый столбец — пример: расставьте цифры по значкам-подсказкам.';

  @override
  String get digitRebusListTitle => 'Цифровые ребусы';

  @override
  String get digitRebusResetConfirmBody => 'Все введённые цифры будут удалены.';

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
  String get settingsTheme => 'Тема';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeLight => 'Светлая';

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
  String get cellSemanticsGiven => 'заданная цифра';

  @override
  String get cellSemanticsEditable => 'цифра для заполнения';

  @override
  String get tutorialComingSoon => 'Обучение появится в следующем обновлении.';

  @override
  String get tutorialTitle => 'Как решать';

  @override
  String get tutorialNext => 'Далее';

  @override
  String get tutorialBack => 'Назад';

  @override
  String get tutorialSkip => 'Пропустить';

  @override
  String get tutorialDone => 'Готово';

  @override
  String tutorialStepCounter(int current, int total) {
    return 'Шаг $current из $total';
  }

  @override
  String get tutorialStep1 =>
      'Каждый квадратик — одна цифра. Ни одно число не равно нулю и не начинается с нуля (но может нулём оканчиваться).';

  @override
  String get tutorialStep2 =>
      'Действия в строке выполняются строго по порядку, слева направо — как будто каждая строка снабжена скобками.';

  @override
  String get tutorialStep3 =>
      'Сумма чисел каждого вертикального ряда равна результату соответствующей строки. Пятая строка — эти суммы и общий итог.';

  @override
  String get tutorialStep4 =>
      'Результат первой строки начинается с 3 — он же первое число пятой строки. А второе число пятой строки оканчивается на 6 — значит, и результат второй строки оканчивается на 6.';

  @override
  String get tutorialStep5 =>
      'Вторая строка: сумма двух однозначных чисел не больше 18, поэтому третье число начинается с 1 — это 16. Сумма первых двух чисел — 17 или 18.';

  @override
  String get tutorialStep6 =>
      'Если сумма равна 17, то (17 − 16) × 8 — однозначное число, а в результате два квадратика. Противоречие.';

  @override
  String get tutorialStep7 =>
      'Значит, сумма равна 18: первое число 9 и второе 9. Тогда (18 − 16) × 8 = 16: четвёртое число 8, результат строки 16 — он же второе число пятой строки.';

  @override
  String get tutorialStep8 =>
      'Второй вертикальный ряд: 2 + 9 уже дают 11 из 16. На третье и четвёртое числа остаётся 5 — каждое из них меньше 5.';

  @override
  String get tutorialStep9 =>
      'Анализ третьей строки допускает для её второго числа только 3 или 8. Меньше 5 — значит 3. Тогда второе число четвёртой строки — 2.';

  @override
  String get tutorialStep10 =>
      'Результат первой строки начинается с 3 и делится на 5 — это 30 или 35. То же верно для первого числа пятой строки.';

  @override
  String get tutorialStep11 =>
      'Первое число третьей строки оканчивается на 7: 17, 27, 37… Уже при 27 сумма первого ряда превысила бы 35. Значит, 17 — и третья строка: 17 + 3 : 5 × 8 = 32.';

  @override
  String get tutorialStep12 =>
      'Пусть результат первой строки равен 35. Тогда (первое число + 2) × третье = 7, и в третьем вертикальном ряду на четвёртое число остаётся 32 − 1 − 16 − 5 = 10 — но оно однозначное. Противоречие — значит, 30.';

  @override
  String get tutorialStep13 =>
      'Первая строка: 1 + 2 × 2 × 5 = 30 (слева направо).';

  @override
  String get tutorialStep14 =>
      'Первый и второй ряды подсказывают четвёртую строку: 3 + 2 × 9 − 12 = 33.';

  @override
  String get tutorialStep15 =>
      'Проверим итог: 30 + 16 + 32 + 33 = 111. Ребус решён!';
}
