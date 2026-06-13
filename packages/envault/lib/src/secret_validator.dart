/// Configures build-time validation for a specific field.
abstract class SecretValidator {
  const SecretValidator();

  /// Validates the secret using a regular expression.
  const factory SecretValidator.regex(String pattern, {String? errorMessage}) =
      _RegexValidator;
}

class _RegexValidator extends SecretValidator {
  const _RegexValidator(this.pattern, {this.errorMessage});
  final String pattern;
  final String? errorMessage;
}
