import 'dart:math';

class EntropyChecker {
  /// Calculates Shannon entropy of a given secret.
  /// 
  /// The true theoretical entropy bound is log2(charset_size^length).
  /// We estimate charset_size based on character categories present.
  static int calculateBits(String secret) {
    if (secret.isEmpty) return 0;

    int charsetSize = 0;
    if (RegExp(r'[a-z]').hasMatch(secret)) charsetSize += 26;
    if (RegExp(r'[A-Z]').hasMatch(secret)) charsetSize += 26;
    if (RegExp(r'[0-9]').hasMatch(secret)) charsetSize += 10;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(secret)) charsetSize += 32;

    if (charsetSize == 0) return 0;

    // log2(charsetSize^length) = length * log2(charsetSize)
    final entropy = secret.length * (log(charsetSize) / ln2);
    return entropy.floor();
  }

  static String? validate(String fieldName, String secret, int minBits) {
    final bits = calculateBits(secret);
    if (bits < minBits) {
      return 'entropy: $bits bits — minimum $minBits required';
    }
    return null; // OK
  }
}
