import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Adjust this import based on where your providers are located
import '../data/comment_provider.dart';

class CommentListPage extends ConsumerWidget {
  final int postId;

  const CommentListPage({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the family provider by passing the postId
    final commentsAsync = ref.watch(commentsProvider(postId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Comments for Post $postId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(commentsProvider(postId)),
          ),
        ],
      ),
      body: commentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(commentErrorMessage(err), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(commentsProvider(postId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (comments) {
          if (comments.isEmpty) {
            return const Center(child: Text('No comments found.'));
          }
          return ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return ListTile(
                leading: CircleAvatar(child: Text(comment.id.toString())),
                title: Text(
                  comment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  comment.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          );
        },
      ),
    );
  }
}