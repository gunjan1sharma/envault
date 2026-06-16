import 'package:envault/envault.dart';

part 'vault.g.dart';

@VaultEnv(
  path: '.env.production',
  obfuscation: ObfuscationLevel.aesGcm256,
  gitIgnoreCheck: GitIgnoreCheck.failBuild,
  strictMode: true,
)
abstract class Vault {
  @VaultField(
    varName: 'API_KEY',
    minEntropyBits: 128,
  )
  static SecureString get apiKey => _Vault.apiKey;

  @VaultField(varName: 'ANOTHER_KEY')
  static SecureString get anotherKey => _Vault.anotherKey;
}
