import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_rebus/module_rebus.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'rebus_module.dart';
import 'rebus_providers.dart';

/// Sentinel used by [PuzzleSessionState.copyWith] to distinguish "leave this
/// nullable field unchanged" from "set it to null".
class _Unset {
  const _Unset();
}

const Object _unset = _Unset();

/// Immutable snapshot of one puzzle-play session: the grid, current
/// selection, accumulated time/checks, and completion status.
class PuzzleSessionState {
  /// The player's current grid (mutable in place; a new [PuzzleSessionState]
  /// is published after every mutation so Riverpod listeners rebuild).
  final PlayerGrid grid;

  /// The currently selected cell, if any.
  final CellRef? selected;

  /// Total accumulated play time for this puzzle, in milliseconds.
  final int elapsedMs;

  /// How many times the player has pressed "Check".
  final int checkCount;

  /// Whether this puzzle has ever been solved (permanent once true).
  final bool solved;

  /// Whether the grid is currently locked for review (solved and not
  /// mid-replay).
  final bool reviewMode;

  /// Whether the player is currently replaying a solved puzzle (grid was
  /// cleared for a fresh attempt; the original completion record is
  /// untouched until/unless this replay is itself won).
  final bool replayInProgress;

  /// Violations found by the most recent "Check" press, for a transient
  /// highlight; cleared automatically after a short delay.
  final GridViolations? checkViolations;

  /// ISO-8601 timestamp of the first solve, if solved.
  final String? solvedAt;

  /// Elapsed time (ms) recorded at the first solve, if solved.
  final int? firstSolveElapsedMs;

  /// Check count recorded at the first solve, if solved.
  final int? firstSolveChecks;

  /// Incremented every time a win is freshly detected (first solve, or a
  /// replay being solved again). Distinct from [solved] — which stays
  /// `true` for the whole lifetime of a replay — so the UI can reliably
  /// detect "a win just happened" (e.g. to show the win dialog) without
  /// confusing it for a replay merely being abandoned back to its already-
  /// solved snapshot.
  final int winSeq;

  /// Creates a session state.
  const PuzzleSessionState({
    required this.grid,
    this.selected,
    this.elapsedMs = 0,
    this.checkCount = 0,
    this.solved = false,
    this.reviewMode = false,
    this.replayInProgress = false,
    this.checkViolations,
    this.solvedAt,
    this.firstSolveElapsedMs,
    this.firstSolveChecks,
    this.winSeq = 0,
  });

  /// A fresh, all-defaults session state for [puzzle].
  factory PuzzleSessionState.initial(RebusPuzzle puzzle) =>
      PuzzleSessionState(grid: PlayerGrid.fromPuzzle(puzzle));

  /// Whether the grid is complete but violates at least one rule — the
  /// "has errors" banner condition.
  bool get hasErrorsBanner => grid.isComplete && !grid.wins;

  /// Returns a copy with the given fields replaced. Pass `null` explicitly
  /// for [selected], [checkViolations], [solvedAt], [firstSolveElapsedMs],
  /// or [firstSolveChecks] to clear them; omit them to leave unchanged.
  PuzzleSessionState copyWith({
    PlayerGrid? grid,
    Object? selected = _unset,
    int? elapsedMs,
    int? checkCount,
    bool? solved,
    bool? reviewMode,
    bool? replayInProgress,
    Object? checkViolations = _unset,
    Object? solvedAt = _unset,
    Object? firstSolveElapsedMs = _unset,
    Object? firstSolveChecks = _unset,
    int? winSeq,
  }) {
    return PuzzleSessionState(
      grid: grid ?? this.grid,
      selected: identical(selected, _unset) ? this.selected : selected as CellRef?,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      checkCount: checkCount ?? this.checkCount,
      solved: solved ?? this.solved,
      reviewMode: reviewMode ?? this.reviewMode,
      replayInProgress: replayInProgress ?? this.replayInProgress,
      checkViolations:
          identical(checkViolations, _unset) ? this.checkViolations : checkViolations as GridViolations?,
      solvedAt: identical(solvedAt, _unset) ? this.solvedAt : solvedAt as String?,
      firstSolveElapsedMs:
          identical(firstSolveElapsedMs, _unset) ? this.firstSolveElapsedMs : firstSolveElapsedMs as int?,
      firstSolveChecks:
          identical(firstSolveChecks, _unset) ? this.firstSolveChecks : firstSolveChecks as int?,
      winSeq: winSeq ?? this.winSeq,
    );
  }
}

/// Per-puzzle session provider family: one [PuzzleSessionNotifier] instance
/// per puzzle id.
final puzzleSessionProvider =
    NotifierProvider.family<PuzzleSessionNotifier, PuzzleSessionState, String>(
  PuzzleSessionNotifier.new,
);

/// Owns one puzzle's play session: grid mutation, cell selection, the
/// elapsed-time stopwatch (running only while the owning screen is active
/// and the app is resumed), check/reset/replay actions, auto-win
/// detection, and coalesced autosave via an injected [SaveService].
class PuzzleSessionNotifier extends Notifier<PuzzleSessionState> {
  /// Creates a session notifier for [puzzleId].
  PuzzleSessionNotifier(this.puzzleId);

  /// The id of the puzzle this session plays.
  final String puzzleId;

  late final RebusPuzzle _puzzle;
  late final SaveService _saveService;

  final Stopwatch _stopwatch = Stopwatch();
  int _accumulatedMs = 0;

  /// The grid cells at the moment this puzzle was last known to be solved,
  /// preserved separately so an abandoned replay can restore it without
  /// having persisted (and thus overwritten) it mid-replay.
  Map<String, dynamic>? _solvedSnapshotJson;

  Timer? _saveTimer;
  Timer? _checkHighlightTimer;

  static const Duration _saveDebounce = Duration(milliseconds: 300);
  static const Duration _checkHighlightDuration = Duration(milliseconds: 1500);

  @override
  PuzzleSessionState build() {
    final puzzles = ref.watch(rebusPuzzlesProvider).requireValue;
    _puzzle = puzzles.firstWhere((p) => p.id == puzzleId);
    _saveService = ref.read(saveServiceProvider);

    ref.onDispose(() {
      _saveTimer?.cancel();
      _checkHighlightTimer?.cancel();
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _accumulatedMs += _stopwatch.elapsedMilliseconds;
      }
      // Best-effort final flush; SaveService serializes writes per
      // namespace so this races safely with any earlier in-flight save.
      unawaited(_persistNow());
    });

    // Kick off the async load of any previously-persisted session; until it
    // resolves, the screen shows a fresh grid. In practice this resolves
    // within a microtask/IO tick well before the player can interact.
    unawaited(_loadPersisted());

    return PuzzleSessionState.initial(_puzzle);
  }

  /// Current total elapsed time, including any time accrued by a currently
  /// running stopwatch.
  int get currentElapsedMs => _accumulatedMs + _stopwatch.elapsedMilliseconds;

  Future<void> _loadPersisted() async {
    final namespaceData = await _saveService.load(rebusSaveNamespace);
    // The provider may have been disposed while the load was in flight.
    if (!ref.mounted) return;
    final puzzlesMap = namespaceData['puzzles'];
    final entry = (puzzlesMap is Map) ? puzzlesMap[puzzleId] : null;
    if (entry is! Map) return;

    final cells = entry['cells'];
    final grid = (cells is Map)
        ? PlayerGrid.fromJson(_puzzle, Map<String, dynamic>.from(cells))
        : PlayerGrid.fromPuzzle(_puzzle);
    final elapsedMs = (entry['elapsedMs'] as num?)?.toInt() ?? 0;
    final checks = (entry['checks'] as num?)?.toInt() ?? 0;
    final solved = entry['solved'] == true;

    _accumulatedMs = elapsedMs;
    _solvedSnapshotJson = solved ? grid.toJson() : null;

    state = PuzzleSessionState(
      grid: grid,
      elapsedMs: elapsedMs,
      checkCount: checks,
      solved: solved,
      reviewMode: solved,
      solvedAt: entry['solvedAt'] as String?,
      firstSolveElapsedMs: (entry['firstSolveElapsedMs'] as num?)?.toInt(),
      firstSolveChecks: (entry['firstSolveChecks'] as num?)?.toInt(),
    );
  }

  /// Selects [ref] for input. A no-op while the grid is locked for review.
  void selectCell(CellRef ref) {
    if (state.reviewMode) return;
    state = state.copyWith(selected: ref);
  }

  /// Fills the selected cell with [digit] (0-9), then auto-advances
  /// selection to the next empty editable cell in reading order. A no-op
  /// if nothing is selected, the selection is a given, or the grid is
  /// locked for review.
  void inputDigit(int digit) {
    final sel = state.selected;
    if (sel == null || state.reviewMode) return;
    if (state.grid.isGiven(sel)) return;

    state.grid.setDigit(sel, digit);
    final next = _nextEmptyAfter(sel);
    state = state.copyWith(selected: next ?? sel);
    _afterMutation();
  }

  /// Clears the selected cell if it holds a digit; if it is already empty,
  /// steps back to the previous editable cell and clears that one instead.
  /// A no-op if nothing is selected, the selection is a given, or the grid
  /// is locked for review.
  void backspace() {
    final sel = state.selected;
    if (sel == null || state.reviewMode) return;
    if (state.grid.isGiven(sel)) return;

    if (state.grid.digitAt(sel) != null) {
      state.grid.clearDigit(sel);
      state = state.copyWith();
    } else {
      final prev = _previousEditable(sel);
      if (prev != null) {
        state.grid.clearDigit(prev);
        state = state.copyWith(selected: prev);
      }
    }
    _afterMutation();
  }

  /// Evaluates every fully-filled scope of the grid for violations,
  /// increments the check counter, and exposes the violations for a brief
  /// UI highlight. A no-op while the grid is locked for review.
  void check() {
    if (state.reviewMode) return;
    final violations = state.grid.violations();
    state = state.copyWith(checkCount: state.checkCount + 1, checkViolations: violations);

    _checkHighlightTimer?.cancel();
    _checkHighlightTimer = Timer(_checkHighlightDuration, () {
      state = state.copyWith(checkViolations: null);
    });

    _maybeAutoWin();
    _scheduleSave();
  }

  /// Clears every editable cell back to blank. Only valid for an unsolved
  /// puzzle (the caller is expected to confirm with the player first).
  void reset() {
    if (state.solved) return;
    _checkHighlightTimer?.cancel();
    state = state.copyWith(grid: PlayerGrid.fromPuzzle(_puzzle), selected: null, checkViolations: null);
    _scheduleSave();
  }

  /// Clears the grid for a fresh attempt on an already-solved puzzle,
  /// without touching the completion record or best stats. Only valid for
  /// a solved puzzle.
  void startReplay() {
    if (!state.solved) return;
    _checkHighlightTimer?.cancel();
    state = state.copyWith(
      grid: PlayerGrid.fromPuzzle(_puzzle),
      selected: null,
      reviewMode: false,
      replayInProgress: true,
      checkViolations: null,
    );
  }

  /// If a replay was started but not completed, discards it and restores
  /// the grid to the original solved state (review mode). A no-op if not
  /// currently mid-replay, or if the replay was itself just won (in which
  /// case it has already become the new completion snapshot).
  void abandonReplayIfUnfinished() {
    if (!ref.mounted) return;
    if (!state.replayInProgress || state.grid.wins) return;
    final snapshot = _solvedSnapshotJson;
    final grid =
        snapshot != null ? PlayerGrid.fromJson(_puzzle, snapshot) : PlayerGrid.fromPuzzle(_puzzle);
    state = state.copyWith(
      grid: grid,
      selected: null,
      reviewMode: true,
      replayInProgress: false,
      checkViolations: null,
    );
  }

  /// Starts the elapsed-time stopwatch. Call when the owning screen becomes
  /// active (`initState`) and when the app returns to the foreground.
  void resumeTimer() {
    if (state.solved && !state.replayInProgress) return;
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
    }
  }

  /// Stops the elapsed-time stopwatch and folds its running time into the
  /// accumulated total. Call when the owning screen becomes inactive
  /// (`dispose`) and when the app is backgrounded.
  void pauseTimer() {
    if (!ref.mounted) return;
    if (!_stopwatch.isRunning) return;
    _stopwatch.stop();
    _accumulatedMs += _stopwatch.elapsedMilliseconds;
    _stopwatch.reset();
    state = state.copyWith(elapsedMs: currentElapsedMs);
    _scheduleSave();
  }

  CellRef? _nextEmptyAfter(CellRef ref) {
    final ordered = state.grid.orderedEditableCells;
    final idx = ordered.indexOf(ref);
    if (idx == -1) return null;
    for (var i = idx + 1; i < ordered.length; i++) {
      if (state.grid.digitAt(ordered[i]) == null) return ordered[i];
    }
    return null;
  }

  CellRef? _previousEditable(CellRef ref) {
    final ordered = state.grid.orderedEditableCells;
    final idx = ordered.indexOf(ref);
    if (idx <= 0) return null;
    return ordered[idx - 1];
  }

  void _afterMutation() {
    _maybeAutoWin();
    _scheduleSave();
  }

  void _maybeAutoWin() {
    if (!state.grid.isComplete || !state.grid.wins) return;

    final isFirstSolve = !state.solved;
    final nowIso = DateTime.now().toIso8601String();
    _solvedSnapshotJson = state.grid.toJson();

    state = state.copyWith(
      solved: true,
      reviewMode: true,
      replayInProgress: false,
      solvedAt: state.solvedAt ?? nowIso,
      firstSolveElapsedMs: isFirstSolve ? currentElapsedMs : state.firstSolveElapsedMs,
      firstSolveChecks: isFirstSolve ? state.checkCount : state.firstSolveChecks,
      winSeq: state.winSeq + 1,
    );

    // A win must never be lost to debounce coalescing.
    unawaited(_persistNow());
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, () {
      unawaited(_persistNow());
    });
  }

  Map<String, dynamic> _buildEntryPayload() {
    final cellsJson = state.replayInProgress ? (_solvedSnapshotJson ?? const {}) : state.grid.toJson();
    return <String, dynamic>{
      'cells': cellsJson,
      'elapsedMs': state.elapsedMs,
      'checks': state.checkCount,
      'solved': state.solved,
      if (state.solvedAt != null) 'solvedAt': state.solvedAt,
      if (state.firstSolveElapsedMs != null) 'firstSolveElapsedMs': state.firstSolveElapsedMs,
      if (state.firstSolveChecks != null) 'firstSolveChecks': state.firstSolveChecks,
    };
  }

  Future<void> _persistNow() async {
    _saveTimer?.cancel();
    final namespaceData = await _saveService.load(rebusSaveNamespace);
    // Copy the whole namespace map (not just 'puzzles') so unrelated
    // top-level keys — e.g. the tutorial-completion flag written by
    // TutorialScreen — survive this write instead of being dropped.
    final merged = Map<String, dynamic>.from(namespaceData);
    final rawPuzzles = namespaceData['puzzles'];
    final puzzlesMap =
        (rawPuzzles is Map) ? Map<String, dynamic>.from(rawPuzzles) : <String, dynamic>{};
    puzzlesMap[puzzleId] = _buildEntryPayload();
    merged['puzzles'] = puzzlesMap;
    await _saveService.save(rebusSaveNamespace, merged);
  }
}
