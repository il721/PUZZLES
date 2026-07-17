import 'model.dart';
import 'verifier.dart';

/// One candidate assignment of a single row's four operands, together with
/// the row value they evaluate to.
class _RowCandidate {
  final List<int> operands;
  final int value;
  const _RowCandidate(this.operands, this.value);
}

/// Applies a single left-to-right arithmetic step `a op b`. Returns `null`
/// if `op` is `:` and the division is by zero or not exact (checked
/// sign-robustly via [int.remainder]).
int? _applyOp(int a, int b, String op) {
  switch (op) {
    case '+':
      return a + b;
    case '-':
      return a - b;
    case '*':
      return a * b;
    case ':':
      if (b == 0 || a.remainder(b) != 0) {
        return null;
      }
      return a ~/ b;
    default:
      throw ArgumentError.value(op, 'op', 'Unsupported operator');
  }
}

int _pow10(int n) {
  var result = 1;
  for (var i = 0; i < n; i++) {
    result *= 10;
  }
  return result;
}

/// Every positive integer with exactly [width] decimal digits (implying no
/// leading zero) that agrees with [givenDigits] (a position -> digit map)
/// at every given position.
List<int> _candidatesForWidth(int width, Map<int, int> givenDigits) {
  if (width <= 0) return const <int>[];
  final low = width == 1 ? 1 : _pow10(width - 1);
  final high = _pow10(width) - 1;

  final candidates = <int>[];
  for (var v = low; v <= high; v++) {
    final s = v.toString();
    var matches = true;
    for (final entry in givenDigits.entries) {
      final pos = entry.key;
      if (pos < 0 || pos >= s.length || s.codeUnitAt(pos) - 48 != entry.value) {
        matches = false;
        break;
      }
    }
    if (matches) candidates.add(v);
  }
  return candidates;
}

/// The subset of [givens] that constrain coordinate `(row, slot)`, as a
/// position -> digit map.
Map<int, int> _digitsFor(List<Given> givens, int row, int slot) {
  final map = <int, int>{};
  for (final g in givens) {
    if (g.row == row && g.slot == slot) {
      map[g.pos] = g.digit;
    }
  }
  return map;
}

/// Enumerates every assignment of row [r]'s four operands (and the
/// resulting row value) consistent with the row's box widths, its
/// left-to-right arithmetic, and the givens that apply to row [r]'s
/// operand boxes (slots 0-3) and result box (slot 4).
///
/// Enumeration proceeds by depth-first search over the four operand slots,
/// evaluating left to right incrementally so a non-exact or by-zero `:`
/// step prunes that branch immediately rather than being discovered only
/// after all four operands are chosen.
List<_RowCandidate> _generateRowCandidates(int r, RebusRow row, List<Given> givens) {
  final widths = row.nums.map((n) => n.length).toList(growable: false);
  final resultWidth = row.result.length;
  final resultGivens = _digitsFor(givens, r, 4);
  final domains = List<List<int>>.generate(
    4,
    (slot) => _candidatesForWidth(widths[slot], _digitsFor(givens, r, slot)),
  );

  final results = <_RowCandidate>[];
  final chosen = List<int>.filled(4, 0);

  void dfs(int slotIndex, int? acc) {
    if (slotIndex == 4) {
      final v = acc!;
      if (v < 1) return;
      final s = v.toString();
      if (s.length != resultWidth) return;
      for (final entry in resultGivens.entries) {
        final pos = entry.key;
        if (pos < 0 || pos >= s.length || s.codeUnitAt(pos) - 48 != entry.value) {
          return;
        }
      }
      results.add(_RowCandidate(List<int>.from(chosen), v));
      return;
    }

    for (final candidate in domains[slotIndex]) {
      chosen[slotIndex] = candidate;
      int? newAcc;
      if (slotIndex == 0) {
        newAcc = candidate;
      } else {
        newAcc = _applyOp(acc!, candidate, row.ops[slotIndex - 1]);
        if (newAcc == null) continue;
      }
      dfs(slotIndex + 1, newAcc);
    }
  }

  dfs(0, null);
  return results;
}

/// Counts distinct solutions of [p] exactly as the player sees it: only the
/// digits listed in [p.givens] are fixed, every other box is free subject
/// to its box width and the puzzle's arithmetic/column/summary/total
/// constraints. Counting stops as soon as [cap] solutions have been found,
/// so this is safe to call even on puzzles with many solutions.
int countSolutions(RebusPuzzle p, {int cap = 2}) {
  var count = 0;
  _forEachSolution(p, cap: cap, onSolution: (_) => count++);
  return count;
}

/// Like [countSolutions], but returns the operand grids themselves. Each
/// returned solution is `solution[row][slot]`, the value placed in that
/// operand box. Capped at [cap] solutions. Intended for tests that need to
/// inspect what the solver actually found (e.g. to confirm the canonical
/// grid is among the solutions, or that a deliberately under-constrained
/// puzzle yields more than one).
List<List<List<int>>> collectSolutions(RebusPuzzle p, {int cap = 2}) {
  final solutions = <List<List<int>>>[];
  _forEachSolution(
    p,
    cap: cap,
    onSolution: (rows) {
      solutions.add(rows.map((c) => List<int>.from(c.operands)).toList(growable: false));
    },
  );
  return solutions;
}

/// Cheap check that the puzzle's canonical (author-supplied) solution is
/// itself internally consistent, i.e. that [verifyCanonical] reports no
/// violations.
bool canonicalIsASolution(RebusPuzzle p) => verifyCanonical(p).isEmpty;

/// Core search: joins each row's candidates (from [_generateRowCandidates])
/// row by row via depth-first search, invoking [onSolution] for every full
/// assignment that satisfies the column, summary, and total constraints,
/// until [cap] solutions have been reported.
///
/// Pruning while joining rows 0..3 is sound by construction: after row `r`
/// has just been chosen, for column `j`:
///  * if `j <= r`, row `j` has already been chosen, so the target the
///    column must eventually sum to is *known* (row `j`'s chosen value) —
///    pruning compares against that known value.
///  * if `j > r`, row `j` has not been chosen yet, so pruning only ever
///    compares against the *fixed* min/max of row `j`'s own result-pattern
///    (computed once, up front, from its box width and givens) — never
///    against a value guessed elsewhere in the search. This is what makes
///    the pruning safe: it can narrow the search, but it can never discard
///    a partial assignment that could still be completed into a valid
///    solution.
void _forEachSolution(
  RebusPuzzle p, {
  required int cap,
  required void Function(List<_RowCandidate> rows) onSolution,
}) {
  if (cap <= 0) return;

  final candidatesByRow = List<List<_RowCandidate>>.generate(
    4,
    (r) => _generateRowCandidates(r, p.rows[r], p.givens),
  );
  for (final list in candidatesByRow) {
    if (list.isEmpty) return;
  }

  // Per-row, per-column min/max operand value — used to bound the
  // achievable range of a column's final sum for rows not yet chosen.
  final columnMin = List<List<int>>.generate(
    4,
    (r) => List<int>.generate(
      4,
      (j) => candidatesByRow[r].map((c) => c.operands[j]).reduce((a, b) => a < b ? a : b),
    ),
  );
  final columnMax = List<List<int>>.generate(
    4,
    (r) => List<int>.generate(
      4,
      (j) => candidatesByRow[r].map((c) => c.operands[j]).reduce((a, b) => a > b ? a : b),
    ),
  );

  // Fixed result-pattern bounds for each row's own value (from its box
  // width + its own result-box givens only) — independent of any choice
  // made elsewhere in the search.
  final resultMin = List<int>.generate(
    4,
    (r) => candidatesByRow[r].map((c) => c.value).reduce((a, b) => a < b ? a : b),
  );
  final resultMax = List<int>.generate(
    4,
    (r) => candidatesByRow[r].map((c) => c.value).reduce((a, b) => a > b ? a : b),
  );

  final summaryGivens = List<Map<int, int>>.generate(4, (j) => _digitsFor(p.givens, 4, j));
  final totalGivens = _digitsFor(p.givens, 4, 4);
  final totalWidth = p.total.length;

  var found = 0;
  final chosenRows = List<_RowCandidate?>.filled(4, null);
  final partialColumnSum = List<int>.filled(4, 0);

  void dfs(int r) {
    if (found >= cap) return;

    if (r == 4) {
      for (var j = 0; j < 4; j++) {
        if (partialColumnSum[j] != chosenRows[j]!.value) return;
      }
      for (var j = 0; j < 4; j++) {
        final s = chosenRows[j]!.value.toString();
        for (final entry in summaryGivens[j].entries) {
          final pos = entry.key;
          if (pos < 0 || pos >= s.length || s.codeUnitAt(pos) - 48 != entry.value) {
            return;
          }
        }
      }
      final total = chosenRows[0]!.value + chosenRows[1]!.value + chosenRows[2]!.value + chosenRows[3]!.value;
      final totalString = total.toString();
      if (totalString.length != totalWidth) return;
      for (final entry in totalGivens.entries) {
        final pos = entry.key;
        if (pos < 0 || pos >= totalString.length || totalString.codeUnitAt(pos) - 48 != entry.value) {
          return;
        }
      }

      found++;
      onSolution(chosenRows.map((c) => c!).toList(growable: false));
      return;
    }

    for (final candidate in candidatesByRow[r]) {
      if (found >= cap) return;

      chosenRows[r] = candidate;
      for (var j = 0; j < 4; j++) {
        partialColumnSum[j] += candidate.operands[j];
      }

      var prunedOut = false;
      for (var j = 0; j < 4; j++) {
        var lo = partialColumnSum[j];
        var hi = partialColumnSum[j];
        for (var future = r + 1; future < 4; future++) {
          lo += columnMin[future][j];
          hi += columnMax[future][j];
        }
        if (j <= r) {
          final target = chosenRows[j]!.value;
          if (target < lo || target > hi) {
            prunedOut = true;
            break;
          }
        } else {
          if (hi < resultMin[j] || lo > resultMax[j]) {
            prunedOut = true;
            break;
          }
        }
      }

      if (!prunedOut) {
        dfs(r + 1);
      }

      for (var j = 0; j < 4; j++) {
        partialColumnSum[j] -= candidate.operands[j];
      }
      chosenRows[r] = null;
    }
  }

  dfs(0);
}
