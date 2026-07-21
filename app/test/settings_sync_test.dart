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
  // SaveService does real dart:io. testWidgets runs its body inside a
  // FakeAsync zone, and a real dart:io await inside that zone never
  // completes, so `pumpAndSettle()` hangs forever whenever a tap reaches
  // export/import (both of which go through SaveService). The fix is the
  // same ratchet idiom used in
  // packages/module_domino_ui/test/domino_tutorial_screen_test.dart: drive
  // every real-io await with `tester.runAsync(...)`, then loop
  // `runAsync(delay) + pump()` up to 50 times, re-checking the expected
  // condition each iteration and breaking as soon as it holds.
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
    await tester.runAsync(() => saveService.save('module_rebus', {
          'puzzles': {
            'p01': {'solved': true, 'updatedAt': 1},
          },
        }));

    await tester.pumpWidget(harness());
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Save progress to a file'), 200);
    await tester.tap(find.text('Save progress to a file'));
    await tester.pump();

    var ready = transfer.savedText != null;
    for (var i = 0; i < 50 && !ready; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
      ready = transfer.savedText != null;
    }
    expect(ready, isTrue, reason: 'export never wrote a bundle through the transfer');

    expect(transfer.savedText, isNotNull);
    final bundle = ProgressBundle.decode(transfer.savedText!);
    expect((bundle.namespaces['module_rebus']!['puzzles'] as Map).containsKey('p01'), isTrue);

    await tester.pump();
    await tester.pump();
    expect(find.text('Progress saved.'), findsOneWidget);
  });

  testWidgets('import shows a confirm dialog and applies on confirm', (tester) async {
    transfer.bundleToPick = '''
{"bundleVersion":1,"exportedAt":"2026-07-21T14:03:11.482","namespaces":{
  "module_rebus":{"puzzles":{"p05":{"solved":true,"updatedAt":9}}}}}
''';

    await tester.pumpWidget(harness());
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Load progress from a file'), 200);
    await tester.tap(find.text('Load progress from a file'));
    await tester.pump();

    var dialogShown = find.text('Load progress?').evaluate().isNotEmpty;
    for (var i = 0; i < 50 && !dialogShown; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
      dialogShown = find.text('Load progress?').evaluate().isNotEmpty;
    }
    expect(dialogShown, isTrue, reason: 'import confirm dialog never appeared');
    expect(find.text('Load progress?'), findsOneWidget);

    await tester.tap(find.text('Load'));
    await tester.pump();

    Map<String, dynamic>? data;
    for (var i = 0; i < 50 && data == null; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
      final loaded = (await tester.runAsync(() => saveService.load('module_rebus')))!;
      if ((loaded['puzzles'] as Map?)?.containsKey('p05') == true) {
        data = loaded;
      }
    }
    expect(data, isNotNull, reason: 'imported p05 never landed on disk');
    expect((data!['puzzles'] as Map).containsKey('p05'), isTrue);

    await tester.pump();
    await tester.pump();
    expect(find.textContaining('added: 1'), findsOneWidget);
  });

  testWidgets('cancelling the confirm dialog writes nothing', (tester) async {
    transfer.bundleToPick = '''
{"bundleVersion":1,"exportedAt":"x","namespaces":{
  "module_rebus":{"puzzles":{"p05":{"solved":true,"updatedAt":9}}}}}
''';

    await tester.pumpWidget(harness());
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Load progress from a file'), 200);
    await tester.tap(find.text('Load progress from a file'));
    await tester.pump();

    var dialogShown = find.text('Load progress?').evaluate().isNotEmpty;
    for (var i = 0; i < 50 && !dialogShown; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
      dialogShown = find.text('Load progress?').evaluate().isNotEmpty;
    }
    expect(dialogShown, isTrue, reason: 'import confirm dialog never appeared');

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();

    expect((await tester.runAsync(() => saveService.load('module_rebus')))!, <String, dynamic>{});
  });

  testWidgets('a non-bundle file reports a format error and writes nothing', (tester) async {
    transfer.bundleToPick = 'definitely not a bundle';

    await tester.pumpWidget(harness());
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Load progress from a file'), 200);
    await tester.tap(find.text('Load progress from a file'));
    await tester.pump();

    var errorShown = find.text('That is not a progress file.').evaluate().isNotEmpty;
    for (var i = 0; i < 50 && !errorShown; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
      errorShown = find.text('That is not a progress file.').evaluate().isNotEmpty;
    }
    expect(errorShown, isTrue, reason: 'format-error message never appeared');
    expect(find.text('That is not a progress file.'), findsOneWidget);

    expect((await tester.runAsync(() => saveService.load('module_rebus')))!, <String, dynamic>{});
  });

  testWidgets('a newer-version bundle reports the version error', (tester) async {
    transfer.bundleToPick = '{"bundleVersion":99,"exportedAt":"x","namespaces":{}}';

    await tester.pumpWidget(harness());
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Load progress from a file'), 200);
    await tester.tap(find.text('Load progress from a file'));
    await tester.pump();

    const message = 'This file was made by a newer version of the app. Please update.';
    var errorShown = find.text(message).evaluate().isNotEmpty;
    for (var i = 0; i < 50 && !errorShown; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
      errorShown = find.text(message).evaluate().isNotEmpty;
    }
    expect(errorShown, isTrue, reason: 'version-error message never appeared');
    expect(find.text(message), findsOneWidget);
  });
}
