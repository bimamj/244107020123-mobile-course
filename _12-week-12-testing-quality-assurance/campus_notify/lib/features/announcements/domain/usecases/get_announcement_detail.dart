import '../../../../core/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

class GetAnnouncementDetail {
  const GetAnnouncementDetail(this._repository);
  final AnnouncementRepository _repository;

  Future<({Announcement? announcement, Failure? failure})> call(
    String id, {
    bool forceRefresh = false,
  }) async {
    if (id.trim().isEmpty) {
      return (
        announcement: null,
        failure: const ValidationFailure('Announcement ID is required'),
      );
    }
    return _repository.fetchAnnouncementById(id, forceRefresh: forceRefresh);
  }
}
