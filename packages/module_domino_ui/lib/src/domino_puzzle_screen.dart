import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'domino_grid_widget.dart';
import 'domino_l10n.dart';
import 'domino_providers.dart';
import 'domino_session_controller.dart';
import 'domino_status_panel.dart';

/// The single-puzzle play screen: the tap-to-bind domino board, the minimal
/// progress panel, and Reset/Replay actions. The win is auto-detected on the
/// final valid placement (no Check button).
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
    final theme = Theme.of(context);
    final state = ref.watch(dominoSessionProvider(widget.puzzleId));
    final status = state.status;
    final puzzleNumber = int.tryParse(widget.puzzleId.substring(1)) ?? 0;

    final actionButtonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      textStyle: theme.textTheme.titleLarge,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.puzzleN(puzzleNumber))),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: DominoGridWidget(
                board: state.board,
                conflicts: status.conflicts,
                cellSemanticsLabel: l10n.cellSemantics,
                onCellTap: (cell) {
                  ref.read(dominoAudioServiceProvider).play(Sfx.tap);
                  ref.read(dominoSessionProvider(widget.puzzleId).notifier).tapCell(cell);
                },
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 190),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DominoStatusPanel(status: status, l10n: l10n),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  if (!state.solved)
                    OutlinedButton(
                      key: const ValueKey('resetButton'),
                      style: actionButtonStyle,
                      onPressed: () => _confirmReset(context, l10n),
                      child: Text(l10n.reset),
                    ),
                  if (state.solved && !state.replayInProgress)
                    OutlinedButton(
                      key: const ValueKey('replayButton'),
                      style: actionButtonStyle,
                      onPressed: () =>
                          ref.read(dominoSessionProvider(widget.puzzleId).notifier).startReplay(),
                      child: Text(l10n.replay),
                    ),
                ],
              ),
            ),
          ],
        ),
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
