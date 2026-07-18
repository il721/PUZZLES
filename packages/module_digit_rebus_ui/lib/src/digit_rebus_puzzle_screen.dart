import 'dart:async';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_digit_rebus/module_digit_rebus.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'digit_rebus_grid_widget.dart';
import 'digit_rebus_l10n.dart';
import 'digit_rebus_providers.dart';
import 'digit_rebus_session_controller.dart';
import 'glyph_legend.dart';

/// The single-puzzle play screen: glyph-masked grid, the always-available
/// glyph legend, and Check/Reset/Replay actions. Digits are entered via a
/// compact popup menu anchored at the tapped cell — showing ONLY the
/// digits the cell's glyph admits — or via the keyboard (restricted to the
/// same set). Handles the Android landscape lock, desktop keyboard input,
/// the "has errors" banner, and the win dialog.
class DigitRebusPuzzleScreen extends ConsumerStatefulWidget {
  /// The id of the puzzle to play (e.g. `p01`).
  final String puzzleId;

  /// Creates a puzzle screen for [puzzleId].
  const DigitRebusPuzzleScreen({super.key, required this.puzzleId});

  @override
  ConsumerState<DigitRebusPuzzleScreen> createState() => _DigitRebusPuzzleScreenState();
}

class _DigitRebusPuzzleScreenState extends ConsumerState<DigitRebusPuzzleScreen>
    with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  late final Future<void> _orientationLockFuture;
  bool _sessionStarted = false;
  DigitRebusSessionNotifier? _notifier;

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
    final puzzlesAsync = ref.watch(digitRebusPuzzlesProvider);
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
          _notifier = ref.read(digitRebusSessionProvider(widget.puzzleId).notifier);
          // Win detection must be registered outside build; the subscription
          // is closed automatically when this element unmounts.
          ref.listenManual<DigitRebusSessionState>(digitRebusSessionProvider(widget.puzzleId),
              (previous, next) {
            if ((previous?.winSeq ?? 0) != next.winSeq) {
              ref.read(digitRebusAudioServiceProvider).play(Sfx.win);
              _showWinDialog(next);
            }
          });
          _notifier!.resumeTimer();
        }
      });
    }
    final l10n = ref.watch(digitRebusL10nProvider);
    final theme = Theme.of(context);

    final state = ref.watch(digitRebusSessionProvider(widget.puzzleId));
    // Ids are `pNN`; the tutorial puzzle `example` is not routed here.
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
                child: DigitRebusGridWidget(
                  grid: state.grid,
                  selected: state.selected,
                  violations: state.checkViolations,
                  onCellTap: (ref0) {
                    _focusNode.requestFocus();
                  },
                  onCellTapDown: (ref0, globalPosition) => _handleCellTapDown(ref0, globalPosition),
                  onCellClear: (ref0) => _handleCellClear(ref0),
                  editableSemanticsLabel: l10n.cellSemanticsEditable,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: GlyphLegend(),
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
                        onPressed: () =>
                            ref.read(digitRebusSessionProvider(widget.puzzleId).notifier).startReplay(),
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

  /// The digits the glyph of [cellRef] admits, in ascending order.
  List<int> _allowedDigits(CellRef cellRef) {
    final glyph = ref
        .read(digitRebusSessionProvider(widget.puzzleId))
        .grid
        .puzzle
        .glyphs[cellRef.row][cellRef.col];
    return glyph.digits.toList()..sort();
  }

  KeyEventResult _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final notifier = ref.read(digitRebusSessionProvider(widget.puzzleId).notifier);
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
      ref.read(digitRebusAudioServiceProvider).play(Sfx.tap);
      return KeyEventResult.handled;
    }
    if (digitKeys.containsKey(key)) {
      // Keyboard input honors the same glyph restriction as the popup: a
      // digit the selected cell's glyph does not admit is ignored (the
      // verifier still independently enforces sets — defense in depth).
      final sel = ref.read(digitRebusSessionProvider(widget.puzzleId)).selected;
      final digit = digitKeys[key]!;
      if (sel != null && _allowedDigits(sel).contains(digit)) {
        notifier.inputDigit(digit);
        ref.read(digitRebusAudioServiceProvider).play(Sfx.place);
      }
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

  /// Handles a tap-down on [cellRef] at [globalPosition]: plays [Sfx.tap],
  /// selects the cell, and opens a compact popup digit menu anchored at
  /// the tap, offering ONLY the digits the cell's glyph admits (2-3
  /// tiles). If a digit is picked, enters it and plays [Sfx.place]. A
  /// silent no-op while the grid is locked for review.
  Future<void> _handleCellTapDown(CellRef cellRef, Offset globalPosition) async {
    final session = ref.read(digitRebusSessionProvider(widget.puzzleId));
    if (session.reviewMode) return;

    final notifier = ref.read(digitRebusSessionProvider(widget.puzzleId).notifier);
    ref.read(digitRebusAudioServiceProvider).play(Sfx.tap);
    notifier.selectCell(cellRef);

    final allowed = _allowedDigits(cellRef);
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
          child: _digitTileRow(allowed),
        ),
      ],
    );

    if (!mounted || digit == null) return;
    notifier.inputDigit(digit);
    ref.read(digitRebusAudioServiceProvider).play(Sfx.place);
  }

  /// A row of 40x40 digit tiles for [digits], each popping the enclosing
  /// popup menu route with the tapped digit.
  Widget _digitTileRow(List<int> digits) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final d in digits)
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
  /// guard) while the grid is locked for review.
  void _handleCellClear(CellRef cellRef) {
    ref.read(digitRebusAudioServiceProvider).play(Sfx.tap);
    ref.read(digitRebusSessionProvider(widget.puzzleId).notifier).clearCell(cellRef);
  }

  /// Runs a Check pass and plays [Sfx.error] if it just found a violation,
  /// or [Sfx.tap] otherwise.
  void _onCheckPressed() {
    ref.read(digitRebusSessionProvider(widget.puzzleId).notifier).check();
    final violations = ref.read(digitRebusSessionProvider(widget.puzzleId)).checkViolations;
    final hasViolations = violations != null && violations.isNotEmpty;
    ref.read(digitRebusAudioServiceProvider).play(hasViolations ? Sfx.error : Sfx.tap);
  }

  void _moveSelection(int delta) {
    final session = ref.read(digitRebusSessionProvider(widget.puzzleId));
    final ordered = session.grid.orderedEditableCells;
    if (ordered.isEmpty) return;
    final current = session.selected;
    var idx = current == null ? -1 : ordered.indexOf(current);
    idx = (idx + delta).clamp(0, ordered.length - 1);
    ref.read(digitRebusSessionProvider(widget.puzzleId).notifier).selectCell(ordered[idx]);
  }

  Future<void> _confirmReset(BuildContext context, DigitRebusL10n l10n) async {
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
      ref.read(digitRebusSessionProvider(widget.puzzleId).notifier).reset();
    }
  }

  void _showWinDialog(DigitRebusSessionState state) {
    final navigator = Navigator.of(context);
    final l10n = ref.read(digitRebusL10nProvider);
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
    final puzzles = ref.read(digitRebusPuzzlesProvider).requireValue.where((p) => !p.tutorial).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final idx = puzzles.indexWhere((p) => p.id == widget.puzzleId);
    if (idx == -1 || idx == puzzles.length - 1) {
      navigator.pop();
      return;
    }
    final nextId = puzzles[idx + 1].id;
    navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => DigitRebusPuzzleScreen(puzzleId: nextId)));
  }

  String _formatMmSs(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
