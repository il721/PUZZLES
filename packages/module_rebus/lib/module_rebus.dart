/// The "rebus" arithmetic-square puzzle module: model, evaluator,
/// canonical-data verifier, and player-facing solution counter, plus the
/// module's puzzle data (`assets/puzzles/module01.json`).
///
/// This library is pure Dart and imports nothing from Flutter. The
/// Flutter UI for this module is added in milestone M2, in an app-shell
/// package that binds a [PuzzleModuleDescriptor] (from `puzzle_core`) and
/// a screen to the model exposed here.
library module_rebus;

export 'src/evaluator.dart';
export 'src/model.dart';
export 'src/player_grid.dart';
export 'src/solver.dart';
export 'src/verifier.dart';
