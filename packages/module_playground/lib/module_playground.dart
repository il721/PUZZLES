/// Pure-Dart logic for the "playground" (Головоломки-игры) puzzle module: a
/// shared game contract for seven small, unrelated play-puzzles; the
/// token-graph engine (board, state, rules, BFS solver) shared by the
/// slide-a-token-along-a-line family; the seven shipped games
/// ("Восемь фишек" / eight chips, "Кошки и собаки" / cats and dogs,
/// "Песочные часы" / hourglass, "Всюду по три" / three each,
/// "Узоры 5x5" / patterns5, "Узоры 4x4" / patterns4 and
/// "Поменяйте местами" / swap blocks); puzzle-data parsing; and the
/// module's game registry.
library;

export 'src/playground_game.dart';
export 'src/games/token_graph/token_graph_board.dart';
export 'src/games/token_graph/token_graph_state.dart';
export 'src/games/token_graph/token_graph_rules.dart';
export 'src/games/token_graph/token_graph_jump_rules.dart';
export 'src/games/token_graph/token_graph_solver.dart';
export 'src/games/eight_chips/eight_chips.dart';
export 'src/games/cats_dogs/cats_dogs.dart';
export 'src/games/hourglass/hourglass.dart';
export 'src/games/three_each/three_each.dart';
export 'src/games/patterns/patterns_tiles.dart';
export 'src/games/patterns/patterns.dart';
export 'src/games/swap_blocks/swap_blocks.dart';
export 'src/data.dart';
export 'src/registry.dart';
