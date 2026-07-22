import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:module_labyrinth/module_labyrinth.dart';

/// Renders the 8x8 labyrinth board: every cell shows its fixed printed
/// letter (through [glyphFor], so EN/DE locales see the substitute glyph
/// grid); the two growing chains are drawn as polylines through cell
/// centres, with a ring around each chain's head; auto-crosses (letters
/// that became non-conducting because their twin is already on a chain)
/// are drawn as a thin light grey X, and manual crosses (the player's own
/// long-press marks) as a thicker dark X in the same slot, painted on top.
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

  /// Called when the player long-presses a cell.
  final ValueChanged<Cell> onCellLongPress;

  /// Called when the player marks a cell (right-click on desktop, double
  /// tap on touch — see [_LabyrinthCellState]).
  final ValueChanged<Cell> onCellMark;

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
    required this.onCellMark,
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
      onSecondaryTap: onCellMark,
      onDoubleTapLike: onCellMark,
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
/// Wired gestures: [onTap] (extend/retract the path), [onLongPress] (toggle
/// a manual cross), [onSecondaryTap] (right-click, desktop mouse - toggles
/// a mark), and a hand-rolled double-tap detector (see
/// [_LabyrinthCellState._handleTapDown]) that also toggles a mark on touch
/// devices.
///
/// A [StatefulWidget] rather than a plain function is needed here purely to
/// hold [_LabyrinthCellState._lastTapDownAt] across rebuilds - the double-tap
/// detector below needs a timestamp that survives the parent
/// [LabyrinthGridWidget] (a [StatelessWidget]) being rebuilt on every board
/// mutation. Flutter preserves this State by (row, col) position in the
/// fixed, never-reordered 8x8 grid, matching the same [key] used for the
/// inner [Container] for extra safety.
///
/// Why not [GestureDetector.onDoubleTap]: Flutter's own docs note that
/// combining `onTap` and `onDoubleTap` on one [GestureDetector] delays every
/// single tap by [kDoubleTapTimeout] (~300ms), because the arena has to wait
/// to see whether a second tap follows before it can resolve a lone tap as
/// final. That would make the primary "extend the path" interaction feel
/// laggy on every tap, everywhere, not just on cells the player intends to
/// mark. Instead, [onTap] stays wired to a plain, immediate
/// [GestureDetector.onTap]/[GestureDetector.onTapDown] pair, and the
/// double-tap gesture is detected manually by comparing consecutive
/// [GestureDetector.onTapDown] timestamps against [kDoubleTapTimeout] - no
/// [DoubleTapGestureRecognizer] ever enters the gesture arena, so [onTap]
/// is never delayed. The tradeoff: this reimplements a simplified slice of
/// what [GestureDetector.onDoubleTap] already does (same cell only, no
/// pointer-movement/slop tolerance), which is acceptable given each cell is
/// a small, fixed-size, non-overlapping hit target.
class _LabyrinthCell extends StatefulWidget {
  final Cell cell;
  final double size;
  final Color background;
  final Color borderColor;
  final String semanticsLabel;
  final String semanticsValue;
  final ValueChanged<Cell> onTap;
  final ValueChanged<Cell> onLongPress;
  final ValueChanged<Cell> onSecondaryTap;
  final ValueChanged<Cell> onDoubleTapLike;

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
    required this.onDoubleTapLike,
  });

  @override
  State<_LabyrinthCell> createState() => _LabyrinthCellState();
}

class _LabyrinthCellState extends State<_LabyrinthCell> {
  DateTime? _lastTapDownAt;

  void _handleTapDown(TapDownDetails details) {
    final now = DateTime.now();
    final last = _lastTapDownAt;
    if (last != null && now.difference(last) <= kDoubleTapTimeout) {
      // Consume the pair so a third rapid tap starts a fresh count rather
      // than immediately re-triggering.
      _lastTapDownAt = null;
      widget.onDoubleTapLike(widget.cell);
    } else {
      _lastTapDownAt = now;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      value: widget.semanticsValue,
      child: GestureDetector(
        onTap: () => widget.onTap(widget.cell),
        onTapDown: _handleTapDown,
        onLongPress: () => widget.onLongPress(widget.cell),
        onSecondaryTap: () => widget.onSecondaryTap(widget.cell),
        child: Container(
          key: ValueKey('cell_${widget.cell.row}_${widget.cell.col}'),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.background,
            border: Border.all(color: widget.borderColor, width: LabyrinthGridWidget._thinEdge),
          ),
        ),
      ),
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
