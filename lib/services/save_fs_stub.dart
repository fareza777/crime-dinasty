final _mem = <String, String>{};

Future<void> saveFsWrite(String name, String json) async {
  _mem[name] = json;
}

Future<String?> saveFsRead(String name) async => _mem[name];
