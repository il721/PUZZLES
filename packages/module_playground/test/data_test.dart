import 'dart:io';

import 'package:module_playground/module_playground.dart';
import 'package:test/test.dart';

void main() {
  late PlaygroundData data;

  setUpAll(() {
    final jsonString = File('assets/puzzles/module06.json').readAsStringSync();
    data = PlaygroundData.fromJsonString(jsonString);
  });

  test('module06.json parses with schemaVersion 1', () {
    expect(data.schemaVersion, 1);
    expect(data.module, 'playground');
  });

  test(
    'eight_chips entry has par 28, parProven true, parSource solver, '
    'solution length 28',
    () {
      final entry = data.forId('eight_chips');
      expect(entry, isNotNull);
      expect(entry!.par, 28);
      expect(entry.parProven, isTrue);
      expect(entry.parSource, ParSource.solver);
      expect(entry.solution, hasLength(28));
    },
  );

  test(
    'cats_dogs entry has par 32, parProven true, parSource solver, '
    'solution length 32',
    () {
      final entry = data.forId('cats_dogs');
      expect(entry, isNotNull);
      expect(entry!.par, 32);
      expect(entry.parProven, isTrue);
      expect(entry.parSource, ParSource.solver);
      expect(entry.solution, hasLength(32));
    },
  );

  test(
    'hourglass entry has par 26, parProven true, parSource solver, '
    'solution length 26',
    () {
      final entry = data.forId('hourglass');
      expect(entry, isNotNull);
      expect(entry!.par, 26);
      expect(entry.parProven, isTrue);
      expect(entry.parSource, ParSource.solver);
      expect(entry.solution, hasLength(26));
    },
  );

  test(
    'three_each entry has par null, parProven false, parSource null, '
    'solution length 9',
    () {
      final entry = data.forId('three_each');
      expect(entry, isNotNull);
      expect(entry!.par, isNull);
      expect(entry.parProven, isFalse);
      expect(entry.parSource, isNull);
      expect(entry.solution, hasLength(9));
    },
  );
}
