import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:module_playground/module_playground.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'games/cats_dogs/cats_dogs_board.dart';
import 'games/eight_chips/eight_chips_board.dart';
import 'games/hourglass/hourglass_board.dart';
import 'playground_l10n.dart';
import 'playground_providers.dart';
import 'playground_session_controller.dart';

/// Below this body width (logical px), the game screen stacks the goal art
/// below the board instead of overlaying it in a corner.
const double _wideLayoutBreakpoint = 720;

/// The goal-artwork asset for [gameId], or `null` for games with no such
/// illustration (everything but `eight_chips`, for now).
String? _goalArtAsset(String gameId) =>
    gameId == 'eight_chips' ? 'assets/eight_chips_goal.svg' : null;

/// Whether [bestMoves] matches or beats [game]'s recorded par at all (proven
/// or book-claimed). Duplicated (rather than shared) from
/// `playground_list_screen.dart`'s private helper of the same shape — both
/// are a 2-line null-guarded comparison, not worth a cross-file import for.
bool _matchesPar(PlaygroundGame game, int? moves) {
  final par = game.par;
  if (par == null || moves == null) return false;
  return moves <= par;
}

/// Shared chrome for every playground game: an AppBar with undo/restart/
/// rules actions, the game's own board widget, a move-counter/record
/// footer, and a one-shot win dialog.
class PlaygroundGameScreen extends ConsumerStatefulWidget {
  /// The id of the game to play (e.g. `eight_chips`).
  final String gameId;

  /// Creates a game screen for [gameId].
  const PlaygroundGameScreen({super.key, required this.gameId});

  @override
  ConsumerState<PlaygroundGameScreen> createState() =>
      _PlaygroundGameScreenState();
}

class _PlaygroundGameScreenState extends ConsumerState<PlaygroundGameScreen>
    with WidgetsBindingObserver {
  bool _sessionStarted = false;
  PlaygroundSessionNotifier? _notifier;

  /// Non-null while the "show solution" playback is animating; overrides
  /// the board display without touching the real session state.
  PlaygroundState? _previewState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = _notifier;
    if (notifier == null) return;
    if (state == AppLifecycleState.resumed) {
      notifier.resumeTimer();
    } else {
      notifier.pauseTimer();
    }
  }

  @override
  void dispose() {
    final notifier = _notifier;
    if (notifier != null) {
      scheduleMicrotask(() => notifier.pauseTimer());
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(playgroundPuzzlesProvider);
    return gamesAsync.when(
      data: (games) => _buildLoaded(context, games),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text('$error'))),
    );
  }

  Widget _buildLoaded(BuildContext context, List<PlaygroundGame> games) {
    final l10n = ref.watch(playgroundL10nProvider);
    PlaygroundGame? game;
    for (final g in games) {
      if (g.id == widget.gameId) {
        game = g;
        break;
      }
    }

    if (game == null || !game.enabled) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.gameTitle(widget.gameId))),
        body: Center(child: Text(l10n.comingSoon)),
      );
    }
    final activeGame = game;

    if (!_sessionStarted) {
      _sessionStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _notifier = ref.read(playgroundSessionProvider(widget.gameId).notifier);
        ref.listenManual<PlaygroundSessionState>(
          playgroundSessionProvider(widget.gameId),
          (previous, next) {
            if ((previous?.winSeq ?? 0) != next.winSeq) {
              ref.read(playgroundAudioServiceProvider).play(Sfx.win);
              _showWinDialog(next);
            }
          },
        );
        _notifier!.resumeTimer();
      });
    }

    final state = ref.watch(playgroundSessionProvider(widget.gameId));
    final theme = Theme.of(context);
    final matchedPar = state.solved && _matchesPar(activeGame, state.bestMoves);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gameTitle(widget.gameId)),
        actions: [
          IconButton(
            key: const ValueKey('pg-undo'),
            icon: const Icon(Icons.undo),
            tooltip: l10n.undo,
            onPressed: state.moveCount == 0 || _previewState != null
                ? null
                : () => ref
                    .read(playgroundSessionProvider(widget.gameId).notifier)
                    .undo(),
          ),
          IconButton(
            key: const ValueKey('pg-restart'),
            icon: const Icon(Icons.restart_alt),
            tooltip: l10n.restart,
            onPressed: () => _confirmRestart(context, l10n),
          ),
          IconButton(
            key: const ValueKey('pg-rules'),
            icon: const Icon(Icons.info_outline),
            tooltip: l10n.rules,
            onPressed: () => _showRulesSheet(context, l10n, activeGame, state),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBoardArea(activeGame)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  Text(l10n.moveCounter(state.moveCount),
                      style: theme.textTheme.bodyMedium),
                  if (state.solved && state.bestMoves != null) ...[
                    Text(l10n.recordLine(state.bestMoves!),
                        style: theme.textTheme.bodyMedium),
                    if (matchedPar)
                      Text(
                        activeGame.parProven
                            ? l10n.optimalBadge
                            : l10n.bookMatchedBadge,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard(PlaygroundGame game) {
    switch (game.id) {
      case 'eight_chips':
        return EightChipsBoard(
            gameId: widget.gameId, previewState: _previewState);
      case 'cats_dogs':
        return CatsDogsBoard(
            gameId: widget.gameId, previewState: _previewState);
      case 'hourglass':
        return HourglassBoard(
            gameId: widget.gameId, previewState: _previewState);
      default:
        return Center(child: Text(ref.read(playgroundL10nProvider).comingSoon));
    }
  }

  /// The board plus, for games with one, a static illustration of the goal
  /// arrangement ([_goalArtAsset]): overlaid bottom-right on wide (desktop)
  /// widths, or stacked below the board (still above the move-counter
  /// footer) on narrow ones. Games with no goal art render just the board,
  /// unchanged.
  Widget _buildBoardArea(PlaygroundGame game) {
    final board = _buildBoard(game);
    final asset = _goalArtAsset(game.id);
    if (asset == null) return board;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wideLayoutBreakpoint;
        if (wide) {
          final artWidth = (constraints.maxWidth * 0.18).clamp(120.0, 260.0);
          return Stack(
            children: [
              board,
              Positioned(
                right: 24,
                bottom: 24,
                width: artWidth,
                child: _buildGoalArt(asset),
              ),
            ],
          );
        }

        final artWidth = (constraints.maxWidth * 0.55).clamp(120.0, 300.0);
        return Column(
          children: [
            Expanded(child: board),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(width: artWidth, child: _buildGoalArt(asset)),
            ),
          ],
        );
      },
    );
  }

  /// The goal-art illustration itself: a non-interactive SVG. No existing
  /// [PlaygroundL10n] string describes "the target arrangement" well enough
  /// to reuse as its semantics label, so it's excluded from the semantics
  /// tree entirely rather than inventing a new ARB key (out of scope for
  /// this package).
  Widget _buildGoalArt(String asset) {
    return ExcludeSemantics(
      child: SvgPicture.asset(
        asset,
        key: const ValueKey('pg-goal-art'),
        package: 'module_playground_ui',
      ),
    );
  }

  Future<void> _confirmRestart(
      BuildContext context, PlaygroundL10n l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.restartConfirmTitle),
        content: Text(l10n.restartConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.restartConfirmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.restartConfirmOk),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(playgroundSessionProvider(widget.gameId).notifier).restart();
    }
  }

  void _showRulesSheet(
    BuildContext context,
    PlaygroundL10n l10n,
    PlaygroundGame game,
    PlaygroundSessionState state,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.gameRules(widget.gameId)),
              if (game.par != null) ...[
                const SizedBox(height: 8),
                Text(game.parProven
                    ? l10n.parProvenLine(game.par!)
                    : l10n.parBookLine(game.par!)),
              ],
              if (state.solved && game.optimalSolution != null) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    unawaited(_playSolution(game));
                  },
                  child: Text(l10n.showSolution),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(l10n.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Steps the board through [game]'s `optimalSolution` one move at a time,
  /// via a purely local preview overlay ([_previewState]) that never
  /// touches the real session state — so "restoring the player's own
  /// position" afterward is simply clearing the override, not undoing
  /// anything real.
  Future<void> _playSolution(PlaygroundGame game) async {
    final solution = game.optimalSolution;
    if (solution == null || !mounted) return;

    var board = game.initialState();
    setState(() => _previewState = board);

    for (final move in solution) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      board = game.applyMove(board, move);
      setState(() => _previewState = board);
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _previewState = null);
  }

  void _showWinDialog(PlaygroundSessionState state) {
    final navigator = Navigator.of(context);
    final l10n = ref.read(playgroundL10nProvider);
    final gamesAsync = ref.read(playgroundPuzzlesProvider);
    final game = gamesAsync.value?.firstWhere((g) => g.id == widget.gameId);
    final matchedPar = game != null && _matchesPar(game, state.moveCount);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.winTitle),
        content: Text(
            matchedPar ? l10n.winBodyOptimal : l10n.winBody(state.moveCount)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              navigator.pop();
            },
            child: Text(l10n.backToList),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}
