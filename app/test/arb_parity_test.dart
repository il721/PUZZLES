import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Loads an ARB file's JSON object, keyed by its locale suffix (e.g. `'ru'`
/// for `lib/l10n/app_ru.arb`). Tests run with CWD `app/` (the Flutter app
/// package directory), so paths are relative to that.
Map<String, dynamic> _loadArb(String locale) {
  final file = File('lib/l10n/app_$locale.arb');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// The message keys of an ARB map: every key that is not a `@`-prefixed
/// metadata entry (and not the `@@locale` entry).
Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  test('en and de ARB files have exactly the same message keys as the ru template', () {
    final ru = _messageKeys(_loadArb('ru'));
    final en = _messageKeys(_loadArb('en'));
    final de = _messageKeys(_loadArb('de'));

    expect(en, equals(ru), reason: 'app_en.arb keys differ from the app_ru.arb template');
    expect(de, equals(ru), reason: 'app_de.arb keys differ from the app_ru.arb template');
  });
}
