import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

class AppException implements Exception {
  final String message;
  final String kind;
  const AppException(this.message, this.kind);
  factory AppException.from(Object error) {
    if (error is AppException) return error;
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return const AppException(
            'Сервер не ответил вовремя. Повторите запрос.',
            'timeout',
          );
        case DioExceptionType.connectionError:
          return const AppException('Нет соединения с интернетом.', 'offline');
        case DioExceptionType.badResponse:
          return (error.response?.statusCode ?? 0) >= 500
              ? const AppException('Ошибка сервера. Повторите позже.', 'server')
              : const AppException('Сервер отклонил запрос.', 'client');
        default:
          if (error.error != null) return AppException.from(error.error!);
      }
    }
    if (error is CheckedFromJsonException ||
        error is FormatException ||
        error is TypeError) {
      return const AppException('Получен некорректный ответ сервера.', 'json');
    }
    return const AppException(
      'Не удалось выполнить операцию. Повторите попытку.',
      'unknown',
    );
  }
  @override
  String toString() => message;
}
