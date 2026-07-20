import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_domino/module_domino.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'domino_grid_widget.dart';
import 'domino_l10n.dart';
import 'domino_providers.dart';
import 'domino_session_controller.dart';
import 'domino_status_panel.dart';

/// The single-puzzle play screen: the tap-to-bind domino board, the placed /
/// still-to-place value grids, and Reset/Replay actions. The win is
/// auto-detected on the final valid placement (no Check button).
///
/// Layout adapts to the platform. On desktop the board is flanked by the
/// "still to place" grid (left) and the "placed" grid (right), both with
/// enlarged chips, so the board itself is as large as possible. On mobile
/// the two grids sit centered below the board.
class DominoPuzzleScreen extends ConsumerStatefulWidget {
  /// The id of the puzzle to play (e.g. `p01`).
  final String puzzleId;

  /// Creates a puzzle screen for [puzzleId].
  const DominoPuzzleScreen({super.key, required this.puzzleId});

  @override
  ConsumerState<DominoPuzzleScreen> createState() => _DominoPuzzleScreenState();
}

class _DominoPuzzleScreenState extends ConsumerState<DominoPuzzleScreen>
    with WidgetsBindingObserver {
  bool _sessionStarted = false;
  DominoSessionNotifier? _notifier;

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
    final puzzlesAsync = ref.watch(dominoPuzzlesProvider);
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
        _notifier = ref.read(dominoSessionProvider(widget.puzzleId).notifier);
        ref.listenManual<DominoSessionState>(dominoSessionProvider(widget.puzzleId),
            (previous, next) {
          if ((previous?.winSeq ?? 0) != next.winSeq) {
            ref.read(dominoAudioServiceProvider).play(Sfx.win);
            _showWinDialog();
          }
        });
        _notifier!.resumeTimer();
      });
    }

    final l10n = ref.watch(dominoL10nProvider);
    final state = ref.watch(dominoSessionProvider(widget.puzzleId));
    final status = state.status;
    final puzzleNumber = int.tryParse(widget.puzzleId.substring(1)) ?? 0;
    final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    final board = DominoGridWidget(
      board: state.board,
      conflicts: status.conflicts,
      cellSemanticsLabel: l10n.cellSemantics,
      maxCell: isDesktop ? null : 200,
      onCellTap: (cell) {
        ref.read(dominoAudioServiceProvider).play(Sfx.tap);
        ref.read(dominoSessionProvider(widget.puzzleId).notifier).tapCell(cell);
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

  List<DominoValue> _sortedUsed(BoardStatus status) {
    return status.usedValues.toList()
      ..sort((a, b) => a.low != b.low ? a.low - b.low : a.high - b.high);
  }

  Widget _buildDesktopBody(
    BuildContext context,
    DominoL10n l10n,
    BoardStatus status,
    Widget board,
    Widget actions,
  ) {
    final theme = Theme.of(context);
    final placedValues = _sortedUsed(status);
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  child: SingleChildScrollView(
                    child: DominoValueGrid(
                      header: l10n.remainingLabel,
                      values: status.remaining,
                      big: true,
                      useGrid: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: board),
                const SizedBox(width: 16),
                SizedBox(
                  width: 260,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        DominoValueGrid(
                          header: l10n.placedCounter(status.placedCount),
                          values: placedValues,
                          big: true,
                          useGrid: true,
                          blueChips: true,
                        ),
                        if (status.conflicts.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              l10n.duplicateWarning,
                              textAlign: TextAlign.right,
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
    DominoL10n l10n,
    BoardStatus status,
    Widget board,
    Widget actions,
  ) {
    final theme = Theme.of(context);
    final placedSet = status.usedValues.toSet();
    final allValues = <DominoValue>[...status.remaining, ...status.usedValues]
      ..sort((a, b) => a.low != b.low ? a.low - b.low : a.high - b.high);
    return Column(
      children: [
        Expanded(child: board),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 170),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DominoValueGrid(
                  header: l10n.placedCounter(status.placedCount),
                  values: allValues,
                  placedValues: placedSet,
                  useGrid: true,
                  crossAxisCount: 6,
                  big: false,
                  chipFontSize: 30,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  wrapAlignment: WrapAlignment.center,
                ),
                if (status.conflicts.isNotEmpty)
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
    DominoL10n l10n,
    DominoSessionState state,
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
                  ref.read(dominoSessionProvider(widget.puzzleId).notifier).startReplay(),
              child: Text(l10n.replay),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, DominoL10n l10n) async {
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
      ref.read(dominoSessionProvider(widget.puzzleId).notifier).reset();
    }
  }

  void _showWinDialog() {
    final navigator = Navigator.of(context);
    final l10n = ref.read(dominoL10nProvider);
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
    final puzzles = ref.read(dominoPuzzlesProvider).requireValue.where((p) => !p.tutorial).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final idx = puzzles.indexWhere((p) => p.id == widget.puzzleId);
    if (idx == -1 || idx == puzzles.length - 1) {
      navigator.pop();
      return;
    }
    final nextId = puzzles[idx + 1].id;
    navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => DominoPuzzleScreen(puzzleId: nextId)));
  }
}
