import 'package:module_rebus/module_rebus.dart';
import 'package:test/test.dart';

void main() {
  test('evaluates strictly left to right, with no operator precedence', () {
    // 1 + 2 * 2 * 5, left to right: ((1 + 2) * 2) * 5 = 30, NOT 21.
    expect(evalLeftToRight([1, 2, 2, 5], ['+', '*', '*']), 30);
  });

  test('exact division succeeds', () {
    // ((17 + 3) : 5) * 8 = (20 : 5) * 8 = 4 * 8 = 32.
    expect(evalLeftToRight([17, 3, 5, 8], ['+', ':', '*']), 32);
  });

  test('non-exact division returns null', () {
    expect(evalLeftToRight([7, 2], [':']), isNull);
  });

  test('division by zero returns null', () {
    expect(evalLeftToRight([5, 0], [':']), isNull);
  });

  test('a negative intermediate value with an exact division still evaluates', () {
    // (2 - 8) : 3 = -6 : 3 = -2 (exact).
    expect(evalLeftToRight([2, 8, 3], ['-', ':']), -2);
  });

  test('a negative intermediate value with a non-exact division returns null', () {
    // (2 - 8) : 4 = -6 : 4, not exact.
    expect(evalLeftToRight([2, 8, 4], ['-', ':']), isNull);
  });
}
