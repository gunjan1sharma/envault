import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:envault_cli/src/parser/env_parser.dart';
import 'package:envault_cli/src/validator/entropy_checker.dart';
import 'package:envault_cli/src/validator/placeholder_detector.dart';

class ValidateCommand {
  static void printUsage(ArgParser parser) {
    print('Usage: envault validate [options]');
    print(parser.usage);
  }

  static Future<void> run(List<String> args) async {
    final parser = ArgParser()
      ..addOption('env', abbr: 'e', defaultsTo: '.env', help: 'Path to .env file')
      ..addFlag('json', help: 'Output results in JSON format for CI pipelines', defaultsTo: false)
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Print this usage information.');

    final ArgResults results;
    try {
      results = parser.parse(args);
    } catch (e) {
      printUsage(parser);
      exit(2);
    }

    if (results['help'] as bool) {
      printUsage(parser);
      exit(0);
    }

    final envPath = results['env'] as String;
    final isJson = results['json'] as bool;

    if (!File(envPath).existsSync()) {
      if (isJson) {
        print(jsonEncode({'status': 'error', 'message': 'File $envPath not found'}));
      } else {
        print('❌ Error: File $envPath not found');
      }
      exit(2);
    }

    final secrets = await EnvParser.parse(envPath);
    final errors = <String, List<String>>{};

    for (final entry in secrets.entries) {
      final key = entry.key;
      final value = entry.value;
      final fieldErrors = <String>[];

      // 1. Placeholder Detection
      final placeholderError = PlaceholderDetector.detect(key, value);
      if (placeholderError != null) {
        fieldErrors.add(placeholderError);
      }

      // 2. Entropy Check (We require 64 bits minimum for a production key as a baseline rule)
      // Note: In reality, we'd parse the @VaultField annotation to get the exact minEntropyBits.
      // For this global CLI validate, we apply a general heuristic.
      final entropyError = EntropyChecker.validate(key, value, 64);
      if (entropyError != null && !key.toLowerCase().contains('url') && !key.toLowerCase().contains('host')) {
        // URLs often have low entropy per length, don't flag them as strictly
        fieldErrors.add(entropyError);
      }

      if (fieldErrors.isNotEmpty) {
        errors[key] = fieldErrors;
      }
    }

    if (isJson) {
      final output = {
        'status': errors.isEmpty ? 'success' : 'failed',
        'errors': errors,
      };
      print(jsonEncode(output));
    } else {
      if (errors.isEmpty) {
        print('✅ Validation passed! All secrets look secure.');
      } else {
        print('❌ Validation failed! Found insecure secrets in $envPath:');
        for (final entry in errors.entries) {
          print('\n  ${entry.key}:');
          for (final err in entry.value) {
            print('    - $err');
          }
        }
      }
    }

    exit(errors.isEmpty ? 0 : 1);
  }
}
