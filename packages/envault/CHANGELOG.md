## 0.1.1

* Added link to the official architectural whitepaper.

## 0.1.0

* Initial release of envault.
* Introduced AES-256-GCM encryption for secrets.
* Added `SecureString` with `.use()` scope to prevent log leakage.
* Implemented PBKDF2 derived keys at runtime (master key not stored in binary).
* Integrated hardware acceleration via `cryptography_flutter`.
