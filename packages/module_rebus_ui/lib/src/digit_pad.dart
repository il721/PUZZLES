import 'package:flutter/material.dart';

/// An on-screen numeric keypad (1-9, 0, backspace) for entering digits into
/// the selected grid cell.
class DigitPad extends StatelessWidget {
  /// Called with the pressed digit (0-9).
  final ValueChanged<int> onDigit;

  /// Called when the backspace key is pressed.
  final VoidCallback onBackspace;

  /// Whether the pad accepts input. When `false`, all keys are disabled
  /// (e.g. while the grid is locked for review).
  final bool enabled;

  /// Creates a digit pad.
  const DigitPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget button(String keySuffix, String label, VoidCallback onTap, {IconData? icon}) {
      return SizedBox(
        width: 56,
        height: 48,
        child: FilledButton.tonal(
          key: ValueKey('digitPad_$keySuffix'),
          onPressed: enabled ? onTap : null,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            padding: EdgeInsets.zero,
          ),
          child: icon != null ? Icon(icon) : Text(label, style: theme.textTheme.titleMedium),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var d = 1; d <= 9; d++) button('$d', '$d', () => onDigit(d)),
        button('0', '0', () => onDigit(0)),
        button('backspace', '', onBackspace, icon: Icons.backspace_outlined),
      ],
    );
  }
}
