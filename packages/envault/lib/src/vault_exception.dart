/// Base exception for all envault related errors.
abstract class VaultException implements Exception {
  const VaultException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a security check fails (e.g. wrong key, tampered ciphertext, RASP failure).
class VaultSecurityException extends VaultException {
  const VaultSecurityException(super.message);
}

/// Thrown when decryption fails due to crypto errors.
class VaultDecryptionException extends VaultException {
  const VaultDecryptionException(super.message);
}
