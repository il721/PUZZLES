/// Flutter UI for the "rebus" arithmetic-square puzzle module.
///
/// Builds on the pure-Dart `module_rebus` package (grid model, evaluator,
/// verifier, solver) to provide the player-facing grid widget, digit pad,
/// puzzle screen, and puzzle list screen, plus the Riverpod session
/// controller that ties player input to persistence via `puzzle_core`'s
/// `SaveService`.
///
/// The app shell must override [saveServiceProvider], [rebusL10nProvider],
/// and optionally [rebusPuzzlesProvider] before building any widget from
/// this library.
library module_rebus_ui;

export 'src/digit_pad.dart';
export 'src/puzzle_grid_widget.dart';
export 'src/puzzle_list_screen.dart';
export 'src/puzzle_screen.dart';
export 'src/puzzle_session_controller.dart';
export 'src/rebus_l10n.dart';
export 'src/rebus_module.dart';
export 'src/rebus_providers.dart';
export 'src/tutorial_screen.dart';
