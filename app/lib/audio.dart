import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:puzzle_core/puzzle_core.dart';

/// [AudioService] backed by the `audioplayers` plugin, playing the bundled
/// WAV assets under `assets/sfx/`.
///
/// One [AudioPlayer] is created per [Sfx] value, lazily, the first time
/// that effect is played. Playback is always fire-and-forget and never
/// throws — a missing asset, unavailable audio device, or disposed player
/// is swallowed, since SFX are best-effort and must never crash gameplay.
/// If an effect is re-triggered while still playing (e.g. rapid digit
/// entry), it is restarted from the beginning rather than layered, so
/// repeated input stays snappy and audible.
class AudioPlayersAudioService implements AudioService {
  /// Creates an audio service. [isSoundOn] is read fresh on every [play]
  /// call (not cached), so toggling the sound setting takes effect
  /// immediately without needing to reconstruct this service.
  AudioPlayersAudioService({required bool Function() isSoundOn}) {
    _isSoundOn = isSoundOn;
  }

  late final bool Function() _isSoundOn;
  final Map<Sfx, AudioPlayer> _players = {};

  static const Map<Sfx, String> _assetPaths = {
    Sfx.tap: 'sfx/tap.wav',
    Sfx.place: 'sfx/place.wav',
    Sfx.error: 'sfx/error.wav',
    Sfx.win: 'sfx/win.wav',
  };

  @override
  void play(Sfx sfx) {
    if (!_isSoundOn()) return;
    unawaited(_play(sfx));
  }

  Future<void> _play(Sfx sfx) async {
    try {
      final player = _playerFor(sfx);
      // Restart from the top if this effect is already playing/queued, so
      // rapid re-triggers (e.g. fast digit entry) stay responsive instead
      // of overlapping or queuing up.
      await player.stop();
      await player.play(AssetSource(_assetPaths[sfx]!));
    } catch (_) {
      // Best-effort: missing asset, no audio device, disposed player, etc.
      // must never crash gameplay.
    }
  }

  AudioPlayer _playerFor(Sfx sfx) {
    return _players.putIfAbsent(sfx, () {
      final player = AudioPlayer(playerId: 'sfx_${sfx.name}');
      // Low-latency mode suits short one-shot effects (backed by
      // SoundPool on Android); harmless on platforms that ignore it.
      unawaited(player.setPlayerMode(PlayerMode.lowLatency).catchError((_) {}));
      unawaited(player.setReleaseMode(ReleaseMode.stop).catchError((_) {}));
      return player;
    });
  }

  /// Releases every player created so far. Call when whatever owns this
  /// service is itself being torn down (e.g. a Riverpod `ref.onDispose`).
  Future<void> dispose() async {
    final players = _players.values.toList();
    _players.clear();
    for (final player in players) {
      try {
        await player.dispose();
      } catch (_) {
        // Best-effort cleanup.
      }
    }
  }
}
