import 'dart:io';
import 'package:envault_cli/src/commands/generate_command.dart';
import 'package:envault_cli/src/commands/validate_command.dart';
import 'package:envault_cli/src/commands/watch_command.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('envault — Fintech-grade secret management CLI');
    print('Available commands:');
    print('  generate    Generate encrypted vault.g.dart from .env file');
    print('  validate    Validate .env file for secrets hygiene and entropy');
    print('  watch       Watch .env file for changes and regenerate automatically');
    exit(1);
  }

  final command = args.first;
  final commandArgs = args.skip(1).toList();

  switch (command) {
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
      exit(1);
  }
}
