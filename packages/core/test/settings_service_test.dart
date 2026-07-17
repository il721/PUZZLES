import 'dart:io';

import 'package:puzzle_core/puzzle_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late SaveService saveService;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('settings_service_test_');
    saveService = SaveService(() => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('reports defaults before and after init with no persisted data', () async {
    final settings = SettingsService(saveService);
    expect(settings.language, SettingsService.defaultLanguage);
    expect(settings.soundOn, SettingsService.defaultSoundOn);
    expect(settings.theme, SettingsService.defaultTheme);

    await settings.init();
    expect(settings.language, SettingsService.defaultLanguage);
    expect(settings.soundOn, SettingsService.defaultSoundOn);
    expect(settings.theme, SettingsService.defaultTheme);
  });

  test('set values persist across a fresh instance and reload', () async {
    final settings = SettingsService(saveService);
    await settings.init();
    await settings.setLanguage('de');
    await settings.setSoundOn(false);
    await settings.setTheme('light');

    final reloaded = SettingsService(saveService);
    await reloaded.init();
    expect(reloaded.language, 'de');
    expect(reloaded.soundOn, false);
    expect(reloaded.theme, 'light');
  });

  group('resolveLanguage', () {
    test('ru maps to ru', () {
      expect(SettingsService.resolveLanguage('ru'), 'ru');
    });

    test('de maps to de', () {
      expect(SettingsService.resolveLanguage('de'), 'de');
    });

    test('en maps to en', () {
      expect(SettingsService.resolveLanguage('en'), 'en');
    });

    test('an unsupported code maps to en', () {
      expect(SettingsService.resolveLanguage('fr'), 'en');
    });

    test('null maps to en', () {
      expect(SettingsService.resolveLanguage(null), 'en');
    });
  });
}
