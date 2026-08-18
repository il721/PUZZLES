import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_playground/module_playground.dart';

import '../../playground_session_controller.dart';
import '../token_graph/token_graph_widgets.dart';

/// Each node's (column, row) position on the 5x5 diagonal lattice, both
/// 0..4, origin top-left. Transcribed from the book scan alongside
/// [CatsDogsGame.board]'s own line topology.
const Map<String, (int, int)> _grid = {
  'L1': (0, 0),
  'TM': (2, 0),
  'R1': (4, 0),
  'U1': (1, 1),
  'U2': (3, 1),
  'L2': (0, 2),
  'M': (2, 2),
  'R2': (4, 2),
  'D1': (1, 3),
  'D2': (3, 3),
  'L3': (0, 4),
  'BM': (2, 4),
  'R3': (4, 4),
};

/// The park board for «Кошки и собаки» (cats and dogs): 13 nodes on a 5x5
/// diagonal lattice joined by the 16 alleys of [CatsDogsGame.board]. Renders
/// the live [playgroundSessionProvider] state for [gameId] unless
/// [previewState] is supplied, in which case that state is shown instead and
/// taps are ignored — used by `PlaygroundGameScreen` to animate
/// [PlaygroundGame.optimalSolution] without touching the real play session.
///
/// Input is tap-select-then-tap-target, mirroring [EightChipsBoard]: tapping
/// an occupied node selects it and highlights every legal destination;
/// tapping a highlighted destination applies the move and clears the
/// selection; tapping the selected node again deselects it; any other tap is
/// a no-op. A move that would place a cat adjacent to a dog is simply never
/// offered as a destination — that rule is enforced by
/// [CatsDogsGame.legalMoves], not by this widget.
class CatsDogsBoard extends ConsumerStatefulWidget {
  /// The id of the game session to display and drive (`cats_dogs`).
  final String gameId;

  /// When non-null, displayed instead of the live session board and not
  /// interactive. Used for the "show solution" playback.
  final PlaygroundState? previewState;

  /// Creates the cats-and-dogs park board for [gameId].
  const CatsDogsBoard({super.key, required this.gameId, this.previewState});

  @override
  ConsumerState<CatsDogsBoard> createState() => _CatsDogsBoardState();
}

class _CatsDogsBoardState extends ConsumerState<CatsDogsBoard> {
  static const CatsDogsGame _game = CatsDogsGame();
  static const TokenGraphBoard _board = CatsDogsGame.board;

  String? _selected;

  /// The node's centre position within a board of the given [size]: the 5x5
  /// grid inset by half a node diameter on each side, so the outermost
  /// nodes' circles sit fully inside the square, then divided into 4 equal
  /// steps per axis.
  Offset _positionFor(String nodeId, double size) {
    final nodeSize = size * 0.16;
    final inset = nodeSize / 2;
    final span = size - nodeSize;
    final (col, row) = _grid[nodeId]!;
    return Offset(inset + span * col / 4, inset + span * row / 4);
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
                    rotation: 0,
                    selected: nodeId == _selected,
                    isDestination: destinations.contains(nodeId),
                    scheme: scheme,
                    onTap: () => _onNodeTap(displayState, nodeId),
                    tokenBackground: _tokenBackground(displayState.tokenAt(_board.indexOf(nodeId)), scheme),
                    tokenForeground: _tokenForeground(displayState.tokenAt(_board.indexOf(nodeId)), scheme),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Cats and dogs use distinguishable colour pairs from the theme so the
  /// two token classes read apart at a glance; `null` for a free node so the
  /// shared widget's default (unoccupied) styling applies.
  Color? _tokenBackground(String? token, ColorScheme scheme) {
    if (token == catToken) return scheme.primaryContainer;
    if (token == dogToken) return scheme.tertiaryContainer;
    return null;
  }

  /// Paired with [_tokenBackground].
  Color? _tokenForeground(String? token, ColorScheme scheme) {
    if (token == catToken) return scheme.onPrimaryContainer;
    if (token == dogToken) return scheme.onTertiaryContainer;
    return null;
  }
}
