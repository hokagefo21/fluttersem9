import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/registration.page.dart';
import 'package:untitled/services/registration_service.dart';

class FakeRegistration implements RegistrationService {
  @override
  final notificationStatus = ValueNotifier<String>('FCM готов');
  @override
  final lastNotification = ValueNotifier<String>('');
  int calls = 0;
  String? email;
  Completer<void>? pending;
  bool fail = false;
  @override
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    calls++;
    this.email = email;
    if (fail) throw StateError('Нет связи');
    if (pending != null) await pending!.future;
  }

  @override
  Future<void> retryNotifications() async {}
  @override
  Future<void> startNewRegistration() async {}
}

Future<void> fill(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Abdurauf');
  await tester.enterText(fields.at(1), 'student@example.com');
  await tester.enterText(fields.at(2), '+77001234567');
  await tester.enterText(fields.at(3), 'Lab7password!');
  await tester.ensureVisible(find.text('Зарегистрироваться'));
}

void main() {
  testWidgets('Invalid form never sends data', (tester) async {
    final service = FakeRegistration();
    await tester.pumpWidget(
      MaterialApp(home: RegistrationPage(service: service)),
    );
    await tester.ensureVisible(find.text('Зарегистрироваться'));
    await tester.tap(find.text('Зарегистрироваться'));
    await tester.pumpAndSettle();
    expect(service.calls, 0);
    expect(find.text('Введите корректный email'), findsOneWidget);
  });

  testWidgets('Success appears only after persistence completes', (
    tester,
  ) async {
    final service = FakeRegistration()..pending = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(home: RegistrationPage(service: service)),
    );
    await fill(tester);
    await tester.tap(find.text('Зарегистрироваться'));
    await tester.pump();
    expect(service.calls, 1);
    expect(find.text('Регистрация успешна'), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    service.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Регистрация успешна'), findsOneWidget);
    expect(service.email, 'student@example.com');
  });

  testWidgets('Failure allows retry and never shows success', (tester) async {
    final service = FakeRegistration()..fail = true;
    await tester.pumpWidget(
      MaterialApp(home: RegistrationPage(service: service)),
    );
    await fill(tester);
    await tester.tap(find.text('Зарегистрироваться'));
    await tester.pumpAndSettle();
    expect(find.text('Регистрация успешна'), findsNothing);
    expect(find.textContaining('Не удалось сохранить данные'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    service.fail = false;
    await tester.tap(find.text('Зарегистрироваться'));
    await tester.pumpAndSettle();
    expect(service.calls, 2);
    expect(find.text('Регистрация успешна'), findsOneWidget);
  });
}
