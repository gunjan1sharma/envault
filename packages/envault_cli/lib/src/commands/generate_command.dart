import 'dart:io';
import 'package:args/args.dart';
import 'package:envault_cli/src/parser/env_parser.dart';
import 'package:envault_cli/src/crypto/key_derivation.dart';
import 'package:envault_cli/src/crypto/aes_gcm_encryptor.dart';
import 'package:envault_cli/src/generator/dart_emitter.dart';
import 'package:envault_cli/src/validator/gitignore_checker.dart';
import 'package:envault/envault.dart';


class GenerateCommand {
  static void printUsage(ArgParser parser) {
    print('Usage: envault generate [options]');
    print('');
    print('Requires VAULT_MASTER_PASSWORD to be set. Run "envault keygen" first.');
    print('');
    print(parser.usage);
  }

  static Future<void> run(List<String> args) async {
    final parser = ArgParser()
      ..addOption('env', abbr: 'e', defaultsTo: '.env', help: 'Path to .env file')
      ..addOption('out', abbr: 'o', defaultsTo: 'lib/vault.g.dart', help: 'Output path')
      ..addOption('class', abbr: 'c', defaultsTo: 'Vault', help: 'Generated class name')
      ..addOption('kid', defaultsTo: 'v1', help: 'Key ID for rotation')
      ..addOption('package', defaultsTo: 'app', help: 'Package name (AAD component)')
      ..addOption('flavor', defaultsTo: 'prod', help: 'Build flavor (AAD component)')
      ..addOption(
        'master-password',
        help: 'Master password for key derivation. '
              'Prefer VAULT_MASTER_PASSWORD env var to avoid password appearing in shell history.',
      )
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Print this usage information.');

    final ArgResults results;
    try {
      results = parser.parse(args);
    } catch (e) {
      printUsage(parser);
      exit(1);
    }

    if (results['help'] as bool) {
      printUsage(parser);
      exit(0);
    }

    final envPath = results['env'] as String;
    final outPath = results['out'] as String;
    final className = results['class'] as String;
    final kid = results['kid'] as String;
    final packageName = results['package'] as String;
    final buildFlavor = results['flavor'] as String;

    // Resolve master password — no fallback, ever.
    final masterPassword = _resolveMasterPassword(results);

    // 1. Git ignore check for .env
    await GitIgnoreChecker.enforceOrWarn(envPath, GitIgnoreCheck.warn);

    // 2. If .vault_key exists locally, enforce it's gitignored
    if (File('.vault_key').existsSync()) {
      await GitIgnoreChecker.enforceFileIgnored(
        '.vault_key',
        'Your .vault_key file contains the master password and must never be committed.',
      );
    }

    // 3. Parse .env
    final parsedSecrets = await EnvParser.parse(envPath);

    // 4. Derive key
    final derivedKey = await VaultKeyDerivation.deriveKey(
      masterPassword: masterPassword,
      packageName: packageName,
      kid: kid,
      buildFlavor: buildFlavor,
    );

    // 5. Compute password fingerprint (HMAC-SHA256 based, first 8 bytes)
    //    This is embedded in vault.g.dart so the app can detect a mismatch at startup.
    final passwordFingerprint = await _computePasswordFingerprint(masterPassword);

    // 6. Encrypt secrets
    final encryptedSecrets = <String, EncryptedSecret>{};
    for (final entry in parsedSecrets.entries) {
      final fieldName = entry.key.toLowerCase().replaceAllMapped(
        RegExp(r'_([a-z])'),
        (match) => match.group(1)!.toUpperCase(),
      );
      encryptedSecrets[fieldName] = await VaultEncryptor.encrypt(
        key: derivedKey,
        plaintext: entry.value,
        fieldName: fieldName,
      );
    }

    // 7. Emit Dart code
    await DartCodeEmitter.generate(
      outputPath: outPath,
      className: className,
      kid: kid,
      packageName: packageName,
      buildFlavor: buildFlavor,
      secrets: encryptedSecrets,
      passwordFingerprint: passwordFingerprint,
    );

    print('✅ Generated $outPath from $envPath');
    print('');
    print('Build your app with:');
    print('  flutter run --dart-define=VAULT_MASTER_PASSWORD=\$VAULT_MASTER_PASSWORD');
    print('  flutter build apk --dart-define=VAULT_MASTER_PASSWORD=\$VAULT_MASTER_PASSWORD');
  }

  /// Resolves the master password from (in priority order):
  ///   1. --master-password CLI flag
  ///   2. VAULT_MASTER_PASSWORD environment variable (CI/CD)
  ///   3. .vault_key file in the current directory (local dev)
  ///   4. Hard failure — no silent fallback
  static String _resolveMasterPassword(ArgResults results) {
    // Priority 1: explicit flag (useful for scripting, warn against interactive use)
    if (results.wasParsed('master-password')) {
      final pwd = results['master-password'] as String;
      stderr.writeln(
        '⚠️  WARNING: --master-password flag used. This may appear in shell history. '
        'Prefer the VAULT_MASTER_PASSWORD env var in CI/CD.',
      );
      _assertPasswordEntropy(pwd);
      return pwd;
    }

    // Priority 2: environment variable (primary CI/CD source)
    final envPassword = Platform.environment['VAULT_MASTER_PASSWORD'];
    if (envPassword != null && envPassword.isNotEmpty) {
      _assertPasswordEntropy(envPassword);
      return envPassword;
    }

    // Priority 3: .vault_key local file (local development only)
    final vaultKeyFile = File('.vault_key');
    if (vaultKeyFile.existsSync()) {
      final filePassword = vaultKeyFile.readAsStringSync().trim();
      if (filePassword.isNotEmpty) {
        _assertPasswordEntropy(filePassword);
        stderr.writeln(
          '⚠️  WARNING: Reading master password from .vault_key file. '
          'LOCAL DEVELOPMENT ONLY. '
          'Ensure .vault_key is in your .gitignore.',
        );
        return filePassword;
      }
    }

    // No password found. Hard fail. No silent fallback. Ever.
    stderr.writeln('');
    stderr.writeln('╔══════════════════════════════════════════════════════════════════╗');
    stderr.writeln('║         envault: VAULT_MASTER_PASSWORD NOT FOUND                 ║');
    stderr.writeln('╠══════════════════════════════════════════════════════════════════╣');
    stderr.writeln('║                                                                  ║');
    stderr.writeln('║  Run "envault keygen" to generate a secure password, then:       ║');
    stderr.writeln('║                                                                  ║');
    stderr.writeln('║  LOCAL DEV:                                                      ║');
    stderr.writeln('║    echo "your-password" > .vault_key                             ║');
    stderr.writeln('║    echo ".vault_key" >> .gitignore                               ║');
    stderr.writeln('║                                                                  ║');
    stderr.writeln('║  CI/CD:                                                          ║');
    stderr.writeln('║    Add VAULT_MASTER_PASSWORD as a repository secret.             ║');
    stderr.writeln('║    GitHub: Settings → Secrets → New repository secret            ║');
    stderr.writeln('║                                                                  ║');
    stderr.writeln('╚══════════════════════════════════════════════════════════════════╝');
    stderr.writeln('');
    exit(1);
  }

  static void _assertPasswordEntropy(String password) {
    if (password.length < 20) {
      stderr.writeln(
        '❌  Master password is too weak (${password.length} chars, minimum 20).\n'
        '    Generate a strong one with: envault keygen',
      );
      exit(1);
    }
  }

  /// Computes a cheap 8-byte fingerprint of the master password using HMAC-SHA256.
  ///
  /// This fingerprint is embedded in vault.g.dart. At runtime, the app computes
  /// the same fingerprint from String.fromEnvironment('VAULT_MASTER_PASSWORD') and
  /// compares them. A mismatch means the password used to build is different from
  /// the one used to generate, and the app throws VaultConfigurationException
  /// before any decryption is attempted.
  ///
  /// Security note: This is NOT the master password, and NOT the AES key.
  /// It is a one-way hash fingerprint used only for mismatch detection.
  static Future<String> _computePasswordFingerprint(String masterPassword) async {
    final hmac = Hmac.sha256();
    final mac = await hmac.calculateMac(
      utf8.encode(masterPassword),
      secretKey: SecretKey(utf8.encode('ENVAULT_FINGERPRINT_V1')),
    );
    // First 8 bytes = 64-bit fingerprint, encoded as 16 hex chars
    return mac.bytes
        .take(8)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
