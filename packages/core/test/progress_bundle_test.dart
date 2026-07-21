import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  test('encode then decode round-trips namespaces', () {
    final bundle = ProgressBundle(
      bundleVersion: ProgressBundle.currentBundleVersion,
      exportedAt: '2026-07-21T14:03:11.482',
      namespaces: {
        'module_rebus': {
          'puzzles': {
            'p01': {'solved': true, 'elapsedMs': 1200, 'updatedAt': 42},
          },
        },
      },
    );

    final decoded = ProgressBundle.decode(bundle.encode());

    expect(decoded.bundleVersion, 1);
    expect(decoded.exportedAt, '2026-07-21T14:03:11.482');
    expect(decoded.namespaces['module_rebus']!['puzzles'], {
      'p01': {'solved': true, 'elapsedMs': 1200, 'updatedAt': 42},
    });
  });

  test('decode rejects a bundle from a newer app', () {
    const text = '{"bundleVersion":2,"exportedAt":"x","namespaces":{}}';
    expect(
      () => ProgressBundle.decode(text),
      throwsA(isA<BundleFormatException>().having((e) => e.isVersionTooNew, 'isVersionTooNew', true)),
    );
  });

  test('decode rejects unparseable JSON', () {
    expect(() => ProgressBundle.decode('not json'), throwsA(isA<BundleFormatException>()));
  });

  test('decode rejects JSON that is not an object', () {
    expect(() => ProgressBundle.decode('[1,2,3]'), throwsA(isA<BundleFormatException>()));
  });

  test('decode rejects a missing or non-int bundleVersion', () {
    expect(
      () => ProgressBundle.decode('{"exportedAt":"x","namespaces":{}}'),
      throwsA(isA<BundleFormatException>()),
    );
  });

  test('decode rejects a namespaces value that is not an object', () {
    expect(
      () => ProgressBundle.decode('{"bundleVersion":1,"exportedAt":"x","namespaces":{"a":5}}'),
      throwsA(isA<BundleFormatException>()),
    );
  });

  test('decode tolerates a missing namespaces key as empty', () {
    final decoded = ProgressBundle.decode('{"bundleVersion":1,"exportedAt":"x"}');
    expect(decoded.namespaces, isEmpty);
  });
}
