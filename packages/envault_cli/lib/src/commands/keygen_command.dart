import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Generates a cryptographically secure master password for use as VAULT_MASTER_PASSWORD.
///
/// Run once per project:
///   envault keygen
///
/// Then store the output in your CI/CD secrets panel (GitHub Actions, Codemagic, Bitrise)
/// and in a .vault_key file for local development (gitignored).
class KeygenCommand {
  static Future<void> run(List<String> args) async {
    final random = Random.secure();
    // 48 bytes = 384 bits of entropy. Base64URL-encoded (no padding) = 64 chars.
    final bytes = Uint8List.fromList(
      List<int>.generate(48, (_) => random.nextInt(256)),
    );
    final password = base64Url.encode(bytes).replaceAll('=', '');

    stdout.writeln('');
    stdout.writeln('╔══════════════════════════════════════════════════════════════════╗');
    stdout.writeln('║         envault — Master Password Generated (384-bit)            ║');
    stdout.writeln('╚══════════════════════════════════════════════════════════════════╝');
    stdout.writeln('');
    stdout.writeln('  $password');
    stdout.writeln('');
    stdout.writeln('──────────────────────────────────────────────────────────────────');
    stdout.writeln('NEXT STEPS:');
    stdout.writeln('');
    stdout.writeln('  1. LOCAL DEVELOPMENT — Save to .vault_key (gitignored):');
    stdout.writeln('       echo "$password" > .vault_key');
    stdout.writeln('       echo ".vault_key" >> .gitignore');
    stdout.writeln('');
    stdout.writeln('  2. CI/CD — Add as a secret named VAULT_MASTER_PASSWORD:');
    stdout.writeln('       GitHub Actions : Settings → Secrets → New repository secret');
    stdout.writeln('       Codemagic      : App settings → Environment variables');
    stdout.writeln('       Bitrise        : Workflow → Secrets');
    stdout.writeln('');
    stdout.writeln('  3. GENERATE YOUR VAULT:');
    stdout.writeln('       envault generate');
    stdout.writeln('');
    stdout.writeln('  4. RUN / BUILD YOUR APP:');
    stdout.writeln('       flutter run --dart-define=VAULT_MASTER_PASSWORD=\$(cat .vault_key)');
    stdout.writeln('       flutter build apk --dart-define=VAULT_MASTER_PASSWORD=\$VAULT_MASTER_PASSWORD');
    stdout.writeln('');
    stdout.writeln('  ⚠️  NEVER commit this password to git.');
    stdout.writeln('  ⚠️  NEVER hardcode it in your source code.');
    stdout.writeln('  ✅  Store a backup in your password manager (1Password, Bitwarden).');
    stdout.writeln('  ✅  Rotating? Run envault generate again with the new password,');
    stdout.writeln('      then rebuild. Old installed apps continue working until updated.');
    stdout.writeln('──────────────────────────────────────────────────────────────────');
    stdout.writeln('');
  }
}
