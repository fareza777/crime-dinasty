import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'save_service.dart';

Future<void> saveFsWrite(String name, String json) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/$name').writeAsString(json);
  } catch (_) {
    webSessionSaves[name] = json;
  }
}

Future<String?> saveFsRead(String name) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    if (file.existsSync()) return file.readAsStringSync();
  } catch (_) {}
  return webSessionSaves[name];
}
