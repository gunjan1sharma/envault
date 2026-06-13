# Migration Guide

## From `envied`

`envault` is designed to be a drop-in replacement for `envied` with superior security and developer experience.

### Step 1: Replace Dependencies
Remove `envied` and `envied_generator`. Add `envault`.

```yaml
# pubspec.yaml
dependencies:
-  envied: ^0.5.4
+  envault: ^1.0.0

dev_dependencies:
-  envied_generator: ^0.5.4
-  build_runner: ^2.4.6
```

### Step 2: Update Code
Change the imports and annotations.

```dart
- import 'package:envied/envied.dart';
+ import 'package:envault/envault.dart';

- part 'env.g.dart';
+ part 'vault.g.dart'; // Note the filename change

- @Envied(path: '.env', obfuscate: true)
+ @VaultEnv(path: '.env')
  abstract class Env {
-   @EnviedField(varName: 'API_KEY', obfuscate: true)
-   static final String apiKey = _Env.apiKey;
+   @VaultField(varName: 'API_KEY')
+   static SecureString get apiKey => _Vault.apiKey;
  }
```

### Step 3: Update Usage
Because `envault` returns a `SecureString`, you must use the `.use()` callback pattern to access the plaintext.

```dart
// OLD:
// final headers = {'Authorization': 'Bearer ${Env.apiKey}'};

// NEW:
final headers = {
  'Authorization': Env.apiKey.use((key) => 'Bearer $key')
};
```

### Step 4: Generate Code
Instead of running `build_runner` (which is slow and often conflicts with other generators), use the blazing fast `envault_cli`.

```bash
dart pub global activate envault_cli
envault generate
```

## From `flutter_dotenv`

`flutter_dotenv` ships your `.env` file as a plaintext asset inside the app bundle. This is extremely insecure.

### Step 1: Remove Asset
Remove the `.env` file from the `assets:` section of your `pubspec.yaml`.

### Step 2: Add `envault`
See Step 1 and 2 above.

### Step 3: Remove async initialization
`flutter_dotenv` requires `await dotenv.load()`. `envault` is synchronous and requires no initialization. Remove `await dotenv.load()` from your `main()`.
