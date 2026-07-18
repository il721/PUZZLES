import 'package:flutter/material.dart';
import 'package:module_digit_rebus/module_digit_rebus.dart';

import 'glyph_painter.dart';

/// The always-available glyph-to-digit-set legend: one entry per [Glyph]
/// showing its marker and the digits it admits. Shown beneath the puzzle
/// grid so the player never has to memorize the five sets.
class GlyphLegend extends StatelessWidget {
  /// Creates the legend.
  const GlyphLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final glyph in Glyph.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outline),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: CustomPaint(
                  painter: GlyphMarkerPainter(glyph: glyph, color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                (glyph.digits.toList()..sort()).join(' '),
                style: theme.textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
      ],
    );
  }
}
