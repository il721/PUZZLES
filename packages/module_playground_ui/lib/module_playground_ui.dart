/// Flutter UI for Module 06 ("Головоломки-игры" / playground): a shared
/// game list and game chrome (undo/restart/info/win handling) driving seven
/// small, unrelated play-puzzles that share one session-persistence shape,
/// plus the board widgets of the three shipped games ("Восемь фишек" / eight
/// chips, "Кошки и собаки" / cats and dogs, "Песочные часы" / hourglass).
/// Builds on the pure-Dart contract in `package:module_playground`.
library;

export 'src/games/cats_dogs/cats_dogs_board.dart';
export 'src/games/eight_chips/eight_chips_board.dart';
export 'src/games/hourglass/hourglass_board.dart';
export 'src/playground_game_screen.dart';
export 'src/playground_l10n.dart';
export 'src/playground_list_screen.dart';
export 'src/playground_module.dart';
export 'src/playground_providers.dart';
export 'src/playground_session_controller.dart';
