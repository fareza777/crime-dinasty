import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_service.dart';

class VoiceLine {
  const VoiceLine({required this.text, required this.start, required this.end});
  final String text;
  final double start;
  final double end;
}

class VoiceClip {
  const VoiceClip({required this.id, required this.asset, required this.lines});
  final String id;
  final String asset;
  final List<VoiceLine> lines;

  double get duration => lines.isEmpty ? 0 : lines.last.end;
}

class VoiceOverService extends ChangeNotifier {
  VoiceOverService(this.audio);

  final AudioService audio;
  final AudioPlayer _player = AudioPlayer();

  static const ids = <String>[
    'opening',
    'prologue_rain',
    'prologue_heat',
    'prologue_loyalty',
    'prologue_name',
    'war_threat_card',
    'war_escalate_card',
    'war_resolve_card',
    'detective_card',
    'heir_rise',
  ];

  final Map<String, VoiceClip> clips = {};
  VoiceClip? current;
  Duration position = Duration.zero;
  bool playing = false;
  bool loaded = false;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<void>? _doneSub;
  Timer? _fake;

  VoiceLine? get activeLine {
    final clip = current;
    if (clip == null || clip.lines.isEmpty) return null;
    final t = position.inMilliseconds / 1000.0;
    for (final line in clip.lines) {
      if (t >= line.start && t < line.end + 0.12) return line;
    }
    VoiceLine? last;
    for (final line in clip.lines) {
      if (line.start <= t) last = line;
    }
    return last;
  }

  bool has(String id) => clips.containsKey(id);

  Future<void> preload() async {
    if (loaded) return;
    loaded = true;
    for (final id in ids) {
      try {
        final raw = await rootBundle.loadString('assets/vo/$id.json');
        final j = jsonDecode(raw) as Map<String, dynamic>;
        final lines = ((j['lines'] as List?) ?? [])
            .map((e) => VoiceLine(
                  text: '${(e as Map)['text']}',
                  start: ((e['start'] as num?) ?? 0).toDouble(),
                  end: ((e['end'] as num?) ?? 0).toDouble(),
                ))
            .toList();
        clips[id] = VoiceClip(
          id: id,
          asset: '${j['asset'] ?? 'vo/$id.mp3'}',
          lines: lines,
        );
      } catch (_) {}
    }
  }

  Future<void> play(String id) async {
    await stop();
    var clip = clips[id];
    if (clip == null) {
      await preload();
      clip = clips[id];
    }
    if (clip == null) return;
    current = clip;
    position = Duration.zero;
    playing = true;
    notifyListeners();
    await audio.duckForVo();
    _posSub = _player.onPositionChanged.listen((p) {
      position = p;
      notifyListeners();
    });
    _doneSub = _player.onPlayerComplete.listen((_) {
      playing = false;
      position = Duration(milliseconds: ((clip!.duration + 0.2) * 1000).round());
      notifyListeners();
      unawaited(audio.unduck());
    });
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(AssetSource(clip.asset));
    } catch (e) {
      debugPrint('VO asset skipped: $e');
      _fakePlay(clip);
    }
  }

  void _fakePlay(VoiceClip clip) {
    final total = Duration(milliseconds: ((clip.duration + 0.4) * 1000).round());
    _fake?.cancel();
    _fake = Timer.periodic(const Duration(milliseconds: 80), (t) {
      position += const Duration(milliseconds: 80);
      notifyListeners();
      if (position >= total) {
        t.cancel();
        playing = false;
        notifyListeners();
        unawaited(audio.unduck());
      }
    });
  }

  Future<void> stop() async {
    _fake?.cancel();
    _fake = null;
    await _posSub?.cancel();
    await _doneSub?.cancel();
    _posSub = null;
    _doneSub = null;
    try {
      await _player.stop();
    } catch (_) {}
    if (playing) unawaited(audio.unduck());
    playing = false;
    current = null;
    position = Duration.zero;
    notifyListeners();
  }

  Future<void> disposePlayer() async {
    await stop();
    await _player.dispose();
  }
}
