import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/chat_assistant/domain/entities/chat_message.dart';
import 'package:campus_notify/features/chat_assistant/domain/repositories/chat_repository.dart';
import 'package:campus_notify/features/chat_assistant/domain/services/sensitive_data_filter.dart';

class SendChatMessage {
  const SendChatMessage({
    required ChatRepository repository,
    SensitiveDataFilter filter = const SensitiveDataFilter(),
  })  : _repository = repository,
        _filter = filter;

  final ChatRepository _repository;
  final SensitiveDataFilter _filter;

  Future<({ChatMessage? message, Failure? failure})> call(String prompt) async {
    final String sanitizedPrompt;
    try {
      sanitizedPrompt = _filter.filterAndSanitize(prompt);
    } on ValidationFailure catch (e) {
      return (message: null, failure: e);
    } catch (_) {
      return (message: null, failure: const ValidationFailure('Invalid input.'));
    }

    return _repository.sendMessage(sanitizedPrompt);
  }
}
