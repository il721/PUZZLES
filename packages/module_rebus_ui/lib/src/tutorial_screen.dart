import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_rebus/module_rebus.dart';
import 'package:puzzle_core/puzzle_core.dart';

import 'puzzle_grid_widget.dart';
import 'rebus_l10n.dart';
import 'rebus_module.dart';
import 'rebus_providers.dart';

/// The guided "how to solve" tutorial: a fixed 15-step walkthrough of
/// solving the `example` puzzle, progressively revealing digits and
/// highlighting rows/columns/cells as the player steps through it.
///
/// Completion is recorded (a `tutorial: {completed: true, completedAt: ...}`
/// entry merged into the module's save namespace) when the player reaches
/// the final step and taps "Done", or is otherwise left unrecorded if they
/// close/skip early.
class TutorialScreen extends ConsumerStatefulWidget {
  /// Creates the tutorial screen.
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  late final Future<void> _orientationLockFuture;
  int _stepIndex = 0;

  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _orientationLockFuture = _isAndroid
        ? SystemChrome.setPreferredOrientations(const [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ])
        : Future<void>.value();
  }

  @override
  void dispose() {
    if (_isAndroid) {
      SystemChrome.setPreferredOrientations(const []);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAndroid) {
      return FutureBuilder<void>(
        future: _orientationLockFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            // Gate the first paint on the orientation lock to avoid a
            // one-frame wrong-orientation flash; a bare themed Scaffold
            // serves as the neutral placeholder frame meanwhile.
            return const Scaffold(body: SizedBox.shrink());
          }
          return _buildContent(context);
        },
      );
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    final puzzlesAsync = ref.watch(rebusPuzzlesProvider);
    return puzzlesAsync.when(
      data: (puzzles) => _buildLoaded(context, puzzles),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(body: Center(child: Text('$error'))),
    );
  }

  Widget _buildLoaded(BuildContext context, List<RebusPuzzle> puzzles) {
    final l10n = ref.watch(rebusL10nProvider);
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
      if (step.highlightRow != null) ..._rowCells(grid, step.highlightRow!),
      if (step.highlightColumn != null) ..._columnCells(grid, step.highlightColumn!),
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
              ref.read(rebusAudioServiceProvider).play(Sfx.tap);
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
              child: PuzzleGridWidget(
                grid: grid,
                selected: null,
                violations: null,
                onCellTap: (_) {},
                emphasized: emphasized,
                givenSemanticsLabel: l10n.cellSemanticsGiven,
                editableSemanticsLabel: l10n.cellSemanticsEditable,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Text(
                    l10n.tutorialStepCounter(_stepIndex + 1, tutorialSteps.length),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.tutorialStepText(_stepIndex + 1), textAlign: TextAlign.center),
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
                        ref.read(rebusAudioServiceProvider).play(Sfx.tap);
                        setState(() => _stepIndex -= 1);
                      },
                      child: Text(l10n.tutorialBack),
                    ),
                  if (!isFirst) const SizedBox(width: 12),
                  FilledButton(
                    key: const ValueKey('tutorialNextButton'),
                    onPressed: () {
                      ref.read(rebusAudioServiceProvider).play(isLast ? Sfx.win : Sfx.tap);
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

  /// Every cell of grid [row], including its result/total box.
  Set<CellRef> _rowCells(PlayerGrid grid, int row) {
    final cells = <CellRef>{};
    for (var slot = 0; slot <= 4; slot++) {
      for (var pos = 0; pos < grid.widthOf(row, slot); pos++) {
        cells.add(CellRef(row, slot, pos));
      }
    }
    return cells;
  }

  /// Every cell of operand slot [column] across arithmetic rows 0..3, plus
  /// the corresponding summary cell `(4, column)`.
  Set<CellRef> _columnCells(PlayerGrid grid, int column) {
    final cells = <CellRef>{};
    for (var row = 0; row <= 3; row++) {
      for (var pos = 0; pos < grid.widthOf(row, column); pos++) {
        cells.add(CellRef(row, column, pos));
      }
    }
    for (var pos = 0; pos < grid.widthOf(4, column); pos++) {
      cells.add(CellRef(4, column, pos));
    }
    return cells;
  }

  Future<void> _finish() async {
    final saveService = ref.read(saveServiceProvider);
    final navigator = Navigator.of(context);
    final namespaceData = await saveService.load(rebusSaveNamespace);
    final merged = Map<String, dynamic>.from(namespaceData);
    merged['tutorial'] = <String, dynamic>{
      'completed': true,
      'completedAt': DateTime.now().toIso8601String(),
    };
    await saveService.save(rebusSaveNamespace, merged);
    if (!mounted) return;
    navigator.pop();
  }
}
