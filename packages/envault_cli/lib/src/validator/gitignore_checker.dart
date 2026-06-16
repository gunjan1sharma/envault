import 'dart:io';
import 'package:envault/envault.dart';

class GitIgnoreChecker {
  /// Checks if [filePath] is ignored by git.
  static Future<bool> isIgnored(String filePath) async {
    try {
      final result = await Process.run(
        'git',
        ['check-ignore', '-v', filePath],
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Checks that [filePath] is gitignored. If not, prints a warning or
  /// throws depending on [checkLevel].
  static Future<void> enforceOrWarn(String envPath, GitIgnoreCheck checkLevel) async {
    if (checkLevel == GitIgnoreCheck.skip) return;

    final ignored = await isIgnored(envPath);
    if (!ignored) {
      final msg = 'SECURITY WARNING: $envPath is NOT gitignored. '
          'Committing this file will expose your plaintext secrets.';

      if (checkLevel == GitIgnoreCheck.failBuild) {
        throw VaultSecurityException(
          '$msg\n'
          'Build blocked by GitIgnoreCheck.failBuild. '
          'Add $envPath to your .gitignore to proceed.',
        );
      } else {
        print('\x1B[33m$msg\x1B[0m');
      }
    }
  }

  /// Enforces that [filePath] is gitignored. Exits with an error message if not.
  /// Used to protect the .vault_key local password file.
  static Future<void> enforceFileIgnored(String filePath, String reason) async {
    final ignored = await isIgnored(filePath);
    if (!ignored) {
      stderr.writeln('');
      stderr.writeln('⛔  SECURITY ERROR: $filePath is NOT gitignored!');
      stderr.writeln('');
      stderr.writeln('    $reason');
      stderr.writeln('');
      stderr.writeln('    Fix immediately:');
      stderr.writeln('      echo "$filePath" >> .gitignore');
      stderr.writeln('      git rm --cached $filePath   # only if already tracked by git');
      stderr.writeln('');
      stderr.writeln('    envault will not generate code until this is resolved.');
      stderr.writeln('');
      exit(1);
    }
  }
}

