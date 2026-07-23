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
  String get digitRebusTutorialStep1 =>
      'Перед вами квадрат 4×4: каждая строка и каждый столбец — пример, решаемый строго слева направо (сверху вниз), без порядка действий. Четвёртая клетка — результат.';

  @override
  String get digitRebusTutorialStep2 =>
      'Цифры скрыты значками. Каждый значок допускает лишь несколько цифр — таблица под сеткой всегда подскажет: например, кружок сверху — это 0, 8 или 9.';

  @override
  String get digitRebusTutorialStep3 =>
      'Начнём со второй строки: (a + b) × c. Результат — одна цифра, а множитель не меньше 3, значит a + b не больше 3: подходят только a = 1 и b = 2.';

  @override
  String get digitRebusTutorialStep4 =>
      'Тогда 1 + 2 = 3 и 3 × 3 = 9 — вторая строка: 1 + 2 × 3 = 9.';

  @override
  String get digitRebusTutorialStep5 =>
      'Первый столбец: (a − 1) × c. Множитель снова не меньше 3, значит a − 1 = 3, то есть a = 4 — и 3 × 3 = 9: столбец 4 − 1 × 3 = 9.';

  @override
  String get digitRebusTutorialStep6 =>
      'Третья строка: 3 + b + c. Из допустимых цифр подходит только 3 + 2 + 1 = 6.';

  @override
  String get digitRebusTutorialStep7 =>
      'Третий столбец: a − 3 − 1. Из цифр 0, 6 и 8 подходит только 6: получаем 6 − 3 − 1 = 2.';

  @override
  String get digitRebusTutorialStep8 =>
      'Остальные клетки следуют из своих строк: 4 + 8 : 6 = 2 и 9 − 3 : 2 = 3. Все восемь примеров сходятся.';

  @override
  String get digitRebusTutorialStep9 =>
      'Готово! В ребусах нажимайте на клетку — меню покажет только допустимые цифры. Побеждает любое заполнение, где сходятся все восемь примеров.';

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
  String get helpRulesRebus =>
      'Каждая головоломка — это квадрат из четырёх строк вида «a op b op c op d = результат», где действия выполняются строго слева направо, без порядка операций. Сумма чисел в каждом столбце равна результату соответствующей строки, а в нижней строке показаны эти четыре суммы и их общий итог. Некоторые цифры уже вписаны и их нельзя менять. Головоломка решена, когда все клетки заполнены и ни одно правило не нарушено — даже если ваш вариант отличается от авторского.';

  @override
  String get helpRulesDigitRebus =>
      'Квадрат 4×4, в котором каждая строка и каждый столбец — пример: действия выполняются строго слева направо, без порядка операций, а четвёртая клетка — результат. Цифры спрятаны за значками, и каждый значок допускает лишь несколько цифр — легенда под сеткой показывает какие. Нажмите на клетку, и в меню появятся только допустимые для её значка цифры. Головоломка решена, когда сходятся все восемь примеров.';

  @override
  String get helpRulesDomino =>
      'На доске 56 клеток с цифрами от 0 до 6. Разбейте их на 28 косточек так, чтобы каждая пара значений от 0:0 до 6:6 встретилась ровно один раз — полный набор. Чтобы поставить косточку, нажмите две соседние клетки; чтобы снять — нажмите на готовую косточку. Под доской показаны список ещё не собранных пар и счётчик «поставлено N из 28»; если одна и та же пара собрана дважды, обе косточки краснеют.';

  @override
  String get helpRulesLabyrinth =>
      'Сетка 8×8 из букв. Проведите единственный путь из левого верхнего угла в правый нижний так, чтобы он прошёл через каждую букву алфавита ровно один раз. Нажмите клетку рядом с концом пути, чтобы продлить его; оба конца растут навстречу друг другу, и путь замыкается, когда они встречаются. Нажатие на клетку, не соседнюю с путём, ставит синюю метку — эта буква обязана быть на пути; долгое нажатие (правая кнопка мыши) вычёркивает клетку. Как только одна из нескольких одинаковых букв попадает на путь, остальные вычёркиваются автоматически.';

  @override
  String get helpRulesSquareword =>
      'Верхняя строка сетки — ключевое слово, несколько букв уже вписаны. Заполните сетку так, чтобы каждая буква ключевого слова встречалась ровно один раз в каждой строке, в каждом столбце и на обеих главных диагоналях. Буква, повторившаяся в строке, столбце или на диагонали, показывается красным.';

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

  @override
  String get moduleDominoTitle => 'Домино-пасьянс';

  @override
  String get moduleDominoDescription =>
      'Восстановите 28 косточек домино в сетке из цифр — полный набор от 0:0 до 6:6.';

  @override
  String get dominoListTitle => 'Домино-пасьянс';

  @override
  String dominoPuzzleN(int n) {
    return 'Домино $n';
  }

  @override
  String get dominoResetConfirmTitle => 'Сбросить домино?';

  @override
  String get dominoResetConfirmBody =>
      'Все выставленные косточки будут убраны.';

  @override
  String get dominoWinTitle => 'Домино собрано!';

  @override
  String get dominoWinBody =>
      'Вы восстановили полный набор домино. Все 28 косточек на месте.';

  @override
  String dominoPlacedCounter(int placed) {
    return 'Выставлено: $placed из 28';
  }

  @override
  String get dominoRemainingLabel => 'Осталось собрать:';

  @override
  String get dominoDuplicateWarning =>
      'Есть повторяющиеся косточки — они выделены красным.';

  @override
  String get dominoCellSemantics => 'клетка домино';

  @override
  String get dominoTutorialStep1 =>
      'Домино-пасьянс: перед вами 56 клеток с цифрами от 0 до 6. Разбейте их на 28 косточек так, чтобы вышел полный набор — каждая пара от 0:0 до 6:6 ровно один раз. Чтобы поставить косточку, коснитесь двух соседних клеток; чтобы убрать — коснитесь готовой косточки.';

  @override
  String get dominoTutorialStep2 =>
      'Внизу — список ещё не собранных пар и счётчик «выставлено N из 28». Если одна и та же пара окажется дважды, обе косточки подсветятся красным: пасьянс не сойдётся, пока повтор не убран.';

  @override
  String get dominoTutorialStep3 =>
      'Ищите клетки, у которых сосед-партнёр определён однозначно. Так ставятся первые три косточки: 0:1, 2:4 и 5:6 (они подсвечены).';

  @override
  String get dominoTutorialStep4 =>
      'Дальше — два дубля: 5:5 и 3:3. Дубль занимает две одинаковые клетки рядом, и каждый дубль в наборе только один.';

  @override
  String get dominoTutorialStep5 =>
      'Продолжаем внизу слева: 2:3 и 0:3 ложатся вынужденно, освобождая соседние цифры.';

  @override
  String get dominoTutorialStep6 =>
      'Следующая четвёрка: 0:4, 4:4, 3:4 и 4:5. Косточки с четвёркой почти закончились — следите за списком снизу.';

  @override
  String get dominoTutorialStep7 => 'Теперь пары с единицей: 1:4, 1:6 и 1:3.';

  @override
  String get dominoTutorialStep8 =>
      'Ещё четыре: 3:5, 1:5, 1:2 и 2:5. Проверьте счётчик — уже больше половины.';

  @override
  String get dominoTutorialStep9 =>
      'Верхняя часть поля: 2:6, 0:5, 0:6, 0:2 и 2:2.';

  @override
  String get dominoTutorialStep10 =>
      'Последние пять закрывают набор: 0:0, 1:1, 6:6, 3:6 и 4:6. Все 28 пар на месте — пасьянс сошёлся! В любой головоломке действуйте так же: ищите вынужденные косточки и следите за списком оставшихся пар.';

  @override
  String get moduleLabyrinthTitle => 'Лабиринт-алфавит';

  @override
  String get moduleLabyrinthDescription =>
      'Проведите единственный путь по сетке 8×8 от А до Я, используя каждую букву алфавита ровно один раз.';

  @override
  String get labyrinthListTitle => 'Лабиринт-алфавит';

  @override
  String labyrinthPuzzleN(int n) {
    return 'Лабиринт $n';
  }

  @override
  String get labyrinthResetConfirmTitle => 'Сбросить путь?';

  @override
  String get labyrinthResetConfirmBody => 'Весь проведённый путь будет стёрт.';

  @override
  String get labyrinthWinTitle => 'Путь найден!';

  @override
  String get labyrinthWinBody =>
      'Вы провели путь через все 33 буквы алфавита от А до Я.';

  @override
  String labyrinthPlacedCounter(int placed) {
    return 'Букв: $placed из 33';
  }

  @override
  String get labyrinthAlphabetLabel => 'Алфавит';

  @override
  String get labyrinthDuplicateWarning =>
      'Одна из букв встречается на пути дважды — она выделена красным.';

  @override
  String get labyrinthCellSemantics => 'клетка лабиринта';

  @override
  String get labyrinthMarkedSemantics => 'отмечена как обязательная для пути';

  @override
  String get labyrinthTutorialStep1 =>
      'Путь начинается в клетке А — в левом верхнем углу. Нажмите на соседнюю клетку, чтобы продлить его.';

  @override
  String get labyrinthTutorialStep2 =>
      'Второй конец закреплён в клетке Я — в правом нижнем углу. Он растёт навстречу первому; когда концы окажутся рядом, путь замкнётся.';

  @override
  String get labyrinthTutorialStep3 =>
      'Нажмите на клетку не рядом с путём, чтобы поставить синюю метку: эта буква обязательно на пути — как У, которая встречается в лабиринте один раз. Долгое нажатие (на компьютере — правая кнопка мыши) зачёркивает клетку крестом: эта буква в путь не войдёт — например, одна из двух Ю. Как только одна из одинаковых букв попадает на путь, остальные зачёркиваются сами.';

  @override
  String get labyrinthTutorialStep4 =>
      'Из А путь идёт вниз, к Р, и дальше поворачивает к Ю и Й.';

  @override
  String get labyrinthTutorialStep5 =>
      'Через И и Щ путь поднимается в верхний ряд, к Д и Т.';

  @override
  String get labyrinthTutorialStep6 =>
      'Буква У встречается в лабиринте один раз, значит она обязательно на пути. Справа от неё — край квадрата и зачёркнутая А, поэтому звенья идут к З и К.';

  @override
  String get labyrinthTutorialStep7 =>
      'От К путь спускается через П и Е к Ж и Ь.';

  @override
  String get labyrinthTutorialStep8 => 'Ц, Л, Б и Ш ведут путь влево и вниз.';

  @override
  String get labyrinthTutorialStep9 =>
      'Через Г, Ъ и Ф путь выходит к правому краю, к С.';

  @override
  String get labyrinthTutorialStep10 => 'Э, Н и Ы поворачивают путь вниз.';

  @override
  String get labyrinthTutorialStep11 =>
      'В в левом нижнем углу окружена с трёх сторон — это тупик, она непроводима. Зато вторая В упирается в низ квадрата и в зачёркнутую З, поэтому звенья идут к О и Ё.';

  @override
  String get labyrinthTutorialStep12 =>
      'Х у левого края оказывается в тупике, значит проводима другая Х. Остаются М, Х и Я — путь замкнулся.';

  @override
  String get moduleSquarewordTitle => 'Сквэрворды';

  @override
  String get moduleSquarewordDescription =>
      'Заполните сетку так, чтобы каждая буква ключевого слова встречалась ровно один раз в каждой строке, столбце и на обеих диагоналях.';

  @override
  String get squarewordListTitle => 'Сквэрворды';

  @override
  String squarewordPuzzleN(int n) {
    return 'Сквэрворд $n';
  }

  @override
  String get squarewordResetConfirmTitle => 'Сбросить сетку?';

  @override
  String get squarewordResetConfirmBody => 'Все введённые буквы будут стёрты.';

  @override
  String get squarewordWinTitle => 'Сетка заполнена!';

  @override
  String get squarewordWinBody =>
      'Вы заполнили сетку без повторов в строках, столбцах и по диагоналям.';

  @override
  String squarewordFilledCounter(int filled, int total) {
    return 'Заполнено: $filled из $total';
  }

  @override
  String get squarewordViolationWarning =>
      'Буква повторяется в строке, столбце или по диагонали — она выделена красным.';

  @override
  String get squarewordCellSemantics => 'клетка сквэрворда';

  @override
  String get squarewordTutorialStep1 =>
      'Верхняя строка — слово-ключ: С Л Е З А. В центре сетки уже вписано слово ЛЕС. Правило то же: в каждой строке, каждом столбце и на обеих главных диагоналях все пять букв встречаются ровно по одному разу.';

  @override
  String get squarewordTutorialStep2 =>
      'Дальше каждая пустая клетка вычисляется однозначно — методом исключения, без угадывания.';

  @override
  String get squarewordTutorialStep3 =>
      'Буква Л уже есть в столбцах b и c — значит её не может быть в b1 и c1. Клетка c3 стоит сразу на двух диагоналях (центр квадрата 5×5), и там уже стоит Л — поэтому Л нет ни в a1, ни в e1. Для неё остаётся только d1.';

  @override
  String get squarewordTutorialStep4 =>
      'В столбце d уже есть З и Л. Клетка d4 лежит на побочной диагонали, где А уже занята (в e5) — значит в d2 может быть только А, а в d4 остаётся единственная буква С.';

  @override
  String get squarewordTutorialStep5 =>
      'В столбце b букве С нет места ни на главной диагонали (С уже в a5), ни на побочной (С уже в d4), ни в третьей строке (С уже в e3). Остаётся только b1.';

  @override
  String get squarewordTutorialStep6 => 'Пятая, последняя С встаёт в c2.';

  @override
  String get squarewordTutorialStep7 =>
      'В нижней строке для А остаётся только клетка c1.';

  @override
  String get squarewordTutorialStep8 =>
      'После этого в столбце c для буквы З остаётся только клетка c4.';

  @override
  String get squarewordTutorialStep9 => 'Две оставшиеся А занимают a4 и b3.';

  @override
  String get squarewordTutorialStep10 =>
      'В третьей строке для З остаётся только a3.';

  @override
  String get squarewordTutorialStep11 =>
      'Всё остальное теперь однозначно: Е — в b4, Л — в e4, З — в e1, Е — в a1, Е — в e2, Л — в a2, З — в b2.';

  @override
  String get squarewordTutorialStep12 =>
      'Сетка заполнена полностью, нарушений нет — головоломка решена. В каждой головоломке действуйте так же: ищите клетки, где буква вынуждена, и двигайтесь дальше по цепочке исключений.';

  @override
  String get squarewordCyrillicNote => '';

  @override
  String get settingsSyncSection => 'Перенос прогресса';

  @override
  String get settingsSyncHint =>
      'Сохраните прогресс в файл и откройте его на другом устройстве.';

  @override
  String get settingsExportProgress => 'Сохранить прогресс в файл';

  @override
  String get settingsImportProgress => 'Загрузить прогресс из файла';

  @override
  String get exportSuccess => 'Прогресс сохранён.';

  @override
  String get exportFailed => 'Не удалось сохранить файл.';

  @override
  String get importConfirmTitle => 'Загрузить прогресс?';

  @override
  String importConfirmBody(String date) {
    return 'Файл создан: $date. Ваш текущий прогресс не будет потерян — лучшие результаты сохранятся.';
  }

  @override
  String get importConfirmApply => 'Загрузить';

  @override
  String get importConfirmCancel => 'Отмена';

  @override
  String importSuccess(int added, int updated) {
    return 'Добавлено головоломок: $added, обновлено: $updated.';
  }

  @override
  String get importNothingNew => 'Новых результатов не найдено.';

  @override
  String get importFailedFormat => 'Это не файл прогресса.';

  @override
  String get importFailedVersion =>
      'Файл создан более новой версией приложения. Обновите приложение.';
}
