import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushService {
  final status = ValueNotifier<String>('Настройка уведомлений…');
  final lastMessage = ValueNotifier<String>('');
  final _local = FlutterLocalNotificationsPlugin();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  void Function(String token)? onTokenRefresh;
  String? token;

  Future<void> initialize() async {
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
        ),
        onDidReceiveNotificationResponse: (response) {
          lastMessage.value = 'Открыто уведомление о регистрации';
        },
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'registration',
              'Регистрация',
              description: 'Подтверждение успешной регистрации',
              importance: Importance.high,
            ),
          );
      _subscriptions.add(
        FirebaseMessaging.onMessage.listen((message) {
          unawaited(_showForeground(message));
        }),
      );
      _subscriptions.add(FirebaseMessaging.onMessageOpenedApp.listen(_opened));
      _subscriptions.add(
        // Use legacy registration tokens for Firebase Admin SDK send(token: ...).
        // ignore: deprecated_member_use
        FirebaseMessaging.instance.onTokenRefresh.listen(
          (value) {
            token = value;
            onTokenRefresh?.call(value);
          },
          onError: (Object error) {
            status.value = 'Не удалось обновить токен уведомлений';
          },
        ),
      );
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _opened(initial);
      await requestPermissionAndToken();
    } catch (error) {
      status.value = 'Уведомления недоступны: проверьте Google Play Services';
    }
  }

  Future<String?> requestPermissionAndToken() async {
    try {
      final permission = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        status.value =
            'Уведомления запрещены. Разрешите их в настройках Android.';
        token = null;
        return null;
      }
      // Admin SDK HTTP v1 accepts registration tokens, not installation IDs.
      // ignore: deprecated_member_use
      token = await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 15),
      );
      status.value = token == null
          ? 'Токен FCM ещё не получен. Повторите запрос.'
          : 'FCM подключён. Ожидаем push от сервера.';
      return token;
    } catch (error) {
      status.value =
          'Токен FCM недоступен. Проверьте интернет и повторите запрос.';
      return null;
    }
  }

  void _opened(RemoteMessage message) {
    status.value = 'Push-уведомление открыто';
    lastMessage.value =
        message.notification?.body ?? 'Открыто уведомление о регистрации';
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    lastMessage.value = notification?.body ?? 'Получено push-уведомление';
    try {
      await _local.show(
        id: message.messageId.hashCode & 0x7fffffff,
        title: notification?.title ?? 'Регистрация',
        body: lastMessage.value,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'registration',
            'Регистрация',
            channelDescription: 'Подтверждение успешной регистрации',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_notification',
          ),
        ),
        payload: message.data['uid'] as String?,
      );
      status.value = 'Push-уведомление получено';
    } catch (error) {
      status.value = 'Push получен, но Android не показал уведомление';
    }
  }
}
