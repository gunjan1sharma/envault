import 'package:test/test.dart';
import 'package:envault_cli/src/crypto/key_derivation.dart';

void main() {
  group('VaultKeyDerivation', () {
    test('derives identical keys for same inputs', () async {
      final key1 = await VaultKeyDerivation.deriveKey(
        masterPassword: 'super_secret_ci_key',
        packageName: 'com.example.app',
        kid: 'v1',
        buildFlavor: 'prod',
      );
      
      final key2 = await VaultKeyDerivation.deriveKey(
        masterPassword: 'super_secret_ci_key',
        packageName: 'com.example.app',
        kid: 'v1',
        buildFlavor: 'prod',
      );
      
      expect(key1, equals(key2));
      expect(key1.length, equals(32)); // 256 bits
    });

    test('derives different keys for different master passwords', () async {
      final key1 = await VaultKeyDerivation.deriveKey(
        masterPassword: 'pass1',
        packageName: 'pkg',
        kid: '1',
        buildFlavor: 'p',
      );
      
      final key2 = await VaultKeyDerivation.deriveKey(
        masterPassword: 'pass2',
        packageName: 'pkg',
        kid: '1',
        buildFlavor: 'p',
      );
      
      expect(key1, isNot(equals(key2)));
    });

    test('derives different keys for different salt components', () async {
      final key1 = await VaultKeyDerivation.deriveKey(
        masterPassword: 'pass',
        packageName: 'pkg1',
        kid: '1',
        buildFlavor: 'p',
      );
      
      final key2 = await VaultKeyDerivation.deriveKey(
        masterPassword: 'pass',
        packageName: 'pkg2',
        kid: '1',
        buildFlavor: 'p',
      );
      
      expect(key1, isNot(equals(key2)));
    });
  });
}
