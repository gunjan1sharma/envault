# PCI-DSS v4.0 & OWASP MASVS v2 Alignment

`envault` is designed to help Flutter applications meet strict regulatory compliance requirements for secret management.

## PCI-DSS v4.0

| Requirement | How `envault` helps |
|-------------|---------------------|
| **Req 3.5.1.1** (Store keys securely) | Keys are not stored in the binary. They are derived dynamically via PBKDF2-HMAC-SHA256 at runtime. |
| **Req 3.5.1.2** (Key-encrypting keys) | The master CI key never enters the final APK/IPA, acting effectively as a zero-trust model for the artifact itself. |
| **Req 6.2.2** (Prevent information leakage) | `SecureString` overrides `toString()` and `toJson()`, physically preventing secrets from leaking into Crashlytics, DataDog, or Sentry logs. |

## OWASP MASVS v2

| Control | How `envault` helps |
|---------|---------------------|
| **MASVS-CRYPTO-1** | Uses AES-256-GCM (NIST FIPS 197) with a 96-bit OS CSPRNG IV per field. No ECB mode, no static IVs. |
| **MASVS-CRYPTO-2** | Uses PBKDF2 with 310,000 iterations (NIST SP 800-132 compliant). |
| **MASVS-STORAGE-2** | Ciphertext is opaque to static analysis (`strings` command) and decompilation. |
| **MASVS-RESILIENCE-1** (Optional) | Setting `rasp: true` prevents decryption on rooted/jailbroken devices (in development). |

*Note: Compliance is a shared responsibility. `envault` secures the client-side resting state and memory usage, but you must still practice secure transmission (TLS 1.3) and secure backend architectures.*
