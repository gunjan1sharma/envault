import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'vault_exception.dart';

/// A type-safe wrapper for sensitive string values.
/// 
/// SECURITY MODEL:
/// - toString() always returns '[REDACTED:SecureString]' — safe for all logging frameworks
/// - toJson() always returns '[REDACTED:SecureString]' — prevents JSON leak
/// - Accessing via .use() creates a temporary String on the Dart heap
///   which is GC-eligible after the scope exits.
///
/// CORRECT USAGE:
///   // ✅ Safe — sends header without creating a String in caller's scope
///   headers['Authorization'] = await Env.apiKey.use((v) => 'Bearer $v');
///
/// INCORRECT USAGE:
///   // ❌ Logs '[REDACTED:SecureString]' — safe, but potentially confusing
///   print(Env.apiKey);
import 'dart:async';
final class SecureString {
  /// Internal constructor. Do not use directly.
  /// Used by generated code.
  @internal
  const SecureString({
    required Uint8List ciphertext,
    required Uint8List iv,
    required Uint8List tag,
    required String fieldName,
    required String kid,
    required String packageName,
    required Future<String> Function(
      Uint8List ciphertext,
      Uint8List iv,
      Uint8List tag,
      String fieldName,
      String kid,
      String packageName,
    ) decryptor,
  })  : _ciphertext = ciphertext,
        _iv = iv,
        _tag = tag,
        _fieldName = fieldName,
        _kid = kid,
        _packageName = packageName,
        _decryptor = decryptor;

  final Uint8List _ciphertext;
  final Uint8List _iv;
  final Uint8List _tag;
  final String _fieldName;
  final String _kid;
  final String _packageName;
  final Future<String> Function(
    Uint8List ciphertext,
    Uint8List iv,
    Uint8List tag,
    String fieldName,
    String kid,
    String packageName,
  ) _decryptor;

  /// NEVER returns the actual value. Safe to use in any log/error context.
  @override
  String toString() => '[REDACTED:SecureString]';

  /// Prevents accidental JSON serialization of secrets.
  String toJson() => '[REDACTED:SecureString]';

  /// Runs [callback] with the decrypted value. The String is eligible
  /// for GC as soon as [callback] returns. Do not store the value.
  Future<T> use<T>(FutureOr<T> Function(String value) callback) async {
    final value = await _decryptor(
      _ciphertext,
      _iv,
      _tag,
      _fieldName,
      _kid,
      _packageName,
    );
    try {
      return await callback(value);
    } finally {
      // We rely on Dart's GC since we can't manually zero strings in Dart.
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw VaultSecurityException(
      'Attempted to call ${invocation.memberName} on SecureString. '
      'You must use await .use((v) => ...) to access the underlying value.',
    );
  }
}
