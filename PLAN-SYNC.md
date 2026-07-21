# Progress Sync — `updatedAt` + Export/Import Bundle — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Status: NOT STARTED.** Written 2026-07-21 for a future session. Background analysis lives in `SYNC-PUZZLEBOOK-PROGRESS.txt` at the repo root — read it first.

**Goal:** Let a player move their puzzle progress between the Windows build and the Android build by exporting one JSON bundle file from Settings and importing it on the other device, merging non-destructively.

**Architecture:** All bundle logic is pure Dart in `packages/core` (no Flutter import), layered on the existing `SaveService`: a bundle model, a pure merge ladder, and a `ProgressBundleService` that reads/writes module namespaces through `SaveService`. The Flutter side is a thin `BundleTransfer` seam (file save/pick dialogs) plus two tiles on the settings screen. Per-puzzle entries gain an `updatedAt` epoch-ms field so the merge can break ties.

**Tech Stack:** Dart 3.12 / Flutter, Riverpod 3, `package:test` for core, `flutter_test` for UI, `file_picker` for platform file dialogs.

## Global Constraints

- Flutter SDK: `F:\____IL_AI\flutter-sdk\flutter\bin\flutter.bat`; Dart: `F:\____IL_AI\flutter-sdk\flutter\bin\dart.bat`. All commands below assume these.
- Working directory for all commands: `F:\____IL_AI\PUZZLES\app`.
- `packages/core` MUST NOT import Flutter. It is tested with `dart test`, not `flutter test`.
- **DO NOT bump `SaveService.currentSchemaVersion`.** It is `1` (`packages/core/lib/src/save_service.dart:34`), and `load()` quarantines any file whose `schemaVersion` exceeds the running build's (`save_service.dart:92-100`). `updatedAt` is added *inside* `data`, which older builds simply ignore.
- All writes go through `SaveService.save()` so the atomic temp-write+rename and the per-namespace write queue still apply. Never write save files directly.
- **`settings` namespace is never exported or imported.** Language, sound and theme are per-device preferences. Export enumerates module namespaces only, via `ModuleRegistry`.
- ARB: `app/lib/l10n/app_ru.arb` is the TEMPLATE. Add keys there first, then `app_en.arb` and `app_de.arb`. `app/test/arb_parity_test.dart` must stay green.
- Commit at the end of every task. Four milestones (M-a = Task 1, M-b = Tasks 2-4, M-c = Tasks 5-7, M-d = Task 8), user approval between milestones — matches the M01/M02/M03 convention.

## File Structure

**Create (core, pure Dart):**
- `packages/core/lib/src/progress_bundle.dart` — the `ProgressBundle` model, JSON encode/decode, `BundleFormatException`.
- `packages/core/lib/src/progress_merge.dart` — pure merge functions. No I/O, no dependencies beyond `dart:core`.
- `packages/core/lib/src/progress_bundle_service.dart` — `ProgressBundleService`, `ImportReport`, `NamespaceCounts`.
- `packages/core/test/progress_bundle_test.dart`
- `packages/core/test/progress_merge_test.dart`
- `packages/core/test/progress_bundle_service_test.dart`

**Create (app, Flutter):**
- `app/lib/bundle_transfer.dart` — the `BundleTransfer` seam + its `file_picker` implementation.
- `app/test/settings_sync_test.dart`

**Modify:**
- `packages/core/lib/puzzle_core.dart` — add three exports.
- `packages/module_rebus_ui/lib/src/puzzle_session_controller.dart:410-421` — `_buildEntryPayload`.
- `packages/module_digit_rebus_ui/lib/src/digit_rebus_session_controller.dart:408-419` — `_buildEntryPayload`.
- `packages/module_domino_ui/lib/src/domino_session_controller.dart:276-287` — `_buildEntryPayload`.
- `app/pubspec.yaml` — add `file_picker`.
- `app/lib/providers.dart` — add `progressBundleServiceProvider`, `bundleTransferProvider`.
- `app/lib/main.dart:38-49` — override the two new providers.
- `app/lib/screens/settings_screen.dart:72` — append the sync section.
- `app/lib/l10n/app_ru.arb`, `app_en.arb`, `app_de.arb` — new keys.

## Bundle Format (v1)

```json
{
  "bundleVersion": 1,
  "exportedAt": "2026-07-21T14:03:11.482",
  "namespaces": {
    "module_rebus":       { "puzzles": { "p01": { } }, "tutorial": { } },
    "module_digit_rebus": { "puzzles": { } },
    "module_domino":      { "puzzles": { } }
  }
}
```

`namespaces` values are the *whole* `data` map of each namespace file, verbatim.

---

### Task 1: Add `updatedAt` to per-puzzle save entries

**Files:**
- Modify: `packages/module_rebus_ui/lib/src/puzzle_session_controller.dart:410-421`
- Modify: `packages/module_digit_rebus_ui/lib/src/digit_rebus_session_controller.dart:408-419`
- Modify: `packages/module_domino_ui/lib/src/domino_session_controller.dart:276-287`
- Test: `packages/module_domino_ui/test/domino_session_controller_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: every per-puzzle save entry now carries `'updatedAt': <int epoch ms>`. Task 3's merge ladder reads it. The key is always written (never conditional), so any entry saved by this build or later has it; entries written by older builds do not, and the merge must tolerate its absence.

- [ ] **Step 1: Write the failing test**

Append to `packages/module_domino_ui/test/domino_session_controller_test.dart`, inside the existing top-level `main()` group structure (the file already sets up `tempDir` and `saveService` in `setUp`):

```dart
  test('persisted entry carries an updatedAt epoch-ms stamp', () async {
    final before = DateTime.now().millisecondsSinceEpoch;
    final container = ProviderContainer(
      overrides: [dominoSaveServiceProvider.overrideWithValue(saveService)],
    );
    addTearDown(container.dispose);

    final controller = container.read(dominoSessionControllerProvider('p01').notifier);
    await controller.ensureLoaded();
    controller.selectCell(0, 0);
    controller.selectCell(0, 1);
    await controller.flushForTest();

    final data = await saveService.load(dominoSaveNamespace);
    final entry = (data['puzzles'] as Map)['p01'] as Map;
    expect(entry['updatedAt'], isA<int>());
    expect(entry['updatedAt'] as int, greaterThanOrEqualTo(before));
  });
```

If the controller's public method names differ from `ensureLoaded` / `selectCell` / `flushForTest`, open the file and use the names it actually exposes — the assertion on `entry['updatedAt']` is the part that matters. If no flush hook exists, drive the save the way the neighbouring tests in that file already do.

- [ ] **Step 2: Run the test to verify it fails**

```
F:\____IL_AI\flutter-sdk\flutter\bin\flutter.bat test packages/module_domino_ui/test/domino_session_controller_test.dart
```

Expected: FAIL — `Expected: <Instance of 'int'> Actual: <null>`.

- [ ] **Step 3: Add the field in all three controllers**

In `packages/module_domino_ui/lib/src/domino_session_controller.dart`, `_buildEntryPayload` becomes:

```dart
  Map<String, dynamic> _buildEntryPayload() {
    final placedJson = state.replayInProgress
        ? (_solvedSnapshotJson ?? const <List<List<int>>>[])
        : state.board.toJson();
    return <String, dynamic>{
      'placed': placedJson,
      'elapsedMs': state.elapsedMs,
      'solved': state.solved,
      // Wall-clock stamp of this write. Read by ProgressBundleService's
      // merge ladder to break ties between two devices' copies of the
      // same puzzle. Absent on entries written before this field existed;
      // the merge tolerates null.
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      if (state.solvedAt != null) 'solvedAt': state.solvedAt,
      if (state.firstSolveElapsedMs != null) 'firstSolveElapsedMs': state.firstSolveElapsedMs,
    };
  }
```

In `packages/module_rebus_ui/lib/src/puzzle_session_controller.dart`:

```dart
  Map<String, dynamic> _buildEntryPayload() {
    final cellsJson = state.replayInProgress ? (_solvedSnapshotJson ?? const {}) : state.grid.toJson();
    return <String, dynamic>{
      'cells': cellsJson,
      'elapsedMs': state.elapsedMs,
      'checks': state.checkCount,
      'solved': state.solved,
      // See the comment on the domino controller's copy of this field.
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      if (state.solvedAt != null) 'solvedAt': state.solvedAt,
      if (state.firstSolveElapsedMs != null) 'firstSolveElapsedMs': state.firstSolveElapsedMs,
      if (state.firstSolveChecks != null) 'firstSolveChecks': state.firstSolveChecks,
    };
  }
```

In `packages/module_digit_rebus_ui/lib/src/digit_rebus_session_controller.dart`, make the identical change — that file's `_buildEntryPayload` has the same body as the rebus one.

- [ ] **Step 4: Run the full suite**

```
F:\____IL_AI\flutter-sdk\flutter\bin\flutter.bat test
F:\____IL_AI\flutter-sdk\flutter\bin\flutter.bat analyze
```

Expected: all tests PASS, analyze clean. A grep at plan-writing time found **no** existing test asserting an exact equality on a saved entry map, so nothing should break. If one does break because it compares a whole entry map with `equals({...})`, change that assertion to `containsPair(...)` for the fields it cares about rather than adding `updatedAt` to the expected literal (the value is non-deterministic).

- [ ] **Step 5: Commit**

```bash
git add packages/module_rebus_ui packages/module_digit_rebus_ui packages/module_domino_ui
git commit -m "feat(core): stamp updatedAt on per-puzzle save entries"
```

---

### Task 2: Bundle model — encode, decode, validate

**Files:**
- Create: `packages/core/lib/src/progress_bundle.dart`
- Modify: `packages/core/lib/puzzle_core.dart`
- Test: `packages/core/test/progress_bundle_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `class ProgressBundle` with `static const int currentBundleVersion = 1`, fields `int bundleVersion`, `String exportedAt`, `Map<String, Map<String, dynamic>> namespaces`; constructor `ProgressBundle({required this.bundleVersion, required this.exportedAt, required this.namespaces})`; `String encode()`; `static ProgressBundle decode(String jsonText)` which throws `BundleFormatException`.
  - `class BundleFormatException implements Exception` with `final String reason` and `final bool isVersionTooNew`.
  Task 4 calls `ProgressBundle.decode` and `bundle.encode`.

- [ ] **Step 1: Write the failing tests**

Create `packages/core/test/progress_bundle_test.dart`:

```dart
import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  test('encode then decode round-trips namespaces', () {
    final bundle = ProgressBundle(
      bundleVersion: ProgressBundle.currentBundleVersion,
      exportedAt: '2026-07-21T14:03:11.482',
      namespaces: {
        'module_rebus': {
          'puzzles': {
            'p01': {'solved': true, 'elapsedMs': 1200, 'updatedAt': 42},
          },
        },
      },
    );

    final decoded = ProgressBundle.decode(bundle.encode());

    expect(decoded.bundleVersion, 1);
    expect(decoded.exportedAt, '2026-07-21T14:03:11.482');
    expect(decoded.namespaces['module_rebus']!['puzzles'], {
      'p01': {'solved': true, 'elapsedMs': 1200, 'updatedAt': 42},
    });
  });

  test('decode rejects a bundle from a newer app', () {
    const text = '{"bundleVersion":2,"exportedAt":"x","namespaces":{}}';
    expect(
      () => ProgressBundle.decode(text),
      throwsA(isA<BundleFormatException>().having((e) => e.isVersionTooNew, 'isVersionTooNew', true)),
    );
  });

  test('decode rejects unparseable JSON', () {
    expect(() => ProgressBundle.decode('not json'), throwsA(isA<BundleFormatException>()));
  });

  test('decode rejects JSON that is not an object', () {
    expect(() => ProgressBundle.decode('[1,2,3]'), throwsA(isA<BundleFormatException>()));
  });

  test('decode rejects a missing or non-int bundleVersion', () {
    expect(
      () => ProgressBundle.decode('{"exportedAt":"x","namespaces":{}}'),
      throwsA(isA<BundleFormatException>()),
    );
  });

  test('decode rejects a namespaces value that is not an object', () {
    expect(
      () => ProgressBundle.decode('{"bundleVersion":1,"exportedAt":"x","namespaces":{"a":5}}'),
      throwsA(isA<BundleFormatException>()),
    );
  });

  test('decode tolerates a missing namespaces key as empty', () {
    final decoded = ProgressBundle.decode('{"bundleVersion":1,"exportedAt":"x"}');
    expect(decoded.namespaces, isEmpty);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

```
F:\____IL_AI\flutter-sdk\flutter\bin\dart.bat test packages/core/test/progress_bundle_test.dart
```

Expected: FAIL to compile — `Undefined name 'ProgressBundle'`.

- [ ] **Step 3: Implement the model**

Create `packages/core/lib/src/progress_bundle.dart`:

```dart
import 'dart:convert';

/// Raised when a bundle's text cannot be understood.
///
/// [isVersionTooNew] distinguishes "this file was written by a newer build
/// of the app" (the user should update, and the data is probably fine) from
/// "this file is not a bundle" (the user picked the wrong file).
class BundleFormatException implements Exception {
  /// Human-readable cause, for logs. Not shown to the player directly —
  /// the UI picks a localized message off [isVersionTooNew].
  final String reason;

  /// Whether the failure was specifically a `bundleVersion` newer than
  /// [ProgressBundle.currentBundleVersion].
  final bool isVersionTooNew;

  /// Creates a format exception.
  const BundleFormatException(this.reason, {this.isVersionTooNew = false});

  @override
  String toString() => 'BundleFormatException: $reason';
}

/// A portable snapshot of every puzzle module's save data, suitable for
/// carrying between installs on different devices.
///
/// Deliberately excludes the `settings` namespace: language, sound and
/// theme are per-device preferences, not progress.
class ProgressBundle {
  /// Bundle format version written by this build. [decode] rejects any
  /// bundle claiming a higher version.
  static const int currentBundleVersion = 1;

  /// The `bundleVersion` this instance carries.
  final int bundleVersion;

  /// ISO-8601 local timestamp of when the bundle was produced. Shown to
  /// the player in the import confirmation dialog; never used for merge
  /// decisions.
  final String exportedAt;

  /// Save-namespace name -> that namespace's whole `data` map.
  final Map<String, Map<String, dynamic>> namespaces;

  /// Creates a bundle.
  const ProgressBundle({
    required this.bundleVersion,
    required this.exportedAt,
    required this.namespaces,
  });

  /// Serializes this bundle to indented JSON (indented so a curious player
  /// opening the file in a text editor sees something readable).
  String encode() {
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'bundleVersion': bundleVersion,
      'exportedAt': exportedAt,
      'namespaces': namespaces,
    });
  }

  /// Parses [jsonText].
  ///
  /// Throws [BundleFormatException] if the text is not JSON, is not a JSON
  /// object, lacks an integer `bundleVersion`, claims a version newer than
  /// [currentBundleVersion], or has a `namespaces` entry that is not an
  /// object. A missing `namespaces` key is treated as empty.
  static ProgressBundle decode(String jsonText) {
    Object? decoded;
    try {
      decoded = jsonDecode(jsonText);
    } catch (e) {
      throw BundleFormatException('unparseable JSON: $e');
    }

    if (decoded is! Map) {
      throw const BundleFormatException('top-level JSON value is not an object');
    }

    final version = decoded['bundleVersion'];
    if (version is! int) {
      throw BundleFormatException('missing or non-integer bundleVersion: $version');
    }
    if (version > currentBundleVersion) {
      throw BundleFormatException(
        'bundleVersion $version is newer than supported $currentBundleVersion',
        isVersionTooNew: true,
      );
    }

    final rawExportedAt = decoded['exportedAt'];
    final exportedAt = rawExportedAt is String ? rawExportedAt : '';

    final rawNamespaces = decoded['namespaces'];
    final namespaces = <String, Map<String, dynamic>>{};
    if (rawNamespaces is Map) {
      for (final entry in rawNamespaces.entries) {
        final value = entry.value;
        if (value is! Map) {
          throw BundleFormatException('namespace "${entry.key}" is not an object');
        }
        namespaces['${entry.key}'] = Map<String, dynamic>.from(value);
      }
    } else if (rawNamespaces != null) {
      throw const BundleFormatException('namespaces is not an object');
    }

    return ProgressBundle(
      bundleVersion: version,
      exportedAt: exportedAt,
      namespaces: namespaces,
    );
  }
}
```

Add to `packages/core/lib/puzzle_core.dart`, keeping the export list alphabetical:

```dart
export 'src/progress_bundle.dart';
```

- [ ] **Step 4: Run to verify it passes**

```
F:\____IL_AI\flutter-sdk\flutter\bin\dart.bat test packages/core/test/progress_bundle_test.dart
```

Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git add packages/core/lib/src/progress_bundle.dart packages/core/lib/puzzle_core.dart packages/core/test/progress_bundle_test.dart
git commit -m "feat(core): add ProgressBundle model with versioned JSON codec"
```

---

### Task 3: The merge ladder (pure functions)

**Files:**
- Create: `packages/core/lib/src/progress_merge.dart`
- Modify: `packages/core/lib/puzzle_core.dart`
- Test: `packages/core/test/progress_merge_test.dart`

**Interfaces:**
- Consumes: the `updatedAt` field from Task 1.
- Produces:
  - `Map<String, dynamic> mergePuzzleEntry(Map<String, dynamic> local, Map<String, dynamic> incoming)` — returns whichever *whole* entry wins.
  - `Map<String, dynamic>? mergeTutorialBlock(Map<String, dynamic>? local, Map<String, dynamic>? incoming)`
  - `class NamespaceCounts { final int added; final int updated; final int unchanged; }`
  - `class NamespaceMergeResult { final Map<String, dynamic> data; final NamespaceCounts counts; }`
  - `NamespaceMergeResult mergeNamespaceData(Map<String, dynamic> local, Map<String, dynamic> incoming)`
  Task 4 calls `mergeNamespaceData` only.

**Why whole-entry, not field-wise:** an entry holds a board state (`cells` / `placed`) alongside its timing. Blending fields from two devices would pair one device's board with the other's clock. The ladder therefore picks a winner and takes it entire.

**The ladder**, applied in order, first rung that discriminates wins:

1. `solved == true` beats `solved != true`.
2. Both solved → smaller `firstSolveElapsedMs` wins (a non-null value beats null).
3. Still tied → earlier `solvedAt` wins (a non-null value beats null; both are ISO-8601 strings compared with `String.compareTo`).
4. Neither solved (or still tied) → larger `updatedAt` wins (a non-null int beats null).
5. Still tied → larger `elapsedMs` wins.
6. Dead tie → keep `local` (stability: importing the same bundle twice is a no-op).

- [ ] **Step 1: Write the failing tests**

Create `packages/core/test/progress_merge_test.dart`:

```dart
import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> entry({
  bool solved = false,
  int? firstSolveElapsedMs,
  String? solvedAt,
  int? updatedAt,
  int elapsedMs = 0,
  String tag = 'x',
}) {
  return <String, dynamic>{
    'solved': solved,
    'elapsedMs': elapsedMs,
    'tag': tag,
    if (firstSolveElapsedMs != null) 'firstSolveElapsedMs': firstSolveElapsedMs,
    if (solvedAt != null) 'solvedAt': solvedAt,
    if (updatedAt != null) 'updatedAt': updatedAt,
  };
}

void main() {
  group('mergePuzzleEntry ladder', () {
    test('rung 1: solved beats unsolved regardless of timestamps', () {
      final local = entry(solved: false, updatedAt: 9999, tag: 'local');
      final incoming = entry(solved: true, updatedAt: 1, tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'incoming');
      expect(mergePuzzleEntry(incoming, local)['tag'], 'incoming');
    });

    test('rung 2: both solved, smaller firstSolveElapsedMs wins', () {
      final local = entry(solved: true, firstSolveElapsedMs: 5000, tag: 'local');
      final incoming = entry(solved: true, firstSolveElapsedMs: 3000, tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'incoming');
    });

    test('rung 2: a present firstSolveElapsedMs beats a missing one', () {
      final local = entry(solved: true, tag: 'local');
      final incoming = entry(solved: true, firstSolveElapsedMs: 9999999, tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'incoming');
    });

    test('rung 3: equal solve times, earlier solvedAt wins', () {
      final local = entry(
          solved: true, firstSolveElapsedMs: 1000, solvedAt: '2026-07-20T10:00:00.000', tag: 'local');
      final incoming = entry(
          solved: true, firstSolveElapsedMs: 1000, solvedAt: '2026-07-19T10:00:00.000', tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'incoming');
    });

    test('rung 4: neither solved, larger updatedAt wins', () {
      final local = entry(updatedAt: 100, tag: 'local');
      final incoming = entry(updatedAt: 200, tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'incoming');
    });

    test('rung 4: a present updatedAt beats a legacy entry without one', () {
      final local = entry(tag: 'local');
      final incoming = entry(updatedAt: 1, tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'incoming');
    });

    test('rung 5: no updatedAt on either side, larger elapsedMs wins', () {
      final local = entry(elapsedMs: 10, tag: 'local');
      final incoming = entry(elapsedMs: 20, tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'incoming');
    });

    test('rung 6: a dead tie keeps local', () {
      final local = entry(updatedAt: 5, elapsedMs: 7, tag: 'local');
      final incoming = entry(updatedAt: 5, elapsedMs: 7, tag: 'incoming');
      expect(mergePuzzleEntry(local, incoming)['tag'], 'local');
    });

    test('returns the winning entry whole, never a field-wise blend', () {
      final local = entry(solved: false, elapsedMs: 999, tag: 'local');
      final incoming = entry(solved: true, elapsedMs: 1, tag: 'incoming');
      final merged = mergePuzzleEntry(local, incoming);
      expect(merged['elapsedMs'], 1);
      expect(merged['tag'], 'incoming');
    });
  });

  group('mergeTutorialBlock', () {
    test('completed beats not completed', () {
      final merged = mergeTutorialBlock(
        {'completed': false},
        {'completed': true, 'completedAt': '2026-01-01T00:00:00.000'},
      );
      expect(merged!['completed'], true);
    });

    test('both completed keeps the earlier completedAt', () {
      final merged = mergeTutorialBlock(
        {'completed': true, 'completedAt': '2026-05-05T00:00:00.000'},
        {'completed': true, 'completedAt': '2026-01-01T00:00:00.000'},
      );
      expect(merged!['completedAt'], '2026-01-01T00:00:00.000');
    });

    test('a null side yields the other side', () {
      expect(mergeTutorialBlock(null, {'completed': true})!['completed'], true);
      expect(mergeTutorialBlock({'completed': true}, null)!['completed'], true);
      expect(mergeTutorialBlock(null, null), isNull);
    });
  });

  group('mergeNamespaceData', () {
    test('unions puzzles from both sides and counts them', () {
      final result = mergeNamespaceData(
        {
          'puzzles': {
            'p01': entry(solved: true, firstSolveElapsedMs: 100, tag: 'local'),
            'p02': entry(updatedAt: 1, tag: 'local'),
          },
        },
        {
          'puzzles': {
            'p02': entry(updatedAt: 2, tag: 'incoming'),
            'p03': entry(updatedAt: 5, tag: 'incoming'),
          },
        },
      );

      final puzzles = result.data['puzzles'] as Map<String, dynamic>;
      expect(puzzles.keys.toSet(), {'p01', 'p02', 'p03'});
      expect((puzzles['p01'] as Map)['tag'], 'local');
      expect((puzzles['p02'] as Map)['tag'], 'incoming');
      expect((puzzles['p03'] as Map)['tag'], 'incoming');
      expect(result.counts.added, 1);
      expect(result.counts.updated, 1);
      expect(result.counts.unchanged, 1);
    });

    test('importing an identical namespace changes nothing', () {
      final local = {
        'puzzles': {'p01': entry(updatedAt: 7, tag: 'local')},
      };
      final result = mergeNamespaceData(local, Map<String, dynamic>.from(local));
      expect(result.counts.added, 0);
      expect(result.counts.updated, 0);
      expect(result.counts.unchanged, 1);
    });

    test('preserves the local tutorial block and unknown top-level keys', () {
      final result = mergeNamespaceData(
        {
          'puzzles': <String, dynamic>{},
          'tutorial': {'completed': true, 'completedAt': '2026-01-01T00:00:00.000'},
          'someFutureKey': 'keep me',
        },
        {'puzzles': <String, dynamic>{}},
      );
      expect((result.data['tutorial'] as Map)['completed'], true);
      expect(result.data['someFutureKey'], 'keep me');
    });

    test('takes an unknown top-level key that only the incoming side has', () {
      final result = mergeNamespaceData(
        {'puzzles': <String, dynamic>{}},
        {'puzzles': <String, dynamic>{}, 'futureKey': 'from other device'},
      );
      expect(result.data['futureKey'], 'from other device');
    });

    test('tolerates a missing or malformed puzzles map on either side', () {
      final result = mergeNamespaceData({}, {'puzzles': 'not a map'});
      expect(result.data['puzzles'], <String, dynamic>{});
      expect(result.counts.added, 0);
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

```
F:\____IL_AI\flutter-sdk\flutter\bin\dart.bat test packages/core/test/progress_merge_test.dart
```

Expected: FAIL to compile — `Undefined name 'mergePuzzleEntry'`.

- [ ] **Step 3: Implement the merge**

Create `packages/core/lib/src/progress_merge.dart`:

```dart
/// Pure, I/O-free merge rules for combining two devices' copies of the same
/// save namespace.
///
/// The guiding property is that merging never loses a better result: for a
/// puzzle present on both sides the winner is the copy representing more
/// progress, judged by a fixed ladder (see [mergePuzzleEntry]). Merging is
/// idempotent — importing the same bundle twice is a no-op.
library;

/// How many puzzle entries a namespace merge created, replaced, or left
/// alone.
class NamespaceCounts {
  /// Puzzles present only in the incoming data.
  final int added;

  /// Puzzles present on both sides where the incoming copy won.
  final int updated;

  /// Puzzles the merge left as they were.
  final int unchanged;

  /// Creates a count triple.
  const NamespaceCounts({this.added = 0, this.updated = 0, this.unchanged = 0});

  /// Sums two count triples, so a caller can total across namespaces.
  NamespaceCounts operator +(NamespaceCounts other) => NamespaceCounts(
        added: added + other.added,
        updated: updated + other.updated,
        unchanged: unchanged + other.unchanged,
      );
}

/// The merged namespace data plus what the merge did.
class NamespaceMergeResult {
  /// The merged `data` map, ready to hand to `SaveService.save`.
  final Map<String, dynamic> data;

  /// What changed.
  final NamespaceCounts counts;

  /// Creates a result.
  const NamespaceMergeResult(this.data, this.counts);
}

int? _asInt(Object? v) => v is num ? v.toInt() : null;

String? _asString(Object? v) => v is String ? v : null;

bool _isSolved(Map<String, dynamic> e) => e['solved'] == true;

/// Compares [local] and [incoming] on one rung. Returns a negative number if
/// local wins, positive if incoming wins, 0 if the rung cannot decide.
///
/// [lower] selects whether a smaller value is better (solve times) or a
/// larger one (timestamps, elapsed time). A present value always beats an
/// absent one.
int _rungInt(int? local, int? incoming, {required bool lower}) {
  if (local == null && incoming == null) return 0;
  if (local == null) return 1;
  if (incoming == null) return -1;
  if (local == incoming) return 0;
  final localBetter = lower ? local < incoming : local > incoming;
  return localBetter ? -1 : 1;
}

int _rungEarlierString(String? local, String? incoming) {
  if (local == null && incoming == null) return 0;
  if (local == null) return 1;
  if (incoming == null) return -1;
  final cmp = local.compareTo(incoming);
  if (cmp == 0) return 0;
  return cmp < 0 ? -1 : 1;
}

/// Picks the winning copy of a single puzzle's save entry.
///
/// Returns the winning map *whole* — never a field-wise blend, because an
/// entry's board state and its timings must stay consistent with each other.
/// Ties resolve to [local], which makes re-importing the same bundle a no-op.
Map<String, dynamic> mergePuzzleEntry(
  Map<String, dynamic> local,
  Map<String, dynamic> incoming,
) {
  // Rung 1: solved beats unsolved.
  final localSolved = _isSolved(local);
  final incomingSolved = _isSolved(incoming);
  if (localSolved != incomingSolved) {
    return localSolved ? local : incoming;
  }

  if (localSolved) {
    // Rung 2: the better first-solve time.
    final byFirstSolve = _rungInt(
      _asInt(local['firstSolveElapsedMs']),
      _asInt(incoming['firstSolveElapsedMs']),
      lower: true,
    );
    if (byFirstSolve != 0) return byFirstSolve < 0 ? local : incoming;

    // Rung 3: whoever solved it first.
    final bySolvedAt = _rungEarlierString(
      _asString(local['solvedAt']),
      _asString(incoming['solvedAt']),
    );
    if (bySolvedAt != 0) return bySolvedAt < 0 ? local : incoming;
  }

  // Rung 4: the more recent write. Entries saved by builds older than the
  // updatedAt field have none, and lose to any entry that does.
  final byUpdatedAt = _rungInt(
    _asInt(local['updatedAt']),
    _asInt(incoming['updatedAt']),
    lower: false,
  );
  if (byUpdatedAt != 0) return byUpdatedAt < 0 ? local : incoming;

  // Rung 5: the copy with more time invested.
  final byElapsed = _rungInt(
    _asInt(local['elapsedMs']),
    _asInt(incoming['elapsedMs']),
    lower: false,
  );
  if (byElapsed != 0) return byElapsed < 0 ? local : incoming;

  // Rung 6: dead tie — keep local.
  return local;
}

/// Merges the `tutorial` block. Completed beats not-completed; if both are
/// completed the earlier `completedAt` is kept, so the record reflects when
/// the player actually first finished it.
Map<String, dynamic>? mergeTutorialBlock(
  Map<String, dynamic>? local,
  Map<String, dynamic>? incoming,
) {
  if (local == null) return incoming;
  if (incoming == null) return local;

  final localDone = local['completed'] == true;
  final incomingDone = incoming['completed'] == true;
  if (localDone != incomingDone) return localDone ? local : incoming;
  if (!localDone) return local;

  final cmp = _rungEarlierString(
    _asString(local['completedAt']),
    _asString(incoming['completedAt']),
  );
  return cmp <= 0 ? local : incoming;
}

Map<String, dynamic> _puzzlesOf(Map<String, dynamic> data) {
  final raw = data['puzzles'];
  return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
}

/// Merges one namespace's whole `data` map.
///
/// The `puzzles` maps are unioned entry-by-entry through [mergePuzzleEntry];
/// the `tutorial` block through [mergeTutorialBlock]; any other top-level key
/// is carried over, with the local value winning a conflict (the app cannot
/// know how to merge a key it does not understand, and the local device's
/// copy is the one the player is standing in front of).
NamespaceMergeResult mergeNamespaceData(
  Map<String, dynamic> local,
  Map<String, dynamic> incoming,
) {
  final merged = Map<String, dynamic>.from(local);

  for (final entry in incoming.entries) {
    if (entry.key == 'puzzles' || entry.key == 'tutorial') continue;
    if (!merged.containsKey(entry.key)) merged[entry.key] = entry.value;
  }

  final localPuzzles = _puzzlesOf(local);
  final incomingPuzzles = _puzzlesOf(incoming);
  final mergedPuzzles = Map<String, dynamic>.from(localPuzzles);

  var added = 0;
  var updated = 0;
  var unchanged = 0;

  for (final id in localPuzzles.keys) {
    if (!incomingPuzzles.containsKey(id)) unchanged++;
  }

  for (final entry in incomingPuzzles.entries) {
    final incomingEntry = entry.value;
    if (incomingEntry is! Map) continue;
    final incomingMap = Map<String, dynamic>.from(incomingEntry);

    final localEntry = localPuzzles[entry.key];
    if (localEntry is! Map) {
      mergedPuzzles[entry.key] = incomingMap;
      added++;
      continue;
    }

    final localMap = Map<String, dynamic>.from(localEntry);
    final winner = mergePuzzleEntry(localMap, incomingMap);
    mergedPuzzles[entry.key] = winner;
    if (identical(winner, localMap)) {
      unchanged++;
    } else {
      updated++;
    }
  }

  merged['puzzles'] = mergedPuzzles;

  final localTutorial = local['tutorial'];
  final incomingTutorial = incoming['tutorial'];
  final mergedTutorial = mergeTutorialBlock(
    localTutorial is Map ? Map<String, dynamic>.from(localTutorial) : null,
    incomingTutorial is Map ? Map<String, dynamic>.from(incomingTutorial) : null,
  );
  if (mergedTutorial != null) merged['tutorial'] = mergedTutorial;

  return NamespaceMergeResult(
    merged,
    NamespaceCounts(added: added, updated: updated, unchanged: unchanged),
  );
}
```

Add to `packages/core/lib/puzzle_core.dart`:

```dart
export 'src/progress_merge.dart';
```

- [ ] **Step 4: Run to verify it passes**

```
F:\____IL_AI\flutter-sdk\flutter\bin\dart.bat test packages/core/test/progress_merge_test.dart
```

Expected: PASS, 17 tests.

- [ ] **Step 5: Commit**

```bash
git add packages/core/lib/src/progress_merge.dart packages/core/lib/puzzle_core.dart packages/core/test/progress_merge_test.dart
git commit -m "feat(core): add non-destructive progress merge ladder"
```

---

### Task 4: `ProgressBundleService` — export and import over `SaveService`

**Files:**
- Create: `packages/core/lib/src/progress_bundle_service.dart`
- Modify: `packages/core/lib/puzzle_core.dart`
- Test: `packages/core/test/progress_bundle_service_test.dart`

**Interfaces:**
- Consumes: `ProgressBundle`, `BundleFormatException` (Task 2); `mergeNamespaceData`, `NamespaceCounts` (Task 3); `SaveService.load` / `SaveService.save`.
- Produces:
  - `class ProgressBundleService` — constructor `ProgressBundleService(SaveService saveService, List<String> exportNamespaces)`; `Future<String> exportJson()`; `Future<ImportReport> importJson(String jsonText)`.
  - `class ImportReport` — `final bool ok`, `final ImportError? error`, `final NamespaceCounts counts`, `final String exportedAt`.
  - `enum ImportError { badFormat, versionTooNew }`.
  Task 7's settings screen calls `exportJson()` and `importJson()` and reads `report.ok`, `report.error`, `report.counts.added`, `report.counts.updated`.

**Asymmetry, on purpose:** *export* enumerates only the namespaces it is given (the registered modules, so `settings` can never leak in). *Import* applies every namespace present in the bundle, including ones this build does not know — a bundle from a newer build carrying `module_04` writes that file, and a later app version finds the data waiting. Since `SaveService` is namespace-agnostic this costs nothing and prevents silent data loss.

- [ ] **Step 1: Write the failing tests**

Create `packages/core/test/progress_bundle_service_test.dart`:

```dart
import 'dart:io';

import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late SaveService saveService;
  late ProgressBundleService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('progress_bundle_service_test_');
    saveService = SaveService(() => tempDir);
    service = ProgressBundleService(saveService, const ['module_rebus', 'module_domino']);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('export includes every listed namespace and excludes settings', () async {
    await saveService.save('module_rebus', {
      'puzzles': {
        'p01': {'solved': true, 'elapsedMs': 500, 'updatedAt': 10},
      },
    });
    await saveService.save('settings', {'language': 'ru', 'soundOn': false});

    final bundle = ProgressBundle.decode(await service.exportJson());

    expect(bundle.bundleVersion, ProgressBundle.currentBundleVersion);
    expect(bundle.namespaces.keys.toSet(), {'module_rebus', 'module_domino'});
    expect(bundle.namespaces.containsKey('settings'), isFalse);
    expect((bundle.namespaces['module_rebus']!['puzzles'] as Map)['p01'], isNotNull);
    expect(bundle.namespaces['module_domino'], <String, dynamic>{});
  });

  test('export then import on the same install is a no-op', () async {
    await saveService.save('module_rebus', {
      'puzzles': {
        'p01': {'solved': true, 'elapsedMs': 500, 'updatedAt': 10},
      },
    });
    final json = await service.exportJson();
    final before = await saveService.load('module_rebus');

    final report = await service.importJson(json);

    expect(report.ok, isTrue);
    expect(report.counts.added, 0);
    expect(report.counts.updated, 0);
    expect(await saveService.load('module_rebus'), before);
  });

  test('import unions a foreign bundle into local progress', () async {
    await saveService.save('module_rebus', {
      'puzzles': {
        'p01': {'solved': true, 'elapsedMs': 500, 'firstSolveElapsedMs': 500, 'updatedAt': 10},
      },
    });

    const foreign = '''
{"bundleVersion":1,"exportedAt":"2026-07-21T00:00:00.000","namespaces":{
  "module_rebus":{"puzzles":{
    "p01":{"solved":true,"elapsedMs":900,"firstSolveElapsedMs":900,"updatedAt":99},
    "p02":{"solved":false,"elapsedMs":40,"updatedAt":99}}}}}
''';

    final report = await service.importJson(foreign);
    expect(report.ok, isTrue);
    expect(report.counts.added, 1);
    expect(report.counts.updated, 0);

    final data = await saveService.load('module_rebus');
    final puzzles = data['puzzles'] as Map;
    expect(puzzles.keys.toSet(), {'p01', 'p02'});
    // Local p01 had the better first-solve time and must survive.
    expect((puzzles['p01'] as Map)['firstSolveElapsedMs'], 500);
  });

  test('import writes namespaces this build does not know about', () async {
    const foreign = '''
{"bundleVersion":1,"exportedAt":"x","namespaces":{
  "module_99_future":{"puzzles":{"z1":{"solved":true,"updatedAt":5}}}}}
''';
    final report = await service.importJson(foreign);
    expect(report.ok, isTrue);

    final data = await saveService.load('module_99_future');
    expect((data['puzzles'] as Map).containsKey('z1'), isTrue);
  });

  test('a malformed bundle is rejected and leaves saves untouched', () async {
    await saveService.save('module_rebus', {
      'puzzles': {
        'p01': {'solved': true, 'updatedAt': 10},
      },
    });
    final before = await saveService.load('module_rebus');

    final report = await service.importJson('this is not a bundle');

    expect(report.ok, isFalse);
    expect(report.error, ImportError.badFormat);
    expect(await saveService.load('module_rebus'), before);
  });

  test('a bundle from a newer app reports versionTooNew and writes nothing', () async {
    final report = await service.importJson(
      '{"bundleVersion":99,"exportedAt":"x","namespaces":{"module_rebus":{"puzzles":{"p9":{}}}}}',
    );

    expect(report.ok, isFalse);
    expect(report.error, ImportError.versionTooNew);
    expect(await saveService.load('module_rebus'), <String, dynamic>{});
  });

  test('import surfaces the bundle exportedAt for the UI', () async {
    final report = await service.importJson(
      '{"bundleVersion":1,"exportedAt":"2026-07-21T14:03:11.482","namespaces":{}}',
    );
    expect(report.ok, isTrue);
    expect(report.exportedAt, '2026-07-21T14:03:11.482');
  });
}
```

- [ ] **Step 2: Run to verify it fails**

```
F:\____IL_AI\flutter-sdk\flutter\bin\dart.bat test packages/core/test/progress_bundle_service_test.dart
```

Expected: FAIL to compile — `Undefined name 'ProgressBundleService'`.

- [ ] **Step 3: Implement the service**

Create `packages/core/lib/src/progress_bundle_service.dart`:

```dart
import 'progress_bundle.dart';
import 'progress_merge.dart';
import 'save_service.dart';

/// Why an import was refused.
enum ImportError {
  /// The text was not a readable bundle — most likely the wrong file.
  badFormat,

  /// The bundle was written by a newer build of the app.
  versionTooNew,
}

/// The outcome of an import attempt.
class ImportReport {
  /// Whether the import was applied.
  final bool ok;

  /// Why it was refused; null when [ok].
  final ImportError? error;

  /// Totals across every namespace touched.
  final NamespaceCounts counts;

  /// The bundle's `exportedAt`, for display. Empty when unknown.
  final String exportedAt;

  /// Creates a report.
  const ImportReport({
    required this.ok,
    this.error,
    this.counts = const NamespaceCounts(),
    this.exportedAt = '',
  });
}

/// Produces and consumes portable progress bundles on top of [SaveService].
///
/// Export enumerates exactly [_exportNamespaces] — pass the registered
/// modules' `saveNamespace` values, which is what keeps the `settings`
/// namespace out of every bundle. Import deliberately does **not** filter:
/// it applies every namespace the bundle carries, so a bundle produced by a
/// newer build (with a module this one has never heard of) preserves that
/// module's data instead of dropping it.
class ProgressBundleService {
  final SaveService _saveService;
  final List<String> _exportNamespaces;

  /// Creates a bundle service over [saveService], exporting
  /// [exportNamespaces].
  ProgressBundleService(this._saveService, List<String> exportNamespaces)
      : _exportNamespaces = List<String>.unmodifiable(exportNamespaces);

  /// Reads every exported namespace and returns the bundle as JSON text.
  Future<String> exportJson() async {
    final namespaces = <String, Map<String, dynamic>>{};
    for (final ns in _exportNamespaces) {
      namespaces[ns] = await _saveService.load(ns);
    }

    final bundle = ProgressBundle(
      bundleVersion: ProgressBundle.currentBundleVersion,
      exportedAt: DateTime.now().toIso8601String(),
      namespaces: namespaces,
    );
    return bundle.encode();
  }

  /// Parses [jsonText] and merges it into local saves.
  ///
  /// Never throws: parse failures come back as a non-[ImportReport.ok]
  /// report. Nothing is written unless the whole bundle parsed, so a bad
  /// file cannot leave saves half-updated.
  Future<ImportReport> importJson(String jsonText) async {
    final ProgressBundle bundle;
    try {
      bundle = ProgressBundle.decode(jsonText);
    } on BundleFormatException catch (e) {
      return ImportReport(
        ok: false,
        error: e.isVersionTooNew ? ImportError.versionTooNew : ImportError.badFormat,
      );
    }

    var totals = const NamespaceCounts();
    for (final entry in bundle.namespaces.entries) {
      final local = await _saveService.load(entry.key);
      final result = mergeNamespaceData(local, entry.value);
      await _saveService.save(entry.key, result.data);
      totals = totals + result.counts;
    }

    return ImportReport(ok: true, counts: totals, exportedAt: bundle.exportedAt);
  }
}
```

Add to `packages/core/lib/puzzle_core.dart`:

```dart
export 'src/progress_bundle_service.dart';
```

- [ ] **Step 4: Run the whole core suite**

```
F:\____IL_AI\flutter-sdk\flutter\bin\dart.bat test packages/core
F:\____IL_AI\flutter-sdk\flutter\bin\flutter.bat analyze
```

Expected: all core tests PASS (the three new files plus the three pre-existing ones), analyze clean.

- [ ] **Step 5: Commit**

```bash
git add packages/core/lib/src/progress_bundle_service.dart packages/core/lib/puzzle_core.dart packages/core/test/progress_bundle_service_test.dart
git commit -m "feat(core): add ProgressBundleService export/import over SaveService"
```

---

### Task 5: Localization keys

**Files:**
- Modify: `app/lib/l10n/app_ru.arb` (TEMPLATE — edit first)
- Modify: `app/lib/l10n/app_en.arb`
- Modify: `app/lib/l10n/app_de.arb`
- Test: `app/test/arb_parity_test.dart` (existing — must stay green)

**Interfaces:**
- Consumes: nothing.
- Produces: `l10n.settingsSyncSection`, `l10n.settingsSyncHint`, `l10n.settingsExportProgress`, `l10n.settingsImportProgress`, `l10n.exportSuccess`, `l10n.exportFailed`, `l10n.importConfirmTitle`, `l10n.importConfirmBody(date)`, `l10n.importConfirmApply`, `l10n.importConfirmCancel`, `l10n.importSuccess(added, updated)`, `l10n.importNothingNew`, `l10n.importFailedFormat`, `l10n.importFailedVersion`. Task 7 uses all of them.

- [ ] **Step 1: Add the keys to the RU template**

Append to `app/lib/l10n/app_ru.arb`, before the closing `}` (add a comma to the previously-last entry):

```json
  "settingsSyncSection": "Перенос прогресса",
  "@settingsSyncSection": {"description": "Header of the settings section for exporting/importing progress between devices."},
  "settingsSyncHint": "Сохраните прогресс в файл и откройте его на другом устройстве.",
  "@settingsSyncHint": {"description": "Subtitle under the progress-sync section header."},
  "settingsExportProgress": "Сохранить прогресс в файл",
  "@settingsExportProgress": {"description": "Label of the export tile in Settings."},
  "settingsImportProgress": "Загрузить прогресс из файла",
  "@settingsImportProgress": {"description": "Label of the import tile in Settings."},
  "exportSuccess": "Прогресс сохранён.",
  "@exportSuccess": {"description": "Snackbar shown after a successful export."},
  "exportFailed": "Не удалось сохранить файл.",
  "@exportFailed": {"description": "Snackbar shown when writing the export file failed."},
  "importConfirmTitle": "Загрузить прогресс?",
  "@importConfirmTitle": {"description": "Title of the import confirmation dialog."},
  "importConfirmBody": "Файл создан: {date}. Ваш текущий прогресс не будет потерян — лучшие результаты сохранятся.",
  "@importConfirmBody": {
    "description": "Body of the import confirmation dialog, reassuring that the merge is non-destructive.",
    "placeholders": {"date": {"type": "String"}}
  },
  "importConfirmApply": "Загрузить",
  "@importConfirmApply": {"description": "Confirm button of the import dialog."},
  "importConfirmCancel": "Отмена",
  "@importConfirmCancel": {"description": "Cancel button of the import dialog."},
  "importSuccess": "Добавлено головоломок: {added}, обновлено: {updated}.",
  "@importSuccess": {
    "description": "Snackbar shown after a successful import.",
    "placeholders": {"added": {"type": "int"}, "updated": {"type": "int"}}
  },
  "importNothingNew": "Новых результатов не найдено.",
  "@importNothingNew": {"description": "Snackbar shown when an import applied cleanly but changed nothing."},
  "importFailedFormat": "Это не файл прогресса.",
  "@importFailedFormat": {"description": "Snackbar shown when the picked file is not a bundle."},
  "importFailedVersion": "Файл создан более новой версией приложения. Обновите приложение.",
  "@importFailedVersion": {"description": "Snackbar shown when the bundle's version is newer than this build supports."}
```

- [ ] **Step 2: Add the same keys to EN**

Append to `app/lib/l10n/app_en.arb` (same key order; `@`-metadata blocks are only required in the template, but this project carries them in every file — match whatever the neighbouring keys in `app_en.arb` already do):

```json
  "settingsSyncSection": "Transfer progress",
  "settingsSyncHint": "Save your progress to a file and open it on another device.",
  "settingsExportProgress": "Save progress to a file",
  "settingsImportProgress": "Load progress from a file",
  "exportSuccess": "Progress saved.",
  "exportFailed": "Could not save the file.",
  "importConfirmTitle": "Load progress?",
  "importConfirmBody": "File created: {date}. Your current progress will not be lost — your best results are kept.",
  "importConfirmApply": "Load",
  "importConfirmCancel": "Cancel",
  "importSuccess": "Puzzles added: {added}, updated: {updated}.",
  "importNothingNew": "No new results found.",
  "importFailedFormat": "That is not a progress file.",
  "importFailedVersion": "This file was made by a newer version of the app. Please update."
```

- [ ] **Step 3: Add the same keys to DE**

Append to `app/lib/l10n/app_de.arb`:

```json
  "settingsSyncSection": "Fortschritt übertragen",
  "settingsSyncHint": "Fortschritt in eine Datei speichern und auf einem anderen Gerät öffnen.",
  "settingsExportProgress": "Fortschritt in Datei speichern",
  "settingsImportProgress": "Fortschritt aus Datei laden",
  "exportSuccess": "Fortschritt gespeichert.",
  "exportFailed": "Datei konnte nicht gespeichert werden.",
  "importConfirmTitle": "Fortschritt laden?",
  "importConfirmBody": "Datei erstellt: {date}. Dein bisheriger Fortschritt geht nicht verloren — die besten Ergebnisse bleiben erhalten.",
  "importConfirmApply": "Laden",
  "importConfirmCancel": "Abbrechen",
  "importSuccess": "Rätsel hinzugefügt: {added}, aktualisiert: {updated}.",
  "importNothingNew": "Keine neuen Ergebnisse gefunden.",
  "importFailedFormat": "Das ist keine Fortschrittsdatei.",
  "importFailedVersion": "Diese Datei stammt aus einer neueren App-Version. Bitte aktualisiere die App."
```

- [ ] **Step 4: Regenerate and verify parity**

```
F:\____IL_AI\flutter-sdk\flutter\bin\flutter.bat gen-l10n
F:\____IL_AI\flutter-sdk\flutter\bin\flutter.bat test app/test/arb_parity_test.dart
F:\____IL_AI\flutter-sdk\flutter\bin\flutter.bat analyze
```

Expected: `gen-l10n` regenerates `app/lib/l10n/app_localizations*.dart` with the 14 new getters (two of them taking parameters), parity test PASS, analyze clean.

If the build runs `gen-l10n` implicitly via `generate: true` in `app/pubspec.yaml`, running `flutter test` alone also regenerates — either way, confirm `app_localizations.dart` now declares `String get settingsExportProgress` and `String importSuccess(int added, int updated)`.

- [ ] **Step 5: Commit**

```bash
git add app/lib/l10n
git commit -m "feat(l10n): add progress export/import strings in ru, en, de"
```

---

### Task 6: The `BundleTransfer` seam and its providers

**Files:**
- Create: `app/lib/bundle_transfer.dart`
- Modify: `app/pubspec.yaml`
- Modify: `app/lib/providers.dart`
- Modify: `app/lib/main.dart:33-49`

**Interfaces:**
- Consumes: `ProgressBundleService` (Task 4), `ModuleRegistry`, `SaveService`.
- Produces:
  - `abstract class BundleTransfer` with `Future<bool> saveBundle(String jsonText, String suggestedFileName)` (returns false if the user cancelled or the write failed) and `Future<String?> pickBundle()` (returns the file's text, or null if cancelled/unreadable).
  - `class FilePickerBundleTransfer implements BundleTransfer`.
  - `final Provider<BundleTransfer> bundleTransferProvider`
  - `final Provider<ProgressBundleService> progressBundleServiceProvider`
  Task 7's settings screen reads both providers; Task 7's widget test overrides `bundleTransferProvider` with a fake.

**Why a seam:** file dialogs cannot run inside a widget test. Everything above the dialog — button wiring, confirm flow, snackbar text, error mapping — becomes testable by overriding this one provider.

- [ ] **Step 1: Add the dependency**

```
F:\____IL_AI\flutter-sdk\flutter\bin\flutter.bat pub add file_picker --directory app
```

Then check which major version resolved:

```
F:\____IL_AI\flutter-sdk\flutter\bin\flutter.bat pub deps --directory app --style=compact | grep file_picker
```

The code in Step 2 targets the `file_picker` 8.x API (`FilePicker.platform.saveFile({dialogTitle, fileName, bytes})` and `FilePicker.platform.pickFiles({type, allowedExtensions, withData})`). **If a different major resolved and the analyzer rejects those signatures, read the installed version's `CHANGELOG.md` under `%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\file_picker-*\` and adapt — do not guess.** The `BundleTransfer` interface must not change either way; that is the whole point of the seam.

- [ ] **Step 2: Write the seam**

Create `app/lib/bundle_transfer.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// Moves bundle text between the app and the device's file system.
///
/// Split out from the settings screen so widget tests can drive the whole
/// export/import flow without a native file dialog.
abstract class BundleTransfer {
  /// Asks the user where to put [jsonText] and writes it.
  ///
  /// Returns false if the user cancelled or the write failed. Implementations
  /// must not throw.
  Future<bool> saveBundle(String jsonText, String suggestedFileName);

  /// Asks the user to pick a bundle file and returns its text.
  ///
  /// Returns null if the user cancelled or the file could not be read.
  /// Implementations must not throw.
  Future<String?> pickBundle();
}

/// [BundleTransfer] backed by the platform file dialogs.
///
/// On Android `saveFile` needs the content up front (`bytes:`) because the
/// write happens through the Storage Access Framework rather than a raw
/// path; on Windows it returns a path and we write it ourselves. Passing
/// `bytes:` on both platforms keeps one code path — on desktop the plugin
/// writes the bytes for us.
class FilePickerBundleTransfer implements BundleTransfer {
  /// Creates a file-dialog-backed transfer.
  const FilePickerBundleTransfer();

  @override
  Future<bool> saveBundle(String jsonText, String suggestedFileName) async {
    try {
      final bytes = utf8.encode(jsonText);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Puzzle Book',
        fileName: suggestedFileName,
        bytes: bytes,
      );
      if (path == null) return false;

      // On desktop the plugin may return the chosen path without having
      // written anything; writing again is harmless and makes the desktop
      // path explicit.
      final file = File(path);
      if (!await file.exists() || await file.length() != bytes.length) {
        await file.writeAsBytes(bytes, flush: true);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> pickBundle() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Puzzle Book',
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;

      final picked = result.files.single;
      final bytes = picked.bytes;
      if (bytes != null) return utf8.decode(bytes, allowMalformed: true);

      final path = picked.path;
      if (path == null) return null;
      return await File(path).readAsString();
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 3: Add the providers**

Append to `app/lib/providers.dart`:

```dart
/// The app's [ProgressBundleService], built in `main` from the registered
/// modules' save namespaces and supplied here via an override. Exporting
/// only registered module namespaces is what keeps the `settings` namespace
/// (a per-device preference, not progress) out of every bundle.
final Provider<ProgressBundleService> progressBundleServiceProvider =
    Provider<ProgressBundleService>((ref) {
  throw UnimplementedError(
      'progressBundleServiceProvider must be overridden with a concrete ProgressBundleService before use.');
});

/// How bundle text reaches the file system. Overridden in `main` with
/// [FilePickerBundleTransfer]; widget tests override it with a fake so the
/// export/import flow can run without a native file dialog.
final Provider<BundleTransfer> bundleTransferProvider = Provider<BundleTransfer>((ref) {
  throw UnimplementedError(
      'bundleTransferProvider must be overridden with a concrete BundleTransfer before use.');
});
```

Add the import at the top of `app/lib/providers.dart`:

```dart
import 'bundle_transfer.dart';
```

- [ ] **Step 4: Wire them in `main`**

In `app/lib/main.dart`, add the import:

```dart
import 'bundle_transfer.dart';
```

After the `moduleRegistry` is built (currently `main.dart:33-36`), add:

```dart
  final progressBundleService = ProgressBundleService(
    saveService,
    moduleRegistry.modules.map((m) => m.saveNamespace).toList(),
  );
```

And add two entries to the `overrides:` list:

```dart
        progressBundleServiceProvider.overrideWithValue(progressBundleService),
        bundleTransferProvider.overrideWithValue(const FilePickerBundleTransfer()),
```

- [ ] **Step 5: Verify it builds**

```
F:\____IL_AI\flutter-sdk\flutter\bin\flutter.bat analyze
F:\____IL_AI\flutter-sdk\flutter\bin\flutter.bat test
```

Expected: analyze clean, all existing tests still PASS. No behaviour changed yet — nothing calls the new providers.

- [ ] **Step 6: Commit**

```bash
git add app/pubspec.yaml app/pubspec.lock pubspec.lock app/lib/bundle_transfer.dart app/lib/providers.dart app/lib/main.dart
git commit -m "feat(app): add BundleTransfer seam and progress-bundle providers"
```

---

### Task 7: Settings screen — export and import tiles

**Files:**
- Modify: `app/lib/screens/settings_screen.dart:72` (append after the theme `RadioGroup`)
- Test: `app/test/settings_sync_test.dart`

**Interfaces:**
- Consumes: `progressBundleServiceProvider`, `bundleTransferProvider` (Task 6); the l10n getters from Task 5; `ImportError`, `ImportReport` (Task 4).
- Produces: nothing other tasks depend on.

**Flow:**
- Export → `exportJson()` → `saveBundle(text, 'puzzlebook-progress-YYYY-MM-DD.json')` → snackbar `exportSuccess` or `exportFailed`.
- Import → `pickBundle()` → null means cancelled, show nothing → parse-free confirm dialog showing the raw file's `exportedAt` is *not* available before parsing, so: call `importJson()` **after** the confirm dialog, and show the dialog with the file name instead. To keep the promised "shows when the bundle was made", the dialog is shown *after* a successful parse — which means the merge must not have been applied yet. Resolve this by parsing in the screen via `ProgressBundle.decode` for the preview, then calling `importJson` on confirm. `decode` is cheap and pure; calling it twice is fine.

- [ ] **Step 1: Write the failing widget test**

Create `app/test/settings_sync_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_core/puzzle_core.dart';
import 'package:puzzles/bundle_transfer.dart';
import 'package:puzzles/l10n/app_localizations.dart';
import 'package:puzzles/providers.dart';
import 'package:puzzles/screens/settings_screen.dart';

class FakeBundleTransfer implements BundleTransfer {
  String? savedText;
  String? bundleToPick;
  bool saveSucceeds = true;

  @override
  Future<bool> saveBundle(String jsonText, String suggestedFileName) async {
    savedText = jsonText;
    return saveSucceeds;
  }

  @override
  Future<String?> pickBundle() async => bundleToPick;
}

void main() {
  late Directory tempDir;
  late SaveService saveService;
  late SettingsService settingsService;
  late ProgressBundleService bundleService;
  late FakeBundleTransfer transfer;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('settings_sync_test_');
    saveService = SaveService(() => tempDir);
    settingsService = SettingsService(saveService);
    await settingsService.init();
    bundleService = ProgressBundleService(saveService, const ['module_rebus']);
    transfer = FakeBundleTransfer();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget harness() {
    return ProviderScope(
      overrides: [
        settingsServiceProvider.overrideWithValue(settingsService),
        progressBundleServiceProvider.overrideWithValue(bundleService),
        bundleTransferProvider.overrideWithValue(transfer),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(),
      ),
    );
  }

  testWidgets('export tile writes a bundle through the transfer', (tester) async {
    await saveService.save('module_rebus', {
      'puzzles': {
        'p01': {'solved': true, 'updatedAt': 1},
      },
    });

    await tester.pumpWidget(harness());
    await tester.scrollUntilVisible(find.text('Save progress to a file'), 200);
    await tester.tap(find.text('Save progress to a file'));
    await tester.pumpAndSettle();

    expect(transfer.savedText, isNotNull);
    final bundle = ProgressBundle.decode(transfer.savedText!);
    expect((bundle.namespaces['module_rebus']!['puzzles'] as Map).containsKey('p01'), isTrue);
    expect(find.text('Progress saved.'), findsOneWidget);
  });

  testWidgets('import shows a confirm dialog and applies on confirm', (tester) async {
    transfer.bundleToPick = '''
{"bundleVersion":1,"exportedAt":"2026-07-21T14:03:11.482","namespaces":{
  "module_rebus":{"puzzles":{"p05":{"solved":true,"updatedAt":9}}}}}
''';

    await tester.pumpWidget(harness());
    await tester.scrollUntilVisible(find.text('Load progress from a file'), 200);
    await tester.tap(find.text('Load progress from a file'));
    await tester.pumpAndSettle();

    expect(find.text('Load progress?'), findsOneWidget);
    await tester.tap(find.text('Load'));
    await tester.pumpAndSettle();

    final data = await saveService.load('module_rebus');
    expect((data['puzzles'] as Map).containsKey('p05'), isTrue);
    expect(find.textContaining('added: 1'), findsOneWidget);
  });

  testWidgets('cancelling the confirm dialog writes nothing', (tester) async {
    transfer.bundleToPick = '''
{"bundleVersion":1,"exportedAt":"x","namespaces":{
  "module_rebus":{"puzzles":{"p05":{"solved":true,"updatedAt":9}}}}}
''';

    await tester.pumpWidget(harness());
    await tester.scrollUntilVisible(find.text('Load progress from a file'), 200);
    await tester.tap(find.text('Load progress from a file'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(await saveService.load('module_rebus'), <String, dynamic>{});
  });

  testWidgets('a non-bundle file reports a format error and writes nothing', (tester) async {
    transfer.bundleToPick = 'definitely not a bundle';

    await tester.pumpWidget(harness());
    await tester.scrollUntilVisible(find.text('Load progress from a file'), 200);
    await tester.tap(find.text('Load progress from a file'));
    await tester.pumpAndSettle();

    expect(find.text('That is not a progress file.'), findsOneWidget);
    expect(await saveService.load('module_rebus'), <String, dynamic>{});
  });

  testWidgets('a newer-version bundle reports the version error', (tester) async {
    transfer.bundleToPick = '{"bundleVersion":99,"exportedAt":"x","namespaces":{}}';

    await tester.pumpWidget(harness());
    await tester.scrollUntilVisible(find.text('Load progress from a file'), 200);
    await tester.tap(find.text('Load progress from a file'));
    await tester.pumpAndSettle();

    expect(
      find.text('This file was made by a newer version of the app. Please update.'),
      findsOneWidget,
    );
  });
}
```

- [ ] **Step 2: Run to verify it fails**

```
F:\____IL_AI\flutter-sdk\flutter\bin\flutter.bat test app/test/settings_sync_test.dart
```

Expected: FAIL — the tiles do not exist, so `scrollUntilVisible` cannot find `Save progress to a file`.

- [ ] **Step 3: Implement the UI**

In `app/lib/screens/settings_screen.dart`, add imports:

```dart
import 'package:puzzle_core/puzzle_core.dart';
```

Change `SettingsScreen` from `ConsumerWidget` to `ConsumerStatefulWidget` (the flows need `context`/`mounted` across awaits):

```dart
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
```

with the existing `build` body becoming `Widget build(BuildContext context)` and every `ref.watch`/`ref.read` unchanged (`ref` is a field on `ConsumerState`).

Append inside the `ListView`'s `children`, after the theme `RadioGroup` (currently ending at `settings_screen.dart:72`):

```dart
          const Divider(),
          ListTile(
            title: Text(l10n.settingsSyncSection),
            subtitle: Text(l10n.settingsSyncHint),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: Text(l10n.settingsExportProgress),
            onTap: _handleExport,
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: Text(l10n.settingsImportProgress),
            onTap: _handleImport,
          ),
```

Add these methods to `_SettingsScreenState`:

```dart
  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleExport() async {
    final l10n = AppLocalizations.of(context);
    final bundleService = ref.read(progressBundleServiceProvider);
    final transfer = ref.read(bundleTransferProvider);

    final jsonText = await bundleService.exportJson();
    final now = DateTime.now();
    final stamp = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final ok = await transfer.saveBundle(jsonText, 'puzzlebook-progress-$stamp.json');

    _showSnack(ok ? l10n.exportSuccess : l10n.exportFailed);
  }

  Future<void> _handleImport() async {
    final l10n = AppLocalizations.of(context);
    final bundleService = ref.read(progressBundleServiceProvider);
    final transfer = ref.read(bundleTransferProvider);

    final jsonText = await transfer.pickBundle();
    // Null means the user backed out of the file dialog — say nothing.
    if (jsonText == null) return;

    // Parse once up front purely to preview the bundle's date in the
    // confirmation dialog; the merge itself re-parses inside importJson.
    // decode() is pure and cheap, so paying for it twice is fine.
    final ProgressBundle preview;
    try {
      preview = ProgressBundle.decode(jsonText);
    } on BundleFormatException catch (e) {
      _showSnack(e.isVersionTooNew ? l10n.importFailedVersion : l10n.importFailedFormat);
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.importConfirmTitle),
        content: Text(l10n.importConfirmBody(preview.exportedAt)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.importConfirmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.importConfirmApply),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final report = await bundleService.importJson(jsonText);
    if (!report.ok) {
      _showSnack(
        report.error == ImportError.versionTooNew ? l10n.importFailedVersion : l10n.importFailedFormat,
      );
      return;
    }

    final changed = report.counts.added + report.counts.updated;
    _showSnack(
      changed == 0
          ? l10n.importNothingNew
          : l10n.importSuccess(report.counts.added, report.counts.updated),
    );
  }
```

- [ ] **Step 4: Run to verify it passes**

```
F:\____IL_AI\flutter-sdk\flutter\bin\flutter.bat test app/test/settings_sync_test.dart
F:\____IL_AI\flutter-sdk\flutter\bin\flutter.bat test
F:\____IL_AI\flutter-sdk\flutter\bin\flutter.bat analyze
```

Expected: 5 new tests PASS, whole suite PASS, analyze clean.

If `expect(find.textContaining('added: 1'), ...)` fails, print the actual snackbar text and align the expectation with the generated `importSuccess` output — the EN string is `"Puzzles added: {added}, updated: {updated}."`, so the substring should match.

- [ ] **Step 5: Commit**

```bash
git add app/lib/screens/settings_screen.dart app/test/settings_sync_test.dart
git commit -m "feat(app): add progress export/import tiles to Settings"
```

---

### Task 8: Live verification on both platforms

**Files:**
- Modify: `SYNC-PUZZLEBOOK-PROGRESS.txt` (mark the feature as shipped; replace §5's adb workaround with the in-app flow)

**Interfaces:**
- Consumes: everything above.
- Produces: evidence that the round trip works on real devices.

This task is manual. It cannot be automated and must not be skipped — the file dialogs are exactly the part no test covers.

- [ ] **Step 1: Windows round trip**

```
F:\____IL_AI\flutter-sdk\flutter\bin\flutter.bat run -d windows --directory app
```

Solve at least one puzzle in two different modules, complete one tutorial, then Settings → "Сохранить прогресс в файл". Save to the Desktop. Confirm:
- The file exists and opens in a text editor as indented JSON.
- It has `bundleVersion: 1` and three `namespaces` keys.
- It does **not** contain `"language"` or `"soundOn"` anywhere (`settings` must not be in the bundle).

- [ ] **Step 2: Windows import is idempotent**

Still on Windows, Settings → "Загрузить прогресс из файла" → pick the file just written → confirm. Expect the "no new results" snackbar. Re-open a solved puzzle and confirm its state and timer are unchanged.

- [ ] **Step 3: Android round trip**

```
F:\____IL_AI\flutter-sdk\flutter\bin\flutter.bat build apk --release --directory app
```

Install on the Meizu test device. Solve a *different* puzzle than the ones solved on Windows. Export from the phone, transfer the file to the PC (any means), import it on Windows. Confirm:
- The phone-only puzzle now shows as solved on Windows.
- The Windows-only puzzles are still solved.
- The home-screen module cards show the summed counts.

- [ ] **Step 4: Reverse direction and the merge rule**

Import the Windows bundle on the phone. Then, on both devices, re-solve one shared puzzle *slowly* on one device so it has a worse `firstSolveElapsedMs`, export from the slow device, import on the fast one, and confirm the **fast** time survived — that is rung 2 of the ladder working in the wild.

- [ ] **Step 5: Update the background note**

Rewrite §1 and §5 of `SYNC-PUZZLEBOOK-PROGRESS.txt` to describe the shipped export/import flow instead of the "no sync exists" assessment and the adb workaround. Keep §2's description of the on-disk format and §4's merge ladder — those stay accurate and are the reference for anyone touching the merge later.

- [ ] **Step 6: Commit**

```bash
git add SYNC-PUZZLEBOOK-PROGRESS.txt
git commit -m "docs: record shipped progress export/import flow"
```

---

## Key decisions & tradeoffs

- **Manual bundle file, not a sync backend.** No account, no server, no privacy surface, no recurring cost, works offline, and it is the only design that gets past Android's app-private data directory without root. Rejected: real cloud sync (overkill until there are users asking), LAN/QR transfer (much more code for the same result; QR cannot hold the board arrays), and a shared cloud folder as the save directory (desktop-to-desktop only, fights `SaveService`'s temp-write+rename, no merge).
- **Clipboard rejected as the transport.** Zero dependencies and identical on both platforms, but a 100 KB+ JSON blob pasted through a messenger is a bad experience.
- **`updatedAt` added inside `data`, no `schemaVersion` bump.** A bump would make older builds quarantine the save file into a `.bak` — actively destructive. An unknown key is simply ignored by older builds.
- **Merge picks a whole winning entry, never blends fields.** An entry's board state and its timings must stay consistent with each other.
- **Ties resolve to local**, which makes importing the same bundle twice a provable no-op — the property the "export then import is a no-op" test locks in.
- **Export filters by registered namespaces; import does not filter.** Export is how `settings` stays out. Import taking unknown namespaces means a bundle from a newer build does not silently lose a future module's data.
- **`settings` is never synced.** Language, sound and theme are per-device preferences; syncing them would be a bug.
- **File dialogs live behind `BundleTransfer`.** Everything except the native dialog itself is covered by widget tests.

## Risks / open questions

- **`file_picker` major-version drift.** The `saveFile(bytes:)` / `pickFiles(withData:)` signatures are from the 8.x API and were not verified against an installed copy at plan-writing time. Task 6 Step 1 makes checking the resolved version an explicit step. The `BundleTransfer` interface absorbs any change.
- **Clock skew across devices.** `updatedAt` and `solvedAt` are device wall-clock. A phone with a wrong clock could win rung 4 undeservedly. Mitigated by ordering: rungs 1–3 (solved-ness, best solve time) are clock-independent and decide most real conflicts; only two unsolved in-progress boards fall through to rung 4, where the cost of a wrong pick is a lost partial board, not a lost solve.
- **`solvedAt` is `DateTime.now().toIso8601String()` — local time with no offset.** Comparing two devices' strings across time zones can order them wrongly. Only reached at rung 3, i.e. when both devices solved the same puzzle in exactly the same number of milliseconds. Accepted.
- **Android SAF write path.** `saveFile` with `bytes:` on Android is the documented path but is untested here; Task 8 Step 3 is where it gets proven. If it fails, the fallback is `share_plus` (write to `getTemporaryDirectory()`, then share the `XFile`) behind the same `BundleTransfer` interface.
- **Task 1 test method names.** The domino controller's public API (`ensureLoaded` / `selectCell` / `flushForTest`) was inferred from the file's shape, not read line-by-line. The implementer should copy whatever drive-and-flush pattern the neighbouring tests in `domino_session_controller_test.dart` already use.
- **`ConsumerWidget` → `ConsumerStatefulWidget` conversion in Task 7** touches an existing screen. `app/test/widget_test.dart` may reach into `SettingsScreen`; run the full suite, not just the new file.

## Out of scope

- Any automatic or background sync.
- Accounts, cloud storage, or a server of any kind.
- Syncing `settings` (language, sound, theme).
- Selective import (choosing which modules or puzzles to take).
- An in-app view of what an import would change before applying it — the merge is non-destructive by construction, so a dry-run preview earns little.
- Encryption or signing of the bundle file.
- iOS, macOS, Linux or web builds.
