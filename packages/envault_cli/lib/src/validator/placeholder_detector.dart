class PlaceholderDetector {
  static final _suspiciousPatterns = [
    RegExp(r'your[-_]?api[-_]?key', caseSensitive: false),
    RegExp(r'your[-_]?secret', caseSensitive: false),
    RegExp(r'change[-_]?me', caseSensitive: false),
    RegExp(r'insert[-_]?key[-_]?here', caseSensitive: false),
    RegExp(r'^todo$', caseSensitive: false),
    RegExp(r'^test$', caseSensitive: false),
    RegExp(r'^dummy$', caseSensitive: false),
    RegExp(r'12345678'), // Trivial sequences
  ];

  /// Returns an error message if the secret is clearly a placeholder, or null if ok.
  static String? detect(String fieldName, String secret) {
    if (secret.isEmpty) return 'cannot be empty';

    for (final pattern in _suspiciousPatterns) {
      if (pattern.hasMatch(secret)) {
        return 'appears to be a placeholder value';
      }
    }
    return null; // OK
  }
}
