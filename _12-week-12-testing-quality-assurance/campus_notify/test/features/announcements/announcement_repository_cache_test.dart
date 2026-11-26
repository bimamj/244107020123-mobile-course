import 'package:campus_notify/features/announcements/data/datasources/announcement_remote_data_source.dart';
import 'package:campus_notify/features/announcements/data/models/announcement_model.dart';
import 'package:campus_notify/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class CountingAnnouncementRemoteDataSource
    implements AnnouncementRemoteDataSource {
  int listCallCount = 0;
  int detailCallCount = 0;
  List<AnnouncementModel> items = [
    const AnnouncementModel(
      id: '1',
      title: 'First Announcement',
      summary: 'Summary 1',
      content: 'Content 1',
    ),
  ];

  @override
  Future<List<AnnouncementModel>> getAnnouncements() async {
    listCallCount++;
    return items;
  }

  @override
  Future<AnnouncementModel?> getAnnouncementById(String id) async {
    detailCallCount++;
    return items.where((e) => e.id == id).firstOrNull;
  }
}

void main() {
  group('AnnouncementRepositoryImpl - Stale While Revalidate Cache', () {
    late CountingAnnouncementRemoteDataSource mockRemote;
    late AnnouncementRepositoryImpl repository;

    setUp(() {
      mockRemote = CountingAnnouncementRemoteDataSource();
      repository = AnnouncementRepositoryImpl(
        remote: mockRemote,
        cacheTtl: const Duration(seconds: 10),
      );
    });

    test('fetches from remote on first call and caches the result', () async {
      final result1 = await repository.fetchAnnouncements();
      expect(result1.announcements.length, 1);
      expect(mockRemote.listCallCount, 1);

      // Second call within TTL should return from cache without calling remote again
      final result2 = await repository.fetchAnnouncements();
      expect(result2.announcements.length, 1);
      expect(mockRemote.listCallCount, 1); // Still 1, remote was not called
    });

    test('forceRefresh bypasses cache and re-fetches from remote', () async {
      await repository.fetchAnnouncements();
      expect(mockRemote.listCallCount, 1);

      await repository.fetchAnnouncements(forceRefresh: true);
      expect(mockRemote.listCallCount, 2);
    });

    test('detail query utilizes warmed up cache from list fetch', () async {
      // List fetch warms up detail cache for items
      await repository.fetchAnnouncements();
      expect(mockRemote.listCallCount, 1);
      expect(mockRemote.detailCallCount, 0);

      // Fetch detail for item '1' should hit warmed cache directly
      final detail = await repository.fetchAnnouncementById('1');
      expect(detail.announcement?.title, 'First Announcement');
      expect(mockRemote.detailCallCount, 0); // No remote call needed
    });
  });
}
