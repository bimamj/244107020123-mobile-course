import '../models/announcement_model.dart';

abstract interface class AnnouncementRemoteDataSource {
  Future<List<AnnouncementModel>> getAnnouncements();

  /// Returns `null` when the announcement does not exist.
  Future<AnnouncementModel?> getAnnouncementById(String id);
}

class MockAnnouncementRemoteDataSource implements AnnouncementRemoteDataSource {
  static final List<AnnouncementModel> _items = List.generate(
    5,
    (index) => AnnouncementModel(
      id: '100${index + 1}',
      title: 'Important Announcement #${index + 1}',
      summary: 'Tap to view details...',
      content:
          'This is the detailed content for announcement #${index + 1}. '
          'In a real app, this data is fetched from your API.',
    ),
  );

  @override
  Future<List<AnnouncementModel>> getAnnouncements() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_items);
  }

  @override
  Future<AnnouncementModel?> getAnnouncementById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
