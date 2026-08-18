import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_playground/module_playground.dart';

import '../../playground_session_controller.dart';
import '../token_graph/token_graph_widgets.dart';

/// The 8 tip node ids in CLOCKWISE order starting from `P1` (straight up).
/// Verified against the book scan (Мочалов, 1980, p. 68), matching the
/// board data's own line topology: `P1`/`C`/`P5` forms the vertical line and
/// `P3`/`C`/`P7` the horizontal one, exactly as this ordering implies (`P1`
/// at angle 0, `P5` four steps clockwise at angle 180; `P3` at 270, `P7` at
/// 90).
const List<String> _clockwiseTips = ['P1', 'P8', 'P7', 'P6', 'P5', 'P4', 'P3', 'P2'];

/// The star board for «Восемь фишек» (eight chips): 9 nodes (8 tips on a
/// circle plus the free centre) joined by the 10 lines in
/// [EightChipsGame.board]. Renders the live [playgroundSessionProvider]
/// state for [gameId] unless [previewState] is supplied, in which case that
/// state is shown instead and taps are ignored — used by
/// `PlaygroundGameScreen` to animate [PlaygroundGame.optimalSolution]
/// without touching the real play session.
///
/// Input is tap-select-then-tap-target: tapping an occupied node selects it
/// and highlights every legal destination; tapping a highlighted destination
/// applies the move and clears the selection; tapping the selected node
/// again deselects it; any other tap (an unselected token, a
/// non-highlighted node) is a no-op — no dialogs, no snackbars.
class EightChipsBoard extends ConsumerStatefulWidget {
  /// The id of the game session to display and drive (`eight_chips`).
  final String gameId;

  /// When non-null, displayed instead of the live session board and not
  /// interactive. Used for the "show solution" playback.
  final PlaygroundState? previewState;

  /// Creates the eight-chips star board for [gameId].
  const EightChipsBoard({super.key, required this.gameId, this.previewState});

  @override
  ConsumerState<EightChipsBoard> createState() => _EightChipsBoardState();
}

class _EightChipsBoardState extends ConsumerState<EightChipsBoard> {
  static const EightChipsGame _game = EightChipsGame();
  static const TokenGraphBoard _board = EightChipsGame.board;

  String? _selected;

  /// The node's centre position within a board of the given [size], with
  /// `C` at the centre and the 8 tips spaced 45° apart around a circle,
  /// starting at `P1` straight up and proceeding clockwise.
  Offset _positionFor(String nodeId, double size) {
    final center = Offset(size / 2, size / 2);
    if (nodeId == 'C') return center;
    final tipIndex = _clockwiseTips.indexOf(nodeId);
    final angle = tipIndex * (2 * math.pi / 8);
    final radius = size / 2 - size * 0.12;
    return Offset(
      center.dx + radius * math.sin(angle),
      center.dy - radius * math.cos(angle),
    );
  }

  /// The digit label's rotation for [nodeId], matching the goal artwork:
  /// upright (`0`) at the top tip (`P1`) and centre (`C`), rotating a
  /// further 45° for each further tip clockwise — i.e. the same clockwise
  /// angle [_positionFor] uses to place the tip itself.
  double _rotationFor(String nodeId) {
    if (nodeId == 'C') return 0;
    final tipIndex = _clockwiseTips.indexOf(nodeId);
    return tipIndex * (2 * math.pi / 8);
  }

  void _onNodeTap(TokenGraphState tokenState, String nodeId) {
    if (widget.previewState != null) return;

    if (_selected == null) {
      final hasToken = tokenState.tokenAt(_board.indexOf(nodeId)) != null;
      if (hasToken) setState(() => _selected = nodeId);
      return;
    }

    if (nodeId == _selected) {
      setState(() => _selected = null);
      return;
    }

    final legal = _game.legalMoves(tokenState, from: _selected);
    final match = legal.where((m) => m.to == nodeId);
    if (match.isNotEmpty) {
      ref.read(playgroundSessionProvider(widget.gameId).notifier).apply(match.first);
      setState(() => _selected = null);
      return;
    }

    // Anything else (a different token, an unreachable free node): no-op.
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(playgroundSessionProvider(widget.gameId));
    final displayState = (widget.previewState ?? sessionState.board) as TokenGraphState;
    final scheme = Theme.of(context).colorScheme;

    final destinations = _selected == null
        ? const <String>{}
        : _game.legalMoves(displayState, from: _selected).map((m) => m.to).toSet();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : constraints.maxWidth;
        final size = math.min(constraints.maxWidth, maxHeight);

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(size, size),
                  painter: TokenGraphLinesPainter(
                    board: _board,
                    positionFor: (id) => _positionFor(id, size),
                    color: scheme.outlineVariant,
                  ),
                ),
                for (final nodeId in _board.nodeIds)
                  TokenGraphNodeWidget(
                    key: ValueKey('pg-node-$nodeId'),
                    nodeId: nodeId,
                    center: _positionFor(nodeId, size),
                    nodeSize: size * 0.16,
                    token: displayState.tokenAt(_board.indexOf(nodeId)),
                    rotation: _rotationFor(nodeId),
                    selected: nodeId == _selected,
                    isDestination: destinations.contains(nodeId),
                    scheme: scheme,
                    onTap: () => _onNodeTap(displayState, nodeId),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
