import 'package:flutter/foundation.dart';

import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../../core/error/app_exception.dart';

class PostsController extends ChangeNotifier {
  final PostRepository repository;
  PostsController(this.repository);
  List<Post> posts = [];
  List<Post> locals = [];
  int? author;
  String query = '';
  bool descending = false,
      loading = false,
      refreshing = false,
      loadingMore = false,
      cached = false,
      hasMore = true;
  String? error, pageError;
  int _page = 0, _generation = 0;
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }

  List<Post> get visible {
    final result =
        [...locals.where((p) => author == null || p.userId == author), ...posts]
            .where(
              (p) => p.title.toLowerCase().contains(query.toLowerCase().trim()),
            )
            .toList();
    result.sort(
      (a, b) => descending ? b.id.compareTo(a.id) : a.id.compareTo(b.id),
    );
    return result;
  }

  void search(String value) {
    query = value;
    notifyListeners();
  }

  void sort(bool value) {
    descending = value;
    notifyListeners();
  }

  Future<void> open({int? userId}) async {
    final generation = ++_generation;
    author = userId;
    _page = 0;
    hasMore = true;
    loadingMore = false;
    pageError = null;
    error = null;
    posts = repository.cache.read(author);
    locals = repository.cache.local();
    cached = posts.isNotEmpty;
    loading = posts.isEmpty;
    refreshing = true;
    notifyListeners();
    try {
      final data = await repository.page(1, userId);
      if (generation != _generation) return;
      posts = data;
      _page = 1;
      hasMore = data.length == 10;
      cached = false;
      try {
        await repository.cache.write(userId, data);
      } catch (_) {
        error = 'Посты загружены, но кэш не сохранён.';
      }
    } catch (e) {
      if (generation == _generation) {
        error = AppException.from(e).message;
        cached = posts.isNotEmpty;
      }
    } finally {
      if (generation == _generation) {
        loading = false;
        refreshing = false;
        notifyListeners();
      }
    }
  }

  Future<void> more() async {
    if (loading || refreshing || loadingMore || !hasMore || _page == 0) return;
    final generation = _generation;
    final next = _page + 1;
    final selectedAuthor = author;
    loadingMore = true;
    pageError = null;
    notifyListeners();
    try {
      final data = await repository.page(next, selectedAuthor);
      if (generation != _generation) return;
      final ids = posts.map((e) => e.id).toSet();
      posts = [...posts, ...data.where((p) => ids.add(p.id))];
      _page = next;
      hasMore = data.length == 10;
      cached = false;
      try {
        await repository.cache.write(selectedAuthor, posts);
      } catch (_) {
        pageError = 'Страница загружена, но кэш не сохранён.';
      }
    } catch (e) {
      if (generation == _generation) pageError = AppException.from(e).message;
    } finally {
      if (generation == _generation) {
        loadingMore = false;
        notifyListeners();
      }
    }
  }

  void reloadLocal() {
    locals = repository.cache.local();
    notifyListeners();
  }

  Future<void> reset() {
    query = '';
    descending = false;
    return open();
  }
}

class PostValidation {
  static String? title(String? value) {
    final n = value?.trim().length ?? 0;
    return n < 5 || n > 100 ? 'Заголовок: от 5 до 100 символов' : null;
  }

  static String? body(String? value) {
    final n = value?.trim().length ?? 0;
    return n < 10 || n > 1000 ? 'Текст: от 10 до 1000 символов' : null;
  }
}
