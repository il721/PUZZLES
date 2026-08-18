import 'package:module_playground/module_playground.dart';
import 'package:test/test.dart';

void main() {
  final board = EightChipsGame.board;

  test('9 nodes, 10 lines', () {
    expect(board.nodeIds, hasLength(9));
    expect(board.lines, hasLength(10));
  });

  test('no node appears twice in a line; every line id is a known node', () {
    final known = board.nodeIds.toSet();
    for (final line in board.lines) {
      expect(line.toSet(), hasLength(line.length),
          reason: 'duplicate node in line $line');
      for (final id in line) {
        expect(known.contains(id), isTrue,
            reason: 'line $line references unknown node "$id"');
      }
    }
  });

  test('degreesOnEmptyBoard matches the book-verified line data', () {
    // The milestone brief's claimed table (P1/P3/P5/P7: 3, C: 4) undercounts
    // the four "main" tips by one. Each main tip (P1/P3/P5/P7) sits on one
    // of the two 3-node lines that pass through the centre C
    // (`[P1, C, P5]`, `[P3, C, P7]`). On an empty board that tip can slide
    // not only onto C and its two physically-adjacent "side" tips, but can
    // also jump clean over the (empty) centre straight to the
    // diametrically-opposite main tip - a 4th distinct destination the
    // brief's table omits. This is a direct consequence of the brief's own
    // definition ("a piece can slide to ANY other node on a line it
    // shares") applied to the brief's own line data, not a reinterpretation:
    // C's own degree (4, matching the brief) is reached the exact same way,
    // by symmetry, since C shares both 3-node lines and reaches all 4 main
    // tips through them.
    expect(board.degreesOnEmptyBoard(), {
      'P1': 4,
      'P2': 2,
      'P3': 4,
      'P4': 2,
      'P5': 4,
      'P6': 2,
      'P7': 4,
      'P8': 2,
      'C': 4,
    });
  });

  // degreesOnEmptyBoard() pins how far a token can slide when the board is
  // otherwise empty - a reachability notion that includes jumping clean over
  // gaps on longer lines. The test below pins a materially different graph
  // property: which nodes are drawn as directly-connected neighbours in the
  // book figure (a line-adjacency with no node in between), measured on a
  // full board where jumps are blocked. Both invariants get their own
  // assertion here so a future reader never conflates the two notions.
  test(
      'full-board adjacency degree (neighbours-only) matches the '
      'book-verified line data', () {
    final degrees = <String, int>{};
    for (final n in board.nodeIds) {
      var label = 1;
      final tokens = board.nodeIds.map((id) {
        if (id == n) return null;
        return '${label++}';
      }).toList();
      final state = TokenGraphState(tokens);
      degrees[n] = slideMoves(board, state).length;
    }
    expect(degrees, {
      'P1': 3,
      'P2': 2,
      'P3': 3,
      'P4': 2,
      'P5': 3,
      'P6': 2,
      'P7': 3,
      'P8': 2,
      'C': 4,
    });
  });
}
