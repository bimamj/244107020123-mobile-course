import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'models/comment.dart';
import 'repositories/comment_repository.dart';

/// Menyediakan satu instance Dio untuk seluruh layer data.
final commentDioProvider = Provider<Dio>((ref) => createDio());

/// Membuat repository menggunakan Dio dari provider agar dependency dapat di-inject.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(commentDioProvider)),
);

/// Memuat komentar berdasarkan post ID dan mengekspos status AsyncValue.
class CommentNotifier extends AsyncNotifier<List<Comment>> {
  /// Menyimpan post ID yang diberikan oleh provider family.
  CommentNotifier(this.postId);

  final int postId;

  @override
  Future<List<Comment>> build() {
    // Exception dari repository otomatis diubah Riverpod menjadi AsyncError.
    return ref.watch(commentRepositoryProvider).fetchComments(postId);
  }
}

/// Provider family memungkinkan pemanggilan komentar untuk post ID berbeda.
final commentsProvider = AsyncNotifierProvider.family<
  CommentNotifier, List<Comment>, int>(
  CommentNotifier.new,
  // Error tidak diulang otomatis supaya UI dapat menampilkan pesan konsisten.
  retry: (retryCount, error) => null,
);

/// Mengubah error teknis Dio menjadi pesan yang mudah dipahami pengguna.
String commentErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Long connection time. Check your internet connection and try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to the server. Check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) return 'Comment not found (404).';
        if (statusCode == 500) {
          return 'Server is experiencing issues (500). Please try again later.';
        }
        return 'Server returned an error ($statusCode). Please try again later.';
      default:
        return 'A network error occurred. Please try again.';
    }
  }

  return 'An unexpected error occurred. Please try again.';
}