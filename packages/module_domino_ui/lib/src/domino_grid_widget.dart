import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:module_domino/module_domino.dart';

/// Renders the 8x7 domino board: every cell shows its fixed printed digit;
/// placed dominoes are drawn as merged tiles (interior seam removed) with a
/// blue fill and bold outline. Duplicate (conflicting) tiles are tinted red;
/// the pending single-cell selection uses the secondary container.
///
/// The board grows to fill the space its parent gives it: cell size is
/// derived from the incoming constraints (`LayoutBuilder`), so the same
/// widget renders large in a roomy desktop column and shrinks to fit a
/// narrow phone. When height is unbounded it falls back to a fixed cell
/// size, and it never exceeds [_maxCell].
class DominoGridWidget extends StatelessWidget {
  /// The board to render.
  final PlayerBoard board;

  /// Placed dominoes flagged as duplicate value-pairs.
  final Set<Domino> conflicts;

  /// Called when the player taps a cell.
  final ValueChanged<Cell> onCellTap;

  /// Accessibility (screen reader) label for a grid cell.
  final String cellSemanticsLabel;

  /// Cells to visually emphasize (e.g. for the guided tutorial).
  final Set<Cell> highlighted;

  /// Optional override for the maximum cell size (defaults to [_maxCell]).
  final double? maxCell;

  static const double _padding = 12;
  static const double _fallbackCell = 46;
  static const double _maxCell = 96;
  static const double _thickEdge = 3;
  static const double _thinEdge = 1;

  /// Creates a grid widget.
  const DominoGridWidget({
    super.key,
    required this.board,
    required this.conflicts,
    required this.onCellTap,
    required this.cellSemanticsLabel,
    this.highlighted = const {},
    this.maxCell,
  });

  @override
  Widget build(BuildContext context) {
    final rows = board.puzzle.rows;
    final cols = board.puzzle.cols;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableW = constraints.maxWidth - _padding * 2;
        final availableH = constraints.maxHeight - _padding * 2;
        var cell = math.min(availableW / cols, availableH / rows);
        if (!cell.isFinite || cell <= 0) cell = _fallbackCell;
        cell = math.min(cell, maxCell ?? _maxCell);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var r = 0; r < rows; r++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var c = 0; c < cols; c++) _buildCell(context, Cell(r, c), cell),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(BuildContext context, Cell cell, double size) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final digit = board.puzzle.valueAt(cell);
    final domino = board.dominoAt(cell);
    final covered = domino != null;
    final inConflict = covered && conflicts.contains(domino);
    final isPending = board.pending == cell;
    final isHighlighted = highlighted.contains(cell);

    final Color background;
    if (inConflict) {
      background = scheme.errorContainer;
    } else if (isHighlighted) {
      background = scheme.tertiaryContainer;
    } else if (covered) {
      background = scheme.primaryContainer;
    } else if (isPending) {
      background = scheme.secondaryContainer;
    } else {
      background = scheme.surface;
    }

    final Color textColor;
    if (inConflict) {
      textColor = scheme.onErrorContainer;
    } else if (isHighlighted) {
      textColor = scheme.onTertiaryContainer;
    } else if (covered) {
      textColor = scheme.onPrimaryContainer;
    } else if (isPending) {
      textColor = scheme.onSecondaryContainer;
    } else {
      textColor = scheme.onSurfaceVariant;
    }

    BorderSide edge(Cell neighbor) {
      if (covered && (domino.a == neighbor || domino.b == neighbor)) {
        return BorderSide.none;
      }
      if (isPending) {
        return BorderSide(color: scheme.primary, width: _thickEdge);
      }
      if (covered) {
        return BorderSide(color: inConflict ? scheme.error : scheme.primary, width: _thickEdge);
      }
      return BorderSide(color: scheme.outlineVariant, width: _thinEdge);
    }

    return Semantics(
      button: true,
      label: cellSemanticsLabel,
      value: '$digit',
      child: GestureDetector(
        onTap: () => onCellTap(cell),
        child: Container(
          key: ValueKey('cell_${cell.row}_${cell.col}'),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            border: Border(
              top: edge(Cell(cell.row - 1, cell.col)),
              bottom: edge(Cell(cell.row + 1, cell.col)),
              left: edge(Cell(cell.row, cell.col - 1)),
              right: edge(Cell(cell.row, cell.col + 1)),
            ),
          ),
          child: Center(
            child: Text(
              '$digit',
              style: textTheme.headlineSmall?.copyWith(
                fontSize: size * 0.55,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
