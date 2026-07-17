/// Evaluates a rebus row's arithmetic strictly left to right — there is no
/// operator precedence: `((nums[0] ops[0] nums[1]) ops[1] nums[2]) ops[2]
/// nums[3]`.
///
/// Requires `nums.length == ops.length + 1`. Supported operators are `+`,
/// `-`, `*`, and `:` (integer division). Division is only valid when the
/// divisor is non-zero and the division is exact (checked sign-robustly
/// via [int.remainder], so it works correctly for negative intermediate
/// values); any violation makes the whole row invalid and this function
/// returns `null`. Intermediate values are otherwise allowed to be
/// negative.
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
        break;
      case '*':
        acc = acc * next;
        break;
      case ':':
        if (next == 0 || acc.remainder(next) != 0) {
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
