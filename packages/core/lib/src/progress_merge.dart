/// Pure, I/O-free merge rules for combining two devices' copies of the same
/// save namespace.
///
/// The guiding property is that merging never loses a better result: for a
/// puzzle present on both sides the winner is the copy representing more
/// progress, judged by a fixed ladder (see [mergePuzzleEntry]). Merging is
/// idempotent — importing the same bundle twice is a no-op.
library;

/// How many puzzle entries a namespace merge created, replaced, or left
/// alone.
class NamespaceCounts {
  /// Puzzles present only in the incoming data.
  final int added;

  /// Puzzles present on both sides where the incoming copy won.
  final int updated;

  /// Puzzles the merge left as they were.
  final int unchanged;

  /// Creates a count triple.
  const NamespaceCounts({this.added = 0, this.updated = 0, this.unchanged = 0});

  /// Sums two count triples, so a caller can total across namespaces.
  NamespaceCounts operator +(NamespaceCounts other) => NamespaceCounts(
        added: added + other.added,
        updated: updated + other.updated,
        unchanged: unchanged + other.unchanged,
      );
}

/// The merged namespace data plus what the merge did.
class NamespaceMergeResult {
  /// The merged `data` map, ready to hand to `SaveService.save`.
  final Map<String, dynamic> data;

  /// What changed.
  final NamespaceCounts counts;

  /// Creates a result.
  const NamespaceMergeResult(this.data, this.counts);
}

int? _asInt(Object? v) => v is num ? v.toInt() : null;

String? _asString(Object? v) => v is String ? v : null;

bool _isSolved(Map<String, dynamic> e) => e['solved'] == true;

/// Compares [local] and [incoming] on one rung. Returns a negative number if
/// local wins, positive if incoming wins, 0 if the rung cannot decide.
///
/// [lower] selects whether a smaller value is better (solve times) or a
/// larger one (timestamps, elapsed time). A present value always beats an
/// absent one.
int _rungInt(int? local, int? incoming, {required bool lower}) {
  if (local == null && incoming == null) return 0;
  if (local == null) return 1;
  if (incoming == null) return -1;
  if (local == incoming) return 0;
  final localBetter = lower ? local < incoming : local > incoming;
  return localBetter ? -1 : 1;
}

int _rungEarlierString(String? local, String? incoming) {
  if (local == null && incoming == null) return 0;
  if (local == null) return 1;
  if (incoming == null) return -1;
  final cmp = local.compareTo(incoming);
  if (cmp == 0) return 0;
  return cmp < 0 ? -1 : 1;
}

/// Picks the winning copy of a single puzzle's save entry.
///
/// Returns the winning map *whole* — never a field-wise blend, because an
/// entry's board state and its timings must stay consistent with each other.
/// Ties resolve to [local], which makes re-importing the same bundle a no-op.
Map<String, dynamic> mergePuzzleEntry(
  Map<String, dynamic> local,
  Map<String, dynamic> incoming,
) {
  // Rung 1: solved beats unsolved.
  final localSolved = _isSolved(local);
  final incomingSolved = _isSolved(incoming);
  if (localSolved != incomingSolved) {
    return localSolved ? local : incoming;
  }

  if (localSolved) {
    // Rung 2: the better first-solve time.
    final byFirstSolve = _rungInt(
      _asInt(local['firstSolveElapsedMs']),
      _asInt(incoming['firstSolveElapsedMs']),
      lower: true,
    );
    if (byFirstSolve != 0) return byFirstSolve < 0 ? local : incoming;

    // Rung 3: whoever solved it first.
    final bySolvedAt = _rungEarlierString(
      _asString(local['solvedAt']),
      _asString(incoming['solvedAt']),
    );
    if (bySolvedAt != 0) return bySolvedAt < 0 ? local : incoming;
  }

  // Rung 4: the more recent write. Entries saved by builds older than the
  // updatedAt field have none, and lose to any entry that does.
  final byUpdatedAt = _rungInt(
    _asInt(local['updatedAt']),
    _asInt(incoming['updatedAt']),
    lower: false,
  );
  if (byUpdatedAt != 0) return byUpdatedAt < 0 ? local : incoming;

  // Rung 5: the copy with more time invested.
  final byElapsed = _rungInt(
    _asInt(local['elapsedMs']),
    _asInt(incoming['elapsedMs']),
    lower: false,
  );
  if (byElapsed != 0) return byElapsed < 0 ? local : incoming;

  // Rung 6: dead tie — keep local.
  return local;
}

/// Merges the `tutorial` block. Completed beats not-completed; if both are
/// completed the earlier `completedAt` is kept, so the record reflects when
/// the player actually first finished it.
Map<String, dynamic>? mergeTutorialBlock(
  Map<String, dynamic>? local,
  Map<String, dynamic>? incoming,
) {
  if (local == null) return incoming;
  if (incoming == null) return local;

  final localDone = local['completed'] == true;
  final incomingDone = incoming['completed'] == true;
  if (localDone != incomingDone) return localDone ? local : incoming;
  if (!localDone) return local;

  final cmp = _rungEarlierString(
    _asString(local['completedAt']),
    _asString(incoming['completedAt']),
  );
  return cmp <= 0 ? local : incoming;
}

Map<String, dynamic> _puzzlesOf(Map<String, dynamic> data) {
  final raw = data['puzzles'];
  return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
}

/// Merges one namespace's whole `data` map.
///
/// The `puzzles` maps are unioned entry-by-entry through [mergePuzzleEntry];
/// the `tutorial` block through [mergeTutorialBlock]; any other top-level key
/// is carried over, with the local value winning a conflict (the app cannot
/// know how to merge a key it does not understand, and the local device's
/// copy is the one the player is standing in front of).
NamespaceMergeResult mergeNamespaceData(
  Map<String, dynamic> local,
  Map<String, dynamic> incoming,
) {
  final merged = Map<String, dynamic>.from(local);

  for (final entry in incoming.entries) {
    if (entry.key == 'puzzles' || entry.key == 'tutorial') continue;
    if (!merged.containsKey(entry.key)) merged[entry.key] = entry.value;
  }

  final localPuzzles = _puzzlesOf(local);
  final incomingPuzzles = _puzzlesOf(incoming);
  final mergedPuzzles = Map<String, dynamic>.from(localPuzzles);

  var added = 0;
  var updated = 0;
  var unchanged = 0;

  for (final id in localPuzzles.keys) {
    if (!incomingPuzzles.containsKey(id)) unchanged++;
  }

  for (final entry in incomingPuzzles.entries) {
    final incomingEntry = entry.value;
    if (incomingEntry is! Map) continue;
    final incomingMap = Map<String, dynamic>.from(incomingEntry);

    final localEntry = localPuzzles[entry.key];
    if (localEntry is! Map) {
      mergedPuzzles[entry.key] = incomingMap;
      added++;
      continue;
    }

    final localMap = Map<String, dynamic>.from(localEntry);
    final winner = mergePuzzleEntry(localMap, incomingMap);
    mergedPuzzles[entry.key] = winner;
    if (identical(winner, localMap)) {
      unchanged++;
    } else {
      updated++;
    }
  }

  merged['puzzles'] = mergedPuzzles;

  final localTutorial = local['tutorial'];
  final incomingTutorial = incoming['tutorial'];
  final mergedTutorial = mergeTutorialBlock(
    localTutorial is Map ? Map<String, dynamic>.from(localTutorial) : null,
    incomingTutorial is Map ? Map<String, dynamic>.from(incomingTutorial) : null,
  );
  if (mergedTutorial != null) merged['tutorial'] = mergedTutorial;

  return NamespaceMergeResult(
    merged,
    NamespaceCounts(added: added, updated: updated, unchanged: unchanged),
  );
}
