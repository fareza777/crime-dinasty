import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioService {
  AudioService();

  AudioPlayer? _sfx;
  AudioPlayer? _music;
  bool sfxOn = true;
  bool musicOn = true;
  bool haptics = true;
  double sfxVolume = 0.55;
  double musicVolume = 0.28;
  String _bed = 'docks';

  bool get enabled => sfxOn;
  set enabled(bool v) => sfxOn = v;

  AudioPlayer? _sfxPlayer() {
    if (_sfx != null) return _sfx;
    try {
      _sfx = AudioPlayer();
    } catch (e) {
      debugPrint('AudioPlayer unavailable: $e');
      return null;
    }
    return _sfx;
  }

  Future<void> startMusic() async {
    await setBed(_bed);
  }

  Future<void> setBed(String bed) async {
    if (!musicOn) {
      _bed = bed;
      return;
    }
    final file = switch (bed) {
      'war' => 'music/war.wav',
      'prison' => 'music/prison.wav',
      _ => 'music/ambience.wav',
    };
    final restart = _bed != bed || _music == null;
    _bed = bed;
    try {
      _music ??= AudioPlayer();
      await _music!.setReleaseMode(ReleaseMode.loop);
      await _music!.setPlayerMode(PlayerMode.mediaPlayer);
      final vol = bed == 'prison'
          ? musicVolume * 0.62
          : (bed == 'war' ? (musicVolume * 1.18).clamp(0.0, 1.0) : musicVolume);
      await _music!.setVolume(vol);
      if (restart) {
        await _music!.play(AssetSource(file));
      }
    } catch (e) {
      debugPrint('music skipped: $e');
      if (file != 'music/ambience.wav') {
        try {
          await _music?.play(AssetSource('music/ambience.wav'));
        } catch (_) {}
      }
    }
  }

  Future<void> stopMusic() async {
    try {
      await _music?.stop();
    } catch (_) {}
  }

  Future<void> setSfxOn(bool on) async {
    sfxOn = on;
  }

  Future<void> setSfxVolume(double v) async {
    sfxVolume = v.clamp(0, 1);
  }

  Future<void> setMusicOn(bool on) async {
    musicOn = on;
    if (on) {
      final bed = _bed.isEmpty ? 'docks' : _bed;
      _bed = '';
      await setBed(bed);
    } else {
      await stopMusic();
    }
  }

  Future<void> setMusicVolume(double v) async {
    musicVolume = v.clamp(0, 1);
    try {
      await _music?.setVolume(musicOn ? musicVolume : 0);
    } catch (_) {}
  }

  Future<void> duckForVo() async {
    try {
      if (_music != null && musicOn) {
        await _music!.setVolume((musicVolume * 0.16).clamp(0.0, 1.0));
      }
    } catch (_) {}
  }

  Future<void> unduck() async {
    try {
      if (_music != null) {
        final vol = _bed == 'prison'
            ? musicVolume * 0.62
            : (_bed == 'war' ? (musicVolume * 1.18).clamp(0.0, 1.0) : musicVolume);
        await _music!.setVolume(musicOn ? vol : 0);
      }
    } catch (_) {}
  }

  Future<void> play(String name, {double? volume}) async {
    if (!sfxOn) return;
    try {
      final player = _sfxPlayer();
      if (player != null) {
        await player.stop();
        await player.play(AssetSource('sfx/$name.wav'), volume: volume ?? sfxVolume);
      }
    } catch (_) {}
    if (haptics && !kIsWeb) {
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {}
    }
  }

  Future<void> tap() => play('tap', volume: 0.4);
  Future<void> success() => play('success');
  Future<void> confirm() => play('confirm');
  Future<void> money() => play('money');
  Future<void> heat() => play('heat');
  Future<void> fail() async {
    await heavy();
    await play('fail');
  }

  Future<void> year() => play('year');

  Future<void> legacy() async {
    await heavy();
    await play('legacy');
  }

  Future<void> card() => play('card');

  Future<void> heavy() async {
    if (haptics && !kIsWeb) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }
  }

  Future<void> disposePlayers() async {
    try {
      await _sfx?.dispose();
    } catch (_) {}
    try {
      await _music?.dispose();
    } catch (_) {}
    _sfx = null;
    _music = null;
  }
}
