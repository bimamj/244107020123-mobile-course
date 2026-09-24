import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'api_client.dart';
import 'models/post.dart';
import 'repositories/post_repository.dart';

final dioProvider = Provider<Dio>((ref) => createDio());

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);

class PostListNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    // Exceptions from the repository automatically become AsyncError.
    // Automatic retry is disabled in the provider declaration below
    // so errors are final and easy to test.
    final repository = ref.watch(postRepositoryProvider);
    return repository.fetchPosts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(postRepositoryProvider);
      state = AsyncData(await repository.fetchPosts());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final postListProvider =
    AsyncNotifierProvider<PostListNotifier, List<Post>>(
        PostListNotifier.new,
        // Disable Riverpod 3 automatic retry so errors are final
        // and testable (otherwise the provider future in tests
        // would retry and hang).
        retry: (retryCount, error) => null);

String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Slow connection or timeout. Check your internet and retry.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Check your internet connection.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 404) return 'Data not found (404).';
        if (code == 401 || code == 403) {
          return 'Access denied ($code). Check your credentials.';
        }
        return 'Server problem ($code). Try again later.';
      default:
        return 'A network error occurred. Try again.';
    }
  }
  return 'An unexpected error occurred: $error';
}

final postDetailProvider = FutureProvider.family<Post, int>((ref, id) async {
  // Try to find it in the already-loaded list
  final cachedPosts = ref.read(postListProvider).value;
  final existingPost = cachedPosts?.where((p) => p.id == id).firstOrNull;
  if (existingPost != null) return existingPost;

  // Fetch from API directly (Make sure your PostRepository has this method)
  final repository = ref.watch(postRepositoryProvider);
  final response = await repository.fetchPosts(); // or repository.fetchPost(id) if created
  return response.firstWhere((p) => p.id == id);
});

Future<List<Post>> readPostsOnce(ProviderContainer container) async {
  return container.read(postListProvider.future);
}

Future<Object?> readPostsErrorOnce(ProviderContainer container) async {
  try {
    await container.read(postListProvider.future);
    return null;
  } catch (e) {
    return e;
  }
}