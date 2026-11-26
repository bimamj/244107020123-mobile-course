import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/chat_assistant/domain/services/sensitive_data_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const filter = SensitiveDataFilter();

  group('SensitiveDataFilter - Security & Secret Detection', () {
    test('throws ValidationFailure when password is included', () {
      expect(
        () => filter.filterAndSanitize(
          'my password: secret123 what is my schedule?',
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (e) => e.message,
            'message',
            contains('passwords, tokens, or API keys'),
          ),
        ),
      );
    });

    test('throws ValidationFailure when token or bearer token is included', () {
      expect(
        () => filter.filterAndSanitize('Please test with Bearer eyJhbGciOi...'),
        throwsA(isA<ValidationFailure>()),
      );

      expect(
        () => filter.filterAndSanitize('token = "abc123xyz456def789"'),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('throws ValidationFailure when API key is included', () {
      expect(
        () =>
            filter.filterAndSanitize('AIzaSyD-1234567890123456789012345678901'),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('throws ValidationFailure on empty or whitespace question', () {
      expect(
        () => filter.filterAndSanitize('   '),
        throwsA(
          isA<ValidationFailure>().having(
            (e) => e.message,
            'message',
            contains('empty'),
          ),
        ),
      );
    });
  });

  group('SensitiveDataFilter - PII Sanitization & Redaction', () {
    test('redacts email addresses with [REDACTED_EMAIL]', () {
      final result = filter.filterAndSanitize(
        'Contact student at john.doe@campus.ac.id for notes',
      );
      expect(result, 'Contact student at [REDACTED_EMAIL] for notes');
      expect(result, isNot(contains('john.doe@campus.ac.id')));
    });

    test('redacts phone numbers with [REDACTED_PHONE]', () {
      final result = filter.filterAndSanitize(
        'Call campus security at 0812-3456-7890 immediately',
      );
      expect(result, contains('[REDACTED_PHONE]'));
      expect(result, isNot(contains('0812-3456-7890')));
    });

    test('redacts credit card patterns with [REDACTED_CARD]', () {
      final result = filter.filterAndSanitize(
        'Card number 4111 2222 3333 4444 for payment',
      );
      expect(result, contains('[REDACTED_CARD]'));
      expect(result, isNot(contains('4111 2222 3333 4444')));
    });

    test('passes safe queries unaltered', () {
      final result = filter.filterAndSanitize(
        'What is the schedule for midterm exams?',
      );
      expect(result, 'What is the schedule for midterm exams?');
    });
  });
}
