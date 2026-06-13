import 'dart:math';
import 'package:envault/envault.dart';

class EncryptedSecret {
  const EncryptedSecret({
    required this.ciphertext,
    required this.iv,
    required this.tag,
    required this.fieldName,
  });

  final Uint8List ciphertext;
  final Uint8List iv;
  final Uint8List tag;
  final String fieldName;
}

class VaultEncryptor {
  /// Encrypts [plaintext] with AES-256-GCM.
  static Future<EncryptedSecret> encrypt({
    required Uint8List key,
    required String plaintext,
    required String fieldName,
  }) async {
    final iv = _generateIV();
    final algorithm = AesGcm.with256bits(nonceLength: 12);
    final secretKey = SecretKey(key);
    final aad = utf8.encode(fieldName);
    
    final box = await algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: iv,
      aad: aad,
    );
    
    return EncryptedSecret(
      ciphertext: Uint8List.fromList(box.cipherText),
      iv: iv,
      tag: Uint8List.fromList(box.mac.bytes),
      fieldName: fieldName,
    );
  }
  
  /// Decrypts [EncryptedSecret] with AES-256-GCM.
  static Future<String> decrypt({
    required Uint8List key,
    required EncryptedSecret secret,
  }) async {
    final algorithm = AesGcm.with256bits(nonceLength: 12);
    final secretKey = SecretKey(key);
    final aad = utf8.encode(secret.fieldName);
    
    final secretBox = SecretBox(
      secret.ciphertext,
      nonce: secret.iv,
      mac: Mac(secret.tag),
    );
    
    try {
      final decryptedBytes = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
        aad: aad,
      );
      return utf8.decode(decryptedBytes);
    } catch (e) {
      throw const VaultDecryptionException('Failed to decrypt secret or tag authentication failed.');
    }
  }

  static Uint8List _generateIV() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(12, (_) => random.nextInt(256)),
    );
  }
}
