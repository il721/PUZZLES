/// Flutter UI for the "domino solitaire" puzzle module.
///
/// Builds on the pure-Dart `module_domino` package (model, value-constrained
/// solver, validator, player board) to provide the tap-to-bind grid widget,
/// progress panel, puzzle screen, and puzzle list screen, plus the Riverpod
/// session controller that ties player input to persistence via
/// `puzzle_core`'s `SaveService`.
///
/// The app shell must override [dominoSaveServiceProvider] and
/// [dominoL10nProvider] (and optionally [dominoPuzzlesProvider] and
/// [dominoAudioServiceProvider]) before building any widget from this
/// library.
library module_domino_ui;

export 'src/domino_grid_widget.dart';
export 'src/domino_l10n.dart';
export 'src/domino_module.dart';
export 'src/domino_providers.dart';
export 'src/domino_puzzle_list_screen.dart';
export 'src/domino_puzzle_screen.dart';
export 'src/domino_session_controller.dart';
export 'src/domino_status_panel.dart';
