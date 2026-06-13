import 'package:test/test.dart';
import 'package:envault_cli/src/validator/entropy_checker.dart';

void main() {
  group('EntropyChecker', () {
    test('calculateBits handles empty strings', () {
      expect(EntropyChecker.calculateBits(''), equals(0));
    });

    test('calculates correct entropy for lowercase only', () {
      final bits = EntropyChecker.calculateBits('abcdef');
      // length 6, charset 26. log2(26^6) ≈ 28.2
      expect(bits, equals(28));
    });

    test('calculates correct entropy for complex string', () {
      final bits = EntropyChecker.calculateBits('aB1!eF9@');
      // length 8, charset 26+26+10+32 = 94. log2(94^8) ≈ 52.4
      expect(bits, equals(52));
    });

    test('validate returns error if below minBits', () {
      final error = EntropyChecker.validate('API_KEY', 'abc', 64);
      expect(error, isNotNull);
      expect(error, contains('minimum 64 required'));
    });

    test('validate returns null if above minBits', () {
      final error = EntropyChecker.validate('API_KEY', 'aB1!eF9@aB1!eF9@', 64); // ~104 bits
      expect(error, isNull);
    });
  });
}
