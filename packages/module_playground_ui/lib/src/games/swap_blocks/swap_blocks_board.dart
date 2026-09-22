import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_playground/module_playground.dart';

import '../../playground_session_controller.dart';

/// Cardboard-tile colours for «Поменяйте местами», ruled exactly like
/// «Всюду по три»'s [ThreeEachBoard]: the red and blue blocks (the latter
/// modelled as [SwapBlocksColour.black]) are fixed regardless of the app's
/// theme - colour identity IS the puzzle (the player is swapping the red
/// pair with the blue pair), so a dark theme must never invert them. Only
/// the "plain" block cardboard tint follows the theme - [_sbCardboard] in
/// light, [_sbCardboardDark] in dark - and the floor (free space) follows
/// the theme's own muted surface tone. Two markers ride on top of the
/// blocks, both fixed regardless of theme: the selected block's own anchor
/// cell gets a blue dot ([_sbAnchorDot], ringed white so it reads over any
/// block colour), and every legal destination's anchor cell gets a grey dot
/// ([_sbDestDot] in light, [_sbDestDotDark] in dark).
const Color _sbCardboard = Color(0xFFFAF8F2);
const Color _sbCardboardDark = Color(0xFFCFD3D6);
const Color _sbRed = Color(0xFFD32F2F);
const Color _sbBlue = Color(0xFF1976D2);
const Color _sbBorder = Color(0xFF1A1A1A);
const Color _sbAnchorDot = Color(0xFF1565C0);
const Color _sbDestDot = Color(0xFF616161);
const Color _sbDestDotDark = Color(0xFF9E9E9E);

Color _sbBlockColour(SwapBlocksColour colour, bool dark) {
  switch (colour) {
    case SwapBlocksColour.red:
      return _sbRed;
    case SwapBlocksColour.black:
      return _sbBlue;
    case SwapBlocksColour.plain:
      return dark ? _sbCardboardDark : _sbCardboard;
  }
}

/// A rectilinear polygon's boundary as an ordered list of grid-unit points
/// (col, row), traced from [cells] (each a (row, col) pair, all part of one
/// simply-connected shape with no holes - true of every [SwapBlocksShape]).
/// Built by cancelling edges shared between two adjacent cells (interior
/// edges) and walking what remains (each boundary edge belongs to exactly
/// one cell) into a single closed loop. Generic on purpose - four shapes
/// share this one implementation rather than four hand-transcribed vertex
/// lists.
List<Offset> _outline(List<(int, int)> cells) {
  final edgeCount = <String, int>{};
  final edgeVerts = <String, (Offset, Offset)>{};

  void addEdge(Offset a, Offset b) {
    final pts = [a, b]
      ..sort((p, q) =>
          p.dx != q.dx ? p.dx.compareTo(q.dx) : p.dy.compareTo(q.dy));
    final key = '${pts[0].dx},${pts[0].dy}-${pts[1].dx},${pts[1].dy}';
    edgeCount[key] = (edgeCount[key] ?? 0) + 1;
    edgeVerts[key] = (pts[0], pts[1]);
  }

  for (final (r, c) in cells) {
    final tl = Offset(c.toDouble(), r.toDouble());
    final tr = Offset(c + 1.0, r.toDouble());
    final bl = Offset(c.toDouble(), r + 1.0);
    final br = Offset(c + 1.0, r + 1.0);
    addEdge(tl, tr);
    addEdge(bl, br);
    addEdge(tl, bl);
    addEdge(tr, br);
  }

  final adjacency = <Offset, List<Offset>>{};
  for (final key in edgeCount.keys) {
    if (edgeCount[key] != 1) continue;
    final (a, b) = edgeVerts[key]!;
    adjacency.putIfAbsent(a, () => []).add(b);
    adjacency.putIfAbsent(b, () => []).add(a);
  }
  if (adjacency.isEmpty) return const [];

  final start = adjacency.keys.first;
  final path = <Offset>[start];
  var prev = start;
  var current = adjacency[start]!.first;
  while (current != start) {
    path.add(current);
    final neighbours = adjacency[current]!;
    final next = neighbours[0] == prev ? neighbours[1] : neighbours[0];
    prev = current;
    current = next;
  }
  return path;
}

/// A cache of each [SwapBlocksShape]'s outline in local (grid-unit)
/// coordinates, relative to its bounding-box origin - computed once, then
/// translated per block/destination at paint time.
final Map<SwapBlocksShape, List<Offset>> _shapeOutlines = {
  for (final shape in SwapBlocksShape.values)
    shape: _outline(swapBlocksShapeOffsets[shape]!),
};

Path _blockPath(SwapBlocksShape shape, double originRow, double originCol,
    double cellSize) {
  final path = Path();
  final points = _shapeOutlines[shape]!;
  for (var i = 0; i < points.length; i++) {
    final p = points[i];
    final offset = Offset(
      (originCol + p.dx) * cellSize,
      (originRow + p.dy) * cellSize,
    );
    if (i == 0) {
      path.moveTo(offset.dx, offset.dy);
    } else {
      path.lineTo(offset.dx, offset.dy);
    }
  }
  path.close();
  return path;
}

/// Paints the whole board: the box floor, then each of the twelve blocks as
/// one filled outlined polygon (never eight separate cell squares - the
/// L-shaped outline is what makes a piece readable), the selected block's
/// primary-coloured highlight plus a blue anchor-cell dot, grey
/// destination-anchor dots, and a translucent ghost of the selected block at
/// a pressed destination.
class _SwapBlocksPainter extends CustomPainter {
  final SwapBlocksState state;
  final Color floor;
  final bool dark;
  final ColorScheme scheme;
  final int? selectedBlock;
  final List<PlaygroundMove> destinations;
  final int? ghostOriginRow;
  final int? ghostOriginCol;

  const _SwapBlocksPainter({
    required this.state,
    required this.floor,
    required this.dark,
    required this.scheme,
    required this.selectedBlock,
    required this.destinations,
    required this.ghostOriginRow,
    required this.ghostOriginCol,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / swapBlocksCols;

    canvas.drawRect(Offset.zero & size, Paint()..color = floor);

    for (var b = 0; b < state.origins.length; b++) {
      final shape = swapBlocksShapes[b];
      final path = _blockPath(
          shape, state.originRow(b).toDouble(), state.originCol(b).toDouble(), cellSize);
      final colour = _sbBlockColour(swapBlocksColours[b], dark);
      canvas.drawPath(path, Paint()..color = colour);
      canvas.drawPath(
        path,
        Paint()
          ..color = _sbBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round,
      );
      if (b == selectedBlock) {
        canvas.drawPath(
          path,
          Paint()
            ..color = scheme.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeJoin = StrokeJoin.round,
        );
        final anchor = swapBlocksParseCellId(state.anchorId(b));
        if (anchor != null) {
          final center = Offset(
            (anchor.$2 + 0.5) * cellSize,
            (anchor.$1 + 0.5) * cellSize,
          );
          canvas.drawCircle(center, cellSize * 0.14, Paint()..color = _sbAnchorDot);
          canvas.drawCircle(
            center,
            cellSize * 0.14 + 1.5,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      }
    }

    final destDotColour = dark ? _sbDestDotDark : _sbDestDot;
    for (final move in destinations) {
      final dest = swapBlocksParseCellId(move.to);
      if (dest == null) continue;
      final center = Offset(
        (dest.$2 + 0.5) * cellSize,
        (dest.$1 + 0.5) * cellSize,
      );
      canvas.drawCircle(center, cellSize * 0.14, Paint()..color = destDotColour);
    }

    final ghostRow = ghostOriginRow;
    final ghostCol = ghostOriginCol;
    final block = selectedBlock;
    if (ghostRow != null && ghostCol != null && block != null) {
      final shape = swapBlocksShapes[block];
      final ghostPath =
          _blockPath(shape, ghostRow.toDouble(), ghostCol.toDouble(), cellSize);
      canvas.drawPath(
          ghostPath, Paint()..color = scheme.primary.withAlpha(110));
      canvas.drawPath(
        ghostPath,
        Paint()
          ..color = scheme.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SwapBlocksPainter oldDelegate) => true;
}

/// The board for «Поменяйте местами»: a 16-row x 8-column box (1:2 aspect)
/// holding twelve fixed-shape P-blocks. Renders the live
/// [playgroundSessionProvider] state for [gameId] unless [previewState] is
/// supplied, in which case that state is shown read-only instead - used by
/// `PlaygroundGameScreen` to animate [PlaygroundGame.optimalSolution]
/// without touching the real play session.
///
/// Input is tap-select-then-tap-target; there is no drag anywhere in this
/// module. Tapping any cell of a block selects it (tapping it again
/// deselects); with a block selected, every legal destination is marked with
/// a dot on its anchor cell ([SwapBlocksGame.legalMoves] is always the
/// source of truth - this widget never computes legality itself). Because a
/// dot alone doesn't show where the block will land, press-and-hold over a
/// destination marker previews a translucent ghost of the whole block there;
/// releasing commits the move.
class SwapBlocksBoard extends ConsumerStatefulWidget {
  /// The id of the game session to display and drive (`swap_blocks`).
  final String gameId;

  /// When non-null, displayed instead of the live session board and not
  /// interactive. Used for the "show solution" playback.
  final PlaygroundState? previewState;

  /// Creates the swap-blocks board for [gameId].
  const SwapBlocksBoard({super.key, required this.gameId, this.previewState});

  @override
  ConsumerState<SwapBlocksBoard> createState() => _SwapBlocksBoardState();
}

class _SwapBlocksBoardState extends ConsumerState<SwapBlocksBoard> {
  static const SwapBlocksGame _game = SwapBlocksGame();

  int? _selectedBlock;
  String? _ghostDestination;

  bool get _interactive => widget.previewState == null;

  (int, int)? _cellAt(Offset local, double cellSize) {
    final col = (local.dx / cellSize).floor();
    final row = (local.dy / cellSize).floor();
    if (row < 0 || row >= swapBlocksRows || col < 0 || col >= swapBlocksCols) {
      return null;
    }
    return (row, col);
  }

  List<PlaygroundMove> _destinations(SwapBlocksState state) {
    final block = _selectedBlock;
    if (block == null) return const [];
    return _game.legalMoves(state, from: state.anchorId(block));
  }

  void _handleTapDown(Offset local, double cellSize, SwapBlocksState state) {
    if (!_interactive) return;
    final cell = _cellAt(local, cellSize);
    if (cell == null) return;
    final block = _selectedBlock;
    if (block == null) return;
    final cellId = swapBlocksCellId(cell.$1, cell.$2);
    final match = _destinations(state).where((m) => m.to == cellId);
    if (match.isEmpty) return;
    setState(() => _ghostDestination = cellId);
  }

  void _handleTapUp(Offset local, double cellSize, SwapBlocksState state) {
    if (!_interactive) return;
    final cell = _cellAt(local, cellSize);
    final ghost = _ghostDestination;
    if (cell != null && ghost != null) {
      final cellId = swapBlocksCellId(cell.$1, cell.$2);
      if (cellId == ghost) {
        final match =
            _destinations(state).where((m) => m.to == ghost).toList();
        if (match.isNotEmpty) {
          ref
              .read(playgroundSessionProvider(widget.gameId).notifier)
              .apply(match.first);
          setState(() {
            _selectedBlock = null;
            _ghostDestination = null;
          });
          return;
        }
      }
    }
    setState(() => _ghostDestination = null);

    if (cell == null) return;
    final cellIndex = cell.$1 * swapBlocksCols + cell.$2;
    final tappedBlock = state.blockAtCell(cellIndex);
    if (tappedBlock == null) return;
    setState(() {
      _selectedBlock = _selectedBlock == tappedBlock ? null : tappedBlock;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(playgroundSessionProvider(widget.gameId));
    final displayState =
        (widget.previewState ?? sessionState.board) as SwapBlocksState;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final floor = scheme.surfaceContainerHighest;

    final selectedBlock = _interactive ? _selectedBlock : null;
    final ghostDestination = _interactive ? _ghostDestination : null;
    final destinations =
        selectedBlock == null ? const <PlaygroundMove>[] : _destinations(displayState);

    int? ghostOriginRow;
    int? ghostOriginCol;
    if (ghostDestination != null && selectedBlock != null) {
      final dest = swapBlocksParseCellId(ghostDestination);
      if (dest != null) {
        final anchorOffset = swapBlocksAnchorOffset[swapBlocksShapes[selectedBlock]]!;
        ghostOriginRow = dest.$1 - anchorOffset.$1;
        ghostOriginCol = dest.$2 - anchorOffset.$2;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = math.min(
          constraints.maxWidth / swapBlocksCols,
          constraints.maxHeight / swapBlocksRows,
        );
        final width = cellSize * swapBlocksCols;
        final height = cellSize * swapBlocksRows;

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: GestureDetector(
              key: const ValueKey('pg-sb-board'),
              onTapDown: (details) =>
                  _handleTapDown(details.localPosition, cellSize, displayState),
              onTapUp: (details) =>
                  _handleTapUp(details.localPosition, cellSize, displayState),
              onTapCancel: () {
                if (_interactive) setState(() => _ghostDestination = null);
              },
              child: CustomPaint(
                painter: _SwapBlocksPainter(
                  state: displayState,
                  floor: floor,
                  dark: dark,
                  scheme: scheme,
                  selectedBlock: selectedBlock,
                  destinations: destinations,
                  ghostOriginRow: ghostOriginRow,
                  ghostOriginCol: ghostOriginCol,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
