import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/data/models/post.dart';
import 'package:untitled/data/models/user.dart';
import 'package:untitled/data/local/post_cache.dart';
import 'package:untitled/data/remote/post_api.dart';
import 'package:untitled/data/repositories/post_repository.dart';
import 'package:untitled/core/error/app_exception.dart';
import 'package:untitled/presentation/state/posts_controller.dart';

class FixtureAdapter implements HttpClientAdapter {
  int calls = 0;
  int status = 200;
  Completer<void>? gate;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (gate != null) await gate!.future;
    Object data;
    if (options.method == 'POST') {
      data = {...(options.data as Map), 'id': 101};
    } else if (options.path == '/users') {
      data = [
        {
          'id': 1,
          'name': 'Author',
          'email': 'author@example.com',
          'address': {'city': 'Almaty'},
        },
      ];
    } else if (options.path.endsWith('/comments')) {
      data = [
        {
          'id': 1,
          'postId': 1,
          'name': 'Comment',
          'email': 'a@example.com',
          'body': 'Comment text',
        },
      ];
    } else if (options.path.startsWith('/users/')) {
      data = {'id': 1, 'name': 'Author'};
    } else if (options.path != '/posts') {
      data = {
        'id': 1,
        'userId': 1,
        'title': 'First post',
        'body': 'Post content',
      };
    } else {
      final page = options.queryParameters['_page'] as int;
      final author = options.queryParameters['userId'] as int? ?? 1;
      data = List.generate(
        10,
        (i) => {
          'id': (page - 1) * 10 + i + 1,
          'userId': author,
          'title': 'Post ${i + 1}',
          'body': 'Post body content',
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<(PostRepository, FixtureAdapter)> fixture() async {
  SharedPreferences.setMockInitialValues({});
  final cache = PostCache(await SharedPreferences.getInstance());
  final adapter = FixtureAdapter();
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = adapter;
  return (PostRepository(PostApi(dio), cache), adapter);
}

void main() {
  test('JSON Post parses mandatory fields', () {
    final p = Post.fromJson({
      'id': 1,
      'userId': 2,
      'title': 'Title',
      'body': 'Body',
    });
    expect(p.userId, 2);
    expect(p.local, false);
  });
  test('Post serializes and round trips', () {
    const p = Post(id: 3, userId: 2, title: 'Title', body: 'Body');
    expect(Post.fromJson(p.toJson()).id, 3);
    expect(p.toJson()['title'], 'Title');
  });
  test('Malformed required field throws a controlled parsing error', () {
    expect(() => Post.fromJson({'id': 'bad'}), throwsA(anything));
  });
  test('Nested user address and nullable fields', () {
    final u = User.fromJson({
      'id': 1,
      'name': 'A',
      'address': {'city': 'Almaty'},
    });
    expect(u.address!.city, 'Almaty');
    expect(u.email, isNull);
    expect(u.toJson()['address']['city'], 'Almaty');
  });
  test('Repository loads a page via Retrofit', () async {
    final (r, a) = await fixture();
    expect((await r.page(1, null)).length, 10);
    expect(a.calls, 1);
  });
  test('HTTP 500 is translated to server error', () async {
    final (r, a) = await fixture();
    a.status = 500;
    await expectLater(
      r.page(1, null),
      throwsA(isA<AppException>().having((e) => e.kind, 'kind', 'server')),
    );
  });
  test('Author and title filtering', () async {
    final (r, _) = await fixture();
    final c = PostsController(r);
    await c.open(userId: 2);
    c.search('Post 1');
    expect(c.visible.every((p) => p.userId == 2), true);
    expect(c.visible.length, 2);
    c.dispose();
  });
  test('Duplicate page loads are blocked', () async {
    final (r, a) = await fixture();
    final c = PostsController(r);
    await c.open();
    a.gate = Completer<void>();
    final first = c.more();
    final duplicate = c.more();
    a.gate!.complete();
    await Future.wait([first, duplicate]);
    expect(a.calls, 2);
    expect(c.posts.length, 20);
    expect(c.posts.map((p) => p.id).toSet().length, 20);
    c.dispose();
  });
  test('Last successful cache survives server failure', () async {
    final (r, a) = await fixture();
    final c = PostsController(r);
    await c.open();
    a.status = 500;
    await c.open();
    expect(c.cached, true);
    expect(c.posts.length, 10);
    expect(c.error, isNotNull);
    c.dispose();
  });
  test('POST echoes response and stores a marked local post', () async {
    final (r, _) = await fixture();
    final result = await r.create('New title', 'New body content', 1);
    expect(result.id, 101);
    expect(r.cache.local().single.local, true);
    expect(r.cache.local().single.id, lessThan(0));
  });
  test('Filter change discards stale pages', () async {
    final (r, a) = await fixture();
    final c = PostsController(r);
    await c.open();
    a.gate = Completer<void>();
    final pending = c.more();
    final selected = c.open(userId: 2);
    a.gate!.complete();
    await Future.wait([pending, selected]);
    expect(c.posts.length, 10);
    expect(c.posts.every((p) => p.userId == 2), true);
    c.dispose();
  });
}
