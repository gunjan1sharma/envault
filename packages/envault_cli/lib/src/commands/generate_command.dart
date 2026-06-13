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

    // Optional CI Master Key. If not present, we fallback to a derived combination
    // (Model A in the plan - lower security, zero config).
    // In a real implementation, you'd mandate VAULT_MASTER_KEY for Model B.
    final ciKey = Platform.environment['VAULT_MASTER_KEY'] ?? 'fallback_zero_config_key';

    // 1. Git ignore check
    await GitIgnoreChecker.enforceOrWarn(envPath, GitIgnoreCheck.warn);

    // 2. Parse .env
    final parsedSecrets = await EnvParser.parse(envPath);

    // 3. Derive key
    final derivedKey = await VaultKeyDerivation.deriveKey(
      masterPassword: ciKey,
      packageName: packageName,
      kid: kid,
      buildFlavor: buildFlavor,
    );

    // 4. Encrypt secrets
    final encryptedSecrets = <String, EncryptedSecret>{};
    for (final entry in parsedSecrets.entries) {
      // Very basic formatting — convert snake_case or SCREAMING_SNAKE to camelCase
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

    // 5. Emit Dart code
    await DartCodeEmitter.generate(
      outputPath: outPath,
      className: className,
      kid: kid,
      packageName: packageName,
      buildFlavor: buildFlavor,
      secrets: encryptedSecrets,
    );

    print('✅ Generated $outPath from $envPath');
  }
}
