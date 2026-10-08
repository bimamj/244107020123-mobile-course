import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Generate some mock announcements for the UI
    final List<Map<String, String>> announcements = List.generate(
      5,
      (index) => {
        'id': '100${index + 1}',
        'title': 'Important Announcement #${index + 1}',
        'subtitle': 'Tap to view details...'
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              // Trigger your Riverpod logout method
              ref.read(authStateProvider.notifier).logout();
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final item = announcements[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.campaign, color: Colors.blue),
              title: Text(item['title']!),
              subtitle: Text(item['subtitle']!),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to the announcement route passing the ID
                context.go('/announcement/${item['id']}');
              },
            ),
          );
        },
      ),
    );
  }
}