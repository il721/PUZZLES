import 'dart:async';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'digit_pad.dart';
import 'puzzle_grid_widget.dart';
import 'puzzle_session_controller.dart';
import 'rebus_l10n.dart';
import 'rebus_providers.dart';

/// The single-puzzle play screen: grid, Check/Reset/Replay actions, and a
/// digit pad. Handles the Android landscape lock, desktop keyboard input,
/// the "has errors" banner, and the win dialog.
class PuzzleScreen extends ConsumerStatefulWidget {
  /// The id of the puzzle to play (e.g. `p01`).
  final String puzzleId;

  /// Creates a puzzle screen for [puzzleId].
  const PuzzleScreen({super.key, required this.puzzleId});

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  late final Future<void> _orientationLockFuture;
  bool _sessionStarted = false;
  PuzzleSessionNotifier? _notifier;

  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _orientationLockFuture = _isAndroid
        ? SystemChrome.setPreferredOrientations(const [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ])
        : Future<void>.value();
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
    // Mutating the session provider synchronously here would notify this
    // very element mid-unmount (its watch subscription is still open), so
    // defer until the unmount pass has finished. The notifier lives in the
    // root ProviderScope and survives this screen.
    final notifier = _notifier;
    if (notifier != null) {
      scheduleMicrotask(() {
        notifier
          ..pauseTimer()
          ..abandonReplayIfUnfinished();
      });
    }
    if (_isAndroid) {
      SystemChrome.setPreferredOrientations(const []);
    }
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAndroid) {
      return FutureBuilder<void>(
        future: _orientationLockFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            // Gate the first paint on the orientation lock to avoid a
            // one-frame wrong-orientation flash.
            return const SizedBox.shrink();
          }
          return _buildContent(context);
        },
      );
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    final puzzlesAsync = ref.watch(rebusPuzzlesProvider);
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
        if (mounted) {
          _notifier = ref.read(puzzleSessionProvider(widget.puzzleId).notifier);
          // Win detection must be registered outside build; the subscription
          // is closed automatically when this element unmounts.
          ref.listenManual<PuzzleSessionState>(puzzleSessionProvider(widget.puzzleId),
              (previous, next) {
            if ((previous?.winSeq ?? 0) != next.winSeq) {
              _showWinDialog(next);
            }
          });
          _notifier!.resumeTimer();
        }
      });
    }
    final l10n = ref.watch(rebusL10nProvider);
    final theme = Theme.of(context);

    final state = ref.watch(puzzleSessionProvider(widget.puzzleId));
    // Ids are normally `pNN`, but the tutorial puzzle's id is `example`.
    final puzzleNumber = int.tryParse(widget.puzzleId.substring(1)) ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.puzzleN(puzzleNumber))),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) => _handleKey(event),
        child: SafeArea(
          child: Column(
            children: [
              if (state.hasErrorsBanner)
                Container(
                  width: double.infinity,
                  color: theme.colorScheme.errorContainer,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    l10n.hasErrors,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              Expanded(
                child: PuzzleGridWidget(
                  grid: state.grid,
                  selected: state.selected,
                  violations: state.checkViolations,
                  onCellTap: (ref0) {
                    _focusNode.requestFocus();
                    ref.read(puzzleSessionProvider(widget.puzzleId).notifier).selectCell(ref0);
                  },
                  givenSemanticsLabel: l10n.cellSemanticsGiven,
                  editableSemanticsLabel: l10n.cellSemanticsEditable,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    if (!state.reviewMode)
                      FilledButton(
                        key: const ValueKey('checkButton'),
                        onPressed: () => ref.read(puzzleSessionProvider(widget.puzzleId).notifier).check(),
                        child: Text(l10n.check),
                      ),
                    if (!state.solved)
                      OutlinedButton(
                        key: const ValueKey('resetButton'),
                        onPressed: () => _confirmReset(context, l10n),
                        child: Text(l10n.reset),
                      ),
                    if (state.solved && !state.replayInProgress)
                      OutlinedButton(
                        key: const ValueKey('replayButton'),
                        onPressed: () => ref.read(puzzleSessionProvider(widget.puzzleId).notifier).startReplay(),
                        child: Text(l10n.replay),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DigitPad(
                  enabled: !state.reviewMode,
                  onDigit: (d) => ref.read(puzzleSessionProvider(widget.puzzleId).notifier).inputDigit(d),
                  onBackspace: () => ref.read(puzzleSessionProvider(widget.puzzleId).notifier).backspace(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final notifier = ref.read(puzzleSessionProvider(widget.puzzleId).notifier);
    final key = event.logicalKey;

    final digitKeys = <LogicalKeyboardKey, int>{
      LogicalKeyboardKey.digit0: 0,
      LogicalKeyboardKey.digit1: 1,
      LogicalKeyboardKey.digit2: 2,
      LogicalKeyboardKey.digit3: 3,
      LogicalKeyboardKey.digit4: 4,
      LogicalKeyboardKey.digit5: 5,
      LogicalKeyboardKey.digit6: 6,
      LogicalKeyboardKey.digit7: 7,
      LogicalKeyboardKey.digit8: 8,
      LogicalKeyboardKey.digit9: 9,
      LogicalKeyboardKey.numpad0: 0,
      LogicalKeyboardKey.numpad1: 1,
      LogicalKeyboardKey.numpad2: 2,
      LogicalKeyboardKey.numpad3: 3,
      LogicalKeyboardKey.numpad4: 4,
      LogicalKeyboardKey.numpad5: 5,
      LogicalKeyboardKey.numpad6: 6,
      LogicalKeyboardKey.numpad7: 7,
      LogicalKeyboardKey.numpad8: 8,
      LogicalKeyboardKey.numpad9: 9,
    };

    if (key == LogicalKeyboardKey.backspace) {
      notifier.backspace();
      return KeyEventResult.handled;
    }
    if (digitKeys.containsKey(key)) {
      notifier.inputDigit(digitKeys[key]!);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.arrowDown) {
      _moveSelection(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowUp) {
      _moveSelection(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveSelection(int delta) {
    final session = ref.read(puzzleSessionProvider(widget.puzzleId));
    final ordered = session.grid.orderedEditableCells;
    if (ordered.isEmpty) return;
    final current = session.selected;
    var idx = current == null ? -1 : ordered.indexOf(current);
    idx = (idx + delta).clamp(0, ordered.length - 1);
    ref.read(puzzleSessionProvider(widget.puzzleId).notifier).selectCell(ordered[idx]);
  }

  Future<void> _confirmReset(BuildContext context, RebusL10n l10n) async {
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
      ref.read(puzzleSessionProvider(widget.puzzleId).notifier).reset();
    }
  }

  void _showWinDialog(PuzzleSessionState state) {
    final navigator = Navigator.of(context);
    final l10n = ref.read(rebusL10nProvider);
    final elapsedMs = state.firstSolveElapsedMs ?? state.elapsedMs;
    final checks = state.firstSolveChecks ?? state.checkCount;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.winTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.winTime(_formatMmSs(elapsedMs))),
            Text(l10n.winChecks(checks)),
          ],
        ),
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
    final puzzles = ref.read(rebusPuzzlesProvider).requireValue.where((p) => !p.tutorial).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final idx = puzzles.indexWhere((p) => p.id == widget.puzzleId);
    if (idx == -1 || idx == puzzles.length - 1) {
      navigator.pop();
      return;
    }
    final nextId = puzzles[idx + 1].id;
    navigator.pushReplacement(MaterialPageRoute<void>(builder: (_) => PuzzleScreen(puzzleId: nextId)));
  }

  String _formatMmSs(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
