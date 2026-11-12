import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../data/datasources/announcement_remote_data_source.dart';
import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/get_announcement_detail.dart';
import '../../domain/usecases/get_announcements.dart';

// ---------- Data layer (DI) ----------
final announcementRemoteDataSourceProvider =
    Provider<AnnouncementRemoteDataSource>(
        (ref) => MockAnnouncementRemoteDataSource());

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl(
    remote: ref.watch(announcementRemoteDataSourceProvider),
  );
});

// ---------- Domain layer ----------
final getAnnouncementsProvider = Provider<GetAnnouncements>(
    (ref) => GetAnnouncements(ref.watch(announcementRepositoryProvider)));

final getAnnouncementDetailProvider = Provider<GetAnnouncementDetail>(
    (ref) => GetAnnouncementDetail(ref.watch(announcementRepositoryProvider)));

// ---------- Presentation layer ----------
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final result = await ref.watch(getAnnouncementsProvider).call();
  final failure = result.failure;
  if (failure != null) throw failure;
  return result.announcements;
});

final announcementDetailProvider =
    FutureProvider.family<Announcement, String>((ref, id) async {
  final result = await ref.watch(getAnnouncementDetailProvider).call(id);
  final failure = result.failure;
  final announcement = result.announcement;
  if (failure != null) throw failure;
  if (announcement == null) {
    throw NotFoundFailure('Announcement $id not found');
  }
  return announcement;
});
