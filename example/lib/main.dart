import 'package:flutter/material.dart';
import 'vault.dart';

/// Entry point — demonstrates the full envault security contract.
///
/// To run this example:
///   flutter run \
///     --dart-define=VAULT_MASTER_PASSWORD="envault-example-demo-key-do-not-use-in-production-v1"
///
/// In production:
///   flutter build apk \
///     --dart-define=VAULT_MASTER_PASSWORD=$VAULT_MASTER_PASSWORD
///
/// VAULT_MASTER_PASSWORD must NEVER be hardcoded in source code.
/// Use CI/CD secrets (GitHub Actions, Codemagic, Bitrise) in production.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // assertVaultPassword() verifies two things before the app starts:
  //   1. VAULT_MASTER_PASSWORD was provided via --dart-define at build time.
  //   2. The password fingerprint in vault.g.dart matches the runtime password.
  //
  // A mismatch means you ran `envault generate` and `flutter build` with different
  // passwords. This is caught HERE, at startup, not silently later during decryption.
  //
  // If this throws VaultConfigurationException, fix by running:
  //   envault generate (with the correct VAULT_MASTER_PASSWORD)
  //   flutter run --dart-define=VAULT_MASTER_PASSWORD=<same password>
  await assertVaultPassword();

  runApp(const EnvaultExampleApp());
}

class EnvaultExampleApp extends StatelessWidget {
  const EnvaultExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'envault Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
        useMaterial3: true,
      ),
      home: const VaultDemoPage(),
    );
  }
}

class VaultDemoPage extends StatelessWidget {
  const VaultDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('envault — Secure Secret Access'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The values below are decrypted at runtime from AES-256-GCM ciphertext.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _SecureField(
              label: 'API Key (length only — never printed)',
              // .use() is the ONLY way to access the plaintext.
              // print(Vault.apiKey) would print '[REDACTED:SecureString]'.
              future: Vault.apiKey.use((v) async => 'Length: ${v.length} chars'),
            ),
            const SizedBox(height: 16),
            _SecureField(
              label: 'Another Key (length only)',
              future:
                  Vault.anotherKey.use((v) async => 'Length: ${v.length} chars'),
            ),
            const SizedBox(height: 32),
            const _SecurityNote(),
          ],
        ),
      ),
    );
  }
}

class _SecureField extends StatelessWidget {
  const _SecureField({required this.label, required this.future});

  final String label;
  final Future<String> future;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Row(
                    children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Deriving key and decrypting...'),
                    ],
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  );
                }
                return Text(
                  snapshot.data ?? '',
                  style: const TextStyle(fontFamily: 'monospace'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('✅ Security Properties Active',
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('• Secrets encrypted with AES-256-GCM'),
          Text('• Key derived via PBKDF2 (310,000 iterations)'),
          Text('• Master password never in source code'),
          Text('• Password fingerprint verified at startup'),
          Text('• print(Vault.apiKey) → [REDACTED:SecureString]'),
        ],
      ),
    );
  }
}
