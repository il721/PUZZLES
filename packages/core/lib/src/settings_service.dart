import 'save_service.dart';

/// User-configurable app settings (language, sound), persisted through a
/// [SaveService] under the `settings` namespace.
///
/// Values are cached in memory after [init] is awaited; getters read from
/// that cache, and setters update the cache and persist immediately.
class SettingsService {
  static const String _namespace = 'settings';
  static const String _keyLanguage = 'language';
  static const String _keySoundOn = 'soundOn';

  /// Sentinel language value meaning "follow the device locale". Resolved
  /// to a concrete supported language via [resolveLanguage].
  static const String defaultLanguage = 'system';

  /// Default value for [soundOn] before any settings have been persisted.
  static const bool defaultSoundOn = true;

  final SaveService _saveService;

  String _language = defaultLanguage;
  bool _soundOn = defaultSoundOn;
  bool _initialized = false;

  /// Creates a settings service backed by [saveService].
  SettingsService(this._saveService);

  /// Loads any previously persisted settings into the in-memory cache.
  /// Must be awaited before relying on persisted values; until then,
  /// [language] and [soundOn] report their defaults.
  Future<void> init() async {
    final data = await _saveService.load(_namespace);

    final lang = data[_keyLanguage];
    if (lang is String) {
      _language = lang;
    }

    final sound = data[_keySoundOn];
    if (sound is bool) {
      _soundOn = sound;
    }

    _initialized = true;
  }

  /// Whether [init] has completed at least once.
  bool get isInitialized => _initialized;

  /// The configured language: `system`, `ru`, `en`, or `de`.
  String get language => _language;

  /// Whether sound effects are enabled.
  bool get soundOn => _soundOn;

  /// Sets and persists the configured language.
  Future<void> setLanguage(String language) async {
    _language = language;
    await _persist();
  }

  /// Sets and persists whether sound effects are enabled.
  Future<void> setSoundOn(bool soundOn) async {
    _soundOn = soundOn;
    await _persist();
  }

  Future<void> _persist() {
    return _saveService.save(_namespace, <String, dynamic>{
      _keyLanguage: _language,
      _keySoundOn: _soundOn,
    });
  }

  /// Maps a BCP-47 primary language subtag (e.g. the `ru` in `ru-RU`) to one
  /// of the app's supported languages.
  ///
  /// `ru` -> `ru`, `de` -> `de`; anything else, including an unsupported
  /// subtag or `null`, -> `en`.
  static String resolveLanguage(String? languageCode) {
    switch (languageCode) {
      case 'ru':
        return 'ru';
      case 'de':
        return 'de';
      default:
        return 'en';
    }
  }
}
