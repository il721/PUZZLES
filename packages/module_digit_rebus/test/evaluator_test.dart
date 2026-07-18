import 'package:module_digit_rebus/module_digit_rebus.dart';
import 'package:test/test.dart';

void main() {
  group('evalLeftToRight', () {
    test('evaluates strictly left to right, no precedence', () {
      expect(evalLeftToRight([1, 2, 3], ['+', '*']), 9); // (1+2)*3
      expect(evalLeftToRight([4, 8, 6], ['+', ':']), 2); // (4+8):6
    });

    test('allows multi-digit intermediates', () {
      expect(evalLeftToRight([8, 3, 4], ['*', ':']), 6); // 24:4
    });

    test('returns null when subtraction goes negative', () {
      expect(evalLeftToRight([2, 8, 1], ['-', '+']), isNull);
    });

    test('zero as a value is fine when no rule is violated', () {
      expect(evalLeftToRight([5, 5, 3], ['-', '*']), 0);
      expect(evalLeftToRight([0, 4, 2], ['+', ':']), 2);
    });

    test('returns null on division by zero', () {
      expect(evalLeftToRight([5, 0, 1], [':', '+']), isNull);
    });

    test('returns null on inexact division', () {
      expect(evalLeftToRight([5, 3, 1], [':', '+']), isNull);
    });

    test('zero divided by nonzero is exact', () {
      expect(evalLeftToRight([0, 7, 2], [':', '+']), 2);
    });

    test('throws on unsupported operator', () {
      expect(() => evalLeftToRight([1, 2, 3], ['x', '+']),
          throwsArgumentError);
    });

    test('throws on length mismatch', () {
      expect(() => evalLeftToRight([1, 2], ['+', '-']), throwsArgumentError);
    });
  });

  group('lineHolds', () {
    test('holds for a valid book line', () {
      expect(lineHolds([4, 2, 6, 8], [':', '+']), isTrue);
    });

    test('fails when the result differs', () {
      expect(lineHolds([4, 2, 6, 9], [':', '+']), isFalse);
    });

    test('fails (not crashes) when evaluation is invalid', () {
      expect(lineHolds([1, 5, 2, 0], ['-', '+']), isFalse);
      expect(lineHolds([5, 0, 2, 2], [':', '+']), isFalse);
    });
  });
}
