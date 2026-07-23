import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_squareword/module_squareword.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'squareword_grid_widget.dart';
import 'squareword_l10n.dart';
import 'squareword_providers.dart';
import 'squareword_session_controller.dart';

/// The single-puzzle play screen: the tap-to-place squareword grid and
/// Reset/Replay actions. Tapping an editable cell opens a popup listing the
/// puzzle's own keyword letters; tapping one places it. Long-pressing a
/// filled editable cell clears it, no popup. The win is auto-detected the
/// instant the grid is completely filled with zero violations (no Check
/// button).
class SquarewordPuzzleScreen extends ConsumerStatefulWidget {
  /// The id of the puzzle to play (e.g. `p01`).
  final String puzzleId;

  /// Creates a puzzle screen for [puzzleId].
  const SquarewordPuzzleScreen({super.key, required this.puzzleId});

  @override
  ConsumerState<SquarewordPuzzleScreen> createState() => _SquarewordPuzzleScreenState();
}

class _SquarewordPuzzleScreenState extends ConsumerState<SquarewordPuzzleScreen>
    with WidgetsBindingObserver {
  bool _sessionStarted = false;
  SquarewordSessionNotifier? _notifier;

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
    final puzzlesAsync = ref.watch(squarewordPuzzlesProvider);
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
        _notifier = ref.read(squarewordSessionProvider(widget.puzzleId).notifier);
        ref.listenManual<SquarewordSessionState>(squarewordSessionProvider(widget.puzzleId),
            (previous, next) {
          if ((previous?.winSeq ?? 0) != next.winSeq) {
            ref.read(squarewordAudioServiceProvider).play(Sfx.win);
            _showWinDialog();
          }
        });
        _notifier!.resumeTimer();
      });
    }

    final l10n = ref.watch(squarewordL10nProvider);
    final state = ref.watch(squarewordSessionProvider(widget.puzzleId));
    final status = state.status;
    final puzzleNumber = int.tryParse(widget.puzzleId.substring(1)) ?? 0;
    final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    final total = state.board.puzzle.n * state.board.puzzle.n;
    final theme = Theme.of(context);

    final board = SquarewordGridWidget(
      board: state.board,
      status: status,
      cellSemanticsLabel: l10n.cellSemantics,
      maxCell: isDesktop ? null : 56,
      onCellTap: (cell) => _openLetterPicker(context, cell),
      onCellLongPress: (cell) {
        ref.read(squarewordAudioServiceProvider).play(Sfx.tap);
        ref.read(squarewordSessionProvider(widget.puzzleId).notifier).clear(cell);
      },
    );

    final actions = _buildActions(context, l10n, state, isDesktop);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.puzzleN(puzzleNumber))),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: board),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                children: [
                  Text(l10n.filledCounter(status.filledCount, total), style: theme.textTheme.bodyMedium),
                  if (status.violatingCells.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.violationWarning,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
            actions,
          ],
        ),
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    SquarewordL10n l10n,
    SquarewordSessionState state,
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
                  ref.read(squarewordSessionProvider(widget.puzzleId).notifier).startReplay(),
              child: Text(l10n.replay),
            ),
        ],
      ),
    );
  }

  /// Opens a popup listing the puzzle's own keyword letters as tappable
  /// buttons; tapping one places it and closes the popup. A silent no-op
  /// for given cells or while the grid is locked for review.
  Future<void> _openLetterPicker(BuildContext context, Cell cell) async {
    final session = ref.read(squarewordSessionProvider(widget.puzzleId));
    if (session.reviewMode || session.board.isGiven(cell)) return;

    ref.read(squarewordAudioServiceProvider).play(Sfx.tap);
    final puzzle = session.board.puzzle;

    final letter = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final option in puzzle.letters)
                  InkWell(
                    key: ValueKey('letterOption_$option'),
                    onTap: () => Navigator.pop(dialogContext, option),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(dialogContext).colorScheme.outline),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(option, style: Theme.of(dialogContext).textTheme.titleLarge),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!mounted || letter == null) return;
    ref.read(squarewordSessionProvider(widget.puzzleId).notifier).place(cell, letter);
    ref.read(squarewordAudioServiceProvider).play(Sfx.place);
  }

  Future<void> _confirmReset(BuildContext context, SquarewordL10n l10n) async {
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
      ref.read(squarewordSessionProvider(widget.puzzleId).notifier).reset();
    }
  }

  void _showWinDialog() {
    final navigator = Navigator.of(context);
    final l10n = ref.read(squarewordL10nProvider);
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
    final puzzles = ref.read(squarewordPuzzlesProvider).requireValue.where((p) => !p.tutorial).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final idx = puzzles.indexWhere((p) => p.id == widget.puzzleId);
    if (idx == -1 || idx == puzzles.length - 1) {
      navigator.pop();
      return;
    }
    final nextId = puzzles[idx + 1].id;
    navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => SquarewordPuzzleScreen(puzzleId: nextId)));
  }
}
