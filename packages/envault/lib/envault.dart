/// envault — Fintech-grade secret management for Flutter/Dart.
///
/// Usage:
/// ```dart
/// import 'package:envault/envault.dart';
///
/// part 'vault.g.dart';
///
/// @VaultEnv(path: '.env')
/// abstract class Vault {
///   @VaultField(varName: 'API_KEY', minEntropyBits: 128)
///   static SecureString get apiKey => _Vault.apiKey;
/// }
/// ```
library envault;

export 'src/annotations.dart';
export 'src/secure_string.dart';
export 'src/vault_exception.dart';
export 'src/obfuscation_level.dart';
export 'src/git_ignore_check.dart';
export 'src/secret_validator.dart';

// Exports required by generated code so the user doesn't have to import them manually.
export 'dart:convert' show utf8;
export 'dart:typed_data' show Uint8List;
export 'package:cryptography/cryptography.dart';
