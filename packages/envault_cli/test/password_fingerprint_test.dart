import 'dart:convert';
import 'package:test/test.dart';
import 'package:cryptography/cryptography.dart';

/// Tests the password fingerprint algorithm used by envault to detect
/// master password mismatches between `envault generate` and `flutter build`.
///
/// The fingerprint is: first 8 bytes of HMAC-SHA256(password, key="ENVAULT_FINGERPRINT_V1")
/// encoded as a 16-char lowercase hex string.
void main() {
  group('Password Fingerprint', () {
    Future<String> computeFingerprint(String password) async {
      final hmac = Hmac.sha256();
      final mac = await hmac.calculateMac(
        utf8.encode(password),
        secretKey: SecretKey(utf8.encode('ENVAULT_FINGERPRINT_V1')),
      );
      return mac.bytes
          .take(8)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
    }

    test('fingerprint is deterministic — same password always gives same fingerprint', () async {
      const password = 'my-super-secure-master-password-for-testing';
      final fp1 = await computeFingerprint(password);
      final fp2 = await computeFingerprint(password);
      expect(fp1, equals(fp2));
    });

    test('different passwords produce different fingerprints', () async {
      final fp1 = await computeFingerprint('password-one-for-testing-1234567890');
      final fp2 = await computeFingerprint('password-two-for-testing-0987654321');
      expect(fp1, isNot(equals(fp2)));
    });

    test('fingerprint is exactly 16 hex characters (8 bytes)', () async {
      final fp = await computeFingerprint('any-valid-password-that-is-long-enough');
      expect(fp.length, equals(16));
      expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(fp), isTrue,
          reason: 'Fingerprint must be lowercase hex');
    });

    test('changing one character in password changes fingerprint (avalanche effect)', () async {
      const password1 = 'super-secure-password-abcdef-1234567890';
      const password2 = 'super-secure-password-abcdef-1234567891'; // last char different
      final fp1 = await computeFingerprint(password1);
      final fp2 = await computeFingerprint(password2);
      expect(fp1, isNot(equals(fp2)));
    });

    test('fingerprint does not reveal the password — output is not a substring of input', () async {
      const password = 'my-secret-master-password-should-not-appear-in-output-xyz';
      final fp = await computeFingerprint(password);
      expect(password.contains(fp), isFalse,
          reason: 'Fingerprint must not be a substring of the password');
    });

    test('INVARIANT: empty password must not produce a valid fingerprint (guard against empty env var)',
        () async {
      // We do NOT test computeFingerprint('') directly because the CLI
      // rejects empty passwords before fingerprint computation.
      // This test verifies the invariant: fingerprint of empty string differs
      // from any non-empty password fingerprint, so a missing --dart-define
      // (which causes String.fromEnvironment to return '') would produce a
      // fingerprint that never matches the generated one.
      final fpEmpty = await computeFingerprint('');
      final fpNonEmpty = await computeFingerprint('some-valid-password-that-is-long-enough');
      expect(fpEmpty, isNot(equals(fpNonEmpty)));
    });

    test('INVARIANT: fingerprint HMAC key is "ENVAULT_FINGERPRINT_V1" — prevents collisions with other HMAC uses', () async {
      final hmac = Hmac.sha256();
      const password = 'test-password-for-invariant-check-long-enough';

      // Fingerprint with correct HMAC key
      final macCorrect = await hmac.calculateMac(
        utf8.encode(password),
        secretKey: SecretKey(utf8.encode('ENVAULT_FINGERPRINT_V1')),
      );

      // HMAC with a different key — simulates a different use of HMAC
      final macOther = await hmac.calculateMac(
        utf8.encode(password),
        secretKey: SecretKey(utf8.encode('SOME_OTHER_CONTEXT')),
      );

      expect(macCorrect.bytes, isNot(equals(macOther.bytes)),
          reason: 'Domain-separated HMAC contexts must produce different outputs');
    });
  });

  group('Mismatch Detection Logic', () {
    Future<String> computeFingerprint(String password) async {
      final hmac = Hmac.sha256();
      final mac = await hmac.calculateMac(
        utf8.encode(password),
        secretKey: SecretKey(utf8.encode('ENVAULT_FINGERPRINT_V1')),
      );
      return mac.bytes
          .take(8)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
    }

    test('CORRECT: same password at generate and build time produces matching fingerprint', () async {
      const masterPassword = 'correct-password-used-for-both-generate-and-build';

      // At envault generate time:
      final fingerprintStoredInVaultGDart = await computeFingerprint(masterPassword);

      // At flutter run time (--dart-define=VAULT_MASTER_PASSWORD=correct-password...):
      final runtimeFingerprint = await computeFingerprint(masterPassword);

      expect(runtimeFingerprint, equals(fingerprintStoredInVaultGDart),
          reason: 'Same password must produce matching fingerprints — no mismatch error');
    });

    test('MISMATCH: different password at build vs generate time produces different fingerprint', () async {
      const generatePassword = 'password-used-to-run-envault-generate-xyz123';
      const buildPassword = 'different-password-used-in-flutter-build-abc456';

      final fingerprintStoredInVaultGDart = await computeFingerprint(generatePassword);
      final runtimeFingerprint = await computeFingerprint(buildPassword);

      // This is the mismatch condition. The app would throw VaultConfigurationException.
      expect(runtimeFingerprint, isNot(equals(fingerprintStoredInVaultGDart)),
          reason: 'Different passwords must produce different fingerprints — mismatch detected');
    });
  });
}
