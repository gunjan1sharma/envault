import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:envault_cli/src/commands/generate_command.dart';

class WatchCommand {
  static void printUsage(ArgParser parser) {
    print('Usage: envault watch [options]');
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
    
    // Do initial generation
    await _triggerGeneration(args);
    
    print('👀 Watching $envPath for changes...');
    
    // Watch with debounce
    Timer? debounceTimer;
    
    try {
      final file = File(envPath);
      if (!file.existsSync()) {
        print('❌ Error: File $envPath not found');
        exit(1);
      }
      
      final watcher = file.watch(events: FileSystemEvent.modify | FileSystemEvent.create);
      
      await for (final _ in watcher) {
        if (debounceTimer?.isActive ?? false) {
          debounceTimer!.cancel();
        }
        
        debounceTimer = Timer(const Duration(milliseconds: 300), () async {
          print('🔄 Change detected in $envPath, regenerating...');
          try {
            await _triggerGeneration(args);
          } catch (e) {
            print('❌ Error during generation: $e');
          }
        });
      }
    } catch (e) {
      print('❌ Failed to watch file: $e');
      // Fallback: poll file modification time
      await _fallbackPolling(envPath, args);
    }
  }
  
  static Future<void> _triggerGeneration(List<String> args) async {
    await GenerateCommand.run(args);
  }
  
  static Future<void> _fallbackPolling(String envPath, List<String> args) async {
    print('⚠️ Falling back to polling mode for file watching.');
    final file = File(envPath);
    var lastModified = file.lastModifiedSync();
    
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final currentModified = file.lastModifiedSync();
        if (currentModified.isAfter(lastModified)) {
          lastModified = currentModified;
          print('🔄 Change detected in $envPath, regenerating...');
          await _triggerGeneration(args);
        }
      } catch (e) {
        // File might be temporarily unavailable during writes
      }
    }
  }
}
