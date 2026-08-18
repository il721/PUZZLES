import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> entry({
  bool solved = false,
  int? bestMoves,
  int? firstSolveElapsedMs,
  String? solvedAt,
  int? updatedAt,
  int elapsedMs = 0,
  String tag = 'x',
}) {
  return <String, dynamic>{
    'solved': solved,
    'elapsedMs': elapsedMs,
    'tag': tag,
    if (bestMoves != null) 'bestMoves': bestMoves,
    if (firstSolveElapsedMs != null) 'firstSolveElapsedMs': firstSolveElapsedMs,
    if (solvedAt != null) 'solvedAt': solvedAt,
    if (updatedAt != null) 'updatedAt': updatedAt,
  };
}

void main() {
  group('mergePuzzleEntry ladder', () {
    test('rung 1: solved beats unsolved regardless of timestamps', () {
      final local = entry(solved: false, updatedAt: 9999, tag: 'local');
      final incoming = entry(solved: true, updatedAt: 1, tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'incoming');
      expect(mergePuzzleEntry(incoming, local)['tag'], 'incoming');
    });

    test('rung 2: both solved, fewer bestMoves wins', () {
      final local = entry(solved: true, bestMoves: 30, tag: 'local');
      final incoming = entry(solved: true, bestMoves: 28, tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'incoming');
    });

    test('rung 2: a present bestMoves beats a missing one', () {
      final local = entry(solved: true, tag: 'local');
      final incoming = entry(solved: true, bestMoves: 99, tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'incoming');
    });

    test('rung 2: fewer bestMoves outranks a faster firstSolveElapsedMs', () {
      final local = entry(solved: true, bestMoves: 28, firstSolveElapsedMs: 9000, tag: 'local');
      final incoming = entry(solved: true, bestMoves: 30, firstSolveElapsedMs: 1000, tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'local');
    });

    test('rung 2 abstains when neither side records bestMoves', () {
      final local = entry(solved: true, firstSolveElapsedMs: 5000, tag: 'local');
      final incoming = entry(solved: true, firstSolveElapsedMs: 3000, tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'incoming');
    });

    test('rung 3: both solved, smaller firstSolveElapsedMs wins', () {
      final local = entry(solved: true, firstSolveElapsedMs: 5000, tag: 'local');
      final incoming = entry(solved: true, firstSolveElapsedMs: 3000, tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'incoming');
    });

    test('rung 3: a present firstSolveElapsedMs beats a missing one', () {
      final local = entry(solved: true, tag: 'local');
      final incoming = entry(solved: true, firstSolveElapsedMs: 9999999, tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'incoming');
    });

    test('rung 4: equal solve times, earlier solvedAt wins', () {
      final local = entry(
          solved: true, firstSolveElapsedMs: 1000, solvedAt: '2026-07-20T10:00:00.000', tag: 'local');
      final incoming = entry(
          solved: true, firstSolveElapsedMs: 1000, solvedAt: '2026-07-19T10:00:00.000', tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'incoming');
    });

    test('rung 5: neither solved, larger updatedAt wins', () {
      final local = entry(updatedAt: 100, tag: 'local');
      final incoming = entry(updatedAt: 200, tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'incoming');
    });

    test('rung 5: a present updatedAt beats a legacy entry without one', () {
      final local = entry(tag: 'local');
      final incoming = entry(updatedAt: 1, tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'incoming');
    });

    test('rung 6: no updatedAt on either side, larger elapsedMs wins', () {
      final local = entry(elapsedMs: 10, tag: 'local');
      final incoming = entry(elapsedMs: 20, tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'incoming');
    });

    test('rung 7: a dead tie keeps local', () {
      final local = entry(updatedAt: 5, elapsedMs: 7, tag: 'local');
      final incoming = entry(updatedAt: 5, elapsedMs: 7, tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'local');
    });

    test('returns the winning entry whole, never a field-wise blend', () {
      final local = entry(solved: false, elapsedMs: 999, tag: 'local');
      final incoming = entry(solved: true, elapsedMs: 1, tag: 'incoming');
      final merged = mergePuzzleEntry(local, incoming);
      expect(merged['elapsedMs'], 1);
      expect(merged['tag'], 'incoming');
    });
  });

  group('mergeTutorialBlock', () {
    test('completed beats not completed', () {
      final merged = mergeTutorialBlock(
        {'completed': false},
        {'completed': true, 'completedAt': '2026-01-01T00:00:00.000'},
      );
      expect(merged!['completed'], true);
    });

    test('both completed keeps the earlier completedAt', () {
      final merged = mergeTutorialBlock(
        {'completed': true, 'completedAt': '2026-05-05T00:00:00.000'},
        {'completed': true, 'completedAt': '2026-01-01T00:00:00.000'},
      );
      expect(merged!['completedAt'], '2026-01-01T00:00:00.000');
    });

    test('a null side yields the other side', () {
      expect(mergeTutorialBlock(null, {'completed': true})!['completed'], true);
      expect(mergeTutorialBlock({'completed': true}, null)!['completed'], true);
      expect(mergeTutorialBlock(null, null), isNull);
    });
  });

  group('mergeNamespaceData', () {
    test('unions puzzles from both sides and counts them', () {
      final result = mergeNamespaceData(
        {
          'puzzles': {
            'p01': entry(solved: true, firstSolveElapsedMs: 100, tag: 'local'),
            'p02': entry(updatedAt: 1, tag: 'local'),
          },
        },
        {
          'puzzles': {
            'p02': entry(updatedAt: 2, tag: 'incoming'),
            'p03': entry(updatedAt: 5, tag: 'incoming'),
          },
        },
      );

      final puzzles = result.data['puzzles'] as Map<String, dynamic>;
      expect(puzzles.keys.toSet(), {'p01', 'p02', 'p03'});
      expect((puzzles['p01'] as Map)['tag'], 'local');
      expect((puzzles['p02'] as Map)['tag'], 'incoming');
      expect((puzzles['p03'] as Map)['tag'], 'incoming');
      expect(result.counts.added, 1);
      expect(result.counts.updated, 1);
      expect(result.counts.unchanged, 1);
    });

    test('importing an identical namespace changes nothing', () {
      final local = {
        'puzzles': {'p01': entry(updatedAt: 7, tag: 'local')},
      };
      final result = mergeNamespaceData(local, Map<String, dynamic>.from(local));
      expect(result.counts.added, 0);
      expect(result.counts.updated, 0);
      expect(result.counts.unchanged, 1);
    });

    test('preserves the local tutorial block and unknown top-level keys', () {
      final result = mergeNamespaceData(
        {
          'puzzles': <String, dynamic>{},
          'tutorial': {'completed': true, 'completedAt': '2026-01-01T00:00:00.000'},
          'someFutureKey': 'keep me',
        },
        {'puzzles': <String, dynamic>{}},
      );
      expect((result.data['tutorial'] as Map)['completed'], true);
      expect(result.data['someFutureKey'], 'keep me');
    });

    test('takes an unknown top-level key that only the incoming side has', () {
      final result = mergeNamespaceData(
        {'puzzles': <String, dynamic>{}},
        {'puzzles': <String, dynamic>{}, 'futureKey': 'from other device'},
      );
      expect(result.data['futureKey'], 'from other device');
    });

    test('tolerates a missing or malformed puzzles map on either side', () {
      final result = mergeNamespaceData({}, {'puzzles': 'not a map'});
      expect(result.data['puzzles'], <String, dynamic>{});
      expect(result.counts.added, 0);
    });
  });
}
