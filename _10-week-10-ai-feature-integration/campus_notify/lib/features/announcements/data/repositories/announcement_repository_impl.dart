import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_remote_data_source.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl({required this._remote});

  final AnnouncementRemoteDataSource _remote;

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
      fetchAnnouncements() async {
    try {
      final items = await _remote.getAnnouncements();
      return (announcements: List<Announcement>.of(items), failure: null);
    } catch (e) {
      return (
        announcements: const <Announcement>[],
        failure: NetworkFailure('Failed to load announcements: $e'),
      );
    }
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> fetchAnnouncementById(
    String id,
  ) async {
    try {
      final item = await _remote.getAnnouncementById(id);
      if (item == null) {
        return (
          announcement: null,
          failure: NotFoundFailure('Announcement $id not found'),
        );
      }
      return (announcement: item, failure: null);
    } catch (e) {
      return (
        announcement: null,
        failure: NetworkFailure('Failed to load announcement: $e'),
      );
    }
  }
}
