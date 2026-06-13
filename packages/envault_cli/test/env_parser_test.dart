import 'dart:io';
import 'package:test/test.dart';
import 'package:envault_cli/src/parser/env_parser.dart';

void main() {
  group('EnvParser', () {
    late File tempFile;

    setUp(() {
      tempFile = File('test_temp.env');
    });

    tearDown(() {
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
    });

    test('parses basic key-value pairs', () async {
      await tempFile.writeAsString('''
KEY1=value1
KEY2=value2
''');
      final result = await EnvParser.parse(tempFile.path);
      expect(result['KEY1'], equals('value1'));
      expect(result['KEY2'], equals('value2'));
    });

    test('ignores comments and empty lines', () async {
      await tempFile.writeAsString('''
# This is a comment

KEY1=value1
  # Another comment
KEY2=value2 # inline comment
''');
      final result = await EnvParser.parse(tempFile.path);
      expect(result.length, equals(2));
      expect(result['KEY1'], equals('value1'));
      expect(result['KEY2'], equals('value2'));
    });

    test('handles quotes correctly', () async {
      await tempFile.writeAsString('''
KEY1="value with spaces"
KEY2='single quotes'
KEY3="line1\\nline2"
''');
      final result = await EnvParser.parse(tempFile.path);
      expect(result['KEY1'], equals('value with spaces'));
      expect(result['KEY2'], equals('single quotes'));
      expect(result['KEY3'], equals('line1\nline2'));
    });
  });
}
