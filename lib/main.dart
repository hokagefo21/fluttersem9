import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/dio_client.dart';
import 'data/remote/post_api.dart';
import 'data/local/post_cache.dart';
import 'data/repositories/post_repository.dart';
import 'presentation/screens/post_screens.dart';
import 'registration_app.dart' as registration;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(
    registration.firebaseMessagingBackgroundHandler,
  );
  final preferences = await SharedPreferences.getInstance();
  final repository = PostRepository(
    PostApi(createDio()),
    PostCache(preferences),
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Post Explorer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3455db)),
        useMaterial3: true,
      ),
      home: PostsScreen(
        repository: repository,
        registrationBuilder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Назад к постам')),
          body: const registration.Lab7App(),
        ),
      ),
    ),
  );
}
