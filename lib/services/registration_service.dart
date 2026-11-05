import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import 'push_service.dart';

abstract class RegistrationService {
  ValueListenable<String> get notificationStatus;
  ValueListenable<String> get lastNotification;
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });
  Future<void> retryNotifications();
  Future<void> startNewRegistration();
}

class FirebaseRegistrationService implements RegistrationService {
  FirebaseRegistrationService({required this.database, required this.push}) {
    push.onTokenRefresh = (token) => unawaited(_updateToken(token));
  }
  final FirebaseDatabase database;
  final PushService push;
  StreamSubscription<DatabaseEvent>? _delivery;
  bool _profileSaved = false;
  String? _uid;
  Future<void>? _pendingSave;

  @override
  ValueListenable<String> get notificationStatus => push.status;
  @override
  ValueListenable<String> get lastNotification => push.lastMessage;

  @override
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final auth = FirebaseAuth.instance;
    var user = auth.currentUser;
    if (user != null && user.email != email.trim().toLowerCase()) {
      await startNewRegistration();
      user = null;
    }
    user ??= (await auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    )).user;
    if (user == null) throw StateError('Не удалось создать аккаунт.');
    push.lastMessage.value = '';
    _uid = user.uid;
    final ref = database.ref('users/${user.uid}');
    final old = await ref.get().timeout(const Duration(seconds: 20));
    final createdAt = old.child('createdAt').value ?? ServerValue.timestamp;
    final profile = <String, Object?>{
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'createdAt': createdAt,
      'pushRequestedAt': ServerValue.timestamp,
      'fcmToken': push.token,
    };
    // Passwords are handled only by Firebase Auth.
    _pendingSave ??= ref.set(profile).whenComplete(() {
      _pendingSave = null;
    });
    await _pendingSave!.timeout(const Duration(seconds: 20));
    _profileSaved = true;
    await _delivery?.cancel();
    _delivery = database
        .ref('registrationPush/${user.uid}')
        .onValue
        .listen(
          (event) {
            final state = event.snapshot.child('status').value;
            if (state == 'sent') {
              push.status.value = push.lastMessage.value.isEmpty
                  ? 'Сервер отправил push. Ожидаем получение на устройстве.'
                  : 'Push-уведомление получено';
            } else if (state == 'error') {
              push.status.value = 'Сервер не отправил push. Повторите запрос.';
            }
          },
          onError: (Object error) {
            push.status.value = 'Не удалось прочитать статус отправки push';
          },
        );
    if (push.token == null) {
      push.status.value =
          'Данные сохранены. Разрешите уведомления и повторите запрос.';
    }
  }

  Future<void> _updateToken(String token) async {
    if (!_profileSaved || _uid == null) return;
    try {
      await database
          .ref('users/$_uid')
          .update({'fcmToken': token, 'pushRequestedAt': ServerValue.timestamp})
          .timeout(const Duration(seconds: 20));
      push.status.value = push.lastMessage.value.isEmpty
          ? 'Запрос push отправлен серверу'
          : 'Push-уведомление получено';
    } catch (error) {
      push.status.value = 'Не удалось сохранить токен FCM. Повторите запрос.';
    }
  }

  @override
  Future<void> retryNotifications() async {
    push.lastMessage.value = '';
    final token = await push.requestPermissionAndToken();
    if (token != null) await _updateToken(token);
  }

  @override
  Future<void> startNewRegistration() async {
    await _delivery?.cancel();
    _delivery = null;
    await FirebaseAuth.instance.signOut();
    _profileSaved = false;
    _uid = null;
    push.lastMessage.value = '';
    push.status.value = push.token == null
        ? 'Разрешите уведомления для получения push.'
        : 'FCM подключён. Ожидаем регистрацию.';
  }
}
