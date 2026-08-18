/// Flutter UI for Module 06 ("Головоломки-игры" / playground): a shared
/// game list and game chrome (undo/restart/info/win handling) driving seven
/// small, unrelated play-puzzles that share one session-persistence shape,
/// plus the first shipped game's board widget ("Восемь фишек" / eight
/// chips). Builds on the pure-Dart contract in `package:module_playground`.
library;

export 'src/games/eight_chips/eight_chips_board.dart';
export 'src/playground_game_screen.dart';
export 'src/playground_l10n.dart';
export 'src/playground_list_screen.dart';
export 'src/playground_module.dart';
export 'src/playground_providers.dart';
export 'src/playground_session_controller.dart';
