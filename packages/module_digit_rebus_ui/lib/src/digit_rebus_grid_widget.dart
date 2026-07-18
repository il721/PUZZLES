import 'package:flutter/material.dart';
import 'package:module_digit_rebus/module_digit_rebus.dart';

import 'glyph_painter.dart';

/// Renders a full digit-rebus grid: the 4x4 glyph-masked digit cells with
/// row operators between the columns and column operators between the rows
/// (the last operator of each line being `=`, since the fourth row/column
/// double as results).
///
/// The whole grid is always visible: content is laid out at its natural
/// size and scaled to fit the available space via [FittedBox], never
/// scrolled or clipped.
///
/// Each cell's bold border is drawn in its glyph's identifying color
/// (same digit set = same color); selection/emphasis tint the background;
/// violations tint the background red — the border always keeps the
/// glyph color.
class DigitRebusGridWidget extends StatelessWidget {
  /// The grid to render.
  final PlayerGrid grid;

  /// The currently selected cell, if any.
  final CellRef? selected;

  /// Violations from the most recent "Check" press, if a highlight should
  /// currently be shown.
  final GridViolations? violations;

  /// Called when the player taps a cell.
  final ValueChanged<CellRef> onCellTap;

  /// Called (in addition to [onCellTap]) when the player taps a cell,
  /// carrying the tap's global position — used by the puzzle screen to
  /// anchor the popup digit menu at the tap location.
  final void Function(CellRef ref, Offset globalPosition)? onCellTapDown;

  /// Called when the player right-clicks (desktop) or long-presses
  /// (Android) a cell, requesting it be cleared.
  final ValueChanged<CellRef>? onCellClear;

  /// Cells to visually emphasize (e.g. for the guided tutorial), with a
  /// `primaryContainer` background tint; the border always keeps the
  /// glyph color. Never overrides the violation highlight.
  final Set<CellRef> emphasized;

  /// Accessibility (screen reader) label for a grid cell.
  final String editableSemanticsLabel;

  /// Side length of a single digit cell, in logical pixels.
  static const double _cellSize = 58;

  /// Margin applied to every side of a digit cell.
  static const double _cellMargin = 1.5;

  /// Width/height of an operator's container, so operators line up in
  /// straight lanes between the cell rows and columns.
  static const double _operatorExtent = 40;

  /// Creates a grid widget.
  const DigitRebusGridWidget({
    super.key,
    required this.grid,
    required this.selected,
    required this.violations,
    required this.onCellTap,
    required this.editableSemanticsLabel,
    this.onCellTapDown,
    this.onCellClear,
    this.emphasized = const {},
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var r = 0; r < 4; r++) ...[
                    _buildCellRow(context, r),
                    if (r < 3) _buildOperatorRow(context, r),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// One row of four digit cells with this row's operators (and `=`)
  /// between them.
  Widget _buildCellRow(BuildContext context, int row) {
    final ops = grid.puzzle.rowOps[row];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var c = 0; c < 4; c++) ...[
          _digitCell(context, CellRef(row, c)),
          if (c < 3)
            _operatorBox(context, c < 2 ? ops[c] : '=',
                width: _operatorExtent, height: _cellSize + _cellMargin * 2),
        ],
      ],
    );
  }

  /// The lane between cell row [row] and row `row + 1`: each column's
  /// operator (or `=` before the last row), aligned under its column of
  /// cells, with spacers under the operator lanes.
  Widget _buildOperatorRow(BuildContext context, int row) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var c = 0; c < 4; c++) ...[
          _operatorBox(
            context,
            row < 2 ? grid.puzzle.colOps[c][row] : '=',
            width: _cellSize + _cellMargin * 2,
            height: _operatorExtent,
          ),
          if (c < 3) const SizedBox(width: _operatorExtent),
        ],
      ],
    );
  }

  Widget _digitCell(BuildContext context, CellRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final digit = grid.digitAt(ref);
    final glyph = grid.puzzle.glyphs[ref.row][ref.col];
    final isSelected = ref == selected;
    final hasViolation = violations?.involves(ref) ?? false;
    final isEmphasized = emphasized.contains(ref);

    Color background = scheme.surface;
    Color textColor = scheme.primary;
    Color borderColor = glyphColor(glyph);
    var borderWidth = glyphBorderWidth;

    if (isEmphasized) {
      background = scheme.primaryContainer;
    }
    if (hasViolation) {
      background = scheme.errorContainer;
      textColor = scheme.onErrorContainer;
    }
    if (isSelected) {
      background = scheme.primaryContainer;
      borderWidth = glyphBorderWidth + 1.5;
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: editableSemanticsLabel,
      value: digit?.toString(),
      child: GestureDetector(
        onTapUp: (details) {
          onCellTap(ref);
          onCellTapDown?.call(ref, details.globalPosition);
        },
        onSecondaryTap: onCellClear == null ? null : () => onCellClear!(ref),
        onLongPress: onCellClear == null ? null : () => onCellClear!(ref),
        child: Container(
          key: ValueKey('cell_${ref.key}'),
          width: _cellSize,
          height: _cellSize,
          margin: const EdgeInsets.all(_cellMargin),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: borderColor, width: borderWidth),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              digit?.toString() ?? '',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 30,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _operatorBox(BuildContext context, String op, {required double width, required double height}) {
    final glyph = switch (op) {
      '*' => '×',
      '-' => '−',
      ':' => ':',
      _ => op,
    };
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Text(
          glyph,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
              ),
        ),
      ),
    );
  }
}
