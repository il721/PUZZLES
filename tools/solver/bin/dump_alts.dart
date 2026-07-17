import 'dart:io';

import 'package:module_rebus/module_rebus.dart';

/// Dumps all solutions (up to a small cap) for the puzzle ids passed as
/// arguments, so non-unique puzzles can be inspected during data curation.
void main(List<String> args) {
  final ids = args.isEmpty ? const ['p01', 'p08'] : args;
  final jsonPath = File(
    '../../packages/module_rebus/assets/puzzles/module01.json',
  );
  final puzzles = RebusPuzzle.listFromJsonString(jsonPath.readAsStringSync());
  for (final id in ids) {
    final puzzle = puzzles.firstWhere((p) => p.id == id);
    final solutions = collectSolutions(puzzle, cap: 5);
    stdout.writeln('=== $id: ${solutions.length} solution(s) (cap 5) ===');
    for (var s = 0; s < solutions.length; s++) {
      stdout.writeln('--- solution ${s + 1} ---');
      for (var r = 0; r < 4; r++) {
        final row = puzzle.rows[r];
        final nums = solutions[s][r];
        final parts = StringBuffer('${nums[0]}');
        for (var k = 0; k < 3; k++) {
          parts.write(' ${row.ops[k]} ${nums[k + 1]}');
        }
        final value = evalLeftToRight(nums, row.ops);
        stdout.writeln('  $parts = $value');
      }
    }
  }
}