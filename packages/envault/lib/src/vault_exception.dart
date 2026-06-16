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
/// Usually means the master password used at build time does not match
/// the password used to generate vault.g.dart.
class VaultDecryptionException extends VaultException {
  const VaultDecryptionException(super.message);
}

/// Thrown when the app is built without --dart-define=VAULT_MASTER_PASSWORD,
/// or when the runtime password fingerprint does not match the one stored in
/// vault.g.dart (password mismatch between envault generate and flutter build).
///
/// This is a BUILD-TIME configuration error, not a runtime secret issue.
///
/// Fix: Ensure you run envault generate and flutter build with the SAME password:
///   envault generate
///   flutter build apk --dart-define=VAULT_MASTER_PASSWORD=\$VAULT_MASTER_PASSWORD
///
/// See https://github.com/gunjan1sharma/envault for full setup guide.
class VaultConfigurationException extends VaultException {
  const VaultConfigurationException(super.message);
}
