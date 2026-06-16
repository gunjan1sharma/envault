//
// Generated file. Do not edit.
// This file is generated from template in file `flutter_tools/lib/src/flutter_plugins.dart`.
//

// @dart = 3.5

import 'dart:io'; // flutter_ignore: dart_io_import.
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';

@pragma('vm:entry-point')
class _PluginRegistrant {

  @pragma('vm:entry-point')
  static void register() {
    if (Platform.isAndroid) {
      try {
        FlutterCryptography.registerWith();
      } catch (err) {
        print(
          '`cryptography_flutter` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    } else if (Platform.isIOS) {
      try {
        FlutterCryptography.registerWith();
      } catch (err) {
        print(
          '`cryptography_flutter` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    } else if (Platform.isLinux) {
    } else if (Platform.isMacOS) {
      try {
        FlutterCryptography.registerWith();
      } catch (err) {
        print(
          '`cryptography_flutter` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    } else if (Platform.isWindows) {
    }
  }
}
