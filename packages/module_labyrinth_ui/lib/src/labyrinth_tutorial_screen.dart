import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_labyrinth/module_labyrinth.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'labyrinth_grid_widget.dart';
import 'labyrinth_l10n.dart';
import 'labyrinth_module.dart';
import 'labyrinth_providers.dart';

/// The growing end anchored at `Я`, in the bottom-right corner - see
/// [LabyrinthBoard.fromPuzzle].
const Cell _zAnchor = Cell(7, 7);

/// The guided "how to solve" tutorial: a fixed 12-step walkthrough of
/// solving the `example` puzzle along the book's deduction order. Steps 1-3
/// teach the tap-to-extend, long-press-to-cross, and mark mechanics; steps
/// 4-12 progressively reveal the example's 33-cell solution path (in the
/// recorded solution order) and highlight the cells added at each step.
///
/// The revealed cells are always a contiguous prefix of the stored
/// `solution` (see `labyrinthTutorialSteps`' doc comment), so this screen
/// builds the display board directly from that prefix - split into
/// `chainA` (the prefix, minus `Я` if the prefix is already complete) and
/// `chainZ` (just its fixed anchor) - via [LabyrinthBoard.fromJson], rather
/// than replaying it through [LabyrinthBoard.tap].
///
/// Completion is recorded (a `tutorial: {completed: true, completedAt:
/// ...}` entry merged into the module's save namespace) when the player
/// reaches the final step and taps "Done"; left unrecorded if they
/// close/skip early.
class LabyrinthTutorialScreen extends ConsumerStatefulWidget {
  /// Creates the tutorial screen.
  const LabyrinthTutorialScreen({super.key});

  @override
  ConsumerState<LabyrinthTutorialScreen> createState() => _LabyrinthTutorialScreenState();
}

class _LabyrinthTutorialScreenState extends ConsumerState<LabyrinthTutorialScreen> {
  int _stepIndex = 0;

  @override
  Widget build(BuildContext context) => _buildContent(context);

  Widget _buildContent(BuildContext context) {
    final puzzlesAsync = ref.watch(labyrinthPuzzlesProvider);
    return puzzlesAsync.when(
      data: (puzzles) => _buildLoaded(context, puzzles),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(body: Center(child: Text('$error'))),
    );
  }

  Widget _buildLoaded(BuildContext context, List<LabyrinthPuzzle> puzzles) {
    final l10n = ref.watch(labyrinthL10nProvider);
    final example = puzzles.firstWhere((p) => p.tutorial);
    final solution = example.solution ?? const <Cell>[];
    final step = labyrinthTutorialSteps[_stepIndex];

    // Reveals are cumulative across steps 0.._stepIndex, and - per
    // labyrinthTutorialSteps' doc comment - always union up to a
    // contiguous prefix {0, 1, ..., m} of the solution's indices.
    final revealed = <int>{};
    for (var i = 0; i <= _stepIndex && i < labyrinthTutorialSteps.length; i++) {
      revealed.addAll(labyrinthTutorialSteps[i].revealPathIndices);
    }
    final revealedIndices = revealed.toList()..sort();
    final revealedCells = [
      for (final idx in revealedIndices)
        if (idx >= 0 && idx < solution.length) solution[idx],
    ];
    // The revealed prefix always starts at solution[0] == Cell(0,0) (the А
    // anchor) whenever it is non-empty, so it is always a valid chainA on
    // its own. Once the prefix reaches Я (the final step), pull it out of
    // chainA and into its own chainZ anchor - the two chains may never
    // share a cell.
    final chainA = revealedCells.isNotEmpty && revealedCells.last == _zAnchor
        ? revealedCells.sublist(0, revealedCells.length - 1)
        : revealedCells;
    final board = LabyrinthBoard.fromJson(example, {
      'chainA': chainA.isEmpty
          ? [
              [0, 0],
            ]
          : [
              for (final c in chainA) [c.row, c.col],
            ],
      'chainZ': [
        [_zAnchor.row, _zAnchor.col],
      ],
      'crosses': [
        for (final c in step.crossCells) [c.row, c.col],
      ],
      'marks': [
        for (final c in step.markCells) [c.row, c.col],
      ],
    });

    final highlighted = <Cell>{
      for (final idx in step.highlightPathIndices)
        if (idx >= 0 && idx < solution.length) solution[idx],
    };

    final isFirst = _stepIndex == 0;
    final isLast = _stepIndex == labyrinthTutorialSteps.length - 1;

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
              ref.read(labyrinthAudioServiceProvider).play(Sfx.tap);
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
              child: LabyrinthGridWidget(
                board: board,
                status: board.status(),
                glyphFor: l10n.glyphFor,
                onCellTap: (_) {},
                onCellLongPress: (_) {},
                onCellMark: (_) {},
                cellSemanticsLabel: l10n.cellSemantics,
                markedSemanticsLabel: l10n.markedSemantics,
                highlightedCells: highlighted,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Text(
                    l10n.tutorialStepCounter(_stepIndex + 1, labyrinthTutorialSteps.length),
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
                        ref.read(labyrinthAudioServiceProvider).play(Sfx.tap);
                        setState(() => _stepIndex -= 1);
                      },
                      child: Text(l10n.tutorialBack),
                    ),
                  if (!isFirst) const SizedBox(width: 12),
                  FilledButton(
                    key: const ValueKey('tutorialNextButton'),
                    onPressed: () {
                      ref.read(labyrinthAudioServiceProvider).play(isLast ? Sfx.win : Sfx.tap);
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
    final saveService = ref.read(labyrinthSaveServiceProvider);
    final navigator = Navigator.of(context);
    final namespaceData = await saveService.load(labyrinthSaveNamespace);
    final merged = Map<String, dynamic>.from(namespaceData);
    merged['tutorial'] = <String, dynamic>{
      'completed': true,
      'completedAt': DateTime.now().toIso8601String(),
    };
    await saveService.save(labyrinthSaveNamespace, merged);
    if (!mounted) return;
    navigator.pop();
  }
}
