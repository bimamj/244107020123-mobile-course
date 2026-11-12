import 'dart:async';

import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_remote_data_source.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl({
    required AnnouncementRemoteDataSource remote,
    Duration cacheTtl = const Duration(minutes: 5),
  })  : _remote = remote,
        _cacheTtl = cacheTtl;

  final AnnouncementRemoteDataSource _remote;
  final Duration _cacheTtl;

  // In-memory cache for announcements list and detail items
  List<Announcement>? _cachedAnnouncements;
  DateTime? _lastListFetchTime;

  final Map<String, Announcement> _cachedDetails = {};
  final Map<String, DateTime> _detailFetchTimes = {};

  bool get _isListCacheValid =>
      _cachedAnnouncements != null &&
      _lastListFetchTime != null &&
      DateTime.now().difference(_lastListFetchTime!) < _cacheTtl;

  bool _isDetailCacheValid(String id) =>
      _cachedDetails.containsKey(id) &&
      _detailFetchTimes.containsKey(id) &&
      DateTime.now().difference(_detailFetchTimes[id]!) < _cacheTtl;

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
      fetchAnnouncements({bool forceRefresh = false}) async {
    // 1. Fresh cache hit: return immediately with 0 network latency
    if (!forceRefresh && _isListCacheValid) {
      return (
        announcements: List<Announcement>.unmodifiable(_cachedAnnouncements!),
        failure: null,
      );
    }

    // 2. Stale-while-revalidate: if stale cache exists and not force refreshed,
    // trigger background revalidation and return the stale cache immediately.
    if (!forceRefresh && _cachedAnnouncements != null) {
      unawaited(_revalidateAnnouncements());
      return (
        announcements: List<Announcement>.unmodifiable(_cachedAnnouncements!),
        failure: null,
      );
    }

    // 3. Cache miss or explicit forceRefresh: await fresh data from remote
    return _fetchFromRemoteAndCache();
  }

  Future<({List<Announcement> announcements, Failure? failure})>
      _fetchFromRemoteAndCache() async {
    try {
      final items = await _remote.getAnnouncements();
      final entities = List<Announcement>.of(items);
      _cachedAnnouncements = entities;
      _lastListFetchTime = DateTime.now();

      // Warm up individual detail caches as well
      for (final item in entities) {
        _cachedDetails[item.id] = item;
        _detailFetchTimes[item.id] = _lastListFetchTime!;
      }

      return (announcements: entities, failure: null);
    } catch (e) {
      // If network fails but stale cache is available, fallback gracefully
      if (_cachedAnnouncements != null) {
        return (
          announcements: List<Announcement>.unmodifiable(_cachedAnnouncements!),
          failure: null,
        );
      }
      return (
        announcements: const <Announcement>[],
        failure: NetworkFailure('Failed to load announcements: $e'),
      );
    }
  }

  Future<void> _revalidateAnnouncements() async {
    try {
      final items = await _remote.getAnnouncements();
      final entities = List<Announcement>.of(items);
      _cachedAnnouncements = entities;
      _lastListFetchTime = DateTime.now();
      for (final item in entities) {
        _cachedDetails[item.id] = item;
        _detailFetchTimes[item.id] = _lastListFetchTime!;
      }
    } catch (_) {
      // Keep existing cache on background revalidation failure
    }
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> fetchAnnouncementById(
    String id, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isDetailCacheValid(id)) {
      return (announcement: _cachedDetails[id], failure: null);
    }

    if (!forceRefresh && _cachedDetails.containsKey(id)) {
      unawaited(_revalidateDetail(id));
      return (announcement: _cachedDetails[id], failure: null);
    }

    try {
      final item = await _remote.getAnnouncementById(id);
      if (item == null) {
        return (
          announcement: null,
          failure: NotFoundFailure('Announcement $id not found'),
        );
      }
      _cachedDetails[id] = item;
      _detailFetchTimes[id] = DateTime.now();
      return (announcement: item, failure: null);
    } catch (e) {
      if (_cachedDetails.containsKey(id)) {
        return (announcement: _cachedDetails[id], failure: null);
      }
      return (
        announcement: null,
        failure: NetworkFailure('Failed to load announcement: $e'),
      );
    }
  }

  Future<void> _revalidateDetail(String id) async {
    try {
      final item = await _remote.getAnnouncementById(id);
      if (item != null) {
        _cachedDetails[id] = item;
        _detailFetchTimes[id] = DateTime.now();
      }
    } catch (_) {
      // Silent revalidation failure
    }
  }
}
