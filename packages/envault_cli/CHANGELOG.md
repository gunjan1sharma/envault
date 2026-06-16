## 1.0.1

* **FIX:** Resolved a compilation error in generated `vault.g.dart` caused by string interpolation (`$YOUR_SECRET`) in error messages.

## 1.0.0 — First Stable Release (Breaking Security Fix)

> ⚠️ **BREAKING:** All existing `vault.g.dart` files must be regenerated after upgrading.
> Run `envault generate` with your `VAULT_MASTER_PASSWORD`.

* **CRITICAL SECURITY FIX:** Removed `fallback_zero_config_key` from generated code.
* Added `envault keygen` command — generates a 384-bit cryptographically secure master password.
* `envault generate` now requires `VAULT_MASTER_PASSWORD` or a `.vault_key` file.
  No password → hard failure with clear setup instructions. No silent fallback.
* Fingerprint embedded in generated code for startup mismatch detection.
* Added `.vault_key` gitignore enforcement to prevent accidental password commits.
* Added CI/CD templates in `docs/ci_cd/` for GitHub Actions and Codemagic.

## 0.1.2

* Updated documentation links in README.

## 0.1.1

* Added link to the official architectural whitepaper.

## 0.1.0

* Initial release of envault_cli.
* Fast, standalone CLI generator (no `build_runner` required).
* Extracts .env, checks entropy/placeholders via `envault validate`.
* Emits securely encrypted `vault.g.dart` using AES-256-GCM.
