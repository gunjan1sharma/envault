import 'dart:io';
import 'package:envault/envault.dart';

class GitIgnoreChecker {
  /// Checks if [filePath] is ignored by git.
  /// Uses `git check-ignore -v` to be robust against complex globs and nested ignores.
  static Future<bool> isIgnored(String filePath) async {
    try {
      final result = await Process.run(
        'git',
        ['check-ignore', '-v', filePath],
        runInShell: true,
      );
      
      // git check-ignore exits with 0 if ignored, 1 if not ignored
      return result.exitCode == 0;
    } catch (e) {
      // If git is not installed or we're not in a git repo, degrade gracefully
      return false; 
    }
  }

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
        print('\x1B[33m$msg\x1B[0m'); // Print yellow warning
      }
    }
  }
}
