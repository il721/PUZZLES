import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:module_labyrinth/module_labyrinth.dart';

/// Renders the 8x8 labyrinth board: every cell shows its fixed printed
/// letter (through [glyphFor], so EN/DE locales see the substitute glyph
/// grid); the two growing chains are drawn as polylines through cell
/// centres, with a ring around each chain's head; auto-crosses (letters
/// that became non-conducting because their twin is already on a chain)
/// are drawn as a thin light grey X, and manual crosses (the player's own
/// long-press marks) as a thicker dark X in the same slot, painted on top.
///
/// The three layers - cell backgrounds/taps, the path/cross painter, and
/// the letters - are stacked so the painter draws behind the letters but
/// above the cell backgrounds. [glyphFor] is threaded in as a plain
/// callback (rather than reading a provider) so this widget and its
/// painter stay provider-agnostic and easy to test in isolation.
///
/// The board grows to fill the space its parent gives it: cell size is
/// derived from the incoming constraints (`LayoutBuilder`), so the same
/// widget renders large in a roomy desktop column and shrinks to fit a
/// narrow phone. When height is unbounded it falls back to a fixed cell
/// size, and it never exceeds [_maxCell] (or the caller's [maxCell]).
class LabyrinthGridWidget extends StatelessWidget {
  /// The board to render.
  final LabyrinthBoard board;

  /// The board's current status snapshot (used for duplicate-letter
  /// highlighting).
  final LabyrinthStatus status;

  /// Maps a canonical (Cyrillic) letter to the glyph to display.
  final String Function(String canonicalLetter) glyphFor;

  /// Called when the player taps a cell.
  final ValueChanged<Cell> onCellTap;

  /// Called when the player long-presses a cell.
  final ValueChanged<Cell> onCellLongPress;

  /// Accessibility (screen reader) label for a grid cell.
  final String cellSemanticsLabel;

  /// Optional override for the maximum cell size (defaults to [_maxCell]).
  final double? maxCell;

  static const double _padding = 12;
  static const double _fallbackCell = 40;
  static const double _maxCell = 72;
  static const double _thinEdge = 1;

  /// Creates a grid widget.
  const LabyrinthGridWidget({
    super.key,
    required this.board,
    required this.status,
    required this.glyphFor,
    required this.onCellTap,
    required this.onCellLongPress,
    required this.cellSemanticsLabel,
    this.maxCell,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const rows = LabyrinthPuzzle.rows;
    const cols = LabyrinthPuzzle.cols;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableW = constraints.maxWidth - _padding * 2;
        final availableH = constraints.maxHeight - _padding * 2;
        var cell = math.min(availableW / cols, availableH / rows);
        if (!cell.isFinite || cell <= 0) cell = _fallbackCell;
        cell = math.min(cell, maxCell ?? _maxCell);
        final boardSize = Size(cell * cols, cell * rows);

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: SizedBox(
              width: boardSize.width,
              height: boardSize.height,
              child: Stack(
                children: [
                  Positioned.fill(child: _buildBackgrounds(context, cell)),
                  // IgnorePointer: CustomPaint.hitTestSelf defaults to true
                  // (see RenderCustomPaint) whenever the painter doesn't
                  // override hitTest(), which would otherwise let this
                  // purely-decorative overlay swallow every tap/long-press
                  // before it reaches the cell GestureDetectors beneath it.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        size: boardSize,
                        painter: _LabyrinthPathPainter(
                          board: board,
                          cellSize: cell,
                          pathColor: scheme.primary,
                          autoCrossColor: scheme.outlineVariant,
                          manualCrossColor: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(child: _buildLetters(context, cell)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgrounds(BuildContext context, double size) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < LabyrinthPuzzle.rows; r++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var c = 0; c < LabyrinthPuzzle.cols; c++) _buildCellBackground(context, scheme, Cell(r, c), size),
            ],
          ),
      ],
    );
  }

  Widget _buildCellBackground(BuildContext context, ColorScheme scheme, Cell cell, double size) {
    final onPath = board.isOnPath(cell);
    final letter = board.puzzle.letterAt(cell);
    final isDuplicate = onPath && status.duplicateLetters.contains(letter);

    final Color background;
    if (isDuplicate) {
      background = scheme.errorContainer;
    } else if (onPath) {
      background = scheme.primaryContainer.withValues(alpha: 0.35);
    } else {
      background = scheme.surface;
    }

    return Semantics(
      button: true,
      label: cellSemanticsLabel,
      value: glyphFor(letter),
      child: GestureDetector(
        onTap: () => onCellTap(cell),
        onLongPress: () => onCellLongPress(cell),
        child: Container(
          key: ValueKey('cell_${cell.row}_${cell.col}'),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: scheme.outlineVariant, width: _thinEdge),
          ),
        ),
      ),
    );
  }

  Widget _buildLetters(BuildContext context, double size) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < LabyrinthPuzzle.rows; r++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var c = 0; c < LabyrinthPuzzle.cols; c++)
                SizedBox(
                  width: size,
                  height: size,
                  child: Center(
                    child: Text(
                      glyphFor(board.puzzle.letterAt(Cell(r, c))),
                      style: textTheme.headlineSmall?.copyWith(
                        fontSize: size * 0.45,
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Paints the two chains as polylines through cell centres, rings each
/// chain's head, and paints auto-crosses (thin, light grey) then manual
/// crosses (thicker, dark) on top in the same cell slot.
class _LabyrinthPathPainter extends CustomPainter {
  final LabyrinthBoard board;
  final double cellSize;
  final Color pathColor;
  final Color autoCrossColor;
  final Color manualCrossColor;

  _LabyrinthPathPainter({
    required this.board,
    required this.cellSize,
    required this.pathColor,
    required this.autoCrossColor,
    required this.manualCrossColor,
  });

  Offset _center(Cell c) => Offset((c.col + 0.5) * cellSize, (c.row + 0.5) * cellSize);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = cellSize * 0.18;

    void drawChain(List<Cell> chain) {
      if (chain.length < 2) return;
      final path = Path()..moveTo(_center(chain.first).dx, _center(chain.first).dy);
      for (final c in chain.skip(1)) {
        final o = _center(c);
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = pathColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    drawChain(board.chainA);
    drawChain(board.chainZ);

    void ringHead(Cell head) {
      canvas.drawCircle(
        _center(head),
        cellSize * 0.34,
        Paint()
          ..color = pathColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.6,
      );
    }

    ringHead(board.headA);
    ringHead(board.headZ);

    void drawX(Cell cell, Color color, double thickness) {
      final o = _center(cell);
      final half = cellSize * 0.22;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(o.translate(-half, -half), o.translate(half, half), paint);
      canvas.drawLine(o.translate(-half, half), o.translate(half, -half), paint);
    }

    for (final cell in board.autoCrosses) {
      drawX(cell, autoCrossColor, cellSize * 0.05);
    }
    for (final cell in board.manualCrosses) {
      drawX(cell, manualCrossColor, cellSize * 0.09);
    }
  }

  @override
  bool shouldRepaint(covariant _LabyrinthPathPainter oldDelegate) {
    // [board] is mutated in place (see LabyrinthSessionState doc comment),
    // so reference/value comparison against the old delegate's [board]
    // cannot detect a chain/cross change — always repaint. The grid is
    // only 8x8, so this is cheap.
    return true;
  }
}
