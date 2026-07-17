/// Sound effects that puzzle modules may request to be played.
enum Sfx {
  /// A generic tap/selection interaction.
  tap,

  /// A piece/value/tile being placed.
  place,

  /// An invalid action or wrong answer.
  error,

  /// A puzzle (or module) being completed successfully.
  win,
}

/// UI-agnostic audio playback seam.
///
/// The Flutter app shell provides a real implementation (backed by an
/// audio-playing plugin) starting at milestone M2. Pure-Dart packages and
/// tests use [NoopAudioService] or a test double.
abstract class AudioService {
  /// Plays the given sound effect. Implementations should not throw on
  /// missing/unavailable audio resources — playback failures are
  /// best-effort and must never crash gameplay.
  void play(Sfx sfx);
}

/// An [AudioService] that does nothing. Useful as a default/injected
/// implementation in pure-Dart contexts (tests, CLI tools) where no audio
/// backend is available.
class NoopAudioService implements AudioService {
  /// Creates a no-op audio service.
  const NoopAudioService();

  @override
  void play(Sfx sfx) {
    // Intentionally does nothing.
  }
}
