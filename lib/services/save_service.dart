import 'dart:convert';

import '../models/game_models.dart';
import 'save_fs.dart';

class SaveMeta {
  SaveMeta({
    required this.slot,
    required this.dynasty,
    required this.leader,
    required this.year,
    required this.generation,
    required this.age,
    required this.updatedMs,
    this.autosave = false,
  });

  final int slot;
  final String dynasty;
  final String leader;
  final int year;
  final int generation;
  final int age;
  final int updatedMs;
  final bool autosave;

  String get label => '$leader · Gen $generation · $year · age $age';
}

class SaveService {
  // ignore: prefer_initializing_formals
  SaveService({Map<String, String>? memory}) : _memory = memory;

  final Map<String, String>? _memory;
  static const slotCount = 3;

  String _name(int slot) => slot == 0 ? 'autosave.json' : 'slot_$slot.json';

  Future<void> write(int slot, GameState state) async {
    final json = jsonEncode(state.toJson());
    if (_memory != null) {
      _memory[_name(slot)] = json;
      return;
    }
    await saveFsWrite(_name(slot), json);
  }

  Future<GameState?> read(int slot) async {
    String? json;
    if (_memory != null) {
      json = _memory[_name(slot)];
    } else {
      json = await saveFsRead(_name(slot));
    }
    if (json == null || json.isEmpty) return null;
    try {
      return GameState.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<SaveMeta?> meta(int slot) async {
    final s = await read(slot);
    if (s == null) return null;
    return SaveMeta(
      slot: slot,
      dynasty: s.dynastyName,
      leader: s.player.name,
      year: s.year,
      generation: s.generation,
      age: s.age,
      updatedMs: DateTime.now().millisecondsSinceEpoch,
      autosave: slot == 0,
    );
  }

  Future<List<SaveMeta?>> list() async {
    return [await meta(0), await meta(1), await meta(2), await meta(3)];
  }
}

final webSessionSaves = <String, String>{};
