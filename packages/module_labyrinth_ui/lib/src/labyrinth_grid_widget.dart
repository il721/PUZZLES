import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:module_labyrinth/module_labyrinth.dart';

/// Renders the 8x8 labyrinth board: every cell shows its fixed printed
/// letter (through [glyphFor], so EN/DE locales see the substitute glyph
/// grid); the two growing chains are drawn as polylines through cell
/// centres, with a ring around each chain's head; auto-crosses (letters
/// that became non-conducting because their twin is already on a chain)
/// are drawn as a faint translucent red cell fill, and manual crosses (the
/// player's own long-press/right-click marks) as a stronger translucent red
/// fill in the same slot, painted on top.
/// Cells the player has [LabyrinthBoard.marks]-ed as "must be on the path"
/// get a solid blue-tinted background (see [_buildCellBackground]).
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

  /// Called when the player long-presses a cell (toggles a manual cross).
  /// Also wired to right-click/secondary-tap on desktop, which now does the
  /// same thing.
  final ValueChanged<Cell> onCellLongPress;

  /// Accessibility (screen reader) label for a grid cell.
  final String cellSemanticsLabel;

  /// Accessibility (screen reader) fragment appended to [cellSemanticsLabel]
  /// for a marked cell.
  final String markedSemanticsLabel;

  /// Cells to visually emphasize (e.g. for the guided tutorial, to call
  /// out the cells a step is teaching). Empty by default, which leaves the
  /// play screen's rendering unchanged. Takes priority over the plain
  /// on-path tint but not over the duplicate-letter tint.
  final Set<Cell> highlightedCells;

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
    required this.markedSemanticsLabel,
    this.highlightedCells = const {},
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
                          autoCrossColor: scheme.error.withValues(alpha: 0.14),
                          manualCrossColor: scheme.error.withValues(alpha: 0.34),
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
    final isHighlighted = highlightedCells.contains(cell);
    // A marked cell can never be on the path (LabyrinthBoard.toggleMark is a
    // no-op there), so this never competes with the path/duplicate cases
    // above it.
    final isMarked = board.marks.contains(cell);

    final Color background;
    if (isDuplicate) {
      background = scheme.errorContainer;
    } else if (isHighlighted) {
      background = scheme.tertiaryContainer;
    } else if (onPath) {
      background = scheme.primaryContainer.withValues(alpha: 0.35);
    } else if (isMarked) {
      // Solid-ish fill (vs. the path's much lighter primaryContainer tint
      // above) so a marked cell reads as clearly distinct from an
      // ordinary path cell at a glance, in both light and dark themes.
      background = scheme.primary.withValues(alpha: 0.55);
    } else {
      background = scheme.surface;
    }

    final label =
        isMarked ? '$cellSemanticsLabel $markedSemanticsLabel' : cellSemanticsLabel;

    return _LabyrinthCell(
      cell: cell,
      size: size,
      background: background,
      borderColor: scheme.outlineVariant,
      semanticsLabel: label,
      semanticsValue: glyphFor(letter),
      onTap: onCellTap,
      onLongPress: onCellLongPress,
      onSecondaryTap: onCellLongPress,
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

/// One grid cell's background, tap target, and semantics.
///
/// Wired gestures: [onTap] (extend/retract the path, or toggle a mark when
/// not adjacent to either chain head - see [LabyrinthBoard.tap]),
/// [onLongPress] (toggle a manual cross), and [onSecondaryTap] (right-click,
/// desktop mouse - also toggles a manual cross).
class _LabyrinthCell extends StatelessWidget {
  final Cell cell;
  final double size;
  final Color background;
  final Color borderColor;
  final String semanticsLabel;
  final String semanticsValue;
  final ValueChanged<Cell> onTap;
  final ValueChanged<Cell> onLongPress;
  final ValueChanged<Cell> onSecondaryTap;

  const _LabyrinthCell({
    required this.cell,
    required this.size,
    required this.background,
    required this.borderColor,
    required this.semanticsLabel,
    required this.semanticsValue,
    required this.onTap,
    required this.onLongPress,
    required this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      value: semanticsValue,
      child: GestureDetector(
        onTap: () => onTap(cell),
        onLongPress: () => onLongPress(cell),
        onSecondaryTap: () => onSecondaryTap(cell),
        child: Container(
          key: ValueKey('cell_${cell.row}_${cell.col}'),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: borderColor, width: LabyrinthGridWidget._thinEdge),
          ),
        ),
      ),
    );
  }
}

/// Paints the two chains as polylines through cell centres, rings each
/// chain's head, and paints auto-crosses (faint translucent red fill) then
/// manual crosses (stronger translucent red fill) on top in the same cell
/// slot.
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

    void fillCell(Cell cell, Color color) {
      final rect = Rect.fromLTWH(
        cell.col * cellSize,
        cell.row * cellSize,
        cellSize,
        cellSize,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }

    for (final cell in board.autoCrosses) {
      fillCell(cell, autoCrossColor);
    }
    for (final cell in board.manualCrosses) {
      fillCell(cell, manualCrossColor);
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
