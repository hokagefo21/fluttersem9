import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';
import '../state/posts_controller.dart';
import '../../core/error/app_exception.dart';

class PostsScreen extends StatefulWidget {
  final PostRepository repository;
  final WidgetBuilder? registrationBuilder;
  const PostsScreen({
    super.key,
    required this.repository,
    this.registrationBuilder,
  });
  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  late final controller = PostsController(widget.repository);
  final search = TextEditingController();
  List<User> users = [];
  String? authorError;
  @override
  void initState() {
    super.initState();
    unawaited(controller.open());
    unawaited(loadUsers());
  }

  Future<void> loadUsers() async {
    try {
      final data = await widget.repository.users();
      if (mounted) {
        setState(() {
          users = data;
          authorError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => authorError = AppException.from(e).message);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    search.dispose();
    super.dispose();
  }

  Future<void> create() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreatePostScreen(repository: widget.repository),
      ),
    );
    if (mounted) controller.reloadLocal();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Post Explorer'),
      actions: [
        if (widget.registrationBuilder != null)
          IconButton(
            tooltip: 'Регистрация Firebase',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: widget.registrationBuilder!),
            ),
          ),
        IconButton(
          tooltip: 'Обновить',
          icon: const Icon(Icons.refresh),
          onPressed: () => controller.open(userId: controller.author),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: create,
      icon: const Icon(Icons.add),
      label: const Text('Создать пост'),
    ),
    body: AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final items = controller.visible;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: search,
                onChanged: controller.search,
                decoration: const InputDecoration(
                  labelText: 'Поиск по заголовку',
                  helperText: 'Поиск только среди загруженных постов',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: controller.author ?? 0,
                      items: [
                        const DropdownMenuItem(
                          value: 0,
                          child: Text('Все авторы'),
                        ),
                        ...users.map(
                          (u) => DropdownMenuItem(
                            value: u.id,
                            child: Text(
                              '#${u.id} ${u.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          unawaited(
                            controller.open(userId: value == 0 ? null : value),
                          );
                        }
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Сортировка по ID',
                    icon: Icon(
                      controller.descending
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                    ),
                    onPressed: () => controller.sort(!controller.descending),
                  ),
                  IconButton(
                    tooltip: 'Сбросить фильтры',
                    icon: const Icon(Icons.filter_alt_off),
                    onPressed: () {
                      search.clear();
                      unawaited(controller.reset());
                    },
                  ),
                ],
              ),
            ),
            if (authorError != null)
              TextButton(
                onPressed: loadUsers,
                child: const Text('Не загружены авторы — повторить'),
              ),
            if (controller.cached)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Показан локальный кэш. Проверяем обновления.'),
              ),
            if (controller.refreshing && !controller.loading)
              const LinearProgressIndicator(),
            if (controller.error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(controller.error!),
                    TextButton(
                      onPressed: () =>
                          controller.open(userId: controller.author),
                      child: const Text('Повторить загрузку'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: controller.loading
                  ? const Center(child: CircularProgressIndicator())
                  : NotificationListener<ScrollNotification>(
                      onNotification: (event) {
                        if (event.metrics.extentAfter < 250 &&
                            controller.pageError == null) {
                          unawaited(controller.more());
                        }
                        return false;
                      },
                      child: RefreshIndicator(
                        onRefresh: () =>
                            controller.open(userId: controller.author),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: items.isEmpty ? 1 : items.length + 1,
                          itemBuilder: (context, index) {
                            if (items.isEmpty) {
                              return SizedBox(
                                height: 240,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Посты не найдены'),
                                      if (controller.hasMore &&
                                          controller.error == null)
                                        TextButton(
                                          onPressed: controller.more,
                                          child: const Text(
                                            'Искать на следующей странице',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            if (index == items.length) {
                              return Column(
                                children: [
                                  if (controller.loadingMore)
                                    const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  if (controller.pageError != null) ...[
                                    Text(controller.pageError!),
                                    TextButton(
                                      onPressed: controller.more,
                                      child: const Text('Повторить страницу'),
                                    ),
                                  ],
                                  if (controller.hasMore &&
                                      !controller.loadingMore &&
                                      controller.pageError == null)
                                    TextButton(
                                      onPressed: controller.more,
                                      child: const Text('Загрузить ещё'),
                                    ),
                                ],
                              );
                            }
                            final post = items[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 5,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(post.local ? 'L' : '${post.id}'),
                                ),
                                title: Text(
                                  post.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  post.local
                                      ? 'Создан локально · автор #${post.userId}'
                                      : 'Автор #${post.userId}',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => PostDetailScreen(
                                      repository: widget.repository,
                                      post: post,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    ),
  );
}

class PostDetailScreen extends StatefulWidget {
  final PostRepository repository;
  final Post post;
  const PostDetailScreen({
    super.key,
    required this.repository,
    required this.post,
  });
  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<PostDetails> data = widget.repository.details(widget.post);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Детали поста')),
    body: FutureBuilder<PostDetails>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppException.from(snapshot.error!).message),
                TextButton(
                  onPressed: () => setState(
                    () => data = widget.repository.details(widget.post),
                  ),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final result = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              result.post.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text('Автор: ${result.author.name}'),
            if (result.author.email != null) Text(result.author.email!),
            if (result.author.address?.city != null)
              Text(result.author.address!.city!),
            const Divider(),
            Text(result.post.body),
            const SizedBox(height: 24),
            Text(
              'Комментарии (${result.comments.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (result.comments.isEmpty)
              Text(
                result.post.local
                    ? 'Локальная запись не сохранена на JSONPlaceholder. Комментарии недоступны.'
                    : 'Комментариев нет.',
              ),
            ...result.comments.map(
              (c) => Card(
                child: ListTile(
                  title: Text(c.name),
                  subtitle: Text('${c.email}\n${c.body}'),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class CreatePostScreen extends StatefulWidget {
  final PostRepository repository;
  const CreatePostScreen({super.key, required this.repository});
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final body = TextEditingController();
  late Future<List<User>> authors = widget.repository.users();
  int? author;
  bool submitting = false;
  String? error;
  Post? response;
  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (submitting || !form.currentState!.validate()) return;
    setState(() {
      submitting = true;
      error = null;
    });
    try {
      final result = await widget.repository.create(
        title.text,
        body.text,
        author!,
      );
      if (mounted) setState(() => response = result);
    } catch (e) {
      if (mounted) setState(() => error = AppException.from(e).message);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Создать пост')),
    body: FutureBuilder<List<User>>(
      future: authors,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppException.from(snapshot.error!).message),
                TextButton(
                  onPressed: () =>
                      setState(() => authors = widget.repository.users()),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('Нет доступных авторов'));
        }
        if (response != null) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.check_circle, size: 56),
              const Text('Пост создан локально'),
              const Text(
                'JSONPlaceholder подтверждает POST, но не хранит его постоянно. Ответ сервера:',
              ),
              SelectableText(
                const JsonEncoder.withIndent('  ').convert(response!.toJson()),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('К списку постов'),
              ),
            ],
          );
        }
        return Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: title,
                enabled: !submitting,
                validator: PostValidation.title,
                decoration: const InputDecoration(
                  labelText: 'Заголовок (5–100 символов)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: body,
                enabled: !submitting,
                validator: PostValidation.body,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Текст (10–1000 символов)',
                ),
              ),
              DropdownButtonFormField<int>(
                initialValue: author,
                decoration: const InputDecoration(labelText: 'Автор'),
                items: snapshot.data!
                    .map(
                      (u) => DropdownMenuItem(value: u.id, child: Text(u.name)),
                    )
                    .toList(),
                onChanged: submitting
                    ? null
                    : (value) => setState(() => author = value),
                validator: (v) => v == null ? 'Выберите автора' : null,
              ),
              if (error != null)
                Padding(padding: const EdgeInsets.all(12), child: Text(error!)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: submitting ? null : submit,
                child: submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      )
                    : const Text('Отправить POST'),
              ),
            ],
          ),
        );
      },
    ),
  );
}
