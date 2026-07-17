import 'evaluator.dart';
import 'model.dart';

/// Validates a [RebusPuzzle]'s canonical (author-supplied) solution.
///
/// Returns a list of human-readable violation descriptions; an empty list
/// means the puzzle's authored data is internally consistent. Checks, in
/// order:
///  * every operand, row result, and the total is 1-3 digits, parses as an
///    integer in `1..999`, and has no leading zero;
///  * each row evaluates, strictly left to right, to exactly its `result`;
///  * for each column `j` (0..3), the sum of `rows[*].nums[j]` equals
///    `rows[j].result`;
///  * `total` equals the sum of the four rows' results;
///  * every given digit matches the canonical digit at its coordinate,
///    including summary-row givens (the column-sum boxes and the total
///    box).
List<String> verifyCanonical(RebusPuzzle p) {
  final violations = <String>[];

  void checkNumberFormat(String label, String s) {
    if (s.isEmpty || s.length > 3) {
      violations.add('$label: "$s" must be 1-3 digits');
      return;
    }
    if (s.length > 1 && s.startsWith('0')) {
      violations.add('$label: "$s" has a leading zero');
      return;
    }
    final v = int.tryParse(s);
    if (v == null || v < 1 || v > 999) {
      violations.add('$label: "$s" is not an integer in 1..999');
    }
  }

  for (var r = 0; r < p.rows.length; r++) {
    final row = p.rows[r];
    for (var j = 0; j < row.nums.length; j++) {
      checkNumberFormat('row $r operand $j', row.nums[j]);
    }
    checkNumberFormat('row $r result', row.result);
  }
  checkNumberFormat('total', p.total);

  if (violations.isNotEmpty) {
    // Arithmetic/given checks below assume every number parses cleanly.
    return violations;
  }

  for (var r = 0; r < p.rows.length; r++) {
    final row = p.rows[r];
    final nums = row.nums.map(int.parse).toList(growable: false);
    final expected = int.parse(row.result);
    final actual = evalLeftToRight(nums, row.ops);
    if (actual == null) {
      violations.add('row $r: evaluation is invalid (division by zero or non-exact)');
    } else if (actual != expected) {
      violations.add('row $r: evaluates to $actual, expected $expected');
    }
  }

  for (var j = 0; j < 4; j++) {
    var sum = 0;
    for (final row in p.rows) {
      sum += int.parse(row.nums[j]);
    }
    final expected = int.parse(p.rows[j].result);
    if (sum != expected) {
      violations.add('column $j: sum $sum does not equal row $j result $expected');
    }
  }

  final resultsSum = p.rows.fold<int>(0, (acc, row) => acc + int.parse(row.result));
  final totalValue = int.parse(p.total);
  if (resultsSum != totalValue) {
    violations.add('total: $totalValue does not equal sum of results $resultsSum');
  }

  String canonicalStringAt(int row, int slot) {
    if (row >= 0 && row <= 3) {
      if (slot >= 0 && slot <= 3) return p.rows[row].nums[slot];
      if (slot == 4) return p.rows[row].result;
    } else if (row == 4) {
      if (slot >= 0 && slot <= 3) return p.rows[slot].result;
      if (slot == 4) return p.total;
    }
    throw ArgumentError('Invalid given coordinate: row=$row slot=$slot');
  }

  for (final g in p.givens) {
    String target;
    try {
      target = canonicalStringAt(g.row, g.slot);
    } on ArgumentError {
      violations.add('given (${g.row},${g.slot},${g.pos}): invalid coordinate');
      continue;
    }
    if (g.pos < 0 || g.pos >= target.length) {
      violations.add(
        'given (${g.row},${g.slot},${g.pos}): position out of range for "$target"',
      );
      continue;
    }
    final actualDigit = target.codeUnitAt(g.pos) - '0'.codeUnitAt(0);
    if (actualDigit != g.digit) {
      violations.add(
        'given (${g.row},${g.slot},${g.pos}): expected digit ${g.digit} but canonical digit is $actualDigit ("$target")',
      );
    }
  }

  return violations;
}
