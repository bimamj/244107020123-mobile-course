import 'package:campus_notify/core/failures.dart';

/// Service responsible for validating and sanitizing user inputs
/// before transmitting them to cloud AI endpoints.
class SensitiveDataFilter {
  const SensitiveDataFilter();

  // Common sensitive secret patterns (passwords, tokens, API keys)
  static final _passwordPattern = RegExp(
    r'(password\s*[:=]\s*\S+|passwd\s*[:=]\s*\S+|secret\s*[:=]\s*\S+)',
    caseSensitive: false,
  );

  static final _tokenPattern = RegExp(
    r'(bearer\s+[A-Za-z0-9\-._~+/]+=*|token\s*[:=]\s*["'
    ']?[A-Za-z0-9_-]{16,}["'
    ']?)',
    caseSensitive: false,
  );

  static final _apiKeyPattern = RegExp(
    r'(AIza[0-9A-Za-z\-_]{35}|sk-[a-zA-Z0-9]{20,})',
  );

  // PII patterns
  static final _emailPattern = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
  );

  static final _phonePattern = RegExp(
    r'(\+?[0-9]{1,3}[-.\s]?)?\(?[0-9]{3,4}\)?[-.\s]?[0-9]{3,4}[-.\s]?[0-9]{4,}',
  );

  static final _creditCardPattern = RegExp(r'\b(?:\d{4}[ -]?){3}\d{4}\b');

  /// Checks whether the text contains critical credentials or secret keys.
  bool containsSecrets(String input) {
    return _passwordPattern.hasMatch(input) ||
        _tokenPattern.hasMatch(input) ||
        _apiKeyPattern.hasMatch(input);
  }

  /// Redacts PII like emails, phone numbers, and financial numbers with placeholders.
  String sanitizePii(String input) {
    var sanitized = input;
    sanitized = sanitized.replaceAll(_emailPattern, '[REDACTED_EMAIL]');
    sanitized = sanitized.replaceAll(_creditCardPattern, '[REDACTED_CARD]');
    sanitized = sanitized.replaceAll(_phonePattern, '[REDACTED_PHONE]');
    return sanitized;
  }

  /// Validates input against security constraints.
  /// Throws [ValidationFailure] if hard credentials/secrets are found.
  /// Returns PII-sanitized text ready for AI inference.
  String filterAndSanitize(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const ValidationFailure('Question cannot be empty.');
    }

    if (containsSecrets(trimmed)) {
      throw const ValidationFailure(
        'For your security, messages containing passwords, tokens, or API keys cannot be sent to the AI assistant.',
      );
    }

    return sanitizePii(trimmed);
  }
}
