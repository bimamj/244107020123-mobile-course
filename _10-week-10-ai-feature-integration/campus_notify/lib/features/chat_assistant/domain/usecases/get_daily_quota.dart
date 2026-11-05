import 'package:campus_notify/features/chat_assistant/domain/repositories/chat_repository.dart';

class GetDailyQuota {
  const GetDailyQuota(this._repository);
  final ChatRepository _repository;

  Future<({int used, int max})> call() => _repository.getDailyQuota();
}
