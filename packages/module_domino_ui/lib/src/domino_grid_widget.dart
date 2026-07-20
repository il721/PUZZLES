import 'package:flutter/material.dart';
import 'package:module_domino/module_domino.dart';

/// Renders the 8x7 domino board: every cell shows its fixed printed digit;
/// placed dominoes are drawn as merged tiles with the interior seam between
/// their two cells removed and a bold outline around the pair. Duplicate
/// (conflicting) tiles are tinted red; the pending single-cell selection is
/// outlined in the accent color.
///
/// The whole board is laid out at natural size and scaled to fit via
/// [FittedBox], never scrolled or clipped.
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

  static const double _cellSize = 46;
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
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var r = 0; r < board.puzzle.rows; r++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var c = 0; c < board.puzzle.cols; c++) _buildCell(context, Cell(r, c)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, Cell cell) {
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
    } else if (isPending) {
      background = scheme.primaryContainer;
    } else if (isHighlighted) {
      background = scheme.tertiaryContainer;
    } else if (covered) {
      background = scheme.surfaceContainerHighest;
    } else {
      background = scheme.surface;
    }

    final Color textColor = inConflict
        ? scheme.onErrorContainer
        : (covered || isPending ? scheme.onSurface : scheme.onSurfaceVariant);

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
          width: _cellSize,
          height: _cellSize,
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
                fontSize: 26,
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
