import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// SECURITY: This is the most critical piece of code in the entire package.
/// 
/// KEY DERIVATION SCHEME:
///   masterKey = PBKDF2(
///     password = VAULT_MASTER_KEY (from CI environment, never in binary),
///     salt     = SHA-256(packageName || buildFlavor || kid),
///     iterations = 310_000,  // NIST 2023 minimum for PBKDF2-HMAC-SHA256
///     keyLength  = 32,       // 256 bits for AES-256
///   )
class VaultKeyDerivation {
  static const int iterations = 310000;
  static const int keyLengthBytes = 32; // 256 bits
  
  /// Derives the AES-256 key.
  static Future<Uint8List> deriveKey({
    required String masterPassword,
    required String packageName,
    required String kid,
    required String buildFlavor,
  }) async {
    final crypto = Cryptography.instance;
    final pbkdf2 = crypto.pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: keyLengthBytes * 8,
    );
    
    // Salt: non-secret, unique per key version and package
    final saltInput = '$packageName|$buildFlavor|$kid';
    final saltHash = await crypto.sha256().hash(utf8.encode(saltInput));
    final salt = Uint8List.fromList(saltHash.bytes);
    
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(masterPassword)),
      nonce: salt,
    );
    
    return Uint8List.fromList(await secretKey.extractBytes());
  }
}
