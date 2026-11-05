import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/presentation/screens/post_screens.dart';

import 'posts_test.dart' show fixture;

void main() {
  testWidgets('Main screen has title, search and create action', (
    tester,
  ) async {
    final (r, _) = await fixture();
    await tester.pumpWidget(MaterialApp(home: PostsScreen(repository: r)));
    await tester.pumpAndSettle();
    expect(find.text('Post Explorer'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Создать пост'), findsOneWidget);
  });
  testWidgets('Searching changes the displayed list to empty state', (
    tester,
  ) async {
    final (r, _) = await fixture();
    await tester.pumpWidget(MaterialApp(home: PostsScreen(repository: r)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'no-such-title');
    await tester.pumpAndSettle();
    expect(find.text('Посты не найдены'), findsOneWidget);
  });
  testWidgets('Tapping a post opens details and back returns to list', (
    tester,
  ) async {
    final (r, _) = await fixture();
    await tester.pumpWidget(MaterialApp(home: PostsScreen(repository: r)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Post 1'));
    await tester.pumpAndSettle();
    expect(find.text('Детали поста'), findsOneWidget);
    expect(find.text('Комментарии (1)'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Post Explorer'), findsOneWidget);
  });
  testWidgets('Create form validates before sending POST', (tester) async {
    final (r, a) = await fixture();
    await tester.pumpWidget(MaterialApp(home: CreatePostScreen(repository: r)));
    await tester.pumpAndSettle();
    final calls = a.calls;
    await tester.tap(find.text('Отправить POST'));
    await tester.pumpAndSettle();
    expect(find.text('Выберите автора'), findsOneWidget);
    expect(a.calls, calls);
  });
}
