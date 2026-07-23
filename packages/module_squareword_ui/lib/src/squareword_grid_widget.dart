import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:module_squareword/module_squareword.dart';

/// Renders an `n`x`n` squareword board: given cells are locked, filled with
/// a distinct background/bold text (matching `module_rebus_ui`'s
/// given-vs-editable convention); editable cells are tappable to open a
/// letter picker and long-pressable to clear; any cell currently in
/// [status]'s `violatingCells` is highlighted live, regardless of whether
/// it is a given or an editable cell.
///
/// Cell size is derived from the incoming constraints (`LayoutBuilder`) and
/// scales inversely with [board]'s `n`, so the same widget comfortably fits
/// a 5x5, 6x6, or 7x7 puzzle in the space its parent gives it.
class SquarewordGridWidget extends StatelessWidget {
  /// The board to render.
  final SquarewordBoard board;

  /// The board's current status snapshot (used for violation highlighting).
  final SquarewordStatus status;

  /// Called when the player taps an editable cell (to open the letter
  /// picker). Never called for a given cell.
  final ValueChanged<Cell> onCellTap;

  /// Called when the player long-presses an editable cell (to clear it).
  /// Never called for a given cell.
  final ValueChanged<Cell> onCellLongPress;

  /// Accessibility (screen reader) label for a grid cell.
  final String cellSemanticsLabel;

  /// Optional override for the maximum cell size (defaults to [_maxCell]).
  final double? maxCell;

  static const double _padding = 12;
  static const double _fallbackCell = 40;
  static const double _maxCell = 72;
  static const double _borderWidth = 1;

  /// Creates a grid widget.
  const SquarewordGridWidget({
    super.key,
    required this.board,
    required this.status,
    required this.onCellTap,
    required this.onCellLongPress,
    required this.cellSemanticsLabel,
    this.maxCell,
  });

  @override
  Widget build(BuildContext context) {
    final n = board.puzzle.n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableW = constraints.maxWidth - _padding * 2;
        final availableH = constraints.maxHeight - _padding * 2;
        var cell = math.min(availableW / n, availableH / n);
        if (!cell.isFinite || cell <= 0) cell = _fallbackCell;
        cell = math.min(cell, maxCell ?? _maxCell);

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var r = 0; r < n; r++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var c = 0; c < n; c++) _buildCell(context, Cell(r, c), cell),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final given = board.isGiven(cell);
    final letter = board.letterAt(cell);
    final violating = status.violatingCells.contains(cell);

    Color background = given ? scheme.surfaceContainerHighest : scheme.surface;
    Color textColor = given ? (isDark ? Colors.white : Colors.black) : scheme.primary;
    Color borderColor = scheme.outlineVariant;
    var borderWidth = _borderWidth;

    if (violating) {
      background = scheme.errorContainer;
      textColor = scheme.onErrorContainer;
      borderColor = scheme.error;
      borderWidth = 2;
    }

    return Semantics(
      button: !given,
      label: cellSemanticsLabel,
      value: letter,
      child: GestureDetector(
        onTap: given ? null : () => onCellTap(cell),
        onLongPress: given ? null : () => onCellLongPress(cell),
        child: Container(
          key: ValueKey('cell_${cell.row}_${cell.col}'),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Text(
            letter ?? '',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: size * 0.45,
              color: textColor,
              fontWeight: given ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
