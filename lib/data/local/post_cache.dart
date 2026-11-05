import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/post.dart';

class PostCache {
  final SharedPreferences prefs;
  PostCache(this.prefs);
  String key(int? author) => 'posts_v1_${author ?? "all"}';
  List<Post> read(int? author) {
    try {
      final raw = prefs.getString(key(author));
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .map((e) => Post.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> write(int? author, List<Post> posts) async {
    final ok = await prefs.setString(
      key(author),
      jsonEncode(posts.map((p) => p.toJson()).toList()),
    );
    if (!ok) throw StateError('Cache write failed');
  }

  List<Post> local() => read(-1);
  Future<void> saveLocal(List<Post> posts) => write(-1, posts);
}
