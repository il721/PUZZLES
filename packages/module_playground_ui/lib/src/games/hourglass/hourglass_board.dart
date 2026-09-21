import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_playground/module_playground.dart';

import '../../playground_session_controller.dart';
import '../token_graph/token_graph_widgets.dart';

/// Each node's (column, row) position on the hourglass lattice. Columns are
/// counted in HALF steps (0..8) because every other row is offset by half a
/// node - that is how the rows interlock in the book's drawing - and rows
/// run 0..8 from the top row of the upper triangle down to the bottom row of
/// the lower one, with the shared waist node `E1` dead centre. Transcribed
/// from the scan alongside [HourglassGame.board]'s own line topology.
const Map<String, (int, int)> _grid = {
  'A1': (0, 0),
  'A2': (2, 0),
  'A3': (4, 0),
  'A4': (6, 0),
  'A5': (8, 0),
  'B1': (1, 1),
  'B2': (3, 1),
  'B3': (5, 1),
  'B4': (7, 1),
  'C1': (2, 2),
  'C2': (4, 2),
  'C3': (6, 2),
  'D1': (3, 3),
  'D2': (5, 3),
  'E1': (4, 4),
  'F1': (3, 5),
  'F2': (5, 5),
  'G1': (2, 6),
  'G2': (4, 6),
  'G3': (6, 6),
  'H1': (1, 7),
  'H2': (3, 7),
  'H3': (5, 7),
  'H4': (7, 7),
  'I1': (0, 8),
  'I2': (2, 8),
  'I3': (4, 8),
  'I4': (6, 8),
  'I5': (8, 8),
};

/// The hourglass board for «Песочные часы»: 29 nodes on the 14 straight
/// lines of [HourglassGame.board], two triangles meeting at a shared waist.
/// Renders the live [playgroundSessionProvider] state for [gameId] unless
/// [previewState] is supplied, in which case that state is shown instead and
/// taps are ignored — used by `PlaygroundGameScreen` to animate
/// [PlaygroundGame.optimalSolution] without touching the real play session.
///
/// Input is tap-select-then-tap-target, mirroring the other two token-graph
/// boards: tapping an occupied node selects it and highlights every legal
/// destination; tapping a highlighted destination applies the move and
/// clears the selection; tapping the selected node again deselects it; any
/// other tap is a no-op. A jump cascade is ONE move ending at ONE
/// destination, so the highlighted circles include landings several hops
/// away — the player picks where the cascade stops rather than tapping the
/// hops one at a time.
class HourglassBoard extends ConsumerStatefulWidget {
  /// The id of the game session to display and drive (`hourglass`).
  final String gameId;

  /// When non-null, displayed instead of the live session board and not
  /// interactive. Used for the "show solution" playback.
  final PlaygroundState? previewState;

  /// Creates the hourglass board for [gameId].
  const HourglassBoard({super.key, required this.gameId, this.previewState});

  @override
  ConsumerState<HourglassBoard> createState() => _HourglassBoardState();
}

class _HourglassBoardState extends ConsumerState<HourglassBoard> {
  static const HourglassGame _game = HourglassGame();
  static const TokenGraphBoard _board = HourglassGame.board;

  String? _selected;

  /// A node's diameter on a board of the given [width]. Small enough to
  /// leave a visible gap between neighbours: the horizontal step between two
  /// nodes of one row is `(width - nodeSize) / 4`.
  double _nodeSizeFor(double width) => width * 0.16;

  /// The node's centre inside a board box of [width] x [height]: the 9x9
  /// half-step grid inset by half a node diameter on each side, so the
  /// outermost circles sit fully inside the box, then divided into 8 equal
  /// steps per axis.
  Offset _positionFor(String nodeId, double width, double height) {
    final nodeSize = _nodeSizeFor(width);
    final inset = nodeSize / 2;
    final (col, row) = _grid[nodeId]!;
    return Offset(
      inset + (width - nodeSize) * col / 8,
      inset + (height - nodeSize) * row / 8,
    );
  }

  /// What the shared node widget prints inside an occupied circle: nothing.
  /// All fifteen tokens are identical, so fifteen copies of
  /// [hourglassToken] would be noise - occupancy is carried by the circle's
  /// fill alone, exactly as the book draws it. `null` keeps a free node's
  /// unoccupied styling.
  String? _label(String? token) => token == null ? null : '';

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
      ref
          .read(playgroundSessionProvider(widget.gameId).notifier)
          .apply(match.first);
      setState(() => _selected = null);
      return;
    }

    // Anything else (a different token, an unreachable free node): no-op.
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(playgroundSessionProvider(widget.gameId));
    final displayState =
        (widget.previewState ?? sessionState.board) as TokenGraphState;
    final scheme = Theme.of(context).colorScheme;

    final destinations = _selected == null
        ? const <String>{}
        : _game
            .legalMoves(displayState, from: _selected)
            .map((m) => m.to)
            .toSet();

    return LayoutBuilder(
      builder: (context, constraints) {
        // The board is twice as tall as it is wide - eight rows against the
        // four node steps spanning its widest row - so whichever dimension
        // binds first sets the size.
        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : constraints.maxWidth * 2;
        final height = math.min(maxHeight, constraints.maxWidth * 2);
        final width = height / 2;

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(width, height),
                  painter: TokenGraphLinesPainter(
                    board: _board,
                    positionFor: (id) => _positionFor(id, width, height),
                    color: scheme.outlineVariant,
                  ),
                ),
                for (final nodeId in _board.nodeIds)
                  TokenGraphNodeWidget(
                    key: ValueKey('pg-node-$nodeId'),
                    nodeId: nodeId,
                    center: _positionFor(nodeId, width, height),
                    nodeSize: _nodeSizeFor(width),
                    token: _label(displayState.tokenAt(_board.indexOf(nodeId))),
                    rotation: 0,
                    selected: nodeId == _selected,
                    isDestination: destinations.contains(nodeId),
                    scheme: scheme,
                    onTap: () => _onNodeTap(displayState, nodeId),
                    tokenBackground: scheme.primaryContainer,
                    tokenForeground: scheme.onPrimaryContainer,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
