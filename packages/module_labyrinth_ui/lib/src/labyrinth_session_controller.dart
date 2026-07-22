import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_labyrinth/module_labyrinth.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'labyrinth_module.dart';
import 'labyrinth_providers.dart';

/// Sentinel used by [LabyrinthSessionState.copyWith] to distinguish "leave
/// this nullable field unchanged" from "set it to null".
class _Unset {
  const _Unset();
}

const Object _unset = _Unset();

/// Immutable snapshot of one puzzle-play session. [board] is mutated in
/// place; [rev] is bumped on every mutation so a new state object is
/// published (Riverpod listeners rebuild) even though the board instance is
/// unchanged.
class LabyrinthSessionState {
  /// The player's current board (mutated in place; see [rev]).
  final LabyrinthBoard board;

  /// Total accumulated play time for this puzzle, in milliseconds.
  final int elapsedMs;

  /// Whether this puzzle has ever been solved (permanent once true).
  final bool solved;

  /// Whether the board is currently locked for review.
  final bool reviewMode;

  /// Whether the player is currently replaying a solved puzzle.
  final bool replayInProgress;

  /// ISO-8601 timestamp of the first solve, if solved.
  final String? solvedAt;

  /// Elapsed time (ms) recorded at the first solve, if solved.
  final int? firstSolveElapsedMs;

  /// Incremented every time a win is freshly detected.
  final int winSeq;

  /// Revision counter, bumped on every in-place board mutation.
  final int rev;

  /// Creates a session state.
  const LabyrinthSessionState({
    required this.board,
    this.elapsedMs = 0,
    this.solved = false,
    this.reviewMode = false,
    this.replayInProgress = false,
    this.solvedAt,
    this.firstSolveElapsedMs,
    this.winSeq = 0,
    this.rev = 0,
  });

  /// A fresh, all-defaults session state for [puzzle].
  factory LabyrinthSessionState.initial(LabyrinthPuzzle puzzle) =>
      LabyrinthSessionState(board: LabyrinthBoard.fromPuzzle(puzzle));

  /// The current board status snapshot.
  LabyrinthStatus get status => board.status();

  /// Returns a copy with the given fields replaced. Pass `null` explicitly
  /// for [solvedAt] or [firstSolveElapsedMs] to clear them; omit to leave
  /// unchanged.
  LabyrinthSessionState copyWith({
    LabyrinthBoard? board,
    int? elapsedMs,
    bool? solved,
    bool? reviewMode,
    bool? replayInProgress,
    Object? solvedAt = _unset,
    Object? firstSolveElapsedMs = _unset,
    int? winSeq,
    int? rev,
  }) {
    return LabyrinthSessionState(
      board: board ?? this.board,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      solved: solved ?? this.solved,
      reviewMode: reviewMode ?? this.reviewMode,
      replayInProgress: replayInProgress ?? this.replayInProgress,
      solvedAt: identical(solvedAt, _unset) ? this.solvedAt : solvedAt as String?,
      firstSolveElapsedMs:
          identical(firstSolveElapsedMs, _unset) ? this.firstSolveElapsedMs : firstSolveElapsedMs as int?,
      winSeq: winSeq ?? this.winSeq,
      rev: rev ?? this.rev,
    );
  }
}

/// Per-puzzle session provider family: one [LabyrinthSessionNotifier]
/// instance per puzzle id. The session is disposed once its last listener
/// goes away (`autoDispose`), which flushes its final state via
/// [Notifier.ref]'s `onDispose` before teardown — so no stale in-memory
/// copy can later overwrite progress that was imported (or otherwise
/// changed) while the session was gone.
final labyrinthSessionProvider =
    NotifierProvider.autoDispose.family<LabyrinthSessionNotifier, LabyrinthSessionState, String>(
  LabyrinthSessionNotifier.new,
);

/// Owns one puzzle's play session: board mutation, the elapsed-time
/// stopwatch, reset/replay actions, auto-win detection, and coalesced
/// autosave via an injected [SaveService].
class LabyrinthSessionNotifier extends Notifier<LabyrinthSessionState> {
  /// Creates a session notifier for [puzzleId].
  LabyrinthSessionNotifier(this.puzzleId);

  /// The id of the puzzle this session plays.
  final String puzzleId;

  late final LabyrinthPuzzle _puzzle;
  late final SaveService _saveService;

  final Stopwatch _stopwatch = Stopwatch();
  int _accumulatedMs = 0;

  Map<String, dynamic>? _solvedSnapshotJson;

  /// The most recently captured save payload for this puzzle, refreshed from
  /// [state] whenever the session changes in a normal (non-lifecycle)
  /// context. The onDispose flush persists THIS, never [state] directly:
  /// Riverpod forbids reading `state`/`ref` inside a lifecycle callback.
  Map<String, dynamic>? _lastPayload;

  Timer? _saveTimer;
  static const Duration _saveDebounce = Duration(milliseconds: 300);

  @override
  LabyrinthSessionState build() {
    final puzzles = ref.watch(labyrinthPuzzlesProvider).requireValue;
    _puzzle = puzzles.firstWhere((p) => p.id == puzzleId);
    _saveService = ref.read(labyrinthSaveServiceProvider);

    ref.onDispose(() {
      _saveTimer?.cancel();
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _accumulatedMs += _stopwatch.elapsedMilliseconds;
      }
      // Best-effort final flush of the last captured payload. Must NOT read
      // [state] or [ref] here.
      unawaited(_flush());
    });

    unawaited(_loadPersisted());
    return LabyrinthSessionState.initial(_puzzle);
  }

  /// Current total elapsed time, including any running stopwatch time.
  int get currentElapsedMs => _accumulatedMs + _stopwatch.elapsedMilliseconds;

  Future<void> _loadPersisted() async {
    final namespaceData = await _saveService.load(labyrinthSaveNamespace);
    if (!ref.mounted) return;
    final puzzlesMap = namespaceData['puzzles'];
    final entry = (puzzlesMap is Map) ? puzzlesMap[puzzleId] : null;
    if (entry is! Map) return;

    // fromJson is tolerant of missing/corrupt chain data and falls back to
    // a fresh board on any defect — no extra validation needed here.
    final board = LabyrinthBoard.fromJson(_puzzle, <String, dynamic>{
      'chainA': entry['chainA'],
      'chainZ': entry['chainZ'],
      'crosses': entry['crosses'],
      'marks': entry['marks'],
    });
    final elapsedMs = (entry['elapsedMs'] as num?)?.toInt() ?? 0;
    final solved = entry['solved'] == true;

    _accumulatedMs = elapsedMs;
    _solvedSnapshotJson = solved ? board.toJson() : null;

    state = LabyrinthSessionState(
      board: board,
      elapsedMs: elapsedMs,
      solved: solved,
      reviewMode: solved,
      solvedAt: entry['solvedAt'] as String?,
      firstSolveElapsedMs: (entry['firstSolveElapsedMs'] as num?)?.toInt(),
      rev: state.rev + 1,
    );
    _lastPayload = _buildEntryPayload();
  }

  /// Applies a tap at [cell]. A no-op while the board is locked for review.
  void tapCell(Cell cell) {
    if (state.reviewMode) return;
    state.board.tap(cell);
    state = state.copyWith(rev: state.rev + 1);
    _afterMutation();
  }

  /// Applies a long-press at [cell]. A no-op while the board is locked for
  /// review.
  void longPressCell(Cell cell) {
    if (state.reviewMode) return;
    state.board.longPress(cell);
    state = state.copyWith(rev: state.rev + 1);
    _afterMutation();
  }

  /// Toggles the "must be on path" mark at [cell]. A no-op while the board
  /// is locked for review.
  void markCell(Cell cell) {
    if (state.reviewMode) return;
    state.board.toggleMark(cell);
    state = state.copyWith(rev: state.rev + 1);
    _afterMutation();
  }

  /// Clears both chains and manual crosses. Only valid for an unsolved
  /// puzzle.
  void reset() {
    if (state.solved) return;
    state.board.reset();
    state = state.copyWith(rev: state.rev + 1);
    _scheduleSave();
  }

  /// Clears the board for a fresh attempt on an already-solved puzzle,
  /// without touching the completion record.
  void startReplay() {
    if (!state.solved) return;
    state.board.reset();
    state = state.copyWith(reviewMode: false, replayInProgress: true, rev: state.rev + 1);
  }

  /// If a replay was started but not completed, discards it and restores
  /// the original solved board.
  void abandonReplayIfUnfinished() {
    if (!ref.mounted) return;
    if (!state.replayInProgress || state.board.status().isSolved) return;
    final snapshot = _solvedSnapshotJson;
    final board = snapshot != null
        ? LabyrinthBoard.fromJson(_puzzle, snapshot)
        : LabyrinthBoard.fromPuzzle(_puzzle);
    state = state.copyWith(
      board: board,
      reviewMode: true,
      replayInProgress: false,
      rev: state.rev + 1,
    );
  }

  /// Starts the elapsed-time stopwatch.
  void resumeTimer() {
    if (state.solved && !state.replayInProgress) return;
    if (!_stopwatch.isRunning) _stopwatch.start();
  }

  /// Stops the stopwatch and folds its running time into the accumulated
  /// total.
  void pauseTimer() {
    if (!ref.mounted) return;
    if (!_stopwatch.isRunning) return;
    _stopwatch.stop();
    _accumulatedMs += _stopwatch.elapsedMilliseconds;
    _stopwatch.reset();
    state = state.copyWith(elapsedMs: currentElapsedMs);
    _scheduleSave();
  }

  void _afterMutation() {
    _maybeAutoWin();
    _scheduleSave();
  }

  void _maybeAutoWin() {
    if (!state.board.status().isSolved) return;
    final isFirstSolve = !state.solved;
    final nowIso = DateTime.now().toIso8601String();
    _solvedSnapshotJson = state.board.toJson();
    state = state.copyWith(
      solved: true,
      reviewMode: true,
      replayInProgress: false,
      solvedAt: state.solvedAt ?? nowIso,
      firstSolveElapsedMs: isFirstSolve ? currentElapsedMs : state.firstSolveElapsedMs,
      winSeq: state.winSeq + 1,
      rev: state.rev + 1,
    );
    // A win must never be lost to debounce coalescing.
    _lastPayload = _buildEntryPayload();
    unawaited(_flush());
  }

  void _scheduleSave() {
    // Capture the payload now, while in a valid (non-lifecycle) context.
    _lastPayload = _buildEntryPayload();
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, () => unawaited(_flush()));
  }

  Map<String, dynamic> _buildEntryPayload() {
    final boardJson = state.replayInProgress
        ? (_solvedSnapshotJson ?? const <String, dynamic>{'chainA': [], 'chainZ': [], 'crosses': []})
        : state.board.toJson();
    return <String, dynamic>{
      // The board's three keys are flattened alongside the metadata below,
      // rather than nested under a "board" key, so that a save entry has a
      // single flat shape shared by all fields.
      ...boardJson,
      'elapsedMs': state.elapsedMs,
      'solved': state.solved,
      // Wall-clock stamp of this write. Read by ProgressBundleService's
      // merge ladder to break ties between two devices' copies of the
      // same puzzle. Absent on entries written before this field existed;
      // the merge tolerates null. Dropping this (or solvedAt /
      // firstSolveElapsedMs below) would make progress_merge.dart fall
      // through to its lowest-priority rung, where the LARGER elapsedMs
      // wins — silently keeping the slower of two solves after a sync.
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      if (state.solvedAt != null) 'solvedAt': state.solvedAt,
      if (state.firstSolveElapsedMs != null) 'firstSolveElapsedMs': state.firstSolveElapsedMs,
    };
  }

  /// Persists the last captured payload, merged into the namespace. Reads
  /// only plain fields ([_lastPayload], [_saveService]) so it is safe to
  /// call from the onDispose lifecycle. A no-op if nothing was ever
  /// captured (the puzzle was opened but never touched).
  Future<void> _flush() async {
    _saveTimer?.cancel();
    final entry = _lastPayload;
    if (entry == null) return;
    final namespaceData = await _saveService.load(labyrinthSaveNamespace);
    final merged = Map<String, dynamic>.from(namespaceData);
    final rawPuzzles = namespaceData['puzzles'];
    final puzzlesMap =
        (rawPuzzles is Map) ? Map<String, dynamic>.from(rawPuzzles) : <String, dynamic>{};
    puzzlesMap[puzzleId] = entry;
    merged['puzzles'] = puzzlesMap;
    await _saveService.save(labyrinthSaveNamespace, merged);
  }
}
