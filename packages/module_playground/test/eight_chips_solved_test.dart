import 'package:module_playground/module_playground.dart';
import 'package:test/test.dart';

void main() {
  final board = EightChipsGame.board;
  const game = EightChipsGame();

  /// Builds the goal state independently of any code under test: token `t`
  /// at tip `P(9-t)` for every t, centre free.
  TokenGraphState buildGoal() {
    final tokens = List<String?>.filled(board.nodeIds.length, null);
    for (var t = 1; t <= 8; t++) {
      tokens[board.indexOf('P${9 - t}')] = '$t';
    }
    return TokenGraphState(tokens);
  }

  test('initial state is not solved', () {
    expect(game.isSolved(game.initialState()), isFalse);
  });

  test('the independently-built goal state is solved', () {
    expect(game.isSolved(buildGoal()), isTrue);
  });

  test('a state one swap away from goal is not solved', () {
    final goal = buildGoal();
    final tokens = List<String?>.of(goal.tokens);
    final i1 = board.indexOf('P8'); // holds token '1' at goal
    final i2 = board.indexOf('P7'); // holds token '2' at goal
    final tmp = tokens[i1];
    tokens[i1] = tokens[i2];
    tokens[i2] = tmp;
    final nearGoal = TokenGraphState(tokens);

    expect(game.isSolved(nearGoal), isFalse);
  });
}
