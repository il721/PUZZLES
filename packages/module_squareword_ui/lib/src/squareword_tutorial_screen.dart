import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_squareword/module_squareword.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'squareword_grid_widget.dart';
import 'squareword_l10n.dart';
import 'squareword_module.dart';
import 'squareword_providers.dart';

/// The guided "how to solve" tutorial: a fixed 12-step walkthrough of
/// solving the `tutorial` puzzle (keyword СЛЕЗА) along the book's own
/// deduction order. Steps 1-2 introduce the grid and the rule; steps 3-11
/// progressively reveal the puzzle's 17 non-given cells; step 12 is a
/// closing step.
///
/// [squarewordTutorialSteps]' `reveal` lists are cumulative across steps
/// (each step's own list holds only what's new that step), so this screen
/// builds the display board directly from the running union of every
/// step's [SquarewordTutorialStep.reveal] up to and including
/// `_stepIndex`, via [SquarewordBoard.fromJson] - rather than replaying it
/// through [SquarewordBoard.place] - since a tutorial reveal and a
/// `{'filled': {...}}` save entry are the same shape.
///
/// Completion is recorded (a `tutorial: {completed: true, completedAt:
/// ...}` entry merged into the module's save namespace) when the player
/// reaches the final step and taps "Done"; left unrecorded if they
/// close/skip early.
class SquarewordTutorialScreen extends ConsumerStatefulWidget {
  /// Creates the tutorial screen.
  const SquarewordTutorialScreen({super.key});

  @override
  ConsumerState<SquarewordTutorialScreen> createState() => _SquarewordTutorialScreenState();
}

class _SquarewordTutorialScreenState extends ConsumerState<SquarewordTutorialScreen> {
  int _stepIndex = 0;

  @override
  Widget build(BuildContext context) => _buildContent(context);

  Widget _buildContent(BuildContext context) {
    final puzzlesAsync = ref.watch(squarewordPuzzlesProvider);
    return puzzlesAsync.when(
      data: (puzzles) => _buildLoaded(context, puzzles),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(body: Center(child: Text('$error'))),
    );
  }

  Widget _buildLoaded(BuildContext context, List<SquarewordPuzzle> puzzles) {
    final l10n = ref.watch(squarewordL10nProvider);
    final tutorialPuzzle = puzzles.firstWhere((p) => p.tutorial);
    final step = squarewordTutorialSteps[_stepIndex];

    // Reveals are cumulative across steps 0.._stepIndex; each step's own
    // [reveal] list holds only what's new that step.
    final cumulativeReveals = <Given>[
      for (var i = 0; i <= _stepIndex; i++) ...squarewordTutorialSteps[i].reveal,
    ];

    final board = SquarewordBoard.fromJson(tutorialPuzzle, {
      'filled': {
        for (final g in cumulativeReveals) '${g.row},${g.col}': g.letter,
      },
    });

    final highlighted = <Cell>{
      for (final g in step.reveal) Cell(g.row, g.col),
    };

    final isFirst = _stepIndex == 0;
    final isLast = _stepIndex == squarewordTutorialSteps.length - 1;

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
              ref.read(squarewordAudioServiceProvider).play(Sfx.tap);
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
              child: SquarewordGridWidget(
                board: board,
                status: board.status(),
                cellSemanticsLabel: l10n.cellSemantics,
                onCellTap: (_) {},
                onCellLongPress: (_) {},
                highlightedCells: highlighted,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Text(
                    l10n.tutorialStepCounter(_stepIndex + 1, squarewordTutorialSteps.length),
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
                        ref.read(squarewordAudioServiceProvider).play(Sfx.tap);
                        setState(() => _stepIndex -= 1);
                      },
                      child: Text(l10n.tutorialBack),
                    ),
                  if (!isFirst) const SizedBox(width: 12),
                  FilledButton(
                    key: const ValueKey('tutorialNextButton'),
                    onPressed: () {
                      ref.read(squarewordAudioServiceProvider).play(isLast ? Sfx.win : Sfx.tap);
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
    final saveService = ref.read(squarewordSaveServiceProvider);
    final navigator = Navigator.of(context);
    final namespaceData = await saveService.load(squarewordSaveNamespace);
    final merged = Map<String, dynamic>.from(namespaceData);
    merged['tutorial'] = <String, dynamic>{
      'completed': true,
      'completedAt': DateTime.now().toIso8601String(),
    };
    await saveService.save(squarewordSaveNamespace, merged);
    if (!mounted) return;
    navigator.pop();
  }
}
