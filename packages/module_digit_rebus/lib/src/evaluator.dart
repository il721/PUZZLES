/// Evaluates a digit-rebus line strictly left to right - there is no
/// operator precedence: `((nums[0] ops[0] nums[1]) ops[1] nums[2])`.
///
/// Requires `nums.length == ops.length + 1`. Supported operators are `+`,
/// `-`, `*`, and `:` (exact integer division).
///
/// Module-02 semantics (deliberately stricter than module_rebus, whose
/// evaluator permits negative intermediates): every intermediate value
/// must be a non-negative integer. A step that goes negative, divides by
/// zero, or divides inexactly invalidates the whole line and this function
/// returns `null`.
int? evalLeftToRight(List<int> nums, List<String> ops) {
  if (nums.isEmpty || nums.length != ops.length + 1) {
    throw ArgumentError(
      'nums.length (${nums.length}) must equal ops.length + 1 (${ops.length + 1})',
    );
  }

  var acc = nums.first;
  for (var i = 0; i < ops.length; i++) {
    final next = nums[i + 1];
    switch (ops[i]) {
      case '+':
        acc = acc + next;
        break;
      case '-':
        acc = acc - next;
        if (acc < 0) {
          return null;
        }
        break;
      case '*':
        acc = acc * next;
        break;
      case ':':
        if (next == 0 || acc % next != 0) {
          return null;
        }
        acc = acc ~/ next;
        break;
      default:
        throw ArgumentError.value(ops[i], 'ops[$i]', 'Unsupported operator');
    }
  }
  return acc;
}

/// Whether the four cells of a line satisfy its equation
/// `c1 op1 c2 op2 c3 = c4` under [evalLeftToRight] semantics.
bool lineHolds(List<int> cells, List<String> ops) {
  assert(cells.length == 4 && ops.length == 2);
  final value = evalLeftToRight(cells.sublist(0, 3), ops);
  return value != null && value == cells[3];
}
