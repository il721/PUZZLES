import 'dart:async';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_rebus/module_rebus.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'puzzle_grid_widget.dart';
import 'puzzle_session_controller.dart';
import 'rebus_l10n.dart';
import 'rebus_providers.dart';

/// The single-puzzle play screen: grid and Check/Reset/Replay actions.
/// Digits are entered via a compact popup menu anchored at the tapped
/// cell, or via the keyboard. Handles the Android landscape lock, desktop
/// keyboard input, the "has errors" banner, and the win dialog.
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
            // one-frame wrong-orientation flash; a bare themed Scaffold
            // serves as the neutral placeholder frame meanwhile.
            return const Scaffold(body: SizedBox.shrink());
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
              ref.read(rebusAudioServiceProvider).play(Sfx.win);
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

    final actionButtonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      textStyle: theme.textTheme.titleLarge,
    );

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
                  },
                  onCellTapDown: (ref0, globalPosition) => _handleCellTapDown(ref0, globalPosition),
                  onCellClear: (ref0) => _handleCellClear(ref0),
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
                      OutlinedButton(
                        key: const ValueKey('checkButton'),
                        style: actionButtonStyle,
                        onPressed: () => _onCheckPressed(),
                        child: Text(l10n.check),
                      ),
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
                        onPressed: () => ref.read(puzzleSessionProvider(widget.puzzleId).notifier).startReplay(),
                        child: Text(l10n.replay),
                      ),
                  ],
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
      ref.read(rebusAudioServiceProvider).play(Sfx.tap);
      return KeyEventResult.handled;
    }
    if (digitKeys.containsKey(key)) {
      notifier.inputDigit(digitKeys[key]!);
      ref.read(rebusAudioServiceProvider).play(Sfx.place);
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

  /// Handles a tap-down on [cellRef] at [globalPosition]: for an editable
  /// cell (not a given, not locked for review), plays [Sfx.tap], selects
  /// the cell, and opens a compact popup digit menu anchored at the tap.
  /// If a digit is picked, enters it and plays [Sfx.place]. A silent no-op
  /// for given cells or while the grid is locked for review.
  Future<void> _handleCellTapDown(CellRef cellRef, Offset globalPosition) async {
    final session = ref.read(puzzleSessionProvider(widget.puzzleId));
    if (session.reviewMode || session.grid.isGiven(cellRef)) return;

    final notifier = ref.read(puzzleSessionProvider(widget.puzzleId).notifier);
    ref.read(rebusAudioServiceProvider).play(Sfx.tap);
    notifier.selectCell(cellRef);

    final digit = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      items: [
        PopupMenuItem<int>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _digitTileRow(0, 4),
        ),
        PopupMenuItem<int>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _digitTileRow(5, 9),
        ),
      ],
    );

    if (!mounted || digit == null) return;
    notifier.inputDigit(digit);
    ref.read(rebusAudioServiceProvider).play(Sfx.place);
  }

  /// A row of five 40x40 digit tiles for [start]..[end], each popping the
  /// enclosing popup menu route with the tapped digit.
  Widget _digitTileRow(int start, int end) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var d = start; d <= end; d++)
          InkWell(
            key: ValueKey('digitMenu_$d'),
            onTap: () => Navigator.pop(context, d),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(child: Text('$d', style: Theme.of(context).textTheme.titleMedium)),
            ),
          ),
      ],
    );
  }

  /// Handles a clear request (right-click or long-press) on [cellRef]:
  /// plays [Sfx.tap] and clears the cell. A no-op (via the notifier's own
  /// guards) for given cells or while the grid is locked for review.
  void _handleCellClear(CellRef cellRef) {
    ref.read(rebusAudioServiceProvider).play(Sfx.tap);
    ref.read(puzzleSessionProvider(widget.puzzleId).notifier).clearCell(cellRef);
  }

  /// Runs a Check pass and plays [Sfx.error] if it just found a violation,
  /// or [Sfx.tap] otherwise.
  void _onCheckPressed() {
    ref.read(puzzleSessionProvider(widget.puzzleId).notifier).check();
    final violations = ref.read(puzzleSessionProvider(widget.puzzleId)).checkViolations;
    final hasViolations = violations != null && violations.isNotEmpty;
    ref.read(rebusAudioServiceProvider).play(hasViolations ? Sfx.error : Sfx.tap);
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
