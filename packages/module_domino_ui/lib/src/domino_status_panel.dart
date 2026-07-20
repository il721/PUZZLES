import 'package:flutter/material.dart';
import 'package:module_domino/module_domino.dart';

import 'domino_l10n.dart';

/// The minimal progress panel below the board: the "N of 28 placed" counter,
/// a one-line duplicate warning when conflicts are present, and the list of
/// double-six value-pairs not yet used.
class DominoStatusPanel extends StatelessWidget {
  /// The current board status snapshot.
  final BoardStatus status;

  /// Localized strings.
  final DominoL10n l10n;

  /// Creates a status panel.
  const DominoStatusPanel({super.key, required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final remaining = status.remaining;
    final hasDuplicate = status.conflicts.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.placedCounter(status.placedCount), style: theme.textTheme.titleMedium),
        if (hasDuplicate)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.duplicateWarning,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          l10n.remainingLabel,
          style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final v in remaining) _valueChip(context, v)],
        ),
      ],
    );
  }

  Widget _valueChip(BuildContext context, DominoValue value) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        '${value.low}:${value.high}',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onSurface),
      ),
    );
  }
}
