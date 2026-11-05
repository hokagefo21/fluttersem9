import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'registration.page.dart';
import 'services/registration_service.dart';
import 'services/push_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Notification payloads are displayed by Android while the app is backgrounded.
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const Lab7App());
}

class Lab7App extends StatefulWidget {
  const Lab7App({super.key});
  @override
  State<Lab7App> createState() => _Lab7AppState();
}

class _Lab7AppState extends State<Lab7App> {
  late Future<RegistrationService> _startup = _initialize();

  Future<RegistrationService> _initialize() async {
    final app = Firebase.apps.isEmpty
        ? await Firebase.initializeApp()
        : Firebase.app();
    const suppliedUrl = String.fromEnvironment('FIREBASE_DATABASE_URL');
    final url = suppliedUrl.isNotEmpty ? suppliedUrl : app.options.databaseURL;
    if (url == null || url.isEmpty) {
      throw StateError(
        'Укажите URL Realtime Database через '
        '--dart-define=FIREBASE_DATABASE_URL=https://ВАША-БАЗА.firebasedatabase.app',
      );
    }
    final push = PushService();
    final database = FirebaseDatabase.instanceFor(app: app, databaseURL: url);
    final service = FirebaseRegistrationService(database: database, push: push);
    await push.initialize();
    return service;
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Лабораторная работа №7',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3455db)),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      useMaterial3: true,
    ),
    home: FutureBuilder<RegistrationService>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return RegistrationPage(service: snapshot.data!);
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Подключение Firebase')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cloud_off, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Firebase пока не настроен',
                    style: TextStyle(fontSize: 22),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Добавьте google-services.json для '
                    'com.example.untitled в android/app и укажите URL базы. '
                    'После добавления файла полностью пересоберите приложение.',
                  ),
                  const SizedBox(height: 16),
                  SelectableText(snapshot.error.toString()),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => setState(() {
                      _startup = _initialize();
                    }),
                    child: const Text('Повторить подключение'),
                  ),
                ],
              ),
            ),
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    ),
  );
}
