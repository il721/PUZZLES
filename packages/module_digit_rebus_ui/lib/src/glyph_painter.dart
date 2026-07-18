import 'package:flutter/material.dart';
import 'package:module_digit_rebus/module_digit_rebus.dart';

/// Fixed colors identifying the five glyph digit sets. A cell's (and the
/// legend sample's) bold outer border is drawn in its glyph's color, so
/// cells admitting the same set of digits always share one border color —
/// in the grid and in the legend alike. Hues chosen to stay distinct on
/// both the light and dark themes (g1's dark blue is far darker than the
/// primary used for entered digits).
const Map<Glyph, Color> _glyphColors = {
  Glyph.g1: Color(0xFF0D47A1), // dark blue - {0, 8, 9}
  Glyph.g2: Color(0xFF43A047), // green - {0, 6, 8}
  Glyph.g3: Color(0xFFFB8C00), // orange - {1, 4, 7}
  Glyph.g4: Color(0xFFAB47BC), // purple - {2, 3}
  Glyph.g5: Color(0xFF00ACC1), // cyan - {3, 5, 9}
};

/// The border color identifying [glyph].
Color glyphColor(Glyph glyph) => _glyphColors[glyph]!;

/// Width of the bold glyph-colored border, shared by grid cells and the
/// legend samples.
const double glyphBorderWidth = 3.0;
