# envault

If you decompile a Flutter app built with `envied` or `flutter_dotenv` today, you can extract its API keys in about 60 seconds using the `strings` command or a basic XOR reversal script. 

`envault` was built to fix this. It’s a secret management package that uses actual cryptography (AES-256-GCM) instead of obfuscation, ensuring your keys are never stored in your binary in any reversible form.

[![Pub Version](https://img.shields.io/pub/v/envault)](https://pub.dev/packages/envault)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

[Read the Technical Whitepaper (PDF)](https://smallpdf.com/file#s=5ad5c618-a4e1-44eb-8e43-5097da5328c3)

## Why existing solutions fail at scale

1. **`flutter_dotenv`**: Ships your `.env` file as a plaintext asset inside the APK/IPA. This isn't security; it's a configuration file.
2. **`envied`**: Bakes secrets into your Dart code using XOR obfuscation. XOR is a toy cipher. It’s trivial to extract the key and ciphertext via static analysis. Furthermore, it relies on `build_runner`, which severely degrades build times on large projects with lots of Freezed/JSON-serializable models.
3. **`flutter_secure_storage`**: Great for storing user tokens *at runtime*, but useless for compile-time secrets (like Stripe publishable keys or Maps API keys) because hardware keystores can't be pre-seeded at compile time.

## How `envault` works

`envault` shifts the paradigm from "obfuscate the string" to "encrypt the string and derive the key at runtime."

1. **Standalone CLI (Zero `build_runner`)**: You run `envault generate`. It parses your `.env`, encrypts the values, and spits out a single Dart file. It doesn't touch your 150 Freezed models.
2. **AES-256-GCM**: Every secret gets its own 96-bit CSPRNG IV and is encrypted using NIST-standard AES-GCM. 
3. **Derived Keys, Not Stored Keys**: The master key is *never* stored in the binary. It’s derived at runtime via PBKDF2 (310,000 iterations). 
4. **Hardware Acceleration**: We delegate decryption to the OS (`java.security` on Android, `CryptoKit` on iOS 13+) via `cryptography_flutter`, preventing timing side-channel attacks and avoiding UI thread blocks.
5. **Memory Safety (`SecureString`)**: Decrypted secrets are accessed via a scoped `.use()` callback. Once the closure finishes, the string reference is dropped, making it instantly eligible for Dart's Garbage Collector.

## Installation

```yaml
# pubspec.yaml
dependencies:
  envault: ^0.1.0
  cryptography_flutter: ^2.3.4 # Required for hardware-accelerated decryption
```

Install the generator globally:
```bash
dart pub global activate envault_cli
```

## Usage

1. **Initialize hardware crypto** in your `main.dart`:
```dart
import 'package:cryptography_flutter/cryptography_flutter.dart';

void main() {
  FlutterCryptography.enable(); // Ensures we use OS-level crypto APIs
  runApp(const MyApp());
}
```

2. **Define your vault** in `vault.dart`:
```dart
import 'package:envault/envault.dart';

part 'vault.g.dart';

@VaultEnv(path: '.env')
abstract class Vault {
  @VaultField(varName: 'API_KEY')
  static SecureString get apiKey => _Vault.apiKey;
}
```

3. **Generate the code**:
```bash
envault generate
```
*(Note: If your `.env` isn't in your `.gitignore`, the CLI will aggressively warn you or fail the build depending on your strictness settings).*

4. **Access securely**:
Because decryption involves a 310k-iteration PBKDF2 key derivation (cached after the first run) and AES math, accessing a secret is asynchronous. This physically prevents frame drops on the UI thread.

```dart
// The .use() method guarantees the plaintext string doesn't leak into logs.
// Calling print(Vault.apiKey) just prints '[REDACTED:SecureString]'.

final headers = {
  'Authorization': await Vault.apiKey.use((key) => 'Bearer $key')
};
```

## CI/CD Validation

Before committing, run:
```bash
envault validate
```
This checks your `.env` against Shannon entropy thresholds and regex heuristics to ensure you aren't accidentally checking in placeholder values like `YOUR_API_KEY_HERE`.

## Security & Architecture Documentation

To ensure `envault` meets enterprise and fintech standards, we maintain detailed documentation on our threat models, compliance, and security disclosures.

* 📄 **[Technical Whitepaper (PDF)](https://smallpdf.com/file#s=5ad5c618-a4e1-44eb-8e43-5097da5328c3)** - Cryptographic pipeline and memory safety analysis.
* 🛡️ **[Threat Model](https://github.com/gunjan1sharma/envault/blob/main/THREAT_MODEL.md)** - What we protect against (and what we don't).
* 📜 **[Compliance (PCI-DSS, MASVS)](https://github.com/gunjan1sharma/envault/blob/main/COMPLIANCE.md)** - Security standard mappings for auditors.
* 🔒 **[Security Policy](https://github.com/gunjan1sharma/envault/blob/main/SECURITY.md)** - Vulnerability disclosure and reporting guidelines.
* 📦 **[Migration Guide](https://github.com/gunjan1sharma/envault/blob/main/MIGRATION.md)** - How to migrate from `envied` or `flutter_dotenv`.

## Limitations

**What this protects against:**
- Static analysis (`strings app.apk`, `apktool`).
- Log leakage (Crashlytics, Sentry, Datadog).
- Accidental GitHub commits of `.env` files.

**What this does NOT protect against:**
- **Arbitrary Memory Reads (Frida/Rooted devices)**: If an attacker roots the device and hooks the Dart VM, they can read the heap. Dart strings are immutable and cannot be manually zeroed via C-style `memset`. If you need absolute zero-trust memory wiping, you need an FFI-based RASP (Runtime Application Self-Protection) solution. `envault` secures the resting state and greatly reduces the memory attack surface, but it is bound by the laws of the Dart VM.
