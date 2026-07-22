import 'package:flutter/material.dart';
import 'package:module_labyrinth/module_labyrinth.dart';

/// A header ("Alphabet") plus a wrap of all 33 glyphs in [russianAlphabet]
/// order: each glyph dims and gets a line-through once its canonical
/// letter is present in [usedLetters]; a letter also present in
/// [duplicateLetters] is rendered in the error color instead. Followed by
/// a small "Letters: N of 33" counter line.
///
/// Plain [StatelessWidget] taking only data + a [glyphFor] callback — no
/// provider reads — so it is trivially testable and reusable from both the
/// desktop side column and the mobile below-grid layout.
class LabyrinthAlphabetTracker extends StatelessWidget {
  /// Header shown above the tracker strip.
  final String label;

  /// Canonical letters currently present somewhere on the path (a letter
  /// used twice still appears once here).
  final Set<String> usedLetters;

  /// Canonical letters occurring more than once on the path.
  final Set<String> duplicateLetters;

  /// Maps a canonical (Cyrillic) letter to the glyph to display.
  final String Function(String canonicalLetter) glyphFor;

  /// Text for the "Letters: N of 33" counter line.
  final String placedCounterText;

  /// Whether to render enlarged (desktop) text.
  final bool big;

  /// Creates an alphabet tracker.
  const LabyrinthAlphabetTracker({
    super.key,
    required this.label,
    required this.usedLetters,
    required this.duplicateLetters,
    required this.glyphFor,
    required this.placedCounterText,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final headerStyle = big ? theme.textTheme.titleLarge : theme.textTheme.titleMedium;
    final fontSize = big ? 20.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: headerStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: big ? 8 : 6,
          runSpacing: big ? 8 : 6,
          children: [
            for (final letter in russianAlphabet)
              _glyphChip(context, scheme, letter, fontSize),
          ],
        ),
        const SizedBox(height: 8),
        Text(placedCounterText, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _glyphChip(BuildContext context, ColorScheme scheme, String letter, double fontSize) {
    final used = usedLetters.contains(letter);
    final duplicate = duplicateLetters.contains(letter);

    Color color;
    if (duplicate) {
      color = scheme.error;
    } else if (used) {
      color = scheme.onSurfaceVariant.withValues(alpha: 0.45);
    } else {
      color = scheme.onSurface;
    }

    return Container(
      width: fontSize * 1.8,
      height: fontSize * 1.8,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: duplicate ? scheme.errorContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        glyphFor(letter),
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w600,
          decoration: used && !duplicate ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}
