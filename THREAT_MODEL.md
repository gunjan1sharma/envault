# Threat Model

This document outlines the security boundaries and assumptions of the `envault` package.

## Boundaries
1. **The build environment is trusted.** The CI runner or developer machine generating `vault.g.dart` must not be compromised.
2. **The application binary is public.** We assume attackers have full access to your APK/IPA and can decompile it.
3. **The device memory is protected by the OS.** We rely on iOS/Android memory sandboxing.

## Addressed Threats

### Threat: Strings Extraction
**Attack:** An attacker runs `strings app.apk` or uses `apktool` to find plain text secrets.
**Mitigation:** Secrets are encrypted using AES-256-GCM. The plaintext does not exist anywhere in the binary.

### Threat: Key Extraction from Code
**Attack:** An attacker decompiles the Dart code, finds the encryption key, and decrypts the ciphertext.
**Mitigation:** `envault` does NOT store the encryption key in the binary. It stores non-secret parameters (`kid`, `packageName`, `buildFlavor`). The key is derived at runtime using PBKDF2 (310,000 iterations), which requires the attacker to guess or brute-force the missing `VAULT_MASTER_KEY` (if configured in strict mode).

### Threat: Logging Leaks
**Attack:** A developer accidentally writes `print('Key: ${Vault.apiKey}')`, sending it to Crashlytics or CloudWatch.
**Mitigation:** `Vault.apiKey` returns a `SecureString`. Its `toString()` and `toJson()` methods are hardcoded to return `[REDACTED:SecureString]`.

### Threat: Git Leaks
**Attack:** A developer accidentally commits `.env.production` to GitHub.
**Mitigation:** `envault_cli` shells out to `git check-ignore` before generation. If the `.env` file is not ignored, the build fails.

## Unaddressed Threats

### Threat: Frida / Runtime Hooking
**Attack:** An attacker on a rooted device uses Frida to hook the `String` instantiation or `dart:ffi` boundaries at the exact moment `SecureString.use()` is called.
**Mitigation:** Out of scope for a package. If a device is rooted, all memory is compromised. You must use RASP (Runtime Application Self-Protection) solutions to detect rooting. (Support for basic RASP integration is planned for future versions).

### Threat: CI Compromise
**Attack:** An attacker steals the `VAULT_MASTER_KEY` from your GitHub Actions secrets.
**Mitigation:** Out of scope. Secure your CI pipelines.
