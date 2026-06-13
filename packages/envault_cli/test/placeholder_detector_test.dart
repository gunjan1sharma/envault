import 'package:test/test.dart';
import 'package:envault_cli/src/validator/placeholder_detector.dart';

void main() {
  group('PlaceholderDetector', () {
    test('detects empty secret', () {
      expect(PlaceholderDetector.detect('API_KEY', ''), equals('cannot be empty'));
    });

    test('detects YOUR_API_KEY pattern', () {
      expect(PlaceholderDetector.detect('API_KEY', 'your_api_key'), isNotNull);
      expect(PlaceholderDetector.detect('API_KEY', 'YOUR-API-KEY'), isNotNull);
      expect(PlaceholderDetector.detect('API_KEY', 'YourApiKey'), isNotNull);
    });

    test('detects changeme pattern', () {
      expect(PlaceholderDetector.detect('DB_PASS', 'changeme'), isNotNull);
      expect(PlaceholderDetector.detect('DB_PASS', 'CHANGE_ME'), isNotNull);
    });

    test('detects todo pattern', () {
      expect(PlaceholderDetector.detect('SECRET', 'todo'), isNotNull);
      expect(PlaceholderDetector.detect('SECRET', 'TODO'), isNotNull);
    });

    test('detects trivial sequences', () {
      expect(PlaceholderDetector.detect('SECRET', '12345678'), isNotNull);
    });

    test('allows legitimate secrets', () {
      expect(PlaceholderDetector.detect('API_KEY', 'sk_live_123abc456def'), isNull);
      expect(PlaceholderDetector.detect('DB_PASS', 'CorrectHorseBatteryStaple!'), isNull);
    });
  });
}
