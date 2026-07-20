import 'package:flutter/material.dart';
import 'package:module_domino/module_domino.dart';

/// A single value-pair chip, e.g. "3:5". [fontSize] and [padding] let the
/// caller render a larger chip on desktop.
Widget dominoValueChip(
  BuildContext context,
  DominoValue value, {
  double fontSize = 14,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  String separator = ':',
  bool centered = false,
  bool fit = false,
  Color? backgroundColor,
  Color? foregroundColor,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    alignment: centered ? Alignment.center : null,
    padding: padding,
    decoration: BoxDecoration(
      color: backgroundColor ?? scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: scheme.outlineVariant),
    ),
    child: fit
        ? FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${value.low}$separator${value.high}',
              style: TextStyle(
                  fontSize: fontSize,
                  color: foregroundColor ?? scheme.onSurface,
                  fontWeight: FontWeight.w600),
            ),
          )
        : Text(
            '${value.low}$separator${value.high}',
            style: TextStyle(
                fontSize: fontSize,
                color: foregroundColor ?? scheme.onSurface,
                fontWeight: FontWeight.w600),
          ),
  );
}

/// A labeled, aligned grid of domino value-pairs. Used for both the
/// remaining ("still to place") set and the already-placed ("placed") set.
/// Every chip has identical content width, so the [Wrap] lays them out in
/// aligned columns and rows — a grid.
class DominoValueGrid extends StatelessWidget {
  /// The header shown above the chips.
  final String header;

  /// The value-pairs to render as chips.
  final List<DominoValue> values;

  /// Optional header text color (e.g. the accent for "Placed").
  final Color? headerColor;

  /// Whether to render enlarged (desktop) chips and header.
  final bool big;

  final bool useGrid;

  final bool blueChips;

  final Set<DominoValue>? placedValues;

  final double? chipFontSize;

  /// Number of columns in the grid (defaults to 4).
  final int? crossAxisCount;

  /// Column cross-axis alignment.
  final CrossAxisAlignment crossAxisAlignment;

  /// Wrap alignment for the chips.
  final WrapAlignment wrapAlignment;

  /// Optional maximum width (constrains the wrap so it forms columns).
  final double? maxWidth;

  /// Creates a value grid.
  const DominoValueGrid({
    super.key,
    required this.header,
    required this.values,
    this.headerColor,
    this.big = false,
    this.useGrid = false,
    this.blueChips = false,
    this.placedValues,
    this.chipFontSize,
    this.crossAxisCount,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.wrapAlignment = WrapAlignment.start,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fontSize = big ? 18.0 : 14.0;
    final chipPadding = big
        ? const EdgeInsets.symmetric(horizontal: 11, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    final headerStyle =
        (big ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)?.copyWith(color: headerColor);

    final content = Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(header, style: headerStyle),
        const SizedBox(height: 8),
        if (useGrid)
          GridView.count(
            crossAxisCount: crossAxisCount ?? 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              for (final v in values)
                Center(
                  child: dominoValueChip(
                    context,
                    v,
                    fontSize: chipFontSize ?? 26,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    separator: '  ',
                    centered: true,
                    fit: true,
                    backgroundColor: (blueChips || placedValues?.contains(v) == true) ? scheme.primary : null,
                    foregroundColor: (blueChips || placedValues?.contains(v) == true) ? scheme.onPrimary : null,
                  ),
                ),
            ],
          )
        else
          Wrap(
            alignment: wrapAlignment,
            spacing: big ? 8 : 6,
            runSpacing: big ? 8 : 6,
            children: [
              for (final v in values)
                dominoValueChip(context, v, fontSize: fontSize, padding: chipPadding),
            ],
          ),
      ],
    );

    if (maxWidth != null) {
      return ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth!), child: content);
    }
    return content;
  }
}
