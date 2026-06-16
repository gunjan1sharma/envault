## 1.0.0 — First Stable Release (Breaking Security Fix)

> ⚠️ **BREAKING:** All existing `vault.g.dart` files must be regenerated after upgrading.
> Run `envault generate` with your new `VAULT_MASTER_PASSWORD`.

* **CRITICAL SECURITY FIX:** Removed `fallback_zero_config_key` from generated code.
  The master key is now a per-project, CI-injected secret — never a known string.
* Master password is sourced from (priority order):
    1. `VAULT_MASTER_PASSWORD` environment variable (CI/CD)
    2. `.vault_key` local file (gitignore-enforced, local dev only)
    3. Hard failure with a clear error — no silent fallback, ever
* Added `assertVaultPassword()` function to generated `vault.g.dart`.
  Call it in `main()` before `runApp()` to detect password mismatches at startup,
  before any decryption is attempted.
* Password fingerprint (HMAC-SHA256, 8 bytes) embedded in generated code.
  Mismatch between `envault generate` and `flutter build` is caught instantly.
* Added `VaultConfigurationException` for misconfiguration errors.
* Generated code now reads password via `String.fromEnvironment('VAULT_MASTER_PASSWORD')`.
* Added `.vault_key` gitignore enforcement — blocks generation if file is not ignored.
* Added CI/CD templates in `docs/ci_cd/` for GitHub Actions and Codemagic.

## 0.1.2

* Updated documentation links (Compliance, Threat Model, Security, Migration Guide) in README.

## 0.1.1

* Added link to the official architectural whitepaper.

## 0.1.0

* Initial release of envault.
* Introduced AES-256-GCM encryption for secrets.
* Added `SecureString` with `.use()` scope to prevent log leakage.
* Implemented PBKDF2 derived keys at runtime (master key not stored in binary).
* Integrated hardware acceleration via `cryptography_flutter`.
