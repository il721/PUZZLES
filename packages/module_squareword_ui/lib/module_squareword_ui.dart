/// Flutter UI for the "squareword" (Сквэрворды) puzzle module.
///
/// Builds on the pure-Dart `module_squareword` package (model and player
/// board) to provide the tap-to-place NxN grid widget with its letter-picker
/// popup, the puzzle screen, and the puzzle list screen, plus the Riverpod
/// session controller that ties player input to persistence via
/// `puzzle_core`'s `SaveService`.
///
/// The app shell must override [squarewordSaveServiceProvider] and
/// [squarewordL10nProvider] (and optionally [squarewordPuzzlesProvider] and
/// [squarewordAudioServiceProvider]) before building any widget from this
/// library.
library module_squareword_ui;

export 'src/squareword_grid_widget.dart';
export 'src/squareword_l10n.dart';
export 'src/squareword_module.dart';
export 'src/squareword_providers.dart';
export 'src/squareword_puzzle_list_screen.dart';
export 'src/squareword_puzzle_screen.dart';
export 'src/squareword_session_controller.dart';
export 'src/squareword_tutorial_screen.dart';
