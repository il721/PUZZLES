import 'package:flutter/material.dart';
import 'package:module_rebus/module_rebus.dart';

/// Renders a full rebus grid: the four arithmetic-row equations, a divider,
/// and the summary line (`a + b + c + d = total`).
///
/// The whole grid is always visible: content is laid out at its natural
/// size and scaled to fit the available space via [FittedBox], never
/// scrolled or clipped. Only [Theme]-derived colors are used, so the grid
/// adapts to light/dark and to a module accent color.
class PuzzleGridWidget extends StatelessWidget {
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
  /// carrying the tap's global position — used by [PuzzleScreen] to anchor
  /// the popup digit menu at the tap location.
  final void Function(CellRef ref, Offset globalPosition)? onCellTapDown;

  /// Called when the player right-clicks (desktop) or long-presses
  /// (Android) a cell, requesting it be cleared.
  final ValueChanged<CellRef>? onCellClear;

  /// Cells to visually emphasize (e.g. for the guided tutorial), with a
  /// `primaryContainer` background and `primary` border. Takes precedence
  /// over the given/selected styling, but never overrides the violation
  /// highlight.
  final Set<CellRef> emphasized;

  /// Accessibility (screen reader) label for a pre-filled, immutable cell.
  final String givenSemanticsLabel;

  /// Accessibility (screen reader) label for an editable cell.
  final String editableSemanticsLabel;

  /// Side length of a single digit cell, in logical pixels.
  static const double _cellSize = 50;

  /// Margin applied to every side of a digit cell.
  static const double _cellMargin = 1.5;

  /// Total horizontal (or vertical) space one digit cell occupies within
  /// its box group, including its margins on both sides.
  static const double _boxExtent = _cellSize + _cellMargin * 2;

  /// Fixed width of an operator glyph's container, so every operator
  /// column lines up across rows regardless of which glyph it holds.
  static const double _operatorWidth = 40;

  /// Creates a grid widget.
  const PuzzleGridWidget({
    super.key,
    required this.grid,
    required this.selected,
    required this.violations,
    required this.onCellTap,
    required this.givenSemanticsLabel,
    required this.editableSemanticsLabel,
    this.onCellTapDown,
    this.onCellClear,
    this.emphasized = const {},
  });

  @override
  Widget build(BuildContext context) {
    // Each of the 5 slots (4 operands + result) must line up in a straight
    // vertical column across all 5 rows (4 equations + summary), even
    // though individual box groups may have different widths (e.g. a
    // 2-digit operand in one row, a 1-digit operand in another). Computing
    // the widest box-group per slot up front lets every row reserve
    // identical fixed-width space for that slot.
    final slotWidths = <int, int>{
      for (var slot = 0; slot < 5; slot++)
        slot: [for (var r = 0; r < 5; r++) grid.widthOf(r, slot)].reduce((a, b) => a > b ? a : b),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var r = 0; r < 4; r++) ...[
                    _buildEquationRow(context, r, slotWidths),
                    const SizedBox(height: 8),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  _buildSummaryRow(context, slotWidths),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEquationRow(BuildContext context, int row, Map<int, int> slotWidths) {
    final ops = grid.puzzle.rows[row].ops;
    final children = <Widget>[];
    for (var slot = 0; slot < 4; slot++) {
      children.add(_numberBoxGroup(context, row, slot, slotWidths[slot]!));
      if (slot < 3) {
        children.add(_operatorGlyph(context, ops[slot]));
      }
    }
    children.add(_operatorGlyph(context, '='));
    children.add(_numberBoxGroup(context, row, 4, slotWidths[4]!));
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _buildSummaryRow(BuildContext context, Map<int, int> slotWidths) {
    final children = <Widget>[];
    for (var slot = 0; slot < 4; slot++) {
      children.add(_numberBoxGroup(context, 4, slot, slotWidths[slot]!));
      if (slot < 3) {
        children.add(_operatorGlyph(context, '+'));
      }
    }
    children.add(_operatorGlyph(context, '='));
    children.add(_numberBoxGroup(context, 4, 4, slotWidths[4]!));
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  /// Renders the box group at `(row, slot)` inside a fixed-width slot of
  /// [maxWidth] boxes (the widest this slot is anywhere in the grid),
  /// right-aligning the (possibly narrower) actual group within it so
  /// every slot column shares one right edge across rows, matching the
  /// source book's layout.
  Widget _numberBoxGroup(BuildContext context, int row, int slot, int maxWidth) {
    final width = grid.widthOf(row, slot);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: SizedBox(
        width: maxWidth * _boxExtent,
        child: Align(alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var pos = 0; pos < width; pos++) _digitCell(context, CellRef(row, slot, pos)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _digitCell(BuildContext context, CellRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final digit = grid.digitAt(ref);
    final given = grid.isGiven(ref);
    final isSelected = ref == selected;
    final hasViolation = violations?.involves(ref) ?? false;
    final isEmphasized = emphasized.contains(ref);

    Color background = given ? scheme.surfaceContainerHighest : scheme.surface;
    Color textColor = given ? scheme.onSurfaceVariant : scheme.onSurface;
    Color borderColor = scheme.outline;
    var borderWidth = 1.5;

    if (isEmphasized) {
      background = scheme.primaryContainer;
      borderColor = scheme.primary;
      borderWidth = 2.0;
    }
    if (hasViolation) {
      background = scheme.errorContainer;
      borderColor = scheme.error;
      textColor = scheme.onErrorContainer;
      borderWidth = 2.0;
    }
    if (isSelected) {
      borderColor = scheme.primary;
      borderWidth = 2.5;
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: given ? givenSemanticsLabel : editableSemanticsLabel,
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
          alignment: Alignment.center,
          child: Text(
            digit?.toString() ?? '',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: textColor,
              fontWeight: given ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _operatorGlyph(BuildContext context, String op) {
    final glyph = switch (op) {
      '*' => '×',
      '-' => '−',
      ':' => ':',
      _ => op,
    };
    return SizedBox(
      width: _operatorWidth,
      child: Center(
        child: Text(
          glyph,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}
