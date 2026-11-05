import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'services/registration_service.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key, required this.service});
  final RegistrationService service;
  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _saved = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone, _password]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.register(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
      );
      if (!mounted) return;
      _password.clear();
      setState(() {
        _saved = true;
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = switch (error.code) {
          'email-already-in-use' => 'Этот email уже зарегистрирован.',
          'invalid-email' => 'Проверьте адрес email.',
          'weak-password' => 'Используйте более надёжный пароль.',
          'operation-not-allowed' =>
            'В Firebase нужно включить вход Email/Password.',
          'network-request-failed' =>
            'Нет связи с Firebase. Проверьте интернет.',
          'too-many-requests' => 'Слишком много попыток. Повторите позже.',
          _ => 'Ошибка регистрации: ${error.code}',
        };
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error =
            'Сервер не ответил вовремя. Проверьте интернет и '
            'повторите. Уже созданный аккаунт будет использован повторно.';
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            'Ошибка базы данных: ${error.code}. '
            'Проверьте подключение и правила доступа.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось сохранить данные: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _newRegistration() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.startNewRegistration();
      if (!mounted) return;
      for (final controller in [_name, _email, _phone, _password]) {
        controller.clear();
      }
      setState(() {
        _saved = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Не удалось выйти из аккаунта.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboard,
    bool password = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !_busy && !_saved,
      keyboardType: keyboard,
      obscureText: password && _hidePassword,
      textInputAction: password ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: password ? (_) => _submit() : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: password
            ? IconButton(
                onPressed: () => setState(() {
                  _hidePassword = !_hidePassword;
                }),
                icon: Icon(
                  _hidePassword ? Icons.visibility : Icons.visibility_off,
                ),
              )
            : null,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Лабораторная работа №7')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  _saved ? Icons.check_circle : Icons.person_add_alt_1,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  _saved ? 'Регистрация успешна' : 'Создать аккаунт',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _saved
                      ? 'Данные сохранены в Firebase Realtime Database.'
                      : 'Заполните форму для регистрации.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _field(
                  label: 'Имя',
                  controller: _name,
                  validator: (v) => (v?.trim().length ?? 0) < 2
                      ? 'Введите имя: минимум 2 символа'
                      : null,
                ),
                _field(
                  label: 'Email',
                  controller: _email,
                  keyboard: TextInputType.emailAddress,
                  validator: (v) =>
                      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                          .hasMatch(v?.trim() ?? '')
                      ? 'Введите корректный email'
                      : null,
                ),
                _field(
                  label: 'Телефон',
                  controller: _phone,
                  keyboard: TextInputType.phone,
                  validator: (v) =>
                      !RegExp(r'^\+?[0-9 ()-]{10,20}$')
                          .hasMatch(v?.trim() ?? '')
                      ? 'Введите корректный телефон'
                      : null,
                ),
                if (!_saved)
                  _field(
                    label: 'Пароль',
                    controller: _password,
                    password: true,
                    validator: (v) => (v?.length ?? 0) < 8
                        ? 'Пароль: минимум 8 символов'
                        : null,
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (!_saved)
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Зарегистрироваться'),
                  ),
                if (_saved)
                  OutlinedButton(
                    onPressed: _busy ? null : _newRegistration,
                    child: const Text('Новая регистрация'),
                  ),
                const SizedBox(height: 20),
                const Divider(),
                const Text(
                  'Push-уведомления',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<String>(
                  valueListenable: widget.service.notificationStatus,
                  builder: (_, value, _) => Text(value),
                ),
                ValueListenableBuilder<String>(
                  valueListenable: widget.service.lastNotification,
                  builder: (_, value, _) => value.isEmpty
                      ? const SizedBox.shrink()
                      : Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(value),
                          ),
                        ),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : widget.service.retryNotifications,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(
                    _saved ? 'Повторить запрос push' : 'Разрешить уведомления',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
