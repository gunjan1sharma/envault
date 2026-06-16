import 'dart:io';
import 'package:envault_cli/src/commands/generate_command.dart';
import 'package:envault_cli/src/commands/keygen_command.dart';
import 'package:envault_cli/src/commands/validate_command.dart';
import 'package:envault_cli/src/commands/watch_command.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    _printHelp();
    exit(1);
  }

  final command = args.first;
  final commandArgs = args.skip(1).toList();

  switch (command) {
    case 'keygen':
      await KeygenCommand.run(commandArgs);
      break;
    case 'generate':
      await GenerateCommand.run(commandArgs);
      break;
    case 'validate':
      await ValidateCommand.run(commandArgs);
      break;
    case 'watch':
      await WatchCommand.run(commandArgs);
      break;
    default:
      print('Unknown command: $command');
      _printHelp();
      exit(1);
  }
}

void _printHelp() {
  print('');
  print('envault — Fintech-grade secret management CLI');
  print('');
  print('Usage: envault <command> [options]');
  print('');
  print('Commands:');
  print('  keygen      Generate a cryptographically secure master password (run once per project)');
  print('  generate    Encrypt .env and generate vault.g.dart');
  print('  validate    Check .env for weak secrets, placeholders, and entropy issues');
  print('  watch       Watch .env for changes and auto-regenerate vault.g.dart');
  print('');
  print('Getting started:');
  print('  1. envault keygen               # generate your master password');
  print('  2. echo "..." > .vault_key      # save password locally (gitignored)');
  print('  3. envault generate             # encrypt your .env');
  print('  4. flutter run \\');
  print('       --dart-define=VAULT_MASTER_PASSWORD=\$(cat .vault_key)');
  print('');
}
