import 'package:meta/meta_meta.dart';
import 'obfuscation_level.dart';
import 'git_ignore_check.dart';
import 'secret_validator.dart';

/// Top-level annotation for your environment class.
@Target({TargetKind.classType})
class VaultEnv {
  const VaultEnv({
    this.path = '.env',
    this.obfuscation = ObfuscationLevel.aesGcm256,
    this.strictMode = true,
    this.gitIgnoreCheck = GitIgnoreCheck.failBuild,
    this.rasp = false,
  });

  /// The path to the .env file. Defaults to '.env'.
  final String path;

  /// The default obfuscation level for all fields.
  final ObfuscationLevel obfuscation;

  /// If true, missing fields in the .env file will cause a build error.
  final bool strictMode;

  /// How to handle .env files that are not gitignored.
  final GitIgnoreCheck gitIgnoreCheck;

  /// Whether to enable Runtime Application Self-Protection (RASP) checks.
  /// If true, decryption will fail if the device is rooted/jailbroken.
  final bool rasp;
}

/// Per-field annotation to override defaults or specify validation.
@Target({TargetKind.field, TargetKind.getter})
class VaultField {
  const VaultField({
    this.varName,
    this.optional = false,
    this.obfuscation,
    this.validator,
    this.minEntropyBits,
  });

  /// The name of the environment variable. If null, the field name is used.
  final String? varName;

  /// If true, the field can be absent from the .env file even in strict mode.
  final bool optional;

  /// Overrides the class-level obfuscation setting.
  final ObfuscationLevel? obfuscation;

  /// Optional validator for the secret's format (e.g. regex).
  final SecretValidator? validator;

  /// The minimum required entropy bits for the secret (e.g. 128).
  final int? minEntropyBits;
}
