import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/failures.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/announcement.dart';
import '../providers/announcement_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'AI Assistant',
            onPressed: () => context.push(AppRoutes.chat),
          ),
          IconButton(
            key: const Key('home_notes_button'),
            icon: const Icon(Icons.note_alt_outlined),
            tooltip: 'My Notes',
            onPressed: () => context.push(AppRoutes.notes),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: announcements.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e is Failure ? e.message : '$e',
          onRetry: () => ref.invalidate(announcementsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(announcementsProvider.future),
          child: RepaintBoundary(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return AnnouncementCard(
                  key: ValueKey(item.id),
                  announcement: item,
                  onTap: () =>
                      context.push(AppRoutes.announcementDetail(item.id)),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('home_ask_ai_fab'),
        onPressed: () => context.push(AppRoutes.chat),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Ask AI'),
      ),
    );
  }
}

/// Extracted widget for announcement card to avoid rebuilding the whole list
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.onTap,
  });

  final Announcement announcement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.campaign, color: Colors.blue),
        title: Text(announcement.title),
        subtitle: Text(announcement.summary),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
