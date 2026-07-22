/// Flutter UI for the "alphabet labyrinth" puzzle module.
///
/// Builds on the pure-Dart `module_labyrinth` package (model, path solver,
/// and player board) to provide the tap-to-thread grid widget, alphabet
/// tracker panel, puzzle screen, and puzzle list screen, plus the Riverpod
/// session controller that ties player input to persistence via
/// `puzzle_core`'s `SaveService`.
///
/// The app shell must override [labyrinthSaveServiceProvider] and
/// [labyrinthL10nProvider] (and optionally [labyrinthPuzzlesProvider] and
/// [labyrinthAudioServiceProvider]) before building any widget from this
/// library.
///
/// This phase (M-c) does not include the guided tutorial screen — that
/// lands in a later milestone alongside its l10n strings.
library module_labyrinth_ui;

export 'src/labyrinth_grid_widget.dart';
export 'src/labyrinth_l10n.dart';
export 'src/labyrinth_module.dart';
export 'src/labyrinth_providers.dart';
export 'src/labyrinth_puzzle_list_screen.dart';
export 'src/labyrinth_puzzle_screen.dart';
export 'src/labyrinth_session_controller.dart';
export 'src/labyrinth_status_panel.dart';
