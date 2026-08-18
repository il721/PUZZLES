import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_playground/module_playground.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'playground_module.dart';
import 'playground_providers.dart';

/// Sentinel used by [PlaygroundSessionState.copyWith] to distinguish "leave
/// this nullable field unchanged" from "set it to null".
class _Unset {
  const _Unset();
}

const Object _unset = _Unset();

/// Immutable snapshot of one game-play session. Unlike
/// `SquarewordSessionState`'s in-place-mutated board, [board] is a fresh
/// [PlaygroundState] instance produced by [PlaygroundGame.applyMove] on
/// every move; [rev] is still bumped on every mutation for structural
/// parity with the sibling controller (a plain equality/identity check on
/// [board] would already suffice here, since token-graph states are
/// content-comparable and every mutation replaces the instance).
class PlaygroundSessionState {
  /// The player's current board state.
  final PlaygroundState board;

  /// Every move applied so far, oldest first. [undo] pops the last entry
  /// and rebuilds [board] by replaying the remainder from
  /// [PlaygroundGame.initialState] — the move counter therefore ROLLS BACK
  /// with undo, by design.
  final List<PlaygroundMove> moveStack;

  /// Whether this game has ever been solved (permanent once true; survives
  /// [PlaygroundSessionNotifier.restart]).
  final bool solved;

  /// The fewest moves this game has ever been solved in, or `null` if never
  /// solved.
  final int? bestMoves;

  /// Total accumulated play time for this game, in milliseconds.
  final int elapsedMs;

  /// ISO-8601 timestamp of the first solve, if solved.
  final String? solvedAt;

  /// Elapsed time (ms) recorded at the first solve, if solved.
  final int? firstSolveElapsedMs;

  /// Revision counter, bumped on every mutation.
  final int rev;

  /// Incremented every time a win is freshly detected.
  final int winSeq;

  /// Creates a session state.
  const PlaygroundSessionState({
    required this.board,
    this.moveStack = const <PlaygroundMove>[],
    this.solved = false,
    this.bestMoves,
    this.elapsedMs = 0,
    this.solvedAt,
    this.firstSolveElapsedMs,
    this.rev = 0,
    this.winSeq = 0,
  });

  /// A fresh, all-defaults session state for [game].
  factory PlaygroundSessionState.initial(PlaygroundGame game) =>
      PlaygroundSessionState(board: game.initialState());

  /// The number of moves currently applied (i.e. `moveStack.length`).
  int get moveCount => moveStack.length;

  /// Returns a copy with the given fields replaced. Pass `null` explicitly
  /// for [bestMoves], [solvedAt], or [firstSolveElapsedMs] to clear them;
  /// omit to leave unchanged.
  PlaygroundSessionState copyWith({
    PlaygroundState? board,
    List<PlaygroundMove>? moveStack,
    bool? solved,
    Object? bestMoves = _unset,
    int? elapsedMs,
    Object? solvedAt = _unset,
    Object? firstSolveElapsedMs = _unset,
    int? rev,
    int? winSeq,
  }) {
    return PlaygroundSessionState(
      board: board ?? this.board,
      moveStack: moveStack ?? this.moveStack,
      solved: solved ?? this.solved,
      bestMoves: identical(bestMoves, _unset) ? this.bestMoves : bestMoves as int?,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      solvedAt: identical(solvedAt, _unset) ? this.solvedAt : solvedAt as String?,
      firstSolveElapsedMs:
          identical(firstSolveElapsedMs, _unset) ? this.firstSolveElapsedMs : firstSolveElapsedMs as int?,
      rev: rev ?? this.rev,
      winSeq: winSeq ?? this.winSeq,
    );
  }
}

/// Per-game session provider family: one [PlaygroundSessionNotifier]
/// instance per game id. The session is disposed once its last listener
/// goes away (`autoDispose`), which flushes its final state via
/// [Notifier.ref]'s `onDispose` before teardown — so no stale in-memory
/// copy can later overwrite progress that was imported (or otherwise
/// changed) while the session was gone.
final playgroundSessionProvider =
    NotifierProvider.autoDispose.family<PlaygroundSessionNotifier, PlaygroundSessionState, String>(
  PlaygroundSessionNotifier.new,
);

/// Owns one game's play session: move application/undo/restart, the
/// elapsed-time stopwatch, auto-win detection, and coalesced autosave via
/// an injected [SaveService].
class PlaygroundSessionNotifier extends Notifier<PlaygroundSessionState> {
  /// Creates a session notifier for [gameId].
  PlaygroundSessionNotifier(this.gameId);

  /// The id of the game this session plays.
  final String gameId;

  late final PlaygroundGame _game;
  late final SaveService _saveService;

  final Stopwatch _stopwatch = Stopwatch();
  int _accumulatedMs = 0;

  /// The most recently captured save payload for this game, refreshed from
  /// [state] whenever the session changes in a normal (non-lifecycle)
  /// context. The onDispose flush persists THIS, never [state] directly:
  /// Riverpod forbids reading `state`/`ref` inside a lifecycle callback.
  Map<String, dynamic>? _lastPayload;

  Timer? _saveTimer;
  static const Duration _saveDebounce = Duration(milliseconds: 300);

  @override
  PlaygroundSessionState build() {
    final games = ref.watch(playgroundPuzzlesProvider).requireValue;
    _game = games.firstWhere((g) => g.id == gameId);
    _saveService = ref.read(playgroundSaveServiceProvider);

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
    return PlaygroundSessionState.initial(_game);
  }

  /// Current total elapsed time, including any running stopwatch time.
  int get currentElapsedMs => _accumulatedMs + _stopwatch.elapsedMilliseconds;

  Future<void> _loadPersisted() async {
    final namespaceData = await _saveService.load(playgroundSaveNamespace);
    if (!ref.mounted) return;
    final puzzlesMap = namespaceData['puzzles'];
    final entry = (puzzlesMap is Map) ? puzzlesMap[gameId] : null;
    if (entry is! Map) return;

    // The stored board field is a corruption gate: an entry whose board
    // data doesn't parse is discarded WHOLE (fresh board, empty stack,
    // solved false, bestMoves null) rather than kept half-fresh alongside a
    // stale `solved: true` — see stateFromJson's contract.
    if (_game.stateFromJson(entry) == null) return;

    final replayed = _tryReplay(entry['moveStack']);
    if (replayed == null) return;

    final elapsedMs = (entry['elapsedMs'] as num?)?.toInt() ?? 0;
    final solved = entry['solved'] == true;

    _accumulatedMs = elapsedMs;

    state = PlaygroundSessionState(
      board: replayed.board,
      moveStack: replayed.moveStack,
      solved: solved,
      bestMoves: (entry['bestMoves'] as num?)?.toInt(),
      elapsedMs: elapsedMs,
      solvedAt: entry['solvedAt'] as String?,
      firstSolveElapsedMs: (entry['firstSolveElapsedMs'] as num?)?.toInt(),
      rev: state.rev + 1,
    );
    _lastPayload = _buildEntryPayload();
  }

  /// Parses and replays [rawMoveStack] (the persisted `moveStack` JSON list)
  /// from [PlaygroundGame.initialState], returning the resulting board and
  /// the parsed move list. Returns `null` on ANY defect: not a list, an
  /// entry that isn't a valid move shape, or a move that is illegal at the
  /// point it is replayed — any of these means the save entry cannot be
  /// trusted and must be discarded as a whole (see [_loadPersisted]).
  ({PlaygroundState board, List<PlaygroundMove> moveStack})? _tryReplay(Object? rawMoveStack) {
    if (rawMoveStack is! List) return null;
    try {
      final moves = rawMoveStack.map((m) => PlaygroundMove.fromJson(m)).toList(growable: false);
      var board = _game.initialState();
      for (final move in moves) {
        board = _game.applyMove(board, move);
      }
      return (board: board, moveStack: moves);
    } catch (_) {
      return null;
    }
  }

  /// Applies [move] to the current board, pushing it onto the move stack
  /// and checking for a fresh win.
  ///
  /// Throws [ArgumentError] if [move] is not currently legal (propagated
  /// from [PlaygroundGame.applyMove]) — callers (board widgets) must only
  /// ever call this with a move drawn from [PlaygroundGame.legalMoves].
  void apply(PlaygroundMove move) {
    final newBoard = _game.applyMove(state.board, move);
    state = state.copyWith(
      board: newBoard,
      moveStack: [...state.moveStack, move],
      rev: state.rev + 1,
    );
    _afterMutation();
  }

  /// Pops the last move and rebuilds the board by replaying the remaining
  /// stack from [PlaygroundGame.initialState] — simple and provably
  /// consistent. The move counter (`moveStack.length`) therefore rolls back
  /// with undo; that is the locked design, not a bug.
  void undo() {
    if (state.moveStack.isEmpty) return;
    final newStack = state.moveStack.sublist(0, state.moveStack.length - 1);
    var board = _game.initialState();
    for (final move in newStack) {
      board = _game.applyMove(board, move);
    }
    state = state.copyWith(board: board, moveStack: newStack, rev: state.rev + 1);
    _scheduleSave();
  }

  /// Clears the move stack and returns the board to its initial state.
  /// Never clears [PlaygroundSessionState.solved] or
  /// [PlaygroundSessionState.bestMoves] — the record survives a restart.
  void restart() {
    state = state.copyWith(
      board: _game.initialState(),
      moveStack: const <PlaygroundMove>[],
      rev: state.rev + 1,
    );
    _scheduleSave();
  }

  /// Starts the elapsed-time stopwatch.
  void resumeTimer() {
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
    if (!_game.isSolved(state.board)) return;
    final isFirstSolve = !state.solved;
    final nowIso = DateTime.now().toIso8601String();
    final moves = state.moveCount;
    final newBest = state.bestMoves == null ? moves : (moves < state.bestMoves! ? moves : state.bestMoves!);
    state = state.copyWith(
      solved: true,
      bestMoves: newBest,
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
    return <String, dynamic>{
      // The board's own JSON fields are flattened alongside the metadata
      // below, rather than nested under a "board" key, so a save entry has
      // a single flat shape shared by all fields (matches
      // module_squareword_ui's `_buildEntryPayload`).
      ..._game.stateToJson(state.board),
      'moveStack': state.moveStack.map((m) => m.toJson()).toList(),
      'moveCount': state.moveCount,
      if (state.bestMoves != null) 'bestMoves': state.bestMoves,
      'solved': state.solved,
      'elapsedMs': state.elapsedMs,
      // Wall-clock stamp of this write. Read by ProgressBundleService's
      // merge ladder to break ties between two devices' copies of the
      // same game. Absent on entries written before this field existed;
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
  /// captured (the game was opened but never touched).
  Future<void> _flush() async {
    _saveTimer?.cancel();
    final entry = _lastPayload;
    if (entry == null) return;
    final namespaceData = await _saveService.load(playgroundSaveNamespace);
    final merged = Map<String, dynamic>.from(namespaceData);
    final rawPuzzles = namespaceData['puzzles'];
    final puzzlesMap =
        (rawPuzzles is Map) ? Map<String, dynamic>.from(rawPuzzles) : <String, dynamic>{};
    puzzlesMap[gameId] = entry;
    merged['puzzles'] = puzzlesMap;
    await _saveService.save(playgroundSaveNamespace, merged);
  }
}
