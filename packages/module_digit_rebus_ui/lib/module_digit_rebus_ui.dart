/// Flutter UI for the "digit rebus" puzzle module.
///
/// Builds on the pure-Dart `module_digit_rebus` package (model, evaluator,
/// verifier, player grid, solver) to provide the glyph-masked grid widget,
/// glyph legend, puzzle screen, and puzzle list screen, plus the Riverpod
/// session controller that ties player input to persistence via
/// `puzzle_core`'s `SaveService`.
///
/// The app shell must override [digitRebusSaveServiceProvider] and
/// [digitRebusL10nProvider] (and optionally [digitRebusPuzzlesProvider] and
/// [digitRebusAudioServiceProvider]) before building any widget from this
/// library.
library module_digit_rebus_ui;

export 'src/digit_rebus_grid_widget.dart';
export 'src/digit_rebus_l10n.dart';
export 'src/digit_rebus_module.dart';
export 'src/digit_rebus_providers.dart';
export 'src/digit_rebus_puzzle_list_screen.dart';
export 'src/digit_rebus_puzzle_screen.dart';
export 'src/digit_rebus_session_controller.dart';
export 'src/glyph_legend.dart';
export 'src/glyph_painter.dart';
