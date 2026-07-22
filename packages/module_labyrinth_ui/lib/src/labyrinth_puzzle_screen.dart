import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_labyrinth/module_labyrinth.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'labyrinth_grid_widget.dart';
import 'labyrinth_l10n.dart';
import 'labyrinth_providers.dart';
import 'labyrinth_session_controller.dart';
import 'labyrinth_status_panel.dart';

/// The single-puzzle play screen: the tap-to-thread labyrinth board, the
/// alphabet tracker strip, and Reset/Replay actions. The win is
/// auto-detected on the move that joins the two chains into a full,
/// duplicate-free, alphabet-complete path (no Check button).
///
/// Layout adapts to the platform. On desktop the board is centred with the
/// alphabet tracker in a 260-wide side column. On mobile the tracker sits
/// centered below the board in a height-capped scroll area.
class LabyrinthPuzzleScreen extends ConsumerStatefulWidget {
  /// The id of the puzzle to play (e.g. `p01`).
  final String puzzleId;

  /// Creates a puzzle screen for [puzzleId].
  const LabyrinthPuzzleScreen({super.key, required this.puzzleId});

  @override
  ConsumerState<LabyrinthPuzzleScreen> createState() => _LabyrinthPuzzleScreenState();
}

class _LabyrinthPuzzleScreenState extends ConsumerState<LabyrinthPuzzleScreen>
    with WidgetsBindingObserver {
  bool _sessionStarted = false;
  LabyrinthSessionNotifier? _notifier;

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
      scheduleMicrotask(() {
        notifier
          ..pauseTimer()
          ..abandonReplayIfUnfinished();
      });
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final puzzlesAsync = ref.watch(labyrinthPuzzlesProvider);
    return puzzlesAsync.when(
      data: (_) => _buildLoaded(context),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(body: Center(child: Text('$error'))),
    );
  }

  Widget _buildLoaded(BuildContext context) {
    if (!_sessionStarted) {
      _sessionStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _notifier = ref.read(labyrinthSessionProvider(widget.puzzleId).notifier);
        ref.listenManual<LabyrinthSessionState>(labyrinthSessionProvider(widget.puzzleId),
            (previous, next) {
          if ((previous?.winSeq ?? 0) != next.winSeq) {
            ref.read(labyrinthAudioServiceProvider).play(Sfx.win);
            _showWinDialog();
          }
        });
        _notifier!.resumeTimer();
      });
    }

    final l10n = ref.watch(labyrinthL10nProvider);
    final state = ref.watch(labyrinthSessionProvider(widget.puzzleId));
    final status = state.status;
    final puzzleNumber = int.tryParse(widget.puzzleId.substring(1)) ?? 0;
    final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    final board = LabyrinthGridWidget(
      board: state.board,
      status: status,
      glyphFor: l10n.glyphFor,
      cellSemanticsLabel: l10n.cellSemantics,
      maxCell: isDesktop ? null : 56,
      onCellTap: (cell) {
        ref.read(labyrinthAudioServiceProvider).play(Sfx.tap);
        ref.read(labyrinthSessionProvider(widget.puzzleId).notifier).tapCell(cell);
      },
      onCellLongPress: (cell) {
        ref.read(labyrinthSessionProvider(widget.puzzleId).notifier).longPressCell(cell);
      },
    );

    final actions = _buildActions(context, l10n, state, isDesktop);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.puzzleN(puzzleNumber))),
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopBody(context, l10n, status, board, actions)
            : _buildMobileBody(context, l10n, status, board, actions),
      ),
    );
  }

  Widget _buildDesktopBody(
    BuildContext context,
    LabyrinthL10n l10n,
    LabyrinthStatus status,
    Widget board,
    Widget actions,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: board),
                const SizedBox(width: 16),
                SizedBox(
                  width: 260,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        LabyrinthAlphabetTracker(
                          label: l10n.alphabetLabel,
                          usedLetters: status.usedLetters,
                          duplicateLetters: status.duplicateLetters,
                          glyphFor: l10n.glyphFor,
                          placedCounterText: l10n.placedCounter(status.placedCount),
                          big: true,
                        ),
                        if (status.duplicateLetters.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              l10n.duplicateWarning,
                              textAlign: TextAlign.left,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.colorScheme.error),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions,
      ],
    );
  }

  Widget _buildMobileBody(
    BuildContext context,
    LabyrinthL10n l10n,
    LabyrinthStatus status,
    Widget board,
    Widget actions,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(child: board),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LabyrinthAlphabetTracker(
                  label: l10n.alphabetLabel,
                  usedLetters: status.usedLetters,
                  duplicateLetters: status.duplicateLetters,
                  glyphFor: l10n.glyphFor,
                  placedCounterText: l10n.placedCounter(status.placedCount),
                ),
                if (status.duplicateLetters.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.duplicateWarning,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions,
      ],
    );
  }

  Widget _buildActions(
    BuildContext context,
    LabyrinthL10n l10n,
    LabyrinthSessionState state,
    bool isDesktop,
  ) {
    final theme = Theme.of(context);
    final style = isDesktop
        ? OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            textStyle: theme.textTheme.titleLarge,
          )
        : OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: theme.textTheme.titleMedium,
          );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          if (!state.solved)
            OutlinedButton(
              key: const ValueKey('resetButton'),
              style: style,
              onPressed: () => _confirmReset(context, l10n),
              child: Text(l10n.reset),
            ),
          if (state.solved && !state.replayInProgress)
            OutlinedButton(
              key: const ValueKey('replayButton'),
              style: style,
              onPressed: () =>
                  ref.read(labyrinthSessionProvider(widget.puzzleId).notifier).startReplay(),
              child: Text(l10n.replay),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, LabyrinthL10n l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resetConfirmTitle),
        content: Text(l10n.resetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.resetConfirmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.resetConfirmOk),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(labyrinthSessionProvider(widget.puzzleId).notifier).reset();
    }
  }

  void _showWinDialog() {
    final navigator = Navigator.of(context);
    final l10n = ref.read(labyrinthL10nProvider);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.winTitle),
        content: Text(l10n.winBody),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              navigator.pop();
            },
            child: Text(l10n.backToList),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _goToNextPuzzle(navigator);
            },
            child: Text(l10n.next),
          ),
        ],
      ),
    );
  }

  void _goToNextPuzzle(NavigatorState navigator) {
    final puzzles = ref.read(labyrinthPuzzlesProvider).requireValue.where((p) => !p.tutorial).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final idx = puzzles.indexWhere((p) => p.id == widget.puzzleId);
    if (idx == -1 || idx == puzzles.length - 1) {
      navigator.pop();
      return;
    }
    final nextId = puzzles[idx + 1].id;
    navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => LabyrinthPuzzleScreen(puzzleId: nextId)));
  }
}
