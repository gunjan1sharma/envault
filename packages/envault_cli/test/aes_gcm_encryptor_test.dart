import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:envault_cli/src/crypto/aes_gcm_encryptor.dart';
import 'package:envault/envault.dart';

void main() {
  group('VaultEncryptor', () {
    final mockKey = Uint8List.fromList(List.generate(32, (i) => i));

    test('encrypt and decrypt roundtrip works', () async {
      final secret = await VaultEncryptor.encrypt(
        key: mockKey,
        plaintext: 'my_secret_data',
        fieldName: 'API_KEY',
      );
      
      final decrypted = await VaultEncryptor.decrypt(
        key: mockKey,
        secret: secret,
      );
      
      expect(decrypted, equals('my_secret_data'));
    });

    test('IV is unique across encrypt calls', () async {
      final secret1 = await VaultEncryptor.encrypt(
        key: mockKey,
        plaintext: 'data',
        fieldName: 'KEY1',
      );
      
      final secret2 = await VaultEncryptor.encrypt(
        key: mockKey,
        plaintext: 'data',
        fieldName: 'KEY2',
      );
      
      expect(secret1.iv, isNot(equals(secret2.iv)));
    });

    test('decrypt with wrong key throws VaultDecryptionException', () async {
      final secret = await VaultEncryptor.encrypt(
        key: mockKey,
        plaintext: 'data',
        fieldName: 'API_KEY',
      );
      
      final wrongKey = Uint8List.fromList(List.generate(32, (i) => 31 - i));
      
      expect(
        () => VaultEncryptor.decrypt(key: wrongKey, secret: secret),
        throwsA(isA<VaultDecryptionException>()),
      );
    });

    test('AAD mismatch (wrong field name) throws VaultDecryptionException', () async {
      final secret = await VaultEncryptor.encrypt(
        key: mockKey,
        plaintext: 'data',
        fieldName: 'API_KEY',
      );
      
      final tamperedSecret = EncryptedSecret(
        ciphertext: secret.ciphertext,
        iv: secret.iv,
        tag: secret.tag,
        fieldName: 'OTHER_KEY', // Tampered AAD
      );
      
      expect(
        () => VaultEncryptor.decrypt(key: mockKey, secret: tamperedSecret),
        throwsA(isA<VaultDecryptionException>()),
      );
    });
  });
}
