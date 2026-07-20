import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_digit_rebus/module_digit_rebus.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'digit_rebus_grid_widget.dart';
import 'digit_rebus_l10n.dart';
import 'digit_rebus_module.dart';
import 'digit_rebus_providers.dart';
import 'glyph_legend.dart';

/// The guided "how to solve" tutorial: a fixed 9-step walkthrough of
/// solving the `example` puzzle along the book's deduction chain (row 2,
/// column 1, row 3, column 3, then the rest), progressively revealing
/// digits and highlighting rows/columns as the player steps through it.
///
/// Completion is recorded (a `tutorial: {completed: true, completedAt: ...}`
/// entry merged into the module's save namespace) when the player reaches
/// the final step and taps "Done", or is otherwise left unrecorded if they
/// close/skip early.
class DigitRebusTutorialScreen extends ConsumerStatefulWidget {
  /// Creates the tutorial screen.
  const DigitRebusTutorialScreen({super.key});

  @override
  ConsumerState<DigitRebusTutorialScreen> createState() => _DigitRebusTutorialScreenState();
}

class _DigitRebusTutorialScreenState extends ConsumerState<DigitRebusTutorialScreen> {
  int _stepIndex = 0;

  @override
  Widget build(BuildContext context) => _buildContent(context);

  Widget _buildContent(BuildContext context) {
    final puzzlesAsync = ref.watch(digitRebusPuzzlesProvider);
    return puzzlesAsync.when(
      data: (puzzles) => _buildLoaded(context, puzzles),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(body: Center(child: Text('$error'))),
    );
  }

  Widget _buildLoaded(BuildContext context, List<DigitRebusPuzzle> puzzles) {
    final l10n = ref.watch(digitRebusL10nProvider);
    final example = puzzles.firstWhere((p) => p.tutorial);
    final grid = PlayerGrid.fromPuzzle(example);

    for (var i = 0; i <= _stepIndex; i++) {
      for (final cell in tutorialSteps[i].reveal) {
        grid.setDigit(cell, canonicalDigitAt(example, cell));
      }
    }

    final step = tutorialSteps[_stepIndex];
    final emphasized = <CellRef>{
      ...step.highlightCells,
      if (step.highlightRow != null)
        for (var c = 0; c < 4; c++) CellRef(step.highlightRow!, c),
      if (step.highlightColumn != null)
        for (var r = 0; r < 4; r++) CellRef(r, step.highlightColumn!),
    };

    final isFirst = _stepIndex == 0;
    final isLast = _stepIndex == tutorialSteps.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tutorialTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(digitRebusAudioServiceProvider).play(Sfx.tap);
              Navigator.of(context).pop();
            },
            child: Text(l10n.tutorialSkip),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: DigitRebusGridWidget(
                grid: grid,
                selected: null,
                violations: null,
                onCellTap: (_) {},
                emphasized: emphasized,
                editableSemanticsLabel: l10n.cellSemanticsEditable,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: GlyphLegend(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Text(
                    l10n.tutorialStepCounter(_stepIndex + 1, tutorialSteps.length),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.tutorialStepText(_stepIndex + 1),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isFirst)
                    OutlinedButton(
                      key: const ValueKey('tutorialBackButton'),
                      onPressed: () {
                        ref.read(digitRebusAudioServiceProvider).play(Sfx.tap);
                        setState(() => _stepIndex -= 1);
                      },
                      child: Text(l10n.tutorialBack),
                    ),
                  if (!isFirst) const SizedBox(width: 12),
                  FilledButton(
                    key: const ValueKey('tutorialNextButton'),
                    onPressed: () {
                      ref.read(digitRebusAudioServiceProvider).play(isLast ? Sfx.win : Sfx.tap);
                      if (isLast) {
                        _finish();
                      } else {
                        setState(() => _stepIndex += 1);
                      }
                    },
                    child: Text(isLast ? l10n.tutorialDone : l10n.tutorialNext),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish() async {
    final saveService = ref.read(digitRebusSaveServiceProvider);
    final navigator = Navigator.of(context);
    final namespaceData = await saveService.load(digitRebusSaveNamespace);
    final merged = Map<String, dynamic>.from(namespaceData);
    merged['tutorial'] = <String, dynamic>{
      'completed': true,
      'completedAt': DateTime.now().toIso8601String(),
    };
    await saveService.save(digitRebusSaveNamespace, merged);
    if (!mounted) return;
    navigator.pop();
  }
}
