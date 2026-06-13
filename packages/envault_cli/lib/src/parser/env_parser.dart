import 'dart:io';

class EnvParser {
  /// Parses a .env file and returns a map of key-value pairs.
  static Future<Map<String, String>> parse(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Environment file not found: $filePath');
    }

    final lines = await file.readAsLines();
    final result = <String, String>{};

    for (var line in lines) {
      line = line.trim();
      
      // Skip empty lines and comments
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      // Handle inline comments
      final commentIdx = line.indexOf(' #');
      if (commentIdx != -1) {
        line = line.substring(0, commentIdx).trim();
      }

      final separatorIdx = line.indexOf('=');
      if (separatorIdx == -1) {
        continue; // Invalid format
      }

      final key = line.substring(0, separatorIdx).trim();
      var value = line.substring(separatorIdx + 1).trim();

      // Handle quotes
      if (value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
        value = value.replaceAll('\\n', '\n');
      } else if (value.startsWith("'") && value.endsWith("'")) {
        value = value.substring(1, value.length - 1);
      }

      result[key] = value;
    }

    return result;
  }
}
