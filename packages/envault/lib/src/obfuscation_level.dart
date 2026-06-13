/// The level of obfuscation/encryption applied to the secret.
enum ObfuscationLevel {
  /// Plaintext. Only use for non-secret configuration (e.g., API URLs).
  none,
  
  /// AES-256-GCM encryption with PBKDF2 derived key.
  /// The default and recommended level for secrets.
  aesGcm256,
}
