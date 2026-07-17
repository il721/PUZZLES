import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_rebus/module_rebus.dart';
import 'package:module_rebus_ui/module_rebus_ui.dart';
import 'package:puzzle_core/puzzle_core.dart';

/// A minimal [RebusL10n] for widget tests, independent of any real
/// localization setup.
class _FakeRebusL10n implements RebusL10n {
  const _FakeRebusL10n();

  @override
  String get puzzleListTitle => 'Rebuses';
  @override
  String puzzleN(int n) => 'Puzzle $n';
  @override
  String get statusUntouched => 'Untouched';
  @override
  String get statusInProgress => 'In progress';
  @override
  String get statusSolved => 'Solved';
  @override
  String get check => 'Check';
  @override
  String get reset => 'Reset';
  @override
  String get replay => 'Replay';
  @override
  String get next => 'Next';
  @override
  String get backToList => 'Back';
  @override
  String get resetConfirmTitle => 'Reset?';
  @override
  String get resetConfirmBody => 'Are you sure?';
  @override
  String get resetConfirmCancel => 'Cancel';
  @override
  String get resetConfirmOk => 'OK';
  @override
  String get winTitle => 'You win!';
  @override
  String winTime(String formattedTime) => 'Time: $formattedTime';
  @override
  String winChecks(int count) => 'Checks: $count';
  @override
  String get hasErrors => 'Has errors';
  @override
  String get tutorialTitle => 'How to solve';
  @override
  String get tutorialNext => 'Next';
  @override
  String get tutorialBack => 'Back';
  @override
  String get tutorialSkip => 'Skip';
  @override
  String get tutorialDone => 'Done';
  @override
  String tutorialStepCounter(int current, int total) => 'Step $current of $total';
  @override
  String tutorialStepText(int index) => 'step $index';
  @override
  String get cellSemanticsGiven => 'given digit';
  @override
  String get cellSemanticsEditable => 'editable digit';
}

/// A recording [AudioService] test double: every [play] call is appended to
/// [played] in order, with no actual playback.
class _RecordingAudio implements AudioService {
  final List<Sfx> played = [];

  @override
  void play(Sfx sfx) => played.add(sfx);
}

List<RebusPuzzle> _loadPuzzles() {
  // Tests run from the package directory (`flutter test` in
  // packages/module_rebus_ui); module_rebus is a sibling package.
  final file = File('../module_rebus/assets/puzzles/module01.json');
  return RebusPuzzle.listFromJsonString(file.readAsStringSync());
}

RebusPuzzle _byId(List<RebusPuzzle> puzzles, String id) => puzzles.firstWhere((p) => p.id == id);

/// The canonical digit at [ref] for [puzzle], derived from its canonical
/// solution strings.
int _canonicalDigitAt(RebusPuzzle puzzle, CellRef ref) {
  final String s;
  if (ref.row <= 3) {
    s = ref.slot <= 3 ? puzzle.rows[ref.row].nums[ref.slot] : puzzle.rows[ref.row].result;
  } else {
    s = ref.slot <= 3 ? puzzle.rows[ref.slot].result : puzzle.total;
  }
  return int.parse(s[ref.pos]);
}

Widget _wrapScreen({
  required String puzzleId,
  required SaveService saveService,
  required List<RebusPuzzle> puzzles,
  AudioService? audioService,
}) {
  return ProviderScope(
    overrides: [
      rebusPuzzlesProvider.overrideWith((ref) async => puzzles),
      saveServiceProvider.overrideWithValue(saveService),
      rebusL10nProvider.overrideWithValue(const _FakeRebusL10n()),
      if (audioService != null) rebusAudioServiceProvider.overrideWithValue(audioService),
    ],
    child: MaterialApp(
      home: PuzzleScreen(puzzleId: puzzleId),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  // Lets the (test-default-Android) orientation-lock future, the puzzle
  // FutureProvider, and the session's async persisted-state load all
  // resolve.
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Finder _cellContainer(CellRef ref) => find.byKey(ValueKey('cell_${ref.key}'));

/// Taps [ref], letting the popup digit menu fully open, then taps the
/// [digit] tile in it and lets the menu's pop/close settle. Mirrors the
/// real player flow that replaced the old on-screen digit pad.
Future<void> _enterDigitViaPopup(WidgetTester tester, CellRef ref, int digit) async {
  await tester.tap(_cellContainer(ref));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.byKey(ValueKey('digitMenu_$digit')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  late List<RebusPuzzle> puzzles;
  late Directory tempDir;
  late SaveService saveService;
  late _RecordingAudio recordingAudio;

  setUpAll(() {
    puzzles = _loadPuzzles();
  });

  setUp(() {
    // In widget tests un-mocked platform channels never respond, so the
    // SystemChrome orientation-lock future would never complete and the
    // screen would stay gated on its first-frame SizedBox forever.
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    tempDir = Directory.systemTemp.createTempSync('module_rebus_ui_test_');
    saveService = SaveService(() => tempDir);
    recordingAudio = _RecordingAudio();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('grid renders every cell for p01, and given cells show their digit', (tester) async {
    final puzzle = _byId(puzzles, 'p01');
    await tester.pumpWidget(_wrapScreen(puzzleId: 'p01', saveService: saveService, puzzles: puzzles));
    await _settle(tester);

    final grid = PlayerGrid.fromPuzzle(puzzle);
    final expectedCellCount = grid.orderedEditableCells.length + puzzle.givens.length;

    final cellFinder = find.byWidgetPredicate(
      (widget) => widget is Container && widget.key is ValueKey && (widget.key! as ValueKey).value.toString().startsWith('cell_'),
    );
    expect(cellFinder, findsNWidgets(expectedCellCount));

    for (final given in puzzle.givens) {
      final ref = CellRef(given.row, given.slot, given.pos);
      final digitText = find.descendant(of: _cellContainer(ref), matching: find.text('${given.digit}'));
      expect(digitText, findsOneWidget, reason: 'given cell $ref should display digit ${given.digit}');
    }
  });

  testWidgets('tapping a cell opens the digit menu; tapping a tile enters the digit and autosaves it',
      (tester) async {
    await tester.pumpWidget(_wrapScreen(puzzleId: 'p01', saveService: saveService, puzzles: puzzles));
    await _settle(tester);

    // Row 0 slot 0 pos 0 is editable in p01 (no given there).
    const ref = CellRef(0, 0, 0);
    await tester.tap(_cellContainer(ref));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('digitMenu_2')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('digitMenu_2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.descendant(of: _cellContainer(ref), matching: find.text('2')), findsOneWidget);

    // Let the coalesced (~300ms) autosave timer fire.
    await tester.pump(const Duration(milliseconds: 400));

    // The save pipeline mixes real dart:io awaits (which only complete
    // while runAsync runs the real event loop) with continuations queued
    // on the test's FakeAsync microtask queue (which only drain on pump).
    // Ratchet both until the write lands on disk.
    Map<String, dynamic>? saved;
    for (var i = 0; i < 50 && saved == null; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
      final data = (await tester.runAsync(() => saveService.load('module_rebus')))!;
      if (((data['puzzles'] as Map?)?['p01'] as Map?)?['cells'] != null) {
        saved = data;
      }
    }
    expect(saved, isNotNull, reason: 'autosave never landed on disk');
    final cells = ((saved!['puzzles'] as Map)['p01'] as Map)['cells'] as Map;
    expect(cells['0:0:0'], 2);
  });

  testWidgets('entering the full canonical solution of the tutorial example triggers the win dialog', (tester) async {
    final example = _byId(puzzles, 'example');
    await tester.pumpWidget(_wrapScreen(puzzleId: 'example', saveService: saveService, puzzles: puzzles));
    await _settle(tester);

    final grid = PlayerGrid.fromPuzzle(example);
    final ordered = grid.orderedEditableCells;
    expect(ordered, isNotEmpty);

    for (final ref in ordered) {
      final digit = _canonicalDigitAt(example, ref);
      await _enterDigitViaPopup(tester, ref, digit);
    }
    await tester.pump();
    await tester.pump();

    expect(find.text('You win!'), findsOneWidget);
  });

  testWidgets('pressing Check with a wrong digit flashes a violation highlight', (tester) async {
    final puzzle = _byId(puzzles, 'p01');
    await tester.pumpWidget(_wrapScreen(puzzleId: 'p01', saveService: saveService, puzzles: puzzles));
    await _settle(tester);

    // Fill row 0 entirely with the canonical values, except deliberately
    // corrupt the result's second digit (canonical "50" -> "51"), so
    // Check finds a rowEquation violation without needing the whole grid
    // complete.
    final rowZeroCells = PlayerGrid.fromPuzzle(puzzle).orderedEditableCells.where((c) => c.row == 0).toList();
    expect(rowZeroCells, isNotEmpty);

    for (final ref in rowZeroCells) {
      final canonical = _canonicalDigitAt(puzzle, ref);
      final digit = (ref.row == 0 && ref.slot == 4 && ref.pos == 1) ? (canonical + 1) % 10 : canonical;
      await _enterDigitViaPopup(tester, ref, digit);
    }

    await tester.tap(find.byKey(const ValueKey('checkButton')));
    await tester.pump();

    final context = tester.element(_cellContainer(rowZeroCells.first));
    final errorContainerColor = Theme.of(context).colorScheme.errorContainer;
    final container = tester.widget<Container>(_cellContainer(rowZeroCells.first));
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, errorContainerColor);
  });

  testWidgets('tapping a cell then a digit menu tile plays tap then place', (tester) async {
    await tester.pumpWidget(
      _wrapScreen(puzzleId: 'p01', saveService: saveService, puzzles: puzzles, audioService: recordingAudio),
    );
    await _settle(tester);

    // Row 0 slot 0 pos 0 is editable in p01 (no given there).
    const ref = CellRef(0, 0, 0);
    await _enterDigitViaPopup(tester, ref, 2);

    expect(recordingAudio.played, [Sfx.tap, Sfx.place]);
  });

  testWidgets('grid columns align: slot 0 groups share left and right edges across rows', (tester) async {
    await tester.pumpWidget(_wrapScreen(puzzleId: 'p01', saveService: saveService, puzzles: puzzles));
    await _settle(tester);

    final equationRowLeft = tester.getTopLeft(_cellContainer(const CellRef(0, 0, 0))).dx;
    final summaryRowLeft = tester.getTopLeft(_cellContainer(const CellRef(4, 0, 0))).dx;

    expect(summaryRowLeft, closeTo(equationRowLeft, 0.5));

    // Right alignment across different-width groups in the same slot:
    // p01 row 0 slot 0 has 2 boxes ("27"), row 1 slot 0 has 1 box ("6").
    final wideRight = tester.getTopRight(_cellContainer(const CellRef(0, 0, 1))).dx;
    final narrowRight = tester.getTopRight(_cellContainer(const CellRef(1, 0, 0))).dx;
    expect(narrowRight, closeTo(wideRight, 0.5));
  });

  testWidgets('right-clicking a filled cell clears it', (tester) async {
    await tester.pumpWidget(_wrapScreen(puzzleId: 'p01', saveService: saveService, puzzles: puzzles));
    await _settle(tester);

    // Row 0 slot 0 pos 0 is editable in p01 (no given there).
    const ref = CellRef(0, 0, 0);
    await _enterDigitViaPopup(tester, ref, 2);
    expect(find.descendant(of: _cellContainer(ref), matching: find.text('2')), findsOneWidget);

    await tester.tap(_cellContainer(ref), buttons: kSecondaryMouseButton);
    await tester.pump();

    expect(find.descendant(of: _cellContainer(ref), matching: find.text('2')), findsNothing);
  });
}
