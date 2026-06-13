import 'package:test/test.dart';
import 'package:envault/envault.dart';

void main() {
  group('SecureString', () {
    final mockCiphertext = Uint8List.fromList([1, 2, 3]);
    final mockIv = Uint8List.fromList([4, 5, 6]);
    final mockTag = Uint8List.fromList([7, 8, 9]);

    Future<String> mockDecryptor(
      Uint8List ciphertext,
      Uint8List iv,
      Uint8List tag,
      String fieldName,
      String kid,
      String packageName,
    ) async {
      if (ciphertext == mockCiphertext &&
          iv == mockIv &&
          tag == mockTag &&
          fieldName == 'apiKey' &&
          kid == '2026' &&
          packageName == 'com.test') {
        return 'secret123';
      }
      throw VaultDecryptionException('Decryption failed');
    }

    SecureString createValidSecureString() {
      return SecureString(
        ciphertext: mockCiphertext,
        iv: mockIv,
        tag: mockTag,
        fieldName: 'apiKey',
        kid: '2026',
        packageName: 'com.test',
        decryptor: mockDecryptor,
      );
    }

    test('toString() returns redacted string', () {
      final secureStr = createValidSecureString();
      expect(secureStr.toString(), equals('[REDACTED:SecureString]'));
    });

    test('toJson() returns redacted string', () {
      final secureStr = createValidSecureString();
      expect(secureStr.toJson(), equals('[REDACTED:SecureString]'));
    });

    test('use() invokes callback with decrypted string', () async {
      final secureStr = createValidSecureString();
      final result = await secureStr.use((v) => 'Bearer $v');
      expect(result, equals('Bearer secret123'));
    });

    test('noSuchMethod throws VaultSecurityException', () {
      dynamic secureStr = createValidSecureString();
      expect(
        () => secureStr.length,
        throwsA(isA<VaultSecurityException>()),
      );
    });
  });
}
