import '../../../../core/failures.dart';
import '../entities/announcement.dart';

abstract interface class AnnouncementRepository {
  Future<({List<Announcement> announcements, Failure? failure})>
      fetchAnnouncements({bool forceRefresh = false});

  Future<({Announcement? announcement, Failure? failure})> fetchAnnouncementById(
    String id, {
    bool forceRefresh = false,
  });
}
