import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_domino/module_domino.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'domino_grid_widget.dart';
import 'domino_l10n.dart';
import 'domino_module.dart';
import 'domino_providers.dart';

/// The guided "how to solve" tutorial: a fixed 10-step walkthrough of
/// solving the `example` puzzle along the book's deduction order. It teaches
/// the tap-to-bind mechanic first, then progressively auto-places the
/// example's 28 dominoes (in the recorded solution order) and highlights the
/// dominoes added at each step.
///
/// Completion is recorded (a `tutorial: {completed: true, completedAt: ...}`
/// entry merged into the module's save namespace) when the player reaches
/// the final step and taps "Done"; left unrecorded if they close/skip early.
class DominoTutorialScreen extends ConsumerStatefulWidget {
  /// Creates the tutorial screen.
  const DominoTutorialScreen({super.key});

  @override
  ConsumerState<DominoTutorialScreen> createState() => _DominoTutorialScreenState();
}

class _DominoTutorialScreenState extends ConsumerState<DominoTutorialScreen> {
  int _stepIndex = 0;

  @override
  Widget build(BuildContext context) => _buildContent(context);

  Widget _buildContent(BuildContext context) {
    final puzzlesAsync = ref.watch(dominoPuzzlesProvider);
    return puzzlesAsync.when(
      data: (puzzles) => _buildLoaded(context, puzzles),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(body: Center(child: Text('$error'))),
    );
  }

  Widget _buildLoaded(BuildContext context, List<DominoPuzzle> puzzles) {
    final l10n = ref.watch(dominoL10nProvider);
    final example = puzzles.firstWhere((p) => p.tutorial);
    final solution = example.solution ?? const <Domino>[];

    final revealed = <int>{};
    for (var i = 0; i <= _stepIndex && i < dominoTutorialSteps.length; i++) {
      revealed.addAll(dominoTutorialSteps[i].revealSolutionIndices);
    }
    final placedJson = <List<List<int>>>[
      for (final idx in revealed)
        if (idx >= 0 && idx < solution.length)
          [
            [solution[idx].a.row, solution[idx].a.col],
            [solution[idx].b.row, solution[idx].b.col],
          ],
    ];
    final board = PlayerBoard.fromJson(example, placedJson);

    final step = dominoTutorialSteps[_stepIndex];
    final highlighted = <Cell>{
      for (final idx in step.highlightSolutionIndices)
        if (idx >= 0 && idx < solution.length) ...[solution[idx].a, solution[idx].b],
    };

    final isFirst = _stepIndex == 0;
    final isLast = _stepIndex == dominoTutorialSteps.length - 1;

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
              ref.read(dominoAudioServiceProvider).play(Sfx.tap);
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
              child: DominoGridWidget(
                board: board,
                conflicts: const <Domino>{},
                highlighted: highlighted,
                cellSemanticsLabel: l10n.cellSemantics,
                onCellTap: (_) {},
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Text(
                    l10n.tutorialStepCounter(_stepIndex + 1, dominoTutorialSteps.length),
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
                        ref.read(dominoAudioServiceProvider).play(Sfx.tap);
                        setState(() => _stepIndex -= 1);
                      },
                      child: Text(l10n.tutorialBack),
                    ),
                  if (!isFirst) const SizedBox(width: 12),
                  FilledButton(
                    key: const ValueKey('tutorialNextButton'),
                    onPressed: () {
                      ref.read(dominoAudioServiceProvider).play(isLast ? Sfx.win : Sfx.tap);
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
    final saveService = ref.read(dominoSaveServiceProvider);
    final navigator = Navigator.of(context);
    final namespaceData = await saveService.load(dominoSaveNamespace);
    final merged = Map<String, dynamic>.from(namespaceData);
    merged['tutorial'] = <String, dynamic>{
      'completed': true,
      'completedAt': DateTime.now().toIso8601String(),
    };
    await saveService.save(dominoSaveNamespace, merged);
    if (!mounted) return;
    navigator.pop();
  }
}
