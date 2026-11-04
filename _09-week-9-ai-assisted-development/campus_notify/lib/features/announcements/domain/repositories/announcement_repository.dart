import '../../../../core/failures.dart';
import '../entities/announcement.dart';

abstract interface class AnnouncementRepository {
  Future<({List<Announcement> announcements, Failure? failure})>
      fetchAnnouncements();

  Future<({Announcement? announcement, Failure? failure})> fetchAnnouncementById(
    String id,
  );
}
