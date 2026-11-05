import 'package:flutter/foundation.dart';

import '../../core/error/app_exception.dart';
import '../remote/post_api.dart';
import '../local/post_cache.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/user.dart';

class PostDetails {
  final Post post;
  final List<Comment> comments;
  final User author;
  PostDetails(this.post, this.comments, this.author);
}

class PostRepository {
  final PostApi api;
  final PostCache cache;
  PostRepository(this.api, this.cache);
  Future<T> guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error, stack) {
      debugPrint('Post API: $error\n$stack');
      throw AppException.from(error);
    }
  }

  Future<List<Post>> page(int page, int? author) => guard(
    () => author == null
        ? api.posts(page, 10)
        : api.authorPosts(author, page, 10),
  );
  Future<List<User>> users() => guard(() => api.users());
  Future<PostDetails> details(Post selected) => guard(() async {
    if (selected.local) {
      return PostDetails(
        selected,
        [],
        User(id: selected.userId, name: 'Автор #${selected.userId}'),
      );
    }
    final results = await Future.wait<Object>([
      api.post(selected.id),
      api.comments(selected.id),
      api.user(selected.userId),
    ]);
    return PostDetails(
      results[0] as Post,
      results[1] as List<Comment>,
      results[2] as User,
    );
  });
  Future<Post> create(String title, String body, int userId) => guard(() async {
    final response = await api.create({
      'title': title.trim(),
      'body': body.trim(),
      'userId': userId,
    });
    // JSONPlaceholder always returns 101. A distinct local ID prevents collisions.
    final saved = Post(
      id: -DateTime.now().microsecondsSinceEpoch,
      userId: response.userId,
      title: response.title,
      body: response.body,
      local: true,
    );
    await cache.saveLocal([saved, ...cache.local()]);
    return response;
  });
}
